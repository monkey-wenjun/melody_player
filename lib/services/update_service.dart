import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class UpdateInfo {
  final bool hasUpdate;
  final String currentVersion;
  final String newVersion;
  final String downloadUrl;
  final String fileName;

  UpdateInfo({
    required this.hasUpdate,
    required this.currentVersion,
    required this.newVersion,
    required this.downloadUrl,
    required this.fileName,
  });
}

class UpdateService {
  static final UpdateService _instance = UpdateService._internal();
  factory UpdateService() => _instance;
  UpdateService._internal();

  // 更新服务器基础URL
  static const String _baseUrl = 'https://file.awen.me/music';
  
  // 检查间隔（7天）
  static const int _checkIntervalDays = 7;
  static const String _lastCheckKey = 'last_update_check';

  /// 比较两个版本号
  /// 返回: -1 表示 v1 < v2, 0 表示相等, 1 表示 v1 > v2
  int _compareVersion(String v1, String v2) {
    final parts1 = v1.split('.').map(int.tryParse).toList();
    final parts2 = v2.split('.').map(int.tryParse).toList();
    
    // 确保都有3个部分
    while (parts1.length < 3) parts1.add(0);
    while (parts2.length < 3) parts2.add(0);
    
    for (int i = 0; i < 3; i++) {
      final a = parts1[i] ?? 0;
      final b = parts2[i] ?? 0;
      if (a < b) return -1;
      if (a > b) return 1;
    }
    return 0;
  }

  /// 检查更新
  Future<UpdateInfo?> checkUpdate({bool manual = false}) async {
    try {
      final currentVersion = AppConstants.appVersion;
      
      if (kDebugMode) {
        print('[Update] 当前版本: $currentVersion');
      }

      // 尝试检查多个可能的版本（从 patch+1 到 patch+10，以及 minor+1, major+1）
      final versionsToCheck = _generateVersionsToCheck(currentVersion);
      
      String? latestVersion;
      String? latestFileName;
      
      // 按版本从高到低检查，找到第一个存在的版本
      for (final version in versionsToCheck) {
        final fileName = 'melody_player_v$version.apk';
        final downloadUrl = '$_baseUrl/$fileName';
        
        if (kDebugMode) {
          print('[Update] 检查版本: $version');
        }
        
        try {
          final response = await http.head(
            Uri.parse(downloadUrl),
            headers: {'Accept': '*/*'},
          ).timeout(const Duration(seconds: 5));
          
          if (response.statusCode == 200) {
            // 找到存在的版本
            if (_compareVersion(version, currentVersion) > 0) {
              latestVersion = version;
              latestFileName = fileName;
              if (kDebugMode) {
                print('[Update] 发现可用版本: $version');
              }
              // 继续检查是否有更新的版本
            }
          }
        } catch (e) {
          // 忽略单个请求的错误
        }
      }
      
      await _saveLastCheckTime();
      
      if (latestVersion != null && latestFileName != null) {
        return UpdateInfo(
          hasUpdate: true,
          currentVersion: currentVersion,
          newVersion: latestVersion,
          downloadUrl: '$_baseUrl/$latestFileName',
          fileName: latestFileName,
        );
      }
      
      // 没有新版本
      return UpdateInfo(
        hasUpdate: false,
        currentVersion: currentVersion,
        newVersion: currentVersion,
        downloadUrl: '',
        fileName: '',
      );
    } catch (e, stackTrace) {
      print('[Update] 检查更新错误: $e');
      if (kDebugMode) {
        print('[Update] 堆栈: $stackTrace');
      }
      return null;
    }
  }
  
  /// 生成要检查的版本列表（按优先级排序）
  List<String> _generateVersionsToCheck(String currentVersion) {
    final versions = <String>[];
    final parts = currentVersion.split('.');
    final major = int.tryParse(parts[0]) ?? 1;
    final minor = int.tryParse(parts[1]) ?? 0;
    final patch = int.tryParse(parts[2]) ?? 0;
    
    // 检查 patch +1 到 +20
    for (int i = 1; i <= 20; i++) {
      versions.add('$major.$minor.${patch + i}');
    }
    
    // 检查 minor +1, +2
    for (int i = 1; i <= 2; i++) {
      versions.add('$major.${minor + i}.0');
      // 以及它们的 patch 版本
      for (int j = 1; j <= 5; j++) {
        versions.add('$major.${minor + i}.$j');
      }
    }
    
    // 检查 major +1
    versions.add('${major + 1}.0.0');
    for (int i = 1; i <= 5; i++) {
      versions.add('${major + 1}.0.$i');
    }
    
    return versions;
  }

