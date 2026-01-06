import 'package:flutter/material.dart';
import '../theme/theme.dart';
import '../services/report_service.dart';

/// Dialog pro nahlaseni obsahu
class ReportDialog extends StatefulWidget {
  final ReportContentType contentType;
  final String contentId;
  final String? contentPreview;

  const ReportDialog({
    super.key,
    required this.contentType,
    required this.contentId,
    this.contentPreview,
  });

  /// Zobrazi dialog pro nahlaseni
  static Future<bool?> show({
    required BuildContext context,
    required ReportContentType contentType,
    required String contentId,
    String? contentPreview,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => ReportDialog(
        contentType: contentType,
        contentId: contentId,
        contentPreview: contentPreview,
      ),
    );
  }

  @override
  State<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<ReportDialog> {
  final _reportService = ReportService();
  final _descriptionController = TextEditingController();

  ReportReason? _selectedReason;
  bool _isSubmitting = false;

  String get _contentTypeName {
    switch (widget.contentType) {
      case ReportContentType.post:
        return 'prispevek';
      case ReportContentType.comment:
        return 'komentar';
      case ReportContentType.user:
        return 'uzivatele';
      case ReportContentType.message:
        return 'zpravu';
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedReason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Vyber duvod nahlaseni'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await _reportService.createReport(
        contentType: widget.contentType,
        contentId: widget.contentId,
        reason: _selectedReason!,
        description: _descriptionController.text.isNotEmpty
            ? _descriptionController.text
            : null,
      );

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                const Text('Nahlaseni bylo odeslano'),
              ],
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        String errorMessage = 'Chyba pri odesilani';
        if (e.toString().contains('duplicate') || e.toString().contains('unique')) {
          errorMessage = 'Tento obsah jsi uz nahlasil/a';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(Icons.flag, color: AppColors.error),
                  const SizedBox(width: 12),
                  Text(
                    'Nahlasit $_contentTypeName',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              Text(
                'Vyber duvod, proc chces tento obsah nahlasit.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textMuted,
                ),
              ),

              // Preview obsahu
              if (widget.contentPreview != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.textMuted.withAlpha(30)),
                  ),
                  child: Text(
                    widget.contentPreview!,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // Duvody
              Text(
                'Duvod nahlaseni',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: 12),

              ...ReportReason.values.map((reason) => _ReasonTile(
                    reason: reason,
                    isSelected: _selectedReason == reason,
                    onTap: () => setState(() => _selectedReason = reason),
                  )),

              const SizedBox(height: 16),

              // Popis
              Text(
                'Dalsi podrobnosti (volitelne)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: 8),

              TextField(
                controller: _descriptionController,
                maxLines: 3,
                maxLength: 500,
                decoration: InputDecoration(
                  hintText: 'Popiš problem podrobneji...',
                  hintStyle: TextStyle(color: AppColors.textMuted),
                  filled: true,
                  fillColor: AppColors.surfaceLight,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  counterStyle: TextStyle(color: AppColors.textMuted),
                ),
                style: TextStyle(color: AppColors.textPrimary),
              ),

              const SizedBox(height: 20),

              // Tlacitka
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                      child: Text(
                        'Zrusit',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Odeslat'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tile pro vyber duvodu
class _ReasonTile extends StatelessWidget {
  final ReportReason reason;
  final bool isSelected;
  final VoidCallback onTap;

  const _ReasonTile({
    required this.reason,
    required this.isSelected,
    required this.onTap,
  });

  IconData get _icon {
    switch (reason) {
      case ReportReason.spam:
        return Icons.report_gmailerrorred;
      case ReportReason.harassment:
        return Icons.person_off;
      case ReportReason.hateSpeech:
        return Icons.sentiment_very_dissatisfied;
      case ReportReason.violence:
        return Icons.dangerous;
      case ReportReason.nudity:
        return Icons.no_adult_content;
      case ReportReason.falseInformation:
        return Icons.fact_check;
      case ReportReason.scam:
        return Icons.warning_amber;
      case ReportReason.selfHarm:
        return Icons.healing;
      case ReportReason.other:
        return Icons.more_horiz;
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.error.withAlpha(20)
              : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.error : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              _icon,
              size: 20,
              color: isSelected ? AppColors.error : AppColors.textMuted,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                reason.displayName,
                style: TextStyle(
                  fontSize: 14,
                  color: isSelected ? AppColors.error : AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                size: 20,
                color: AppColors.error,
              ),
          ],
        ),
      ),
    );
  }
}
