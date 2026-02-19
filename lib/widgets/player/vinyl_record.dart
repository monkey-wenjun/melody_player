import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/player_provider.dart';
import '../common/album_art.dart';

/// 黑胶唱片播放器组件
class VinylRecordPlayer extends StatefulWidget {
  final String songId;
  final double size;

  const VinylRecordPlayer({
    Key? key,
    required this.songId,
    this.size = 280,
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
      duration: const Duration(seconds: 3), // 旋转一圈的时间
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  /// 构建圆形专辑封面
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
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerProvider>(
      builder: (context, player, child) {
        // 根据播放状态控制旋转
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
        // 黑胶唱片纹理
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
          // 唱片纹路
          ..._buildGrooves(vinylSize),

          // 中心标签区域
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

          // 中心孔
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

          // 高光反射效果
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

  // 构建唱片纹路
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

  const VinylPlayerWithArm({
    Key? key,
    required this.songId,
    this.size = 320,
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
        // 控制唱臂位置
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
              // 黑胶唱片
              VinylRecordPlayer(
                songId: widget.songId,
                size: widget.size * 0.85,
              ),

              // 唱臂
              Positioned(
                top: 0,
                right: widget.size * 0.1,
                child: AnimatedBuilder(
                  animation: _armController,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: -0.3 + (_armController.value * 0.4), // 从 -0.3 到 0.1
                      alignment: Alignment.topRight,
                      child: child,
                    );
                  },
                  child: _buildToneArm(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildToneArm() {
    return SizedBox(
      width: widget.size * 0.4,
      height: widget.size * 0.6,
      child: CustomPaint(
        painter: ToneArmPainter(),
      ),
    );
  }
}

/// 唱臂绘制器 - 金属质感设计
class ToneArmPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 支点位置（右上角）
    final pivotX = size.width * 0.82;
    final pivotY = size.height * 0.10;
    
    // 唱头位置（唱片中心附近）
    final headX = size.width * 0.38;
    final headY = size.height * 0.72;
    
    // 1. 支点底座 - 外圈金属环
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
    
    // 2. 支点中心 - 金色轴承
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
    
    // 3. 唱臂杆 - 金属管状
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
    
    // 4. 唱头 - 圆形金属头
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
    
    // 5. 唱头中心 - 深色圆点
    canvas.drawCircle(
      Offset(headX, headY),
      size.width * 0.015,
      Paint()..color = const Color(0xFF333333),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
