import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/audio_provider.dart';
import '../widgets/absolute_glass.dart';
import '../models/song.dart';
import '../widgets/karaoke_lyrics_dialog.dart';
import '../widgets/absolute_glass.dart';

class FullscreenPlayerScreen extends StatefulWidget {
  const FullscreenPlayerScreen({super.key});

  @override
  State<FullscreenPlayerScreen> createState() => _FullscreenPlayerScreenState();
}

class _FullscreenPlayerScreenState extends State<FullscreenPlayerScreen> {
  bool _showQueueSheet = false;

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AudioProvider>();
    final song = p.currentSong;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      extendBody: true,
      body: Stack(
        children: [
          if (song != null)
            Positioned.fill(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: song.thumbnailUrl,
                    fit: BoxFit.cover,
                  ),
                  BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                    child: Container(color: Colors.black.withValues(alpha: 0.7)),
                  ),
                ],
              ),
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 32),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Text(
                        'NOW PLAYING',
                        style: TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 2),
                      ),
                      IconButton(
                        icon: Icon(Icons.queue_music_rounded, color: _showQueueSheet ? const Color(0xFF00F2FE) : Colors.white70),
                        onPressed: () => setState(() => _showQueueSheet = !_showQueueSheet),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        children: [
                           Container(
                             padding: const EdgeInsets.all(20),
                             decoration: BoxDecoration(
                               borderRadius: BorderRadius.circular(28),
                               color: Colors.white.withValues(alpha: 0.05),
                             ),
                             child: Column(
                               children: [
                                 SizedBox(
                                   height: screenHeight * 0.35,
                                   width: screenHeight * 0.35,
                                   child: ClipRRect(
                                     borderRadius: BorderRadius.circular(22),
                                     child: song != null
                                         ? CachedNetworkImage(imageUrl: song.thumbnailUrl, fit: BoxFit.cover)
                                         : Container(color: Colors.grey[900], child: const Icon(Icons.music_note, size: 64, color: Colors.white24)),
                                   ),
                                 ),
                                 const SizedBox(height: 24),
                                 Text(
                                   song?.title ?? 'No Track Playing',
                                   maxLines: 1,
                                   overflow: TextOverflow.ellipsis,
                                   textAlign: TextAlign.center,
                                   style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 20, color: Colors.white),
                                 ),
                                 const SizedBox(height: 4),
                                 Text(
                                   song?.author ?? 'Select a song to stream',
                                   maxLines: 1,
                                   overflow: TextOverflow.ellipsis,
                                   textAlign: TextAlign.center,
                                   style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14),
                                 ),
                               ],
                             ),
                           ),
                           const SizedBox(height: 16),
                           Container(
                             padding: const EdgeInsets.all(16),
                             decoration: BoxDecoration(
                               borderRadius: BorderRadius.circular(22),
                               color: Colors.white.withValues(alpha: 0.05),
                             ),
                             child: Column(
                               children: [
                                 SliderTheme(
                                   data: SliderTheme.of(context).copyWith(
                                     activeTrackColor: Colors.white,
                                     inactiveTrackColor: Colors.white.withValues(alpha: 0.1),
                                     thumbColor: Colors.white,
                                     trackHeight: 4,
                                     thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                   ),
                                   child: Slider(
                                     value: p.position.inSeconds.toDouble().clamp(0.0, p.duration.inSeconds.toDouble() > 0 ? p.duration.inSeconds.toDouble() : 1.0),
                                     max: p.duration.inSeconds.toDouble() > 0 ? p.duration.inSeconds.toDouble() : 1.0,
                                     onChanged: (v) => p.seek(Duration(seconds: v.toInt())),
                                   ),
                                 ),
                                 Padding(
                                   padding: const EdgeInsets.symmetric(horizontal: 8),
                                   child: Row(
                                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                     children: [
                                       Text(_formatDuration(p.position), style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11)),
                                       Text(_formatDuration(p.duration), style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11)),
                                     ],
                                   ),
                                 ),
                               ],
                             ),
                           ),
                           const SizedBox(height: 16),
                           Container(
                             padding: const EdgeInsets.symmetric(vertical: 12),
                             decoration: BoxDecoration(
                               borderRadius: BorderRadius.circular(22),
                               color: Colors.white.withValues(alpha: 0.05),
                             ),
                             child: Row(
                               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                               children: [
                                 IconButton(
                                   icon: Icon(Icons.shuffle_rounded, color: p.isShuffle ? Colors.white : Colors.white.withValues(alpha: 0.5), size: 24),
                                   onPressed: p.toggleShuffle,
                                 ),
                                 IconButton(
                                   icon: const Icon(Icons.skip_previous_rounded, color: Colors.white, size: 32),
                                   onPressed: p.skipPrevious,
                                 ),
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF00F2FE)),
                                    child: IconButton(
                                      iconSize: 34,
                                      icon: p.isLoading
                                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                                          : Icon(p.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.black),
                                      onPressed: p.togglePlayPause,
                                    ),
                                  ),
                                 IconButton(
                                   icon: const Icon(Icons.skip_next_rounded, color: Colors.white, size: 32),
                                   onPressed: p.skipNext,
                                 ),
                                 IconButton(
                                   icon: Icon(Icons.repeat_rounded, color: p.isRepeat ? Colors.white : Colors.white.withValues(alpha: 0.5), size: 24),
                                   onPressed: p.toggleRepeat,
                                 ),
                               ],
                             ),
                           ),
                           const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: Colors.white.withValues(alpha: 0.08)),
                                    child: InkWell(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          PageRouteBuilder(
                                            pageBuilder: (_, __, ___) => KaraokeLyricsDialog(audioProvider: p),
                                            transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
                                          ),
                                        );
                                      },
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.lyrics_outlined, color: Colors.white.withValues(alpha: 0.9), size: 20),
                                          const SizedBox(width: 8),
                                          const Text('Full Lyrics', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                               const SizedBox(width: 12),
                               Expanded(
                                 child: Container(
                                   padding: const EdgeInsets.symmetric(vertical: 12),
                                   decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: Colors.white.withValues(alpha: 0.05)),
                                   child: InkWell(
                                     onTap: () => _showShareDialog(context, song),
                                     child: Row(
                                       mainAxisAlignment: MainAxisAlignment.center,
                                       children: [
                                         Icon(Icons.share_outlined, color: Colors.white.withValues(alpha: 0.8), size: 20),
                                         const SizedBox(width: 8),
                                         const Text('Share', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                                       ],
                                     ),
                                   ),
                                 ),
                               ),
                             ],
                           ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_showQueueSheet)
            GestureDetector(
              onTap: () => setState(() => _showQueueSheet = false),
              child: Container(
                color: Colors.black.withValues(alpha: 0.6),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    height: screenHeight * 0.6,
                    decoration: const BoxDecoration(
                      color: Color(0xFF161616),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('UP NEXT QUEUE', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                              IconButton(
                                icon: const Icon(Icons.close_rounded, color: Colors.white70),
                                onPressed: () => setState(() => _showQueueSheet = false),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: p.queue.isEmpty
                              ? Center(child: Text('Queue is empty', style: TextStyle(color: Colors.white.withValues(alpha: 0.5))))
                              : ListView.builder(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  itemCount: p.queue.length,
                                  itemBuilder: (_, i) {
                                    final s = p.queue[i];
                                    final isCurrent = s.id == song?.id;
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      decoration: BoxDecoration(
                                        color: isCurrent ? Colors.white.withValues(alpha: 0.06) : Colors.transparent,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: ListTile(
                                        leading: ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: CachedNetworkImage(imageUrl: s.thumbnailUrl, width: 44, height: 44, fit: BoxFit.cover),
                                        ),
                                        title: Text(s.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal, color: Colors.white, fontSize: 13)),
                                        subtitle: Text(s.author, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11)),
                                        onTap: () => p.playSong(s, queue: p.queue, index: i),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  String _cleanLyricLine(String line) {
    return line.replaceAll(RegExp(r'\[\d{2}:\d{2}\.\d{2}\]'), '').trim();
  }

  void _showLyricsDialog(BuildContext context, AudioProvider p) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => KaraokeLyricsDialog(audioProvider: p),
      ),
    );
  }

  void _showShareDialog(BuildContext context, Song? song) {
    if (song == null) return;
    final ytMusicUrl = 'https://music.youtube.com/watch?v=${song.id}';
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF161616),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Share Track', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Text('${song.title} - ${song.author}', textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(8)),
                child: Text(ytMusicUrl, style: const TextStyle(color: Color(0xFF00F2FE), fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF282828)),
                    icon: const Icon(Icons.copy, color: Colors.white, size: 18),
                    label: const Text('Copy Link', style: TextStyle(color: Colors.white)),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: ytMusicUrl));
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Link copied to clipboard!')));
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
