import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/song.dart';
import '../../providers/player_provider.dart';
import '../../providers/playlist_provider.dart';
import '../../providers/library_provider.dart';
import '../../widgets/common/album_art.dart';
import '../../widgets/common/song_list_item.dart';

enum QuickAccessType {
  favorites,
  recentlyAdded,
  mostPlayed,
  playHistory,
}

class QuickAccessSongsScreen extends StatefulWidget {
  final QuickAccessType type;

  const QuickAccessSongsScreen({
    Key? key,
    required this.type,
  }) : super(key: key);

  @override
  State<QuickAccessSongsScreen> createState() => _QuickAccessSongsScreenState();
}

class _QuickAccessSongsScreenState extends State<QuickAccessSongsScreen> {
  List<Song> _songs = [];
  bool _isLoading = true;

  String get _title {
    switch (widget.type) {
      case QuickAccessType.favorites:
        return '我喜欢的';
      case QuickAccessType.recentlyAdded:
        return '最近添加';
      case QuickAccessType.mostPlayed:
        return '最多播放';
      case QuickAccessType.playHistory:
        return '播放历史';
    }
  }

  IconData get _icon {
    switch (widget.type) {
      case QuickAccessType.favorites:
        return Icons.favorite;
      case QuickAccessType.recentlyAdded:
        return Icons.add_box;
      case QuickAccessType.mostPlayed:
        return Icons.trending_up;
      case QuickAccessType.playHistory:
        return Icons.history;
    }
  }

  Color get _color {
    switch (widget.type) {
      case QuickAccessType.favorites:
        return Colors.red;
      case QuickAccessType.recentlyAdded:
        return Colors.blue;
      case QuickAccessType.mostPlayed:
        return Colors.orange;
      case QuickAccessType.playHistory:
        return Colors.green;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadSongs();
  }

  Future<void> _loadSongs() async {
    setState(() {
      _isLoading = true;
    });

    final playlistProvider = context.read<PlaylistProvider>();
    final libraryProvider = context.read<LibraryProvider>();

    List<Song> songs = [];

    switch (widget.type) {
      case QuickAccessType.favorites:
        songs = playlistProvider.favorites;
        break;
      case QuickAccessType.recentlyAdded:
        // 获取所有歌曲并按日期排序（最新的在前）
        songs = List.from(libraryProvider.songs);
        // 注意：由于 Song 模型没有 dateAdded 字段，我们使用 id 作为近似排序
        // 通常新添加的歌曲 id 会更大（如果是自增的）
        songs.sort((a, b) => b.id.compareTo(a.id));
        break;
      case QuickAccessType.mostPlayed:
        songs = await playlistProvider.getMostPlayedSongs(libraryProvider.songs);
        break;
      case QuickAccessType.playHistory:
        songs = playlistProvider.recentSongs;
        break;
    }

    setState(() {
      _songs = songs;
      _isLoading = false;
    });
  }

  Future<void> _playAll() async {
    if (_songs.isEmpty) return;
    await context.read<PlayerProvider>().setPlaylist(_songs, autoPlay: true);
  }

  Future<void> _shufflePlay() async {
    if (_songs.isEmpty) return;
    final shuffled = List<Song>.from(_songs)..shuffle();
    await context.read<PlayerProvider>().setPlaylist(shuffled, autoPlay: true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // 顶部标题区域
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _color.withOpacity(0.8),
                      _color.withOpacity(0.4),
                    ],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      Icon(_icon, size: 64, color: Colors.white),
                      const SizedBox(height: 16),
                      Text(
                        _title,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_songs.length} 首歌曲',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 操作按钮
          if (_songs.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _playAll,
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('播放全部'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _shufflePlay,
                        icon: const Icon(Icons.shuffle),
                        label: const Text('随机播放'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // 歌曲列表
          _isLoading
              ? const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              : _songs.isEmpty
                  ? SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(_icon, size: 64, color: theme.disabledColor),
                            const SizedBox(height: 16),
                            Text(
                              '暂无歌曲',
                              style: theme.textTheme.titleMedium,
                            ),
                          ],
                        ),
                      ),
                    )
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final song = _songs[index];
                          return SongListItem(
                            song: song,
                            onTap: () {
                              context.read<PlayerProvider>().playSong(
                                song,
                                queue: _songs,
                              );
                            },
                          );
                        },
                        childCount: _songs.length,
                      ),
                    ),
        ],
      ),
    );
  }
}
