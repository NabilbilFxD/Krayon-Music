import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/audio_provider.dart';

class LyricLine {
  final Duration timestamp;
  final String text;
  
  LyricLine(this.timestamp, this.text);
}

class LyricsScreen extends StatefulWidget {
  const LyricsScreen({super.key});

  @override
  State<LyricsScreen> createState() => _LyricsScreenState();
}

class _LyricsScreenState extends State<LyricsScreen> with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  List<LyricLine> _parsedLyrics = [];
  int _activeIndex = -1;
  int? _hoveredIndex;
  late AnimationController _animController;
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat(reverse: true);
    _shimmerController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))..repeat();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _animController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  List<LyricLine> _parseLRC(String lrcText) {
    final lines = <LyricLine>[];
    final regex = RegExp(r'\[(\d+):(\d+\.\d+)\](.*)');
    
    for (var line in lrcText.split('\n')) {
      final match = regex.firstMatch(line);
      if (match != null) {
        final minutes = int.parse(match.group(1)!);
        final seconds = double.parse(match.group(2)!);
        final text = match.group(3)!.trim();
        
        if (text.isNotEmpty) {
          final timestamp = Duration(minutes: minutes, milliseconds: (seconds * 1000).round());
          lines.add(LyricLine(timestamp, text));
        }
      }
    }
    lines.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return lines;
  }

  int _findActiveIndex(Duration position, List<LyricLine> lyrics) {
    if (lyrics.isEmpty) return -1;
    for (int i = lyrics.length - 1; i >= 0; i--) {
      if (position >= lyrics[i].timestamp) return i;
    }
    return -1;
  }

  void _scrollToActiveLine(int index, double viewportHeight) {
    if (index < 0 || !_scrollController.hasClients) return;
    const itemHeight = 68.0;
    final targetOffset = (index * itemHeight) - (viewportHeight / 2) + (itemHeight / 2);
    _scrollController.animateTo(
      targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 600),
      curve: Curves.fastOutSlowIn,
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AudioProvider>();
    final song = p.currentSong;
    final screenHeight = MediaQuery.of(context).size.height;
    final viewportPadding = screenHeight * 0.4;
    
    if (!p.isLyricsLoading && _parsedLyrics.isEmpty && p.lyrics.isNotEmpty) {
      _parsedLyrics = _parseLRC(p.lyrics);
    }
    
    final newActiveIndex = _findActiveIndex(p.position, _parsedLyrics);
    if (newActiveIndex != _activeIndex) {
      _activeIndex = newActiveIndex;
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToActiveLine(_activeIndex, screenHeight));
    }

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(song?.title ?? 'Lyrics', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 17, color: Colors.white)),
      ),
      body: Stack(
        children: [
          if (song != null)
            Positioned.fill(
              child: Image.network(
                song.thumbnailUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox(),
              ),
            ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
              child: Container(color: Colors.black.withValues(alpha: 0.6)),
            ),
          ),
          AnimatedBuilder(
            animation: _animController,
            builder: (_, __) => Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(_animController.value * 0.5 - 0.25, 0.5),
                  radius: 1.2,
                  colors: [Colors.white.withValues(alpha: 0.1), Colors.transparent],
                ),
              ),
            ),
          ),
          p.isLyricsLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.white70))
              : ListView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.only(top: viewportPadding + kToolbarHeight + 40, bottom: viewportPadding, left: 48, right: 48),
                  itemCount: _parsedLyrics.length,
                  itemBuilder: (context, index) {
                    final lyric = _parsedLyrics[index];
                    final isActive = index == _activeIndex;
                    final isHovered = index == _hoveredIndex;
                    return MouseRegion(
                      onEnter: (_) => setState(() => _hoveredIndex = index),
                      onExit: (_) => setState(() => _hoveredIndex = null),
                      child: GestureDetector(
                        onTap: () => p.seek(lyric.timestamp),
                        child: AnimatedScale(
                          duration: const Duration(milliseconds: 350),
                          scale: isActive ? 1.0 : 0.95,
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 350),
                            opacity: isActive ? 1.0 : (isHovered ? 0.7 : 0.35),
                            child: Container(
                              alignment: Alignment.centerLeft,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: isActive
                                  ? AnimatedBuilder(
                                      animation: _shimmerController,
                                      builder: (context, child) {
                                        return ShaderMask(
                                          shaderCallback: (bounds) {
                                            return LinearGradient(
                                              colors: const [Colors.white54, Colors.white, Colors.white54],
                                              stops: const [0.0, 0.5, 1.0],
                                              begin: Alignment(-1.0 + (_shimmerController.value * 3), 0.0),
                                              end: Alignment(0.0 + (_shimmerController.value * 3), 0.0),
                                            ).createShader(bounds);
                                          },
                                          blendMode: BlendMode.srcIn,
                                          child: Text(
                                            lyric.text,
                                            style: const TextStyle(
                                              fontSize: 32,
                                              fontWeight: FontWeight.w700,
                                              height: 1.4,
                                            ),
                                          ),
                                        );
                                      },
                                    )
                                  : Text(
                                      lyric.text,
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w400,
                                        color: Colors.white,
                                        height: 1.4,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }
}
