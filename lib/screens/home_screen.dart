import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/song.dart';
import '../services/youtube_service.dart';
import '../providers/audio_provider.dart';
import '../auth_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final YouTubeService _yt = YouTubeService();
  List<Song> _trending = [];
  bool _loading = true;
  String _selectedCategory = 'All';

  final Map<String, String> _categoryQueries = {
    'All': 'top global hits music 2026',
    'Music': 'trending music pop rock hits',
    'Podcasts': 'popular full podcast episodes english',
    'Charts': 'top 50 global charts music',
    'Mood': 'chill relaxed lofi songs',
  };

  @override
  void initState() {
    super.initState();
    _loadCategory('All');
  }

  Future<void> _loadCategory(String category) async {
    setState(() {
      _selectedCategory = category;
      _loading = true;
    });
    final query = _categoryQueries[category] ?? 'top global hits music 2026';
    final results = await _yt.searchSongs(query);
    setState(() {
      _trending = results.length > 3 ? results : results + results + results;
      _loading = false;
    });
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AudioProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: const Color(0xFF121212),
            floating: true,
            pinned: false,
            elevation: 0,
            title: GestureDetector(
              onTap: () {
                final user = FirebaseAuth.instance.currentUser;
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: const Color(0xFF1E1E1E),
                    title: const Text('Profile', style: TextStyle(color: Colors.white)),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
                          child: user?.photoURL == null ? const Icon(Icons.person, size: 30) : null,
                        ),
                        const SizedBox(height: 12),
                        Text(user?.displayName ?? 'User', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(user?.email ?? '', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close', style: TextStyle(color: Colors.white70)),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey),
                        onPressed: () async {
                          Navigator.pop(context);
                          await AuthService().switchAccount();
                        },
                        child: const Text('Switch Account'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        onPressed: () async {
                          Navigator.pop(context);
                          await AuthService().signOut();
                        },
                        child: const Text('Log Out'),
                      ),
                    ],
                  ),
                );
              },
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundImage: FirebaseAuth.instance.currentUser?.photoURL != null
                        ? NetworkImage(FirebaseAuth.instance.currentUser!.photoURL!)
                        : null,
                    child: FirebaseAuth.instance.currentUser?.photoURL == null
                        ? const Icon(Icons.person, size: 16)
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    FirebaseAuth.instance.currentUser?.displayName?.split(' ').first ?? 'Profile',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_none_rounded, color: Colors.white),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('No new notifications'), duration: Duration(seconds: 1)),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.history_rounded, color: Colors.white),
                onPressed: () async {
                  await provider.refreshHistory();
                  print("HISTORY SONGS COUNT: ${provider.historySongs.length}");
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: const Color(0xFF161616),
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
                    builder: (context) {
                      final p = context.watch<AudioProvider>();
                      return Container(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Listening History', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                if (p.historySongs.isNotEmpty)
                                  TextButton(
                                    onPressed: () => p.clearHistory(),
                                    child: const Text('Clear All', style: TextStyle(color: Colors.redAccent)),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Expanded(
                              child: p.historySongs.isEmpty
                                  ? const Center(
                                      child: Text('Recently played songs will appear here', style: TextStyle(color: Colors.white54)),
                                    )
                                  : ListView.builder(
                                      itemCount: p.historySongs.length,
                                      itemBuilder: (context, index) {
                                        final song = p.historySongs[index];
                                        return ListTile(
                                          leading: ClipRRect(
                                            borderRadius: BorderRadius.circular(6),
                                            child: CachedNetworkImage(
                                              imageUrl: song.thumbnailUrl,
                                              width: 40,
                                              height: 40,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                          title: Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white)),
                                          subtitle: Text(song.author, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white54)),
                                          onTap: () {
                                            p.playSong(song, queue: p.historySongs, index: index);
                                            Navigator.pop(context);
                                          },
                                        );
                                      },
                                    ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.settings_outlined, color: Colors.white),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: const Color(0xFF161616),
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
                    builder: (context) => Wrap(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Settings', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 16),

                              ListTile(
                                leading: const Icon(Icons.timer_outlined, color: Colors.white70),
                                title: const Text('Sleep Timer', style: TextStyle(color: Colors.white)),
                                subtitle: Text(
                                  provider.sleepTimeRemaining != null
                                      ? '${provider.sleepTimeRemaining!.inMinutes} mins remaining'
                                      : (provider.sleepOnTrackEnd ? 'After current track' : 'Off'),
                                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                                ),
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => SimpleDialog(
                                      backgroundColor: const Color(0xFF1E1E1E),
                                      title: const Text('Set Sleep Timer', style: TextStyle(color: Colors.white)),
                                      children: [
                                        SimpleDialogOption(
                                          onPressed: () { provider.setSleepTimer(null, onTrackEnd: true); Navigator.pop(context); },
                                          child: const Text('After current track', style: TextStyle(color: Colors.white70)),
                                        ),
                                        SimpleDialogOption(
                                          onPressed: () { provider.setSleepTimer(const Duration(minutes: 15)); Navigator.pop(context); },
                                          child: const Text('15 Minutes', style: TextStyle(color: Colors.white70)),
                                        ),
                                        SimpleDialogOption(
                                          onPressed: () { provider.setSleepTimer(const Duration(minutes: 30)); Navigator.pop(context); },
                                          child: const Text('30 Minutes', style: TextStyle(color: Colors.white70)),
                                        ),
                                        SimpleDialogOption(
                                          onPressed: () { provider.setSleepTimer(const Duration(minutes: 60)); Navigator.pop(context); },
                                          child: const Text('1 Hour', style: TextStyle(color: Colors.white70)),
                                        ),
                                        SimpleDialogOption(
                                          onPressed: () {
                                            Navigator.pop(context);
                                            final controller = TextEditingController();
                                            showDialog(
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                backgroundColor: const Color(0xFF1E1E1E),
                                                title: const Text('Custom Sleep Timer', style: TextStyle(color: Colors.white)),
                                                content: TextField(
                                                  controller: controller,
                                                  keyboardType: TextInputType.number,
                                                  style: const TextStyle(color: Colors.white),
                                                  decoration: const InputDecoration(
                                                    hintText: 'Enter minutes',
                                                    hintStyle: TextStyle(color: Colors.white54),
                                                  ),
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () => Navigator.pop(context),
                                                    child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
                                                  ),
                                                  TextButton(
                                                    onPressed: () {
                                                      final mins = int.tryParse(controller.text);
                                                      if (mins != null && mins > 0) {
                                                        provider.setSleepTimer(Duration(minutes: mins));
                                                        Navigator.pop(context);
                                                      }
                                                    },
                                                    child: const Text('Set', style: TextStyle(color: Color(0xFF00F2FE))),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                          child: const Text('Custom Minutes...', style: TextStyle(color: Color(0xFF00F2FE))),
                                        ),
                                        if (provider.sleepTimeRemaining != null || provider.sleepOnTrackEnd)
                                          SimpleDialogOption(
                                            onPressed: () { provider.cancelSleepTimer(); Navigator.pop(context); },
                                            child: const Text('Turn Off', style: TextStyle(color: Colors.redAccent)),
                                          ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                              StatefulBuilder(
                                builder: (context, setModalState) {
                                  return ListTile(
                                    leading: const Icon(Icons.autorenew_rounded, color: Colors.white70),
                                    title: const Text('Autoplay Related Tracks', style: TextStyle(color: Colors.white)),
                                    subtitle: const Text('Automatically queue similar songs', style: TextStyle(color: Colors.white54, fontSize: 12)),
                                    trailing: Switch(
                                      value: provider.autoPlayRelated,
                                      activeColor: const Color(0xFF00F2FE),
                                      onChanged: (val) {
                                        provider.toggleAutoPlayRelated();
                                        setModalState(() {});
                                      },
                                    ),
                                  );
                                },
                              ),
                              ListTile(
                                leading: const Icon(Icons.info_outline, color: Colors.white70),
                                title: const Text('About Krayon Music', style: TextStyle(color: Colors.white)),
                                subtitle: const Text('Version 2.6.0 Spatial', style: TextStyle(color: Colors.white54, fontSize: 12)),
                                onTap: () {},
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                   children: [
                     _buildChip('All', _selectedCategory == 'All'),
                     const SizedBox(width: 8),
                     _buildChip('Music', _selectedCategory == 'Music'),
                     const SizedBox(width: 8),
                     _buildChip('Podcasts', _selectedCategory == 'Podcasts'),
                     const SizedBox(width: 8),
                     _buildChip('Charts', _selectedCategory == 'Charts'),
                     const SizedBox(width: 8),
                     _buildChip('Mood', _selectedCategory == 'Mood'),
                   ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            sliver: SliverToBoxAdapter(
              child: const Text(
                'Recommended for you',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          if (_loading)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFF00F2FE)),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final song = _trending[index];
                  final isLiked = provider.isLiked(song);
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => provider.playSong(song, queue: _trending, index: index),
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
                                onPressed: () => provider.toggleLike(song),
                              ),
                            ],
                           ),
                         ),
                       ),
                     ),
                   );
                },
                childCount: _trending.length,
              ),
            ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 150)),
        ],
      ),
    );
  }

  Widget _buildChip(String label, bool isSelected) {
    return GestureDetector(
      onTap: () => _loadCategory(label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : const Color(0xFF282828),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.black : Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
