import 'package:firebase_auth/firebase_auth.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:media_kit/media_kit.dart';
import 'package:device_preview/device_preview.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:firebase_core/firebase_core.dart';
import 'providers/audio_provider.dart';
import 'screens/home_screen.dart';
import 'screens/library_screen.dart';
import 'screens/search_screen.dart';
import 'screens/artist_screen.dart';
import 'screens/player_fullscreen_screen.dart';
import 'screens/login_screen.dart';
import 'widgets/player_bar.dart';
import 'widgets/absolute_glass.dart';
import 'auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (e) {
    print("Firebase init error: $e");
  }
  runApp(const SonicVibeApp());
}

class NavigationProvider with ChangeNotifier {
  int _currentIndex = 0;
  int get currentIndex => _currentIndex;

  void setIndex(int index) {
    _currentIndex = index;
    notifyListeners();
  }
}

class SonicVibeApp extends StatelessWidget {
  const SonicVibeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AudioProvider()),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
      ],
      child: MaterialApp(
        title: 'SonicVibe Spatial Audio',
        debugShowCheckedModeBanner: false,
        // useInheritedMediaQuery: true,
        // locale: DevicePreview.locale(context),
        // builder: (context, child) {
        //   return MediaQuery(
        //     data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(1.0)),
        //     child: DevicePreview.appBuilder(context, child!),
        //   );
        // },
        theme: ThemeData.dark(useMaterial3: true).copyWith(
          scaffoldBackgroundColor: const Color(0xFF121212),
          colorScheme: const ColorScheme.dark(
            surface: Color(0xFF121212),
            primary: Colors.white,
            secondary: Colors.white70,
          ),
        ),
        home: StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }
            if (snapshot.hasData) return const MasterLayout();
            return LoginScreen();
          },
        ),
      ),
    );
  }
}

class MasterLayout extends StatelessWidget {
  const MasterLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 700;
        
        if (isMobile) {
          return const _SpatialMobileLayout();
        }
        
        return const _DesktopLayout();
      },
    );
  }
}

class _DesktopLayout extends StatelessWidget {
  const _DesktopLayout();

  @override
  Widget build(BuildContext context) {
    final nav = context.watch<NavigationProvider>();
    final audio = context.watch<AudioProvider>();

    final screens = [
      const HomeScreen(),
      audio.selectedArtist != null ? const ArtistScreen() : const SearchScreen(),
      const LibraryScreen(),
    ];

    return Scaffold(
      body: Row(
        children: [
          const _LeftSidebar(),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFF131722), Color(0xFF0B0D12)],
                      ),
                    ),
                    child: IndexedStack(
                      index: nav.currentIndex,
                      children: screens,
                    ),
                  ),
                ),
                const PlayerBar(),
              ],
            ),
          ),
          const _RightQueuePanel(),
        ],
      ),
    );
  }
}

class _SpatialMobileLayout extends StatelessWidget {
  const _SpatialMobileLayout();

  @override
  Widget build(BuildContext context) {
    final nav = context.watch<NavigationProvider>();
    final audio = context.watch<AudioProvider>();

    final screens = [
      const HomeScreen(),
      audio.selectedArtist != null ? const ArtistScreen() : const SearchScreen(),
      const LibraryScreen(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      extendBody: true,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          SafeArea(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(begin: const Offset(0.03, 0), end: Offset.zero).animate(CurvedAnimation(parent: animation, curve: Curves.easeInOutCubicEmphasized)),
                  child: child,
                ),
              ),
              child: KeyedSubtree(
                key: ValueKey<int>(nav.currentIndex),
                child: screens[nav.currentIndex],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (audio.currentSong != null) _MiniPlayer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: _NavigationDock(),
          ),
        ],
      ),
    );
  }
}

class _MarqueeText extends StatefulWidget {
  final String text;
  final TextStyle style;

  const _MarqueeText({required this.text, required this.style});

