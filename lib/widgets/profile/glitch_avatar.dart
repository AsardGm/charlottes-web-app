import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/rank_model.dart';
import '../../theme/theme.dart';
import '../../utils/helpers.dart';

/// Styl glitch efektu
enum GlitchStyle {
  /// Zadny efekt
  none,

  /// Jemny RGB posun
  subtle,

  /// Klasicky glitch
  classic,

  /// Neonovy efekt
  neon,

  /// Pavoucina kolem avataru
  web,

  /// Pulzujici energie
  pulse,

  /// Horejici ohen
  fire,
}

/// Avatar s glitch efektem a neonovym okrajem podle ranku
class GlitchAvatar extends StatefulWidget {
  /// URL obrazku
  final String? imageUrl;

  /// Jmeno uzivatele (pro fallback)
  final String name;

  /// Velikost avataru
  final double size;

  /// Rank uzivatele (pro barvu okraje)
  final SpiderRank? rank;

  /// Styl glitch efektu
  final GlitchStyle glitchStyle;

  /// Intenzita efektu (0.0 - 1.0)
  final double intensity;

  /// Zobrazit animaci?
  final bool animated;

  /// Callback pri kliknuti
  final VoidCallback? onTap;

  /// Zobrazit level badge?
  final bool showLevelBadge;

  /// Web level (0-10 pro hustotu pavuciny)
  final int webLevel;

  const GlitchAvatar({
    super.key,
    this.imageUrl,
    required this.name,
    this.size = 100,
    this.rank,
    this.glitchStyle = GlitchStyle.subtle,
    this.intensity = 0.5,
    this.animated = true,
    this.onTap,
    this.showLevelBadge = false,
    this.webLevel = 0,
  });

  @override
  State<GlitchAvatar> createState() => _GlitchAvatarState();
}

