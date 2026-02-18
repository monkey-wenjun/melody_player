import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../models/song.dart';
import 'album_art.dart';

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
          ? AlbumArt(id: song.id, size: 48, borderRadius: 8)
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
      trailing: trailing ?? Row(
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
        ],
      ),
    );

    // 如果有滑动操作，包装在 Slidable 中
    if (onPlayNext != null || onAddToPlaylist != null || onToggleFavorite != null) {
      content = Slidable(
        endActionPane: ActionPane(
          motion: const BehindMotion(),
          extentRatio: 0.5,
          children: [
            if (onToggleFavorite != null)
              SlidableAction(
                onPressed: (_) => onToggleFavorite!(),
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                icon: Icons.favorite_border,
                label: '收藏',
              ),
            if (onAddToPlaylist != null)
              SlidableAction(
                onPressed: (_) => onAddToPlaylist!(),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                icon: Icons.playlist_add,
                label: '歌单',
              ),
          ],
        ),
        child: content,
      );
    }

    return content;
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
