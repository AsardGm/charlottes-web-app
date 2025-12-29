import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/theme.dart';

/// Moderní search bar tlačítko (Instagram/TikTok styl)
///
/// Zobrazuje se jako klikatelný placeholder pro vyhledávání.
/// Obsahuje animace, haptic feedback a různé styly.
class SearchBarButton extends StatefulWidget {
  /// Callback při kliknutí
  final VoidCallback onTap;

  /// Placeholder text
  final String placeholder;

  /// Výška komponenty
  final double height;

  /// Ikona na levé straně
  final IconData icon;

  /// Trailing widget (mikrofon, QR)
  final Widget? trailing;

  /// Styl varianty
  final SearchBarStyle style;

  /// Animovaný gradient border
  final bool animatedBorder;

  /// Zobrazit shimmer efekt
  final bool shimmerEffect;

  const SearchBarButton({
    super.key,
    required this.onTap,
    this.placeholder = 'Hledat...',
    this.height = 44,
    this.icon = Icons.search_rounded,
    this.trailing,
    this.style = SearchBarStyle.modern,
    this.animatedBorder = false,
    this.shimmerEffect = false,
  });

  @override
  State<SearchBarButton> createState() => _SearchBarButtonState();
}

class _SearchBarButtonState extends State<SearchBarButton>
    with TickerProviderStateMixin {
  bool _isPressed = false;
  late AnimationController _borderController;
  late AnimationController _shimmerController;
  late AnimationController _pulseController;
  late Animation<double> _borderAnimation;
  late Animation<double> _shimmerAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Border rotation animation
    _borderController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _borderAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _borderController, curve: Curves.linear),
    );

    // Shimmer animation
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _shimmerAnimation = Tween<double>(begin: -1, end: 2).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

    // Pulse animation for icon
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.animatedBorder) {
      _borderController.repeat();
    }
    if (widget.shimmerEffect) {
      _shimmerController.repeat();
    }
  }

  @override
  void dispose() {
    _borderController.dispose();
    _shimmerController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _pulseController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _pulseController.reverse();
    HapticFeedback.lightImpact();
    widget.onTap();
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    _pulseController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          child: _buildSearchBar(),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    if (widget.animatedBorder) {
      return _buildAnimatedBorderBar();
    }
    return _buildStandardBar();
  }

  Widget _buildStandardBar() {
    Widget content = Container(
      height: widget.height,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: _getDecoration(),
      child: _buildContent(),
    );

    if (widget.shimmerEffect) {
      return _wrapWithShimmer(content);
    }
    return content;
  }

  Widget _wrapWithShimmer(Widget child) {
    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, _) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.white.withAlpha(0),
                Colors.white.withAlpha(40),
                Colors.white.withAlpha(0),
              ],
              stops: [
                _shimmerAnimation.value - 0.3,
                _shimmerAnimation.value,
                _shimmerAnimation.value + 0.3,
              ].map((s) => s.clamp(0.0, 1.0)).toList(),
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcATop,
          child: child,
        );
      },
    );
  }

  Widget _buildAnimatedBorderBar() {
    return AnimatedBuilder(
      animation: _borderAnimation,
      builder: (context, child) {
        return Container(
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.height / 2),
            gradient: SweepGradient(
              center: Alignment.center,
              transform: GradientRotation(_borderAnimation.value * math.pi * 2),
              colors: [
                AppColors.primary,
                AppColors.primaryLight,
                const Color(0xFFEC4899), // Pink accent
                AppColors.primary,
              ],
            ),
          ),
          child: Container(
            margin: const EdgeInsets.all(2),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(widget.height / 2 - 2),
            ),
            child: _buildContent(),
          ),
        );
      },
    );
  }

  BoxDecoration _getDecoration() {
    switch (widget.style) {
      case SearchBarStyle.filled:
        return BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(widget.height / 2),
        );

      case SearchBarStyle.outlined:
        return BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(widget.height / 2),
          border: Border.all(
            color: _isPressed
                ? AppColors.primary.withAlpha(150)
                : AppColors.textMuted.withAlpha(40),
            width: 1.5,
          ),
        );

      case SearchBarStyle.glass:
        return BoxDecoration(
          color: AppColors.surface.withAlpha(200),
          borderRadius: BorderRadius.circular(widget.height / 2),
          border: Border.all(
            color: Colors.white.withAlpha(15),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(30),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: AppColors.primary.withAlpha(_isPressed ? 30 : 0),
              blurRadius: 20,
              spreadRadius: -5,
            ),
          ],
        );

      case SearchBarStyle.modern:
        return BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.surface,
              AppColors.surfaceLight.withAlpha(200),
            ],
          ),
          borderRadius: BorderRadius.circular(widget.height / 2),
          border: Border.all(
            color: _isPressed
                ? AppColors.primary.withAlpha(100)
                : Colors.white.withAlpha(8),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(25),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
            if (_isPressed)
              BoxShadow(
                color: AppColors.primary.withAlpha(20),
                blurRadius: 16,
                spreadRadius: -4,
              ),
          ],
        );

      case SearchBarStyle.pill:
        return BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(widget.height / 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(15),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        );

      case SearchBarStyle.neumorphic:
        return BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(widget.height / 2),
          boxShadow: [
            // Light shadow (top-left)
            BoxShadow(
              color: Colors.white.withAlpha(8),
              blurRadius: 8,
              offset: const Offset(-4, -4),
            ),
            // Dark shadow (bottom-right)
            BoxShadow(
              color: Colors.black.withAlpha(40),
              blurRadius: 8,
              offset: const Offset(4, 4),
            ),
          ],
        );
    }
  }

  Widget _buildContent() {
    return Row(
      children: [
        // Search icon with pulse animation
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _isPressed ? _pulseAnimation.value : 1.0,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: _isPressed
                      ? AppColors.primary.withAlpha(20)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  widget.icon,
                  color: _isPressed ? AppColors.primary : AppColors.textMuted,
                  size: 20,
                ),
              ),
            );
          },
        ),
        const SizedBox(width: 12),

        // Placeholder text with animated color
        Expanded(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              color: _isPressed
                  ? AppColors.textSecondary
                  : AppColors.textMuted,
              fontSize: 15,
              fontWeight: FontWeight.w400,
              letterSpacing: 0.2,
            ),
            child: Text(
              widget.placeholder,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),

        // Trailing widget
        if (widget.trailing != null) ...[
          const SizedBox(width: 8),
          widget.trailing!,
        ],
      ],
    );
  }
}