  /// 是否应该自动检查更新
  Future<bool> shouldAutoCheck() async {
    final prefs = await SharedPreferences.getInstance();
    final lastCheck = prefs.getInt(_lastCheckKey);
    
    if (lastCheck == null) return true;
    
    final lastCheckDate = DateTime.fromMillisecondsSinceEpoch(lastCheck);
    final now = DateTime.now();
    final difference = now.difference(lastCheckDate);
    
    if (kDebugMode) {
      print('[Update] 距离上次检查: ${difference.inDays} 天');
    }
    
    return difference.inDays >= _checkIntervalDays;
  }

  /// 保存最后检查时间
  Future<void> _saveLastCheckTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastCheckKey, DateTime.now().millisecondsSinceEpoch);
  }

  /// 重置最后检查时间（用于测试）
  Future<void> resetLastCheckTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastCheckKey);
  }

  /// 下载APK到应用外部文件目录（确保 FileProvider 可以访问）
  Future<String> downloadApk(String url, String fileName, 
      {Function(double)? onProgress}) async {
    try {
      // Android 11+ 不需要存储权限来写入应用私有目录
      if (Platform.isAndroid) {
        var status = await Permission.storage.status;
        if (!status.isGranted) {
          // 尝试请求，但不强制要求
          status = await Permission.storage.request();
        }
      }

      // 使用应用外部文件目录，确保 FileProvider 可以访问
      Directory downloadDir;
      if (Platform.isAndroid) {
        final extDir = await getExternalStorageDirectory();
        // 使用 Android/data/com.melody.melody_player/files/ 目录
        downloadDir = Directory('${extDir?.path ?? '/storage/emulated/0/Android/data/com.melody.melody_player/files'}/updates');
        if (!await downloadDir.exists()) {
          await downloadDir.create(recursive: true);
        }
      } else {
        downloadDir = await getApplicationDocumentsDirectory();
      }

      final filePath = '${downloadDir.path}/$fileName';
      final file = File(filePath);

      if (await file.exists()) {
        await file.delete();
      }

      final request = http.Request('GET', Uri.parse(url));
      final response = await request.send();

      if (response.statusCode != 200) {
        throw Exception('下载失败: HTTP ${response.statusCode}');
      }

      final contentLength = response.contentLength ?? 0;
      var received = 0;

      final sink = file.openWrite();
      await for (final chunk in response.stream) {
        sink.add(chunk);
        received += chunk.length;
        if (contentLength > 0) {
          onProgress?.call(received / contentLength);
        }
      }
      await sink.close();

      final downloadedFile = File(filePath);
      if (!await downloadedFile.exists()) {
        throw Exception('下载文件不存在');
      }
      
      final fileSize = await downloadedFile.length();
      if (fileSize == 0) {
        await downloadedFile.delete();
        throw Exception('下载文件大小为0');
      }
      
      if (contentLength > 0 && fileSize < contentLength * 0.9) {
        await downloadedFile.delete();
        throw Exception('下载不完整，请重试');
      }

      return filePath;
    } catch (e) {
      print('Download error: $e');
      throw Exception('下载失败: $e');
    }
  }

  /// 获取已下载的APK路径
  Future<String?> getExistingApkPath(String fileName) async {
    try {
      // 检查新的下载路径 (Android/data/.../files/updates/)
      final extDir = await getExternalStorageDirectory();
      final newPath = '${extDir?.path}/updates/$fileName';
      final newFile = File(newPath);
      if (await newFile.exists()) {
        return newFile.path;
      }
      
      // 兼容旧版本：检查旧下载路径 (Download/)
      final oldFile = File('/storage/emulated/0/Download/$fileName');
      if (await oldFile.exists()) {
        return oldFile.path;
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }
}
