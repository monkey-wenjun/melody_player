import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';
import '../../models/artist.dart';
import '../../models/album.dart';
import '../../models/song.dart';
import '../../providers/library_provider.dart';
import '../../providers/player_provider.dart';
import '../../providers/playlist_provider.dart';
import '../../widgets/common/album_art.dart';
import '../../widgets/common/song_list_item.dart';
import '../../widgets/common/add_to_playlist_dialog.dart';
import '../../widgets/common/song_info_dialog.dart';
import 'album_detail_screen.dart';

class ArtistDetailScreen extends StatefulWidget {
  final Artist artist;

  const ArtistDetailScreen({
    Key? key,
    required this.artist,
  }) : super(key: key);

  @override
  State<ArtistDetailScreen> createState() => _ArtistDetailScreenState();
}

class _ArtistDetailScreenState extends State<ArtistDetailScreen> {
  List<Song> _songs = [];
  List<Album> _albums = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final libraryProvider = context.read<LibraryProvider>();
    try {
      final songs = await libraryProvider.getSongsByArtist(widget.artist.id);
      
      // 从歌曲中提取专辑信息
      final Map<String, Album> albumMap = {};
      for (final song in songs) {
        final key = '${song.album}_${song.artist}';
        if (!albumMap.containsKey(key)) {
          albumMap[key] = Album(
            id: song.albumId ?? song.album.hashCode.toString(),
            title: song.album,
            artist: song.artist,
            numberOfSongs: 1,
          );
        } else {
          final album = albumMap[key]!;
          albumMap[key] = Album(
            id: album.id,
            title: album.title,
            artist: album.artist,
            numberOfSongs: album.numberOfSongs + 1,
          );
        }
      }

      setState(() {
        _songs = songs;
        _albums = albumMap.values.toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载数据失败: $e')),
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

  void _navigateToAlbum(Album album) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AlbumDetailScreen(album: album),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primary.withOpacity(0.06),
              theme.colorScheme.secondary.withOpacity(0.04),
              theme.colorScheme.tertiary.withOpacity(0.02),
            ],
          ),
        ),
        child: CustomScrollView(
          slivers: [
          // 顶部应用栏
          SliverAppBar(
            expandedHeight: 280,
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
                    CircleAvatar(
                      radius: 60,
                      backgroundColor:
                          theme.colorScheme.primary.withOpacity(0.1),
                      child: Text(
                        widget.artist.name.isNotEmpty
                            ? widget.artist.name[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        widget.artist.name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.artist.numberOfTracks} 首歌曲 · ${widget.artist.numberOfAlbums} 张专辑',
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.textTheme.bodyMedium?.color,
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

          // 专辑列表
          if (_albums.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Text(
                  '专辑',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.titleLarge?.color,
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 180,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: _albums.length,
                  itemBuilder: (context, index) {
                    final album = _albums[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: InkWell(
                        onTap: () => _navigateToAlbum(album),
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          width: 130,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: AlbumArt(
                                  id: album.id,
                                  type: ArtworkType.ALBUM,
                                  size: 130,
                                  borderRadius: 0,
                                  title: album.title,
                                  artist: album.artist,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: Text(
                                  album.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: Text(
                                  '${album.numberOfSongs} 首',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: theme.textTheme.bodySmall?.color,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],

          // 所有歌曲标题
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Text(
                '所有歌曲',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.titleLarge?.color,
                ),
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
                            final isFav = playlistProvider.favorites
                                .any((s) => s.id == song.id);
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
      ),
    );
  }
}
