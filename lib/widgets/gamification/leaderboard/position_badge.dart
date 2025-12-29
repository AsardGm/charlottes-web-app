import 'package:flutter/material.dart';
import '../../../theme/theme.dart';

/// Badge s pozici v zebricku
class PositionBadge extends StatelessWidget {
  /// Pozice (1-based)
  final int position;

  const PositionBadge({
    super.key,
    required this.position,
  });

  @override
  Widget build(BuildContext context) {
    if (position <= 3) {
      return Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _getGradientColors(position),
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: _getGradientColors(position).first.withAlpha(100),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            _getMedal(position),
            style: const TextStyle(fontSize: 18),
          ),
        ),
      );
    }

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          position.toString(),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  List<Color> _getGradientColors(int pos) {
    switch (pos) {
      case 1:
        return [const Color(0xFFFFD700), const Color(0xFFFFA500)];
      case 2:
        return [const Color(0xFFE8E8E8), const Color(0xFFA0A0A0)];
      case 3:
        return [const Color(0xFFCD7F32), const Color(0xFF8B4513)];
      default:
        return [AppColors.surface, AppColors.surfaceLight];
    }
  }

  String _getMedal(int pos) {
    switch (pos) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return '';
    }
  }
}
