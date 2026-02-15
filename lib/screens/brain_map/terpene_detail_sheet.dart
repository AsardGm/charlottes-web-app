import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/terpene_model.dart';
import '../../providers/terpene_provider.dart';
import '../../theme/theme.dart';

/// Detail sheet pro terpen
///
/// Zobrazuje kompletní informace o terpenu včetně
/// nálad, efektů, kdy ano/ne a komunitních zkušeností.
class TerpeneDetailSheet extends ConsumerWidget {
  final TerpeneModel terpene;

  const TerpeneDetailSheet({super.key, required this.terpene});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final experiencesAsync = ref.watch(terpeneExperiencesProvider(terpene.id));
    final color = _parseColor(terpene.color);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.functionalBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.functionalBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Header
                    _TerpeneHeader(terpene: terpene, color: color),
                    const SizedBox(height: 24),

                    // Aroma
                    _InfoSection(
                      icon: Icons.air,
                      iconColor: color,
                      title: 'Vůně',
                      content: terpene.aroma,
                    ),
                    const SizedBox(height: 16),

                    // Nálady
                    if (terpene.moods.isNotEmpty) ...[
                      _TagSection(
                        icon: Icons.mood,
                        iconColor: Colors.yellow.shade700,
                        title: 'Nálady',
                        tags: terpene.moods,
                        tagColor: Colors.yellow.shade700,
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Efekty
                    if (terpene.effects.isNotEmpty) ...[
                      _TagSection(
                        icon: Icons.psychology,
                        iconColor: Colors.purple,
                        title: 'Typické efekty',
                        tags: terpene.effects,
                        tagColor: Colors.purple,
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Kdy se hodí
                    if (terpene.benefits.isNotEmpty) ...[
                      _ListSection(
                        icon: Icons.check_circle,
                        iconColor: Colors.green,
                        title: 'Kdy se hodí',
                        items: terpene.benefits,
                        itemColor: Colors.green,
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Kdy ne / opatrně
                    if (terpene.cautions.isNotEmpty) ...[
                      _ListSection(
                        icon: Icons.warning,
                        iconColor: Colors.orange,
                        title: 'Kdy opatrně',
                        items: terpene.cautions,
                        itemColor: Colors.orange,
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Přírodní zdroje
                    if (terpene.naturalSources.isNotEmpty) ...[
                      _TagSection(
                        icon: Icons.eco,
                        iconColor: Colors.green,
                        title: 'Kde v přírodě',
                        tags: terpene.naturalSources,
                        tagColor: Colors.green,
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Technické info
                    _TechnicalInfo(terpene: terpene),
                    const SizedBox(height: 24),

                    // Disclaimer před zkušenostmi
                    _ExperienceDisclaimer(),
                    const SizedBox(height: 16),

                    // Komunitní zkušenosti
                    _ExperiencesSection(
                      experiencesAsync: experiencesAsync,
                      terpeneId: terpene.id,
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return AppColors.accent;
    }
  }
}

/// Header s názvem a popisem
class _TerpeneHeader extends StatelessWidget {
  final TerpeneModel terpene;
  final Color color;

  const _TerpeneHeader({required this.terpene, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: color.withAlpha(50),
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 2),
              ),
              child: Center(
                child: Text(
                  terpene.name.substring(0, 1),
                  style: TextStyle(
                    color: color,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    terpene.name,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (terpene.chemicalFormula.isNotEmpty)
                    Text(
                      terpene.chemicalFormula,
                      style: TextStyle(
                        color: AppColors.functionalMuted,
                        fontSize: 14,
                        fontFamily: 'monospace',
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          terpene.description,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 15,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

/// Info sekce s ikonou
class _InfoSection extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String content;

  const _InfoSection({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.functionalSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.functionalMuted,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Sekce s tagy
class _TagSection extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final List<String> tags;
  final Color tagColor;

  const _TagSection({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.tags,
    required this.tagColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.functionalSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: tags.map((tag) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: tagColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: tagColor.withAlpha(100)),
                ),
                child: Text(
                  tag,
                  style: TextStyle(color: tagColor, fontSize: 13),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

/// Sekce se seznamem
class _ListSection extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final List<String> items;
  final Color itemColor;

  const _ListSection({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.items,
    required this.itemColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.functionalSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    icon == Icons.warning ? Icons.warning_amber : Icons.check,
                    color: itemColor,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

/// Technické informace
class _TechnicalInfo extends StatelessWidget {
  final TerpeneModel terpene;

  const _TechnicalInfo({required this.terpene});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.functionalSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.science, color: AppColors.accent, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Technické údaje',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _InfoRow('Bod varu', '${terpene.boilingPoint.toStringAsFixed(0)}°C'),
          _InfoRow('Oblast mozku', _brainRegionName(terpene.brainRegion)),
        ],
      ),
    );
  }

  String _brainRegionName(String region) {
    switch (region) {
      case 'limbic':
        return 'Limbický systém (emoce)';
      case 'prefrontal':
        return 'Prefrontální kůra (rozhodování)';
      case 'hippocampus':
        return 'Hipokampus (paměť)';
      case 'amygdala':
        return 'Amygdala (strach, úzkost)';
      case 'hypothalamus':
        return 'Hypotalamus (hlad, spánek)';
      case 'peripheral':
        return 'Periferní systém (tělo)';
      case 'creative':
        return 'Kreativní centra';
      case 'immune':
        return 'Imunitní systém';
      default:
        return region;
    }
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: AppColors.functionalMuted)),
          Text(value, style: const TextStyle(color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}

/// Disclaimer před zkušenostmi
class _ExperienceDisclaimer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withAlpha(50)),
      ),
      child: Row(
        children: [
          Icon(Icons.gavel, color: Colors.red, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Zkušenosti jsou subjektivní. Nenaváděme k užívání bez výslovného souhlasu. '
              'Respektujte zákony.',
              style: TextStyle(color: Colors.red.shade200, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}

/// Sekce komunitních zkušeností
class _ExperiencesSection extends StatelessWidget {
  final AsyncValue<List<TerpeneExperienceModel>> experiencesAsync;
  final String terpeneId;

  const _ExperiencesSection({
    required this.experiencesAsync,
    required this.terpeneId,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Zkušenosti komunity',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline, color: AppColors.accent),
              tooltip: 'Pridat zkusenost',
              onPressed: () => _showAddExperienceDialog(context),
            ),
          ],
        ),
        const SizedBox(height: 12),
        experiencesAsync.when(
          data: (experiences) {
            if (experiences.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.functionalSurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.chat_bubble_outline,
                          color: AppColors.functionalMuted, size: 40),
                      const SizedBox(height: 12),
                      Text(
                        'Zatím žádné zkušenosti',
                        style: TextStyle(color: AppColors.functionalMuted),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Column(
              children: experiences.map((exp) {
                return _ExperienceCard(experience: exp);
              }).toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Chyba: $e'),
        ),
      ],
    );
  }

  void _showAddExperienceDialog(BuildContext context) {
    final textController = TextEditingController();
    int rating = 3;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Pridat zkusenost', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < rating ? Icons.star : Icons.star_border,
                      color: AppColors.accent,
                    ),
                    onPressed: () => setDialogState(() => rating = index + 1),
                  );
                }),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: textController,
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Tvoje zkusenost s timto terpenem...',
                  hintStyle: TextStyle(color: AppColors.textMuted),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.surfaceLight),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Zrusit', style: TextStyle(color: AppColors.textMuted)),
            ),
            ElevatedButton(
              onPressed: () {
                if (textController.text.trim().isNotEmpty) {
                  // Save will be handled by provider when integrated
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Zkusenost pridana')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
              ),
              child: const Text('Pridat'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Karta zkušenosti
class _ExperienceCard extends StatelessWidget {
  final TerpeneExperienceModel experience;

  const _ExperienceCard({required this.experience});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.functionalSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.accent.withAlpha(50),
                backgroundImage: experience.userAvatar != null
                    ? NetworkImage(experience.userAvatar!)
                    : null,
                child: experience.userAvatar == null
                    ? Icon(Icons.person, size: 16, color: AppColors.accent)
                    : null,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  experience.userName ?? 'Anonym',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              // Rating
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < experience.rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 16,
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Content
          Text(
            experience.content,
            style: TextStyle(color: AppColors.textSecondary),
          ),

          // Tags
          if (experience.tags.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: experience.tags.map((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withAlpha(20),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '#$tag',
                    style: TextStyle(color: AppColors.accent, fontSize: 11),
                  ),
                );
              }).toList(),
            ),
          ],

          // Footer
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.thumb_up_outlined,
                  size: 14, color: AppColors.functionalMuted),
              const SizedBox(width: 4),
              Text(
                '${experience.helpfulCount} užitečné',
                style: TextStyle(
                  color: AppColors.functionalMuted,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              Text(
                _formatDate(experience.createdAt),
                style: TextStyle(
                  color: AppColors.functionalMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) return 'Dnes';
    if (diff.inDays == 1) return 'Včera';
    if (diff.inDays < 7) return 'Před ${diff.inDays} dny';
    return '${date.day}.${date.month}.${date.year}';
  }
}
