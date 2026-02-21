import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;

/// 预定义的渐变配色方案 (RGB格式)
final List<List<int>> _gradientPalettes = [
  [0xFF667eea, 0xFF764ba2], // 紫蓝渐变
  [0xFFf093fb, 0xFFf5576c], // 粉紫渐变
  [0xFF4facfe, 0xFF00f2fe], // 青色渐变
  [0xFF43e97b, 0xFF38f9d7], // 绿色渐变
  [0xFFfa709a, 0xFFfee140], // 橙粉渐变
  [0xFF30cfd0, 0xFF330867], // 深青紫渐变
  [0xFFa8edea, 0xFFfed6e3], // 柔和粉青
  [0xFFff9a9e, 0xFFfecfef], // 浅粉渐变
  [0xFFffecd2, 0xFFfcb69f], // 暖橙渐变
  [0xFF11998e, 0xFF38ef7d], // 翠绿渐变
  [0xFFfc5c7d, 0xFF6a82fb], // 粉蓝渐变
];

/// 根据ID获取一致的渐变颜色
List<int> _getGradientColors(String id) {
  int hash = 0;
  for (int i = 0; i < id.length; i++) {
    hash = ((hash << 5) - hash) + id.codeUnitAt(i);
    hash = hash & 0xFFFFFFFF;
  }
  return _gradientPalettes[hash.abs() % _gradientPalettes.length];
}

/// 获取标题的首字母
String _getInitial(String? title) {
  if (title == null || title.isEmpty) return '♪';
  final c = title.trim()[0];
  if (RegExp(r'[a-zA-Z]').hasMatch(c)) return c.toUpperCase();
  return c;
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
      // 使用外部缓存目录，FileProvider 可以访问
      final dir = await getExternalCacheDirectories();
      if (dir != null && dir.isNotEmpty) {
        _cacheDir = dir.first.path;
      } else {
        _cacheDir = (await getTemporaryDirectory()).path;
      }
      
      _initialized = true;
      print('[ArtworkGenerator] Cache dir: $_cacheDir');
    } catch (e) {
      print('[ArtworkGenerator] Init error: $e');
    }
  }
  
  /// 获取或生成缩略图，返回 base64 data URI
  /// 使用 data URI 避免 FileProvider 权限问题
  static Future<String?> getArtworkUri(String id, {String? title}) async {
    try {
      final cacheKey = '${id}_$title';
      
      // 检查内存缓存
      if (_cache.containsKey(cacheKey)) {
        print('[ArtworkGenerator] Using memory cache');
        return _cache[cacheKey];
      }
      
      // 生成图片
      print('[ArtworkGenerator] Generating artwork for: $title');
      final bytes = await _generateArtwork(id, title);
      if (bytes == null) {
        print('[ArtworkGenerator] Failed to generate artwork');
        return null;
      }
      
      // 转换为 base64 data URI
      final base64 = base64Encode(bytes);
      final dataUri = 'data:image/png;base64,$base64';
      
      print('[ArtworkGenerator] Generated data URI: ${dataUri.substring(0, 50)}... (${bytes.length} bytes)');
      _cache[cacheKey] = dataUri;
      
      return dataUri;
    } catch (e, stack) {
      print('[ArtworkGenerator] Error: $e\n$stack');
      return null;
    }
  }
  
  /// 生成渐变色缩略图 - 使用纯 Dart 的 image 库
  static Future<Uint8List?> _generateArtwork(String id, String? title) async {
    try {
      final colors = _getGradientColors(id);
      final initial = _getInitial(title);
      
      const width = 512;
      const height = 512;
      
      // 创建图片
      final image = img.Image(width: width, height: height);
      
      // 解析颜色
      final color1 = img.ColorRgb8(
        (colors[0] >> 16) & 0xFF,
        (colors[0] >> 8) & 0xFF,
        colors[0] & 0xFF,
      );
      final color2 = img.ColorRgb8(
        (colors[1] >> 16) & 0xFF,
        (colors[1] >> 8) & 0xFF,
        colors[1] & 0xFF,
      );
      
      // 绘制渐变背景 (对角线渐变)
      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final t = (x + y) / (width + height);
          final r = (color1.r * (1 - t) + color2.r * t).toInt();
          final g = (color1.g * (1 - t) + color2.g * t).toInt();
          final b = (color1.b * (1 - t) + color2.b * t).toInt();
          image.setPixel(x, y, img.ColorRgb8(r, g, b));
        }
      }
      
      // 绘制白色半透明圆形背景
      final centerX = width ~/ 2;
      final centerY = height ~/ 2;
      final radius = 140;
      
      for (int y = centerY - radius; y <= centerY + radius; y++) {
        for (int x = centerX - radius; x <= centerX + radius; x++) {
          if (x < 0 || x >= width || y < 0 || y >= height) continue;
          final dx = x - centerX;
          final dy = y - centerY;
          if (dx * dx + dy * dy <= radius * radius) {
            final pixel = image.getPixel(x, y);
            // 半透明白色叠加
            final alpha = 0.25;
            final r = (pixel.r * (1 - alpha) + 255 * alpha).toInt();
            final g = (pixel.g * (1 - alpha) + 255 * alpha).toInt();
            final b = (pixel.b * (1 - alpha) + 255 * alpha).toInt();
            image.setPixel(x, y, img.ColorRgb8(r, g, b));
          }
        }
      }
      
      // 编码为 PNG
      final png = img.encodePng(image);
      return Uint8List.fromList(png);
    } catch (e, stack) {
      print('[ArtworkGenerator] Generate error: $e\n$stack');
      return null;
    }
  }
}
