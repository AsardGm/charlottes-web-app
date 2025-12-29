import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../theme/theme.dart';
import '../../../providers/chat_provider.dart';

/// Dialog pro výběr konverzace kam přeposlat zprávu
class ForwardMessageDialog extends ConsumerStatefulWidget {
  final String messageId;
  final String currentConversationId;

  const ForwardMessageDialog({
    super.key,
    required this.messageId,
    required this.currentConversationId,
  });

  @override
  ConsumerState<ForwardMessageDialog> createState() =>
      _ForwardMessageDialogState();
}

class _ForwardMessageDialogState extends ConsumerState<ForwardMessageDialog> {
  String? _selectedConversationId;
  bool _isForwarding = false;

  Future<void> _forward() async {
    if (_selectedConversationId == null) return;

    setState(() => _isForwarding = true);

    try {
      final chatService = ref.read(chatServiceProvider);
      await chatService.forwardMessage(
        messageId: widget.messageId,
        toConversationId: _selectedConversationId!,
      );

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Zprava preposlana')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Chyba: ${e.toString()}')),
        );
        setState(() => _isForwarding = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final conversationsAsync = ref.watch(conversationsProvider);
    final currentUserId =
        ref.read(chatServiceProvider).currentUserId ?? '';

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 320,
        constraints: const BoxConstraints(maxHeight: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.forward, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Preposlat do',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Conversations list
            Expanded(
              child: conversationsAsync.when(
                data: (conversations) {
                  // Filter out current conversation
                  final filtered = conversations
                      .where((c) => c.id != widget.currentConversationId)
                      .toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Text(
                        'Zadne konverzace',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final conv = filtered[index];
                      final isSelected = _selectedConversationId == conv.id;
                      final displayName = conv.getDisplayName(currentUserId);
                      final avatarUrl = conv.getDisplayAvatar(currentUserId);

                      return ListTile(
                        onTap: () =>
                            setState(() => _selectedConversationId = conv.id),
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primary.withAlpha(40),
                          backgroundImage:
                              avatarUrl != null ? NetworkImage(avatarUrl) : null,
                          child: avatarUrl == null
                              ? Text(
                                  displayName.isNotEmpty
                                      ? displayName[0].toUpperCase()
                                      : '?',
                                  style: TextStyle(color: AppColors.primary),
                                )
                              : null,
                        ),
                        title: Text(
                          displayName,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                        subtitle: conv.type == 'group'
                            ? Text(
                                '${conv.participants.length} clenu',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textMuted,
                                ),
                              )
                            : null,
                        trailing: isSelected
                            ? Icon(Icons.check_circle, color: AppColors.primary)
                            : Icon(Icons.circle_outlined,
                                color: AppColors.textMuted),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) => Center(
                  child: Text(
                    'Chyba pri nacitani',
                    style: TextStyle(color: AppColors.error),
                  ),
                ),
              ),
            ),
            const Divider(height: 1),
            // Actions
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Zrusit',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _selectedConversationId != null && !_isForwarding
                        ? _forward
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isForwarding
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Preposlat'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
