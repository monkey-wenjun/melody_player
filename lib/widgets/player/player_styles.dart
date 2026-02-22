import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/player_provider.dart';
import '../../providers/settings_provider.dart';
import '../common/album_art.dart';

/// 播放器样式基类
abstract class PlayerStyleWidget extends StatelessWidget {
  final String songId;
  final double size;
  final String? title;
  final String? artist;

  const PlayerStyleWidget({
    Key? key,
    required this.songId,
    this.size = 320,
    this.title,
    this.artist,
  }) : super(key: key);
}

/// 1. 黑胶唱片样式（原版）
class VinylPlayer extends PlayerStyleWidget {
  const VinylPlayer({
    Key? key,
    required String songId,
    double size = 320,
    String? title,
    String? artist,
  }) : super(key: key, songId: songId, size: size, title: title, artist: artist);

  @override
  Widget build(BuildContext context) {
    return VinylPlayerWithArm(
      songId: songId,
      size: size,
      title: title,
      artist: artist,
    );
  }
}

/// 2. 波形可视化样式
class WaveformPlayer extends PlayerStyleWidget {
  const WaveformPlayer({
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
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                Theme.of(context).colorScheme.primary.withOpacity(0.3),
                Theme.of(context).colorScheme.primary.withOpacity(0.1),
                Colors.transparent,
              ],
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 专辑封面
              ClipOval(
                child: Container(
                  width: size * 0.7,
                  height: size * 0.7,
                  color: Colors.grey[900],
                  child: AlbumArt(
                    id: songId,
                    size: size * 0.7,
                    borderRadius: 0,
                    fit: BoxFit.cover,
                    title: title,
                    artist: artist,
                  ),
                ),
              ),
              // 波形圆环
              AnimatedWaveformRing(
                size: size * 0.9,
                isPlaying: player.isPlaying,
              ),
              // 内圈装饰
              Container(
                width: size * 0.75,
                height: size * 0.75,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                    width: 2,
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

/// 动画波形圆环
class AnimatedWaveformRing extends StatefulWidget {
  final double size;
  final bool isPlaying;

  const AnimatedWaveformRing({
    Key? key,
    required this.size,
    required this.isPlaying,
  }) : super(key: key);

  @override
  State<AnimatedWaveformRing> createState() => _AnimatedWaveformRingState();
}

class _AnimatedWaveformRingState extends State<AnimatedWaveformRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    if (widget.isPlaying) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedWaveformRing oldWidget) {
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
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: WaveformRingPainter(
            progress: _controller.value,
            color: Theme.of(context).colorScheme.primary,
            isPlaying: widget.isPlaying,
          ),
        );
      },
    );
  }
}

class WaveformRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final bool isPlaying;

  WaveformRingPainter({
    required this.progress,
    required this.color,
    required this.isPlaying,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const barCount = 60;
    final barWidth = (2 * math.pi * radius) / barCount * 0.6;

    for (var i = 0; i < barCount; i++) {
      final angle = (i / barCount) * 2 * math.pi - math.pi / 2;
      final barHeight = isPlaying
          ? 8.0 + math.sin((i * 0.3) + (progress * 2 * math.pi)) * 15.0 + (math.Random().nextDouble() * 5.0)
          : 8.0;

      final paint = Paint()
        ..color = color.withOpacity(0.3 + (i % 5) * 0.1)
        ..style = PaintingStyle.fill;

      final barRect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(
            center.dx + math.cos(angle) * (radius - barHeight / 2),
            center.dy + math.sin(angle) * (radius - barHeight / 2),
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
      canvas.drawRRect(barRect, paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// 3. 旋转光盘样式
class RotatingDiscPlayer extends PlayerStyleWidget {
  const RotatingDiscPlayer({
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
        return Stack(
          alignment: Alignment.center,
          children: [
            // 外圈旋转光环
            AnimatedRotation(
              isPlaying: player.isPlaying,
              size: size,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: SweepGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary.withOpacity(0.0),
                      Theme.of(context).colorScheme.primary.withOpacity(0.5),
                      Theme.of(context).colorScheme.primary.withOpacity(0.0),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),
            // 光盘主体
            AnimatedRotation(
              isPlaying: player.isPlaying,
              duration: const Duration(seconds: 4),
              size: size * 0.85,
              child: Container(
                width: size * 0.85,
                height: size * 0.85,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [
                      Color(0xFF2a2a2a),
                      Color(0xFF1a1a1a),
                      Color(0xFF0a0a0a),
                    ],
                    stops: [0.3, 0.7, 1.0],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Center(
                  child: Container(
                    width: size * 0.55,
                    height: size * 0.55,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.grey[700]!,
                        width: 2,
                      ),
                    ),
                    child: ClipOval(
                      child: AlbumArt(
                        id: songId,
                        size: size * 0.55,
                        borderRadius: 0,
                        fit: BoxFit.cover,
                        title: title,
                        artist: artist,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // 中心孔
            Container(
              width: size * 0.08,
              height: size * 0.08,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF1a1a1a),
                border: Border.all(
                  color: Colors.grey[600]!,
                  width: 1,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// 旋转动画组件
class AnimatedRotation extends StatefulWidget {
  final bool isPlaying;
  final Widget child;
  final double size;
  final Duration duration;

  const AnimatedRotation({
    Key? key,
    required this.isPlaying,
    required this.child,
    required this.size,
    this.duration = const Duration(seconds: 8),
  }) : super(key: key);

  @override
  State<AnimatedRotation> createState() => _AnimatedRotationState();
}

class _AnimatedRotationState extends State<AnimatedRotation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    if (widget.isPlaying) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedRotation oldWidget) {
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
          angle: _controller.value * 2 * math.pi,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// 4. 简约封面样式
class MinimalPlayer extends PlayerStyleWidget {
  const MinimalPlayer({
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
        return AnimatedScale(
          isPlaying: player.isPlaying,
          size: size,
          child: Container(
            width: size * 0.8,
            height: size * 0.8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  blurRadius: 30,
                  spreadRadius: 5,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: AlbumArt(
                id: songId,
                size: size * 0.8,
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

/// 缩放动画组件
class AnimatedScale extends StatefulWidget {
  final bool isPlaying;
  final Widget child;
  final double size;

  const AnimatedScale({
    Key? key,
    required this.isPlaying,
    required this.child,
    required this.size,
  }) : super(key: key);

  @override
  State<AnimatedScale> createState() => _AnimatedScaleState();
}

class _AnimatedScaleState extends State<AnimatedScale>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    if (widget.isPlaying) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedScale oldWidget) {
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
        return Transform.scale(
          scale: 1.0 + (_controller.value * 0.02),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// 黑胶唱片组件（复用原版代码）
class VinylRecordPlayer extends StatefulWidget {
  final String songId;
  final double size;
  final String? title;
  final String? artist;

  const VinylRecordPlayer({
    Key? key,
    required this.songId,
    this.size = 280,
    this.title,
    this.artist,
  }) : super(key: key);

  @override
  State<VinylRecordPlayer> createState() => _VinylRecordPlayerState();
}

class _VinylRecordPlayerState extends State<VinylRecordPlayer>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  Widget _buildCircularAlbumArt(double size) {
    return ClipOval(
      child: Container(
        width: size,
        height: size,
        color: Colors.grey[800],
        child: AlbumArt(
          id: widget.songId,
          size: size,
          borderRadius: 0,
          fit: BoxFit.cover,
          title: widget.title,
          artist: widget.artist,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerProvider>(
      builder: (context, player, child) {
        if (player.isPlaying) {
          _rotationController.repeat();
        } else {
          _rotationController.stop();
        }

        return AnimatedBuilder(
          animation: _rotationController,
          builder: (context, child) {
            return Transform.rotate(
              angle: _rotationController.value * 2 * math.pi,
              child: child,
            );
          },
          child: _buildVinylRecord(),
        );
      },
    );
  }

  Widget _buildVinylRecord() {
    final vinylSize = widget.size;
    final centerHoleSize = vinylSize * 0.08;
    final labelSize = vinylSize * 0.35;

    return Container(
      width: vinylSize,
      height: vinylSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          colors: [
            Color(0xFF1a1a1a),
            Color(0xFF0d0d0d),
            Color(0xFF000000),
          ],
          stops: [0.3, 0.8, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 20,
            spreadRadius: 5,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          ..._buildGrooves(vinylSize),
          Container(
            width: labelSize,
            height: labelSize,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Color(0xFF8B4513),
                  Color(0xFF654321),
                ],
              ),
            ),
            child: Center(
              child: Container(
                width: labelSize * 0.95,
                height: labelSize * 0.95,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                ),
                clipBehavior: Clip.antiAlias,
                child: _buildCircularAlbumArt(labelSize * 0.95),
              ),
            ),
          ),
          Container(
            width: centerHoleSize,
            height: centerHoleSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF1a1a1a),
              border: Border.all(
                color: const Color(0xFF333333),
                width: 1,
              ),
            ),
          ),
          Positioned(
            top: vinylSize * 0.15,
            left: vinylSize * 0.2,
            child: Container(
              width: vinylSize * 0.15,
              height: vinylSize * 0.3,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.1),
                    Colors.white.withOpacity(0.0),
                  ],
                ),
                borderRadius: BorderRadius.circular(vinylSize * 0.075),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildGrooves(double size) {
    final grooves = <Widget>[];
    final startRadius = size * 0.22;
    final endRadius = size * 0.48;
    final step = (endRadius - startRadius) / 12;

    for (var i = 0; i < 12; i++) {
      final radius = startRadius + step * i;
      grooves.add(
        Container(
          width: radius * 2,
          height: radius * 2,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.grey.shade800.withOpacity(0.3 + i * 0.03),
              width: 1,
            ),
          ),
        ),
      );
    }

    return grooves;
  }
}

/// 带唱臂的黑胶播放器
class VinylPlayerWithArm extends StatefulWidget {
  final String songId;
  final double size;
  final String? title;
  final String? artist;

  const VinylPlayerWithArm({
    Key? key,
    required this.songId,
    this.size = 320,
    this.title,
    this.artist,
  }) : super(key: key);

  @override
  State<VinylPlayerWithArm> createState() => _VinylPlayerWithArmState();
}

class _VinylPlayerWithArmState extends State<VinylPlayerWithArm>
    with SingleTickerProviderStateMixin {
  late AnimationController _armController;

  @override
  void initState() {
    super.initState();
    _armController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  void dispose() {
    _armController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerProvider>(
      builder: (context, player, child) {
        if (player.isPlaying) {
          _armController.forward();
        } else {
          _armController.reverse();
        }

        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              VinylRecordPlayer(
                songId: widget.songId,
                size: widget.size * 0.85,
                title: widget.title,
                artist: widget.artist,
              ),
              Positioned(
                top: 0,
                right: widget.size * 0.1,
                child: AnimatedBuilder(
                  animation: _armController,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: -0.3 + (_armController.value * 0.4),
                      alignment: Alignment.topRight,
                      child: child,
                    );
                  },
                  child: SizedBox(
                    width: widget.size * 0.4,
                    height: widget.size * 0.6,
                    child: CustomPaint(painter: ToneArmPainter()),
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

class ToneArmPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final pivotX = size.width * 0.82;
    final pivotY = size.height * 0.10;
    final headX = size.width * 0.38;
    final headY = size.height * 0.72;

    final outerGradient = RadialGradient(
      colors: [
        const Color(0xFFE8E8E8),
        const Color(0xFF999999),
        const Color(0xFF666666),
      ],
    );

    final outerPaint = Paint()
      ..shader = outerGradient.createShader(
        Rect.fromCircle(center: Offset(pivotX, pivotY), radius: size.width * 0.05),
      )
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(pivotX, pivotY), size.width * 0.05, outerPaint);

    final innerGradient = RadialGradient(
      colors: [
        const Color(0xFFFFD700),
        const Color(0xFFB8860B),
        const Color(0xFF8B6914),
      ],
      stops: const [0.0, 0.6, 1.0],
    );

    final innerPaint = Paint()
      ..shader = innerGradient.createShader(
        Rect.fromCircle(center: Offset(pivotX, pivotY), radius: size.width * 0.025),
      )
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(pivotX, pivotY), size.width * 0.025, innerPaint);

    final armPaint = Paint()
      ..color = const Color(0xFFCCCCCC)
      ..strokeWidth = size.width * 0.03
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(pivotX, pivotY),
      Offset(headX, headY),
      armPaint,
    );

    final headGradient = RadialGradient(
      colors: [
        const Color(0xFFDDDDDD),
        const Color(0xFF888888),
        const Color(0xFF555555),
      ],
    );

    final headPaint = Paint()
      ..shader = headGradient.createShader(
        Rect.fromCircle(center: Offset(headX, headY), radius: size.width * 0.035),
      )
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(headX, headY), size.width * 0.035, headPaint);

    canvas.drawCircle(
      Offset(headX, headY),
      size.width * 0.015,
      Paint()..color = const Color(0xFF333333),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 播放器样式选择器组件
class PlayerStyleSelector extends StatelessWidget {
  final PlayerStyle selectedStyle;
  final Function(PlayerStyle) onStyleSelected;
  final bool isPreview;

  const PlayerStyleSelector({
    Key? key,
    required this.selectedStyle,
    required this.onStyleSelected,
    this.isPreview = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final styles = [
      _StyleItem(PlayerStyle.vinyl, '黑胶唱片', Icons.album),
      _StyleItem(PlayerStyle.waveform, '波形可视', Icons.equalizer),
      _StyleItem(PlayerStyle.rotatingDisc, '旋转光盘', Icons.disc_full),
      _StyleItem(PlayerStyle.minimal, '简约封面', Icons.image),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isPreview) ...[
          Text(
            '播放器样式',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
        ],
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: styles.map((style) {
            final isSelected = selectedStyle == style.style;
            return InkWell(
              onTap: () => onStyleSelected(style.style),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: isPreview ? 70 : 80,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary.withOpacity(0.15)
                      : Theme.of(context).colorScheme.surface.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.outline.withOpacity(0.2),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      style.icon,
                      size: isPreview ? 24 : 28,
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).iconTheme.color?.withOpacity(0.6),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      style.name,
                      style: TextStyle(
                        fontSize: isPreview ? 11 : 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _StyleItem {
  final PlayerStyle style;
  final String name;
  final IconData icon;

  _StyleItem(this.style, this.name, this.icon);
}
