import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:dart_ytmusic_api/yt_music.dart';
import '../models/song.dart';
import '../models/artist.dart';

class YouTubeService {
  final YoutubeExplode _yt = YoutubeExplode();
  final YTMusic _ytMusic = YTMusic();
  bool _isInit = false;

  Future<void> _initYtMusic() async {
    if (!_isInit) {
      await _ytMusic.initialize();
      _isInit = true;
    }
  }

  // Fetch tracklist from MusicBrainz
  Future<List<Song>> getAlbumTracksMusicBrainz(String albumName, String artistName) async {
    try {
      final releaseGroupUrl = Uri.parse(
          'https://musicbrainz.org/ws/2/release-group/?query=releasegroup:"${Uri.encodeComponent(albumName)}" AND artist:"${Uri.encodeComponent(artistName)}"&fmt=json');
      final response = await http.get(releaseGroupUrl, headers: {'User-Agent': 'StreamingApp/1.0 (rakha@example.com)'});
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final releaseGroups = data['release-groups'];
        if (releaseGroups != null && releaseGroups.isNotEmpty) {
          final rgId = releaseGroups[0]['id'];
          final releaseUrl = Uri.parse('https://musicbrainz.org/ws/2/release-group/$rgId?inc=releases&fmt=json');
          final releaseResponse = await http.get(releaseUrl, headers: {'User-Agent': 'StreamingApp/1.0 (rakha@example.com)'});
          
          if (releaseResponse.statusCode == 200) {
            final releaseData = jsonDecode(releaseResponse.body);
            final releases = releaseData['releases'];
            if (releases != null && releases.isNotEmpty) {
              final releaseId = releases[0]['id'];
              final tracksUrl = Uri.parse('https://musicbrainz.org/ws/2/release/$releaseId?inc=recordings&fmt=json');
              final tracksResponse = await http.get(tracksUrl, headers: {'User-Agent': 'StreamingApp/1.0 (rakha@example.com)'});
              
              if (tracksResponse.statusCode == 200) {
                final tracksData = jsonDecode(tracksResponse.body);
                final List recordings = tracksData['media'][0]['tracks'];
                List<Song> songs = [];
                for (var r in recordings) {
                  songs.add(Song(
                    id: '', // Placeholder ID, need to fetch from YT search
                    title: r['title'],
                    author: artistName,
                    thumbnailUrl: '',
                    duration: Duration(milliseconds: r['length'] ?? 0),
                  ));
                }
                return songs;
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint("MusicBrainz Error: $e");
    }
    return [];
  }


  // Helper for high-res thumbnail
  String _getHighResThumbnail(String url) {
    if (url.isEmpty) return url;
    return url.replaceAll(RegExp(r'=w\d+-h\d+.*'), '=w800-h800-l90-rj');
  }

  Future<List<Artist>> searchArtists(String query) async {
    if (query.trim().isEmpty) return [];

    try {
      debugPrint("SEARCHING ARTISTS FOR: $query");
      await _initYtMusic();
      
      final results = await _ytMusic.searchArtists(query);
      List<Artist> artists = [];
      
      for (var result in results) {
        artists.add(Artist(
          id: result.artistId ?? '',
          name: result.name ?? '',
          thumbnailUrl: result.thumbnails?.isNotEmpty == true ? _getHighResThumbnail(result.thumbnails!.last.url) : '',
        ));
      }
      
      debugPrint("FOUND ${artists.length} artists");
      return artists;
    } catch (e, st) {
      debugPrint("Artist Search Error: $e\n$st");
      return [];
    }
  }

  Future<List<Song>> searchSongs(String query) async {
    if (query.trim().isEmpty) {
      return _getDefaultTracks();
    }

    try {
      debugPrint("SEARCHING YOUTUBE MUSIC FOR: $query");
      await _initYtMusic();
      
      List<Song> songs = [];
      Set<String> seenIds = {};

      // Search songs, videos, and albums to get more results
      try {
        final songResults = await _ytMusic.searchSongs(query);
        for (var result in songResults) {
          if (result.videoId != null && seenIds.add(result.videoId!)) {
            songs.add(Song(
              id: result.videoId!,
              title: result.name ?? '',
              author: result.artist?.name ?? '',
              thumbnailUrl: result.thumbnails?.isNotEmpty == true ? _getHighResThumbnail(result.thumbnails!.last.url) : '',
              duration: Duration(milliseconds: result.duration ?? 0),
            ));
          }
        }
      } catch (_) {}

      try {
        final videoResults = await _ytMusic.searchVideos(query);
        for (var result in videoResults) {
          if (result.videoId != null && seenIds.add(result.videoId!)) {
            songs.add(Song(
              id: result.videoId!,
              title: result.name ?? '',
              author: result.artist?.name ?? '',
              thumbnailUrl: result.thumbnails?.isNotEmpty == true ? _getHighResThumbnail(result.thumbnails!.last.url) : '',
              duration: Duration(milliseconds: result.duration ?? 0),
            ));
          }
        }
      } catch (_) {}
      
      if (songs.isEmpty) {
        var searchList = await _yt.search.search('$query music');
        for (var video in searchList.take(30)) {
          if (seenIds.add(video.id.value)) {
            songs.add(Song(
              id: video.id.value,
              title: video.title,
              author: video.author.replaceAll(RegExp(r'- Topic$'), '').trim(),
              thumbnailUrl: video.thumbnails.highResUrl,
              duration: video.duration ?? const Duration(minutes: 3, seconds: 30),
            ));
          }
        }
      }
      
      debugPrint("FOUND ${songs.length} results for: $query");
      return songs;
    } catch (e, st) {
      debugPrint("YouTube Music Search Error: $e\n$st");
      return _getDefaultTracks();
    }
  }

  List<Song> _getDefaultTracks() {
    return [
      Song(
        id: 'wlvzaThRs2g',
        title: 'Sandiwara Semu',
        author: 'rumahsakit',
        thumbnailUrl: 'https://i.ytimg.com/vi/wlvzaThRs2g/hqdefault.jpg',
        duration: const Duration(minutes: 4, seconds: 24),
      ),
      Song(
        id: '5qap5aO4i9A',
        title: 'Lofi Hip Hop Radio',
        author: 'Lofi Girl',
        thumbnailUrl: 'https://i.ytimg.com/vi/5qap5aO4i9A/hqdefault.jpg',
        duration: const Duration(hours: 24),
      ),
      Song(
        id: '2Vv-BfVoq4g',
        title: 'Perfect',
        author: 'Ed Sheeran',
        thumbnailUrl: 'https://i.ytimg.com/vi/2Vv-BfVoq4g/hqdefault.jpg',
        duration: const Duration(minutes: 4, seconds: 23),
      ),
      Song(
        id: 'JGwWNGJdvx8',
        title: 'Shape of You',
        author: 'Ed Sheeran',
        thumbnailUrl: 'https://i.ytimg.com/vi/JGwWNGJdvx8/hqdefault.jpg',
        duration: const Duration(minutes: 4, seconds: 10),
      ),
      Song(
        id: 'kJQP7kiw5Fk',
        title: 'Despacito',
        author: 'Luis Fonsi ft. Daddy Yankee',
        thumbnailUrl: 'https://i.ytimg.com/vi/kJQP7kiw5Fk/hqdefault.jpg',
        duration: const Duration(minutes: 4, seconds: 41),
      ),
      Song(
        id: 'F3p9tAHzHvU',
        title: 'Blinding Lights',
        author: 'The Weeknd',
        thumbnailUrl: 'https://i.ytimg.com/vi/F3p9tAHzHvU/hqdefault.jpg',
        duration: const Duration(minutes: 3, seconds: 22),
      ),
      Song(
        id: 'Ck9rJhYhEyc',
        title: 'Stay',
        author: 'The Kid LAROI, Justin Bieber',
        thumbnailUrl: 'https://i.ytimg.com/vi/Ck9rJhYhEyc/hqdefault.jpg',
        duration: const Duration(minutes: 2, seconds: 21),
      ),
      Song(
        id: 'TUVcZfQe-Kw',
        title: 'Levitating',
        author: 'Dua Lipa',
        thumbnailUrl: 'https://i.ytimg.com/vi/TUVcZfQe-Kw/hqdefault.jpg',
        duration: const Duration(minutes: 3, seconds: 24),
      ),
      Song(
        id: 'pHDN-p2yByo',
        title: 'Dynamite',
        author: 'BTS',
        thumbnailUrl: 'https://i.ytimg.com/vi/pHDN-p2yByo/hqdefault.jpg',
        duration: const Duration(minutes: 3, seconds: 43),
      ),
      Song(
        id: 'QYh6mYIJG2Y',
        title: 'Stayin Alive',
        author: 'Bee Gees',
        thumbnailUrl: 'https://i.ytimg.com/vi/QYh6mYIJG2Y/hqdefault.jpg',
        duration: const Duration(minutes: 4, seconds: 45),
      ),
    ];
  }

  Future<List<Song>> getRelatedSongs(String videoId) async {
    try {
      final video = await _yt.videos.get(videoId);
      final mixes = await _yt.videos.getRelatedVideos(video);
      List<Song> songs = [];
      if (mixes != null) {
        for (var mix in mixes) {
          if (mix.id.value.isNotEmpty && mix.title.isNotEmpty) {
            songs.add(Song(
              id: mix.id.value,
              title: mix.title,
              author: mix.author,
              thumbnailUrl: mix.thumbnails.highResUrl,
              duration: mix.duration ?? Duration.zero,
            ));
          }
        }
      }
      return songs;
    } catch (e) {
      debugPrint("Get Related Songs Error: $e");
      return [];
    }
  }

  Future<String?> getAudioStreamUrl(String videoId) async {
    try {
      final manifest = await _yt.videos.streamsClient.getManifest(videoId);
      final streamInfo = manifest.muxed.withHighestBitrate();
      return streamInfo.url.toString();
    } catch (e) {
      try {
        final manifest = await _yt.videos.streamsClient.getManifest(videoId);
        return manifest.audioOnly.withHighestBitrate().url.toString();
      } catch (_) {
        return null;
      }
    }
  }

  Future<Map<String, dynamic>> getAlbumDetails(String albumId) async {
    await _initYtMusic();
    try {
      final albumData = await _ytMusic.getAlbum(albumId);
      List<Song> songs = [];
      
      // Get tracks directly from the album object
      final tracks = albumData.songs ?? [];
      for (var track in tracks) {
        if (track.videoId != null) {
          songs.add(Song(
            id: track.videoId!,
            title: track.name ?? '',
            author: albumData.artist?.name ?? track.artist?.name ?? '',
            thumbnailUrl: albumData.thumbnails?.isNotEmpty == true ? albumData.thumbnails!.last.url : '',
            duration: Duration(milliseconds: track.duration ?? 0),
          ));
        }
      }

      return {
        'title': albumData.name ?? 'Album',
        'thumbnailUrl': albumData.thumbnails?.isNotEmpty == true ? _getHighResThumbnail(albumData.thumbnails!.last.url) : '',
        'artist': albumData.artist?.name ?? '',
        'year': albumData.year,
        'songs': songs,
      };
    } catch (e) {
      debugPrint("Album Error: $e");
      return {'title': 'Album', 'thumbnailUrl': '', 'artist': '', 'year': 0, 'songs': <Song>[]};
    }
  }

  Future<Artist> getArtistDetails(String artistId) async {
    await _initYtMusic();
    final artistData = await _ytMusic.getArtist(artistId);
    
    List<Song> songs = [];
    try {
      final fetchedSongs = await _ytMusic.getArtistSongs(artistId);
      for (var s in fetchedSongs) {
        if (s.videoId != null) {
          songs.add(Song(
            id: s.videoId!,
            title: s.name ?? '',
            author: artistData.name ?? '',
            thumbnailUrl: s.thumbnails?.isNotEmpty == true ? _getHighResThumbnail(s.thumbnails!.last.url) : '',
            duration: Duration(milliseconds: s.duration ?? 0),
          ));
        }
      }
    } catch (_) {}

    List<Map<String, dynamic>> albumList = [];
    final targetArtist = (artistData.name ?? '').toLowerCase().trim();

    bool isValidArtist(String? authorName) {
      if (authorName == null || authorName.isEmpty) return true;
      final a = authorName.toLowerCase().trim();
      return a == targetArtist;
    }

    try {
      final fetchedAlbums = await _ytMusic.getArtistAlbums(artistId);
      for (var a in fetchedAlbums) {
        if (isValidArtist(a.artist?.name)) {
          albumList.add({
            'id': a.albumId,
            'title': a.name,
            'thumbnailUrl': a.thumbnails?.isNotEmpty == true ? _getHighResThumbnail(a.thumbnails!.last.url) : '',
            'year': a.year,
          });
        }
      }
    } catch (_) {}

    if (albumList.isEmpty && targetArtist.isNotEmpty) {
      try {
        final searchAlbums = await _ytMusic.searchAlbums(artistData.name!);
        for (var a in searchAlbums) {
          if (isValidArtist(a.artist?.name)) {
            albumList.add({
              'id': a.albumId,
              'title': a.name,
              'thumbnailUrl': a.thumbnails?.isNotEmpty == true ? _getHighResThumbnail(a.thumbnails!.last.url) : '',
              'year': a.year,
            });
          }
        }
      } catch (_) {}
    }

    return Artist(
      id: artistId,
      name: artistData.name ?? '',
      thumbnailUrl: artistData.thumbnails?.isNotEmpty == true ? _getHighResThumbnail(artistData.thumbnails!.last.url) : '',
      topSongs: songs,
      albums: albumList,
    );
  }

  void dispose() {
    _yt.close();
  }
}
