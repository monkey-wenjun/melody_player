import 'dart:io';
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

  /// 检查更新
  /// [manual] 是否手动检查（手动检查会显示加载和提示）
  Future<UpdateInfo?> checkUpdate({bool manual = false}) async {
    try {
      final currentVersion = AppConstants.appVersion;
      
      // 解析当前版本号
      final versionParts = currentVersion.split('.');
      if (versionParts.length != 3) return null;
      
      final major = int.tryParse(versionParts[0]) ?? 1;
      final minor = int.tryParse(versionParts[1]) ?? 0;
      final patch = int.tryParse(versionParts[2]) ?? 0;

      // 尝试检查新版本（patch + 1）
      final newPatch = patch + 1;
      final newVersion = '$major.$minor.$newPatch';
      // 使用英文文件名
      final fileName = 'melody_player_v$newVersion.apk';
      final downloadUrl = '$_baseUrl/$fileName';

      // 发送HEAD请求检查文件是否存在
      final response = await http.head(Uri.parse(downloadUrl))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        // 有新版本
        await _saveLastCheckTime();
        return UpdateInfo(
          hasUpdate: true,
          currentVersion: currentVersion,
          newVersion: newVersion,
          downloadUrl: downloadUrl,
          fileName: fileName,
        );
      }

      // 如果没有patch+1的版本，尝试minor+1
      final newMinorVersion = '$major.${minor + 1}.0';
      // 使用英文文件名
      final minorFileName = 'melody_player_v$newMinorVersion.apk';
      final minorDownloadUrl = '$_baseUrl/$minorFileName';

      final minorResponse = await http.head(Uri.parse(minorDownloadUrl))
          .timeout(const Duration(seconds: 10));

      if (minorResponse.statusCode == 200) {
        await _saveLastCheckTime();
        return UpdateInfo(
          hasUpdate: true,
          currentVersion: currentVersion,
          newVersion: newMinorVersion,
          downloadUrl: minorDownloadUrl,
          fileName: minorFileName,
        );
      }

      // 没有新版本
      await _saveLastCheckTime();
      return UpdateInfo(
        hasUpdate: false,
        currentVersion: currentVersion,
        newVersion: currentVersion,
        downloadUrl: '',
        fileName: '',
      );
    } catch (e) {
      print('Check update error: $e');
      if (manual) {
        // 手动检查时返回null表示检查失败
        return null;
      }
      return null;
    }
  }

  /// 是否应该自动检查更新
  Future<bool> shouldAutoCheck() async {
    final prefs = await SharedPreferences.getInstance();
    final lastCheck = prefs.getInt(_lastCheckKey);
    
    if (lastCheck == null) return true;
    
    final lastCheckDate = DateTime.fromMillisecondsSinceEpoch(lastCheck);
    final now = DateTime.now();
    final difference = now.difference(lastCheckDate);
    
    return difference.inDays >= _checkIntervalDays;
  }

  /// 保存最后检查时间
  Future<void> _saveLastCheckTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastCheckKey, DateTime.now().millisecondsSinceEpoch);
  }

  /// 下载APK到下载目录
  /// 返回下载的文件路径
  Future<String> downloadApk(String url, String fileName, 
      {Function(double)? onProgress}) async {
    try {
      // 请求存储权限
      var status = await Permission.storage.request();
      if (!status.isGranted) {
        // Android 11+ 尝试请求管理外部存储
        status = await Permission.manageExternalStorage.request();
        if (!status.isGranted) {
          throw Exception('需要存储权限才能下载更新');
        }
      }

      // 获取下载目录
      Directory downloadDir;
      if (Platform.isAndroid) {
        // 使用公共下载目录
        downloadDir = Directory('/storage/emulated/0/Download');
        if (!await downloadDir.exists()) {
          final extDir = await getExternalStorageDirectory();
          downloadDir = extDir ?? await getApplicationDocumentsDirectory();
        }
      } else {
        downloadDir = await getApplicationDocumentsDirectory();
      }

      final filePath = '${downloadDir.path}/$fileName';
      final file = File(filePath);

      // 如果文件已存在，先删除
      if (await file.exists()) {
        await file.delete();
      }

      // 下载文件
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

      // 校验文件完整性
      final downloadedFile = File(filePath);
      if (!await downloadedFile.exists()) {
        throw Exception('下载文件不存在');
      }
      
      final fileSize = await downloadedFile.length();
      if (fileSize == 0) {
        await downloadedFile.delete();
        throw Exception('下载文件大小为0');
      }
      
      // 如果服务器返回了内容长度，校验大小
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

  /// 获取已下载的APK路径（如果存在）
  Future<String?> getExistingApkPath(String fileName) async {
    try {
      final downloadDir = Directory('/storage/emulated/0/Download');
      if (!await downloadDir.exists()) return null;
      
      final file = File('${downloadDir.path}/$fileName');
      if (await file.exists()) {
        return file.path;
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
