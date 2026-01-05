import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// Holografický průvodce aplikací - Charlotte
/// Cyan wireframe postava s tabletem a digitálním interfacem
class HolographicGuide extends StatefulWidget {
  const HolographicGuide({
    super.key,
    this.size = 200,
    this.showGlow = true,
    this.animate = true,
  });

  /// Velikost průvodce
  final double size;

  /// Zobrazit cyan záři kolem postavy
  final bool showGlow;

  /// Animovat efekty (flicker, glow pulse)
  final bool animate;

  @override
  State<HolographicGuide> createState() => _HolographicGuideState();
}

class _HolographicGuideState extends State<HolographicGuide>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowAnimation;
  late Animation<double> _flickerAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _glowAnimation = Tween<double>(begin: 0.4, end: 0.8).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _flickerAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
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
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.size,
          height: widget.size * 1.5,
          decoration: widget.showGlow
              ? BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: _glowAnimation.value * 0.3),
                      blurRadius: 40,
                      spreadRadius: 10,
                    ),
                  ],
                )
              : null,
          child: Opacity(
            opacity: widget.animate ? _flickerAnimation.value : 1.0,
            child: Image.asset(
              'assets/images/pruvodce.png',
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
          ),
        );
      },
    );
  }
}

/// Průvodce s bublinou pro text - pro tutoriály a nápovědy
class GuideSpeechBubble extends StatelessWidget {
  const GuideSpeechBubble({
    super.key,
    required this.message,
    this.guideSize = 120,
    this.position = GuidePosition.left,
    this.onDismiss,
    this.onAction,
    this.actionLabel,
    this.showSkip = false,
    this.onSkip,
  });

  /// Zpráva průvodce
  final String message;

  /// Velikost průvodce
  final double guideSize;

  /// Pozice průvodce (vlevo/vpravo od bubliny)
  final GuidePosition position;

  /// Callback při zavření
  final VoidCallback? onDismiss;

  /// Callback pro akční tlačítko
  final VoidCallback? onAction;

  /// Popisek akčního tlačítka
  final String? actionLabel;

  /// Zobrazit tlačítko Skip
  final bool showSkip;

  /// Callback pro skip
  final VoidCallback? onSkip;

  @override
  Widget build(BuildContext context) {
    final guide = HolographicGuide(
      size: guideSize,
      showGlow: true,
      animate: true,
    );

    final bubble = _SpeechBubble(
      message: message,
      position: position,
      onDismiss: onDismiss,
      onAction: onAction,
      actionLabel: actionLabel,
      showSkip: showSkip,
      onSkip: onSkip,
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: position == GuidePosition.left
          ? [guide, const SizedBox(width: 12), Flexible(child: bubble)]
          : [Flexible(child: bubble), const SizedBox(width: 12), guide],
    );
  }
}

/// Pozice průvodce vzhledem k bublině
enum GuidePosition { left, right }

class _SpeechBubble extends StatelessWidget {
  const _SpeechBubble({
    required this.message,
    required this.position,
    this.onDismiss,
    this.onAction,
    this.actionLabel,
    this.showSkip = false,
    this.onSkip,
  });

  final String message;
  final GuidePosition position;
  final VoidCallback? onDismiss;
  final VoidCallback? onAction;
  final String? actionLabel;
  final bool showSkip;
  final VoidCallback? onSkip;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.functionalSurface,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: position == GuidePosition.left
              ? const Radius.circular(4)
              : const Radius.circular(16),
          bottomRight: position == GuidePosition.right
              ? const Radius.circular(4)
              : const Radius.circular(16),
        ),
        border: Border.all(
          color: AppColors.accent.withValues(alpha: 0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.2),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header s názvem průvodce
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'CHARLOTTE',
                  style: TextStyle(
                    color: AppColors.accent,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const Spacer(),
              if (onDismiss != null)
                GestureDetector(
                  onTap: onDismiss,
                  child: Icon(
                    Icons.close,
                    size: 18,
                    color: AppColors.functionalMuted,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // Zpráva
          Text(
            message,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          // Tlačítka
          if (onAction != null || showSkip) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (showSkip)
                  TextButton(
                    onPressed: onSkip,
                    child: Text(
                      'Přeskočit',
                      style: TextStyle(
                        color: AppColors.functionalMuted,
                        fontSize: 13,
                      ),
                    ),
                  ),
                if (onAction != null) ...[
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: onAction,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      actionLabel ?? 'Pokračovat',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Overlay s průvodcem pro tutoriály
class GuideOverlay extends StatelessWidget {
  const GuideOverlay({
    super.key,
    required this.child,
    required this.message,
    this.isVisible = true,
    this.highlightPosition,
    this.highlightSize,
    this.onDismiss,
    this.onNext,
    this.showSkip = false,
    this.onSkip,
    this.step,
    this.totalSteps,
  });

  /// Widget pod overlayem
  final Widget child;

  /// Zpráva průvodce
  final String message;

  /// Je overlay viditelný
  final bool isVisible;

  /// Pozice zvýrazněné oblasti
  final Offset? highlightPosition;

  /// Velikost zvýrazněné oblasti
  final Size? highlightSize;

  /// Callback při zavření
  final VoidCallback? onDismiss;

  /// Callback pro další krok
  final VoidCallback? onNext;

  /// Zobrazit skip
  final bool showSkip;

  /// Callback pro skip
  final VoidCallback? onSkip;

  /// Aktuální krok tutoriálu
  final int? step;

  /// Celkový počet kroků
  final int? totalSteps;

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return child;

    return Stack(
      children: [
        child,
        // Tmavý overlay
        Positioned.fill(
          child: GestureDetector(
            onTap: onDismiss,
            child: Container(
              color: Colors.black.withValues(alpha: 0.7),
            ),
          ),
        ),
        // Průvodce s bublinou
        Positioned(
          left: 16,
          right: 16,
          bottom: 100,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GuideSpeechBubble(
                message: message,
                guideSize: 100,
                position: GuidePosition.left,
                onDismiss: onDismiss,
                onAction: onNext,
                actionLabel: step != null && totalSteps != null
                    ? 'Další ($step/$totalSteps)'
                    : 'Pokračovat',
                showSkip: showSkip,
                onSkip: onSkip,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Malý plovoucí průvodce pro rychlé tipy
class GuideTooltip extends StatefulWidget {
  const GuideTooltip({
    super.key,
    required this.message,
    this.duration = const Duration(seconds: 5),
    this.onDismiss,
  });

  final String message;
  final Duration duration;
  final VoidCallback? onDismiss;

  @override
  State<GuideTooltip> createState() => _GuideTooltipState();
}

class _GuideTooltipState extends State<GuideTooltip>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();

    // Auto dismiss
    Future.delayed(widget.duration, () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  void _dismiss() {
    _controller.reverse().then((_) {
      widget.onDismiss?.call();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          margin: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Mini průvodce
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.5),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.3),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/pruvodce.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Zpráva
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.functionalSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.accent.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.message,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: _dismiss,
                        child: Icon(
                          Icons.close,
                          size: 18,
                          color: AppColors.functionalMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
