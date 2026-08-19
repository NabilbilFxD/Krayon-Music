import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:media_kit/media_kit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/song.dart';
import '../models/artist.dart';
import '../services/youtube_service.dart';
import '../services/database_service.dart';

class AudioProvider with ChangeNotifier {
  late final Player _player = Player();
  final YouTubeService _youtubeService = YouTubeService();
  late SharedPreferences _prefs;

  Song? _currentSong;
  bool _isLoading = false;
  bool _isSearchLoading = false;
  bool _isSongLoading = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  double _volume = 100.0;

  List<Song> _queue = [];
  int _currentIndex = -1;
  List<Song> _searchResults = [];
  List<Artist> _searchArtists = [];
  List<Song> _likedSongs = [];

  bool _isShuffle = false;
  bool _autoPlayRelated = true;
  bool _isRepeat = false;
  String? _selectedArtist;
  String? _selectedArtistId;
  String? _selectedArtistThumbnail;
  List<Song> _artistSongs = [];
  List<Map<String, dynamic>> _artistAlbums = [];
  bool _isArtistLoading = false;

  Map<String, dynamic>? _selectedAlbum;
  List<Song> _albumSongs = [];
  bool _isAlbumLoading = false;

  String _lyrics = "Loading lyrics...";
  bool _isLyricsLoading = false;

  List<Song> _historySongs = [];
  List<Song> get historySongs => _historySongs;

  AudioProvider() {
    _init();
    _loadHistory();
    _player.stream.position.listen((p) { _position = p; notifyListeners(); });
    _player.stream.duration.listen((d) { _duration = d; notifyListeners(); });
    _player.stream.playing.listen((isPlaying) { notifyListeners(); });
    _player.stream.completed.listen((c) { if (c) skipNext(); });
  }

  @override
  void notifyListeners() {
    super.notifyListeners();
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
    final likedJson = _prefs.getString('liked_songs');
    if (likedJson != null) {
      final List<dynamic> list = jsonDecode(likedJson);
      _likedSongs = list.map((item) => Song(
        id: item['id'],
        title: item['title'],
        author: item['author'],
        thumbnailUrl: item['thumbnailUrl'],
        duration: Duration(milliseconds: item['durationMs']),
      )).toList();
      notifyListeners();
    }
  }

  Song? get currentSong => _currentSong;
  bool get isPlaying => _player.state.playing;
  bool get isLoading => _isLoading;
  bool get isSearchLoading => _isSearchLoading;
  bool get isSongLoading => _isSongLoading;
  Duration get position => _position;
  Duration get duration => _duration;
  double get volume => _volume;
  List<Song> get likedSongs => _likedSongs;
  List<Song> get searchResults => _searchResults;
  List<Song> _downloadedSongs = [];
  List<Song> get downloadedSongs => _downloadedSongs;

  bool isDownloaded(Song song) => _downloadedSongs.any((s) => s.id == song.id);

  void toggleDownload(Song song) {
    if (isDownloaded(song)) {
      _downloadedSongs.removeWhere((s) => s.id == song.id);
    } else {
      _downloadedSongs.add(song);
    }
    notifyListeners();
  }

  Map<String, List<Song>> _customPlaylists = {};
  Map<String, List<Song>> get customPlaylists => _customPlaylists;

  void createPlaylist(String name) {
    if (name.trim().isNotEmpty && !_customPlaylists.containsKey(name)) {
      _customPlaylists[name] = [];
      notifyListeners();
    }
  }

  void deletePlaylist(String name) {
    _customPlaylists.remove(name);
    notifyListeners();
  }

  void addToPlaylist(String name, Song song) {
    if (_customPlaylists.containsKey(name)) {
      if (!_customPlaylists[name]!.any((s) => s.id == song.id)) {
        _customPlaylists[name]!.add(song);
        notifyListeners();
      }
    }
  }

  void removeFromPlaylist(String name, Song song) {
    if (_customPlaylists.containsKey(name)) {
      _customPlaylists[name]!.removeWhere((s) => s.id == song.id);
      notifyListeners();
    }
  }

  void addToQueue(Song song) {
    _queue.add(song);
    notifyListeners();
  }

  void playNextInQueue(Song song) {
    if (_currentIndex >= 0 && _currentIndex < _queue.length) {
      _queue.insert(_currentIndex + 1, song);
    } else {
      _queue.add(song);
    }
    notifyListeners();
  }

