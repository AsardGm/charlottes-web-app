import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../theme/theme.dart';

/// Widget pro animaci získání XP s particle efektem
///
/// Zobrazí XP číslo, které "vystřelí" nahoru s particle efektem
/// Použití: Overlay přes screen, spustí se když user získá XP
class AnimatedXPGain extends StatefulWidget {
  final int xpAmount;
  final Offset startPosition;
  final VoidCallback? onComplete;
  final Duration duration;

  const AnimatedXPGain({
    super.key,
    required this.xpAmount,
    required this.startPosition,
    this.onComplete,
    this.duration = const Duration(milliseconds: 1500),
  });

  @override
  State<AnimatedXPGain> createState() => _AnimatedXPGainState();
}

class _AnimatedXPGainState extends State<AnimatedXPGain>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late List<Particle> _particles;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    // Animace posunu nahoru
    _slideAnimation = Tween<double>(
      begin: 0.0,
      end: -120.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    // Fade out na konci
    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.7, 1.0, curve: Curves.easeIn),
    ));

    // Scale efekt (trochu se zvětší, pak zmenší)
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.5, end: 1.3),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.3, end: 1.0),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.8),
        weight: 50,
      ),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    // Generuj particles
    _particles = List.generate(12, (index) {
      final random = math.Random(index);
      return Particle(
        angle: (index * math.pi * 2 / 12) + random.nextDouble() * 0.3,
        speed: 40 + random.nextDouble() * 40,
        size: 3 + random.nextDouble() * 4,
        color: _getParticleColor(index),
      );
    });

    _controller.forward().then((_) {
      widget.onComplete?.call();
    });
  }

  Color _getParticleColor(int index) {
    final colors = [
      AppColors.accent,
      AppColors.accent.withValues(alpha: 0.7),
      Colors.white,
      AppColors.success,
    ];
    return colors[index % colors.length];
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
        return Positioned(
          left: widget.startPosition.dx - 40,
          top: widget.startPosition.dy + _slideAnimation.value - 40,
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Particles
                ..._particles.map((particle) => _buildParticle(particle)),

                // XP číslo
                Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.accent,
                          AppColors.accent.withValues(alpha: 0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accent.withValues(alpha: 0.4),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.add,
                          color: Colors.black,
                          size: 16,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${widget.xpAmount}',
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'XP',
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildParticle(Particle particle) {
    final progress = _controller.value;
    final distance = particle.speed * progress;

    final x = math.cos(particle.angle) * distance;
    final y = math.sin(particle.angle) * distance - (progress * 30); // Gravitace

    final opacity = (1.0 - progress).clamp(0.0, 1.0);

    return Transform.translate(
      offset: Offset(x, y),
      child: Opacity(
        opacity: opacity,
        child: Container(
          width: particle.size,
          height: particle.size,
          decoration: BoxDecoration(
            color: particle.color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: particle.color.withValues(alpha: 0.6),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Model pro jednu particle
class Particle {
  final double angle;
  final double speed;
  final double size;
  final Color color;

  Particle({
    required this.angle,
    required this.speed,
    required this.size,
    required this.color,
  });
}

/// XP Gain Manager pro zobrazování XP animací
/// Použij jako Overlay v MaterialApp nebo jako Stack v konkrétním screenu
class XPGainOverlay extends StatefulWidget {
  final Widget child;

  const XPGainOverlay({
    super.key,
    required this.child,
  });

  @override
  State<XPGainOverlay> createState() => XPGainOverlayState();

  static XPGainOverlayState? of(BuildContext context) {
    return context.findAncestorStateOfType<XPGainOverlayState>();
  }
}

class XPGainOverlayState extends State<XPGainOverlay> {
  final List<_XPGainEntry> _activeGains = [];

  /// Zobraz XP gain animaci
  void showXPGain(int xpAmount, {Offset? position}) {
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final size = renderBox.size;
    final defaultPosition = Offset(size.width / 2, size.height * 0.3);

    setState(() {
      _activeGains.add(_XPGainEntry(
        key: UniqueKey(),
        xpAmount: xpAmount,
        position: position ?? defaultPosition,
      ));
    });
  }

  void _removeGain(Key key) {
    setState(() {
      _activeGains.removeWhere((entry) => entry.key == key);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        ..._activeGains.map((entry) {
          return AnimatedXPGain(
            key: entry.key,
            xpAmount: entry.xpAmount,
            startPosition: entry.position,
            onComplete: () => _removeGain(entry.key),
          );
        }),
      ],
    );
  }
}

class _XPGainEntry {
  final Key key;
  final int xpAmount;
  final Offset position;

  _XPGainEntry({
    required this.key,
    required this.xpAmount,
    required this.position,
  });
}