/// Styly search baru
enum SearchBarStyle {
  /// Vyplněný pozadím
  filled,

  /// Pouze obrys
  outlined,

  /// Skleněný efekt
  glass,

  /// Moderní gradient (výchozí)
  modern,

  /// Pill shape
  pill,

  /// Neumorphic efekt
  neumorphic,
}

/// Rozšířený search bar s textovým polem
class ExpandedSearchBar extends StatefulWidget {
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final String placeholder;
  final bool autofocus;
  final bool showClearButton;
  final VoidCallback? onBack;
  final Widget? trailing;

  const ExpandedSearchBar({
    super.key,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.placeholder = 'Hledat...',
    this.autofocus = true,
    this.showClearButton = true,
    this.onBack,
    this.trailing,
  });

  @override
  State<ExpandedSearchBar> createState() => _ExpandedSearchBarState();
}

class _ExpandedSearchBarState extends State<ExpandedSearchBar>
    with SingleTickerProviderStateMixin {
  late TextEditingController _controller;
  late AnimationController _focusController;
  late Animation<double> _focusAnimation;
  bool _hasText = false;
  bool _isFocused = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _hasText = _controller.text.isNotEmpty;
    _controller.addListener(_onTextChanged);

    _focusController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _focusAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _focusController, curve: Curves.easeOut),
    );

    _focusNode.addListener(() {
      setState(() => _isFocused = _focusNode.hasFocus);
      if (_focusNode.hasFocus) {
        _focusController.forward();
      } else {
        _focusController.reverse();
      }
    });
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    _focusController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _controller.text.isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
  }

  void _clear() {
    _controller.clear();
    widget.onChanged?.call('');
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _focusAnimation,
      builder: (context, child) {
        return Container(
          height: 44,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.surface,
                Color.lerp(
                  AppColors.surface,
                  AppColors.surfaceLight,
                  _focusAnimation.value * 0.5,
                )!,
              ],
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: Color.lerp(
                Colors.white.withAlpha(8),
                AppColors.primary.withAlpha(80),
                _focusAnimation.value,
              )!,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(20),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
              BoxShadow(
                color: AppColors.primary.withAlpha(
                  (20 * _focusAnimation.value).toInt(),
                ),
                blurRadius: 16,
                spreadRadius: -4,
              ),
            ],
          ),
          child: Row(
            children: [
              // Back/Search icon
              GestureDetector(
                onTap: widget.onBack,
                child: Padding(
                  padding: const EdgeInsets.only(left: 14, right: 4),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      widget.onBack != null ? Icons.arrow_back_rounded : Icons.search_rounded,
                      key: ValueKey(widget.onBack != null),
                      color: _isFocused ? AppColors.primary : AppColors.textMuted,
                      size: 22,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Text field
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  autofocus: widget.autofocus,
                  textInputAction: TextInputAction.search,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                  ),
                  cursorColor: AppColors.primary,
                  decoration: InputDecoration(
                    hintText: widget.placeholder,
                    hintStyle: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                  ),
                  onChanged: widget.onChanged,
                  onSubmitted: widget.onSubmitted,
                ),
              ),

              // Clear button
              AnimatedOpacity(
                opacity: _hasText ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 150),
                child: AnimatedScale(
                  scale: _hasText ? 1.0 : 0.8,
                  duration: const Duration(milliseconds: 150),
                  child: GestureDetector(
                    onTap: _hasText ? _clear : null,
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.textMuted.withAlpha(40),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        color: AppColors.textPrimary,
                        size: 14,
                      ),
                    ),
                  ),
                ),
              ),

              // Trailing widget
              if (widget.trailing != null) ...[
                widget.trailing!,
                const SizedBox(width: 12),
              ] else if (!_hasText) ...[
                const SizedBox(width: 14),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// Voice search button pro trailing
class VoiceSearchButton extends StatefulWidget {
  final VoidCallback? onTap;

  const VoiceSearchButton({super.key, this.onTap});

  @override
  State<VoiceSearchButton> createState() => _VoiceSearchButtonState();
}

class _VoiceSearchButtonState extends State<VoiceSearchButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        HapticFeedback.mediumImpact();
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _isPressed
              ? AppColors.primary.withAlpha(30)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.mic_rounded,
          color: _isPressed ? AppColors.primary : AppColors.textMuted,
          size: 20,
        ),
      ),
    );
  }
}
