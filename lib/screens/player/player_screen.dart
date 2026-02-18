import 'package:flutter/material.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:provider/provider.dart';
import '../../providers/player_provider.dart';
import '../../providers/playlist_provider.dart';
import '../../widgets/common/album_art.dart';
import '../../widgets/common/add_to_playlist_dialog.dart';
import '../../widgets/common/song_info_dialog.dart';
import '../../widgets/player/player_controls.dart';

class PlayerScreen extends StatelessWidget {
  const PlayerScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1A2E) : theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Consumer<PlayerProvider>(
          builder: (context, player, child) {
            final song = player.currentSong;
            
            if (song == null) {
              return const Center(child: Text('没有正在播放的歌曲'));
            }

            return Column(
              children: [
                // 顶部导航
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.keyboard_arrow_down, size: 32),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Text(
                        '正在播放',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      IconButton(
                        icon: const Icon(Icons.more_vert),
                        onPressed: () => _showMoreOptions(context, song),
                      ),
                    ],
                  ),
                ),

                // 专辑封面
                Expanded(
                  flex: 3,
                  child: Center(
                    child: Hero(
                      tag: 'album_art_${song.id}',
                      child: LargeAlbumArt(id: song.id, size: 280),
                    ),
                  ),
                ),

                // 歌曲信息
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          song.title,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          song.artist,
                          style: TextStyle(
                            fontSize: 16,
                            color: theme.textTheme.bodyMedium?.color,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (song.album.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            song.album,
                            style: TextStyle(
                              fontSize: 14,
                              color: theme.textTheme.bodySmall?.color,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // 进度条
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: ProgressBar(
                    progress: player.position,
                    total: player.duration,
                    onSeek: player.seek,
                    barHeight: 4,
                    thumbRadius: 6,
                    thumbGlowRadius: 12,
                    timeLabelLocation: TimeLabelLocation.below,
                    timeLabelTextStyle: TextStyle(
                      fontSize: 12,
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // 错误提示
                if (player.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.errorContainer.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 16,
                            color: theme.colorScheme.error,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              player.errorMessage!,
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.error,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.close,
                              size: 16,
                              color: theme.colorScheme.error,
                            ),
                            onPressed: player.clearError,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),
                  ),

                // 播放控制
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(
                        player.getPlaybackModeIcon(),
                        color: theme.colorScheme.primary,
                      ),
                      tooltip: player.getPlaybackModeText(),
                      onPressed: player.cyclePlaybackMode,
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: const Icon(Icons.skip_previous, size: 36),
                      onPressed: player.previous,
                    ),
                    const SizedBox(width: 16),
                    PlayPauseButton(
                      isPlaying: player.isPlaying,
                      onPressed: player.togglePlay,
                      size: 72,
                      iconSize: 36,
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: const Icon(Icons.skip_next, size: 36),
                      onPressed: player.next,
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: const Icon(Icons.queue_music),
                      onPressed: () => _showPlaylist(context),
                    ),
                  ],
                ),

                const SizedBox(height: 32),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showMoreOptions(BuildContext context, var song) {
    final playlistProvider = context.read<PlaylistProvider>();
    final isFavorite = playlistProvider.favorites.any((s) => s.id == song.id);

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 收藏
            ListTile(
              leading: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: isFavorite ? Colors.red : null,
              ),
              title: Text(isFavorite ? '取消收藏' : '收藏'),
              onTap: () {
                Navigator.pop(context);
                playlistProvider.toggleFavorite(song);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isFavorite ? '已取消收藏' : '已添加到收藏'),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
            ),
            // 添加到歌单
            ListTile(
              leading: const Icon(Icons.playlist_add),
              title: const Text('添加到歌单'),
              onTap: () {
                Navigator.pop(context);
                showAddToPlaylistDialog(context, song);
              },
            ),
            // 歌曲信息
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('歌曲信息'),
              onTap: () {
                Navigator.pop(context);
                showSongInfoDialog(context, song);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showPlaylist(BuildContext context) {
    final player = context.read<PlayerProvider>();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '播放队列 (${player.playlist.length})',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.clear_all, size: 18),
                      label: const Text('清空'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: player.playlist.length,
                  itemBuilder: (context, index) {
                    final song = player.playlist[index];
                    final isCurrent = player.currentIndex == index;
                    
                    return ListTile(
                      leading: SizedBox(
                        width: 40,
                        child: isCurrent
                            ? Icon(Icons.volume_up, color: Theme.of(context).colorScheme.primary)
                            : Text('${index + 1}'),
                      ),
                      title: Text(
                        song.title,
                        style: TextStyle(
                          fontWeight: isCurrent ? FontWeight.bold : null,
                          color: isCurrent ? Theme.of(context).colorScheme.primary : null,
                        ),
                      ),
                      subtitle: Text(song.artist),
                      trailing: IconButton(
                        icon: const Icon(Icons.remove_circle_outline, size: 20),
                        onPressed: () {},
                      ),
                      onTap: () {
                        player.playAtIndex(index);
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
