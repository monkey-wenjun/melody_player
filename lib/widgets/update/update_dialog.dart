import 'dart:io';
import 'package:flutter/material.dart';
import '../../services/update_service.dart';

import 'package:flutter/services.dart';
import '../../app.dart';

// 与原生 Android 通信的 MethodChannel
const MethodChannel _installChannel = MethodChannel('com.melody.melody_player/install');

/// 安装 APK 文件 - 使用原生 Android Intent
Future<void> installApkFile(String filePath, BuildContext? originalContext) async {
  debugPrint('准备安装 APK: $filePath');
  
  try {
    // 检查文件是否存在
    final file = File(filePath);
    if (!await file.exists()) {
      debugPrint('APK 文件不存在: $filePath');
      _showInstallResultSnackBar('安装文件不存在，请重新下载');
      return;
    }
    
    final fileSize = await file.length();
    debugPrint('APK 文件大小: $fileSize bytes');
    
    if (fileSize == 0) {
      _showInstallResultSnackBar('安装文件损坏，请重新下载');
      return;
    }
    
    // 使用 MethodChannel 调用原生 Android 安装
    debugPrint('调用原生安装方法...');
    final result = await _installChannel.invokeMethod<Map>('installApk', {
      'filePath': filePath,
    });
    
    debugPrint('安装调用结果: $result');
    
    if (result != null && result['success'] == false) {
      final error = result['error'] ?? '未知错误';
      debugPrint('安装调用失败: $error');
      _showInstallResultSnackBar('安装失败: $error');
    } else {
      debugPrint('安装界面已调起');
    }
  } on PlatformException catch (e) {
    debugPrint('安装 APK 失败 (PlatformException): ${e.message}');
    _showInstallResultSnackBar('安装失败: ${e.message}');
  } catch (e, stackTrace) {
    debugPrint('安装 APK 失败: $e');
    debugPrint('StackTrace: $stackTrace');
    _showInstallResultSnackBar('安装失败，请手动安装: $e');
  }
}

/// 显示安装结果提示
void _showInstallResultSnackBar(String message) {
  final context = appNavigatorKey.currentContext;
  if (context != null && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: '知道了',
          onPressed: () {},
        ),
      ),
    );
  }
}

class UpdateDialog extends StatefulWidget {
  final UpdateInfo updateInfo;
  final VoidCallback? onSkip;

  const UpdateDialog({
    Key? key,
    required this.updateInfo,
    this.onSkip,
  }) : super(key: key);

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  bool _isDownloading = false;
  double _progress = 0.0;
  String _status = '';
  String? _downloadedFilePath;

  @override
  void initState() {
    super.initState();
    _checkExistingDownload();
  }

  /// 检查是否已经下载过该版本
  Future<void> _checkExistingDownload() async {
    final updateService = UpdateService();
    final existingPath = await updateService.getExistingApkPath(
      widget.updateInfo.fileName,
    );
    if (existingPath != null) {
      setState(() {
        _downloadedFilePath = existingPath;
        _status = '已下载到: $existingPath';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.system_update, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          const Text('发现新版本'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '悦音播放器 v${widget.updateInfo.newVersion}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '当前版本: v${widget.updateInfo.currentVersion}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          
          // 下载进度或状态
          if (_isDownloading) ...[
            LinearProgressIndicator(value: _progress > 0 ? _progress : null),
            const SizedBox(height: 8),
            Text(
              _status.isEmpty 
                  ? '下载中... ${(_progress * 100).toStringAsFixed(1)}%' 
                  : _status,
              style: const TextStyle(fontSize: 12),
            ),
          ] else if (_downloadedFilePath != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 20),
                      SizedBox(width: 8),
                      Text(
                        '下载完成',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '文件位置:\n$_downloadedFilePath',
                    style: const TextStyle(fontSize: 11),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '请点击"立即安装"进行安装',
                    style: TextStyle(fontSize: 12, color: Colors.orange),
                  ),
                ],
              ),
            ),
          ] else ...[
            const Text(
              '更新内容：\n• 修复已知问题\n• 优化用户体验',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ],
      ),
      actions: [
        if (!_isDownloading) ...[
          TextButton(
            onPressed: () {
              widget.onSkip?.call();
              Navigator.pop(context);
            },
            child: const Text('稍后提醒'),
          ),
          if (_downloadedFilePath == null)
            ElevatedButton(
              onPressed: _startDownload,
              child: const Text('下载更新'),
            )
          else ...[
            ElevatedButton(
              onPressed: () async {
                final path = _downloadedFilePath!;
                Navigator.pop(context);
                await Future.delayed(const Duration(milliseconds: 200));
                await installApkFile(path, null);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              child: const Text('立即安装'),
            ),
          ],
        ] else ...[
          TextButton(
            onPressed: () {
              // 后台下载，关闭对话框但继续下载
              Navigator.pop(context);
              _startBackgroundDownload();
            },
            child: const Text('后台下载'),
          ),
        ],
      ],
    );
  }

