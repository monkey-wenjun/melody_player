import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import '../../services/update_service.dart';

/// 安装 APK 文件
Future<void> installApkFile(String filePath, BuildContext context) async {
  try {
    final result = await OpenFilex.open(
      filePath,
      type: 'application/vnd.android.package-archive',
    );

    if (result.type != ResultType.done && context.mounted) {
      _showManualInstallDialog(filePath, context);
    }
  } catch (e) {
    if (context.mounted) {
      _showManualInstallDialog(filePath, context);
    }
  }
}

void _showManualInstallDialog(String filePath, BuildContext context) {
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
          Text('3. 点击 ${filePath.split('/').last}'),
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
              onPressed: () {
                Navigator.pop(context);
                Future.delayed(const Duration(milliseconds: 300), () {
                  installApkFile(_downloadedFilePath!, context);
                });
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
    setState(() {
      _isDownloading = true;
      _status = '准备下载...';
    });

    try {
      final updateService = UpdateService();
      
      final filePath = await updateService.downloadApk(
        widget.updateInfo.downloadUrl,
        widget.updateInfo.fileName,
        onProgress: (progress) {
          setState(() {
            _progress = progress;
            _status = '下载中... ${(progress * 100).toStringAsFixed(1)}%';
          });
        },
      );

      // 下载完成后，先关闭对话框再安装
      if (mounted) {
        Navigator.pop(context);
      }
      
      // 延迟一下确保对话框关闭后再调起安装
      await Future.delayed(const Duration(milliseconds: 300));
      
      // 直接调起安装
      await installApkFile(filePath, context);
    } catch (e) {
      setState(() {
        _isDownloading = false;
        _status = '下载失败: $e';
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('下载失败: $e')),
      );
    }
  }

  /// 后台下载（对话框关闭后）
  Future<void> _startBackgroundDownload() async {
    // 先关闭对话框
    Navigator.pop(context);
    
    // 显示下载中的通知
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('正在后台下载更新...'),
          duration: Duration(seconds: 2),
        ),
      );
    }
    
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
      await installApkFile(filePath, context);
    } catch (e) {
      print('后台下载失败: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('后台下载失败: $e')),
        );
      }
    }
  }

  Future<void> _installApk() async {
    if (_downloadedFilePath == null) return;

    try {
      // 使用 open_filex 调起安装界面
      final result = await OpenFilex.open(
        _downloadedFilePath!,
        type: 'application/vnd.android.package-archive',
      );

      if (result.type != ResultType.done) {
        // 如果自动打开失败，显示手动安装提示
        if (mounted) {
          _showManualInstallDialog();
        }
      }
    } catch (e) {
      // 出错时显示手动安装提示
      if (mounted) {
        _showManualInstallDialog();
      }
    }
  }

  void _showManualInstallDialog() {
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
            Text('3. 点击 ${widget.updateInfo.fileName}'),
            const Text('4. 允许安装未知来源应用'),
            const SizedBox(height: 12),
            Text(
              '文件位置:\n$_downloadedFilePath',
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
              onPressed: () {
                Navigator.pop(context);
                // 自动调起安装
                installApkFile(existingPath, context);
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
