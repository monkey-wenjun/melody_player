import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../../services/media_scanner_service.dart';

// 全局缓存，避免重复查询
final Map<String, Uint8List?> _artworkCache = {};

// 预定义的渐变配色方案
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

/// 获取标题的首字母（用于大字体显示）
String _getInitial(String title) {
  if (title.isEmpty) return '♪';
  // 取第一个非空字符
  final firstChar = title.trim()[0];
  // 如果是英文或数字，返回大写
  if (RegExp(r'[a-zA-Z0-9]').hasMatch(firstChar)) {
    return firstChar.toUpperCase();
  }
  // 否则返回该字符
  return firstChar;
}

/// 构建无封面时的占位图 Widget
class _DefaultCoverWidget extends StatelessWidget {
  final String id;
  final String? title;
  final String? artist;
  final double size;

  const _DefaultCoverWidget({
    required this.id,
    this.title,
    this.artist,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _getGradientColors(id);
    final isSmall = size < 60;
    final isMedium = size >= 60 && size < 100;
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: isSmall 
        ? _buildSmallLayout()
        : _buildLargeLayout(isMedium),
    );
  }

  /// 小尺寸布局：只显示首字母大图标
  Widget _buildSmallLayout() {
    return Center(
      child: Text(
        _getInitial(title ?? ''),
        style: TextStyle(
          fontSize: size * 0.45,
          fontWeight: FontWeight.bold,
          color: Colors.white.withOpacity(0.9),
        ),
      ),
    );
  }

  /// 中大尺寸布局：显示首字母 + 歌曲名/歌手名
  Widget _buildLargeLayout(bool isMedium) {
    return Padding(
      padding: EdgeInsets.all(size * 0.1),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 首字母大图标
          Text(
            _getInitial(title ?? ''),
            style: TextStyle(
              fontSize: isMedium ? size * 0.35 : size * 0.4,
              fontWeight: FontWeight.bold,
              color: Colors.white.withOpacity(0.95),
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
          SizedBox(height: size * 0.05),
          // 歌曲名
          if (title != null && title!.isNotEmpty)
            Text(
              title!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isMedium ? size * 0.1 : size * 0.08,
                fontWeight: FontWeight.w600,
                color: Colors.white.withOpacity(0.95),
              ),
            ),
          // 歌手名
          if (artist != null && artist!.isNotEmpty && !isMedium)
            Padding(
              padding: EdgeInsets.only(top: size * 0.02),
              child: Text(
                artist!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: size * 0.06,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class AlbumArt extends StatefulWidget {
  final String id;
  final ArtworkType type;
  final double size;
  final double borderRadius;
  final BoxFit fit;
  final String? title;
  final String? artist;

  const AlbumArt({
    Key? key,
    required this.id,
    this.type = ArtworkType.AUDIO,
    this.size = 56,
    this.borderRadius = 8,
    this.fit = BoxFit.cover,
    this.title,
    this.artist,
  }) : super(key: key);

  @override
  State<AlbumArt> createState() => _AlbumArtState();
}

class _AlbumArtState extends State<AlbumArt> {
  Uint8List? _imageData;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadArtwork();
  }

  @override
  void didUpdateWidget(AlbumArt oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.id != widget.id) {
      _loadArtwork();
    }
  }

  Future<void> _loadArtwork() async {
    // 检查缓存
    if (_artworkCache.containsKey(widget.id)) {
      setState(() {
        _imageData = _artworkCache[widget.id];
        _loaded = true;
      });
      return;
    }

    // 异步加载
    try {
      final data = await MediaScannerService().getArtwork(widget.id, type: widget.type);
      if (mounted) {
        setState(() {
          _imageData = data;
          _loaded = true;
        });
        // 存入缓存
        _artworkCache[widget.id] = data;
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loaded = true;
        });
        _artworkCache[widget.id] = null;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (!_loaded) {
      // 加载中显示渐变占位图
      child = _DefaultCoverWidget(
        id: widget.id,
        title: widget.title,
        artist: widget.artist,
        size: widget.size,
      );
    } else if (_imageData != null) {
      // 显示图片
      child = Image.memory(
        _imageData!,
        fit: widget.fit,
        gaplessPlayback: true, // 避免闪烁
      );
    } else {
      // 无图片时显示设计的默认封面
      child = _DefaultCoverWidget(
        id: widget.id,
        title: widget.title,
        artist: widget.artist,
        size: widget.size,
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: Container(
        width: widget.size,
        height: widget.size,
        color: Colors.grey[300],
        child: child,
      ),
    );
  }
}

class AlbumArtImage extends StatelessWidget {
  final Uint8List? imageData;
  final double size;
  final double borderRadius;
  final String? id;
  final String? title;
  final String? artist;

  const AlbumArtImage({
    Key? key,
    this.imageData,
    this.size = 56,
    this.borderRadius = 8,
    this.id,
    this.title,
    this.artist,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        width: size,
        height: size,
        color: Colors.grey[300],
        child: imageData != null
            ? Image.memory(imageData!, fit: BoxFit.cover, gaplessPlayback: true)
            : id != null
                ? _DefaultCoverWidget(
                    id: id!,
                    title: title,
                    artist: artist,
                    size: size,
                  )
                : Icon(
                    Icons.music_note,
                    size: size * 0.5,
                    color: Colors.grey[500],
                  ),
      ),
    );
  }
}

class LargeAlbumArt extends StatefulWidget {
  final String? id;
  final double size;
  final String? title;
  final String? artist;

  const LargeAlbumArt({
    Key? key,
    this.id,
    this.size = 280,
    this.title,
    this.artist,
  }) : super(key: key);

  @override
  State<LargeAlbumArt> createState() => _LargeAlbumArtState();
}

class _LargeAlbumArtState extends State<LargeAlbumArt> {
  Uint8List? _imageData;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadArtwork();
  }

  @override
  void didUpdateWidget(LargeAlbumArt oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.id != widget.id) {
      _loadArtwork();
    }
  }

  Future<void> _loadArtwork() async {
    if (widget.id == null) {
      setState(() {
        _loaded = true;
      });
      return;
    }

    // 检查缓存
    if (_artworkCache.containsKey(widget.id)) {
      setState(() {
        _imageData = _artworkCache[widget.id];
        _loaded = true;
      });
      return;
    }

    try {
      final data = await MediaScannerService().getArtwork(widget.id!);
      if (mounted) {
        setState(() {
          _imageData = data;
          _loaded = true;
        });
        _artworkCache[widget.id!] = data;
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loaded = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (!_loaded || _imageData == null) {
      child = widget.id != null
          ? _DefaultCoverWidget(
              id: widget.id!,
              title: widget.title,
              artist: widget.artist,
              size: widget.size,
            )
          : _buildFallbackPlaceholder();
    } else {
      child = Image.memory(
        _imageData!,
        fit: BoxFit.cover,
        gaplessPlayback: true,
      );
    }

    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: child,
      ),
    );
  }

  Widget _buildFallbackPlaceholder() {
    final colors = _getGradientColors('default');
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: Center(
        child: Text(
          '♪',
          style: TextStyle(
            fontSize: widget.size * 0.3,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
      ),
    );
  }
}
