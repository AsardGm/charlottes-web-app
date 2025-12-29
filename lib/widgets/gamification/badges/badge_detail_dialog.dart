import 'package:flutter/material.dart' hide Badge;
import '../../../models/badge_model.dart';
import '../../../theme/theme.dart';

/// Dialog pro detail odznaku
class BadgeDetailDialog extends StatelessWidget {
  final Badge badge;
  final bool isEarned;
  final DateTime? earnedAt;
  final bool isFeatured;
  final VoidCallback? onToggleFeatured;

  const BadgeDetailDialog({
    super.key,
    required this.badge,
    this.isEarned = false,
    this.earnedAt,
    this.isFeatured = false,
    this.onToggleFeatured,
  });

  static Future<void> show(
    BuildContext context,
    Badge badge, {
    bool isEarned = false,
    DateTime? earnedAt,
    bool isFeatured = false,
    VoidCallback? onToggleFeatured,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => BadgeDetailDialog(
        badge: badge,
        isEarned: isEarned,
        earnedAt: earnedAt,
        isFeatured: isFeatured,
        onToggleFeatured: onToggleFeatured,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textMuted.withAlpha(50),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          const SizedBox(height: 24),

          // Badge icon s animaci
          _AnimatedBadgeIcon(
            badge: badge,
            isEarned: isEarned,
          ),

          const SizedBox(height: 20),

          // Rarity chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: badge.rarity.gradientColors,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              badge.rarity.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Name
          Text(
            isEarned || !badge.isSecret ? badge.name : '???',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 8),

          // Category
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                badge.category.icon,
                size: 16,
                color: badge.category.color,
              ),
              const SizedBox(width: 6),
              Text(
                badge.category.name,
                style: TextStyle(
                  fontSize: 14,
                  color: badge.category.color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Description
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              isEarned || !badge.isSecret
                  ? badge.description
                  : 'Tento odznak je tajny. Najdi zpusob jak ho odemknout!',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 20),

          // XP reward
          if (badge.xpReward > 0 && (isEarned || !badge.isSecret))
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.stars,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '+${badge.xpReward} XP',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),

          // Earned date
          if (isEarned && earnedAt != null) ...[
            const SizedBox(height: 16),
            Text(
              'Ziskano: ${_formatDate(earnedAt!)}',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
              ),
            ),
          ],

          // Requirement hint
          if (!isEarned && badge.requirement != null && !badge.isSecret) ...[
            const SizedBox(height: 16),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.textMuted.withAlpha(30),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 18,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _getRequirementHint(badge.requirement!),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Actions
          if (isEarned && onToggleFeatured != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    onToggleFeatured!();
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isFeatured
                        ? AppColors.textMuted.withAlpha(30)
                        : Colors.amber,
                    foregroundColor: isFeatured
                        ? AppColors.textSecondary
                        : Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: Icon(
                    isFeatured ? Icons.star_outline : Icons.star,
                    size: 20,
                  ),
                  label: Text(
                    isFeatured ? 'Odebrat z profilu' : 'Zobrazit v profilu',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),

          SizedBox(height: MediaQuery.of(context).padding.bottom + 24),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }

  String _getRequirementHint(BadgeRequirement requirement) {
    final typeLabels = {
      'posts': 'prispevku',
      'xp': 'XP',
      'photos': 'fotek',
      'followers': 'sledujicich',
      'cards': 'karet',
      'reviews': 'hodnoceni',
      'days': 'dnu clenstvi',
      'webs': 'vlaken',
    };

    final label = typeLabels[requirement.type] ?? requirement.type;
    return 'Potrebujes: ${requirement.targetValue} $label';
  }
}

/// Animovana ikona odznaku
class _AnimatedBadgeIcon extends StatefulWidget {
  final Badge badge;
  final bool isEarned;

  const _AnimatedBadgeIcon({
    required this.badge,
    required this.isEarned,
  });

  @override
  State<_AnimatedBadgeIcon> createState() => _AnimatedBadgeIconState();
}

class _AnimatedBadgeIconState extends State<_AnimatedBadgeIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _glowAnimation = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.isEarned) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isEarned) {
      return _buildIcon(1.0, 0.0);
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => _buildIcon(
        _scaleAnimation.value,
        _glowAnimation.value,
      ),
    );
  }

  Widget _buildIcon(double scale, double glow) {
    return Transform.scale(
      scale: scale,
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: widget.isEarned
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: widget.badge.rarity.gradientColors,
                )
              : null,
          color: widget.isEarned ? null : AppColors.surface,
          border: Border.all(
            color: widget.isEarned
                ? widget.badge.rarity.color
                : AppColors.textMuted.withAlpha(50),
            width: 3,
          ),
          boxShadow: widget.isEarned
              ? [
                  BoxShadow(
                    color: widget.badge.rarity.color.withAlpha((glow * 150).toInt()),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            widget.badge.emoji,
            style: TextStyle(
              fontSize: 50,
              color: widget.isEarned
                  ? null
                  : AppColors.textMuted.withAlpha(100),
            ),
          ),
        ),
      ),
    );
  }
}
