import 'package:flutter/material.dart';
import '../../models/daily_quest_model.dart';
import '../../theme/theme.dart';

/// Widget pro zobrazeni denniho questu
class DailyQuestCard extends StatelessWidget {
  final DailyQuest quest;
  final VoidCallback? onTap;

  const DailyQuestCard({
    super.key,
    required this.quest,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = quest.isCompleted;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isCompleted
              ? AppColors.success.withAlpha(20)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isCompleted
                ? AppColors.success.withAlpha(50)
                : AppColors.surfaceLight,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Icon / Checkbox
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted
                    ? AppColors.success
                    : AppColors.surfaceLight,
              ),
              child: Icon(
                isCompleted ? Icons.check : _getQuestIcon(),
                color: isCompleted ? Colors.white : AppColors.textMuted,
                size: 24,
              ),
            ),

            const SizedBox(width: 16),

            // Quest info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    quest.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isCompleted
                          ? AppColors.success
                          : AppColors.textPrimary,
                      decoration: isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    quest.description,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Progress bar
                  if (!isCompleted) ...[
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: quest.progress,
                              backgroundColor: AppColors.surfaceLight,
                              valueColor: AlwaysStoppedAnimation(
                                AppColors.primary,
                              ),
                              minHeight: 6,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${quest.currentProgress}/${quest.targetCount}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(width: 12),

            // XP reward
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isCompleted
                    ? AppColors.success.withAlpha(30)
                    : AppColors.primary.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.star,
                    size: 14,
                    color: isCompleted ? AppColors.success : AppColors.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '+${quest.xpReward}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isCompleted ? AppColors.success : AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getQuestIcon() {
    switch (quest.type) {
      case QuestType.like:
        return Icons.favorite_outline;
      case QuestType.comment:
        return Icons.chat_bubble_outline;
      case QuestType.uploadPhoto:
        return Icons.camera_alt_outlined;
      case QuestType.rateStrain:
        return Icons.star_outline;
      case QuestType.sharePost:
        return Icons.share_outlined;
      case QuestType.visitProfile:
        return Icons.person_outline;
      case QuestType.sendMessage:
        return Icons.message_outlined;
      case QuestType.collectCard:
        return Icons.style_outlined;
      case QuestType.contestEntry:
        return Icons.emoji_events_outlined;
    }
  }
}

/// Widget pro seznam dennich questu
class DailyQuestsSection extends StatelessWidget {
  final List<DailyQuest> quests;
  final Function(DailyQuest)? onQuestTap;

  const DailyQuestsSection({
    super.key,
    required this.quests,
    this.onQuestTap,
  });

  @override
  Widget build(BuildContext context) {
    final completedCount = quests.where((q) => q.isCompleted).length;
    final totalXp = quests.map((q) => q.xpReward).reduce((a, b) => a + b);
    final earnedXp = quests
        .where((q) => q.isCompleted)
        .map((q) => q.xpReward)
        .fold(0, (a, b) => a + b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.task_alt,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Denni ukoly',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: completedCount == quests.length
                    ? AppColors.success.withAlpha(20)
                    : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$completedCount/${quests.length}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: completedCount == quests.length
                      ? AppColors.success
                      : AppColors.textMuted,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // Overall progress
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: quests.isEmpty ? 0 : completedCount / quests.length,
                  backgroundColor: AppColors.surfaceLight,
                  valueColor: AlwaysStoppedAnimation(
                    completedCount == quests.length
                        ? AppColors.success
                        : AppColors.primary,
                  ),
                  minHeight: 8,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '$earnedXp/$totalXp XP',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Quest list
        ...quests.map((quest) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: DailyQuestCard(
                quest: quest,
                onTap: onQuestTap != null ? () => onQuestTap!(quest) : null,
              ),
            )),
      ],
    );
  }
}
