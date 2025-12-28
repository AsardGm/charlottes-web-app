import 'package:flutter/material.dart';
import '../utils/constants.dart';

class ReactionBar extends StatelessWidget {
  final Map<String, int> reactionCounts;
  final String? userReaction;
  final Function(String type) onReact;
  final VoidCallback onRemoveReaction;

  const ReactionBar({
    super.key,
    required this.reactionCounts,
    this.userReaction,
    required this.onReact,
    required this.onRemoveReaction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Quick like button
        _QuickReactionButton(
          isActive: userReaction == 'like',
          onTap: () {
            if (userReaction == 'like') {
              onRemoveReaction();
            } else {
              onReact('like');
            }
          },
          onLongPress: () => _showReactionPicker(context),
        ),
        const SizedBox(width: 8),
        // Display reaction counts
        if (reactionCounts.isNotEmpty) ...[
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: reactionCounts.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: userReaction == entry.key
                            ? Theme.of(context).primaryColor.withAlpha(51)
                            : Colors.grey.withAlpha(25),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            AppConstants.reactionEmojis[entry.key] ?? '',
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            entry.value.toString(),
                            style: TextStyle(
                              fontSize: 12,
                              color: userReaction == entry.key
                                  ? Theme.of(context).primaryColor
                                  : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ] else
          const Spacer(),
      ],
    );
  }

  void _showReactionPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: AppConstants.reactionEmojis.entries.map((entry) {
            return GestureDetector(
              onTap: () {
                Navigator.pop(context);
                if (userReaction == entry.key) {
                  onRemoveReaction();
                } else {
                  onReact(entry.key);
                }
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: userReaction == entry.key
                      ? Theme.of(context).primaryColor.withAlpha(51)
                      : null,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  entry.value,
                  style: const TextStyle(fontSize: 28),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _QuickReactionButton extends StatelessWidget {
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _QuickReactionButton({
    required this.isActive,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? Theme.of(context).primaryColor.withAlpha(51)
              : Colors.grey.withAlpha(25),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? Icons.thumb_up : Icons.thumb_up_outlined,
              size: 18,
              color: isActive
                  ? Theme.of(context).primaryColor
                  : Colors.grey[600],
            ),
            const SizedBox(width: 4),
            Text(
              'To se mi libi',
              style: TextStyle(
                fontSize: 12,
                color: isActive
                    ? Theme.of(context).primaryColor
                    : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
