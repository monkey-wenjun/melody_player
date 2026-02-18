import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/song.dart';
import '../../providers/playlist_provider.dart';

/// 添加到歌单对话框
class AddToPlaylistDialog extends StatefulWidget {
  final Song song;

  const AddToPlaylistDialog({
    Key? key,
    required this.song,
  }) : super(key: key);

  @override
  State<AddToPlaylistDialog> createState() => _AddToPlaylistDialogState();
}

class _AddToPlaylistDialogState extends State<AddToPlaylistDialog> {
  final TextEditingController _nameController = TextEditingController();
  bool _isCreating = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('添加到歌单'),
      content: SizedBox(
        width: double.maxFinite,
        child: Consumer<PlaylistProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (provider.playlists.isEmpty) {
              return _buildEmptyState(theme);
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 新建歌单按钮
                ListTile(
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.add,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  title: const Text('新建歌单'),
                  onTap: _showCreatePlaylistDialog,
                ),
                const Divider(),
                // 歌单列表
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: provider.playlists.length,
                    itemBuilder: (context, index) {
                      final playlist = provider.playlists[index];
                      final isAlreadyInPlaylist =
                          playlist.songs.any((s) => s.id == widget.song.id);

                      return ListTile(
                        leading: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.queue_music),
                        ),
                        title: Text(playlist.name),
                        subtitle: Text('${playlist.songCount} 首歌曲'),
                        trailing: isAlreadyInPlaylist
                            ? Icon(
                                Icons.check,
                                color: theme.colorScheme.primary,
                              )
                            : null,
                        onTap: isAlreadyInPlaylist
                            ? null
                            : () => _addToPlaylist(playlist.id),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
      ],
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.queue_music_outlined,
          size: 48,
          color: theme.colorScheme.outline,
        ),
        const SizedBox(height: 16),
        const Text(
          '还没有歌单',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '创建一个新歌单来收藏歌曲',
          style: TextStyle(
            fontSize: 14,
            color: theme.textTheme.bodySmall?.color,
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _showCreatePlaylistDialog,
          icon: const Icon(Icons.add),
          label: const Text('新建歌单'),
        ),
      ],
    );
  }

  void _showCreatePlaylistDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新建歌单'),
        content: TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            hintText: '歌单名称',
            prefixIcon: Icon(Icons.queue_music),
          ),
          autofocus: true,
          maxLength: 50,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: _createPlaylist,
            child: const Text('创建'),
          ),
        ],
      ),
    );
  }

  Future<void> _createPlaylist() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isCreating = true);

    try {
      final provider = context.read<PlaylistProvider>();
      final playlist = await provider.createPlaylist(name);
      await provider.addSongToPlaylist(playlist.id, widget.song);

      if (mounted) {
        Navigator.pop(context); // 关闭创建对话框
        Navigator.pop(context); // 关闭添加到歌单对话框
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已添加到歌单 "$name"')),
        );
      }
    } finally {
      _nameController.clear();
      setState(() => _isCreating = false);
    }
  }

  Future<void> _addToPlaylist(String playlistId) async {
    final provider = context.read<PlaylistProvider>();
    final playlist = provider.playlists.firstWhere((p) => p.id == playlistId);

    await provider.addSongToPlaylist(playlistId, widget.song);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已添加到歌单 "${playlist.name}"')),
      );
    }
  }
}

/// 显示添加到歌单对话框的辅助函数
void showAddToPlaylistDialog(BuildContext context, Song song) {
  showDialog(
    context: context,
    builder: (context) => AddToPlaylistDialog(song: song),
  );
}
