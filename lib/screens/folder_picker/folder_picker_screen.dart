import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class FolderPickerScreen extends StatefulWidget {
  final List<String> selectedPaths;

  const FolderPickerScreen({
    Key? key,
    this.selectedPaths = const [],
  }) : super(key: key);

  @override
  State<FolderPickerScreen> createState() => _FolderPickerScreenState();
}

class _FolderPickerScreenState extends State<FolderPickerScreen> {
  List<String> _selectedPaths = [];
  bool _isLoading = true;
  String _currentPath = '';
  List<DirectoryItem> _items = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _selectedPaths = List.from(widget.selectedPaths);
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    // 检查权限
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      status = await Permission.storage.request();
    }
    
    // Android 11+ 需要额外权限
    if (!status.isGranted && Platform.isAndroid) {
      final manageStatus = await Permission.manageExternalStorage.status;
      if (!manageStatus.isGranted) {
        await Permission.manageExternalStorage.request();
      }
    }

    if (status.isGranted || await Permission.manageExternalStorage.isGranted) {
      await _loadRoot();
    } else {
      setState(() {
        _isLoading = false;
        _error = '需要存储权限才能访问目录';
      });
    }
  }

  /// 加载根目录
  Future<void> _loadRoot() async {
    setState(() {
      _isLoading = true;
      _currentPath = '';
      _error = null;
    });

    try {
      final externalDir = await getExternalStorageDirectory();
      if (externalDir == null) {
        setState(() {
          _isLoading = false;
          _error = '无法获取存储目录';
        });
        return;
      }

      final rootPath = externalDir.path.split('Android')[0];
      final List<DirectoryItem> items = [];

      // 添加内部存储根目录
      items.add(DirectoryItem(
        name: '📱 内部存储',
        path: rootPath,
        type: ItemType.root,
      ));

      // 扫描常见目录
      final commonDirs = ['Music', 'Download', 'Downloads', '音乐', '下载', 'kgmusic', 'netease'];
      for (final dirName in commonDirs) {
        final dirPath = '$rootPath/$dirName';
        final dir = Directory(dirPath);
        if (await dir.exists()) {
          items.add(DirectoryItem(
            name: '📁 $dirName',
            path: dirPath,
            type: ItemType.directory,
          ));
        }
      }

      // 扫描所有一级子目录
      try {
        final rootDir = Directory(rootPath);
        final List<DirectoryItem> subDirs = [];
        
        await for (final entity in rootDir.list()) {
          if (entity is Directory) {
            final name = entity.path.split('/').last;
            
            // 跳过系统目录
            if (_isSystemDir(name)) continue;
            
            // 跳过已添加的常见目录
            if (commonDirs.contains(name)) continue;
            
            subDirs.add(DirectoryItem(
              name: '📂 $name',
              path: entity.path,
              type: ItemType.directory,
            ));
          }
        }
        
        subDirs.sort((a, b) => a.name.compareTo(b.name));
        items.addAll(subDirs);
      } catch (e) {
        print('Scan subdirs error: $e');
      }

      setState(() {
        _items = items;
        _isLoading = false;
      });
    } catch (e) {
      print('Load root error: $e');
      setState(() {
        _isLoading = false;
        _error = '加载目录失败: $e';
      });
    }
  }

  /// 加载指定目录的内容
  Future<void> _loadDirectory(String path) async {
    setState(() {
      _isLoading = true;
      _currentPath = path;
      _error = null;
    });

    try {
      final List<DirectoryItem> items = [];
      final dir = Directory(path);

      if (!await dir.exists()) {
        setState(() {
          _isLoading = false;
          _error = '目录不存在';
        });
        return;
      }

      // 1. 添加"选择当前目录"按钮
      final dirName = path.split('/').last;
      items.add(DirectoryItem(
        name: '✅ 选择此目录 ($dirName)',
        path: path,
        type: ItemType.selectCurrent,
      ));

      // 2. 扫描子目录
      final List<DirectoryItem> subDirs = [];
      
      await for (final entity in dir.list()) {
        if (entity is Directory) {
          final name = entity.path.split('/').last;
          
          // 跳过隐藏目录和系统目录
          if (name.startsWith('.')) continue;
          if (_isSystemDir(name)) continue;
          
          subDirs.add(DirectoryItem(
            name: '📁 $name',
            path: entity.path,
            type: ItemType.directory,
          ));
        }
      }

      subDirs.sort((a, b) => a.name.compareTo(b.name));
      items.addAll(subDirs);

      setState(() {
        _items = items;
        _isLoading = false;
      });
    } catch (e) {
      print('Load directory error: $e');
      setState(() {
        _isLoading = false;
        _error = '加载失败: $e';
      });
    }
  }

  bool _isSystemDir(String name) {
    final systemDirs = [
      'Android', '.thumbnails', '.cache', '.android',
      'data', 'obb', 'com.android', 'com.google',
    ];
    final lower = name.toLowerCase();
    for (final excluded in systemDirs) {
      if (lower.contains(excluded)) return true;
    }
    return false;
  }

  void _toggleSelection(String path) {
    setState(() {
      if (_selectedPaths.contains(path)) {
        _selectedPaths.remove(path);
      } else {
        _selectedPaths.add(path);
      }
    });
  }

  void _goBack() {
    if (_currentPath.isEmpty) return;
    
    final lastSlash = _currentPath.lastIndexOf('/');
    if (lastSlash <= 0) {
      _loadRoot();
      return;
    }
    
    final parent = _currentPath.substring(0, lastSlash);
    if (parent == '' || parent == '/') {
      _loadRoot();
    } else {
      _loadDirectory(parent);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentPath.isEmpty ? '选择音乐目录' : '选择目录'),
        leading: _currentPath.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _goBack,
              )
            : null,
        actions: [
          if (_selectedPaths.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  '${_selectedPaths.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context, _selectedPaths),
            child: const Text('完成'),
          ),
        ],
      ),
      body: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.colorScheme.primary.withOpacity(0.12),
                  theme.colorScheme.secondary.withOpacity(0.08),
                  theme.colorScheme.tertiary.withOpacity(0.04),
                ],
              ),
            ),
            child: _buildBody(),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('加载目录中...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(_error!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _checkPermission,
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // 当前路径显示
        if (_currentPath.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: Colors.grey[200],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('当前路径：', style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 4),
                Text(
                  _currentPath,
                  style: const TextStyle(fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

        // 目录列表
        Expanded(
          child: _items.isEmpty
              ? const Center(child: Text('没有可用的目录'))
              : ListView.builder(
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    final isSelected = _selectedPaths.contains(item.path);

                    // "选择当前目录" 按钮
                    if (item.type == ItemType.selectCurrent) {
                      return Card(
                        margin: const EdgeInsets.all(12),
                        color: isSelected ? Colors.green : Theme.of(context).colorScheme.primary,
                        child: ListTile(
                          leading: Icon(
                            isSelected ? Icons.check_circle : Icons.folder,
                            color: Colors.white,
                          ),
                          title: Text(
                            item.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          trailing: isSelected
                              ? const Icon(Icons.check, color: Colors.white)
                              : null,
                          onTap: () => _toggleSelection(item.path),
                        ),
                      );
                    }

                    // 普通目录
                    return ListTile(
                      leading: Icon(
                        item.type == ItemType.root ? Icons.storage : Icons.folder,
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : item.type == ItemType.root
                                ? Colors.orange
                                : Colors.amber,
                      ),
                      title: Text(
                        item.name.replaceAll('📱 ', '').replaceAll('📁 ', '').replaceAll('📂 ', ''),
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : null,
                          color: isSelected ? Theme.of(context).colorScheme.primary : null,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Checkbox(
                            value: isSelected,
                            onChanged: (_) => _toggleSelection(item.path),
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_right),
                            onPressed: () => _loadDirectory(item.path),
                          ),
                        ],
                      ),
                      onTap: () => _toggleSelection(item.path),
                    );
                  },
                ),
        ),

        // 底部已选择
        if (_selectedPaths.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)],
            ),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.check_circle, size: 16, color: Colors.green),
                      const SizedBox(width: 4),
                      Text('已选择 ${_selectedPaths.length} 个'),
                      const Spacer(),
                      TextButton(
                        onPressed: () => setState(() => _selectedPaths.clear()),
                        child: const Text('清空'),
                      ),
                    ],
                  ),
                  Wrap(
                    spacing: 8,
                    children: _selectedPaths.map((path) {
                      final name = path.split('/').last;
                      return Chip(
                        label: Text(name),
                        onDeleted: () {
                          setState(() => _selectedPaths.remove(path));
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

enum ItemType { root, directory, selectCurrent }

class DirectoryItem {
  final String name;
  final String path;
  final ItemType type;

  DirectoryItem({
    required this.name,
    required this.path,
    required this.type,
  });
}