  Future<void> _startDownload() async {
    debugPrint('开始下载更新...');
    setState(() {
      _isDownloading = true;
      _status = '准备下载...';
    });

    String? filePath;
    try {
      final updateService = UpdateService();
      
      filePath = await updateService.downloadApk(
        widget.updateInfo.downloadUrl,
        widget.updateInfo.fileName,
        onProgress: (progress) {
          if (mounted) {
            setState(() {
              _progress = progress;
              _status = '下载中... ${(progress * 100).toStringAsFixed(1)}%';
            });
          }
        },
      );
      debugPrint('下载完成，文件路径: $filePath');
    } catch (e) {
      debugPrint('下载失败: $e');
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _status = '下载失败: $e';
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('下载失败: $e')),
        );
      }
      return;
    }

    // 下载成功，关闭对话框并安装
    if (mounted && filePath != null) {
      debugPrint('关闭对话框并准备安装...');
      Navigator.pop(context);
      
      // 延迟确保对话框关闭
      await Future.delayed(const Duration(milliseconds: 300));
      
      // 直接调起安装
      debugPrint('调用 installApkFile...');
      await installApkFile(filePath, null);
    }
  }

  /// 后台下载（对话框关闭后）
  Future<void> _startBackgroundDownload() async {
    // 先关闭对话框
    Navigator.pop(context);
    
    // 显示下载中的通知
    _showGlobalSnackBar('正在后台下载更新...');
    
    try {
      final updateService = UpdateService();
      
      final filePath = await updateService.downloadApk(
        widget.updateInfo.downloadUrl,
        widget.updateInfo.fileName,
        onProgress: (progress) {
          // 后台下载不更新UI
          print('后台下载进度: ${(progress * 100).toStringAsFixed(1)}%');
        },
      );

      // 后台下载完成后自动安装
      await installApkFile(filePath, null);
    } catch (e) {
      print('后台下载失败: $e');
      _showGlobalSnackBar('后台下载失败: $e');
    }
  }
  
  void _showGlobalSnackBar(String message) {
    final context = appNavigatorKey.currentContext;
    if (context != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  Future<void> _installApk() async {
    if (_downloadedFilePath == null) return;
    await installApkFile(_downloadedFilePath!, context);
  }

  void _showManualInstallDialog() {
    final fileName = widget.updateInfo.fileName;
    final filePath = _downloadedFilePath ?? '未知路径';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('手动安装'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('自动安装失败，请按以下步骤手动安装：'),
            const SizedBox(height: 12),
            const Text('1. 打开文件管理器'),
            const Text('2. 进入 Download 目录'),
            Text('3. 点击 $fileName'),
            const Text('4. 允许安装未知来源应用'),
            const SizedBox(height: 12),
            Text(
              '文件位置:\n$filePath',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }
}

/// 检查更新并显示对话框
Future<void> checkAndShowUpdate(BuildContext context, {bool manual = false}) async {
  final updateService = UpdateService();
  
  // 如果不是手动检查，先判断是否应该自动检查
  if (!manual) {
    final shouldCheck = await updateService.shouldAutoCheck();
    if (!shouldCheck) return;
  }

  // 显示加载提示（手动检查时）
  if (manual) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('检查更新中...'),
          ],
        ),
      ),
    );
  }

  // 检查更新
  final updateInfo = await updateService.checkUpdate(manual: manual);

  // 关闭加载对话框
  if (manual && context.mounted) {
    Navigator.pop(context);
  }

  if (!context.mounted) return;

  if (updateInfo == null) {
    // 检查失败
    if (manual) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('检查失败'),
          content: const Text('无法连接到更新服务器，请检查网络后重试。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('确定'),
            ),
          ],
        ),
      );
    }
    return;
  }

  if (updateInfo.hasUpdate) {
    // 检查是否已下载
    final existingPath = await updateService.getExistingApkPath(updateInfo.fileName);
    
    if (existingPath != null && context.mounted) {
      // 已下载，提示安装
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('发现已下载的更新'),
          content: Text('新版本 v${updateInfo.newVersion} 已下载，是否立即安装？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('稍后'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await Future.delayed(const Duration(milliseconds: 200));
                await installApkFile(existingPath, null);
              },
              child: const Text('立即安装'),
            ),
          ],
        ),
      );
    } else if (context.mounted) {
      // 显示更新对话框
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => UpdateDialog(updateInfo: updateInfo),
      );
    }
  } else {
    // 已是最新版本
    if (manual) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('已是最新版本'),
          content: Text('当前版本 v${updateInfo.currentVersion} 已是最新。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('确定'),
            ),
          ],
        ),
      );
    }
  }
}
