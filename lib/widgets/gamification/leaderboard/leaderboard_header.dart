import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../theme/theme.dart';

/// Header zebricku s XP uzivatele
class LeaderboardHeader extends StatelessWidget {
  /// Aktualni XP uzivatele
  final AsyncValue<int> currentUserXp;

  const LeaderboardHeader({
    super.key,
    required this.currentUserXp,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primary.withAlpha(40),
            AppColors.background,
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            Icon(
              Icons.emoji_events,
              size: 48,
              color: AppColors.warning,
            ),
            const SizedBox(height: 8),
            Text(
              'Zebricek',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            currentUserXp.when(
              data: (xp) => Text(
                'Tvoje XP: $xp',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              loading: () => const SizedBox(),
              error: (_, _) => const SizedBox(),
            ),
          ],
        ),
      ),
    );
  }
}
