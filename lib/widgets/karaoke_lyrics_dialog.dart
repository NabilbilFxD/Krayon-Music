import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/audio_provider.dart';

class LyricLine {
  final Duration time;
  final String text;

  LyricLine({required this.time, required this.text});
}

class KaraokeLyricsDialog extends StatefulWidget {
  final AudioProvider audioProvider;

  const KaraokeLyricsDialog({super.key, required this.audioProvider});

  @override
  State<KaraokeLyricsDialog> createState() => _KaraokeLyricsDialogState();
}

class _KaraokeLyricsDialogState extends State<KaraokeLyricsDialog> {
  final ScrollController _scrollController = ScrollController();
  List<LyricLine> _lines = [];
  int _currentIndex = -1;
  Timer? _positionTimer;

  @override
  void initState() {
    super.initState();
    _parseLyrics(widget.audioProvider.lyrics);
    _positionTimer = Timer.periodic(const Duration(milliseconds: 200), (_) => _updateCurrentIndex());
  }

  void _parseLyrics(String rawLyrics) {
    final lrcRegExp = RegExp(r'\[(\d{2}):(\d{2})\.(\d{2,3})\](.*)');
    final lines = rawLyrics.split('\n');
    List<LyricLine> parsed = [];

    for (var line in lines) {
      final match = lrcRegExp.firstMatch(line);
      if (match != null) {
        final minutes = int.parse(match.group(1)!);
        final seconds = int.parse(match.group(2)!);
        final millis = int.parse(match.group(3)!.padRight(3, '0').substring(0, 3));
        final duration = Duration(minutes: minutes, seconds: seconds, milliseconds: millis);
        final text = match.group(4)!.trim();
        if (text.isNotEmpty) {
          parsed.add(LyricLine(time: duration, text: text));
        }
      } else if (line.trim().isNotEmpty && !line.startsWith('[')) {
        parsed.add(LyricLine(time: Duration.zero, text: line.trim()));
      }
    }

    if (parsed.isEmpty) {
      parsed.add(LyricLine(time: Duration.zero, text: rawLyrics));
    }

    setState(() {
      _lines = parsed;
    });
  }

  void _scrollToActiveIndex(int index) {
    if (!_scrollController.hasClients || index < 0) return;
    
    final double itemHeight = 64.0;
    double targetOffset = index * itemHeight;
    
    _scrollController.animateTo(
      targetOffset.clamp(_scrollController.position.minScrollExtent, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  void _updateCurrentIndex() {
    if (!mounted || _lines.isEmpty) return;
    final pos = widget.audioProvider.position;
    int activeIndex = -1;

    for (int i = 0; i < _lines.length; i++) {
      if (pos >= _lines[i].time) {
        activeIndex = i;
      } else {
        break;
      }
    }

    if (activeIndex != _currentIndex) {
      setState(() {
        _currentIndex = activeIndex;
      });
      if (_currentIndex >= 0) {
        _scrollToActiveIndex(_currentIndex);
      }
    }
  }

  @override
  void dispose() {
    _positionTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final song = widget.audioProvider.currentSong;
    final p = widget.audioProvider;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (song != null)
            Positioned.fill(
              child: Opacity(
                opacity: 0.25,
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                  child: CachedNetworkImage(
                    imageUrl: song.thumbnailUrl,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 32),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Text(
                        'LYRICS',
                        style: TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 2),
                      ),
                      const SizedBox(width: 32),
                    ],
                  ),
                ),
            ListenableBuilder(
              listenable: widget.audioProvider,
              builder: (context, _) {
                final p = widget.audioProvider;
                final song = p.currentSong;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.white.withValues(alpha: 0.04),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: song != null
                                ? CachedNetworkImage(imageUrl: song.thumbnailUrl, width: 48, height: 48, fit: BoxFit.cover)
                                : Container(width: 48, height: 48, color: Colors.grey[900], child: const Icon(Icons.music_note, color: Colors.white24)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  song?.title ?? 'No Track Playing',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Colors.white),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  song?.author ?? '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.skip_previous_rounded, color: Colors.white, size: 24),
                            onPressed: p.skipPrevious,
                          ),
                          IconButton(
                            icon: Icon(p.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.white, size: 26),
                            onPressed: p.togglePlayPause,
                          ),
                          IconButton(
                            icon: const Icon(Icons.skip_next_rounded, color: Colors.white, size: 24),
                            onPressed: p.skipNext,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: Colors.white,
                          inactiveTrackColor: Colors.white.withValues(alpha: 0.1),
                          thumbColor: Colors.white,
                          trackHeight: 2,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4),
                        ),
                        child: Slider(
                          value: p.position.inSeconds.toDouble().clamp(0.0, p.duration.inSeconds.toDouble() > 0 ? p.duration.inSeconds.toDouble() : 1.0),
                          max: p.duration.inSeconds.toDouble() > 0 ? p.duration.inSeconds.toDouble() : 1.0,
                          onChanged: (v) => p.seek(Duration(seconds: v.toInt())),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_formatDuration(p.position), style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11)),
                            Text(_formatDuration(p.duration), style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11)),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            Expanded(
              child: _lines.isEmpty
                  ? Center(child: Text(widget.audioProvider.lyrics, textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withValues(alpha: 0.7))))
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final double centeringPadding = constraints.maxHeight / 2 - 32.0;
                        return ListView.builder(
                          controller: _scrollController,
                          itemCount: _lines.length,
                          itemExtent: 64.0,
                          padding: EdgeInsets.only(top: centeringPadding, bottom: centeringPadding),
                          itemBuilder: (context, index) {
                            final isSelected = index == _currentIndex;
                            final isBelowCurrent = index > _currentIndex;
                            final distance = (index - _currentIndex).abs();
                            
                            double opacity = 0.4;
                            double blurRadius = 0.0;
                            double scale = 1.0;
                            
                            if (isSelected) {
                              opacity = 1.0;
                              blurRadius = 0.0;
                              scale = 1.05;
                            } else if (isBelowCurrent) {
                              if (distance == 1) {
                                opacity = 0.5;
                                blurRadius = 1.5;
                              } else if (distance == 2) {
                                opacity = 0.35;
                                blurRadius = 3.0;
                              } else {
                                opacity = 0.25;
                                blurRadius = 4.0;
                              }
                            } else {
                              opacity = distance == 1 ? 0.6 : 0.4;
                            }

                            return GestureDetector(
                              onTap: () {
                                if (_lines[index].time > Duration.zero) {
                                  p.seek(_lines[index].time);
                                }
                              },
                              child: Container(
                                height: 64.0,
                                alignment: Alignment.center,
                                padding: const EdgeInsets.symmetric(horizontal: 24),
                                child: AnimatedDefaultTextStyle(
                                  duration: const Duration(milliseconds: 300),
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : Colors.white.withValues(alpha: opacity),
                                    fontSize: isSelected ? 22 : 16,
                                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                                    letterSpacing: -0.5,
                                    height: 1.2,
                                    shadows: isSelected
                                        ? [
                                            const Shadow(color: Colors.white, blurRadius: 16.0),
                                            const Shadow(color: Colors.white70, blurRadius: 8.0),
                                          ]
                                        : [],
                                  ),
                                  child: Text(
                                    _lines[index].text,
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
