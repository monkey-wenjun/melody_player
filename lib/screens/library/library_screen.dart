import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';
import '../../models/song.dart';
import '../../providers/library_provider.dart';
import '../../providers/player_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/common/song_list_item.dart';
import '../../widgets/common/album_art.dart';
import '../folder_picker/folder_picker_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({Key? key}) : super(key: key);

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> with SingleTickerProviderStateMixin {
  TabController? _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController!.addListener(() {
      context.read<LibraryProvider>().setCurrentTab(LibraryTab.values[_tabController!.index]);
    });
    
    // 初始化时传递 SettingsProvider 并开始扫描
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final libraryProvider = context.read<LibraryProvider>();
      final settingsProvider = context.read<SettingsProvider>();
      libraryProvider.setSettings(settingsProvider);
      libraryProvider.checkPermissionAndScan();
    });
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('音乐库'),
        actions: [
          IconButton(
            icon: const Icon(Icons.folder_open),
            onPressed: _showFolderOptions,
            tooltip: '选择目录',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<LibraryProvider>().refreshLibrary(),
          ),
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: _showSortOptions,
          ),
        ],
        bottom: _tabController != null ? TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '歌曲'),
            Tab(text: '专辑'),
            Tab(text: '艺术家'),
          ],
        ) : null,
      ),
      body: Column(
        children: [
          // 扫描路径提示
          Consumer2<LibraryProvider, SettingsProvider>(
            builder: (context, library, settings, child) {
              if (library.isLoading) return const SizedBox.shrink();
              
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      settings.hasCustomScanPaths ? Icons.folder : Icons.music_note,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        settings.hasCustomScanPaths
                            ? '自定义目录: ${settings.scanPaths.length} 个位置'
                            : '扫描所有音乐文件（不含通话录音等）',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.primary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (settings.hasCustomScanPaths)
                      GestureDetector(
                        onTap: () => _clearCustomPaths(),
                        child: Icon(
                          Icons.clear,
                          size: 16,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                  ],
                ),
              );
            },
          ),

          // 搜索栏
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '搜索...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          context.read<LibraryProvider>().clearSearch();
                        },
                      )
                    : null,
                filled: true,
                fillColor: theme.colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) => context.read<LibraryProvider>().setSearchQuery(value),
            ),
          ),
          
          // 内容区域
          Expanded(
            child: Consumer<LibraryProvider>(
              builder: (context, library, child) {
                if (library.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (library.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
                        const SizedBox(height: 16),
                        Text(library.error!),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => library.checkPermissionAndScan(),
                          child: const Text('重试'),
                        ),
                      ],
                    ),
                  );
                }

                return _tabController != null ? TabBarView(
                  controller: _tabController,
                  children: [
                    _SongsTab(songs: library.songs),
                    _AlbumsTab(albums: library.albums),
                    _ArtistsTab(artists: library.artists),
                  ],
                ) : const Center(child: CircularProgressIndicator());
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showFolderOptions() {
    final settings = context.read<SettingsProvider>();
    
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              title: Text('扫描目录', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            ListTile(
              leading: const Icon(Icons.folder),
              title: const Text('选择音乐目录'),
              subtitle: const Text('只扫描选定的文件夹'),
              onTap: () async {
                Navigator.pop(context);
                final result = await Navigator.push<List<String>>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FolderPickerScreen(
                      selectedPaths: settings.scanPaths,
                    ),
                  ),
                );
                if (result != null) {
                  await settings.clearScanPaths();
                  for (final path in result) {
                    await settings.addScanPath(path);
                  }
                  // 重新扫描
                  if (context.mounted) {
                    context.read<LibraryProvider>().refreshLibrary();
                  }
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.refresh),
              title: const Text('扫描所有音乐'),
              subtitle: const Text('自动扫描设备中的音乐'),
              onTap: () async {
                await settings.clearScanPaths();
                if (context.mounted) {
                  Navigator.pop(context);
                  context.read<LibraryProvider>().refreshLibrary();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _clearCustomPaths() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清除自定义目录'),
        content: const Text('确定要清除自定义目录设置，恢复扫描所有音乐吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确定'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await context.read<SettingsProvider>().clearScanPaths();
      if (context.mounted) {
        context.read<LibraryProvider>().refreshLibrary();
      }
    }
  }

  void _showSortOptions() {
    final library = context.read<LibraryProvider>();
    
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              title: Text('排序方式', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            ListTile(
              leading: const Icon(Icons.title),
              title: const Text('标题'),
              trailing: library.sortType == SongSortType.TITLE
                  ? const Icon(Icons.check, color: Colors.blue)
                  : null,
              onTap: () {
                library.setSortType(SongSortType.TITLE);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('艺术家'),
              trailing: library.sortType == SongSortType.ARTIST
                  ? const Icon(Icons.check, color: Colors.blue)
                  : null,
              onTap: () {
                library.setSortType(SongSortType.ARTIST);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.album),
              title: const Text('专辑'),
              trailing: library.sortType == SongSortType.ALBUM
                  ? const Icon(Icons.check, color: Colors.blue)
                  : null,
              onTap: () {
                library.setSortType(SongSortType.ALBUM);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.timer),
              title: const Text('时长'),
              trailing: library.sortType == SongSortType.DURATION
                  ? const Icon(Icons.check, color: Colors.blue)
                  : null,
              onTap: () {
                library.setSortType(SongSortType.DURATION);
                Navigator.pop(context);
              },
            ),
            const Divider(),
            ListTile(
              leading: Icon(
                library.orderType == OrderType.ASC_OR_SMALLER
                    ? Icons.arrow_upward
                    : Icons.arrow_downward,
              ),
              title: Text(library.orderType == OrderType.ASC_OR_SMALLER ? '升序' : '降序'),
              onTap: () {
                library.toggleOrder();
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SongsTab extends StatelessWidget {
  final List<Song> songs;

  const _SongsTab({required this.songs});

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();

    if (songs.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.music_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('没有找到音乐文件', style: TextStyle(color: Colors.grey)),
            SizedBox(height: 8),
            Text('请检查扫描目录设置', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: songs.length,
      itemBuilder: (context, index) {
        final song = songs[index];
        final isPlaying = player.currentSong?.id == song.id && player.isPlaying;

        return SongListItem(
          song: song,
          isPlaying: isPlaying,
          onTap: () {
            player.setPlaylist(songs, initialIndex: index);
          },
        );
      },
    );
  }
}

class _AlbumsTab extends StatelessWidget {
  final List albums;

  const _AlbumsTab({required this.albums});

  @override
  Widget build(BuildContext context) {
    if (albums.isEmpty) {
      return const Center(child: Text('没有专辑'));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: albums.length,
      itemBuilder: (context, index) {
        final album = albums[index];
        return _AlbumCard(album: album);
      },
    );
  }
}

class _AlbumCard extends StatelessWidget {
  final album;

  const _AlbumCard({required this.album});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        // 导航到专辑详情
      },
      borderRadius: BorderRadius.circular(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AlbumArt(
                id: album.id,
                type: ArtworkType.ALBUM,
                size: double.infinity,
                borderRadius: 0,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            album.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          Text(
            album.artist,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ArtistsTab extends StatelessWidget {
  final List artists;

  const _ArtistsTab({required this.artists});

  @override
  Widget build(BuildContext context) {
    if (artists.isEmpty) {
      return const Center(child: Text('没有艺术家'));
    }

    return ListView.builder(
      itemCount: artists.length,
      itemBuilder: (context, index) {
        final artist = artists[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            child: Text(
              artist.name.isNotEmpty ? artist.name[0].toUpperCase() : '?',
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
          ),
          title: Text(artist.name),
          subtitle: Text('${artist.numberOfTracks} 首歌曲 · ${artist.numberOfAlbums} 张专辑'),
          onTap: () {
            // 导航到艺术家详情
          },
        );
      },
    );
  }
}
