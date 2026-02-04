import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/theme.dart';
import '../../services/strain_journal_service.dart';
import '../../models/strain_journal_model.dart';
import '../../widgets/common/shimmer_loading.dart';
import 'package:intl/intl.dart';

/// Strain Journal Entry Detail Screen
class EntryDetailScreen extends ConsumerStatefulWidget {
  final String entryId;

  const EntryDetailScreen({super.key, required this.entryId});

  @override
  ConsumerState<EntryDetailScreen> createState() => _EntryDetailScreenState();
}

class _EntryDetailScreenState extends ConsumerState<EntryDetailScreen> {
  final _journalService = StrainJournalService();

  bool _isLoading = true;
  StrainJournalEntry? _entry;

  @override
  void initState() {
    super.initState();
    _loadEntry();
  }

  Future<void> _loadEntry() async {
    setState(() => _isLoading = true);

    try {
      final entry = await _journalService.getJournalEntry(widget.entryId);

      setState(() {
        _entry = entry;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading entry: $e')),
        );
      }
    }
  }

  Future<void> _toggleFavorite() async {
    if (_entry == null) return;

    try {
      await _journalService.toggleFavorite(_entry!.id, !_entry!.isFavorite);
      setState(() {
        _entry = StrainJournalEntry(
          id: _entry!.id,
          userId: _entry!.userId,
          strainId: _entry!.strainId,
          strainName: _entry!.strainName,
          consumptionLogId: _entry!.consumptionLogId,
          consumedAt: _entry!.consumedAt,
          method: _entry!.method,
          amount: _entry!.amount,
          amountUnit: _entry!.amountUnit,
          setting: _entry!.setting,
          activities: _entry!.activities,
          moodBefore: _entry!.moodBefore,
          intention: _entry!.intention,
          physicalEffects: _entry!.physicalEffects,
          mentalEffects: _entry!.mentalEffects,
          emotionalEffects: _entry!.emotionalEffects,
          onsetTime: _entry!.onsetTime,
          peakTime: _entry!.peakTime,
          totalDuration: _entry!.totalDuration,
          overallRating: _entry!.overallRating,
          wouldUseAgain: _entry!.wouldUseAgain,
          title: _entry!.title,
          notes: _entry!.notes,
          highlights: _entry!.highlights,
          drawbacks: _entry!.drawbacks,
          tags: _entry!.tags,
          photos: _entry!.photos,
          aiSummary: _entry!.aiSummary,
          aiRecommendations: _entry!.aiRecommendations,
          aiAnalyzedAt: _entry!.aiAnalyzedAt,
          isFavorite: !_entry!.isFavorite,
          isPrivate: _entry!.isPrivate,
          createdAt: _entry!.createdAt,
          updatedAt: _entry!.updatedAt,
        );
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error toggling favorite: $e')),
        );
      }
    }
  }

