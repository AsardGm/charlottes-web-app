import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../theme/theme.dart';
import '../../../models/conversation_model.dart';
import '../../../providers/chat_provider.dart';

/// Widget pro zobrazení připnutých zpráv v horní liště
class PinnedMessagesBar extends ConsumerStatefulWidget {
  final String conversationId;
  final Function(MessageModel) onTap;

  const PinnedMessagesBar({
    super.key,
    required this.conversationId,
    required this.onTap,
  });

  @override
  ConsumerState<PinnedMessagesBar> createState() => _PinnedMessagesBarState();
}

class _PinnedMessagesBarState extends ConsumerState<PinnedMessagesBar> {
  List<MessageModel> _pinnedMessages = [];
  int _currentIndex = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPinnedMessages();
  }

  Future<void> _loadPinnedMessages() async {
    try {
      final chatService = ref.read(chatServiceProvider);
      final messages = await chatService.getPinnedMessages(widget.conversationId);
      if (mounted) {
        setState(() {
          _pinnedMessages = messages;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _nextMessage() {
    if (_pinnedMessages.length > 1) {
      setState(() {
        _currentIndex = (_currentIndex + 1) % _pinnedMessages.length;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _pinnedMessages.isEmpty) {
      return const SizedBox.shrink();
    }

    final message = _pinnedMessages[_currentIndex];
    final content = message.decryptedContent ?? 'Pripnuta zprava';

    return GestureDetector(
      onTap: () => widget.onTap(message),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primary.withAlpha(20),
          border: Border(
            bottom: BorderSide(color: AppColors.surfaceLight, width: 1),
          ),
        ),
        child: Row(
          children: [
            // Pin icon
            Icon(Icons.push_pin, size: 16, color: AppColors.primary),
            const SizedBox(width: 8),
            // Message content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(
                        message.sender?.username ?? 'Uzivatel',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                      if (_pinnedMessages.length > 1) ...[
                        const Spacer(),
                        Text(
                          '${_currentIndex + 1}/${_pinnedMessages.length}',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    content,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Navigate if multiple
            if (_pinnedMessages.length > 1)
              IconButton(
                onPressed: _nextMessage,
                icon: Icon(
                  Icons.keyboard_arrow_down,
                  color: AppColors.textMuted,
                  size: 20,
                ),
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(4),
              ),
          ],
        ),
      ),
    );
  }
}

/// Sheet pro zobrazení všech připnutých zpráv
class PinnedMessagesSheet extends ConsumerStatefulWidget {
  final String conversationId;
  final ScrollController scrollController;

  const PinnedMessagesSheet({
    super.key,
    required this.conversationId,
    required this.scrollController,
  });

  @override
  ConsumerState<PinnedMessagesSheet> createState() => _PinnedMessagesSheetState();
}

class _PinnedMessagesSheetState extends ConsumerState<PinnedMessagesSheet> {
  List<MessageModel> _pinnedMessages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPinnedMessages();
  }

  Future<void> _loadPinnedMessages() async {
    try {
      final chatService = ref.read(chatServiceProvider);
      final messages = await chatService.getPinnedMessages(widget.conversationId);
      if (mounted) {
        setState(() {
          _pinnedMessages = messages;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _unpinMessage(MessageModel message) async {
    try {
      final chatService = ref.read(chatServiceProvider);
      await chatService.unpinMessage(widget.conversationId, message.id);
      await _loadPinnedMessages();
    } catch (_) {
      // Ignore errors
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Handle
        Container(
          margin: const EdgeInsets.only(top: 12),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.textMuted,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        // Header
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.push_pin, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'Pripnute zpravy',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                '${_pinnedMessages.length}',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // List
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _pinnedMessages.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.push_pin_outlined,
                            size: 48,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Zadne pripnute zpravy',
                            style: TextStyle(color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: widget.scrollController,
                      itemCount: _pinnedMessages.length,
                      itemBuilder: (context, index) {
                        final message = _pinnedMessages[index];
                        return _buildPinnedMessageTile(message);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildPinnedMessageTile(MessageModel message) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppColors.primary.withAlpha(40),
        backgroundImage: message.sender?.avatarUrl != null
            ? NetworkImage(message.sender!.avatarUrl!)
            : null,
        child: message.sender?.avatarUrl == null
            ? Text(
                message.sender?.username[0].toUpperCase() ?? '?',
                style: TextStyle(color: AppColors.primary),
              )
            : null,
      ),
      title: Text(
        message.decryptedContent ?? '',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${message.sender?.username ?? 'Uzivatel'} • ${timeago.format(message.createdAt, locale: 'cs')}',
        style: TextStyle(
          fontSize: 12,
          color: AppColors.textMuted,
        ),
      ),
      trailing: IconButton(
        onPressed: () => _unpinMessage(message),
        icon: Icon(Icons.push_pin_outlined, color: AppColors.textMuted),
        tooltip: 'Odepnout',
      ),
    );
  }
}
