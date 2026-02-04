import 'package:flutter/material.dart';
import '../../models/harm_reduction_guide.dart';
import '../../theme/theme.dart';

/// Safety Tips Widget - Shows contextual harm reduction tips
///
/// Can be used in consumption logging, profile, or anywhere
/// safety reminders are beneficial
class SafetyTipsWidget extends StatelessWidget {
  final String context; // 'before', 'during', 'after'
  final bool compact;

  const SafetyTipsWidget({
    super.key,
    this.context = 'before',
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final tips = HarmReductionTips.getTipsForContext(this.context);

    if (compact) {
      return _buildCompactView(tips);
    }

    return _buildFullView(tips);
  }

  Widget _buildFullView(List<String> tips) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A4A1A), Color(0xFF0D2A0D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF66BB6A).withValues(alpha:0.3),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF66BB6A).withValues(alpha:0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.shield,
                  color: Color(0xFF66BB6A),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                _getTitle(),
                style: const TextStyle(
                  color: Color(0xFF66BB6A),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...tips.map((tip) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Text(
                        '• ',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        tip,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildCompactView(List<String> tips) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF66BB6A).withValues(alpha:0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF66BB6A).withValues(alpha:0.3),
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline,
            color: Color(0xFF66BB6A),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              HarmReductionTips.getRandomTip(),
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getTitle() {
    switch (context) {
      case 'before':
        return 'Před konzumací - zkontroluj';
      case 'during':
        return 'Během - pamatuj';
      case 'after':
        return 'Po konzumaci';
      default:
        return 'Bezpečnostní tipy';
    }
  }
}

/// Harm Reduction Quick Card - Clickable card leading to full guide
class HarmReductionQuickCard extends StatelessWidget {
  final VoidCallback? onTap;

  const HarmReductionQuickCard({
    super.key,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2D6A2D), Color(0xFF1A4A1A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF81C784).withValues(alpha:0.3),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF81C784).withValues(alpha:0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.local_hospital,
                    color: Color(0xFF81C784),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Harm Reduction',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Průvodce bezpečnou konzumací',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Color(0xFF81C784),
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Dosage Recommendation Widget
class DosageRecommendationWidget extends StatelessWidget {
  final String method; // 'smoking', 'vaping', 'edibles'
  final String experience; // 'beginner', 'occasional', 'experienced'

  const DosageRecommendationWidget({
    super.key,
    required this.method,
    required this.experience,
  });

  @override
  Widget build(BuildContext context) {
    final recommendation = _getRecommendation();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.functionalSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF2196F3).withValues(alpha:0.3),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.science,
                color: const Color(0xFF2196F3),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Doporučená dávka',
                style: TextStyle(
                  color: Color(0xFF2196F3),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            recommendation,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFF9800).withValues(alpha:0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.warning_amber,
                  color: Color(0xFFFF9800),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _getWarning(),
                    style: const TextStyle(
                      color: Color(0xFFFF9800),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getRecommendation() {
    switch (method) {
      case 'smoking':
      case 'vaping':
        switch (experience) {
          case 'beginner':
            return '1-2 tahy, počkej 15 minut. Start low, go slow!';
          case 'occasional':
            return '2-3 tahy. Vyhodnoť účinek po 15 minutách.';
          case 'experienced':
            return '3-5 tahů podle tolerance. Respektuj své limity.';
          default:
            return 'Začni pomalu a postupně zvyšuj.';
        }
      case 'edibles':
        switch (experience) {
          case 'beginner':
            return '2.5-5mg THC. POČKEJ MINIMÁLNĚ 2 HODINY!';
          case 'occasional':
            return '5-10mg THC. Nespěchej, nástup trvá 30min-2h.';
          case 'experienced':
            return '10-20mg THC. Pamatuj: nelze vzít zpět.';
          default:
            return 'Start low, go slow. Edibles jsou silné!';
        }
      default:
        return 'Začni s nízkou dávkou a postupně zvyšuj pokud potřeba.';
    }
  }

  String _getWarning() {
    switch (method) {
      case 'edibles':
        return 'NIKDY nepřidávej dříve než za 2 hodiny!';
      case 'smoking':
        return 'Kouření poškozuje plíce. Zvažuj vaping.';
      case 'vaping':
        return 'Bezpečnější než kouření, ale stále zátěž pro plíce.';
      default:
        return 'Nelze vzít zpět, ale můžeš přidat. Buď trpělivý.';
    }
  }
}
