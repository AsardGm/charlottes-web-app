import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/lab/lab_nutrient_model.dart';
import '../../../providers/lab_provider.dart';
import '../../../theme/theme.dart';

/// Prednastavene feeding schedules
class AlchymistaSchedulesScreen extends ConsumerWidget {
  const AlchymistaSchedulesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schedules = ref.watch(labFeedingSchedulesProvider);

    return Scaffold(
      backgroundColor: AppColors.functionalBg,
      appBar: AppBar(
        title: const Text('Feeding Schedules'),
        backgroundColor: AppColors.surface,
      ),
      body: schedules.when(
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: Text(
                'Zadne recepty',
                style: TextStyle(color: AppColors.textMuted),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (context, index) {
              return _ScheduleCard(schedule: list[index]);
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
        error: (e, _) => Center(
          child: Text('Chyba: $e', style: TextStyle(color: AppColors.error)),
        ),
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  final FeedingScheduleModel schedule;

  const _ScheduleCard({required this.schedule});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.functionalSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.functionalBorder, width: 1),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.success.withAlpha(20),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.restaurant_menu,
              color: AppColors.success, size: 20),
        ),
        title: Text(
          schedule.name,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          schedule.brand ?? schedule.description ?? '',
          style: TextStyle(color: AppColors.textMuted, fontSize: 12),
        ),
        iconColor: AppColors.textMuted,
        collapsedIconColor: AppColors.textMuted,
        children: [
          ...schedule.weeks.map((week) {
            final weekNum = week['week'];
            final phase = week['phase'] ?? '';
            final products = (week['products'] as List<dynamic>?) ?? [];

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.functionalBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Tyden $weekNum',
                        style: TextStyle(
                          color: AppColors.accent,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        phase.toString(),
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ...products.map((p) {
                    final product = p as Map<String, dynamic>;
                    return Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Row(
                        children: [
                          Icon(Icons.water_drop,
                              color: AppColors.success, size: 14),
                          const SizedBox(width: 6),
                          Text(
                            '${product['name']} - ${product['ml_per_l']} ml/L',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
