import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Animated card with press effect and optional glow
class AnimatedCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Duration duration;
  final double pressedScale;
  final bool enableGlow;
  final Color? glowColor;
  final BorderRadius? borderRadius;

  const AnimatedCard({
    super.key,
    required this.child,
    this.onTap,
    this.duration = const Duration(milliseconds: 150),
    this.pressedScale = 0.97,
    this.enableGlow = false,
    this.glowColor,
    this.borderRadius,
  });

  @override
  State<AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<AnimatedCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.pressedScale,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onTap?.call();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    Widget card = ScaleTransition(
      scale: _scaleAnimation,
      child: widget.child,
    );

    if (widget.enableGlow) {
      final glowColor = widget.glowColor ?? Theme.of(context).primaryColor;

      card = Container(
        decoration: BoxDecoration(
          borderRadius: widget.borderRadius ?? BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: glowColor.withValues(alpha: 0.3),
              blurRadius: 12,
              spreadRadius: 0,
            ),
          ],
        ),
        child: card,
      );
    }

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: card,
    );
  }
}

/// Animated container with smooth property changes
class SmoothAnimatedContainer extends StatelessWidget {
  final Widget? child;
  final Color? color;
  final Decoration? decoration;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Duration duration;
  final Curve curve;

  const SmoothAnimatedContainer({
    super.key,
    this.child,
    this.color,
    this.decoration,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOutCubic,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: duration,
      curve: curve,
      color: color,
      decoration: decoration,
      width: width,
      height: height,
      padding: padding,
      margin: margin,
      child: child,
    );
  }
}

/// Rotating icon animation
class RotatingIcon extends StatefulWidget {
  final IconData icon;
  final double size;
  final Color? color;
  final Duration duration;
  final bool clockwise;

  const RotatingIcon({
    super.key,
    required this.icon,
    this.size = 24,
    this.color,
    this.duration = const Duration(seconds: 2),
    this.clockwise = true,
  });

  @override
  State<RotatingIcon> createState() => _RotatingIconState();
}

class _RotatingIconState extends State<RotatingIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
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
        final angle = widget.clockwise
            ? _controller.value * 2 * math.pi
            : -_controller.value * 2 * math.pi;

        return Transform.rotate(
          angle: angle,
          child: child,
        );
      },
      child: Icon(
        widget.icon,
        size: widget.size,
        color: widget.color,
      ),
    );
  }
}

/// Bouncing widget animation
class BouncingWidget extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double bounceHeight;

  const BouncingWidget({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 800),
    this.bounceHeight = 10.0,
  });

  @override
  State<BouncingWidget> createState() => _BouncingWidgetState();
}

class _BouncingWidgetState extends State<BouncingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: 0,
      end: -widget.bounceHeight,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _animation.value),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Glowing container effect
class GlowingContainer extends StatefulWidget {
  final Widget child;
  final Color glowColor;
  final double glowRadius;
  final Duration duration;
  final bool animate;

  const GlowingContainer({
    super.key,
    required this.child,
    required this.glowColor,
    this.glowRadius = 20.0,
    this.duration = const Duration(milliseconds: 1500),
    this.animate = true,
  });

  @override
  State<GlowingContainer> createState() => _GlowingContainerState();
}

class _GlowingContainerState extends State<GlowingContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _animation = Tween<double>(begin: 0.3, end: 0.6).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    if (widget.animate) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.animate) {
      return Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: widget.glowColor.withValues(alpha: 0.4),
              blurRadius: widget.glowRadius,
              spreadRadius: 2,
            ),
          ],
        ),
        child: widget.child,
      );
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: widget.glowColor.withValues(alpha: _animation.value),
                blurRadius: widget.glowRadius,
                spreadRadius: 2,
              ),
            ],
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Number counter animation
class AnimatedCounter extends StatelessWidget {
  final int value;
  final Duration duration;
  final TextStyle? style;
  final String? suffix;
  final String? prefix;

  const AnimatedCounter({
    super.key,
    required this.value,
    this.duration = const Duration(milliseconds: 500),
    this.style,
    this.suffix,
    this.prefix,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: value),
      duration: duration,
      builder: (context, value, child) {
        return Text(
          '${prefix ?? ''}$value${suffix ?? ''}',
          style: style,
        );
      },
    );
  }
}

/// Animated progress bar with gradient
class AnimatedProgressBar extends StatelessWidget {
  final double value; // 0.0 to 1.0
  final double height;
  final Color? backgroundColor;
  final Gradient? gradient;
  final Color? color;
  final BorderRadius? borderRadius;
  final Duration duration;
  final bool showLabel;
  final String? label;

  const AnimatedProgressBar({
    super.key,
    required this.value,
    this.height = 8.0,
    this.backgroundColor,
    this.gradient,
    this.color,
    this.borderRadius,
    this.duration = const Duration(milliseconds: 500),
    this.showLabel = false,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultColor = color ?? theme.primaryColor;
    final defaultBg = backgroundColor ?? Colors.grey[800]!;
    final radius = borderRadius ?? BorderRadius.circular(height / 2);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showLabel) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (label != null)
                Text(
                  label!,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.textTheme.bodyMedium?.color,
                  ),
                ),
              Text(
                '${(value * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: defaultColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
        ],
        ClipRRect(
          borderRadius: radius,
          child: Container(
            height: height,
            color: defaultBg,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: value.clamp(0.0, 1.0)),
              duration: duration,
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: value,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: gradient ??
                          LinearGradient(
                            colors: [
                              defaultColor,
                              defaultColor.withValues(alpha: 0.8),
                            ],
                          ),
                      borderRadius: radius,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

/// Shake animation for errors
class ShakeWidget extends StatefulWidget {
  final Widget child;
  final bool shake;
  final Duration duration;

  const ShakeWidget({
    super.key,
    required this.child,
    this.shake = false,
    this.duration = const Duration(milliseconds: 500),
  });

  @override
  State<ShakeWidget> createState() => _ShakeWidgetState();
}

class _ShakeWidgetState extends State<ShakeWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticIn,
      ),
    );
  }

  @override
  void didUpdateWidget(ShakeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shake && !oldWidget.shake) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final offset = math.sin(_animation.value * math.pi * 4) * 10;
        return Transform.translate(
          offset: Offset(offset, 0),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Reveal animation (for modals, cards appearing)
class RevealAnimation extends StatelessWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final Curve curve;

  const RevealAnimation({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 400),
    this.delay = Duration.zero,
    this.curve = Curves.easeOutCubic,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: duration + delay,
      curve: curve,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.scale(
            scale: 0.9 + (0.1 * value),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
