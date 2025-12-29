import 'package:flutter/material.dart';
import '../../../theme/theme.dart';

/// Widget pro zobrazeni typing indikatoru
class TypingIndicator extends StatelessWidget {
  final List<String> typingUsers;

  const TypingIndicator({
    super.key,
    required this.typingUsers,
  });

  @override
  Widget build(BuildContext context) {
    if (typingUsers.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Animované tečky
          const TypingDots(),
          const SizedBox(width: 8),
          Text(
            'pise...',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textMuted,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

/// Animované tečky pro typing indicator
class TypingDots extends StatefulWidget {
  const TypingDots({super.key});

  @override
  State<TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<TypingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
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
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final delay = index * 0.2;
            final value = ((_controller.value + delay) % 1.0);
            final opacity = (value < 0.5 ? value * 2 : 2 - value * 2).clamp(0.3, 1.0);

            return Container(
              margin: EdgeInsets.only(right: index < 2 ? 4 : 0),
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: AppColors.textMuted.withAlpha((opacity * 255).toInt()),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}
