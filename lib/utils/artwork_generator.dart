import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';


/// 预定义的渐变配色方案
final List<List<Color>> _gradientPalettes = [
  [const Color(0xFF667eea), const Color(0xFF764ba2)], // 紫蓝渐变
  [const Color(0xFFf093fb), const Color(0xFFf5576c)], // 粉紫渐变
  [const Color(0xFF4facfe), const Color(0xFF00f2fe)], // 青色渐变
  [const Color(0xFF43e97b), const Color(0xFF38f9d7)], // 绿色渐变
  [const Color(0xFFfa709a), const Color(0xFFfee140)], // 橙粉渐变
  [const Color(0xFF30cfd0), const Color(0xFF330867)], // 深青紫渐变
  [const Color(0xFFa8edea), const Color(0xFFfed6e3)], // 柔和粉青
  [const Color(0xFFff9a9e), const Color(0xFFfecfef)], // 浅粉渐变
  [const Color(0xFFffecd2), const Color(0xFFfcb69f)], // 暖橙渐变
  [const Color(0xFF667eea), const Color(0xFF764ba2)], // 蓝紫渐变
  [const Color(0xFF11998e), const Color(0xFF38ef7d)], // 翠绿渐变
  [const Color(0xFFfc5c7d), const Color(0xFF6a82fb)], // 粉蓝渐变
];

/// 根据ID获取一致的渐变颜色
List<Color> _getGradientColors(String id) {
  int hash = 0;
  for (int i = 0; i < id.length; i++) {
    hash = ((hash << 5) - hash) + id.codeUnitAt(i);
    hash = hash & 0xFFFFFFFF;
  }
  return _gradientPalettes[hash.abs() % _gradientPalettes.length];
}

/// 获取标题的首字母
String _getInitial(String title) {
  if (title.isEmpty) return '♪';
  final firstChar = title.trim()[0];
  if (RegExp(r'[a-zA-Z0-9]').hasMatch(firstChar)) {
    return firstChar.toUpperCase();
  }
  return firstChar;
}

/// 后台通知栏缩略图生成器
class ArtworkGenerator {
  static final Map<String, String> _cache = {};
  static bool _initialized = false;
  static String? _cacheDir;
  
  /// 初始化缓存目录
  static Future<void> _init() async {
    if (_initialized) return;
    
    try {
      // 使用应用外部缓存目录，Android 通知栏可以访问
      final dir = await getExternalCacheDirectories();
      if (dir != null && dir.isNotEmpty) {
        _cacheDir = dir.first.path;
      } else {
        final appDir = await getApplicationSupportDirectory();
        _cacheDir = appDir.path;
      }
      
      // 创建 artwork 子目录
      final artworkDir = Directory('$_cacheDir/artworks');
      if (!await artworkDir.exists()) {
        await artworkDir.create(recursive: true);
      }
      _cacheDir = artworkDir.path;
      
      _initialized = true;
      print('[ArtworkGenerator] Cache dir: $_cacheDir');
    } catch (e) {
      print('[ArtworkGenerator] Init error: $e');
    }
  }
  
  /// 获取或生成缩略图文件路径
  /// 返回本地文件绝对路径
  static Future<String?> getArtworkPath(String id, {String? title}) async {
    await _init();
    
    if (_cacheDir == null) {
      print('[ArtworkGenerator] Cache dir is null');
      return null;
    }
    
    final cacheKey = '${id}_${title ?? ""}';
    final filename = 'artwork_${id.hashCode}.jpg';
    final filepath = '$_cacheDir/$filename';
    
    // 检查内存缓存
    if (_cache.containsKey(cacheKey)) {
      final file = File(filepath);
      if (await file.exists()) {
        print('[ArtworkGenerator] Using cached: $filepath');
        return filepath;
      }
    }
    
    try {
      // 如果文件已存在，直接返回
      final file = File(filepath);
      if (await file.exists()) {
        _cache[cacheKey] = filepath;
        return filepath;
      }
      
      // 生成图片
      final bytes = await _generateArtwork(id, title);
      if (bytes == null) {
        print('[ArtworkGenerator] Failed to generate artwork');
        return null;
      }
      
      // 保存到缓存目录
      await file.writeAsBytes(bytes);
      
      print('[ArtworkGenerator] Saved artwork: $filepath (${bytes.length} bytes)');
      _cache[cacheKey] = filepath;
      
      return filepath;
    } catch (e) {
      print('[ArtworkGenerator] Error: $e');
      return null;
    }
  }
  
  /// 生成渐变色缩略图
  static Future<Uint8List?> _generateArtwork(String id, String? title) async {
    final colors = _getGradientColors(id);
    final initial = _getInitial(title ?? '');
    
    print('[ArtworkGenerator] Generating artwork for: $title, initial: $initial');
    
    // 创建图片 (512x512 用于通知栏)
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final size = const Size(512, 512);
    
    // 绘制渐变背景
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: colors,
    );
    
    final paint = Paint()
      ..shader = gradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
    
    // 绘制首字母
    final textPainter = TextPainter(
      text: TextSpan(
        text: initial,
        style: const TextStyle(
          fontSize: 220,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (size.width - textPainter.width) / 2,
        (size.height - textPainter.height) / 2,
      ),
    );
    
    // 生成图片
    final picture = recorder.endRecording();
    final image = await picture.toImage(size.width.toInt(), size.height.toInt());
    
    // 使用 PNG 格式
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      print('[ArtworkGenerator] Failed to encode image');
      return null;
    }
    
    return byteData.buffer.asUint8List();
  }
  
  /// 清理缓存（可选，定期调用）
  static Future<void> clearCache() async {
    if (_cacheDir == null) return;
    
    try {
      final dir = Directory(_cacheDir!);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
        await dir.create();
      }
      _cache.clear();
    } catch (e) {
      print('[ArtworkGenerator] Clear cache error: $e');
    }
  }
}
