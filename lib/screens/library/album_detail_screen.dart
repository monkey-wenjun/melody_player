import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';
import '../../models/album.dart';
import '../../models/song.dart';
import '../../providers/library_provider.dart';
import '../../providers/player_provider.dart';
import '../../providers/playlist_provider.dart';
import '../../widgets/common/album_art.dart';
import '../../widgets/common/song_list_item.dart';
import '../../widgets/common/add_to_playlist_dialog.dart';
import '../../widgets/common/song_info_dialog.dart';

class AlbumDetailScreen extends StatefulWidget {
  final Album album;

  const AlbumDetailScreen({
    Key? key,
    required this.album,
  }) : super(key: key);

  @override
  State<AlbumDetailScreen> createState() => _AlbumDetailScreenState();
}

class _AlbumDetailScreenState extends State<AlbumDetailScreen> {
  List<Song> _songs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSongs();
  }

  Future<void> _loadSongs() async {
    final libraryProvider = context.read<LibraryProvider>();
    try {
      final songs = await libraryProvider.getSongsByAlbum(widget.album.id);
      // 按曲目号排序
      songs.sort((a, b) => (a.trackNumber ?? 0).compareTo(b.trackNumber ?? 0));
      setState(() {
        _songs = songs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载歌曲失败: $e')),
        );
      }
    }
  }

  void _playAllSongs({int initialIndex = 0}) {
    if (_songs.isEmpty) return;
    final player = context.read<PlayerProvider>();
    player.setPlaylist(_songs, initialIndex: initialIndex);
  }

  void _shufflePlay() {
    if (_songs.isEmpty) return;
    final player = context.read<PlayerProvider>();
    _songs.shuffle();
    player.setPlaylist(_songs, initialIndex: 0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // 顶部应用栏
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      theme.colorScheme.primary.withOpacity(0.3),
                      theme.colorScheme.surface,
                    ],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 64),
                    Hero(
                      tag: 'album_${widget.album.id}',
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: AlbumArt(
                          id: widget.album.id,
                          type: ArtworkType.ALBUM,
                          size: 160,
                          borderRadius: 0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        widget.album.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.album.artist,
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.textTheme.bodyMedium?.color,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.album.numberOfSongs} 首歌曲',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 播放控制按钮
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _songs.isEmpty ? null : () => _playAllSongs(),
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('播放全部'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _songs.isEmpty ? null : _shufflePlay,
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
                            Icon(
                              Icons.music_off,
                              size: 64,
                              color: theme.disabledColor,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '没有歌曲',
                              style: TextStyle(color: theme.disabledColor),
                            ),
                          ],
                        ),
                      ),
                    )
                  : SliverList.builder(
                      itemCount: _songs.length,
                      itemBuilder: (context, index) {
                        final song = _songs[index];
                        final player = context.watch<PlayerProvider>();
                        final isPlaying =
                            player.currentSong?.id == song.id && player.isPlaying;

                        return SongListItem(
                          song: song,
                          isPlaying: isPlaying,
                          onTap: () => _playAllSongs(initialIndex: index),
                          onToggleFavorite: () async {
                            final playlistProvider =
                                context.read<PlaylistProvider>();
                            await playlistProvider.toggleFavorite(song);
                            final isFav =
                                playlistProvider.favorites.any((s) => s.id == song.id);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content:
                                      Text(isFav ? '已添加到收藏' : '已取消收藏'),
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                            }
                          },
                          onAddToPlaylist: () {
                            showAddToPlaylistDialog(context, song);
                          },
                          onPlayNext: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('已添加到下一首播放'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                        );
                      },
                    ),
        ],
      ),
    );
  }
}
