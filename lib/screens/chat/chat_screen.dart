import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../theme/theme.dart';
import '../../models/conversation_model.dart';
import '../../providers/chat_provider.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String conversationId;

  const ChatScreen({
    super.key,
    required this.conversationId,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSending = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    _messageController.clear();

    try {
      await ref.read(chatProvider.notifier).sendMessage(
            conversationId: widget.conversationId,
            content: content,
          );

      // Scroll dolů
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Chyba: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(messagesProvider(widget.conversationId));
    final currentUserId =
        ref.watch(chatProvider.notifier).chatService.currentUserId ?? '';

    // Listen to real-time messages
    ref.listen(messageStreamProvider(widget.conversationId), (_, next) {
      next.whenData((message) {
        // Refresh messages when new one arrives
        ref.invalidate(messagesProvider(widget.conversationId));
      });
    });

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            Icon(Icons.lock, size: 16, color: AppColors.success),
            const SizedBox(width: 8),
            const Text('Sifrovany chat'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showChatOptions(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Encryption notice
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppColors.success.withAlpha(20),
            child: Row(
              children: [
                Icon(Icons.verified_user, size: 16, color: AppColors.success),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Zpravy jsou end-to-end sifrovane',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.success,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Messages
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                if (messages.isEmpty) {
                  return Center(
                    child: Text(
                      'Zatim zadne zpravy',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == currentUserId;
                    final showAvatar = index == messages.length - 1 ||
                        messages[index + 1].senderId != message.senderId;

                    return _MessageBubble(
                      message: message,
                      isMe: isMe,
                      showAvatar: showAvatar,
                      onReaction: (emoji) {
                        ref.read(chatProvider.notifier).addReaction(
                              message.id,
                              emoji,
                              widget.conversationId,
                            );
                      },
                      onDelete: isMe
                          ? () {
                              ref.read(chatProvider.notifier).deleteMessage(
                                    message.id,
                                    widget.conversationId,
                                  );
                            }
                          : null,
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Text('Chyba: ${error.toString()}'),
              ),
            ),
          ),

          // Input
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(
            color: Colors.white.withAlpha(10),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.attach_file),
              onPressed: () {
                // TODO: Attach file
              },
            ),
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Napsat zpravu...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: AppColors.surfaceLight,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                maxLines: 4,
                minLines: 1,
              ),
            ),
            const SizedBox(width: 8),
            _isSending
                ? const SizedBox(
                    width: 48,
                    height: 48,
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton.filled(
                    onPressed: _sendMessage,
                    icon: const Icon(Icons.send),
                  ),
          ],
        ),
      ),
    );
  }

  void _showChatOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.timer),
              title: const Text('Mizici zpravy'),
              subtitle: const Text('Vypnuto'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Settings for disappearing messages
              },
            ),
            ListTile(
              leading: const Icon(Icons.volume_off),
              title: const Text('Ztlumit'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.block, color: AppColors.error),
              title: Text('Blokovat', style: TextStyle(color: AppColors.error)),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final bool showAvatar;
  final Function(String) onReaction;
  final VoidCallback? onDelete;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.showAvatar,
    required this.onReaction,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final content = message.isDeleted
        ? 'Zprava byla smazana'
        : (message.decryptedContent ?? '[Sifrovano]');

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe && showAvatar)
            CircleAvatar(
              radius: 16,
              backgroundImage: message.sender?.avatarUrl != null
                  ? NetworkImage(message.sender!.avatarUrl!)
                  : null,
              child: message.sender?.avatarUrl == null
                  ? Text(
                      message.sender?.username[0].toUpperCase() ?? '?',
                      style: const TextStyle(fontSize: 12),
                    )
                  : null,
            )
          else if (!isMe)
            const SizedBox(width: 32),
          const SizedBox(width: 8),
          Flexible(
            child: GestureDetector(
              onLongPress: () => _showMessageOptions(context),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isMe
                      ? AppColors.primary
                      : AppColors.surfaceLight,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isMe ? 16 : 4),
                    bottomRight: Radius.circular(isMe ? 4 : 16),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      content,
                      style: TextStyle(
                        color: isMe ? Colors.white : AppColors.textPrimary,
                        fontStyle: message.isDeleted
                            ? FontStyle.italic
                            : FontStyle.normal,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          timeago.format(message.createdAt, locale: 'cs'),
                          style: TextStyle(
                            fontSize: 10,
                            color: isMe
                                ? Colors.white.withAlpha(180)
                                : AppColors.textMuted,
                          ),
                        ),
                        if (message.isEdited) ...[
                          const SizedBox(width: 4),
                          Text(
                            '(upraveno)',
                            style: TextStyle(
                              fontSize: 10,
                              color: isMe
                                  ? Colors.white.withAlpha(180)
                                  : AppColors.textMuted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (isMe && showAvatar)
            const SizedBox(width: 32)
          else if (isMe)
            const SizedBox(width: 32),
        ],
      ),
    );
  }

  void _showMessageOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Reakce
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: ['❤️', '😂', '😮', '😢', '👍', '👎'].map((emoji) {
                  return GestureDetector(
                    onTap: () {
                      onReaction(emoji);
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(emoji, style: const TextStyle(fontSize: 24)),
                    ),
                  );
                }).toList(),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Kopirovat'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Copy to clipboard
              },
            ),
            ListTile(
              leading: const Icon(Icons.reply),
              title: const Text('Odpovedet'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Reply
              },
            ),
            if (onDelete != null)
              ListTile(
                leading: Icon(Icons.delete, color: AppColors.error),
                title: Text('Smazat', style: TextStyle(color: AppColors.error)),
                onTap: () {
                  Navigator.pop(context);
                  onDelete!();
                },
              ),
          ],
        ),
      ),
    );
  }
}
