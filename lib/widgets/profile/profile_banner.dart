import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../theme/theme.dart';
import '../../models/rank_model.dart';

/// Styl banneru
enum BannerStyle {
  /// Jednoduchy obrazek
  simple,

  /// Gradient overlay
  gradient,

  /// Paralax efekt
  parallax,

  /// Blur efekt
  blur,

  /// Animated gradient (pro vyssi ranky)
  animatedGradient,
}

/// Widget pro profilovy banner (podobne jako Twitter/X)
class ProfileBanner extends StatefulWidget {
  /// URL obrazku banneru
  final String? imageUrl;

  /// Vyska banneru
  final double height;

  /// Styl banneru
  final BannerStyle style;

  /// Rank uzivatele (pro specialni efekty)
  final SpiderRank? rank;

  /// Callback pro zmenu banneru
  final VoidCallback? onEdit;

  /// Zobrazit tlacitko editace?
  final bool showEditButton;

  /// Scroll offset pro paralax efekt
  final double scrollOffset;

  /// Fallback gradient pokud neni obrazek
  final List<Color>? fallbackGradient;

  const ProfileBanner({
    super.key,
    this.imageUrl,
    this.height = 150,
    this.style = BannerStyle.gradient,
    this.rank,
    this.onEdit,
    this.showEditButton = false,
    this.scrollOffset = 0,
    this.fallbackGradient,
  });

  @override
  State<ProfileBanner> createState() => _ProfileBannerState();
}

class _ProfileBannerState extends State<ProfileBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _gradientAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _gradientAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    if (widget.style == BannerStyle.animatedGradient) {
      _animationController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Hlavni obsah banneru
          _buildBannerContent(),

          // Gradient overlay
          if (widget.style == BannerStyle.gradient ||
              widget.style == BannerStyle.blur)
            _buildGradientOverlay(),

          // Animated gradient pro vyssi ranky
          if (widget.style == BannerStyle.animatedGradient)
            _buildAnimatedGradient(),

