import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/media_scanner_service.dart';

// 全局缓存，避免重复查询
final Map<String, Uint8List?> _artworkCache = {};

class AlbumArt extends StatefulWidget {
  final String id;
  final ArtworkType type;
  final double size;
  final double borderRadius;
  final BoxFit fit;

  const AlbumArt({
    Key? key,
    required this.id,
    this.type = ArtworkType.AUDIO,
    this.size = 56,
    this.borderRadius = 8,
    this.fit = BoxFit.cover,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget child;
    if (!_loaded) {
      // 加载中显示占位图
      child = Icon(
        Icons.music_note,
        size: widget.size * 0.5,
        color: isDark ? Colors.grey[600] : Colors.grey[400],
      );
    } else if (_imageData != null) {
      // 显示图片
      child = Image.memory(
        _imageData!,
        fit: widget.fit,
        gaplessPlayback: true, // 避免闪烁
      );
    } else {
      // 无图片
      child = Icon(
        Icons.music_note,
        size: widget.size * 0.5,
        color: isDark ? Colors.grey[600] : Colors.grey[400],
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: Container(
        width: widget.size,
        height: widget.size,
        color: isDark ? Colors.grey[800] : Colors.grey[200],
        child: child,
      ),
    );
  }
}

class AlbumArtImage extends StatelessWidget {
  final Uint8List? imageData;
  final double size;
  final double borderRadius;

  const AlbumArtImage({
    Key? key,
    this.imageData,
    this.size = 56,
    this.borderRadius = 8,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        width: size,
        height: size,
        color: isDark ? Colors.grey[800] : Colors.grey[200],
        child: imageData != null
            ? Image.memory(imageData!, fit: BoxFit.cover, gaplessPlayback: true)
            : Icon(
                Icons.music_note,
                size: size * 0.5,
                color: isDark ? Colors.grey[600] : Colors.grey[400],
              ),
      ),
    );
  }
}

class LargeAlbumArt extends StatefulWidget {
  final String? id;
  final double size;

  const LargeAlbumArt({
    Key? key,
    this.id,
    this.size = 280,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget child;
    if (!_loaded || _imageData == null) {
      child = _buildPlaceholder(isDark);
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

  Widget _buildPlaceholder(bool isDark) {
    return Container(
      color: isDark ? const Color(0xFF2D2D4A) : const Color(0xFFE8E8E8),
      child: Center(
        child: Icon(
          Icons.music_note,
          size: widget.size * 0.3,
          color: isDark ? Colors.grey[600] : Colors.grey[400],
        ),
      ),
    );
  }
}
