import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../theme/theme.dart';

/// Animated spider loader - pavouk spřádající pavučinu
///
/// Náhrada za CircularProgressIndicator s spider tématikou
class SpiderLoader extends StatefulWidget {
  final double size;
  final Color? color;
  final double strokeWidth;

  const SpiderLoader({
    super.key,
    this.size = 40.0,
    this.color,
    this.strokeWidth = 3.0,
  });

  @override
  State<SpiderLoader> createState() => _SpiderLoaderState();
}

class _SpiderLoaderState extends State<SpiderLoader>
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
    final color = widget.color ?? AppColors.accent;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: SpiderLoaderPainter(
              progress: _controller.value,
              color: color,
              strokeWidth: widget.strokeWidth,
            ),
          );
        },
      ),
    );
  }
}

class SpiderLoaderPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  SpiderLoaderPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - strokeWidth;

    // Nakresli partial pavučinu (spřádá se postupně)
    _drawWeb(canvas, center, radius);

    // Nakresli pavouka rotujícího kolem
    _drawSpider(canvas, center, radius);
  }

  void _drawWeb(Canvas canvas, Offset center, double radius) {
    final webPaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..strokeWidth = strokeWidth * 0.5
      ..style = PaintingStyle.stroke;

    // Počet linií pavučiny (zvětšuje se s progress)
    final lineCount = 8;
    final visibleLines = (lineCount * progress).ceil();

    // Radiální linie
    for (int i = 0; i < visibleLines; i++) {
      final angle = (i * 2 * math.pi / lineCount) - math.pi / 2;
      final lineProgress = ((progress * lineCount) - i).clamp(0.0, 1.0);

      final end = Offset(
        center.dx + math.cos(angle) * radius * lineProgress,
        center.dy + math.sin(angle) * radius * lineProgress,
      );

      canvas.drawLine(center, end, webPaint);
    }

    // Koncentrické kruhy (3 kruhy, objevují se postupně)
    for (int i = 1; i <= 3; i++) {
      final circleProgress = ((progress * 3) - (i - 1)).clamp(0.0, 1.0);
      if (circleProgress > 0) {
        final circleRadius = radius * (i / 3);
        final sweepAngle = circleProgress * 2 * math.pi;

        canvas.drawArc(
          Rect.fromCircle(center: center, radius: circleRadius),
          -math.pi / 2,
          sweepAngle,
          false,
          webPaint,
        );
      }
    }
  }

  void _drawSpider(Canvas canvas, Offset center, double radius) {
    // Pavouk se pohybuje po kruhu
    final angle = progress * 2 * math.pi - math.pi / 2;
    final spiderPos = Offset(
      center.dx + math.cos(angle) * radius,
      center.dy + math.sin(angle) * radius,
    );

    final spiderPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final spiderSize = strokeWidth * 2;

    // Tělo (2 části)
    canvas.drawCircle(spiderPos, spiderSize * 0.6, spiderPaint);

    final headPos = Offset(
      spiderPos.dx + math.cos(angle) * spiderSize * 0.8,
      spiderPos.dy + math.sin(angle) * spiderSize * 0.8,
    );
    canvas.drawCircle(headPos, spiderSize * 0.4, spiderPaint);

    // Nohy (zjednodušené, 4 viditelné z každé strany)
    final legPaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth * 0.3
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < 4; i++) {
      final legAngle = angle + math.pi / 2;
      final sideOffset = (i - 1.5) * spiderSize * 0.5;

      // Levé nohy
      final leftStart = Offset(
        spiderPos.dx + math.cos(legAngle) * sideOffset,
        spiderPos.dy + math.sin(legAngle) * sideOffset,
      );
      final leftEnd = Offset(
        leftStart.dx + math.cos(angle - math.pi / 2) * spiderSize * 1.5,
        leftStart.dy + math.sin(angle - math.pi / 2) * spiderSize * 1.5,
      );
      canvas.drawLine(leftStart, leftEnd, legPaint);

      // Pravé nohy
      final rightStart = Offset(
        spiderPos.dx - math.cos(legAngle) * sideOffset,
        spiderPos.dy - math.sin(legAngle) * sideOffset,
      );
      final rightEnd = Offset(
        rightStart.dx + math.cos(angle + math.pi / 2) * spiderSize * 1.5,
        rightStart.dy + math.sin(angle + math.pi / 2) * spiderSize * 1.5,
      );
      canvas.drawLine(rightStart, rightEnd, legPaint);
    }

    // Silk thread od centra k pavoukovi
    final threadPaint = Paint()
      ..color = color.withValues(alpha: 0.2)
      ..strokeWidth = strokeWidth * 0.3
      ..style = PaintingStyle.stroke;

    canvas.drawLine(center, spiderPos, threadPaint);
  }

  @override
  bool shouldRepaint(SpiderLoaderPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// Malý inline loader - použij místo CircularProgressIndicator.adaptive()
class SpiderLoaderSmall extends StatelessWidget {
  final Color? color;

  const SpiderLoaderSmall({super.key, this.color});

  @override
  Widget build(BuildContext context) {
    return SpiderLoader(
      size: 20,
      color: color,
      strokeWidth: 2,
    );
  }
}

/// Fullscreen loader overlay
class SpiderLoaderOverlay extends StatelessWidget {
  final String? message;

  const SpiderLoaderOverlay({
    super.key,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SpiderLoader(size: 60),
            if (message != null) ...[
              const SizedBox(height: 24),
              Text(
                message!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Zobraz loading overlay
  static void show(BuildContext context, {String? message}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (context) => SpiderLoaderOverlay(message: message),
    );
  }

  /// Zavři loading overlay
  static void hide(BuildContext context) {
    Navigator.of(context).pop();
  }
}