  List<Song> get queue => _queue;
  bool get isShuffle => _isShuffle;
  bool get isRepeat => _isRepeat;
  bool get autoPlayRelated => _autoPlayRelated;
  Map<String, dynamic>? get selectedAlbum => _selectedAlbum;
  List<Song> get albumSongs => _albumSongs;
  bool get isAlbumLoading => _isAlbumLoading;
  String? get selectedArtist => _selectedArtist;
  String? get selectedArtistId => _selectedArtistId;
  String? get selectedArtistThumbnail => _selectedArtistThumbnail;
  List<Song> get artistSongs => _artistSongs;
  List<Map<String, dynamic>> get artistAlbums => _artistAlbums;
  bool get isArtistLoading => _isArtistLoading;
  
  void clearArtist() {
    _selectedArtist = null;
    _selectedArtistId = null;
    _selectedArtistThumbnail = null;
    _artistSongs = [];
    _artistAlbums = [];
    notifyListeners();
  }
  String get lyrics => _lyrics;
  bool get isLyricsLoading => _isLyricsLoading;
  List<Artist> get searchArtists => _searchArtists;

  bool isLiked(Song song) => _likedSongs.any((s) => s.id == song.id);

  void toggleLike(Song song) {
    if (isLiked(song)) {
      _likedSongs.removeWhere((s) => s.id == song.id);
    } else {
      _likedSongs.add(song);
    }
    _prefs.setString('liked_songs', jsonEncode(_likedSongs.map((s) => {
      'id': s.id,
      'title': s.title,
      'author': s.author,
      'thumbnailUrl': s.thumbnailUrl,
      'durationMs': s.duration.inMilliseconds,
    }).toList()));
    notifyListeners();
  }

