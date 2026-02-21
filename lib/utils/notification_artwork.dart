import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// 通知栏缩略图生成器 - 在主 isolate 中生成
class NotificationArtwork {
  static final Map<String, String> _pathCache = {};
  
  /// 预定义的渐变配色
  static final List<List<Color>> _palettes = [
    [const Color(0xFF667eea), const Color(0xFF764ba2)],
    [const Color(0xFFf093fb), const Color(0xFFf5576c)],
    [const Color(0xFF4facfe), const Color(0xFF00f2fe)],
    [const Color(0xFF43e97b), const Color(0xFF38f9d7)],
    [const Color(0xFFfa709a), const Color(0xFFfee140)],
    [const Color(0xFF30cfd0), const Color(0xFF330867)],
    [const Color(0xFFa8edea), const Color(0xFFfed6e3)],
    [const Color(0xFFff9a9e), const Color(0xFFfecfef)],
    [const Color(0xFFffecd2), const Color(0xFFfcb69f)],
    [const Color(0xFF11998e), const Color(0xFF38ef7d)],
    [const Color(0xFFfc5c7d), const Color(0xFF6a82fb)],
  ];
  
  /// 获取颜色
  static List<Color> _getColors(String id) {
    int hash = 0;
    for (int i = 0; i < id.length; i++) {
      hash = ((hash << 5) - hash) + id.codeUnitAt(i);
      hash = hash & 0xFFFFFFFF;
    }
    return _palettes[hash.abs() % _palettes.length];
  }
  
  /// 获取首字母
  static String _getInitial(String? title) {
    if (title == null || title.isEmpty) return '♪';
    final c = title.trim()[0];
    if (RegExp(r'[a-zA-Z]').hasMatch(c)) return c.toUpperCase();
    return c;
  }
  
  /// 同步生成缩略图字节数据（必须在主 isolate 中调用）
  static Future<Uint8List?> generate(String id, String? title) async {
    try {
      final colors = _getColors(id);
      final initial = _getInitial(title);
      
      print('[NotificationArtwork] Generating for: $title');
      
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      const size = Size(400, 400);
      
      // 渐变背景
      final gradient = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: colors,
      );
      final paint = Paint()
        ..shader = gradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height));
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
      
      // 文字
      final textPainter = TextPainter(
        text: TextSpan(
          text: initial,
          style: const TextStyle(
            fontSize: 180,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset((size.width - textPainter.width) / 2, (size.height - textPainter.height) / 2),
      );
      
      final picture = recorder.endRecording();
      final image = await picture.toImage(400, 400);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      
      print('[NotificationArtwork] Generated ${byteData?.lengthInBytes ?? 0} bytes');
      return byteData?.buffer.asUint8List();
    } catch (e, stack) {
      print('[NotificationArtwork] Error: $e\n$stack');
      return null;
    }
  }
  
  /// 获取或创建 artwork，返回 content:// URI
  static Future<String?> getOrCreate(String id, String? title) async {
    final cacheKey = '${id}_$title';
    
    // 检查缓存
    if (_pathCache.containsKey(cacheKey)) {
      return _pathCache[cacheKey];
    }
    
    try {
      // 生成图片
      final bytes = await generate(id, title);
      if (bytes == null) return null;
      
      // 保存到 files/artworks 目录
      final appDir = await getApplicationSupportDirectory();
      final artworkDir = Directory('${appDir.path}/artworks');
      if (!await artworkDir.exists()) {
        await artworkDir.create(recursive: true);
      }
      
      final filename = 'art_${id.hashCode}.png';
      final file = File('${artworkDir.path}/$filename');
      await file.writeAsBytes(bytes);
      
      // 构建 content:// URI
      final uri = 'content://com.melody.melody_player.fileprovider/artworks/$filename';
      _pathCache[cacheKey] = uri;
      
      print('[NotificationArtwork] Saved to: $file');
      print('[NotificationArtwork] URI: $uri');
      
      return uri;
    } catch (e, stack) {
      print('[NotificationArtwork] Error: $e\n$stack');
      return null;
    }
  }
}
