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
  
  /// 获取或生成缩略图，返回 content:// URI
  static Future<String?> getArtworkUri(String id, {String? title}) async {
    await _init();
    
    if (_cacheDir == null) return null;
    
    final cacheKey = '${id}_$title';
    final filename = 'artwork_${id.hashCode}.png';
    final filepath = '$_cacheDir/$filename';
    
    // 构建 content:// URI
    final uri = 'content://com.melody.melody_player.fileprovider/external_cache/$filename';
    
    // 检查内存缓存
    if (_cache.containsKey(cacheKey)) {
      final file = File(filepath);
      if (await file.exists()) {
        print('[ArtworkGenerator] Using cached: $uri');
        return uri;
      }
    }
    
    try {
      // 如果文件已存在，直接返回
      final file = File(filepath);
      if (await file.exists()) {
        _cache[cacheKey] = uri;
        print('[ArtworkGenerator] File exists: $filepath');
        return uri;
      }
      
      // 生成图片
      print('[ArtworkGenerator] Generating artwork for: $title');
      final bytes = await _generateArtwork(id, title);
      if (bytes == null) {
        print('[ArtworkGenerator] Failed to generate artwork');
        return null;
      }
      
      // 保存到缓存目录
      await file.writeAsBytes(bytes);
      
      print('[ArtworkGenerator] Saved: $filepath (${bytes.length} bytes), URI: $uri');
      _cache[cacheKey] = uri;
      
      return uri;
    } catch (e, stack) {
      print('[ArtworkGenerator] Error: $e\n$stack');
      return null;
    }
  }
  
  /// 生成渐变色缩略图 - 使用纯 Dart 的 image 库，不依赖 dart:ui
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
          final t = (x + y) / (width + height); // 对角线插值
          final r = (color1.r * (1 - t) + color2.r * t).toInt();
          final g = (color1.g * (1 - t) + color2.g * t).toInt();
          final b = (color1.b * (1 - t) + color2.b * t).toInt();
          image.setPixel(x, y, img.ColorRgb8(r, g, b));
        }
      }
      
      // 绘制文字 - 使用简单的矩形代替文字
      // 由于 image 库的文字渲染比较复杂，我们用圆形+首字母的方式简化
      final centerX = width ~/ 2;
      final centerY = height ~/ 2;
      final radius = 120;
      
      // 绘制白色半透明圆形背景
      for (int y = centerY - radius; y <= centerY + radius; y++) {
        for (int x = centerX - radius; x <= centerX + radius; x++) {
          final dx = x - centerX;
          final dy = y - centerY;
          if (dx * dx + dy * dy <= radius * radius) {
            // 半透明白色
            final pixel = image.getPixel(x, y);
            final r = (pixel.r * 0.7 + 255 * 0.3).toInt();
            final g = (pixel.g * 0.7 + 255 * 0.3).toInt();
            final b = (pixel.b * 0.7 + 255 * 0.3).toInt();
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
