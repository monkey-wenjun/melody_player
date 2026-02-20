import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';
import '../../models/song.dart';
import '../../providers/playlist_provider.dart';
import 'album_art.dart';
import 'add_to_playlist_dialog.dart';
import 'song_info_dialog.dart';

/// 检查音频格式是否支持
bool _isFormatSupported(String extension) {
  var ext = extension.toLowerCase().trim();
  if (ext.startsWith('.')) {
    ext = ext.substring(1);
  }
  final supported = ['mp3', 'aac', 'm4a', 'flac', 'wav', 'ogg', 'opus'];
  return supported.contains(ext);
}

class SongListItem extends StatelessWidget {
  final Song song;
  final VoidCallback? onTap;
  final VoidCallback? onPlayNext;
  final VoidCallback? onAddToPlaylist;
  final VoidCallback? onToggleFavorite;
  final bool isPlaying;
  final bool showAlbumArt;
  final Widget? trailing;

  const SongListItem({
    Key? key,
    required this.song,
    this.onTap,
    this.onPlayNext,
    this.onAddToPlaylist,
    this.onToggleFavorite,
    this.isPlaying = false,
    this.showAlbumArt = true,
    this.trailing,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Widget content = ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: showAlbumArt
          ? AlbumArt(
              id: song.id,
              size: 48,
              borderRadius: 8,
              title: song.title,
              artist: song.artist,
            )
          : null,
      title: Text(
        song.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 15,
          fontWeight: isPlaying ? FontWeight.w600 : FontWeight.normal,
          color: isPlaying ? theme.colorScheme.primary : theme.textTheme.bodyLarge?.color,
        ),
      ),
      subtitle: Text(
        '${song.artist} · ${song.album}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 13,
          color: isPlaying 
              ? theme.colorScheme.primary.withOpacity(0.7)
              : theme.textTheme.bodyMedium?.color,
        ),
      ),
      trailing: trailing ?? _buildDefaultTrailing(context),
    );

    // 如果有滑动操作，包装在 Slidable 中
    if (onPlayNext != null || onAddToPlaylist != null || onToggleFavorite != null) {
      content = Slidable(
        endActionPane: ActionPane(
          motion: const BehindMotion(),
          extentRatio: 0.5,
          children: [
            if (onToggleFavorite != null)
              CustomSlidableAction(
                onPressed: (_) => onToggleFavorite!(),
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Consumer<PlaylistProvider>(
                      builder: (context, provider, child) {
                        final isFav = provider.favorites.any((s) => s.id == song.id);
                        return Icon(
                          isFav ? Icons.favorite : Icons.favorite_border,
                          size: 24,
                        );
                      },
                    ),
                    const SizedBox(height: 4),
                    Consumer<PlaylistProvider>(
                      builder: (context, provider, child) {
                        final isFav = provider.favorites.any((s) => s.id == song.id);
                        return Text(
                          isFav ? '取消收藏' : '收藏',
                          style: const TextStyle(fontSize: 12),
                        );
                      },
                    ),
                  ],
                ),
              ),
            if (onAddToPlaylist != null)
              CustomSlidableAction(
                onPressed: (_) => onAddToPlaylist!(),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.playlist_add, size: 24),
                    SizedBox(height: 4),
                    Text(
                      '歌单',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
          ],
        ),
        child: content,
      );
    }

    return content;
  }

  Widget _buildDefaultTrailing(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 格式标签（不支持的格式）
        if (!_isFormatSupported(song.fileExtension))
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: theme.colorScheme.primary.withOpacity(0.3),
                width: 0.5,
              ),
            ),
            child: Text(
              song.fileExtension.toUpperCase(),
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        Text(
          song.durationText,
          style: TextStyle(
            fontSize: 12,
            color: theme.textTheme.bodySmall?.color,
          ),
        ),
        // 更多选项按钮
        IconButton(
          icon: const Icon(Icons.more_vert, size: 20),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          onPressed: () => _showMoreOptions(context),
        ),
      ],
    );
  }

  void _showMoreOptions(BuildContext context) {
    final playlistProvider = context.read<PlaylistProvider>();
    final isFavorite = playlistProvider.favorites.any((s) => s.id == song.id);

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 歌曲预览
            ListTile(
              leading: AlbumArt(
                id: song.id,
                size: 48,
                borderRadius: 8,
                title: song.title,
                artist: song.artist,
              ),
              title: Text(
                song.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                song.artist,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Divider(),
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
            // 下一首播放
            if (onPlayNext != null)
              ListTile(
                leading: const Icon(Icons.play_circle_outline),
                title: const Text('下一首播放'),
                onTap: () {
                  Navigator.pop(context);
                  onPlayNext!();
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
}

class SongListTile extends StatelessWidget {
  final Song song;
  final int index;
  final VoidCallback? onTap;
  final bool isPlaying;

  const SongListTile({
    Key? key,
    required this.song,
    required this.index,
    this.onTap,
    this.isPlaying = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      leading: SizedBox(
        width: 40,
        child: Center(
          child: isPlaying
              ? Icon(
                  Icons.volume_up,
                  size: 20,
                  color: theme.colorScheme.primary,
                )
              : Text(
                  '$index',
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.textTheme.bodySmall?.color,
                  ),
                ),
        ),
      ),
      title: Text(
        song.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 15,
          fontWeight: isPlaying ? FontWeight.w600 : FontWeight.normal,
          color: isPlaying ? theme.colorScheme.primary : null,
        ),
      ),
      subtitle: Text(
        song.artist,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodySmall,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 格式标签（不支持的格式）
          if (!_isFormatSupported(song.fileExtension))
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: theme.colorScheme.primary.withOpacity(0.3),
                  width: 0.5,
                ),
              ),
              child: Text(
                song.fileExtension.toUpperCase(),
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          Text(
            song.durationText,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
