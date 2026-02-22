import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/player_provider.dart';
import '../common/album_art.dart';
import 'player_styles.dart';

/// 5. 复古磁带播放器
class RetroCassettePlayer extends PlayerStyleWidget {
  const RetroCassettePlayer({
    Key? key,
    required String songId,
    double size = 320,
    String? title,
    String? artist,
  }) : super(key: key, songId: songId, size: size, title: title, artist: artist);

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerProvider>(
      builder: (context, player, child) {
        return Container(
          width: size * 0.9,
          height: size * 0.6,
          decoration: BoxDecoration(
            color: const Color(0xFF3d3d3d),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 磁带窗口
              Container(
                width: size * 0.7,
                height: size * 0.35,
                decoration: BoxDecoration(
                  color: const Color(0xFF2a2a2a),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF555555),
                    width: 3,
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // 专辑封面
                    ClipRect(
                      child: AlbumArt(
                        id: songId,
                        size: size * 0.3,
                        borderRadius: 0,
                        fit: BoxFit.cover,
                        title: title,
                        artist: artist,
                      ),
                    ),
                    // 左右卷轴
                    Positioned(
                      left: size * 0.05,
                      child: _CassetteReel(
                        isPlaying: player.isPlaying,
                        size: size * 0.15,
                      ),
                    ),
                    Positioned(
                      right: size * 0.05,
                      child: _CassetteReel(
                        isPlaying: player.isPlaying,
                        size: size * 0.15,
                        reverse: true,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // 标签区域
              Container(
                width: size * 0.6,
                height: size * 0.08,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8D5B7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(
                  child: Text(
                    'A SIDE',
                    style: TextStyle(
                      fontSize: size * 0.04,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF333333),
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CassetteReel extends StatefulWidget {
  final bool isPlaying;
  final double size;
  final bool reverse;

  const _CassetteReel({
    required this.isPlaying,
    required this.size,
    this.reverse = false,
  });

  @override
  State<_CassetteReel> createState() => _CassetteReelState();
}

class _CassetteReelState extends State<_CassetteReel>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    if (widget.isPlaying) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant _CassetteReel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying) {
      _controller.repeat();
    } else {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.rotate(
          angle: widget.reverse
              ? -_controller.value * 2 * math.pi
              : _controller.value * 2 * math.pi,
          child: child,
        );
      },
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF1a1a1a),
          border: Border.all(color: const Color(0xFF444444), width: 2),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            for (var i = 0; i < 6; i++)
              Transform.rotate(
                angle: i * math.pi / 3,
                child: Container(
                  width: widget.size * 0.15,
                  height: widget.size * 0.5,
                  decoration: BoxDecoration(
                    color: const Color(0xFF333333),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 6. 霓虹脉冲样式
class NeonPulsePlayer extends PlayerStyleWidget {
  const NeonPulsePlayer({
    Key? key,
    required String songId,
    double size = 320,
    String? title,
    String? artist,
  }) : super(key: key, songId: songId, size: size, title: title, artist: artist);

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    return Consumer<PlayerProvider>(
      builder: (context, player, child) {
        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 多层脉冲圆环
              for (var i = 0; i < 3; i++)
                _PulseRing(
                  size: size * (0.5 + i * 0.15),
                  isPlaying: player.isPlaying,
                  delay: i * 0.3,
                  color: primaryColor.withOpacity(0.3 - i * 0.1),
                ),
              // 中心专辑封面
              Container(
                width: size * 0.5,
                height: size * 0.5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.5),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                  border: Border.all(
                    color: primaryColor,
                    width: 3,
                  ),
                ),
                child: ClipOval(
                  child: AlbumArt(
                    id: songId,
                    size: size * 0.5,
                    borderRadius: 0,
                    fit: BoxFit.cover,
                    title: title,
                    artist: artist,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PulseRing extends StatefulWidget {
  final double size;
  final bool isPlaying;
  final double delay;
  final Color color;

  const _PulseRing({
    required this.size,
    required this.isPlaying,
    required this.delay,
    required this.color,
  });

  @override
  State<_PulseRing> createState() => _PulseRingState();
}

class _PulseRingState extends State<_PulseRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    Future.delayed(Duration(milliseconds: (widget.delay * 1000).toInt()), () {
      if (mounted && widget.isPlaying) _controller.repeat();
    });
  }

  @override
  void didUpdateWidget(covariant _PulseRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying) {
      _controller.repeat();
    } else {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.size + (_controller.value * 20),
          height: widget.size + (_controller.value * 20),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: widget.color.withOpacity(1 - _controller.value),
              width: 2,
            ),
          ),
        );
      },
    );
  }
}

/// 7. 粒子星云样式
class ParticleNebulaPlayer extends PlayerStyleWidget {
  const ParticleNebulaPlayer({
    Key? key,
    required String songId,
    double size = 320,
    String? title,
    String? artist,
  }) : super(key: key, songId: songId, size: size, title: title, artist: artist);

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerProvider>(
      builder: (context, player, child) {
        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 粒子效果
              CustomPaint(
                size: Size(size, size),
                painter: ParticlePainter(
                  isPlaying: player.isPlaying,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              // 中心封面
              Container(
                width: size * 0.45,
                height: size * 0.45,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                      blurRadius: 40,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: AlbumArt(
                    id: songId,
                    size: size * 0.45,
                    borderRadius: 0,
                    fit: BoxFit.cover,
                    title: title,
                    artist: artist,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class ParticlePainter extends CustomPainter with ChangeNotifier {
  final bool isPlaying;
  final Color color;
  var _animationValue = 0.0;

  ParticlePainter({required this.isPlaying, required this.color}) {
    if (isPlaying) {
      _startAnimation();
    }
  }

  void _startAnimation() async {
    while (isPlaying) {
      await Future.delayed(const Duration(milliseconds: 50));
      _animationValue += 0.02;
      if (_animationValue > 1) _animationValue = 0;
      notifyListeners();
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final random = math.Random(42);

    for (var i = 0; i < 30; i++) {
      final angle = random.nextDouble() * 2 * math.pi;
      final radius = size.width * 0.25 + random.nextDouble() * size.width * 0.25;
      final particleSize = 2.0 + random.nextDouble() * 4;
      final opacity = 0.3 + random.nextDouble() * 0.5;

      final x = center.dx + math.cos(angle + _animationValue * 2 * math.pi) * radius;
      final y = center.dy + math.sin(angle + _animationValue * 2 * math.pi) * radius;

      final paint = Paint()
        ..color = color.withOpacity(opacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), particleSize, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => isPlaying;
}

/// 8. 频谱瀑布样式
class SpectrumWaterfallPlayer extends PlayerStyleWidget {
  const SpectrumWaterfallPlayer({
    Key? key,
    required String songId,
    double size = 320,
    String? title,
    String? artist,
  }) : super(key: key, songId: songId, size: size, title: title, artist: artist);

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerProvider>(
      builder: (context, player, child) {
        return Container(
          width: size * 0.8,
          height: size,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.8),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
              width: 2,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 专辑封面
              Container(
                width: size * 0.5,
                height: size * 0.5,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: AlbumArt(
                    id: songId,
                    size: size * 0.5,
                    borderRadius: 0,
                    fit: BoxFit.cover,
                    title: title,
                    artist: artist,
                  ),
                ),
              ),
              // 频谱条
              SizedBox(
                height: size * 0.2,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(12, (index) {
                    return _SpectrumBar(
                      index: index,
                      isPlaying: player.isPlaying,
                      color: Theme.of(context).colorScheme.primary,
                    );
                  }),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SpectrumBar extends StatefulWidget {
  final int index;
  final bool isPlaying;
  final Color color;

  const _SpectrumBar({
    required this.index,
    required this.isPlaying,
    required this.color,
  });

  @override
  State<_SpectrumBar> createState() => _SpectrumBarState();
}

class _SpectrumBarState extends State<_SpectrumBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 400 + widget.index * 50),
    );
    if (widget.isPlaying) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _SpectrumBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying) {
      _controller.repeat(reverse: true);
    } else {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final height = widget.isPlaying
            ? 0.3 + (_controller.value * 0.7) + (_random.nextDouble() * 0.2)
            : 0.1;
        return Container(
          width: 8,
          height: 60 * height,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                widget.color.withOpacity(0.2),
                widget.color,
              ],
            ),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      },
    );
  }
}

/// 9. 魔法光环样式
class MagicAuraPlayer extends PlayerStyleWidget {
  const MagicAuraPlayer({
    Key? key,
    required String songId,
    double size = 320,
    String? title,
    String? artist,
  }) : super(key: key, songId: songId, size: size, title: title, artist: artist);

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerProvider>(
      builder: (context, player, child) {
        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 旋转的光环
              _RotatingAura(
                size: size * 0.9,
                isPlaying: player.isPlaying,
                color: Theme.of(context).colorScheme.primary,
              ),
              _RotatingAura(
                size: size * 0.75,
                isPlaying: player.isPlaying,
                color: Theme.of(context).colorScheme.secondary,
                reverse: true,
              ),
              // 中心封面
              Container(
                width: size * 0.5,
                height: size * 0.5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: AlbumArt(
                    id: songId,
                    size: size * 0.5,
                    borderRadius: 0,
                    fit: BoxFit.cover,
                    title: title,
                    artist: artist,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RotatingAura extends StatefulWidget {
  final double size;
  final bool isPlaying;
  final Color color;
  final bool reverse;

  const _RotatingAura({
    required this.size,
    required this.isPlaying,
    required this.color,
    this.reverse = false,
  });

  @override
  State<_RotatingAura> createState() => _RotatingAuraState();
}

class _RotatingAuraState extends State<_RotatingAura>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    if (widget.isPlaying) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant _RotatingAura oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying) {
      _controller.repeat();
    } else {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.rotate(
          angle: widget.reverse
              ? -_controller.value * 2 * math.pi
              : _controller.value * 2 * math.pi,
          child: child,
        );
      },
      child: CustomPaint(
        size: Size(widget.size, widget.size),
        painter: AuraPainter(color: widget.color),
      ),
    );
  }
}

class AuraPainter extends CustomPainter {
  final Color color;

  AuraPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = color.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (var i = 0; i < 8; i++) {
      final path = Path();
      final angle = i * math.pi / 4;
      final radius = size.width * 0.4;

      path.moveTo(
        center.dx + math.cos(angle) * radius * 0.5,
        center.dy + math.sin(angle) * radius * 0.5,
      );
      path.quadraticBezierTo(
        center.dx + math.cos(angle + math.pi / 8) * radius * 1.2,
        center.dy + math.sin(angle + math.pi / 8) * radius * 1.2,
        center.dx + math.cos(angle + math.pi / 4) * radius * 0.5,
        center.dy + math.sin(angle + math.pi / 4) * radius * 0.5,
      );

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 10. 均衡器样式
class EqualizerPlayer extends PlayerStyleWidget {
  const EqualizerPlayer({
    Key? key,
    required String songId,
    double size = 320,
    String? title,
    String? artist,
  }) : super(key: key, songId: songId, size: size, title: title, artist: artist);

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerProvider>(
      builder: (context, player, child) {
        return Container(
          width: size * 0.85,
          height: size * 0.85,
          decoration: BoxDecoration(
            gradient: RadialGradient(
              colors: [
                Colors.grey[900]!,
                Colors.black,
              ],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 均衡器环
              CustomPaint(
                size: Size(size * 0.7, size * 0.7),
                painter: EqualizerPainter(
                  isPlaying: player.isPlaying,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              // 中心封面
              Container(
                width: size * 0.35,
                height: size * 0.35,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  ),
                ),
                child: ClipOval(
                  child: AlbumArt(
                    id: songId,
                    size: size * 0.35,
                    borderRadius: 0,
                    fit: BoxFit.cover,
                    title: title,
                    artist: artist,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class EqualizerPainter extends CustomPainter with ChangeNotifier {
  final bool isPlaying;
  final Color color;
  var _animationValue = 0.0;

  EqualizerPainter({required this.isPlaying, required this.color}) {
    if (isPlaying) {
      _startAnimation();
    }
  }

  void _startAnimation() async {
    while (isPlaying) {
      await Future.delayed(const Duration(milliseconds: 80));
      _animationValue += 0.1;
      notifyListeners();
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final barCount = 16;
    final barWidth = (2 * math.pi * radius) / barCount * 0.6;

    for (var i = 0; i < barCount; i++) {
      final angle = (i / barCount) * 2 * math.pi - math.pi / 2;
      final barHeight = isPlaying
          ? 15.0 + math.sin(_animationValue + i * 0.5) * 25.0
          : 10.0;

      final paint = Paint()
        ..color = color.withOpacity(0.6 + math.sin(_animationValue + i) * 0.4)
        ..style = PaintingStyle.fill;

      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(
            center.dx + math.cos(angle) * (radius - 10),
            center.dy + math.sin(angle) * (radius - 10),
          ),
          width: barWidth,
          height: barHeight,
        ),
        Radius.circular(barWidth / 2),
      );

      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(angle + math.pi / 2);
      canvas.translate(-center.dx, -center.dy);
      canvas.drawRRect(rect, paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => isPlaying;
}

/// 11. 水滴波纹样式
class RipplePlayer extends PlayerStyleWidget {
  const RipplePlayer({
    Key? key,
    required String songId,
    double size = 320,
    String? title,
    String? artist,
  }) : super(key: key, songId: songId, size: size, title: title, artist: artist);

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerProvider>(
      builder: (context, player, child) {
        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 多层波纹
              for (var i = 0; i < 4; i++)
                _WaterRipple(
                  size: size * (0.4 + i * 0.15),
                  isPlaying: player.isPlaying,
                  delay: i * 0.4,
                  color: Theme.of(context).colorScheme.primary,
                ),
              // 中心封面
              Container(
                width: size * 0.4,
                height: size * 0.4,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: AlbumArt(
                    id: songId,
                    size: size * 0.4,
                    borderRadius: 0,
                    fit: BoxFit.cover,
                    title: title,
                    artist: artist,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _WaterRipple extends StatefulWidget {
  final double size;
  final bool isPlaying;
  final double delay;
  final Color color;

  const _WaterRipple({
    required this.size,
    required this.isPlaying,
    required this.delay,
    required this.color,
  });

  @override
  State<_WaterRipple> createState() => _WaterRippleState();
}

class _WaterRippleState extends State<_WaterRipple>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    Future.delayed(Duration(milliseconds: (widget.delay * 1000).toInt()), () {
      if (mounted && widget.isPlaying) _controller.repeat();
    });
  }

  @override
  void didUpdateWidget(covariant _WaterRipple oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying) {
      _controller.repeat();
    } else {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: widget.color.withOpacity((1 - _controller.value) * 0.5),
              width: 2 + _controller.value * 2,
            ),
          ),
        );
      },
    );
  }
}

/// 12. 赛博朋克样式
class CyberpunkPlayer extends PlayerStyleWidget {
  const CyberpunkPlayer({
    Key? key,
    required String songId,
    double size = 320,
    String? title,
    String? artist,
  }) : super(key: key, songId: songId, size: size, title: title, artist: artist);

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerProvider>(
      builder: (context, player, child) {
        return Container(
          width: size * 0.9,
          height: size * 0.9,
          decoration: BoxDecoration(
            color: const Color(0xFF0a0a0a),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF00ffff),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00ffff).withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 扫描线效果
              if (player.isPlaying)
                Positioned.fill(
                  child: AnimatedScanLines(),
                ),
              // 角标装饰
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Color(0xFFff00ff), width: 3),
                      left: BorderSide(color: Color(0xFFff00ff), width: 3),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Color(0xFFff00ff), width: 3),
                      right: BorderSide(color: Color(0xFFff00ff), width: 3),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 10,
                left: 10,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFff00ff), width: 3),
                      left: BorderSide(color: Color(0xFFff00ff), width: 3),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 10,
                right: 10,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFff00ff), width: 3),
                      right: BorderSide(color: Color(0xFFff00ff), width: 3),
                    ),
                  ),
                ),
              ),
              // 中心封面
              Container(
                width: size * 0.55,
                height: size * 0.55,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: const Color(0xFF00ffff),
                    width: 2,
                  ),
                ),
                child: AlbumArt(
                  id: songId,
                  size: size * 0.55,
                  borderRadius: 0,
                  fit: BoxFit.cover,
                  title: title,
                  artist: artist,
                ),
              ),
              // 底部状态文字
              Positioned(
                bottom: 25,
                child: Text(
                  player.isPlaying ? '▶ PLAYING' : '❚❚ PAUSED',
                  style: const TextStyle(
                    color: Color(0xFF00ffff),
                    fontSize: 12,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class AnimatedScanLines extends StatefulWidget {
  @override
  State<AnimatedScanLines> createState() => _AnimatedScanLinesState();
}

class _AnimatedScanLinesState extends State<AnimatedScanLines>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: ScanLinePainter(progress: _controller.value),
        );
      },
    );
  }
}

class ScanLinePainter extends CustomPainter {
  final double progress;

  ScanLinePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00ffff).withOpacity(0.1)
      ..style = PaintingStyle.fill;

    final y = size.height * progress;
    canvas.drawRect(
      Rect.fromLTWH(0, y - 2, size.width, 4),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// 13. 3D旋转卡片
class Card3DPlayer extends PlayerStyleWidget {
  const Card3DPlayer({
    Key? key,
    required String songId,
    double size = 320,
    String? title,
    String? artist,
  }) : super(key: key, songId: songId, size: size, title: title, artist: artist);

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerProvider>(
      builder: (context, player, child) {
        return _Animated3DCard(
          isPlaying: player.isPlaying,
          child: Container(
            width: size * 0.65,
            height: size * 0.65,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AlbumArt(
                id: songId,
                size: size * 0.65,
                borderRadius: 0,
                fit: BoxFit.cover,
                title: title,
                artist: artist,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Animated3DCard extends StatefulWidget {
  final bool isPlaying;
  final Widget child;

  const _Animated3DCard({required this.isPlaying, required this.child});

  @override
  State<_Animated3DCard> createState() => _Animated3DCardState();
}

class _Animated3DCardState extends State<_Animated3DCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );
    if (widget.isPlaying) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant _Animated3DCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying) {
      _controller.repeat();
    } else {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final angle = math.sin(_controller.value * 2 * math.pi) * 0.15;
        return Transform(
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(angle),
          alignment: Alignment.center,
          child: widget.child,
        );
      },
    );
  }
}

/// 14. 光盘盒样式
class CDCasePlayer extends PlayerStyleWidget {
  const CDCasePlayer({
    Key? key,
    required String songId,
    double size = 320,
    String? title,
    String? artist,
  }) : super(key: key, songId: songId, size: size, title: title, artist: artist);

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerProvider>(
      builder: (context, player, child) {
        return Container(
          width: size * 0.85,
          height: size * 0.85,
          decoration: BoxDecoration(
            color: const Color(0xFF1a1a2e),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 20,
                offset: const Offset(5, 5),
              ),
            ],
          ),
          child: Stack(
            children: [
              // 背景封面
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: AlbumArt(
                    id: songId,
                    size: size * 0.85,
                    borderRadius: 0,
                    fit: BoxFit.cover,
                    title: title,
                    artist: artist,
                  ),
                ),
              ),
              // 半透明遮罩
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.1),
                        Colors.transparent,
                        Colors.black.withOpacity(0.2),
                      ],
                    ),
                  ),
                ),
              ),
              // 塑料盒边框
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 3,
                    ),
                  ),
                ),
              ),
              // 中心圆孔
              Center(
                child: Container(
                  width: size * 0.15,
                  height: size * 0.15,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF1a1a2e),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.5),
                      width: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