  @override
  State<_MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<_MarqueeText> with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;
  bool _isScrolling = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startScroll());
  }

  void _startScroll() async {
    while (mounted) {
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) break;
      if (_scrollController.hasClients && _scrollController.position.maxScrollExtent > 0) {
        await _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: (_scrollController.position.maxScrollExtent * 20).toInt()),
          curve: Curves.linear,
        );
        if (!mounted) break;
        await Future.delayed(const Duration(seconds: 2));
        if (!mounted) break;
        _scrollController.jumpTo(0);
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      child: Text(
        widget.text,
        style: widget.style,
      ),
    );
  }
}

class _MiniPlayer extends StatelessWidget {
  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final audio = context.watch<AudioProvider>();
    final song = audio.currentSong;

    if (song == null) return const SizedBox.shrink();

    final maxVal = audio.duration.inSeconds.toDouble().clamp(1.0, double.infinity);
    final curVal = audio.position.inSeconds.toDouble().clamp(0.0, maxVal);
    final progress = maxVal > 0 ? curVal / maxVal : 0.0;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const FullscreenPlayerScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.0, 1.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(parent: animation, curve: Curves.easeInOutCubic)),
                child: child,
              );
            },
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF181818),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    song.thumbnailUrl,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  _MarqueeText(
                    text: song.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                      const SizedBox(height: 2),
                      Text(
                        song.author,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _formatDuration(audio.position),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.skip_previous, color: Colors.white, size: 24),
                  onPressed: audio.skipPrevious,
                  constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                  padding: EdgeInsets.zero,
                ),
                IconButton(
                  icon: audio.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Icon(
                          audio.isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                          size: 28,
                        ),
                  onPressed: audio.togglePlayPause,
                  constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                  padding: EdgeInsets.zero,
                ),
                IconButton(
                  icon: const Icon(Icons.skip_next, color: Colors.white, size: 24),
                  onPressed: audio.skipNext,
                  constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 3,
                backgroundColor: Colors.white.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation<Color>(
                  Color.lerp(
                    const Color(0xFF00F2FE),
                    const Color(0xFF9B51E0),
                    progress,
                  )!,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavigationDock extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final nav = context.watch<NavigationProvider>();
    final audio = context.watch<AudioProvider>();

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF181818),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _SpatialNavButton(
            icon: Icons.explore,
            label: 'Explore',
            isSelected: nav.currentIndex == 0,
            onTap: () {
              audio.clearArtist();
              nav.setIndex(0);
            },
          ),
          _SpatialNavButton(
            icon: Icons.search,
            label: 'Search',
            isSelected: nav.currentIndex == 1,
            onTap: () {
              audio.clearArtist();
              nav.setIndex(1);
            },
          ),
          _SpatialNavButton(
            icon: Icons.library_music,
            label: 'Library',
            isSelected: nav.currentIndex == 2,
            onTap: () {
              audio.clearArtist();
              nav.setIndex(2);
            },
          ),
        ],
      ),
    );
  }
}

