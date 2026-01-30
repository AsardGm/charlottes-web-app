import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../theme/theme.dart';

/// Custom pull-to-refresh widget s pavučinou a pavoukem
///
/// Při tažení dolů se vykresluje pavučina, která se "natahuje"
/// Pavouk klesá dolů s pavučinou a pak se "vráti" zpět
class SpiderWebRefresh extends StatefulWidget {
  final Widget child;
  final Future<void> Function() onRefresh;
  final Color webColor;
  final Color spiderColor;

  const SpiderWebRefresh({
    super.key,
    required this.child,
    required this.onRefresh,
    this.webColor = Colors.white24,
    Color? spiderColor,
  }) : spiderColor = spiderColor ?? AppColors.accent;

  @override
  State<SpiderWebRefresh> createState() => _SpiderWebRefreshState();
}

class _SpiderWebRefreshState extends State<SpiderWebRefresh>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isRefreshing = false;
  double _dragDistance = 0;
  static const double _triggerDistance = 100.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    _controller.repeat();

    try {
      await widget.onRefresh();
    } finally {
      if (mounted) {
        _controller.stop();
        _controller.reset();
        setState(() {
          _isRefreshing = false;
          _dragDistance = 0;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollUpdateNotification) {
          if (notification.metrics.pixels < 0 && !_isRefreshing) {
            setState(() {
              _dragDistance = (-notification.metrics.pixels).clamp(0, _triggerDistance * 1.5);
            });
          }
        } else if (notification is ScrollEndNotification) {
          if (_dragDistance >= _triggerDistance && !_isRefreshing) {
            _handleRefresh();
          } else if (!_isRefreshing) {
            setState(() {
              _dragDistance = 0;
            });
          }
        }
        return false;
      },
      child: Stack(
        children: [
          widget.child,
          if (_dragDistance > 0 || _isRefreshing)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _buildRefreshIndicator(),
            ),
        ],
      ),
    );
  }

  Widget _buildRefreshIndicator() {
    final progress = (_dragDistance / _triggerDistance).clamp(0.0, 1.0);
    final height = _isRefreshing ? 80.0 : _dragDistance.clamp(0.0, 80.0);

    return Container(
      height: height,
      alignment: Alignment.center,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            size: Size(MediaQuery.of(context).size.width, height),
            painter: SpiderWebPainter(
              progress: _isRefreshing ? 1.0 : progress,
              webColor: widget.webColor,
              spiderColor: widget.spiderColor,
              isSpinning: _isRefreshing,
              spinAngle: _controller.value * 2 * math.pi,
            ),
          );
        },
      ),
    );
  }
}

/// Custom painter pro pavučinu a pavouka
class SpiderWebPainter extends CustomPainter {
  final double progress;
  final Color webColor;
  final Color spiderColor;
  final bool isSpinning;
  final double spinAngle;

  SpiderWebPainter({
    required this.progress,
    required this.webColor,
    required this.spiderColor,
    required this.isSpinning,
    required this.spinAngle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final center = Offset(size.width / 2, 20);
    final maxRadius = size.width / 3 * progress;

    // Nakresli pavučinu
    _drawWeb(canvas, center, maxRadius);

    // Nakresli pavouka
    final spiderY = isSpinning ? 40.0 : 20 + (progress * 40);
    _drawSpider(canvas, Offset(size.width / 2, spiderY));
  }

  void _drawWeb(Canvas canvas, Offset center, double maxRadius) {
    final webPaint = Paint()
      ..color = webColor
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Radiální linie pavučiny (8 linií)
    for (int i = 0; i < 8; i++) {
      final angle = (i * math.pi / 4) - math.pi / 2;
      final end = Offset(
        center.dx + math.cos(angle) * maxRadius,
        center.dy + math.sin(angle) * maxRadius,
      );
      canvas.drawLine(center, end, webPaint);
    }

    // Koncentrické kruhy
    for (int i = 1; i <= 3; i++) {
      final radius = maxRadius * (i / 3);
      canvas.drawCircle(center, radius, webPaint);
    }

    // Vertikální "silk thread" od pavouka
    final threadPaint = Paint()
      ..color = webColor.withValues(alpha: 0.6)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(center.dx, 0),
      Offset(center.dx, center.dy),
      threadPaint,
    );
  }

  void _drawSpider(Canvas canvas, Offset position) {
    final paint = Paint()
      ..color = spiderColor
      ..style = PaintingStyle.fill;

    // Tělo pavouka (2 části)
    // Hlava (menší)
    canvas.drawCircle(
      Offset(position.dx, position.dy - 3),
      4,
      paint,
    );

    // Zadeček (větší)
    canvas.drawCircle(
      Offset(position.dx, position.dy + 4),
      6,
      paint,
    );

    // Nohy (8 noh)
    final legPaint = Paint()
      ..color = spiderColor
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < 8; i++) {
      final side = i < 4 ? -1 : 1;
      final legIndex = i % 4;
      final baseAngle = isSpinning ? spinAngle : 0.0;
      final angle = baseAngle + (legIndex * math.pi / 6) * side;

      final startY = position.dy + (legIndex * 2.0 - 3);
      final start = Offset(position.dx, startY);

      // Dvojité zalomení nohy (realistické)
      final mid = Offset(
        position.dx + side * math.cos(angle) * 8,
        startY + math.sin(angle) * 4,
      );

      final end = Offset(
        position.dx + side * math.cos(angle) * 14,
        startY + math.sin(angle) * 2,
      );

      final path = Path()
        ..moveTo(start.dx, start.dy)
        ..lineTo(mid.dx, mid.dy)
        ..lineTo(end.dx, end.dy);

      canvas.drawPath(path, legPaint);
    }

    // Oči (2 malé tečky)
    final eyePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(position.dx - 2, position.dy - 4), 1, eyePaint);
    canvas.drawCircle(Offset(position.dx + 2, position.dy - 4), 1, eyePaint);
  }

  @override
  bool shouldRepaint(SpiderWebPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.isSpinning != isSpinning ||
        oldDelegate.spinAngle != spinAngle;
  }
}
