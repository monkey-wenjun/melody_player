import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../models/song.dart';
import '../models/album.dart';
import '../models/artist.dart';
import '../services/media_scanner_service.dart';
import '../providers/settings_provider.dart';

enum LibraryTab { songs, albums, artists, folders }

class LibraryProvider extends ChangeNotifier {
  final MediaScannerService _scanner = MediaScannerService();
  SettingsProvider? _settings;

  // 数据
  List<Song> _songs = [];
  List<Album> _albums = [];
  List<Artist> _artists = [];
  List<String> _folders = [];

  // 状态
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  LibraryTab _currentTab = LibraryTab.songs;
  SongSortType _sortType = SongSortType.TITLE;
  OrderType _orderType = OrderType.ASC_OR_SMALLER;

  // Getters
  List<Song> get songs => _filteredAndSortedSongs;
  List<Album> get albums => _filteredAlbums;
  List<Artist> get artists => _filteredArtists;
  List<String> get folders => _folders;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  LibraryTab get currentTab => _currentTab;
  SongSortType get sortType => _sortType;
  OrderType get orderType => _orderType;

  // 是否使用自定义扫描路径
  bool get _useCustomPaths => _settings?.hasCustomScanPaths ?? false;
  List<String> get _customPaths => _settings?.scanPaths ?? [];

  List<Song> get _filteredAndSortedSongs {
    var result = List<Song>.from(_songs);
    
    // 搜索过滤
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      result = result.where((s) =>
        s.title.toLowerCase().contains(query) ||
        s.artist.toLowerCase().contains(query) ||
        s.album.toLowerCase().contains(query)
      ).toList();
    }
    
    // 排序
    result.sort((a, b) {
      int comparison;
      switch (_sortType) {
        case SongSortType.TITLE:
          comparison = a.title.toLowerCase().compareTo(b.title.toLowerCase());
          break;
        case SongSortType.ARTIST:
          comparison = a.artist.toLowerCase().compareTo(b.artist.toLowerCase());
          if (comparison == 0) {
            comparison = a.title.toLowerCase().compareTo(b.title.toLowerCase());
          }
          break;
        case SongSortType.ALBUM:
          comparison = a.album.toLowerCase().compareTo(b.album.toLowerCase());
          if (comparison == 0) {
            comparison = a.trackNumber?.compareTo(b.trackNumber ?? 0) ?? 0;
          }
          break;
        case SongSortType.DURATION:
          comparison = a.duration.compareTo(b.duration);
          break;
        case SongSortType.DATE_ADDED:
        case SongSortType.SIZE:
          comparison = 0;
          break;
        default:
          comparison = a.title.compareTo(b.title);
      }
      return _orderType == OrderType.ASC_OR_SMALLER ? comparison : -comparison;
    });
    
