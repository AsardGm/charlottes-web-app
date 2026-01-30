import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../models/lab/lab_diagnostic_model.dart';
import '../../../providers/lab_provider.dart';
import '../../../theme/theme.dart';

/// Oci Arasaky - AI diagnosticky skener
class OciScannerScreen extends ConsumerStatefulWidget {
  final String growId;

  const OciScannerScreen({super.key, required this.growId});

  @override
  ConsumerState<OciScannerScreen> createState() => _OciScannerScreenState();
}

class _OciScannerScreenState extends ConsumerState<OciScannerScreen> {
  DiagnosticType _selectedType = DiagnosticType.health;
  bool _isAnalyzing = false;

  Future<void> _pickAndAnalyze() async {
    final service = ref.read(labServiceProvider);
    final aiService = ref.read(labAiServiceProvider);
    final image = await service.pickImageFromGallery();
    if (image == null) return;

    setState(() => _isAnalyzing = true);

    try {
      // Nacti bytes pro AI analyzu
      final imageBytes = await image.readAsBytes();

      // Upload image do storage
      final imageUrl = await service.uploadImage(image, subfolder: 'diagnostics');

      final userId = service.currentUserId;
      if (userId == null) return;

      // AI analyza pres Gemini Vision
      String diagnosis = 'AI analyza selhala';
      DiagnosticSeverity? severity;
      List<String> recommendations = [];
      double confidence = 0;
      Map<String, dynamic>? aiResponse;

      try {
        final rawResponse = await aiService.analyzeImage(
          imageBytes: imageBytes,
          diagnosticType: _selectedType,
        );
        final result = aiService.parseResponse(rawResponse);
        diagnosis = result.diagnosis;
        severity = result.severity;
        recommendations = result.recommendations;
        confidence = result.confidence;
        aiResponse = result.rawResponse;
      } catch (aiError) {
        // AI selhala, ulozime diagnostic i bez AI vysledku
        // ignore: avoid_print
        print('[OciScanner] AI chyba: $aiError');
        diagnosis = 'AI analyza nedostupna: $aiError';
      }

      final diagnostic = LabDiagnosticModel(
        id: '',
        growId: widget.growId,
        userId: userId,
        diagnosticType: _selectedType,
        imageUrl: imageUrl,
        aiResponse: aiResponse,
        severity: severity,
        diagnosis: diagnosis,
        recommendations: recommendations,
        confidence: confidence,
        createdAt: DateTime.now(),
      );

      final saved = await service.saveDiagnostic(diagnostic);

      if (mounted) {
        ref.invalidate(labDiagnosticsProvider(widget.growId));
        context.push('/lab/oci/${widget.growId}/result/${saved.id}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Chyba: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final diagnostics = ref.watch(labDiagnosticsProvider(widget.growId));

    return Scaffold(
      backgroundColor: AppColors.functionalBg,
      appBar: AppBar(
        title: const Text('Oci Arasaky'),
        backgroundColor: AppColors.surface,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF6B1A6E),
                  const Color(0xFF2A0D2A),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.remove_red_eye,
                  color: AppColors.rarityExotic,
                  size: 48,
                ),
                const SizedBox(height: 12),
                Text(
                  'AI DIAGNOSTIKA',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Vyber typ analyzy a nahraj fotku',
                  style: TextStyle(
                    color: Colors.white.withAlpha(180),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Typ analyzy
          Text(
            'TYP ANALYZY',
            style: TextStyle(
              color: AppColors.accent,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 12),

          ...DiagnosticType.values.map((type) {
            final isSelected = _selectedType == type;
            return GestureDetector(
              onTap: () => setState(() => _selectedType = type),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.rarityExotic.withAlpha(20)
                      : AppColors.functionalSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.rarityExotic
                        : AppColors.functionalBorder,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Text(type.icon, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            type.label,
                            style: TextStyle(
                              color: isSelected
                                  ? AppColors.rarityExotic
                                  : AppColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Icon(Icons.check_circle,
                          color: AppColors.rarityExotic, size: 22),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 20),

          // Analyze button
          SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _isAnalyzing ? null : _pickAndAnalyze,
              icon: _isAnalyzing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : const Icon(Icons.camera_alt),
              label: Text(
                _isAnalyzing ? 'ANALYZUJI...' : 'NAHRAT FOTKU A ANALYZOVAT',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.rarityExotic,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Historie diagnostik
          Text(
            'HISTORIE',
            style: TextStyle(
              color: AppColors.accent,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 12),

          diagnostics.when(
            data: (list) {
              if (list.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.functionalSurface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      'Zadne diagnostiky',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  ),
                );
              }
              return Column(
                children: list.map((d) => _DiagnosticCard(diagnostic: d)).toList(),
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            ),
            error: (e, _) => Text('Chyba: $e',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _DiagnosticCard extends StatelessWidget {
  final LabDiagnosticModel diagnostic;

  const _DiagnosticCard({required this.diagnostic});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.functionalSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.functionalBorder, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push(
              '/lab/oci/${diagnostic.growId}/result/${diagnostic.id}'),
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    diagnostic.imageUrl,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      width: 50,
                      height: 50,
                      color: AppColors.functionalBg,
                      child: const Icon(Icons.image, color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${diagnostic.diagnosticType.icon} ${diagnostic.diagnosticType.label}',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (diagnostic.diagnosis != null)
                        Text(
                          diagnostic.diagnosis!,
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right,
                    color: AppColors.functionalMuted, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
