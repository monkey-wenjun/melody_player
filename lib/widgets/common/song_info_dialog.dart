import 'dart:io';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/song.dart';

/// 歌曲信息对话框
class SongInfoDialog extends StatefulWidget {
  final Song song;

  const SongInfoDialog({
    Key? key,
    required this.song,
  }) : super(key: key);

  @override
  State<SongInfoDialog> createState() => _SongInfoDialogState();
}

class _SongInfoDialogState extends State<SongInfoDialog> {
  FileStat? _fileStat;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFileInfo();
  }

  Future<void> _loadFileInfo() async {
    try {
      final file = File(widget.song.uri);
      if (await file.exists()) {
        final stat = await file.stat();
        setState(() {
          _fileStat = stat;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      developer.log('无法获取文件信息: $e', name: 'SongInfoDialog');
      setState(() => _isLoading = false);
    }
  }

  String _formatFileSize(int? bytes) {
    if (bytes == null) return '未知';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '未知';
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label 已复制到剪贴板'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('歌曲信息'),
      content: SizedBox(
        width: double.maxFinite,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 歌曲标题
                    _buildInfoSection(
                      context,
                      title: '标题',
                      content: widget.song.title,
                      icon: Icons.music_note,
                      copyable: true,
                    ),
                    const Divider(height: 24),
                    // 艺术家
                    _buildInfoSection(
                      context,
                      title: '艺术家',
                      content: widget.song.artist,
                      icon: Icons.person,
                      copyable: true,
                    ),
                    const Divider(height: 24),
                    // 专辑
                    _buildInfoSection(
                      context,
                      title: '专辑',
                      content: widget.song.album,
                      icon: Icons.album,
                      copyable: true,
                    ),
                    const Divider(height: 24),
                    // 时长
                    _buildInfoSection(
                      context,
                      title: '时长',
                      content: widget.song.durationText,
                      icon: Icons.timer,
                    ),
                    const Divider(height: 24),
                    // 格式
                    _buildInfoSection(
                      context,
                      title: '格式',
                      content: widget.song.fileExtension.toUpperCase(),
                      icon: Icons.audio_file,
                    ),
                    if (_fileStat != null) ...[
                      const Divider(height: 24),
                      // 文件大小
                      _buildInfoSection(
                        context,
                        title: '文件大小',
                        content: _formatFileSize(_fileStat!.size),
                        icon: Icons.data_usage,
                      ),
                      const Divider(height: 24),
                      // 修改时间
                      _buildInfoSection(
                        context,
                        title: '修改时间',
                        content: _formatDateTime(_fileStat!.modified),
                        icon: Icons.calendar_today,
                      ),
                    ],
                    const Divider(height: 24),
                    // 文件路径
                    _buildInfoSection(
                      context,
                      title: '文件路径',
                      content: widget.song.uri,
                      icon: Icons.folder,
                      copyable: true,
                      isPath: true,
                    ),
                  ],
                ),
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('关闭'),
        ),
      ],
    );
  }

  Widget _buildInfoSection(
    BuildContext context, {
    required String title,
    required String content,
    required IconData icon,
    bool copyable = false,
    bool isPath = false,
  }) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: copyable ? () => _copyToClipboard(content, title) : null,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: 20,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.textTheme.bodySmall?.color,
                        ),
                      ),
                      if (copyable) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.copy,
                          size: 12,
                          color: theme.colorScheme.primary.withOpacity(0.6),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    content,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isPath ? FontWeight.normal : FontWeight.w500,
                    ),
                    maxLines: isPath ? 3 : 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 显示歌曲信息对话框的辅助函数
void showSongInfoDialog(BuildContext context, Song song) {
  showDialog(
    context: context,
    builder: (context) => SongInfoDialog(song: song),
  );
}
