import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../theme/theme.dart';
import '../../../models/conversation_model.dart';
import 'voice_message_inline.dart';
import 'location_message_widget.dart';
import 'file_message_widget.dart';
import 'formatted_text_widget.dart';

/// Widget pro zobrazeni zpravy v chatu
class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final bool showAvatar;
  final Function(String) onReaction;
  final VoidCallback onReply;
  final VoidCallback? onDelete;
  final VoidCallback? onForward;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.showAvatar,
    required this.onReaction,
    required this.onReply,
    this.onDelete,
    this.onForward,
  });

  /// Zjistí, zda byla zpráva přečtena příjemcem
  bool get _isRead => message.receipts.any((r) => r.isRead);

  /// Zjistí, zda byla zpráva doručena
  bool get _isDelivered => message.receipts.isNotEmpty;

  /// Vytvoří ikonu pro stav doručení/přečtení
  Widget _buildReadReceiptIcon(bool isImage) {
    final Color color;
    final IconData icon;

    if (_isRead) {
      color = isImage ? AppColors.primary : const Color(0xFF4CAF50);
      icon = Icons.done_all;
    } else if (_isDelivered) {
      color = isImage ? AppColors.textMuted : Colors.white.withAlpha(180);
      icon = Icons.done_all;
    } else {
      color = isImage ? AppColors.textMuted : Colors.white.withAlpha(180);
      icon = Icons.done;
    }

    return Icon(icon, size: 14, color: color);
  }

  @override
  Widget build(BuildContext context) {
    final content = message.isDeleted
        ? 'Zprava byla smazana'
        : (message.decryptedContent ?? 'Nova zprava');

    final messageType = message.messageType;
    final isImage = messageType == 'image';
    final isVoice = messageType == 'voice';
    final isLocation = messageType == 'location';
    final isFile = messageType == 'file';
    final isPoll = messageType == 'poll';
    final isSpecialType = isImage || isVoice || isLocation || isFile || isPoll;

    // Pro obrázek extrahuj URL (může obsahovat |caption)
    String? imageUrl;
    String? caption;
    if (isImage && !message.isDeleted) {
      final parts = content.split('|');
      imageUrl = parts[0];
      caption = parts.length > 1 ? parts[1] : null;
    }

    return Padding(
      padding: EdgeInsets.only(
        bottom: showAvatar ? 12 : 3,
        left: isMe ? 48 : 0,
        right: isMe ? 0 : 48,
      ),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe && showAvatar)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primary.withAlpha(40),
                backgroundImage: message.sender?.avatarUrl != null
                    ? NetworkImage(message.sender!.avatarUrl!)
                    : null,
                child: message.sender?.avatarUrl == null
                    ? Text(
                        message.sender?.username[0].toUpperCase() ?? '?',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
            )
          else if (!isMe)
            const SizedBox(width: 40),
          Flexible(
            child: GestureDetector(
              onLongPress: () => _showMessageOptions(context),
              onTap: isImage && imageUrl != null
                  ? () => _showFullImage(context, imageUrl!)
                  : null,
              child: Container(
                padding: isSpecialType
                    ? const EdgeInsets.all(4)
                    : const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: isMe && !isSpecialType
                      ? LinearGradient(
                          colors: [
                            AppColors.primary,
                            AppColors.primary.withAlpha(220),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: isMe ? (isSpecialType ? AppColors.primary.withAlpha(40) : null) : AppColors.surfaceLight,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(20),
                    topRight: const Radius.circular(20),
                    bottomLeft: Radius.circular(isMe ? 20 : 6),
                    bottomRight: Radius.circular(isMe ? 6 : 20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(15),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment:
                      isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    // Render based on message type
                    _buildMessageContent(context, content, isImage, isVoice, isLocation, isFile, imageUrl),
                    // Popisek obrázku
                    if (caption != null && caption.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          caption,
                          style: TextStyle(
                            color: isMe ? Colors.white : AppColors.textPrimary,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    _buildTimestamp(isImage),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageContent(
    BuildContext context,
    String content,
    bool isImage,
    bool isVoice,
    bool isLocation,
    bool isFile,
    String? imageUrl,
  ) {
    if (message.isDeleted) {
      return Text(
        content,
        style: TextStyle(
          color: isMe ? Colors.white : AppColors.textPrimary,
          fontSize: 15,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    if (isImage && imageUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(
          imageUrl,
          width: 200,
          height: 200,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return Container(
              width: 200,
              height: 200,
              color: AppColors.surfaceLight,
              child: Center(
                child: CircularProgressIndicator(
                  value: progress.expectedTotalBytes != null
                      ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                      : null,
                  strokeWidth: 2,
                ),
              ),
            );
          },
          errorBuilder: (context, error, stack) {
            return Container(
              width: 200,
              height: 200,
              color: AppColors.surfaceLight,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.broken_image, color: AppColors.textMuted),
                  const SizedBox(height: 8),
                  Text('Nelze nacist', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                ],
              ),
            );
          },
        ),
      );
    }

    if (isVoice) {
      return VoiceMessageInline(
        voiceUrl: content.split('|')[0],
        durationSeconds: int.tryParse(content.split('|').length > 1 ? content.split('|')[1] : '0') ?? 0,
        isMe: isMe,
      );
    }

    if (isLocation) {
      return LocationMessageWidget(
        latitude: double.tryParse(content.split(',')[0]) ?? 0,
        longitude: double.tryParse(content.split(',').length > 1 ? content.split(',')[1] : '0') ?? 0,
        isMe: isMe,
      );
    }

    if (isFile) {
      return FileMessageWidget(
        fileUrl: content.split('|')[0],
        fileName: content.split('|').length > 1 ? content.split('|')[1] : 'soubor',
        fileSize: int.tryParse(content.split('|').length > 2 ? content.split('|')[2] : '0') ?? 0,
        mimeType: content.split('|').length > 3 ? content.split('|')[3] : 'application/octet-stream',
        isMe: isMe,
      );
    }

    return FormattedTextWidget(
      text: content,
      isMe: isMe,
    );
  }

  Widget _buildTimestamp(bool isImage) {
    return Padding(
      padding: isImage ? const EdgeInsets.symmetric(horizontal: 8) : EdgeInsets.zero,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isMe) ...[
            _buildReadReceiptIcon(isImage),
            const SizedBox(width: 4),
          ],
          Text(
            timeago.format(message.createdAt, locale: 'cs'),
            style: TextStyle(
              fontSize: 11,
              color: isMe && !isImage
                  ? Colors.white.withAlpha(180)
                  : AppColors.textMuted,
            ),
          ),
          if (message.isEdited) ...[
            const SizedBox(width: 4),
            Text(
              '· upraveno',
              style: TextStyle(
                fontSize: 11,
                color: isMe && !isImage
                    ? Colors.white.withAlpha(180)
                    : AppColors.textMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showFullImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            InteractiveViewer(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
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
                Clipboard.setData(ClipboardData(text: message.decryptedContent ?? ''));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Zkopirovano do schranky')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.reply),
              title: const Text('Odpovedet'),
              onTap: () {
                Navigator.pop(context);
                onReply();
              },
            ),
            if (onForward != null)
              ListTile(
                leading: const Icon(Icons.forward),
                title: const Text('Preposlat'),
                onTap: () {
                  Navigator.pop(context);
                  onForward!();
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
