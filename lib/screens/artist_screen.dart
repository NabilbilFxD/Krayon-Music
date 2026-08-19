import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/audio_provider.dart';

class ArtistScreen extends StatelessWidget {
  const ArtistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AudioProvider>();
    final artistName = p.selectedArtist ?? 'Artist';

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 250,
          pinned: true,
          backgroundColor: const Color(0xFF121212),
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: p.clearArtist,
          ),
          flexibleSpace: LayoutBuilder(
            builder: (context, constraints) {
              final top = constraints.biggest.height;
              final collapseThreshold = MediaQuery.of(context).padding.top + kToolbarHeight;
              // Progress from 0.0 (expanded) to 1.0 (collapsed)
              final progress = ((250 - top) / (250 - collapseThreshold)).clamp(0.0, 1.0);

              return FlexibleSpaceBar(
                titlePadding: EdgeInsets.zero,
                title: Opacity(
                  opacity: progress > 0.5 ? 1.0 : 0.0,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 48, bottom: 18),
                    child: Align(
                      alignment: Alignment.bottomLeft,
                      child: Text(
                        artistName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
                      ),
                    ),
                  ),
                ),
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (p.selectedArtistThumbnail != null)
                      CachedNetworkImage(
                        imageUrl: p.selectedArtistThumbnail!,
                        fit: BoxFit.cover,
                      ),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black26,
                            Colors.transparent,
                            Color(0xFF121212),
                          ],
                          stops: [0.0, 0.5, 1.0],
                        ),
                      ),
                    ),
                    Opacity(
                      opacity: (1.0 - (progress * 1.5)).clamp(0.0, 1.0),
                      child: Align(
                        alignment: Alignment.bottomLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 16, bottom: 16),
                          child: Text(
                            artistName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 32, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Expanded(
                  child: Text('Verified Artist', style: TextStyle(color: Colors.white54, fontSize: 14)),
                ),
                if (p.artistSongs.isNotEmpty)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(16),
                      backgroundColor: const Color(0xFF00F2FE),
                    ),
                    onPressed: () => p.playSong(p.artistSongs.first, queue: p.artistSongs, index: 0),
                    child: const Icon(Icons.play_arrow, size: 32, color: Colors.black),
                  ),
              ],
            ),
          ),
        ),
        if (p.isArtistLoading)
          const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator(color: Color(0xFF00F2FE))),
          )
        else ...[
          if (p.artistAlbums.isNotEmpty) ...[
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(left: 16, top: 32, bottom: 16),
                child: Text('Releases', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: p.artistAlbums.length,
                  itemBuilder: (context, i) {
                    final album = p.artistAlbums[i];
                    return GestureDetector(
                      onTap: () {
                        p.loadAlbum(album['id']);
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: const Color(0xFF121212),
                          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
                          builder: (context) => Consumer<AudioProvider>(
                            builder: (context, provider, _) => DraggableScrollableSheet(
                              initialChildSize: 0.9,
                              maxChildSize: 0.9,
                              minChildSize: 0.5,
                              expand: false,
                              builder: (context, controller) => Column(
                                children: [
                                  const SizedBox(height: 12),
                                  Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
                                  const SizedBox(height: 24),
                                  if (provider.isAlbumLoading)
                                    const Expanded(child: Center(child: CircularProgressIndicator(color: Color(0xFF00F2FE))))
                                  else ...[
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 20),
                                      child: Row(
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: CachedNetworkImage(imageUrl: provider.selectedAlbum?['thumbnailUrl'] ?? '', width: 100, height: 100, fit: BoxFit.cover),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(provider.selectedAlbum?['title'] ?? 'Album', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                                                const SizedBox(height: 4),
                                                Text(provider.selectedAlbum?['artist'] ?? 'Artist', style: const TextStyle(color: Colors.white54, fontSize: 14)),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    Expanded(
                                      child: ListView.builder(
                                        controller: controller,
                                        padding: const EdgeInsets.symmetric(horizontal: 8),
                                        itemCount: provider.albumSongs.length,
                                        itemBuilder: (context, idx) {
                                          final s = provider.albumSongs[idx];
                                          final isLiked = provider.isLiked(s);
                                          return ListTile(
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                            leading: ClipRRect(
                                              borderRadius: BorderRadius.circular(4),
                                              child: CachedNetworkImage(imageUrl: s.thumbnailUrl, width: 48, height: 48, fit: BoxFit.cover, errorWidget: (_, __, ___) => Container(color: Colors.grey[900])),
                                            ),
                                            title: Text(s.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
                                            subtitle: Text(s.author, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white54, fontSize: 13)),
                                            trailing: IconButton(
                                              icon: Icon(isLiked ? Icons.favorite : Icons.favorite_border, color: isLiked ? const Color(0xFF00F2FE) : Colors.white54, size: 20),
                                              onPressed: () => provider.toggleLike(s),
                                            ),
                                            onTap: () => provider.playSong(s, queue: provider.albumSongs, index: idx),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                      child: Container(
                        width: 140,
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: CachedNetworkImage(
                                imageUrl: album['thumbnailUrl'] ?? '',
                                width: 140,
                                height: 140,
                                fit: BoxFit.cover,
                                errorWidget: (_, __, ___) => Container(color: Colors.grey[900], width: 140, height: 140),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(album['title'] ?? 'Unknown Album', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(height: 4),
                            Text(album['year']?.toString() ?? 'Album', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white54, fontSize: 13)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
          if (p.artistSongs.isNotEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(left: 16, top: 32, bottom: 8),
                child: Text('Popular', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              ),
            ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) {
                final song = p.artistSongs[i];
                final isLiked = p.isLiked(song);
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 24, 
                        child: Text('${i + 1}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white54, fontSize: 14, fontWeight: FontWeight.w600))
                      ),
                      const SizedBox(width: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: CachedNetworkImage(
                          imageUrl: song.thumbnailUrl,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => Container(color: Colors.grey[900]),
                        ),
                      ),
                    ],
                  ),
                  title: Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
                  subtitle: Text(song.author, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white54, fontSize: 14)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(isLiked ? Icons.favorite : Icons.favorite_border, color: isLiked ? const Color(0xFF00F2FE) : Colors.white54, size: 20),
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
                  onTap: () => p.playSong(song, queue: p.artistSongs, index: i),
                );
              },
              childCount: p.artistSongs.length > 15 ? 15 : p.artistSongs.length,
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 150)),
        ],
      ],
    );
  }
}
