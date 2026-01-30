import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/lab/lab_diagnostic_model.dart';
import '../../../providers/lab_provider.dart';
import '../../../theme/theme.dart';

/// Vysledek AI diagnostiky
class OciResultScreen extends ConsumerWidget {
  final String growId;
  final String diagnosticId;

  const OciResultScreen({
    super.key,
    required this.growId,
    required this.diagnosticId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final diagnostics = ref.watch(labDiagnosticsProvider(growId));

    return Scaffold(
      backgroundColor: AppColors.functionalBg,
      body: Column(
        children: [
          // Custom header with gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.surface,
                  AppColors.surfaceLight,
                ],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.functionalSurface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.functionalBorder,
                          width: 1,
                        ),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'OCI ARASAKY',
                      style: TextStyle(
                        color: AppColors.rarityExotic,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: diagnostics.when(
              data: (list) {
                final diagnostic = list.where((d) => d.id == diagnosticId).firstOrNull;
                if (diagnostic == null) {
                  return Center(
                    child: Text(
                      'Diagnostika nenalezena',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  );
                }
                return _buildResult(diagnostic);
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.accent),
              ),
              error: (e, _) => Center(
                child: Text('Chyba: $e', style: TextStyle(color: AppColors.error)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResult(LabDiagnosticModel diagnostic) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Obrazek s gradient overlay a badge
        Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  Image.network(
                    diagnostic.imageUrl,
                    height: 250,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      height: 250,
                      color: AppColors.functionalSurface,
                      child: const Center(
                        child: Icon(Icons.broken_image, color: Colors.grey, size: 48),
                      ),
                    ),
                  ),
                  // Gradient overlay at bottom
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            AppColors.functionalBg.withAlpha(200),
                            AppColors.functionalBg,
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Diagnostic type badge overlay
            Positioned(
              bottom: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.rarityExotic.withAlpha(40),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.rarityExotic,
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.rarityExotic.withAlpha(60),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Text(
                  '${diagnostic.diagnosticType.icon} ${diagnostic.diagnosticType.label}',
                  style: TextStyle(
                    color: AppColors.rarityExotic,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Severity + Confidence circular indicator
        Row(
          children: [
            if (diagnostic.severity != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: _severityColor(diagnostic.severity!).withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _severityColor(diagnostic.severity!).withAlpha(100),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _severityColor(diagnostic.severity!).withAlpha(40),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Text(
                  diagnostic.severity!.label,
                  style: TextStyle(
                    color: _severityColor(diagnostic.severity!),
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            const Spacer(),
            if (diagnostic.confidence != null)
              SizedBox(
                width: 56,
                height: 56,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 56,
                      height: 56,
                      child: CircularProgressIndicator(
                        value: diagnostic.confidence! / 100,
                        strokeWidth: 5,
                        backgroundColor: AppColors.functionalSurface,
                        color: AppColors.accent,
                      ),
                    ),
                    Text(
                      '${diagnostic.confidence!.toStringAsFixed(0)}%',
                      style: TextStyle(
                        color: AppColors.accent,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 24),

        // Decorative divider
        Container(
          height: 2,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                AppColors.accent.withAlpha(100),
                Colors.transparent,
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Diagnoza with accent line
        if (diagnostic.diagnosis != null) ...[
          Text(
            'DIAGNOZA',
            style: TextStyle(
              color: AppColors.accent,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 4,
                height: null,
                constraints: const BoxConstraints(minHeight: 60),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.accent,
                      AppColors.accent.withAlpha(50),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.functionalSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.functionalBorder,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    diagnostic.diagnosis!,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      height: 1.6,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Decorative divider
          Container(
            height: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  AppColors.success.withAlpha(80),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],

        // Doporuceni s cisly
        if (diagnostic.recommendations.isNotEmpty) ...[
          Text(
            'DOPORUCENI',
            style: TextStyle(
              color: AppColors.accent,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 12),
          ...diagnostic.recommendations.asMap().entries.map((entry) {
            final index = entry.key;
            final rec = entry.value;
            final isEven = index % 2 == 0;

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isEven
                    ? AppColors.functionalSurface
                    : AppColors.functionalSurface.withAlpha(150),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.success.withAlpha(60),
                  width: 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.success,
                          AppColors.success.withAlpha(180),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.success.withAlpha(60),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: AppColors.functionalBg,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      rec,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }

  Color _severityColor(DiagnosticSeverity severity) {
    switch (severity) {
      case DiagnosticSeverity.low:
        return AppColors.success;
      case DiagnosticSeverity.medium:
        return AppColors.warning;
      case DiagnosticSeverity.high:
        return AppColors.primary;
      case DiagnosticSeverity.critical:
        return AppColors.error;
    }
  }
}