  Future<void> _deleteEntry() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete Entry?',
            style: TextStyle(color: Colors.white)),
        content: const Text(
          'This action cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await _journalService.deleteJournalEntry(widget.entryId);
        if (mounted) {
          context.pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting entry: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_entry?.displayTitle ?? 'Journal Entry'),
        backgroundColor: AppColors.surface,
        actions: [
          if (_entry != null) ...[
            IconButton(
              icon: Icon(
                _entry!.isFavorite ? Icons.favorite : Icons.favorite_border,
                color: _entry!.isFavorite ? AppColors.accent : null,
              ),
              onPressed: _toggleFavorite,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _deleteEntry,
            ),
          ],
        ],
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _entry == null
              ? _buildErrorState()
              : _buildContent(),
    );
  }

  Widget _buildLoadingState() {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          ShimmerCard(height: 200),
          SizedBox(height: 16),
          ShimmerCard(height: 150),
          SizedBox(height: 16),
          ShimmerCard(height: 150),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline,
                size: 64, color: AppColors.textMuted.withValues(alpha:0.5)),
            const SizedBox(height: 16),
            const Text(
              'Entry Not Found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This journal entry could not be loaded',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final dateFormat = DateFormat('EEEE, MMM d, yyyy • h:mm a');

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header Card
        _buildSection(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha:0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.local_florist,
                    color: AppColors.accent,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _entry!.strainName ?? 'Unknown Strain',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dateFormat.format(_entry!.consumedAt),
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_entry!.title != null) ...[
              const SizedBox(height: 16),
              Text(
                _entry!.title!,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
            if (_entry!.overallRating != null) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.star, color: AppColors.success, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    '${_entry!.overallRating!.toStringAsFixed(1)} / 10',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.success,
                    ),
                  ),
                  const Spacer(),
                  if (_entry!.wouldUseAgain != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _entry!.wouldUseAgain!
                            ? AppColors.success.withValues(alpha:0.2)
                            : AppColors.error.withValues(alpha:0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _entry!.wouldUseAgain!
                                ? Icons.thumb_up
                                : Icons.thumb_down,
                            size: 16,
                            color: _entry!.wouldUseAgain!
                                ? AppColors.success
                                : AppColors.error,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _entry!.wouldUseAgain!
                                ? 'Would use again'
                                : 'Would not use again',
                            style: TextStyle(
                              fontSize: 12,
                              color: _entry!.wouldUseAgain!
                                  ? AppColors.success
                                  : AppColors.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),

        // Basic Info
        if (_entry!.method != null ||
            _entry!.amount != null ||
            _entry!.setting.isNotEmpty ||
            _entry!.activities.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildInfoSection(),
        ],

        // AI Analysis
        if (_entry!.hasAIAnalysis) ...[
          const SizedBox(height: 16),
          _buildAIAnalysisSection(),
        ],

        // Physical Effects
        if (_entry!.physicalEffects.hasAnyRating) ...[
          const SizedBox(height: 16),
          _buildPhysicalEffectsSection(),
        ],

        // Mental Effects
        if (_entry!.mentalEffects.hasAnyRating) ...[
          const SizedBox(height: 16),
          _buildMentalEffectsSection(),
        ],

        // Emotional Effects
        if (_entry!.emotionalEffects.hasAnyRating) ...[
          const SizedBox(height: 16),
          _buildEmotionalEffectsSection(),
        ],

        // Duration
        if (_entry!.onsetTime != null ||
            _entry!.peakTime != null ||
            _entry!.totalDuration != null) ...[
          const SizedBox(height: 16),
          _buildDurationSection(),
        ],

        // Notes
        if (_entry!.notes != null) ...[
          const SizedBox(height: 16),
          _buildNotesSection(),
        ],

        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildSection({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildInfoSection() {
    return _buildSection(
      children: [
        Row(
          children: [
            Icon(Icons.info_outline, color: AppColors.accent, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Details',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_entry!.method != null)
          _buildInfoRow('Method', _entry!.method!, Icons.smoking_rooms),
        if (_entry!.amount != null)
          _buildInfoRow(
            'Amount',
            '${_entry!.amount} ${_entry!.amountUnit ?? ''}',
            Icons.scale,
          ),
        if (_entry!.setting.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildChipRow('Setting', _entry!.setting),
        ],
        if (_entry!.activities.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildChipRow('Activities', _entry!.activities),
        ],
        if (_entry!.moodBefore != null) ...[
          const SizedBox(height: 12),
          _buildInfoRow(
            'Mood Before',
            '${_entry!.moodBefore}/10',
            Icons.sentiment_satisfied,
          ),
        ],
        if (_entry!.intention != null) ...[
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.emoji_objects, color: AppColors.textMuted, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Intention',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                    Text(
                      _entry!.intention!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildAIAnalysisSection() {
    return _buildSection(
      children: [
        Row(
          children: [
            Icon(Icons.psychology, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Charlotte AI Analysis',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha:0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            _entry!.aiSummary!,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.primary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        if (_entry!.aiRecommendations.isNotEmpty) ...[
          const SizedBox(height: 12),
          ..._entry!.aiRecommendations.map((rec) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(_getRecommendationIcon(rec.type),
                        color: AppColors.accent, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        rec.message,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ],
    );
  }

  Widget _buildPhysicalEffectsSection() {
    return _buildSection(
      children: [
        Row(
          children: [
            Icon(Icons.fitness_center, color: AppColors.accent, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Physical Effects',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_entry!.physicalEffects.bodyHigh != null)
          _buildEffectBar('Body High', _entry!.physicalEffects.bodyHigh!),
        if (_entry!.physicalEffects.energyLevel != null)
          _buildEffectBar('Energy', _entry!.physicalEffects.energyLevel!),
        if (_entry!.physicalEffects.physicalRelaxation != null)
          _buildEffectBar('Relaxation',
              _entry!.physicalEffects.physicalRelaxation!),
        if (_entry!.physicalEffects.appetite != null)
          _buildEffectBar('Appetite', _entry!.physicalEffects.appetite!),
        if (_entry!.physicalEffects.painRelief != null)
          _buildEffectBar('Pain Relief', _entry!.physicalEffects.painRelief!),
        if (_entry!.physicalEffects.sleepiness != null)
          _buildEffectBar('Sleepiness', _entry!.physicalEffects.sleepiness!),
        if (_entry!.physicalEffects.dryMouth != null)
          _buildEffectBar('Dry Mouth', _entry!.physicalEffects.dryMouth!),
        if (_entry!.physicalEffects.redEyes != null)
          _buildEffectBar('Red Eyes', _entry!.physicalEffects.redEyes!),
      ],
    );
  }

  Widget _buildMentalEffectsSection() {
    return _buildSection(
      children: [
        Row(
          children: [
            Icon(Icons.psychology, color: AppColors.accent, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Mental Effects',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_entry!.mentalEffects.headHigh != null)
          _buildEffectBar('Head High', _entry!.mentalEffects.headHigh!),
        if (_entry!.mentalEffects.focus != null)
          _buildEffectBar('Focus', _entry!.mentalEffects.focus!),
        if (_entry!.mentalEffects.creativity != null)
          _buildEffectBar('Creativity', _entry!.mentalEffects.creativity!),
        if (_entry!.mentalEffects.euphoria != null)
          _buildEffectBar('Euphoria', _entry!.mentalEffects.euphoria!),
        if (_entry!.mentalEffects.mentalClarity != null)
          _buildEffectBar(
              'Mental Clarity', _entry!.mentalEffects.mentalClarity!),
        if (_entry!.mentalEffects.memoryImpact != null)
          _buildEffectBar(
              'Memory Impact', _entry!.mentalEffects.memoryImpact!),
        if (_entry!.mentalEffects.paranoia != null)
          _buildEffectBar('Paranoia', _entry!.mentalEffects.paranoia!),
      ],
    );
  }

  Widget _buildEmotionalEffectsSection() {
    return _buildSection(
      children: [
        Row(
          children: [
            Icon(Icons.mood, color: AppColors.accent, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Emotional Effects',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_entry!.emotionalEffects.happiness != null)
          _buildEffectBar('Happiness', _entry!.emotionalEffects.happiness!),
        if (_entry!.emotionalEffects.anxietyRelief != null)
          _buildEffectBar(
              'Anxiety Relief', _entry!.emotionalEffects.anxietyRelief!),
        if (_entry!.emotionalEffects.stressRelief != null)
          _buildEffectBar(
              'Stress Relief', _entry!.emotionalEffects.stressRelief!),
        if (_entry!.emotionalEffects.sociability != null)
          _buildEffectBar('Sociability', _entry!.emotionalEffects.sociability!),
        if (_entry!.emotionalEffects.introspection != null)
          _buildEffectBar(
              'Introspection', _entry!.emotionalEffects.introspection!),
      ],
    );
  }

  Widget _buildDurationSection() {
    return _buildSection(
      children: [
        Row(
          children: [
            Icon(Icons.timer, color: AppColors.accent, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Duration',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_entry!.onsetTime != null)
          _buildInfoRow(
              'Onset', '${_entry!.onsetTime} min', Icons.play_arrow),
        if (_entry!.peakTime != null)
          _buildInfoRow('Peak', '${_entry!.peakTime} min', Icons.trending_up),
        if (_entry!.totalDuration != null)
          _buildInfoRow(
              'Total', '${_entry!.totalDuration} min', Icons.access_time),
      ],
    );
  }

  Widget _buildNotesSection() {
    return _buildSection(
      children: [
        Row(
          children: [
            Icon(Icons.notes, color: AppColors.accent, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Notes',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          _entry!.notes!,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.white70,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textMuted, size: 20),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: TextStyle(fontSize: 14, color: AppColors.textMuted),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChipRow(String label, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label:',
          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: items
              .map((item) => Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.functionalBorder,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      item,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildEffectBar(String label, int value) {
    final percentage = value / 10;
    Color color;
    if (value >= 7) {
      color = AppColors.success;
    } else if (value >= 4) {
      color = AppColors.accent;
    } else {
      color = AppColors.textMuted;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 14, color: Colors.white70),
              ),
              Text(
                '$value/10',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: AppColors.functionalBorder,
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getRecommendationIcon(String type) {
    switch (type) {
      case 'timing':
        return Icons.schedule;
      case 'activity':
        return Icons.directions_run;
      case 'wellbeing':
        return Icons.favorite;
      case 'caution':
        return Icons.warning;
      default:
        return Icons.lightbulb;
    }
  }
}
