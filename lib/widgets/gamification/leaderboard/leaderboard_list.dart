import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../theme/theme.dart';
import 'leaderboard_item.dart';

/// Seznam zebricku
class LeaderboardList extends StatelessWidget {
  /// Data zebricku
  final AsyncValue<List<Map<String, dynamic>>> dataAsync;

  /// Obdobi (week, month, all)
  final String period;

  const LeaderboardList({
    super.key,
    required this.dataAsync,
    required this.period,
  });

  @override
  Widget build(BuildContext context) {
    return dataAsync.when(
      data: (entries) {
        if (entries.isEmpty) {
          return const EmptyLeaderboardState();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: entries.length,
          itemBuilder: (context, index) {
            final entry = entries[index];
            return LeaderboardItem(
              entry: entry,
              position: index + 1,
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Text(
          'Chyba: $error',
          style: TextStyle(color: AppColors.error),
        ),
      ),
    );
  }
}

/// Prazdny stav zebricku
class EmptyLeaderboardState extends StatelessWidget {
  const EmptyLeaderboardState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.leaderboard_outlined,
            size: 64,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: 16),
          Text(
            'Zebricek je prazdny',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
