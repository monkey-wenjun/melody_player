import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/playlist_provider.dart';
import '../../providers/player_provider.dart';
import '../../widgets/common/song_list_item.dart';
import '../../widgets/common/add_to_playlist_dialog.dart';

class PlaylistsScreen extends StatelessWidget {
  const PlaylistsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('歌单'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreatePlaylistDialog(context),
          ),
        ],
      ),
      body: Consumer<PlaylistProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView(
            children: [
              // 收藏
              _buildSectionHeader(context, '我的收藏'),
              ListTile(
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.red, Colors.pink],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.favorite, color: Colors.white),
                ),
                title: const Text('我喜欢的音乐'),
                subtitle: Text('${provider.favorites.length} 首歌曲'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showFavoriteSongs(context),
              ),
              
              const Divider(),
              
              // 自定义歌单
              _buildSectionHeader(context, '我的歌单'),
              if (provider.playlists.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: Text('还没有歌单，点击右上角创建')),
                )
              else
                ...provider.playlists.map((playlist) => ListTile(
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.playlist_play,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  title: Text(playlist.name),
                  subtitle: Text('${playlist.songCount} 首歌曲'),
                  trailing: PopupMenuButton(
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'rename',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 8),
                            Text('重命名'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: Colors.red),
                            SizedBox(width: 8),
                            Text('删除', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'rename') {
                        _showRenameDialog(context, playlist.id, playlist.name);
                      } else if (value == 'delete') {
                        _showDeleteConfirm(context, playlist.id, playlist.name);
                      }
                    },
                  ),
                  onTap: () => _showPlaylistDetail(context, playlist.id),
                )),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  void _showCreatePlaylistDialog(BuildContext context) {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新建歌单'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '歌单名称',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                await context.read<PlaylistProvider>().createPlaylist(controller.text);
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('创建'),
          ),
        ],
      ),
    );
  }

  void _showRenameDialog(BuildContext context, String id, String currentName) {
    final controller = TextEditingController(text: currentName);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重命名歌单'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                await context.read<PlaylistProvider>().renamePlaylist(id, controller.text);
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context, String id, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除歌单'),
        content: Text('确定要删除 "$name" 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              await context.read<PlaylistProvider>().deletePlaylist(id);
              if (context.mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  void _showFavoriteSongs(BuildContext context) {
    final provider = context.read<PlaylistProvider>();
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('我喜欢的音乐'),
          ),
          body: Consumer<PlaylistProvider>(
            builder: (context, provider, child) {
              if (provider.favorites.isEmpty) {
                return const Center(child: Text('还没有收藏的歌曲'));
              }

              return ListView.builder(
                itemCount: provider.favorites.length,
                itemBuilder: (context, index) {
                  final song = provider.favorites[index];
                  return SongListItem(
                    song: song,
                    onTap: () {
                      context.read<PlayerProvider>().setPlaylist(
                        provider.favorites,
                        initialIndex: index,
                      );
                    },
                    onToggleFavorite: () async {
                      await provider.toggleFavorite(song);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('已取消收藏'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      }
                    },
                    onAddToPlaylist: () {
                      showAddToPlaylistDialog(context, song);
                    },
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _showPlaylistDetail(BuildContext context, String playlistId) {
    // 实现歌单详情页面
  }
}
