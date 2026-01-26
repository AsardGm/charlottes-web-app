import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/api_config.dart';
import '../../providers/strain_provider.dart';
import '../../theme/theme.dart';

/// Hlavní obrazovka skeneru rostlin
///
/// Umožňuje uživateli vyfotit nebo vybrat obrázek
/// a odeslat ho na AI analýzu.
class ScannerScreen extends ConsumerWidget {
  const ScannerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scannerState = ref.watch(scannerProvider);
    final historyCount = ref.watch(scanCountProvider);

    return Scaffold(
      backgroundColor: AppColors.functionalBg,
      appBar: AppBar(
        backgroundColor: AppColors.functionalBg,
        title: const Text('AI Skener'),
        actions: [
          // Tlačítko historie
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.history),
                onPressed: () => context.push('/scanner/history'),
                tooltip: 'Historie skenů',
              ),
              // Badge s počtem
              historyCount.when(
                data: (count) => count > 0
                    ? Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            count > 99 ? '99+' : count.toString(),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Kontrola API klíče
            if (!ApiConfig.hasOpenAiKey)
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withAlpha(100)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber, color: Colors.orange),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'AI skener není nakonfigurován. Kontaktujte správce.',
                        style: TextStyle(color: Colors.orange.shade200),
                      ),
                    ),
                  ],
                ),
              ),

            // Hlavní obsah
            Expanded(
              child: _buildContent(context, ref, scannerState),
            ),

            // Spodní akční tlačítka
            if (!scannerState.isLoading)
              _buildActionButtons(context, ref, scannerState),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
      BuildContext context, WidgetRef ref, ScannerState state) {
    // Error state
    if (state.hasError) {
      return _buildErrorState(context, ref, state);
    }

    // Loading/Analyzing state
    if (state.isLoading) {
      return _buildLoadingState(state);
    }

    // Vybraný obrázek
    if (state.selectedImage != null) {
      return _buildImagePreview(context, ref, state);
    }

    // Prázdný stav
    return _buildEmptyState(context, ref);
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Ikona
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.accent.withAlpha(20),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.accent.withAlpha(50),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.document_scanner_outlined,
                size: 60,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(height: 32),

            // Nadpis
            const Text(
              'AI Skener Rostlin',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),

            // Popis
            Text(
              'Vyfoť nebo vyber obrázek rostliny a získej edukativní informace o odrůdě, pěstování a dalších vlastnostech.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.functionalMuted,
              ),
            ),
            const SizedBox(height: 48),

            // Tlačítka
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Kamera - přímý přechod na camera screen
                _ActionButton(
                  icon: Icons.camera_alt,
                  label: 'Vyfotit',
                  onTap: () => context.push('/scanner/camera'),
                ),
                const SizedBox(width: 24),
                // Galerie
                _ActionButton(
                  icon: Icons.photo_library,
                  label: 'Galerie',
                  onTap: () =>
                      ref.read(scannerProvider.notifier).pickFromGallery(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview(
      BuildContext context, WidgetRef ref, ScannerState state) {
    return Column(
      children: [
        // Obrázek
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(100),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(
                File(state.selectedImage!.path),
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),

        // Instrukce
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Obrázek připraven k analýze',
            style: TextStyle(
              color: AppColors.functionalMuted,
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildLoadingState(ScannerState state) {
    String message;
    switch (state.state) {
      case ScanState.pickingImage:
        message = 'Vybírám obrázek...';
        break;
      case ScanState.uploading:
        message = 'Nahrávám obrázek...';
        break;
      case ScanState.analyzing:
        message = 'AI analyzuje rostlinu...';
        break;
      default:
        message = 'Zpracovávám...';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animovaný progress
            SizedBox(
              width: 120,
              height: 120,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Vnější kruh
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: CircularProgressIndicator(
                      value: state.progress,
                      strokeWidth: 4,
                      backgroundColor: AppColors.functionalBorder,
                      valueColor: AlwaysStoppedAnimation(AppColors.accent),
                    ),
                  ),
                  // Ikona
                  Icon(
                    state.state == ScanState.analyzing
                        ? Icons.psychology
                        : Icons.cloud_upload,
                    size: 48,
                    color: AppColors.accent,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Text
            Text(
              message,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),

            // Progress procenta
            Text(
              '${(state.progress * 100).toInt()}%',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.functionalMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(
      BuildContext context, WidgetRef ref, ScannerState state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Ikona
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.error.withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                size: 40,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 24),

            // Nadpis
            const Text(
              'Něco se pokazilo',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),

            // Chybová zpráva
            Text(
              state.errorMessage ?? 'Neznámá chyba',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.functionalMuted,
              ),
            ),
            const SizedBox(height: 32),

            // Tlačítko zkusit znovu
            ElevatedButton.icon(
              onPressed: () => ref.read(scannerProvider.notifier).reset(),
              icon: const Icon(Icons.refresh),
              label: const Text('Zkusit znovu'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.black,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(
      BuildContext context, WidgetRef ref, ScannerState state) {
    // Pokud je vybraný obrázek
    if (state.selectedImage != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.functionalSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              // Zrušit
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () =>
                      ref.read(scannerProvider.notifier).clearImage(),
                  icon: const Icon(Icons.close),
                  label: const Text('Zrušit'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: BorderSide(color: AppColors.functionalBorder),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Skenovat
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: ApiConfig.hasOpenAiKey
                      ? () async {
                          await ref.read(scannerProvider.notifier).scan();
                          // Navigovat na výsledek pokud úspěšné
                          final newState = ref.read(scannerProvider);
                          if (newState.hasResult && context.mounted) {
                            context.push(
                                '/scanner/result/${newState.result!.id}');
                          }
                        }
                      : null,
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('Analyzovat'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.black,
                    disabledBackgroundColor: AppColors.functionalBorder,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

/// Akční tlačítko pro výběr obrázku
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 100,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.functionalSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.functionalBorder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.accent.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.accent),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
