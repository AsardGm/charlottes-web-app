import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Smooth page transition with fade and slide
class SmoothPageTransition extends PageRouteBuilder {
  final Widget page;
  final Duration duration;
  final Curve curve;

  SmoothPageTransition({
    required this.page,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeOutCubic,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: duration,
          reverseTransitionDuration: duration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Combine fade and slide
            const begin = Offset(0.0, 0.03);
            const end = Offset.zero;
            final slideTween = Tween(begin: begin, end: end);
            final curveTween = CurveTween(curve: curve);

            final slideAnimation = animation.drive(slideTween.chain(curveTween));
            final fadeAnimation = animation.drive(
              Tween(begin: 0.0, end: 1.0).chain(curveTween),
            );

            return SlideTransition(
              position: slideAnimation,
              child: FadeTransition(
                opacity: fadeAnimation,
                child: child,
              ),
            );
          },
        );
}

/// Scale and fade transition (for modal-like screens)
class ScalePageTransition extends PageRouteBuilder {
  final Widget page;
  final Duration duration;

  ScalePageTransition({
    required this.page,
    this.duration = const Duration(milliseconds: 250),
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: duration,
          reverseTransitionDuration: duration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final scaleTween = Tween(begin: 0.92, end: 1.0);
            final curveTween = CurveTween(curve: Curves.easeOutCubic);

            final scaleAnimation = animation.drive(scaleTween.chain(curveTween));
            final fadeAnimation = animation.drive(
              Tween(begin: 0.0, end: 1.0).chain(curveTween),
            );

            return ScaleTransition(
              scale: scaleAnimation,
              child: FadeTransition(
                opacity: fadeAnimation,
                child: child,
              ),
            );
          },
        );
}

/// Slide from bottom transition (for sheets and forms)
class SlideFromBottomTransition extends PageRouteBuilder {
  final Widget page;
  final Duration duration;

  SlideFromBottomTransition({
    required this.page,
    this.duration = const Duration(milliseconds: 300),
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: duration,
          reverseTransitionDuration: duration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(0.0, 1.0);
            const end = Offset.zero;
            final tween = Tween(begin: begin, end: end);
            final curveTween = CurveTween(curve: Curves.easeOutCubic);

            final offsetAnimation = animation.drive(tween.chain(curveTween));

            return SlideTransition(
              position: offsetAnimation,
              child: child,
            );
          },
        );
}

/// Custom transition for GoRouter
Page<void> smoothTransitionPage({
  required Widget child,
  required LocalKey key,
  String? name,
  TransitionType type = TransitionType.smooth,
}) {
  return CustomTransitionPage(
    key: key,
    name: name,
    child: child,
    transitionDuration: type == TransitionType.scale
        ? const Duration(milliseconds: 250)
        : const Duration(milliseconds: 300),
    reverseTransitionDuration: type == TransitionType.scale
        ? const Duration(milliseconds: 250)
        : const Duration(milliseconds: 300),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      switch (type) {
        case TransitionType.smooth:
          const begin = Offset(0.0, 0.03);
          const end = Offset.zero;
          final slideTween = Tween(begin: begin, end: end);
          final curveTween = CurveTween(curve: Curves.easeOutCubic);

          final slideAnimation = animation.drive(slideTween.chain(curveTween));
          final fadeAnimation = animation.drive(
            Tween(begin: 0.0, end: 1.0).chain(curveTween),
          );

          return SlideTransition(
            position: slideAnimation,
            child: FadeTransition(
              opacity: fadeAnimation,
              child: child,
            ),
          );

        case TransitionType.scale:
          final scaleTween = Tween(begin: 0.92, end: 1.0);
          final curveTween = CurveTween(curve: Curves.easeOutCubic);

          final scaleAnimation = animation.drive(scaleTween.chain(curveTween));
          final fadeAnimation = animation.drive(
            Tween(begin: 0.0, end: 1.0).chain(curveTween),
          );

          return ScaleTransition(
            scale: scaleAnimation,
            child: FadeTransition(
              opacity: fadeAnimation,
              child: child,
            ),
          );

        case TransitionType.slideFromBottom:
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          final tween = Tween(begin: begin, end: end);
          final curveTween = CurveTween(curve: Curves.easeOutCubic);

          final offsetAnimation = animation.drive(tween.chain(curveTween));

          return SlideTransition(
            position: offsetAnimation,
            child: child,
          );

        case TransitionType.fade:
          return FadeTransition(
            opacity: animation.drive(
              Tween(begin: 0.0, end: 1.0).chain(
                CurveTween(curve: Curves.easeOut),
              ),
            ),
            child: child,
          );
      }
    },
  );
}

enum TransitionType {
  smooth,
  scale,
  slideFromBottom,
  fade,
}
