import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/audio_provider.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _ctrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AudioProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: const Color(0xFF121212),
            surfaceTintColor: Colors.transparent,
            floating: false,
            pinned: true,
            elevation: 0,
            titleSpacing: 16,
            title: Container(
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF282828),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _ctrl,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                textAlignVertical: TextAlignVertical.center,
                decoration: InputDecoration(
                  hintText: 'What do you want to listen to?',
                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 16),
                  prefixIcon: Icon(Icons.search, color: Colors.white.withValues(alpha: 0.6), size: 24),
                  suffixIcon: _ctrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () {
                            _ctrl.clear();
                            setState(() {});
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                ),
                onChanged: (_) => setState(() {}),
                onSubmitted: (q) => p.searchSongs(q),
              ),
            ),
            automaticallyImplyLeading: false,
            toolbarHeight: 64,
          ),
           if (p.isSearchLoading)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFF00F2FE)),
              ),
            )
          else if (p.searchResults.isEmpty && p.searchArtists.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.music_note_outlined, size: 64, color: Colors.white.withValues(alpha: 0.3)),
                    const SizedBox(height: 16),
                    Text(
                      'What do you want to listen to?',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 18),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  if (p.searchArtists.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Artist', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: () => p.loadArtist(p.searchArtists.first.id, p.searchArtists.first.name, p.searchArtists.first.thumbnailUrl),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 35,
                                    backgroundImage: CachedNetworkImageProvider(p.searchArtists.first.thumbnailUrl),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          p.searchArtists.first.name,
                                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Artist',
                                          style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 14),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right, color: Colors.white24),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Divider(color: Colors.white10, height: 1),
                        ],
                      ),
                    ),
                  if (p.searchResults.isNotEmpty)
                    ...p.searchResults.map((song) {
                      final isLiked = p.isLiked(song);
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => p.playSong(song, queue: p.searchResults, index: p.searchResults.indexOf(song)),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.white.withValues(alpha: 0.05),
                              ),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: CachedNetworkImage(
                                      imageUrl: song.thumbnailUrl,
                                      width: 56,
                                      height: 56,
                                      fit: BoxFit.cover,
                                      errorWidget: (_, __, ___) => Container(
                                        width: 56,
                                        height: 56,
                                        color: Colors.grey[900],
                                        child: const Icon(Icons.music_note, color: Colors.white54),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          song.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          song.author,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: Colors.white.withValues(alpha: 0.6),
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                   IconButton(
                                     icon: Icon(
                                       isLiked ? Icons.favorite : Icons.favorite_border,
                                       color: isLiked ? const Color(0xFF00F2FE) : Colors.white.withValues(alpha: 0.4),
                                       size: 20,
                                     ),
                                     onPressed: () => p.toggleLike(song),
                                   ),
                                   IconButton(
                                     icon: const Icon(Icons.more_vert, color: Colors.white54, size: 20),
                                     onPressed: () {
                                       showModalBottomSheet(
                                         context: context,
                                         backgroundColor: const Color(0xFF121212),
                                         shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
                                         builder: (context) => SafeArea(
                                           child: Column(
                                             mainAxisSize: MainAxisSize.min,
                                             children: [
                                               ListTile(
                                                 leading: const Icon(Icons.queue_music, color: Colors.white),
                                                 title: const Text('Add to Queue', style: TextStyle(color: Colors.white)),
                                                 onTap: () {
                                                   p.addToQueue(song);
                                                   Navigator.pop(context);
                                                   ScaffoldMessenger.of(context).showSnackBar(
                                                     const SnackBar(content: Text('Added to Queue'), duration: Duration(seconds: 1)),
                                                   );
                                                 },
                                               ),
                                               ListTile(
                                                 leading: const Icon(Icons.playlist_play, color: Colors.white),
                                                 title: const Text('Play Next', style: TextStyle(color: Colors.white)),
                                                 onTap: () {
                                                   p.playNextInQueue(song);
                                                   Navigator.pop(context);
                                                   ScaffoldMessenger.of(context).showSnackBar(
                                                     const SnackBar(content: Text('Will play next'), duration: Duration(seconds: 1)),
                                                   );
                                                 },
                                               ),
                                               ListTile(
                                                 leading: const Icon(Icons.playlist_add, color: Colors.white),
                                                 title: const Text('Add to Playlist', style: TextStyle(color: Colors.white)),
                                                 onTap: () {
                                                   Navigator.pop(context);
                                                   showDialog(
                                                     context: context,
                                                     builder: (context) => AlertDialog(
                                                       backgroundColor: const Color(0xFF282828),
                                                       title: const Text('Add to Playlist', style: TextStyle(color: Colors.white)),
                                                       content: SizedBox(
                                                         width: double.maxFinite,
                                                         child: Consumer<AudioProvider>(
                                                           builder: (context, provider, _) {
                                                             final playlists = provider.customPlaylists.keys.toList();
                                                             if (playlists.isEmpty) {
                                                               return const Text('No playlists created yet.', style: TextStyle(color: Colors.white54));
                                                             }
                                                             return ListView.builder(
                                                               shrinkWrap: true,
                                                               itemCount: playlists.length,
                                                               itemBuilder: (context, index) {
                                                                 final name = playlists[index];
                                                                 return ListTile(
                                                                   title: Text(name, style: const TextStyle(color: Colors.white)),
                                                                   onTap: () {
                                                                     provider.addToPlaylist(name, song);
                                                                     Navigator.pop(context);
                                                                     ScaffoldMessenger.of(context).showSnackBar(
                                                                       SnackBar(content: Text('Added to $name'), duration: const Duration(seconds: 1)),
                                                                     );
                                                                   },
                                                                 );
                                                               },
                                                             );
                                                           },
                                                         ),
                                                       ),
                                                     ),
                                                   );
                                                 },
                                               ),
                                             ],
                                           ),
                                         ),
                                       );
                                     },
                                   ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                ]),
              ),
            ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 150)),
        ],
      ),
    );
  }
}