  Future<void> searchSongs(String query) async {
    if (query.trim().isEmpty) return;
    _searchResults = [];
    _searchArtists = [];
    _isSearchLoading = true;
    notifyListeners();
    try {
      _searchResults = await _youtubeService.searchSongs(query);
      _searchArtists = await _youtubeService.searchArtists(query);
    } catch (e) {
      debugPrint("Search Error: $e");
    } finally {
      _isSearchLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadArtist(String artistId, String artistName, [String? thumbnail]) async {
    _selectedArtistId = artistId;
    _selectedArtist = artistName;
    _selectedArtistThumbnail = thumbnail;
    _isArtistLoading = true;
    _artistSongs = [];
    _artistAlbums = [];
    notifyListeners();
    
    try {
      if (artistId.isNotEmpty) {
        final artist = await _youtubeService.getArtistDetails(artistId);
        _artistSongs = artist.topSongs;
        _artistAlbums = artist.albums;
      }
      if (_artistSongs.isEmpty) {
        _artistSongs = await _youtubeService.searchSongs(artistName);
      }
    } catch (e) {
      debugPrint("Load Artist Details Error: $e");
      _artistSongs = await _youtubeService.searchSongs(artistName);
    } finally {
      _isArtistLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadAlbum(String albumId) async {
    _isAlbumLoading = true;
    _albumSongs = [];
    notifyListeners();
    try {
      final albumData = await _youtubeService.getAlbumDetails(albumId);
      _selectedAlbum = albumData;
      _albumSongs = (albumData['songs'] as List<dynamic>).map((e) => e as Song).toList();
    } catch (e) {
      debugPrint("Load Album Error: $e");
    } finally {
      _isAlbumLoading = false;
      notifyListeners();
    }
  }

  void clearAlbum() {
    _selectedAlbum = null;
    _albumSongs = [];
    notifyListeners();
  }

  Future<void> fetchLyrics(String title, String artist) async {
    _isLyricsLoading = true;
    _lyrics = "Fetching live lyrics...";
    notifyListeners();

    // Clean title and artist to increase search match rate
    final cleanTitle = title.replaceAll(RegExp(r'\(.*?\)|\[.*?\]'), '').trim();
    final cleanArtist = artist.replaceAll(RegExp(r'VEVO|Official', caseSensitive: false), '').trim();

    try {
      // Direct exact match query with 3 second timeout
      var res = await http.get(
        Uri.parse('https://lrclib.net/api/get?artist_name=${Uri.encodeComponent(cleanArtist)}&track_name=${Uri.encodeComponent(cleanTitle)}'),
      ).timeout(const Duration(seconds: 3));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        _lyrics = data['syncedLyrics'] ?? data['plainLyrics'] ?? "No lyrics found.";
      } else {
        // Fallback search query if exact match fails
        final searchRes = await http.get(
          Uri.parse('https://lrclib.net/api/search?q=${Uri.encodeComponent("$cleanTitle $cleanArtist")}'),
        ).timeout(const Duration(seconds: 3));

        if (searchRes.statusCode == 200) {
          final List results = jsonDecode(searchRes.body);
          if (results.isNotEmpty) {
            _lyrics = results.first['syncedLyrics'] ?? results.first['plainLyrics'] ?? "No lyrics found.";
          } else {
            _lyrics = "No lyrics available for this track.";
          }
        } else {
          _lyrics = "No lyrics available for this track.";
        }
      }
    } catch (e) {
      _lyrics = "No lyrics available for this track.";
    }
    _isLyricsLoading = false;
    notifyListeners();
  }

  Future<void> _loadHistory() async {
    try {
      _historySongs = await DatabaseService.instance.getHistory();
      notifyListeners();
    } catch (e) {
      debugPrint("Load History Error: $e");
    }
  }

  Future<void> refreshHistory() async {
    await _loadHistory();
  }

  Future<void> clearHistory() async {
    await DatabaseService.instance.clearHistory();
    _historySongs = [];
    notifyListeners();
  }

  Future<void> playSong(Song song, {List<Song>? queue, int? index}) async {
    if (queue != null && queue.isNotEmpty) {
      _queue = List.from(queue);
      if (index != null) _currentIndex = index;
    } else {
      // Content-Based Filtering / Auto Queue Generator
      if (_autoPlayRelated) {
        try {
          final related = await _youtubeService.getRelatedSongs(song.id);
          if (related.isNotEmpty) {
            _queue = [song, ...related];
            _currentIndex = 0;
          } else {
            _queue = [song];
            _currentIndex = 0;
          }
        } catch (e) {
          _queue = [song];
          _currentIndex = 0;
        }
      } else {
        _queue = [song];
        _currentIndex = 0;
      }
    }
    
    _isSongLoading = true;
    _currentSong = song;
    notifyListeners();

    try {
      print("Attempting to add to history: ${song.title} | UserID: ${FirebaseAuth.instance.currentUser?.uid}");
      await DatabaseService.instance.addToHistory(song);
      await _loadHistory();
      print("SUCCESS ADDED TO HISTORY: ${song.title}");
    } catch (e) {
      debugPrint("AddToHistory Error: $e");
    }

    fetchLyrics(song.title, song.author);

    try {
      final url = await _youtubeService.getAudioStreamUrl(song.id);
      if (url != null) {
        await _player.open(Media(url));
        await _player.play();
      }
    } catch (e) {
      debugPrint("Playback Error: $e");
    } finally {
      _isSongLoading = false;
      notifyListeners();
    }
  }

  void skipNext() {
    if (_queue.isEmpty) return;
    if (_isRepeat) {
      playSong(_currentSong!);
      return;
    }
    _currentIndex = (_currentIndex + 1) % _queue.length;
    playSong(_queue[_currentIndex]);
  }

  Timer? _sleepTimer;
  Duration? _sleepTimeRemaining;
  bool _sleepOnTrackEnd = false;
  Duration? get sleepTimeRemaining => _sleepTimeRemaining;
  bool get sleepOnTrackEnd => _sleepOnTrackEnd;

  void setSleepTimer(Duration? duration, {bool onTrackEnd = false}) {
    _sleepTimer?.cancel();
    _sleepTimeRemaining = duration;
    _sleepOnTrackEnd = onTrackEnd;
    notifyListeners();

    if (duration != null) {
      _sleepTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_sleepTimeRemaining == null || _sleepTimeRemaining!.inSeconds <= 0) {
          timer.cancel();
          _sleepTimeRemaining = null;
          _player.pause();
          notifyListeners();
        } else {
          _sleepTimeRemaining = Duration(seconds: _sleepTimeRemaining!.inSeconds - 1);
          notifyListeners();
        }
      });
    }
  }

  void cancelSleepTimer() {
    _sleepTimer?.cancel();
    _sleepTimeRemaining = null;
    notifyListeners();
  }

  void skipPrevious() {
    if (_queue.isEmpty) return;
    if (_position.inSeconds > 3) {
      _player.seek(Duration.zero);
      return;
    }
    _currentIndex = (_currentIndex - 1 + _queue.length) % _queue.length;
    playSong(_queue[_currentIndex]);
  }

  void setVolume(double v) {
    _volume = v;
    _player.setVolume(v);
    notifyListeners();
  }

  void toggleShuffle() { _isShuffle = !_isShuffle; notifyListeners(); }
  void toggleRepeat() { _isRepeat = !_isRepeat; notifyListeners(); }
  void toggleAutoPlayRelated() { _autoPlayRelated = !_autoPlayRelated; notifyListeners(); }

  Future<void> togglePlayPause() async {
    if (_player.state.playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
    notifyListeners();
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