class _SpatialNavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SpatialNavButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: isSelected ? Colors.white.withValues(alpha: 0.1) : Colors.transparent,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.5),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.5),
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeftSidebar extends StatelessWidget {
  const _LeftSidebar();

  @override
  Widget build(BuildContext context) {
    final nav = context.watch<NavigationProvider>();
    final audio = context.watch<AudioProvider>();

    return Container(
      width: 260,
      decoration: const BoxDecoration(
        color: Color(0xFF0F1218),
        border: Border(right: BorderSide(color: Color(0x1FFFFFFF), width: 1)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF00F2FE), Color(0xFF9B51E0)]),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFF00F2FE).withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 4)),
                  ],
                ),
                child: const Icon(Icons.bolt_rounded, color: Colors.black, size: 26),
              ),
              const SizedBox(width: 14),
              const Text(
                'SONICVIBE',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 36),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Text('DISCOVER', style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          ),
          _NavItem(icon: Icons.explore_rounded, label: 'Explore', isSelected: nav.currentIndex == 0, onTap: () { audio.clearArtist(); nav.setIndex(0); }),
          _NavItem(icon: Icons.search_rounded, label: 'Search Engine', isSelected: nav.currentIndex == 1, onTap: () { audio.clearArtist(); nav.setIndex(1); }),
          _NavItem(icon: Icons.library_music_rounded, label: 'My Library', isSelected: nav.currentIndex == 2, onTap: () { audio.clearArtist(); nav.setIndex(2); }),
          const SizedBox(height: 24),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Text('QUICK ARTISTS', style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          ),
          _ArtistShortcut(name: 'rumahsakit', onTap: () => audio.loadArtist('rumahsakit', 'rumahsakit')),
          _ArtistShortcut(name: 'Ed Sheeran', onTap: () => audio.loadArtist('Ed Sheeran', 'Ed Sheeran')),
          _ArtistShortcut(name: 'Lofi Girl', onTap: () => audio.loadArtist('Lofi Girl', 'Lofi Girl')),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0x0FFFFFFF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0x1FFFFFFF)),
            ),
            child: Row(
              children: [
                Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF00F2FE), shape: BoxShape.circle)),
                const SizedBox(width: 10),
                const Text('Lossless Hi-Fi', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                const Spacer(),
                const Text('24-bit/96kHz', style: TextStyle(color: Color(0xFF00F2FE), fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ArtistShortcut extends StatelessWidget {
  final String name;
  final VoidCallback onTap;

  const _ArtistShortcut({required this.name, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          child: Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: const Color(0xFF00F2FE).withValues(alpha: 0.2),
                child: Text(name[0], style: const TextStyle(color: Color(0xFF00F2FE), fontSize: 12, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 12),
              Text(name, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({required this.icon, required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? const LinearGradient(colors: [Color(0x3300F2FE), Color(0x119B51E0)])
                  : null,
              borderRadius: BorderRadius.circular(12),
              border: isSelected ? Border.all(color: const Color(0x4400F2FE)) : null,
              boxShadow: isSelected ? [BoxShadow(color: const Color(0xFF00F2FE).withValues(alpha: 0.15), blurRadius: 10)] : null,
            ),
            child: Row(
              children: [
                Icon(icon, color: isSelected ? const Color(0xFF00F2FE) : Colors.white60, size: 20),
                const SizedBox(width: 14),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RightQueuePanel extends StatelessWidget {
  const _RightQueuePanel();

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AudioProvider>();
    final song = p.currentSong;

    return Container(
      width: 280,
      decoration: const BoxDecoration(
        color: Color(0xFF0F1218),
        border: Border(left: BorderSide(color: Color(0x1FFFFFFF), width: 1)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('NOW PLAYING', style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          const SizedBox(height: 20),
          Center(
            child: Container(
              width: 200, height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF00F2FE).withValues(alpha: 0.2), blurRadius: 20, spreadRadius: 2),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: song != null
                    ? Image.network(song.thumbnailUrl, fit: BoxFit.cover)
                    : Container(color: Colors.grey[900], child: const Icon(Icons.music_note, size: 48, color: Colors.white24)),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(song?.title ?? 'No Track Playing', maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          Text(song?.author ?? 'Select a song to start', maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white60, fontSize: 13)),
          const SizedBox(height: 30),
          const Text('UP NEXT QUEUE', style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          const SizedBox(height: 12),
          Expanded(
            child: p.queue.isEmpty
                ? const Center(child: Text('Queue is empty', style: TextStyle(color: Colors.white38, fontSize: 13)))
                : ListView.builder(
                    itemCount: p.queue.length,
                    itemBuilder: (_, i) {
                      final s = p.queue[i];
                      final isCurrent = s.id == song?.id;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: isCurrent ? const Color(0x2200F2FE) : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: isCurrent ? Border.all(color: const Color(0x4400F2FE)) : null,
                        ),
                        child: ListTile(
                          dense: true,
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.network(s.thumbnailUrl, width: 36, height: 36, fit: BoxFit.cover),
                          ),
                          title: Text(s.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal, fontSize: 13)),
                          subtitle: Text(s.author, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11)),
                          onTap: () => p.playSong(s, queue: p.queue, index: i),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
