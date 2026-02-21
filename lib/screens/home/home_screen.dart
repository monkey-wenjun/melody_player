import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import '../../providers/player_provider.dart';
import '../../providers/library_provider.dart';
import '../../providers/playlist_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/player/mini_player.dart';
import '../../widgets/common/album_art.dart';
import '../../widgets/update/update_dialog.dart';
import '../library/library_screen.dart';
import '../player/player_screen.dart';
import '../playlist/playlists_screen.dart';
import '../settings/settings_screen.dart';
import 'quick_access_songs_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();
  bool _hasCheckedUpdate = false;

  final List<Widget> _pages = [
    const HomeTab(),
    const LibraryScreen(),
    const PlaylistsScreen(),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // 延迟自动检查更新（避免启动时卡顿）
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && !_hasCheckedUpdate) {
        _hasCheckedUpdate = true;
        _autoCheckUpdate();
      }
    });
  }

  Future<void> _autoCheckUpdate() async {
    // 静默检查更新
    await checkAndShowUpdate(context, manual: false);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.jumpToPage(index);
  }

  // 公共方法供子组件调用
  void onTabChanged(int index) => _onTabChanged(index);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: _pages,
            ),
          ),
          const MiniPlayerProgressBar(),
          MiniPlayer(
            onTap: () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      const PlayerScreen(),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                    // 使用慢速的底部滑入动画，类似播放列表效果
                    const begin = Offset(0.0, 1.0);
                    const end = Offset.zero;
                    const curve = Curves.easeOutCubic;

                    // 延长动画时长到 400ms，更缓慢流畅
                    var tween = Tween(begin: begin, end: end).chain(
                      CurveTween(curve: curve),
                    );

                    var offsetAnimation = animation.drive(tween);

                    return SlideTransition(
                      position: offsetAnimation,
                      child: child,
                    );
                  },
                  transitionDuration: const Duration(milliseconds: 400),
                  reverseTransitionDuration: const Duration(milliseconds: 350),
                ),
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).colorScheme.primary.withOpacity(0.15),
                  Theme.of(context).colorScheme.secondary.withOpacity(0.10),
                  Theme.of(context).colorScheme.tertiary.withOpacity(0.08),
                ],
              ),
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
                  width: 0.5,
                ),
              ),
            ),
            child: NavigationBar(
              selectedIndex: _currentIndex,
              onDestinationSelected: _onTabChanged,
              backgroundColor: Colors.transparent,
              elevation: 0,
              surfaceTintColor: Colors.transparent,
              indicatorColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: '首页',
                ),
                NavigationDestination(
                  icon: Icon(Icons.library_music_outlined),
                  selectedIcon: Icon(Icons.library_music),
                  label: '音乐库',
                ),
                NavigationDestination(
                  icon: Icon(Icons.playlist_play_outlined),
                  selectedIcon: Icon(Icons.playlist_play),
                  label: '歌单',
                ),
                NavigationDestination(
                  icon: Icon(Icons.settings_outlined),
                  selectedIcon: Icon(Icons.settings),
                  label: '设置',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HomeTab extends StatefulWidget {
  const HomeTab({Key? key}) : super(key: key);

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  void _navigateToLibrarySearch() {
    // 获取 HomeScreen 的状态并切换到音乐库页面
    final homeState = context.findAncestorStateOfType<_HomeScreenState>();
    homeState?.onTabChanged(1);
  }

  @override
  void initState() {
    super.initState();
    // 首次进入首页时触发扫描（如果还没有数据）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final libraryProvider = context.read<LibraryProvider>();
      if (libraryProvider.songs.isEmpty && !libraryProvider.isLoading) {
        libraryProvider.checkPermissionAndScan();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 搜索栏
                  InkWell(
                    onTap: () {
                      _navigateToLibrarySearch();
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 12),
                          Icon(
                            Icons.search,
                            color: theme.iconTheme.color?.withOpacity(0.6),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '搜索音乐...',
                            style: TextStyle(
                              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // 快捷入口
                  _buildSectionTitle(context, '快捷入口'),
                  const SizedBox(height: 12),
                  _buildQuickAccess(context),
                  const SizedBox(height: 24),
                  
                  // 最近播放
                  _buildSectionTitle(context, '最近播放'),
                  const SizedBox(height: 12),
                  const RecentSongsList(),
                  const SizedBox(height: 24),
                  
                  // 随机推荐
                  _buildSectionTitle(context, '发现'),
                  const SizedBox(height: 12),
                  _buildDiscoverSection(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildQuickAccess(BuildContext context) {
    final items = [
      _QuickAccessItem(Icons.favorite, '我喜欢的', Colors.red, () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const QuickAccessSongsScreen(
              type: QuickAccessType.favorites,
            ),
          ),
        );
      }),
      _QuickAccessItem(Icons.add_box, '最近添加', Colors.blue, () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const QuickAccessSongsScreen(
              type: QuickAccessType.recentlyAdded,
            ),
          ),
        );
      }),
      _QuickAccessItem(Icons.trending_up, '最多播放', Colors.orange, () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const QuickAccessSongsScreen(
              type: QuickAccessType.mostPlayed,
            ),
          ),
        );
      }),
      _QuickAccessItem(Icons.history, '播放历史', Colors.green, () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const QuickAccessSongsScreen(
              type: QuickAccessType.playHistory,
            ),
          ),
        );
      }),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: items.map((item) => _buildQuickAccessItem(context, item)).toList(),
    );
  }

  Widget _buildQuickAccessItem(BuildContext context, _QuickAccessItem item) {
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 72,
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: item.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(item.icon, color: item.color),
            ),
            const SizedBox(height: 8),
            Text(
              item.label,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiscoverSection(BuildContext context) {
    return Consumer<LibraryProvider>(
      builder: (context, library, child) {
        if (library.songs.isEmpty) {
          return _buildEmptyState(context, '暂无音乐，去扫描一下吧');
        }

        // 随机选择几首歌曲
        final songs = List.of(library.songs)..shuffle();
        final displaySongs = songs.take(5).toList();

        return Column(
          children: displaySongs.map((song) => ListTile(
            contentPadding: EdgeInsets.zero,
            leading: AlbumArt(
              id: song.id,
              size: 48,
              title: song.title,
              artist: song.artist,
            ),
            title: Text(
              song.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(song.artist),
            onTap: () {
              context.read<PlayerProvider>().playSong(song, queue: library.songs);
            },
          )).toList(),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          message,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}

class RecentSongsList extends StatelessWidget {
  const RecentSongsList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<PlaylistProvider>(
      builder: (context, playlistProvider, child) {
        if (playlistProvider.recentSongs.isEmpty) {
          return Container(
            height: 120,
            alignment: Alignment.center,
            child: Text(
              '还没有播放记录',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          );
        }

        return SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: playlistProvider.recentSongs.length,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            itemBuilder: (context, index) {
              final song = playlistProvider.recentSongs[index];
              return GestureDetector(
                onTap: () {
                  context.read<PlayerProvider>().playSong(song);
                },
                child: Container(
                width: 120,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AlbumArt(
                      id: song.id,
                      size: 120,
                      borderRadius: 12,
                      title: song.title,
                      artist: song.artist,
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: 120,
                      child: Text(
                        song.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ),
                    SizedBox(
                      width: 120,
                      child: Text(
                        song.artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              );
            },
          ),
        );
      },
    );
  }
}

class _QuickAccessItem {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  _QuickAccessItem(this.icon, this.label, this.color, this.onTap);
}
