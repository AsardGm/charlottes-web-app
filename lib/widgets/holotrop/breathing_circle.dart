import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/holotrop_state_model.dart';
import '../../theme/holotrop_colors.dart';

/// Animovany dychaci kruh pro techniku 4-4-4
/// Rozsirovani (nadech), drzeni, stahovani (vydech)
/// Vylepseny vizual: vrstvy, prstence, castice, glow
class BreathingCircle extends StatefulWidget {
  final bool isRunning;
  final ValueChanged<BreathingPhase> onPhaseChange;
  final VoidCallback onCycleComplete;

  const BreathingCircle({
    super.key,
    required this.isRunning,
    required this.onPhaseChange,
    required this.onCycleComplete,
  });

  @override
  State<BreathingCircle> createState() => _BreathingCircleState();
}

class _BreathingCircleState extends State<BreathingCircle>
    with TickerProviderStateMixin {
  late AnimationController _cycleController;
  late AnimationController _glowController;
  late AnimationController _pulseRingController;
  late AnimationController _rotationController;
  late Animation<double> _glowAnimation;
  late Animation<double> _pulseRingAnimation;

  BreathingPhase _currentPhase = BreathingPhase.idle;

  static const double _minRadius = 0.22;
  static const double _maxRadius = 0.42;
  static const Duration _cycleDuration = Duration(seconds: 12);

  @override
  void initState() {
    super.initState();

    _cycleController = AnimationController(
      vsync: this,
      duration: _cycleDuration,
    );

    _cycleController.addListener(_updatePhase);
    _cycleController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onCycleComplete();
        if (widget.isRunning) {
          _cycleController.forward(from: 0);
        }
      }
    });

    // Glow pulsace
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.2, end: 0.8).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    // Vnější pulzující prstenec
    _pulseRingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();

    _pulseRingAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseRingController, curve: Curves.easeOut),
    );

    // Pomalá rotace ornamentů
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  void _updatePhase() {
    final progress = _cycleController.value;
    BreathingPhase newPhase;

    if (progress < 1 / 3) {
      newPhase = BreathingPhase.inhale;
    } else if (progress < 2 / 3) {
      newPhase = BreathingPhase.hold;
    } else {
      newPhase = BreathingPhase.exhale;
    }

    if (newPhase != _currentPhase) {
      _currentPhase = newPhase;
      widget.onPhaseChange(newPhase);
      HapticFeedback.selectionClick();
    }
  }

  double _calculateRadius(double progress) {
    if (progress < 1 / 3) {
      final t = progress * 3;
      return _minRadius +
          (_maxRadius - _minRadius) * Curves.easeInOut.transform(t);
    } else if (progress < 2 / 3) {
      return _maxRadius;
    } else {
      final t = (progress - 2 / 3) * 3;
      return _maxRadius -
          (_maxRadius - _minRadius) * Curves.easeInOut.transform(t);
    }
  }

  Color _phaseColor() {
    switch (_currentPhase) {
      case BreathingPhase.inhale:
        return HolotropColors.inhale;
      case BreathingPhase.hold:
        return HolotropColors.hold;
      case BreathingPhase.exhale:
        return HolotropColors.exhale;
      case BreathingPhase.idle:
        return HolotropColors.accent;
    }
  }

  String _phaseLabel() {
    switch (_currentPhase) {
      case BreathingPhase.inhale:
        return 'NADECH';
      case BreathingPhase.hold:
        return 'ZADRZET';
      case BreathingPhase.exhale:
        return 'VYDECH';
      case BreathingPhase.idle:
        return 'START';
    }
  }

  String _phaseTimerText() {
    final progress = _cycleController.value;
    final totalSeconds = progress * 12;
    int secondsInPhase;

    if (progress < 1 / 3) {
      secondsInPhase = 4 - (totalSeconds).floor();
    } else if (progress < 2 / 3) {
      secondsInPhase = 8 - (totalSeconds).floor();
    } else {
      secondsInPhase = 12 - (totalSeconds).floor();
    }

    return '${secondsInPhase.clamp(1, 4)}';
  }

  @override
  void didUpdateWidget(BreathingCircle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRunning && !oldWidget.isRunning) {
      _cycleController.forward(from: 0);
    } else if (!widget.isRunning && oldWidget.isRunning) {
      _cycleController.stop();
      setState(() {
        _currentPhase = BreathingPhase.idle;
      });
    }
  }

  @override
  void dispose() {
    _cycleController.dispose();
    _glowController.dispose();
    _pulseRingController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _cycleController,
        _glowController,
        _pulseRingController,
        _rotationController,
      ]),
      builder: (context, child) {
        final radius = widget.isRunning
            ? _calculateRadius(_cycleController.value)
            : _minRadius;
        final color = _phaseColor();

        return LayoutBuilder(
          builder: (context, constraints) {
            final maxDim = math.min(constraints.maxWidth, constraints.maxHeight);
            final circleSize = maxDim * radius * 2;
            final outerRingSize = circleSize + 24;
            final pulseSize = circleSize + 24 + (_pulseRingAnimation.value * 60);

            return Center(
              child: SizedBox(
                width: maxDim,
                height: maxDim,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Vrstva 1: Ambientni glow na pozadi
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      width: circleSize + 100,
                      height: circleSize + 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            color.withAlpha((_glowAnimation.value * 35).toInt()),
                            color.withAlpha((_glowAnimation.value * 12).toInt()),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        ),
                      ),
                    ),

                    // Vrstva 2: Pulzujici prstenec (expanduje ven)
                    if (widget.isRunning)
                      Opacity(
                        opacity: (1.0 - _pulseRingAnimation.value).clamp(0.0, 0.4),
                        child: Container(
                          width: pulseSize,
                          height: pulseSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: color.withAlpha(60),
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),

                    // Vrstva 3: Rotujici teckovany prstenec
                    Transform.rotate(
                      angle: _rotationController.value * 2 * math.pi,
                      child: CustomPaint(
                        size: Size(outerRingSize, outerRingSize),
                        painter: _DottedRingPainter(
                          color: color.withAlpha(
                            widget.isRunning ? 80 : 40,
                          ),
                          dotCount: 36,
                          dotRadius: 1.5,
                        ),
                      ),
                    ),

                    // Vrstva 4: Vnejsi tenky prstenec
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      width: outerRingSize,
                      height: outerRingSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: color.withAlpha(40),
                          width: 1,
                        ),
                      ),
                    ),

                    // Vrstva 5: Hlavni kruh
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: circleSize,
                      height: circleSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            color.withAlpha(60),
                            color.withAlpha(30),
                            color.withAlpha(8),
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        ),
                        border: Border.all(
                          color: color.withAlpha(200),
                          width: 2.5,
                        ),
                        boxShadow: [
                          // Vnitrni glow
                          BoxShadow(
                            color: color.withAlpha(
                              (_glowAnimation.value * 80).toInt(),
                            ),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                          // Vnejsi jemny glow
                          BoxShadow(
                            color: color.withAlpha(
                              (_glowAnimation.value * 40).toInt(),
                            ),
                            blurRadius: 60,
                            spreadRadius: 15,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Faze label
                            Text(
                              _phaseLabel(),
                              style: TextStyle(
                                color: color,
                                fontSize: widget.isRunning ? 22 : 28,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 4,
                                fontFamily: 'Rajdhani',
                                shadows: [
                                  Shadow(
                                    color: color.withAlpha(120),
                                    blurRadius: 20,
                                  ),
                                ],
                              ),
                            ),
                            if (widget.isRunning) ...[
                              const SizedBox(height: 4),
                              // Timer - velke cislo
                              Text(
                                _phaseTimerText(),
                                style: TextStyle(
                                  color: color.withAlpha(220),
                                  fontSize: 36,
                                  fontWeight: FontWeight.w300,
                                  fontFamily: 'Rajdhani',
                                  height: 1.0,
                                  shadows: [
                                    Shadow(
                                      color: color.withAlpha(80),
                                      blurRadius: 16,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    // Vrstva 6: Vnitrni dekorativni prstenec
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: circleSize - 16,
                      height: circleSize - 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: color.withAlpha(25),
                          width: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// Painter pro teckovany prstenec kolem kruhu
class _DottedRingPainter extends CustomPainter {
  final Color color;
  final int dotCount;
  final double dotRadius;

  _DottedRingPainter({
    required this.color,
    required this.dotCount,
    required this.dotRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final ringRadius = size.width / 2;
    final paint = Paint()..color = color;

    for (int i = 0; i < dotCount; i++) {
      final angle = (2 * math.pi / dotCount) * i;
      final dx = center.dx + ringRadius * math.cos(angle);
      final dy = center.dy + ringRadius * math.sin(angle);
      // Stridave vetsi a mensi tecky
      final r = i % 3 == 0 ? dotRadius * 1.5 : dotRadius;
      canvas.drawCircle(Offset(dx, dy), r, paint);
    }
  }

  @override
  bool shouldRepaint(_DottedRingPainter oldDelegate) =>
      color != oldDelegate.color;
}