    return result;
  }

  List<Album> get _filteredAlbums {
    if (_searchQuery.isEmpty) return _albums;
    final query = _searchQuery.toLowerCase();
    return _albums.where((a) =>
      a.title.toLowerCase().contains(query) ||
      a.artist.toLowerCase().contains(query)
    ).toList();
  }

  List<Artist> get _filteredArtists {
    if (_searchQuery.isEmpty) return _artists;
    final query = _searchQuery.toLowerCase();
    return _artists.where((a) =>
      a.name.toLowerCase().contains(query)
    ).toList();
  }

  // 设置 SettingsProvider
  void setSettings(SettingsProvider settings) {
    _settings = settings;
  }

  // 扫描音乐库
  Future<void> refreshLibrary() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (_useCustomPaths && _customPaths.isNotEmpty) {
        // 使用自定义路径扫描
        await _scanWithCustomPaths();
      } else {
        // 全盘扫描
        await _scanAll();
      }
      
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 使用自定义路径扫描
  Future<void> _scanWithCustomPaths() async {
    final List<Song> allSongs = [];
    final Set<Album> allAlbums = {};
    final Set<Artist> allArtists = {};

    for (final path in _customPaths) {
      try {
        final songs = await _scanner.scanSongsInPath(path, sortType: _sortType);
        allSongs.addAll(songs);
      } catch (e) {
        print('Scan path error: $path, $e');
      }
    }

    // 去重（基于文件路径）
    final uniqueSongs = <String, Song>{};
    for (final song in allSongs) {
      uniqueSongs[song.uri] = song;
    }
    _songs = uniqueSongs.values.toList();

    // 从歌曲中提取专辑和艺术家
    final albumMap = <String, Album>{};
    final artistMap = <String, Artist>{};

    for (final song in _songs) {
      // 专辑
      if (!albumMap.containsKey(song.album)) {
        albumMap[song.album] = Album(
          id: song.albumId ?? song.album.hashCode.toString(),
          title: song.album,
          artist: song.artist,
          numberOfSongs: 1,
        );
      } else {
        final album = albumMap[song.album]!;
        albumMap[song.album] = Album(
          id: album.id,
          title: album.title,
          artist: album.artist,
          numberOfSongs: album.numberOfSongs + 1,
        );
      }

      // 艺术家
      if (!artistMap.containsKey(song.artist)) {
        artistMap[song.artist] = Artist(
          id: song.artist.hashCode.toString(),
          name: song.artist,
          numberOfAlbums: 1,
          numberOfTracks: 1,
        );
      } else {
        final artist = artistMap[song.artist]!;
        artistMap[song.artist] = Artist(
          id: artist.id,
          name: artist.name,
          numberOfAlbums: artist.numberOfAlbums,
          numberOfTracks: artist.numberOfTracks + 1,
        );
      }
    }

    _albums = albumMap.values.toList();
    _artists = artistMap.values.toList();
    _folders = _customPaths;
  }

  // 全盘扫描
  Future<void> _scanAll() async {
    final results = await Future.wait([
      _scanner.scanSongs(sortType: _sortType),
      _scanner.scanAlbums(),
      _scanner.scanArtists(),
      _scanner.scanFolders(),
    ]);

    _songs = results[0] as List<Song>;
    _albums = results[1] as List<Album>;
    _artists = results[2] as List<Artist>;
    _folders = results[3] as List<String>;
  }

  Future<void> checkPermissionAndScan() async {
    final hasPermission = await _scanner.checkPermission();
    if (!hasPermission) {
      _error = '需要存储权限才能访问音乐文件';
      notifyListeners();
      return;
    }
    await refreshLibrary();
  }

  // 搜索
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    notifyListeners();
  }

  // Tab 切换
  void setCurrentTab(LibraryTab tab) {
    _currentTab = tab;
    notifyListeners();
  }

  // 排序
  void setSortType(SongSortType type) {
    _sortType = type;
    notifyListeners();
  }

  void toggleOrder() {
    _orderType = _orderType == OrderType.ASC_OR_SMALLER
        ? OrderType.DESC_OR_GREATER
        : OrderType.ASC_OR_SMALLER;
    notifyListeners();
  }

  // 获取专辑详情
  Future<List<Song>> getSongsByAlbum(String albumId) async {
    return await _scanner.getSongsByAlbum(albumId);
  }

  // 获取艺术家详情
  // 注意：从已加载的歌曲中按艺术家名称过滤，而不是查询系统媒体库
  // 因为 Artist.id 是 artist.hashCode，与系统媒体库的 ID 不匹配
  Future<List<Song>> getSongsByArtist(String artistId) async {
    // 首先尝试从已加载的歌曲中查找匹配的艺术家
    final artist = _artists.firstWhere(
      (a) => a.id == artistId,
      orElse: () => Artist(id: '', name: '', numberOfAlbums: 0, numberOfTracks: 0),
    );
    
    if (artist.name.isEmpty) {
      // 如果找不到艺术家，回退到系统查询
      return await _scanner.getSongsByArtist(artistId);
    }
    
    // 按艺术家名称过滤已加载的歌曲
    return _songs.where((s) => s.artist == artist.name).toList();
  }

  // 获取封面
  Future<Uint8List?> getArtwork(String id, {ArtworkType type = ArtworkType.AUDIO}) async {
    return await _scanner.getArtwork(id, type: type);
  }

  // 获取文件夹中的歌曲
  List<Song> getSongsByFolder(String folder) {
    return _songs.where((s) => s.uri.startsWith(folder)).toList();
  }
}
