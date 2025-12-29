import 'dart:math';
import 'package:flutter/material.dart';
import '../../theme/theme.dart';

/// Widget pro avatar s pavucinou (webs visualization)
class WebAvatarWidget extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final int webLevel; // 0-10
  final double size;
  final bool showWebCount;
  final int? webCount;

  const WebAvatarWidget({
    super.key,
    this.imageUrl,
    required this.name,
    required this.webLevel,
    this.size = 80,
    this.showWebCount = false,
    this.webCount,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Pavucina kolem avataru (jen pokud je level > 0)
        if (webLevel > 0)
          CustomPaint(
            size: Size(size + 40, size + 40),
            painter: _WebPainter(
              level: webLevel,
              color: AppColors.primary,
            ),
          ),

        // Avatar
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: _getBorderColor(),
              width: 3,
            ),
            boxShadow: webLevel > 5
                ? [
                    BoxShadow(
                      color: AppColors.primary.withAlpha(50),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: ClipOval(
            child: imageUrl != null
                ? Image.network(
                    imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _buildFallbackAvatar(),
                  )
                : _buildFallbackAvatar(),
          ),
        ),

        // Web count badge
        if (showWebCount && webCount != null)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.background,
                  width: 2,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.hub,
                    size: 12,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatWebCount(webCount!),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFallbackAvatar() {
    return Container(
      color: AppColors.surfaceLight,
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: TextStyle(
            fontSize: size * 0.4,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }

  Color _getBorderColor() {
    if (webLevel >= 10) return const Color(0xFFFFD700); // Gold
    if (webLevel >= 7) return AppColors.primary;
    if (webLevel >= 4) return AppColors.primary.withAlpha(180);
    if (webLevel >= 1) return AppColors.primary.withAlpha(100);
    return AppColors.surfaceLight;
  }

  String _formatWebCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}

/// Custom painter pro pavucinu
class _WebPainter extends CustomPainter {
  final int level; // 1-10
  final Color color;

  _WebPainter({
    required this.level,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    // Pocet kruznic a paprsků závisí na levelu
    final circles = (level / 2).ceil().clamp(1, 5);
    final rays = 6 + level;

    final paint = Paint()
      ..color = color.withAlpha(30 + (level * 10).clamp(0, 100))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Kresli koncentricke kruznice
    for (var i = 1; i <= circles; i++) {
      final radius = maxRadius * (i / circles) * 0.8;
      canvas.drawCircle(center, radius, paint);
    }

    // Kresli paprsky
    for (var i = 0; i < rays; i++) {
      final angle = (2 * pi / rays) * i;
      final startRadius = maxRadius * 0.3;
      final endRadius = maxRadius * 0.9;

      final start = Offset(
        center.dx + cos(angle) * startRadius,
        center.dy + sin(angle) * startRadius,
      );
      final end = Offset(
        center.dx + cos(angle) * endRadius,
        center.dy + sin(angle) * endRadius,
      );

      canvas.drawLine(start, end, paint);
    }

    // Pridat "lepive" body na prusecicich (pro vyssi levely)
    if (level >= 5) {
      final dotPaint = Paint()
        ..color = color.withAlpha(50 + (level * 5))
        ..style = PaintingStyle.fill;

      for (var c = 1; c <= circles; c++) {
        final radius = maxRadius * (c / circles) * 0.8;
        for (var r = 0; r < rays; r++) {
          final angle = (2 * pi / rays) * r;
          final point = Offset(
            center.dx + cos(angle) * radius,
            center.dy + sin(angle) * radius,
          );
          canvas.drawCircle(point, 2, dotPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _WebPainter oldDelegate) {
    return oldDelegate.level != level || oldDelegate.color != color;
  }
}

/// Maly indicator poctu vlaken
class WebCountBadge extends StatelessWidget {
  final int count;
  final bool compact;

  const WebCountBadge({
    super.key,
    required this.count,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 10,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(20),
        borderRadius: BorderRadius.circular(compact ? 8 : 12),
        border: Border.all(
          color: AppColors.primary.withAlpha(50),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.hub,
            size: compact ? 12 : 16,
            color: AppColors.primary,
          ),
          SizedBox(width: compact ? 4 : 6),
          Text(
            _formatCount(count),
            style: TextStyle(
              fontSize: compact ? 11 : 13,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
          if (!compact) ...[
            const SizedBox(width: 4),
            Text(
              'vlaken',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}