          // Tlacitko editace
          if (widget.showEditButton && widget.onEdit != null)
            Positioned(
              right: 12,
              bottom: 12,
              child: _buildEditButton(),
            ),
        ],
      ),
    );
  }

  Widget _buildBannerContent() {
    if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty) {
      return _buildImage();
    }
    return _buildFallbackGradient();
  }

  Widget _buildImage() {
    Widget image = CachedNetworkImage(
      imageUrl: widget.imageUrl!,
      fit: BoxFit.cover,
      width: double.infinity,
      height: widget.height,
      placeholder: (context, url) => _buildFallbackGradient(),
      errorWidget: (context, url, error) => _buildFallbackGradient(),
    );

    // Paralax efekt
    if (widget.style == BannerStyle.parallax) {
      final offset = widget.scrollOffset * 0.5;
      image = Transform.translate(
        offset: Offset(0, offset.clamp(-50.0, 50.0)),
        child: SizedBox(
          height: widget.height + 50,
          child: image,
        ),
      );
    }

    // Blur efekt
    if (widget.style == BannerStyle.blur) {
      image = ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
        child: image,
      );
    }

    return ClipRect(child: image);
  }

  Widget _buildFallbackGradient() {
    final colors = widget.fallbackGradient ?? _getDefaultGradient();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: _buildPatternOverlay(),
    );
  }

  Widget _buildPatternOverlay() {
    // Jemny vzor na pozadi
    return CustomPaint(
      painter: _PatternPainter(
        color: Colors.white.withAlpha(10),
        rank: widget.rank,
      ),
      size: Size.infinite,
    );
  }

  Widget _buildGradientOverlay() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            AppColors.background.withAlpha(200),
          ],
          stops: const [0.3, 1.0],
        ),
      ),
    );
  }

  Widget _buildAnimatedGradient() {
    return AnimatedBuilder(
      animation: _gradientAnimation,
      builder: (context, child) {
        final colors = _getAnimatedGradientColors();
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: colors,
              stops: [
                0,
                _gradientAnimation.value,
                1,
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEditButton() {
    return GestureDetector(
      onTap: widget.onEdit,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.background.withAlpha(200),
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.textMuted.withAlpha(50),
          ),
        ),
        child: Icon(
          Icons.camera_alt,
          size: 20,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  List<Color> _getDefaultGradient() {
    // Gradient podle ranku
    switch (widget.rank?.id) {
      case 'master':
        return [
          const Color(0xFF1a1a2e),
          const Color(0xFF16213e),
          const Color(0xFFFFD700).withAlpha(100),
        ];
      case 'widow':
        return [
          const Color(0xFF1a1a2e),
          const Color(0xFF4a1942),
          const Color(0xFFE53935).withAlpha(100),
        ];
      case 'weaver':
        return [
          const Color(0xFF1a1a2e),
          const Color(0xFF2d132c),
          const Color(0xFFBA68C8).withAlpha(100),
        ];
      case 'hunter':
        return [
          const Color(0xFF1a1a2e),
          const Color(0xFF0f3460),
          const Color(0xFF64B5F6).withAlpha(100),
        ];
      default:
        return [
          const Color(0xFF1a1a2e),
          const Color(0xFF16213e),
          AppColors.primary.withAlpha(100),
        ];
    }
  }

  List<Color> _getAnimatedGradientColors() {
    final baseColors = _getDefaultGradient();
    final progress = _gradientAnimation.value;

    return [
      Color.lerp(baseColors[0], baseColors[1], progress) ?? baseColors[0],
      Color.lerp(baseColors[1], baseColors[2], progress) ?? baseColors[1],
      Color.lerp(baseColors[2], baseColors[0], progress) ?? baseColors[2],
    ];
  }
}

/// Painter pro vzor na pozadi
class _PatternPainter extends CustomPainter {
  final Color color;
  final SpiderRank? rank;

  _PatternPainter({required this.color, this.rank});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Ruzne vzory podle ranku
    switch (rank?.id) {
      case 'master':
      case 'widow':
        _drawWebPattern(canvas, size, paint);
        break;
      case 'weaver':
        _drawDiagonalLines(canvas, size, paint);
        break;
      default:
        _drawDots(canvas, size, paint);
    }
  }

  void _drawWebPattern(Canvas canvas, Size size, Paint paint) {
    // Pavoukovy vzor
    final centerX = size.width / 2;
    final centerY = size.height;
    final rays = 12;

    for (int i = 0; i < rays; i++) {
      final angle = (i / rays) * 3.14159;
      final endX = centerX + size.width * 0.8 * (angle - 1.57).abs() / 1.57;
      final endY = 0.0;
      canvas.drawLine(
        Offset(centerX, centerY),
        Offset(endX, endY),
        paint,
      );
    }
  }

  void _drawDiagonalLines(Canvas canvas, Size size, Paint paint) {
    final spacing = 30.0;
    for (double i = -size.height; i < size.width + size.height; i += spacing) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }
  }

  void _drawDots(Canvas canvas, Size size, Paint paint) {
    paint.style = PaintingStyle.fill;
    final spacing = 20.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PatternPainter oldDelegate) {
    return oldDelegate.rank != rank;
  }
}

/// Prednastavene bannery k vyberu
class BannerPresets {
  static const List<BannerPreset> all = [
    BannerPreset(
      id: 'spider_web',
      name: 'Pavucina',
      gradient: [Color(0xFF1a1a2e), Color(0xFF16213e), Color(0xFF7B2FF7)],
    ),
    BannerPreset(
      id: 'neon_purple',
      name: 'Neon Purple',
      gradient: [Color(0xFF2d132c), Color(0xFF4a1942), Color(0xFFBA68C8)],
    ),
    BannerPreset(
      id: 'dark_forest',
      name: 'Temny les',
      gradient: [Color(0xFF0d1b0f), Color(0xFF1a3a1a), Color(0xFF2d5a2d)],
    ),
    BannerPreset(
      id: 'sunset',
      name: 'Zapad slunce',
      gradient: [Color(0xFF1a1a2e), Color(0xFF4a1942), Color(0xFFFF6B6B)],
    ),
    BannerPreset(
      id: 'ocean',
      name: 'Ocean',
      gradient: [Color(0xFF0f3460), Color(0xFF16213e), Color(0xFF64B5F6)],
    ),
    BannerPreset(
      id: 'gold',
      name: 'Zlato',
      gradient: [Color(0xFF1a1a0e), Color(0xFF3a3a1e), Color(0xFFFFD700)],
    ),
  ];
}

class BannerPreset {
  final String id;
  final String name;
  final List<Color> gradient;

  const BannerPreset({
    required this.id,
    required this.name,
    required this.gradient,
  });
}

/// Widget pro vyber banneru
class BannerPicker extends StatelessWidget {
  final String? selectedId;
  final ValueChanged<BannerPreset> onSelect;

  const BannerPicker({
    super.key,
    this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: BannerPresets.all.length,
        itemBuilder: (context, index) {
          final preset = BannerPresets.all[index];
          final isSelected = preset.id == selectedId;

          return GestureDetector(
            onTap: () => onSelect(preset),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 100,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  width: 2,
                ),
                gradient: LinearGradient(
                  colors: preset.gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Text(
                  preset.name,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    shadows: const [
                      Shadow(
                        color: Colors.black54,
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
