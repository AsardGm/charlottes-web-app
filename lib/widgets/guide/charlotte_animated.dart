import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// Animační stavy průvodkyně Charlotte
enum CharlotteState {
  /// Základní floating stav
  idle,
  /// Skenování tabletu
  scanning,
  /// Uvítání - mávání rukou
  welcome,
  /// Úspěch - palec nahoru
  success,
  /// Chyba - nakloněná hlava
  error,
  /// Ukazování na UI element
  pointing,
  /// Meditacni mod - uklidnujici teal zare, pomaly puls
  meditation,
}

/// Pokročilá animovaná verze průvodkyně Charlotte
/// S efekty: scanlines, chromatic aberration, digital noise, glow pulze
class CharlotteAnimated extends StatefulWidget {
  const CharlotteAnimated({
    super.key,
    this.size = 200,
    this.state = CharlotteState.idle,
    this.showGlow = true,
    this.showScanlines = true,
    this.showNoise = false,
    this.onAnimationComplete,
  });

  /// Velikost průvodce
  final double size;

  /// Aktuální animační stav
  final CharlotteState state;

  /// Zobrazit cyan záři
  final bool showGlow;

  /// Zobrazit scanlines efekt
  final bool showScanlines;

  /// Zobrazit digitální šum
  final bool showNoise;

  /// Callback po dokončení one-shot animace
  final VoidCallback? onAnimationComplete;

  @override
  State<CharlotteAnimated> createState() => _CharlotteAnimatedState();
}

class _CharlotteAnimatedState extends State<CharlotteAnimated>
    with TickerProviderStateMixin {
  late AnimationController _floatController;
  late AnimationController _glowController;
  late AnimationController _stateController;

  late Animation<double> _floatAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _opacityAnimation;

  Color _currentGlowColor = AppColors.accent;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _updateStateAnimation();
  }

  void _initAnimations() {
    // Floating animace - 3000ms podle spec
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );
    _floatAnimation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
    _floatController.repeat(reverse: true);

    // Glow pulse animace - intensity 0.8-1.2
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _glowAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
    _glowController.repeat(reverse: true);

    // State animace - pro one-shot stavy
    _stateController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _opacityAnimation = Tween<double>(begin: 0.4, end: 0.9).animate(
      CurvedAnimation(parent: _stateController, curve: Curves.easeInOut),
    );
    _stateController.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(CharlotteAnimated oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) {
      _updateStateAnimation();
    }
  }

  void _updateStateAnimation() {
    switch (widget.state) {
      case CharlotteState.idle:
      case CharlotteState.scanning:
        _currentGlowColor = AppColors.accent;
        _glowController.duration = const Duration(milliseconds: 2000);
        break;
      case CharlotteState.welcome:
        _currentGlowColor = AppColors.accent;
        _triggerOneShotAnimation();
        break;
      case CharlotteState.success:
        // Emerald glow: #00FFCC
        _currentGlowColor = const Color(0xFF00FFCC);
        _triggerOneShotAnimation();
        break;
      case CharlotteState.error:
        // Soft red: #FF3366, flickering
        _currentGlowColor = const Color(0xFFFF3366);
        _glowController.duration = const Duration(milliseconds: 500);
        break;
      case CharlotteState.pointing:
        _currentGlowColor = AppColors.accent;
        break;
      case CharlotteState.meditation:
        // Uklidnujici teal zare s pomalym pulzem
        _currentGlowColor = const Color(0xFF00BFA5);
        _glowController.duration = const Duration(milliseconds: 4000);
        _floatController.duration = const Duration(milliseconds: 5000);
        break;
    }
    setState(() {});
  }

  void _triggerOneShotAnimation() {
    _stateController.forward(from: 0).then((_) {
      widget.onAnimationComplete?.call();
    });
  }

  @override
  void dispose() {
    _floatController.dispose();
    _glowController.dispose();
    _stateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _floatController,
        _glowController,
        _stateController,
      ]),
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -_floatAnimation.value),
          child: Container(
            width: widget.size,
            height: widget.size * 1.5,
            decoration: widget.showGlow
                ? BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: _currentGlowColor
                            .withValues(alpha: _glowAnimation.value * 0.3),
                        blurRadius: 40 * _glowAnimation.value,
                        spreadRadius: 10,
                      ),
                    ],
                  )
                : null,
            child: Stack(
              children: [
                // Hlavní obrázek
                Opacity(
                  opacity: _opacityAnimation.value,
                  child: ColorFiltered(
                    colorFilter: ColorFilter.mode(
                      _currentGlowColor.withValues(alpha: 0.1),
                      BlendMode.srcATop,
                    ),
                    child: Image.asset(
                      'assets/images/pruvodce.png',
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                ),
                // Scanlines efekt
                if (widget.showScanlines)
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _ScanlinesPainter(
                        color: _currentGlowColor,
                        opacity: 0.1,
                      ),
                    ),
                  ),
                // Digitální šum
                if (widget.showNoise)
                  Positioned.fill(
                    child: _DigitalNoise(
                      color: _currentGlowColor,
                      intensity: widget.state == CharlotteState.error ? 0.3 : 0.1,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Scanlines efekt painter
class _ScanlinesPainter extends CustomPainter {
  _ScanlinesPainter({
    required this.color,
    this.opacity = 0.1,
  });

  final Color color;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..strokeWidth = 1;

    // Horizontální scanlines každé 4 pixely
    for (double y = 0; y < size.height; y += 4) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ScanlinesPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.opacity != opacity;
  }
}

/// Digitální šum widget
class _DigitalNoise extends StatefulWidget {
  const _DigitalNoise({
    required this.color,
    this.intensity = 0.1,
  });

  final Color color;
  final double intensity;

  @override
  State<_DigitalNoise> createState() => _DigitalNoiseState();
}

class _DigitalNoiseState extends State<_DigitalNoise>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    )..repeat();
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
          painter: _NoisePainter(
            color: widget.color,
            intensity: widget.intensity,
            seed: _random.nextInt(1000),
          ),
        );
      },
    );
  }
}

