import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/theme.dart';
import '../../models/cognitive_test_model.dart';

/// Obrazovka s výsledky cognitive testu
class CognitiveResultsScreen extends StatelessWidget {
  final ReactionTimeResult reactionTime;
  final MemoryFlashResult memoryFlash;
  final PatternRecognitionResult patternRecognition;
  final int totalScore;
  final CognitiveStatus status;
  final int? baselineScore;

  const CognitiveResultsScreen({
    super.key,
    required this.reactionTime,
    required this.memoryFlash,
    required this.patternRecognition,
    required this.totalScore,
    required this.status,
    this.baselineScore,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.functionalBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Close button
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  onPressed: () => context.pop(),
                  icon: Icon(Icons.close, color: AppColors.textMuted),
                ),
              ),
              const SizedBox(height: 16),

              // Status icon
              _buildStatusIcon(),
              const SizedBox(height: 24),

              // Total score
              Text(
                'Tvůj Cognitive Score',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$totalScore/100',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 8),

              // Status label
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _getStatusColor().withAlpha(30),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _getStatusColor(),
                    width: 1.5,
                  ),
                ),
                child: Text(
                  status.label,
                  style: TextStyle(
                    color: _getStatusColor(),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Description
              Text(
                status.description,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                ),
                textAlign: TextAlign.center,
              ),

              // Baseline comparison
              if (baselineScore != null) ...[
                const SizedBox(height: 24),
                _buildBaselineComparison(),
              ],

              const SizedBox(height: 32),

              // Individual test results
              _buildTestResult(
                icon: Icons.flash_on,
                title: 'Reakce',
                score: reactionTime.score,
                detail: '${reactionTime.averageMs}ms průměr',
                color: AppColors.accent,
              ),
              const SizedBox(height: 12),
              _buildTestResult(
                icon: Icons.memory,
                title: 'Paměť',
                score: memoryFlash.score,
                detail: '${memoryFlash.correctAnswers}/${memoryFlash.totalAttempts} správně',
                color: const Color(0xFF4CAF50),
              ),
              const SizedBox(height: 12),
              _buildTestResult(
                icon: Icons.pattern,
                title: 'Vzory',
                score: patternRecognition.score,
                detail:
                    '${patternRecognition.correctAnswers}/${patternRecognition.totalAttempts} správně',
                color: const Color(0xFF9C27B0),
              ),

              const SizedBox(height: 32),

              // XP reward
              _buildXPReward(),

              const SizedBox(height: 32),

              // Action buttons
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => context.pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Hotovo',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.push('/cognitive/history'),
                child: Text(
                  'Zobrazit historii',
                  style: TextStyle(
                    color: AppColors.accent,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIcon() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            _getStatusColor().withAlpha(40),
            _getStatusColor().withAlpha(0),
          ],
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _getStatusColor().withAlpha(30),
          border: Border.all(
            color: _getStatusColor(),
            width: 3,
          ),
        ),
        child: Center(
          child: Text(
            _getStatusEmoji(),
            style: const TextStyle(fontSize: 48),
          ),
        ),
      ),
    );
  }

  Widget _buildBaselineComparison() {
    final diff = totalScore - baselineScore!;
    final diffText = diff >= 0 ? '+$diff%' : '$diff%';
    final isPositive = diff >= 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.functionalSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.functionalBorder,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isPositive ? Icons.trending_up : Icons.trending_down,
            color: isPositive ? AppColors.success : AppColors.error,
            size: 32,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tvůj baseline: $baselineScore',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Dnes: $diffText',
                  style: TextStyle(
                    color: isPositive ? AppColors.success : AppColors.error,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestResult({
    required IconData icon,
    required String title,
    required int score,
    required String detail,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.functionalSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.functionalBorder,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withAlpha(30),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  detail,
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$score',
                style: TextStyle(
                  color: color,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                '/100',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildXPReward() {
    // Calculate XP based on performance: base 25 + up to 75 bonus
    final xpReward = 25 + ((totalScore / 100.0) * 75).round();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.accent.withAlpha(30),
            AppColors.accent.withAlpha(15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.accent.withAlpha(80),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.accent.withAlpha(40),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.stars,
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
                  'Test dokončen!',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '+$xpReward XP',
                  style: TextStyle(
                    color: AppColors.accent,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    switch (status) {
      case CognitiveStatus.sharp:
        return const Color(0xFF4CAF50);
      case CognitiveStatus.normal:
        return AppColors.accent;
      case CognitiveStatus.tired:
        return const Color(0xFFFFA726);
      case CognitiveStatus.blurry:
        return const Color(0xFFFF9800);
      case CognitiveStatus.overloaded:
        return const Color(0xFFF44336);
    }
  }

  String _getStatusEmoji() {
    switch (status) {
      case CognitiveStatus.sharp:
        return '🔥';
      case CognitiveStatus.normal:
        return '✅';
      case CognitiveStatus.tired:
        return '😴';
      case CognitiveStatus.blurry:
        return '🌫️';
      case CognitiveStatus.overloaded:
        return '🔴';
    }
  }
}
