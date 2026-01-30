import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/holotrop_colors.dart';

/// Neonove pulzujici tlacitko Holotrop
/// Pouziva AnimationController pro glow puls a scale efekt
class HolotropButton extends StatefulWidget {
  final VoidCallback onTap;
  final double size;

  const HolotropButton({
    super.key,
    required this.onTap,
    this.size = 56,
  });

  @override
  State<HolotropButton> createState() => _HolotropButtonState();
}

class _HolotropButtonState extends State<HolotropButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _glowAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 8.0, end: 24.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTap: () {
              HapticFeedback.mediumImpact();
              widget.onTap();
            },
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    HolotropColors.accent,
                    HolotropColors.accent.withAlpha(180),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: HolotropColors.accentGlow,
                    blurRadius: _glowAnimation.value,
                    spreadRadius: _glowAnimation.value / 3,
                  ),
                  BoxShadow(
                    color: HolotropColors.accent.withAlpha(30),
                    blurRadius: _glowAnimation.value * 2,
                    spreadRadius: _glowAnimation.value / 2,
                  ),
                ],
                border: Border.all(
                  color: HolotropColors.accentSoft.withAlpha(120),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.self_improvement,
                color: Colors.white,
                size: widget.size * 0.5,
              ),
            ),
          ),
        );
      },
    );
  }
}
