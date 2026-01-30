import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../theme/theme.dart';
import '../../models/rank_model.dart';

/// Fullscreen rank up celebration animace
///
/// Zobrazí se když user postupuje na vyšší rank
/// S confetti, glow efekty a rank badge animací
class RankUpCelebration extends StatefulWidget {
  final SpiderRank newRank;
  final int newXP;
  final VoidCallback onComplete;

  const RankUpCelebration({
    super.key,
    required this.newRank,
    required this.newXP,
    required this.onComplete,
  });

  @override
  State<RankUpCelebration> createState() => _RankUpCelebrationState();

  /// Show rank up celebration as a fullscreen overlay
  static Future<void> show(
    BuildContext context, {
    required SpiderRank newRank,
    required int newXP,
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87,
      builder: (context) => RankUpCelebration(
        newRank: newRank,
        newXP: newXP,
        onComplete: () => Navigator.of(context).pop(),
      ),
    );
  }
}

class _RankUpCelebrationState extends State<RankUpCelebration>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _confettiController;
  late AnimationController _glowController;

  late Animation<double> _fadeInAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _slideAnimation;

  List<ConfettiParticle> _confettiParticles = [];

  @override
  void initState() {
    super.initState();

    // Main animation controller (3 seconds)
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    // Confetti animation (separate, 2 seconds)
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    // Glow pulse animation (repeating)
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    // Fade in the overlay
    _fadeInAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.0, 0.2, curve: Curves.easeIn),
    ));

    // Scale up the rank badge
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.3),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.3, end: 1.0),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.0),
        weight: 40,
      ),
    ]).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.2, 0.8, curve: Curves.elasticOut),
    ));

    // Slide up the text
    _slideAnimation = Tween<double>(
      begin: 100.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.3, 0.7, curve: Curves.easeOut),
    ));

    // Generate confetti particles
    _generateConfetti();

    // Start animations
    _mainController.forward();
    _confettiController.forward();

    // Auto-dismiss after animation
    Future.delayed(const Duration(milliseconds: 3500), () {
      if (mounted) {
        widget.onComplete();
      }
    });
  }

  void _generateConfetti() {
    final random = math.Random();
    _confettiParticles = List.generate(50, (index) {
      return ConfettiParticle(
        x: random.nextDouble(),
        y: -0.1 - random.nextDouble() * 0.2,
        rotation: random.nextDouble() * math.pi * 2,
        rotationSpeed: (random.nextDouble() - 0.5) * 4,
        size: 8 + random.nextDouble() * 6,
        color: _getRandomConfettiColor(random),
        fallSpeed: 0.3 + random.nextDouble() * 0.4,
        sway: (random.nextDouble() - 0.5) * 0.2,
      );
    });
  }

  Color _getRandomConfettiColor(math.Random random) {
    final colors = [
      widget.newRank.color,
      AppColors.accent,
      AppColors.success,
      Colors.amber,
      Colors.pink,
      Colors.purple,
    ];
    return colors[random.nextInt(colors.length)];
  }

  @override
  void dispose() {
    _mainController.dispose();
    _confettiController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _mainController,
        _confettiController,
        _glowController,
      ]),
      builder: (context, child) {
        return Material(
          color: Colors.transparent,
          child: Stack(
            children: [
              // Confetti particles
              ..._confettiParticles.map((particle) {
                return _buildConfettiParticle(particle);
              }),

              // Main content
              Opacity(
                opacity: _fadeInAnimation.value,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // "RANK UP!" text
                      Transform.translate(
                        offset: Offset(0, _slideAnimation.value),
                        child: Text(
                          'RANK UP!',
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.w900,
                            foreground: Paint()
                              ..shader = LinearGradient(
                                colors: [
                                  AppColors.accent,
                                  widget.newRank.color,
                                ],
                              ).createShader(const Rect.fromLTWH(0, 0, 200, 70)),
                            letterSpacing: 4,
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Rank badge with glow
                      Transform.scale(
                        scale: _scaleAnimation.value,
                        child: _buildRankBadge(),
                      ),

                      const SizedBox(height: 30),

                      // New rank name
                      Transform.translate(
                        offset: Offset(0, -_slideAnimation.value),
                        child: Column(
                          children: [
                            Text(
                              widget.newRank.name,
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: widget.newRank.color,
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${widget.newXP} XP',
                              style: TextStyle(
                                fontSize: 18,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Tap to continue hint
                      if (_mainController.value > 0.9)
                        Opacity(
                          opacity: ((_mainController.value - 0.9) / 0.1).clamp(0.0, 1.0),
                          child: Text(
                            'Tap to continue',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textMuted,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Tap anywhere to dismiss
              if (_mainController.value > 0.5)
                Positioned.fill(
                  child: GestureDetector(
                    onTap: widget.onComplete,
                    behavior: HitTestBehavior.translucent,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRankBadge() {
    final glowIntensity = 1.0 + (_glowController.value * 0.5);

    return Container(
      width: 150,
      height: 150,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: widget.newRank.color.withValues(alpha: 0.2),
        boxShadow: [
          BoxShadow(
            color: widget.newRank.color.withValues(alpha: 0.6),
            blurRadius: 30 * glowIntensity,
            spreadRadius: 10 * glowIntensity,
          ),
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.4),
            blurRadius: 50 * glowIntensity,
            spreadRadius: 5 * glowIntensity,
          ),
        ],
      ),
      child: Center(
        child: Text(
          widget.newRank.emoji,
          style: const TextStyle(fontSize: 80),
        ),
      ),
    );
  }

  Widget _buildConfettiParticle(ConfettiParticle particle) {
    final progress = _confettiController.value;

    final y = particle.y + (progress * particle.fallSpeed);
    final x = particle.x + (math.sin(progress * math.pi * 2) * particle.sway);
    final rotation = particle.rotation + (progress * particle.rotationSpeed);
    final opacity = (1.0 - progress).clamp(0.0, 1.0);

    // Don't render if off screen
    if (y > 1.2) return const SizedBox.shrink();

    return Positioned(
      left: x * MediaQuery.of(context).size.width,
      top: y * MediaQuery.of(context).size.height,
      child: Transform.rotate(
        angle: rotation,
        child: Opacity(
          opacity: opacity,
          child: Container(
            width: particle.size,
            height: particle.size * 1.5,
            decoration: BoxDecoration(
              color: particle.color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ),
    );
  }
}

/// Model pro jednu confetti particle
class ConfettiParticle {
  final double x; // 0-1 (screen width percentage)
  final double y; // Start Y position
  final double rotation; // Initial rotation
  final double rotationSpeed; // Rotation per second
  final double size; // Size in pixels
  final Color color;
  final double fallSpeed; // Fall speed
  final double sway; // Horizontal sway amount

  ConfettiParticle({
    required this.x,
    required this.y,
    required this.rotation,
    required this.rotationSpeed,
    required this.size,
    required this.color,
    required this.fallSpeed,
    required this.sway,
  });
}