class _NoisePainter extends CustomPainter {
  _NoisePainter({
    required this.color,
    required this.intensity,
    required this.seed,
  });

  final Color color;
  final double intensity;
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(seed);
    final paint = Paint()..color = color.withValues(alpha: intensity);

    // Náhodné pixely
    for (int i = 0; i < 50; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      canvas.drawRect(
        Rect.fromLTWH(x, y, 2, 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _NoisePainter oldDelegate) {
    return oldDelegate.seed != seed;
  }
}

/// Chromatic aberration efekt (RGB offset)
class ChromaticAberration extends StatelessWidget {
  const ChromaticAberration({
    super.key,
    required this.child,
    this.offset = 2.0,
  });

  final Widget child;
  final double offset;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Red channel - offset vlevo
        Transform.translate(
          offset: Offset(-offset, 0),
          child: ColorFiltered(
            colorFilter: const ColorFilter.mode(
              Color(0x40FF0000),
              BlendMode.srcATop,
            ),
            child: child,
          ),
        ),
        // Green channel - střed
        child,
        // Blue channel - offset vpravo
        Transform.translate(
          offset: Offset(offset, 0),
          child: ColorFiltered(
            colorFilter: const ColorFilter.mode(
              Color(0x400000FF),
              BlendMode.srcATop,
            ),
            child: child,
          ),
        ),
      ],
    );
  }
}

/// Voice line widget pro Charlotte
class CharlotteVoiceLine extends StatefulWidget {
  const CharlotteVoiceLine({
    super.key,
    required this.text,
    this.typingSpeed = const Duration(milliseconds: 30),
    this.onComplete,
  });

  final String text;
  final Duration typingSpeed;
  final VoidCallback? onComplete;

  @override
  State<CharlotteVoiceLine> createState() => _CharlotteVoiceLineState();
}

class _CharlotteVoiceLineState extends State<CharlotteVoiceLine> {
  String _displayedText = '';
  int _charIndex = 0;

  @override
  void initState() {
    super.initState();
    _startTyping();
  }

  void _startTyping() async {
    while (_charIndex < widget.text.length && mounted) {
      await Future.delayed(widget.typingSpeed);
      if (mounted) {
        setState(() {
          _charIndex++;
          _displayedText = widget.text.substring(0, _charIndex);
        });
      }
    }
    widget.onComplete?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: _displayedText,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          // Blikající kurzor
          if (_charIndex < widget.text.length)
            WidgetSpan(
              child: _BlinkingCursor(color: AppColors.accent),
            ),
        ],
      ),
    );
  }
}

class _BlinkingCursor extends StatefulWidget {
  const _BlinkingCursor({required this.color});

  final Color color;

  @override
  State<_BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<_BlinkingCursor>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
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
        return Opacity(
          opacity: _controller.value,
          child: Container(
            width: 2,
            height: 16,
            color: widget.color,
          ),
        );
      },
    );
  }
}
