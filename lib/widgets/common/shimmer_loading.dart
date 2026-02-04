import 'package:flutter/material.dart';

/// Shimmer loading effect for skeleton screens
class ShimmerLoading extends StatefulWidget {
  final Widget child;
  final bool isLoading;
  final Color? baseColor;
  final Color? highlightColor;
  final Duration duration;

  const ShimmerLoading({
    super.key,
    required this.child,
    this.isLoading = true,
    this.baseColor,
    this.highlightColor,
    this.duration = const Duration(milliseconds: 1500),
  });

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
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

    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    if (widget.isLoading) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(ShimmerLoading oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoading != oldWidget.isLoading) {
      if (widget.isLoading) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLoading) {
      return widget.child;
    }

    final baseColor = widget.baseColor ?? Colors.grey[300]!;
    final highlightColor = widget.highlightColor ?? Colors.grey[100]!;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                baseColor,
                highlightColor,
                baseColor,
              ],
              stops: [
                _animation.value - 0.3,
                _animation.value,
                _animation.value + 0.3,
              ],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Pre-built shimmer skeleton widgets
class ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;
  final Color? baseColor;
  final Color? highlightColor;

  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8.0,
    this.baseColor,
    this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultBase = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final defaultHighlight = isDark ? Colors.grey[700]! : Colors.grey[100]!;

    return ShimmerLoading(
      baseColor: baseColor ?? defaultBase,
      highlightColor: highlightColor ?? defaultHighlight,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

/// Shimmer card skeleton
class ShimmerCard extends StatelessWidget {
  final double height;
  final EdgeInsets? margin;

  const ShimmerCard({
    super.key,
    this.height = 120,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ShimmerBox(
        width: double.infinity,
        height: height,
        borderRadius: 16,
      ),
    );
  }
}

/// Shimmer list item skeleton
class ShimmerListTile extends StatelessWidget {
  final bool hasAvatar;
  final bool hasTrailing;

  const ShimmerListTile({
    super.key,
    this.hasAvatar = true,
    this.hasTrailing = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasAvatar) ...[
            const ShimmerBox(width: 48, height: 48, borderRadius: 24),
            const SizedBox(width: 16),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(
                  width: double.infinity,
                  height: 16,
                  borderRadius: 4,
                ),
                const SizedBox(height: 8),
                ShimmerBox(
                  width: MediaQuery.of(context).size.width * 0.6,
                  height: 14,
                  borderRadius: 4,
                ),
              ],
            ),
          ),
          if (hasTrailing) ...[
            const SizedBox(width: 16),
            const ShimmerBox(width: 24, height: 24, borderRadius: 12),
          ],
        ],
      ),
    );
  }
}

/// Shimmer grid item
class ShimmerGridItem extends StatelessWidget {
  final double aspectRatio;

  const ShimmerGridItem({
    super.key,
    this.aspectRatio = 1.1,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: const ShimmerBox(
        width: double.infinity,
        height: double.infinity,
        borderRadius: 16,
      ),
    );
  }
}

/// Shimmer text lines
class ShimmerText extends StatelessWidget {
  final int lines;
  final double lineHeight;
  final double spacing;

  const ShimmerText({
    super.key,
    this.lines = 3,
    this.lineHeight = 16,
    this.spacing = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(lines, (index) {
        final isLast = index == lines - 1;
        final width = isLast
            ? MediaQuery.of(context).size.width * 0.7
            : double.infinity;

        return Padding(
          padding: EdgeInsets.only(bottom: isLast ? 0 : spacing),
          child: ShimmerBox(
            width: width,
            height: lineHeight,
            borderRadius: 4,
          ),
        );
      }),
    );
  }
}

/// Shimmer profile header
class ShimmerProfileHeader extends StatelessWidget {
  const ShimmerProfileHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const ShimmerBox(width: 100, height: 100, borderRadius: 50),
          const SizedBox(height: 16),
          ShimmerBox(
            width: MediaQuery.of(context).size.width * 0.4,
            height: 24,
            borderRadius: 4,
          ),
          const SizedBox(height: 8),
          ShimmerBox(
            width: MediaQuery.of(context).size.width * 0.6,
            height: 16,
            borderRadius: 4,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatShimmer(),
              _buildStatShimmer(),
              _buildStatShimmer(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatShimmer() {
    return const Column(
      children: [
        ShimmerBox(width: 50, height: 24, borderRadius: 4),
        SizedBox(height: 4),
        ShimmerBox(width: 60, height: 14, borderRadius: 4),
      ],
    );
  }
}

/// Animated loading dots
class LoadingDots extends StatefulWidget {
  final Color? color;
  final double size;
  final Duration duration;

  const LoadingDots({
    super.key,
    this.color,
    this.size = 8.0,
    this.duration = const Duration(milliseconds: 1200),
  });

  @override
  State<LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<LoadingDots>
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
    final color = widget.color ?? Theme.of(context).primaryColor;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final delay = index * 0.2;
            final value = (_controller.value - delay).clamp(0.0, 1.0);
            final scale = 0.5 + (0.5 * (1 - (value - 0.5).abs() * 2));

            return Transform.scale(
              scale: scale,
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: widget.size * 0.3),
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  color: color.withValues(alpha:0.5 + (scale * 0.5)),
                  shape: BoxShape.circle,
                ),
              ),
            );
          },
        );
      }),
    );
  }
}

/// Circular progress with glow
class GlowingCircularProgress extends StatelessWidget {
  final double size;
  final Color? color;
  final double strokeWidth;

  const GlowingCircularProgress({
    super.key,
    this.size = 40,
    this.color,
    this.strokeWidth = 3.0,
  });

  @override
  Widget build(BuildContext context) {
    final indicatorColor = color ?? Theme.of(context).primaryColor;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: indicatorColor.withValues(alpha:0.3),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        valueColor: AlwaysStoppedAnimation<Color>(indicatorColor),
      ),
    );
  }
}
