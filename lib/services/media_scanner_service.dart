import 'dart:typed_data';
import 'dart:io';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ffmpeg_kit_flutter_audio/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_audio/media_information.dart';
import '../models/song.dart';
import '../models/album.dart';
import '../models/artist.dart';

class MediaScannerService {
  static final MediaScannerService _instance = MediaScannerService._internal();
  factory MediaScannerService() => _instance;
  MediaScannerService._internal();

  final OnAudioQuery _audioQuery = OnAudioQuery();

  // 需要排除的目录关键词（小写）
  final List<String> _excludedPaths = [
    'call', 'recorder', 'recording', 'recordings',
    'voice', 'voices', 'voicerecorder',
    'whatsapp', 'wechat', 'qq',
    'notifications', 'ringtones', 'alarms', 'podcasts',
    'android/data', 'android/obb', '.cache', '.thumbnails',
    'download/weixin', 'download/qq', 'tencent',
  ];

  // 支持的音频格式 - 注意：just_audio 不直接支持 WMA
  // WMA 需要转码或使用其他播放器
  final List<String> _supportedFormats = [
    'mp3', 'aac', 'm4a', 'flac', 'wav', 'ogg', 'opus', 'ape', 'dsd'
  ];
  
  // 额外支持的格式（可以列出但可能无法播放）
  final List<String> _extraFormats = ['wma'];

  Future<bool> requestPermission() async {
    // Android 13+ (API 33+) 使用新的权限模型
    if (await Permission.audio.request().isGranted) {
      return true;
    }
    // Android 12 及以下使用存储权限
    if (await Permission.storage.request().isGranted) {
      return true;
    }
    // 尝试请求管理外部存储权限（用于访问所有文件）
    if (await Permission.manageExternalStorage.request().isGranted) {
      return true;
    }
    return false;
  }

  Future<bool> checkPermission() async {
    if (await Permission.audio.isGranted) return true;
    if (await Permission.storage.isGranted) return true;
    if (await Permission.manageExternalStorage.isGranted) return true;
    return false;
  }

  /// 检查路径是否应该被排除
  bool _isExcludedPath(String? path) {
    if (path == null) return true;
    final lowerPath = path.toLowerCase();
    for (final excluded in _excludedPaths) {
      if (lowerPath.contains(excluded)) {
        return true;
      }
    }
    return false;
  }

  /// 检查是否为有效歌曲
  bool _isValidSong(SongModel model, {String? targetPath, int minDuration = 30000}) {
    // 必须有 URI
    if (model.uri == null || model.uri!.isEmpty) return false;
    
    // 检查文件路径是否被排除
    final filePath = model.data ?? model.uri ?? '';
    if (_isExcludedPath(filePath)) return false;
    
    // 如果指定了目标路径，只包含该路径下的文件
    if (targetPath != null && targetPath.isNotEmpty) {
      if (!filePath.toLowerCase().startsWith(targetPath.toLowerCase())) {
        return false;
      }
    }
    
    // 检查时长（过滤铃声/提示音）
    if (model.duration != null && model.duration! < minDuration) {
      return false;
    }
    
    // 检查文件扩展名
    final ext = (model.fileExtension).toLowerCase();
    if (!_supportedFormats.contains(ext)) {
      return false;
    }
    
    return true;
  }

  /// 扫描指定目录的歌曲
  Future<List<Song>> scanSongsInPath(String? path, {SongSortType? sortType, int minDuration = 30000}) async {
    final hasPermission = await requestPermission();
    if (!hasPermission) {
      throw Exception('需要存储权限才能扫描音乐文件');
    }

    // 如果指定了自定义路径，使用文件系统扫描
    if (path != null && path.isNotEmpty) {
      return await _scanDirectoryForAllFormats(path);
    }

    // 全盘扫描：使用 on_audio_query + 补充其他格式
    final songModels = await _audioQuery.querySongs(
      sortType: sortType ?? SongSortType.TITLE,
      orderType: OrderType.ASC_OR_SMALLER,
      ignoreCase: true,
    );

    var songs = songModels
        .where((model) => _isValidSong(model, minDuration: minDuration))
        .map((model) => Song.fromSongModel(model))
        .toList();

    // 去重（基于文件路径）
    final uniquePaths = <String>{};
    songs = songs.where((song) {
      if (uniquePaths.contains(song.uri)) return false;
      uniquePaths.add(song.uri);
      return true;
    }).toList();

    return songs;
  }

  /// 扫描所有歌曲（带过滤）
  Future<List<Song>> scanSongs({SongSortType? sortType, int minDuration = 30000}) async {
    return scanSongsInPath(null, sortType: sortType, minDuration: minDuration);
  }

