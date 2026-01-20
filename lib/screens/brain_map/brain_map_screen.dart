import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/terpene_model.dart';
import '../../providers/terpene_provider.dart';
import '../../theme/theme.dart';
import 'terpene_detail_sheet.dart';

/// Interaktivní Terpene Brain Map
///
/// Zobrazuje mozek s klikatelnými oblastmi pro jednotlivé terpeny.
/// Kliknutím na terpen se zobrazí detail s informacemi.
class BrainMapScreen extends ConsumerWidget {
  const BrainMapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final terpenesAsync = ref.watch(terpenesProvider);
    final selectedTerpene = ref.watch(selectedTerpeneProvider);

    return Scaffold(
      backgroundColor: AppColors.functionalBg,
      appBar: AppBar(
        backgroundColor: AppColors.functionalBg,
        title: const Text('Terpene Brain Map'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showDisclaimer(context),
            tooltip: 'Důležité informace',
          ),
        ],
      ),
      body: Column(
        children: [
          // Disclaimer banner
          _DisclaimerBanner(),

          // Brain visualization
          Expanded(
            child: terpenesAsync.when(
              data: (terpenes) => _BrainVisualization(
                terpenes: terpenes,
                selectedTerpene: selectedTerpene,
                onTerpeneSelected: (terpene) {
                  ref.read(selectedTerpeneProvider.notifier).select(terpene);
                  _showTerpeneDetail(context, terpene);
                },
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Chyba: $e')),
            ),
          ),

          // Legenda
          _TerpeneLegend(
            terpenes: terpenesAsync.value ?? [],
            onTerpeneSelected: (terpene) {
              ref.read(selectedTerpeneProvider.notifier).select(terpene);
              _showTerpeneDetail(context, terpene);
            },
          ),
        ],
      ),
    );
  }

  void _showTerpeneDetail(BuildContext context, TerpeneModel terpene) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TerpeneDetailSheet(terpene: terpene),
    );
  }

  void _showDisclaimer(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.functionalSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.orange),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Důležité upozornění',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 18),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Tato sekce slouží pouze pro vzdělávací účely.',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '• Informace zde uvedené nejsou lékařskou radou\n'
                '• Nenahrazují konzultaci s odborníkem\n'
                '• Nenaváděme k užívání žádných látek\n'
                '• Účinky se mohou lišit u každého jedince\n'
                '• Respektujte zákony vaší země\n'
                '• Konzumace bez souhlasu je trestná',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              Text(
                'Komunitní zkušenosti jsou subjektivní a neměly by být brány jako doporučení.',
                style: TextStyle(
                  color: AppColors.functionalMuted,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Rozumím', style: TextStyle(color: AppColors.accent)),
          ),
        ],
      ),
    );
  }
}

/// Disclaimer banner nahoře
class _DisclaimerBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withAlpha(50)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.orange, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Pouze pro vzdělávací účely. Nenaváděme k užívání bez souhlasu.',
              style: TextStyle(color: Colors.orange.shade200, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

/// Interaktivní vizualizace mozku
class _BrainVisualization extends StatelessWidget {
  final List<TerpeneModel> terpenes;
  final TerpeneModel? selectedTerpene;
  final Function(TerpeneModel) onTerpeneSelected;

  const _BrainVisualization({
    required this.terpenes,
    this.selectedTerpene,
    required this.onTerpeneSelected,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final centerX = constraints.maxWidth / 2;
        final centerY = constraints.maxHeight / 2;
        final radius = constraints.maxWidth * 0.35;

        return Stack(
          children: [
            // Pozadí mozku
            Center(
              child: Container(
                width: radius * 2.2,
                height: radius * 2.2,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.accent.withAlpha(20),
                      AppColors.functionalBg,
                    ],
                  ),
                  border: Border.all(
                    color: AppColors.accent.withAlpha(30),
                    width: 2,
                  ),
                ),
                child: CustomPaint(
                  painter: _BrainPainter(),
                ),
              ),
            ),

            // Terpen body
            ...terpenes.asMap().entries.map((entry) {
              final index = entry.key;
              final terpene = entry.value;
              final angle = (index * 2 * math.pi / terpenes.length) - math.pi / 2;
              final x = centerX + radius * 0.8 * math.cos(angle);
              final y = centerY + radius * 0.8 * math.sin(angle);

              final isSelected = selectedTerpene?.id == terpene.id;
              final color = _parseColor(terpene.color);

              return Positioned(
                left: x - 30,
                top: y - 30,
                child: GestureDetector(
                  onTap: () => onTerpeneSelected(terpene),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: isSelected ? 70 : 60,
                    height: isSelected ? 70 : 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color.withAlpha(isSelected ? 200 : 150),
                      border: Border.all(
                        color: isSelected ? Colors.white : color,
                        width: isSelected ? 3 : 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: color.withAlpha(isSelected ? 150 : 80),
                          blurRadius: isSelected ? 20 : 10,
                          spreadRadius: isSelected ? 5 : 2,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        terpene.name.substring(0, 1),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isSelected ? 24 : 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),

            // Středový popis
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.psychology,
                    color: AppColors.accent.withAlpha(100),
                    size: 48,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Klikni na terpen',
                    style: TextStyle(
                      color: AppColors.functionalMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
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

/// Painter pro mozek
class _BrainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.accent.withAlpha(30)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;

    // Kruhové čáry
    for (var i = 1; i <= 3; i++) {
      canvas.drawCircle(center, radius * i / 3, paint);
    }

    // Radiální čáry
    for (var i = 0; i < 8; i++) {
      final angle = i * math.pi / 4;
      final dx = radius * math.cos(angle);
      final dy = radius * math.sin(angle);
      canvas.drawLine(center, Offset(center.dx + dx, center.dy + dy), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Legenda terpenů
class _TerpeneLegend extends StatelessWidget {
  final List<TerpeneModel> terpenes;
  final Function(TerpeneModel) onTerpeneSelected;

  const _TerpeneLegend({
    required this.terpenes,
    required this.onTerpeneSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.functionalSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Terpeny',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: terpenes.map((terpene) {
              final color = _parseColor(terpene.color);
              return GestureDetector(
                onTap: () => onTerpeneSelected(terpene),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withAlpha(30),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.withAlpha(100)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        terpene.name,
                        style: TextStyle(color: color, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
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
