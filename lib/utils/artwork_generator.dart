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
  
  /// 获取或生成缩略图文件路径
  /// 返回本地文件 URI (file://...)
  static Future<String?> getArtworkUri(String id, {String? title}) async {
    final cacheKey = '${id}_${title ?? ""}';
    
    // 检查内存缓存
    if (_cache.containsKey(cacheKey)) {
      final file = File(_cache[cacheKey]!);
      if (await file.exists()) {
        return _cache[cacheKey];
      }
    }
    
    try {
      // 生成图片
      final bytes = await _generateArtwork(id, title);
      if (bytes == null) return null;
      
      // 保存到缓存目录
      final dir = await getTemporaryDirectory();
      final filename = 'artwork_${id.hashCode}.png';
      final file = File('${dir.path}/$filename');
      
      await file.writeAsBytes(bytes);
      
      final uri = file.uri.toString();
      _cache[cacheKey] = uri;
      
      return uri;
    } catch (e) {
      print('ArtworkGenerator error: $e');
      return null;
    }
  }
  
  /// 生成渐变色缩略图
  static Future<Uint8List?> _generateArtwork(String id, String? title) async {
    final colors = _getGradientColors(id);
    final initial = _getInitial(title ?? '');
    
    // 创建图片 (500x500 用于通知栏)
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final size = const Size(500, 500);
    
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
          fontSize: 200,
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
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    
    return byteData?.buffer.asUint8List();
  }
  
  /// 清理缓存（可选，定期调用）
  static Future<void> clearCache() async {
    for (final uri in _cache.values) {
      try {
        final file = File(Uri.parse(uri).path);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {}
    }
    _cache.clear();
  }
}
