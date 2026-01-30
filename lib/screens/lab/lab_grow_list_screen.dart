import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/lab/lab_grow_model.dart';
import '../../providers/lab_provider.dart';
import '../../theme/theme.dart';

/// Seznam vsech grows uzivatele
class LabGrowListScreen extends ConsumerWidget {
  const LabGrowListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final grows = ref.watch(labGrowsProvider);

    return Scaffold(
      backgroundColor: AppColors.functionalBg,
      appBar: AppBar(
        title: const Text('Moje Grows'),
        backgroundColor: AppColors.surface,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/lab/create-grow'),
          ),
        ],
      ),
      body: grows.when(
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.eco, size: 64, color: AppColors.functionalMuted),
                  const SizedBox(height: 16),
                  Text(
                    'Zatim zadne grows',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Zaloz svuj prvni pestovaci denik',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => context.push('/lab/create-grow'),
                    icon: const Icon(Icons.add),
                    label: const Text('Novy Grow'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(labGrowsProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              itemBuilder: (context, index) {
                final grow = list[index];
                return _GrowListItem(grow: grow);
              },
            ),
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

class _GrowListItem extends StatelessWidget {
  final LabGrowModel grow;

  const _GrowListItem({required this.grow});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.functionalSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: grow.isActive
              ? AppColors.accent.withAlpha(60)
              : AppColors.functionalBorder,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/lab/chronos/${grow.id}'),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        grow.name,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (grow.isActive)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withAlpha(25),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'AKTIVNI',
                          style: TextStyle(
                            color: AppColors.accent,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
                if (grow.strainName != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    grow.strainName!,
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    _buildInfoTag(grow.phase.icon, grow.phase.label),
                    const SizedBox(width: 8),
                    _buildInfoTag('📅', 'Den ${grow.dayCount}'),
                    if (grow.environment != null) ...[
                      const SizedBox(width: 8),
                      _buildInfoTag('🏠', grow.environment!.label),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoTag(String icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.functionalBg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$icon $label',
        style: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 11,
        ),
      ),
    );
  }
}
