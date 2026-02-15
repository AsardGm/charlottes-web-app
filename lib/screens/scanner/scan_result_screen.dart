import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/scan_result_model.dart';
import '../../providers/strain_provider.dart';
import '../../theme/theme.dart';

/// Obrazovka výsledku AI skenování
///
/// Zobrazuje identifikovanou odrůdu s edukativními informacemi.
class ScanResultScreen extends ConsumerWidget {
  final String scanId;

  const ScanResultScreen({super.key, required this.scanId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scanAsync = ref.watch(scanByIdProvider(scanId));

    return Scaffold(
      backgroundColor: AppColors.functionalBg,
      body: scanAsync.when(
        data: (scan) {
          if (scan == null) {
            return const Center(child: Text('Sken nenalezen'));
          }
          return _ScanResultContent(scan: scan);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Chyba: $e')),
      ),
    );
  }
}

class _ScanResultContent extends ConsumerStatefulWidget {
  final ScanResultModel scan;

  const _ScanResultContent({required this.scan});

  @override
  ConsumerState<_ScanResultContent> createState() => _ScanResultContentState();
}

class _ScanResultContentState extends ConsumerState<_ScanResultContent> {
  late bool _isFavorite;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.scan.isFavorite;
  }

  Future<void> _toggleFavorite() async {
    setState(() => _isFavorite = !_isFavorite);
    await ref
        .read(scanHistoryNotifierProvider.notifier)
        .toggleFavorite(widget.scan.id);
  }

  @override
  Widget build(BuildContext context) {
    final scan = widget.scan;

    return CustomScrollView(
      slivers: [
        // Header s obrázkem
        SliverAppBar(
          expandedHeight: 300,
          pinned: true,
          backgroundColor: AppColors.functionalBg,
          leading: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back, color: Colors.white),
            ),
            onPressed: () => context.go('/scanner'),
          ),
          actions: [
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: _isFavorite ? Colors.red : Colors.white,
                ),
              ),
              onPressed: _toggleFavorite,
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                // Obrázek
                CachedNetworkImage(
                  imageUrl: scan.imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, _) => Container(
                    color: AppColors.functionalSurface,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (_, _, _) => Container(
                    color: AppColors.functionalSurface,
                    child: const Icon(Icons.broken_image, size: 64),
                  ),
                ),
                // Gradient overlay
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        AppColors.functionalBg.withAlpha(200),
                        AppColors.functionalBg,
                      ],
                      stops: const [0.4, 0.8, 1.0],
                    ),
                  ),
                ),
                // Info overlay
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Type badge
                      if (scan.strainType != null)
                        _TypeBadge(type: scan.strainType!),
                      const SizedBox(height: 8),
                      // Název
                      Text(
                        scan.identified
                            ? (scan.strainName ?? 'Neznámá odrůda')
                            : 'Rostlina neidentifikována',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      // Confidence
                      if (scan.confidence != null)
                        Row(
                          children: [
                            Icon(Icons.analytics,
                                size: 16, color: AppColors.accent),
                            const SizedBox(width: 4),
                            Text(
                              'Jistota: ${scan.confidencePercent}',
                              style: TextStyle(
                                color: AppColors.accent,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Obsah
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Pokud není identifikováno
                if (!scan.identified) ...[
                  _InfoCard(
                    icon: Icons.info_outline,
                    iconColor: Colors.orange,
                    title: 'Nelze identifikovat',
                    child: Text(
                      scan.rawAiResponse?['general_info'] ??
                          'AI nemohla s jistotou identifikovat rostlinu na obrázku.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Charakteristiky
                if (scan.characteristics != null) ...[
                  _CharacteristicsSection(characteristics: scan.characteristics!),
                  const SizedBox(height: 16),
                ],

                // Edukativní informace
                if (scan.education != null) ...[
                  _EducationSection(education: scan.education!),
                  const SizedBox(height: 16),
                ],

                // Zdravotní stav
                if (scan.healthAssessment != null) ...[
                  _HealthSection(health: scan.healthAssessment!),
                  const SizedBox(height: 16),
                ],

                // Akční tlačítka
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          ref.read(scannerProvider.notifier).reset();
                          context.go('/scanner');
                        },
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Nový sken'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.accent,
                          side: BorderSide(color: AppColors.accent),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Badge pro typ odrůdy
class _TypeBadge extends StatelessWidget {
  final String type;

  const _TypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;

    switch (type.toLowerCase()) {
      case 'indica':
        bgColor = Colors.purple;
        textColor = Colors.white;
        break;
      case 'sativa':
        bgColor = Colors.green;
        textColor = Colors.white;
        break;
      case 'hybrid':
        bgColor = AppColors.accent;
        textColor = Colors.black;
        break;
      default:
        bgColor = AppColors.functionalSurface;
        textColor = AppColors.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        type.toUpperCase(),
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

/// Info karta
class _InfoCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final Widget child;

  const _InfoCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.functionalSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.functionalBorder),
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
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

/// Sekce charakteristik
class _CharacteristicsSection extends StatelessWidget {
  final ScanCharacteristics characteristics;

  const _CharacteristicsSection({required this.characteristics});

  @override
  Widget build(BuildContext context) {
    final items = <MapEntry<String, String?>>[];
    if (characteristics.leafShape != null) {
      items.add(MapEntry('Listy', characteristics.leafShape));
    }
    if (characteristics.structure != null) {
      items.add(MapEntry('Struktura', characteristics.structure));
    }
    if (characteristics.color != null) {
      items.add(MapEntry('Barva', characteristics.color));
    }
    if (characteristics.trichomes != null) {
      items.add(MapEntry('Trichomy', characteristics.trichomes));
    }
    if (characteristics.buds != null) {
      items.add(MapEntry('Květy', characteristics.buds));
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return _InfoCard(
      icon: Icons.eco,
      iconColor: Colors.green,
      title: 'Charakteristiky',
      child: Column(
        children: items.map((e) => _DetailRow(label: e.key, value: e.value!)).toList(),
      ),
    );
  }
}

/// Sekce edukace
class _EducationSection extends StatelessWidget {
  final ScanEducation education;

  const _EducationSection({required this.education});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Genetika a THC/CBD
        _InfoCard(
          icon: Icons.science,
          iconColor: AppColors.accent,
          title: 'Informace',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (education.genetics != null)
                _DetailRow(label: 'Genetika', value: education.genetics!),
              if (education.thcRange != null)
                _DetailRow(label: 'THC', value: education.thcRange!),
              if (education.cbdRange != null)
                _DetailRow(label: 'CBD', value: education.cbdRange!),
              if (education.floweringTime != null)
                _DetailRow(label: 'Doba květu', value: education.floweringTime!),
              if (education.growDifficulty != null)
                _DetailRow(label: 'Obtížnost', value: education.growDifficultyLocalized),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Efekty
        if (education.effects.isNotEmpty) ...[
          _InfoCard(
            icon: Icons.psychology,
            iconColor: Colors.purple,
            title: 'Účinky',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: education.effects
                  .map((e) => _Tag(text: e, color: Colors.purple))
                  .toList(),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Chutě
        if (education.flavors.isNotEmpty) ...[
          _InfoCard(
            icon: Icons.restaurant,
            iconColor: Colors.orange,
            title: 'Chutě a vůně',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: education.flavors
                  .map((e) => _Tag(text: e, color: Colors.orange))
                  .toList(),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Tipy
        if (education.tips.isNotEmpty) ...[
          _InfoCard(
            icon: Icons.lightbulb,
            iconColor: Colors.yellow.shade700,
            title: 'Tipy pro pěstování',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: education.tips
                  .map((tip) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.check_circle,
                                size: 16, color: Colors.green),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                tip,
                                style:
                                    TextStyle(color: AppColors.textSecondary),
                              ),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ),
        ],

        // Medicinální využití
        if (education.medicalUses != null) ...[
          const SizedBox(height: 16),
          _InfoCard(
            icon: Icons.medical_services,
            iconColor: Colors.red,
            title: 'Potenciální medicinální využití',
            child: Text(
              education.medicalUses!,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ],

        // Historie
        if (education.history != null) ...[
          const SizedBox(height: 16),
          _InfoCard(
            icon: Icons.history_edu,
            iconColor: AppColors.gold,
            title: 'Historie',
            child: Text(
              education.history!,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ],
      ],
    );
  }
}

/// Sekce zdraví rostliny
class _HealthSection extends StatelessWidget {
  final HealthAssessment health;

  const _HealthSection({required this.health});

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    IconData statusIcon;

    switch (health.status) {
      case 'healthy':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'warning':
        statusColor = Colors.orange;
        statusIcon = Icons.warning;
        break;
      case 'critical':
        statusColor = Colors.red;
        statusIcon = Icons.error;
        break;
      default:
        statusColor = AppColors.functionalMuted;
        statusIcon = Icons.help_outline;
    }

    return _InfoCard(
      icon: statusIcon,
      iconColor: statusColor,
      title: 'Zdravotní stav: ${health.statusLocalized}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Problémy
          if (health.issues.isNotEmpty) ...[
            const Text(
              'Zjištěné problémy:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            ...health.issues.map((issue) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber,
                          size: 16, color: Colors.orange),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          issue,
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 12),
          ],

          // Doporučení
          if (health.recommendations.isNotEmpty) ...[
            const Text(
              'Doporučení:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            ...health.recommendations.map((rec) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.tips_and_updates,
                          size: 16, color: AppColors.accent),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          rec,
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                )),
          ],

          // Pokud je zdravá bez problémů
          if (health.issues.isEmpty && health.recommendations.isEmpty)
            Row(
              children: [
                Icon(Icons.check, size: 16, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'Rostlina vypadá zdravě!',
                  style: TextStyle(color: Colors.green),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// Řádek s detailem
class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: AppColors.functionalMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tag/chip pro efekty a chutě
class _Tag extends StatelessWidget {
  final String text;
  final Color color;

  const _Tag({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(100)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