  /// 扫描指定目录的所有音频文件（所有格式）
  Future<List<Song>> _scanDirectoryForAllFormats(String rootPath) async {
    final List<Song> songs = [];
    
    try {
      await _scanDirectoryRecursive(rootPath, songs, 0);
    } catch (e) {
      print('Scan directory error: $e');
    }
    
    print('Directory scan found: ${songs.length} files in $rootPath');
    return songs;
  }

  Future<void> _scanDirectoryRecursive(String path, List<Song> songs, int depth) async {
    if (depth > 8) return; // 限制递归深度
    
    try {
      final dir = Directory(path);
      if (!await dir.exists()) return;

      await for (final entity in dir.list(recursive: false)) {
        if (entity is File) {
          final lowerPath = entity.path.toLowerCase();
          
          // 检查是否是支持的音频格式
          bool isSupported = false;
          String ext = '';
          
          for (final format in _supportedFormats) {
            if (lowerPath.endsWith('.$format')) {
              isSupported = true;
              ext = format;
              break;
            }
          }
          
          // 也检查额外格式（如WMA）
          if (!isSupported) {
            for (final format in _extraFormats) {
              if (lowerPath.endsWith('.$format')) {
                isSupported = true;
                ext = format;
                break;
              }
            }
          }
          
          if (isSupported) {
            // 检查是否已被排除
            if (_isExcludedPath(entity.path)) continue;
            
            final fileName = entity.path.split('/').last;
            final dotIndex = fileName.lastIndexOf('.');
            final title = dotIndex > 0 ? fileName.substring(0, dotIndex) : fileName;
            
            // 尝试获取文件大小（作为备用信息）
            int fileSize = 0;
            try {
              final stat = await entity.stat();
              fileSize = stat.size;
            } catch (_) {}
            
            // 使用 FFprobe 获取音频时长
            int duration = await _getAudioDuration(entity.path);
            
            songs.add(Song(
              id: entity.path.hashCode.toString(),
              title: title,
              artist: '未知艺术家',
              album: '未知专辑',
              duration: duration,
              uri: entity.path,
              fileExtension: ext,
            ));
          }
        } else if (entity is Directory) {
          final name = entity.path.split('/').last;
          if (!name.startsWith('.') && !_isSystemDir(name)) {
            await _scanDirectoryRecursive(entity.path, songs, depth + 1);
          }
        }
      }
    } catch (e) {
      // 权限错误，忽略
    }
  }

  bool _isSystemDir(String name) {
    final systemDirs = ['Android', 'data', 'obb', 'cache', '.thumbnails', 'com.android'];
    final lower = name.toLowerCase();
    for (final excluded in systemDirs) {
      if (lower.contains(excluded)) return true;
    }
    return false;
  }

