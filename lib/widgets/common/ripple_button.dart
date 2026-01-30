import 'package:flutter/material.dart';
import '../../theme/theme.dart';

/// Custom button s cyan ripple efektem
///
/// Wrap jakýkoliv widget a přidá cyan ripple efekt při kliknutí
class RippleButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color? rippleColor;
  final BorderRadius? borderRadius;
  final EdgeInsets? padding;

  const RippleButton({
    super.key,
    required this.child,
    this.onTap,
    this.rippleColor,
    this.borderRadius,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: (rippleColor ?? AppColors.accent).withValues(alpha: 0.3),
        highlightColor: (rippleColor ?? AppColors.accent).withValues(alpha: 0.1),
        borderRadius: borderRadius ?? BorderRadius.circular(12),
        child: padding != null
            ? Padding(padding: padding!, child: child)
            : child,
      ),
    );
  }
}

/// Primary button s cyan ripple a gradient
class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final Color? backgroundColor;
  final double? width;

  const PrimaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.backgroundColor,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 48,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          splashColor: Colors.white.withValues(alpha: 0.3),
          highlightColor: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  backgroundColor ?? AppColors.accent,
                  (backgroundColor ?? AppColors.accent).withValues(alpha: 0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (icon != null) ...[
                          Icon(icon, size: 20, color: Colors.black),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          text,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Secondary outlined button s cyan ripple
class SecondaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? borderColor;
  final double? width;

  const SecondaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.borderColor,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final color = borderColor ?? AppColors.accent;

    return SizedBox(
      width: width,
      height: 48,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          splashColor: color.withValues(alpha: 0.2),
          highlightColor: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: color, width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20, color: color),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    text,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Icon button s circular ripple
class RippleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? color;
  final Color? rippleColor;
  final double size;

  const RippleIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.color,
    this.rippleColor,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = color ?? AppColors.textPrimary;
    final splash = rippleColor ?? AppColors.accent;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        splashColor: splash.withValues(alpha: 0.3),
        highlightColor: splash.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(50),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: size, color: iconColor),
        ),
      ),
    );
  }
}