class _GlitchAvatarState extends State<GlitchAvatar>
    with TickerProviderStateMixin {
  late AnimationController _glitchController;
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late Animation<double> _pulseAnimation;

  final _random = math.Random();
  double _glitchOffsetX = 0;
  double _glitchOffsetY = 0;

  @override
  void initState() {
    super.initState();

    // Glitch controller - nahodne glitche
    _glitchController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );

    // Pulse controller - plynuly pulz
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Rotation controller - pro web efekt
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    );

    if (widget.animated) {
      _startAnimations();
    }
  }

  void _startAnimations() {
    // Nahodne glitche
    _scheduleGlitch();

    // Pulzovani
    _pulseController.repeat(reverse: true);

    // Rotace pavuciny
    if (widget.glitchStyle == GlitchStyle.web) {
      _rotationController.repeat();
    }
  }

  void _scheduleGlitch() {
    if (!mounted || !widget.animated) return;

    final delay = Duration(
      milliseconds: 500 + _random.nextInt(3000),
    );

    Future.delayed(delay, () {
      if (!mounted) return;
      _triggerGlitch();
      _scheduleGlitch();
    });
  }

  void _triggerGlitch() {
    if (!mounted) return;

    setState(() {
      _glitchOffsetX = (_random.nextDouble() - 0.5) * widget.intensity * 10;
      _glitchOffsetY = (_random.nextDouble() - 0.5) * widget.intensity * 5;
    });

    _glitchController.forward().then((_) {
      if (mounted) {
        _glitchController.reverse();
        setState(() {
          _glitchOffsetX = 0;
          _glitchOffsetY = 0;
        });
      }
    });
  }

  @override
  void dispose() {
    _glitchController.dispose();
    _pulseController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: SizedBox(
        width: widget.size + 20,
        height: widget.size + 20,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Efekty na pozadi
            if (widget.glitchStyle == GlitchStyle.web) _buildWebEffect(),
            if (widget.glitchStyle == GlitchStyle.pulse) _buildPulseEffect(),
            if (widget.glitchStyle == GlitchStyle.fire) _buildFireEffect(),
            if (widget.glitchStyle == GlitchStyle.neon) _buildNeonGlow(),

            // Hlavni avatar s okrajem
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: widget.animated ? _pulseAnimation.value : 1.0,
                  child: _buildAvatarWithBorder(),
                );
              },
            ),

            // Level badge
            if (widget.showLevelBadge && widget.rank != null)
              Positioned(
                bottom: 0,
                right: 0,
                child: _buildLevelBadge(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarWithBorder() {
    final borderColor = widget.rank?.color ?? AppColors.primary;
    final borderWidth = _getBorderWidth();

    return Container(
      padding: EdgeInsets.all(borderWidth),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: _getBorderGradient(borderColor),
        boxShadow: [
          if (widget.glitchStyle != GlitchStyle.none)
            BoxShadow(
              color: borderColor.withAlpha(100),
              blurRadius: 15,
              spreadRadius: 2,
            ),
        ],
      ),
      child: _buildAvatarStack(),
    );
  }

  Widget _buildAvatarStack() {
    if (widget.glitchStyle == GlitchStyle.none ||
        widget.glitchStyle == GlitchStyle.web ||
        widget.glitchStyle == GlitchStyle.pulse) {
      return _buildAvatar();
    }

    // Glitch efekt - vice vrstev
    return Stack(
      children: [
        // Cerveny kanal - posunuto doleva
        if (widget.glitchStyle == GlitchStyle.classic ||
            widget.glitchStyle == GlitchStyle.subtle)
          Transform.translate(
            offset: Offset(-_glitchOffsetX * 0.5, _glitchOffsetY * 0.3),
            child: ColorFiltered(
              colorFilter: const ColorFilter.mode(
                Colors.red,
                BlendMode.modulate,
              ),
              child: Opacity(
                opacity: 0.3 * widget.intensity,
                child: _buildAvatar(),
              ),
            ),
          ),

        // Modry kanal - posunuto doprava
        if (widget.glitchStyle == GlitchStyle.classic ||
            widget.glitchStyle == GlitchStyle.subtle)
          Transform.translate(
            offset: Offset(_glitchOffsetX * 0.5, -_glitchOffsetY * 0.3),
            child: ColorFiltered(
              colorFilter: const ColorFilter.mode(
                Colors.cyan,
                BlendMode.modulate,
              ),
              child: Opacity(
                opacity: 0.3 * widget.intensity,
                child: _buildAvatar(),
              ),
            ),
          ),

        // Hlavni obrazek
        Transform.translate(
          offset: Offset(_glitchOffsetX, _glitchOffsetY),
          child: _buildAvatar(),
        ),
      ],
    );
  }

  Widget _buildAvatar() {
    return ClipOval(
      child: Container(
        width: widget.size,
        height: widget.size,
        color: AppColors.surface,
        child: widget.imageUrl != null && widget.imageUrl!.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: widget.imageUrl!,
                width: widget.size,
                height: widget.size,
                fit: BoxFit.cover,
                placeholder: (context, url) => _buildInitials(),
                errorWidget: (context, url, error) => _buildInitials(),
              )
            : _buildInitials(),
      ),
    );
  }

  Widget _buildInitials() {
    return Center(
      child: Text(
        Helpers.getInitials(widget.name),
        style: TextStyle(
          fontSize: widget.size / 2.5,
          fontWeight: FontWeight.bold,
          color: widget.rank?.color ?? AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildWebEffect() {
    return AnimatedBuilder(
      animation: _rotationController,
      builder: (context, child) {
        return Transform.rotate(
          angle: _rotationController.value * 2 * math.pi,
          child: CustomPaint(
            size: Size(widget.size + 20, widget.size + 20),
            painter: _WebPainter(
              color: widget.rank?.color ?? AppColors.primary,
              webLevel: widget.webLevel,
              intensity: widget.intensity,
            ),
          ),
        );
      },
    );
  }

  Widget _buildPulseEffect() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Container(
          width: widget.size + 30,
          height: widget.size + 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: (widget.rank?.color ?? AppColors.primary)
                  .withAlpha((50 * (2 - _pulseAnimation.value)).toInt()),
              width: 2,
            ),
          ),
        );
      },
    );
  }

  Widget _buildFireEffect() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                Colors.orange,
                Colors.red,
                Colors.transparent,
              ],
              stops: [
                0.0,
                0.5 + (_pulseAnimation.value - 1) * 0.5,
                1.0,
              ],
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcATop,
          child: Container(
            width: widget.size + 25,
            height: widget.size + 25,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.transparent,
                  Colors.orange.withAlpha(50),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNeonGlow() {
    final color = widget.rank?.color ?? AppColors.primary;
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Container(
          width: widget.size + 16,
          height: widget.size + 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withAlpha((100 * _pulseAnimation.value).toInt()),
                blurRadius: 20 * _pulseAnimation.value,
                spreadRadius: 5,
              ),
              BoxShadow(
                color: color.withAlpha((50 * _pulseAnimation.value).toInt()),
                blurRadius: 40 * _pulseAnimation.value,
                spreadRadius: 10,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLevelBadge() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.background,
        shape: BoxShape.circle,
        border: Border.all(
          color: widget.rank?.color ?? AppColors.primary,
          width: 2,
        ),
      ),
      child: Text(
        widget.rank?.emoji ?? '🥚',
        style: const TextStyle(fontSize: 16),
      ),
    );
  }

  double _getBorderWidth() {
    switch (widget.rank?.id) {
      case 'master':
        return 4;
      case 'widow':
        return 3.5;
      case 'weaver':
        return 3;
      case 'hunter':
        return 2.5;
      default:
        return 2;
    }
  }

  LinearGradient _getBorderGradient(Color baseColor) {
    // Specialni gradient pro vyssi ranky
    switch (widget.rank?.id) {
      case 'master':
        return const LinearGradient(
          colors: [
            Color(0xFFFFD700),
            Color(0xFFFFA500),
            Color(0xFFFFD700),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'widow':
        return const LinearGradient(
          colors: [
            Color(0xFFE53935),
            Color(0xFF7B1FA2),
            Color(0xFFE53935),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'weaver':
        return LinearGradient(
          colors: [
            baseColor,
            baseColor.withAlpha(200),
            baseColor,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      default:
        return LinearGradient(
          colors: [baseColor, baseColor],
        );
    }
  }
}

/// Painter pro pavucinovy efekt
class _WebPainter extends CustomPainter {
  final Color color;
  final int webLevel;
  final double intensity;

  _WebPainter({
    required this.color,
    required this.webLevel,
    required this.intensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (webLevel == 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final paint = Paint()
      ..color = color.withAlpha((80 * intensity).toInt())
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Pocet paprskovych linek
    final rays = 8 + webLevel;
    for (int i = 0; i < rays; i++) {
      final angle = (i / rays) * 2 * math.pi;
      final endX = center.dx + radius * math.cos(angle);
      final endY = center.dy + radius * math.sin(angle);
      canvas.drawLine(center, Offset(endX, endY), paint);
    }

    // Kruznice (pavucina)
    final circles = 2 + (webLevel / 3).floor();
    for (int i = 1; i <= circles; i++) {
      final r = (i / circles) * radius * 0.8;
      canvas.drawCircle(center, r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WebPainter oldDelegate) {
    return oldDelegate.webLevel != webLevel ||
        oldDelegate.intensity != intensity;
  }
}

/// Illustrace pavouciho avataru (pro vyber)
class SpiderIllustration extends StatelessWidget {
  final int index;
  final double size;
  final bool isSelected;
  final VoidCallback? onTap;

  const SpiderIllustration({
    super.key,
    required this.index,
    this.size = 60,
    this.isSelected = false,
    this.onTap,
  });

  static const _spiderEmojis = [
    '🕷️',
    '🕸️',
    '🦂',
    '🐜',
    '🪲',
    '🦗',
    '🪳',
    '🐞',
  ];

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected ? AppColors.primary.withAlpha(30) : AppColors.surface,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.surfaceLight,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            _spiderEmojis[index % _spiderEmojis.length],
            style: TextStyle(fontSize: size * 0.5),
          ),
        ),
      ),
    );
  }
}
