import 'package:flutter/material.dart';

/// Custom page transitions for smooth navigation
class PageTransitions {
  /// Slide transition from right (default for push)
  static Route<T> slideFromRight<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOutCubic;

        var tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  /// Slide from bottom (for modals)
  static Route<T> slideFromBottom<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 1.0);
        const end = Offset.zero;
        const curve = Curves.easeOutCubic;

        var tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 350),
    );
  }

  /// Fade transition (for subtle screens)
  static Route<T> fade<T>(Widget page, {Duration? duration}) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      transitionDuration: duration ?? const Duration(milliseconds: 250),
    );
  }

  /// Scale + Fade (for popups/details)
  static Route<T> scaleFade<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const curve = Curves.easeOutCubic;

        var scaleTween = Tween(begin: 0.9, end: 1.0).chain(
          CurveTween(curve: curve),
        );

        var fadeTween = Tween(begin: 0.0, end: 1.0).chain(
          CurveTween(curve: curve),
        );

        return ScaleTransition(
          scale: animation.drive(scaleTween),
          child: FadeTransition(
            opacity: animation.drive(fadeTween),
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
      opaque: false,
    );
  }

  /// Shared axis transition (Material Design)
  static Route<T> sharedAxis<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const curve = Curves.easeInOutCubic;

        var slideInTween = Tween(begin: const Offset(0.05, 0.0), end: Offset.zero).chain(
          CurveTween(curve: curve),
        );

        var fadeInTween = Tween(begin: 0.0, end: 1.0).chain(
          CurveTween(curve: curve),
        );

        return SlideTransition(
          position: animation.drive(slideInTween),
          child: FadeTransition(
            opacity: animation.drive(fadeInTween),
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  /// No animation (instant)
  static Route<T> instant<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) => child,
      transitionDuration: Duration.zero,
    );
  }
}

/// Animated container mixin for easy animations
mixin AnimatedCardMixin<T extends StatefulWidget> on State<T> {
  bool _isPressed = false;

  void setPressed(bool pressed) {
    if (mounted) {
      setState(() => _isPressed = pressed);
    }
  }

  Widget buildAnimatedCard({
    required Widget child,
    VoidCallback? onTap,
    Duration duration = const Duration(milliseconds: 150),
    double pressedScale = 0.97,
    double pressedOpacity = 0.9,
  }) {
    return GestureDetector(
      onTapDown: (_) => setPressed(true),
      onTapUp: (_) {
        setPressed(false);
        onTap?.call();
      },
      onTapCancel: () => setPressed(false),
      child: AnimatedScale(
        scale: _isPressed ? pressedScale : 1.0,
        duration: duration,
        curve: Curves.easeInOut,
        child: AnimatedOpacity(
          opacity: _isPressed ? pressedOpacity : 1.0,
          duration: duration,
          child: child,
        ),
      ),
    );
  }
}

/// Staggered list animation
class StaggeredListAnimation extends StatelessWidget {
  final int index;
  final Widget child;
  final Duration delay;
  final Duration duration;

  const StaggeredListAnimation({
    super.key,
    required this.index,
    required this.child,
    this.delay = const Duration(milliseconds: 50),
    this.duration = const Duration(milliseconds: 400),
  });

  @override
  Widget build(BuildContext context) {
    final delayDuration = delay * index;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: duration + delayDuration,
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

/// Fade in on scroll animation
class FadeInOnScroll extends StatefulWidget {
  final Widget child;
  final ScrollController? scrollController;
  final double fadeStartOffset;

  const FadeInOnScroll({
    super.key,
    required this.child,
    this.scrollController,
    this.fadeStartOffset = 100.0,
  });

  @override
  State<FadeInOnScroll> createState() => _FadeInOnScrollState();
}

class _FadeInOnScrollState extends State<FadeInOnScroll> {
  double _opacity = 0.0;

  @override
  void initState() {
    super.initState();
    widget.scrollController?.addListener(_onScroll);
    // Fade in after a short delay
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() => _opacity = 1.0);
      }
    });
  }

  @override
  void dispose() {
    widget.scrollController?.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    if (widget.scrollController == null) return;

    final offset = widget.scrollController!.offset;
    final newOpacity = (offset / widget.fadeStartOffset).clamp(0.0, 1.0);

    if ((newOpacity - _opacity).abs() > 0.01) {
      setState(() => _opacity = newOpacity);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _opacity,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      child: widget.child,
    );
  }
}

/// Pulse animation (for notifications, new content)
class PulseAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final bool infinite;

  const PulseAnimation({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1500),
    this.infinite = true,
  });

  @override
  State<PulseAnimation> createState() => _PulseAnimationState();
}

class _PulseAnimationState extends State<PulseAnimation>
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

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    if (widget.infinite) {
      _controller.repeat(reverse: true);
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: widget.child,
    );
  }
}

/// Slide in from direction
enum SlideDirection { left, right, top, bottom }

class SlideInAnimation extends StatelessWidget {
  final Widget child;
  final SlideDirection direction;
  final Duration duration;
  final Duration delay;

  const SlideInAnimation({
    super.key,
    required this.child,
    this.direction = SlideDirection.left,
    this.duration = const Duration(milliseconds: 400),
    this.delay = Duration.zero,
  });

  Offset _getBeginOffset() {
    switch (direction) {
      case SlideDirection.left:
        return const Offset(-1.0, 0.0);
      case SlideDirection.right:
        return const Offset(1.0, 0.0);
      case SlideDirection.top:
        return const Offset(0.0, -1.0);
      case SlideDirection.bottom:
        return const Offset(0.0, 1.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<Offset>(
      tween: Tween(begin: _getBeginOffset(), end: Offset.zero),
      duration: duration + delay,
      curve: Curves.easeOutCubic,
      builder: (context, offset, child) {
        return Transform.translate(
          offset: Offset(offset.dx * 100, offset.dy * 100),
          child: child,
        );
      },
      child: child,
    );
  }
}
