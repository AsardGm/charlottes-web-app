import 'package:flutter/material.dart';
import '../../../theme/theme.dart';

/// Widget pro vstupni pole zprav v chatu
class MessageInput extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isSending;
  final bool showEmojiPicker;
  final bool showGifPicker;
  final bool showAttachmentMenu;
  final bool isRecordingVoice;
  final VoidCallback onToggleEmojiPicker;
  final VoidCallback onToggleGifPicker;
  final VoidCallback onToggleAttachmentMenu;
  final VoidCallback onSendMessage;
  final VoidCallback onStartVoiceRecording;
  final VoidCallback onStopVoiceRecording;

  const MessageInput({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.isSending,
    required this.showEmojiPicker,
    required this.showGifPicker,
    required this.showAttachmentMenu,
    required this.isRecordingVoice,
    required this.onToggleEmojiPicker,
    required this.onToggleGifPicker,
    required this.onToggleAttachmentMenu,
    required this.onSendMessage,
    required this.onStartVoiceRecording,
    required this.onStopVoiceRecording,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Emoji button
            IconButton(
              icon: Icon(
                showEmojiPicker ? Icons.keyboard : Icons.emoji_emotions_outlined,
                color: showEmojiPicker ? AppColors.primary : AppColors.textMuted,
              ),
              onPressed: onToggleEmojiPicker,
              splashRadius: 20,
            ),
            // GIF button
            IconButton(
              icon: Icon(
                Icons.gif_box_outlined,
                color: showGifPicker ? AppColors.primary : AppColors.textMuted,
              ),
              onPressed: onToggleGifPicker,
              splashRadius: 20,
            ),
            // Attachment button
            IconButton(
              icon: Icon(
                showAttachmentMenu ? Icons.close : Icons.add_circle_outline,
                color: showAttachmentMenu ? AppColors.primary : AppColors.textMuted,
              ),
              onPressed: onToggleAttachmentMenu,
              splashRadius: 20,
            ),
            // Text field
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: InputDecoration(
                    hintText: 'Napsat zpravu...',
                    hintStyle: TextStyle(color: AppColors.textMuted),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => onSendMessage(),
                  onTap: () {
                    if (showEmojiPicker) {
                      onToggleEmojiPicker();
                    }
                  },
                  maxLines: 4,
                  minLines: 1,
                  style: TextStyle(color: AppColors.textPrimary),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Send/Voice button
            _buildSendButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildSendButton() {
    if (isSending) {
      return Container(
        width: 48,
        height: 48,
        padding: const EdgeInsets.all(12),
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppColors.primary,
        ),
      );
    }

    if (controller.text.isEmpty) {
      return GestureDetector(
        onLongPressStart: (_) => onStartVoiceRecording(),
        onLongPressEnd: (_) => onStopVoiceRecording(),
        child: Container(
          decoration: BoxDecoration(
            color: isRecordingVoice ? AppColors.error : AppColors.surfaceLight,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            onPressed: () {},
            icon: Icon(
              Icons.mic,
              color: isRecordingVoice ? Colors.white : AppColors.textMuted,
              size: 24,
            ),
            splashRadius: 24,
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withAlpha(200),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha(80),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        onPressed: onSendMessage,
        icon: const Icon(Icons.send, color: Colors.white, size: 20),
        splashRadius: 24,
      ),
    );
  }
}
