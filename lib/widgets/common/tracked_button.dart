import 'package:flutter/material.dart';
import '../../services/analytics_service.dart';
import '../../services/haptic_service.dart';

/// Button that automatically tracks taps with analytics
class TrackedButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final String eventName;
  final Map<String, dynamic>? eventProperties;
  final bool enableHaptic;
  final ButtonStyle? style;

  const TrackedButton({
    super.key,
    required this.child,
    required this.onPressed,
    required this.eventName,
    this.eventProperties,
    this.enableHaptic = true,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      style: style,
      onPressed: onPressed != null
          ? () {
              // Track event
              AnalyticsService().trackAction(eventName, properties: eventProperties);

              // Haptic feedback
              if (enableHaptic) {
                HapticService.light();
              }

              // Call original callback
              onPressed!();
            }
          : null,
      child: child,
    );
  }
}

/// Text button with tracking
class TrackedTextButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final String eventName;
  final Map<String, dynamic>? eventProperties;
  final bool enableHaptic;
  final ButtonStyle? style;

  const TrackedTextButton({
    super.key,
    required this.child,
    required this.onPressed,
    required this.eventName,
    this.eventProperties,
    this.enableHaptic = true,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      style: style,
      onPressed: onPressed != null
          ? () {
              AnalyticsService().trackAction(eventName, properties: eventProperties);
              if (enableHaptic) HapticService.light();
              onPressed!();
            }
          : null,
      child: child,
    );
  }
}

/// Icon button with tracking
class TrackedIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String eventName;
  final Map<String, dynamic>? eventProperties;
  final bool enableHaptic;
  final Color? color;
  final double? size;

  const TrackedIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.eventName,
    this.eventProperties,
    this.enableHaptic = true,
    this.color,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: size),
      color: color,
      onPressed: onPressed != null
          ? () {
              AnalyticsService().trackAction(eventName, properties: eventProperties);
              if (enableHaptic) HapticService.light();
              onPressed!();
            }
          : null,
    );
  }
}

/// Card with tap tracking
class TrackedCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final String eventName;
  final Map<String, dynamic>? eventProperties;
  final bool enableHaptic;
  final EdgeInsets? padding;
  final Decoration? decoration;

  const TrackedCard({
    super.key,
    required this.child,
    required this.onTap,
    required this.eventName,
    this.eventProperties,
    this.enableHaptic = true,
    this.padding,
    this.decoration,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap != null
          ? () {
              AnalyticsService().trackAction(eventName, properties: eventProperties);
              if (enableHaptic) HapticService.light();
              onTap!();
            }
          : null,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: padding,
        decoration: decoration,
        child: child,
      ),
    );
  }
}

/// Floating action button with tracking
class TrackedFAB extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final String eventName;
  final Map<String, dynamic>? eventProperties;
  final bool enableHaptic;
  final Color? backgroundColor;

  const TrackedFAB({
    super.key,
    required this.child,
    required this.onPressed,
    required this.eventName,
    this.eventProperties,
    this.enableHaptic = true,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      backgroundColor: backgroundColor,
      onPressed: onPressed != null
          ? () {
              AnalyticsService().trackAction(eventName, properties: eventProperties);
              if (enableHaptic) HapticService.medium();
              onPressed!();
            }
          : null,
      child: child,
    );
  }
}

/// Example usage:
///
/// TrackedButton(
///   eventName: AnalyticsEvents.challengeStarted,
///   eventProperties: {'challenge_id': challenge.id},
///   onPressed: _startChallenge,
///   child: Text('Start Challenge'),
/// )
///
/// TrackedIconButton(
///   icon: Icons.favorite,
///   eventName: 'post_liked',
///   eventProperties: {'post_id': post.id},
///   onPressed: _likePost,
/// )
