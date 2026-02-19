import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/song.dart';
import '../../models/playlist.dart';
import '../../providers/playlist_provider.dart';
import '../../providers/player_provider.dart';
import '../../widgets/common/song_list_item.dart';
import '../../widgets/common/album_art.dart';
import '../../widgets/common/add_to_playlist_dialog.dart';

/// 歌单封面组件 - 随机显示歌单中的一首歌曲封面
class PlaylistCover extends StatelessWidget {
  final Playlist playlist;
  final double size;

  const PlaylistCover({
    Key? key,
    required this.playlist,
    this.size = 48,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 如果歌单有歌曲，随机选择一首显示封面
    final songId = playlist.songs.isNotEmpty
        ? playlist.songs.first.id
        : null;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: songId != null
          ? AlbumArt(
              id: songId,
              size: size,
              borderRadius: 0,
            )
          : Icon(
              Icons.playlist_play,
              color: Theme.of(context).colorScheme.primary,
            ),
    );
  }
}

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
                  leading: PlaylistCover(playlist: playlist),
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
    final playlist = context.read<PlaylistProvider>().playlists
        .firstWhere((p) => p.id == playlistId);
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlaylistDetailScreen(playlist: playlist),
      ),
    );
  }
}

/// 歌单详情页面
class PlaylistDetailScreen extends StatelessWidget {
  final Playlist playlist;

  const PlaylistDetailScreen({
    Key? key,
    required this.playlist,
  }) : super(key: key);

  String get _totalDurationText {
    final totalSeconds = playlist.totalDuration ~/ 1000;
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    
    if (hours > 0) {
      return '$hours小时${minutes}分钟';
    } else {
      return '$minutes分钟';
    }
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
                      theme.colorScheme.primary.withOpacity(0.8),
                      theme.colorScheme.primary.withOpacity(0.4),
                    ],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      Icon(
                        Icons.queue_music,
                        size: 64,
                        color: Colors.white.withOpacity(0.8),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        playlist.name,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${playlist.songCount} 首歌曲 · $_totalDurationText',
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
          if (playlist.songs.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          context.read<PlayerProvider>().setPlaylist(
                            playlist.songs,
                            autoPlay: true,
                          );
                        },
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
                        onPressed: () {
                          final shuffled = List<Song>.from(playlist.songs)..shuffle();
                          context.read<PlayerProvider>().setPlaylist(
                            shuffled,
                            autoPlay: true,
                          );
                        },
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
          Consumer<PlaylistProvider>(
            builder: (context, provider, child) {
              // 重新获取最新的歌单数据
              final currentPlaylist = provider.playlists
                  .firstWhere((p) => p.id == playlist.id, orElse: () => playlist);
              
              if (currentPlaylist.songs.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.music_off, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('歌单为空', style: TextStyle(color: Colors.grey)),
                        SizedBox(height: 8),
                        Text('快去添加歌曲吧', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final song = currentPlaylist.songs[index];
                    return SongListItem(
                      song: song,
                      onTap: () {
                        context.read<PlayerProvider>().setPlaylist(
                          currentPlaylist.songs,
                          initialIndex: index,
                        );
                      },
                      onToggleFavorite: () => provider.toggleFavorite(song),
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
                      trailing: IconButton(
                        icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                        onPressed: () => _removeSong(context, currentPlaylist.id, song.id),
                      ),
                    );
                  },
                  childCount: currentPlaylist.songs.length,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _removeSong(BuildContext context, String playlistId, String songId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('移除歌曲'),
        content: const Text('确定要从歌单中移除这首歌曲吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<PlaylistProvider>().removeSongFromPlaylist(playlistId, songId);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('已从歌单中移除'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('移除'),
          ),
        ],
      ),
    );
  }
}
