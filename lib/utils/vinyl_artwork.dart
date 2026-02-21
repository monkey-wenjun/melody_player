import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

/// 黑胶唱片图标生成器
class VinylArtwork {
  static String? _cachedPath;
  
  /// 获取唱片图标路径
  static Future<String?> getVinylPath() async {
    if (_cachedPath != null) return _cachedPath;
    
    try {
      final appDir = await getApplicationSupportDirectory();
      final file = File('${appDir.path}/vinyl_icon.png');
      
      if (await file.exists()) {
        _cachedPath = file.path;
        return _cachedPath;
      }
      
      // 生成唱片图标
      final bytes = await _generateVinylIcon();
      if (bytes == null) return null;
      
      await file.writeAsBytes(bytes);
      _cachedPath = file.path;
      
      print('[VinylArtwork] Generated at: ${file.path}');
      return _cachedPath;
    } catch (e) {
      print('[VinylArtwork] Error: $e');
      return null;
    }
  }
  
  /// 生成黑胶唱片图标
  static Future<Uint8List?> _generateVinylIcon() async {
    const size = 512.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final center = Offset(size / 2, size / 2);
    
    // 绘制唱片背景（黑色）
    final bgPaint = Paint()
      ..color = const Color(0xFF1a1a1a)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, size / 2, bgPaint);
    
    // 绘制唱片纹路（同心圆）
    final groovePaint = Paint()
      ..color = const Color(0xFF2a2a2a)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    for (double r = 60; r < size / 2 - 20; r += 15) {
      canvas.drawCircle(center, r, groovePaint);
    }
    
    // 绘制标签区域（棕色渐变）
    final labelPaint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFF8B4513), Color(0xFF654321)],
      ).createShader(Rect.fromCircle(center: center, radius: 80));
    canvas.drawCircle(center, 80, labelPaint);
    
    // 绘制音乐符号
    final textPainter = TextPainter(
      text: const TextSpan(
        text: '♪',
        style: TextStyle(
          fontSize: 80,
          color: Colors.white70,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(center.dx - textPainter.width / 2, center.dy - textPainter.height / 2),
    );
    
    // 绘制中心孔
    final holePaint = Paint()
      ..color = const Color(0xFF1a1a1a)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 15, holePaint);
    
    // 绘制高光
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(size * 0.3, size * 0.25), width: 60, height: 120),
      highlightPaint,
    );
    
    // 生成图片
    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    
    return byteData?.buffer.asUint8List();
  }
}
