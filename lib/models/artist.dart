import 'song.dart';

class Artist {
  final String id;
  final String name;
  final String thumbnailUrl;
  final List<Song> topSongs;
  final List<Map<String, dynamic>> albums;

  Artist({
    required this.id,
    required this.name,
    required this.thumbnailUrl,
    this.topSongs = const [],
    this.albums = const [],
  });
}