  Future<List<Album>> scanAlbums() async {
    final hasPermission = await checkPermission();
    if (!hasPermission) {
      throw Exception('需要存储权限');
    }

    // 先获取所有有效歌曲
    final songs = await scanSongs();
    
    // 从歌曲中提取专辑信息
    final Map<String, Album> albumMap = {};
    
    for (final song in songs) {
      if (_isExcludedPath(song.album)) continue;
      
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
    
    return albumMap.values.toList();
  }

  Future<List<Artist>> scanArtists() async {
    final hasPermission = await checkPermission();
    if (!hasPermission) {
      throw Exception('需要存储权限');
    }

    // 先获取所有有效歌曲
    final songs = await scanSongs();
    
    // 从歌曲中提取艺术家信息
    final Map<String, Artist> artistMap = {};
    final Map<String, Set<String>> artistAlbums = {};
    
    for (final song in songs) {
      if (_isExcludedPath(song.artist)) continue;
      
      final key = song.artist;
      if (!artistMap.containsKey(key)) {
        artistMap[key] = Artist(
          id: song.artist.hashCode.toString(),
          name: song.artist,
          numberOfAlbums: 1,
          numberOfTracks: 1,
        );
        artistAlbums[key] = {song.album};
      } else {
        artistAlbums[key]!.add(song.album);
        final artist = artistMap[key]!;
        artistMap[key] = Artist(
          id: artist.id,
          name: artist.name,
          numberOfAlbums: artistAlbums[key]!.length,
          numberOfTracks: artist.numberOfTracks + 1,
        );
      }
    }
    
    return artistMap.values.toList();
  }

  Future<List<Song>> getSongsByAlbum(String albumId, {int minDuration = 30000}) async {
    final hasPermission = await checkPermission();
    if (!hasPermission) return [];

    final songModels = await _audioQuery.queryAudiosFrom(
      AudiosFromType.ALBUM_ID,
      int.parse(albumId),
    );

    return songModels
        .where((model) => _isValidSong(model, minDuration: minDuration))
        .map((model) => Song.fromSongModel(model))
        .toList();
  }

  Future<List<Song>> getSongsByArtist(String artistId, {int minDuration = 30000}) async {
    final hasPermission = await checkPermission();
    if (!hasPermission) return [];

    final songModels = await _audioQuery.queryAudiosFrom(
      AudiosFromType.ARTIST_ID,
      int.parse(artistId),
    );

    return songModels
        .where((model) => _isValidSong(model, minDuration: minDuration))
        .map((model) => Song.fromSongModel(model))
        .toList();
  }

  Future<Uint8List?> getArtwork(String id, {ArtworkType type = ArtworkType.AUDIO}) async {
    final hasPermission = await checkPermission();
    if (!hasPermission) return null;

    try {
      return await _audioQuery.queryArtwork(
        int.parse(id),
        type,
        format: ArtworkFormat.JPEG,
        size: 500,
        quality: 80,
      );
    } catch (e) {
      return null;
    }
  }

  /// 扫描音乐文件夹（过滤掉非音乐目录）
  Future<List<String>> scanFolders() async {
    final hasPermission = await checkPermission();
    if (!hasPermission) return [];

    try {
      final songModels = await _audioQuery.querySongs();
      final folders = <String>{};
      
      for (final song in songModels) {
        if (song.data != null) {
          final path = song.data!;
          
          // 检查是否被排除
          if (_isExcludedPath(path)) continue;
          
          final lastSlash = path.lastIndexOf('/');
          if (lastSlash > 0) {
            final folder = path.substring(0, lastSlash);
            folders.add(folder);
          }
        }
      }
      
      return folders.toList()..sort();
    } catch (e) {
      return [];
    }
  }

  /// 获取自定义目录下的所有子目录（包含音乐的）
  Future<List<DirectoryInfo>> getMusicDirectories(String rootPath) async {
    final List<DirectoryInfo> result = [];
    
    try {
      final root = Directory(rootPath);
      if (!await root.exists()) return result;
      
      // 添加根目录
      if (await _hasMusicFiles(rootPath)) {
        result.add(DirectoryInfo(
          name: rootPath.split('/').last,
          path: rootPath,
          level: 0,
        ));
      }
      
      // 递归扫描子目录
      await _scanSubdirectories(root, result, 1);
      
    } catch (e) {
      print('Get music directories error: $e');
    }
    
    return result;
  }
  
  Future<void> _scanSubdirectories(Directory dir, List<DirectoryInfo> result, int level) async {
    if (level > 3) return;
    
    try {
      await for (final entity in dir.list()) {
        if (entity is Directory) {
          final name = entity.path.split('/').last;
          
          // 跳过隐藏目录和系统目录
          if (name.startsWith('.')) continue;
          if (_isSystemDir(name)) continue;
          
          // 检查是否包含音乐文件
          if (await _hasMusicFiles(entity.path)) {
            result.add(DirectoryInfo(
              name: name,
              path: entity.path,
              level: level,
            ));
            
            // 继续扫描子目录
            await _scanSubdirectories(entity, result, level + 1);
          }
        }
      }
    } catch (e) {
      // 权限拒绝等错误，忽略
    }
  }
  
  Future<bool> _hasMusicFiles(String path) async {
    try {
      final dir = Directory(path);
      // 检查所有支持的格式
      for (final ext in [..._supportedFormats, ..._extraFormats]) {
        await for (final entity in dir.list(recursive: false)) {
          if (entity is File) {
            if (entity.path.toLowerCase().endsWith('.$ext')) {
              return true;
            }
          }
        }
      }
    } catch (e) {
      return false;
    }
    return false;
  }

  /// 获取音频文件时长（用于 WMA 等无法通过 on_audio_query 获取时长的格式）
  Future<int> _getAudioDuration(String filePath) async {
    try {
      final mediaInfo = await FFprobeKit.getMediaInformation(filePath);
      final information = mediaInfo.getMediaInformation();
      
      if (information != null) {
        final durationStr = information.getDuration();
        if (durationStr != null) {
          // 时长以秒为单位返回，转换为毫秒
          final durationSec = double.tryParse(durationStr);
          if (durationSec != null) {
            return (durationSec * 1000).round();
          }
        }
      }
    } catch (e) {
      print('Get duration error for $filePath: $e');
    }
    return 0;
  }
}

class DirectoryInfo {
  final String name;
  final String path;
  final int level;

  DirectoryInfo({
    required this.name,
    required this.path,
    required this.level,
  });
}
