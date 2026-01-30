import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../../theme/theme.dart';
import '../../models/conversation_model.dart';
import '../../providers/chat_provider.dart';
import '../../services/voice_service.dart';
import 'widgets/widgets.dart';

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
  final _focusNode = FocusNode();
  final VoiceService _voiceService = VoiceService();
  bool _isSending = false;
  bool _showEmojiPicker = false;
  bool _showGifPicker = false;
  bool _showAttachmentMenu = false;
  bool _isRecordingVoice = false;
  MessageModel? _replyingTo;
  Timer? _typingTimer;

  @override
  void initState() {
    super.initState();
    _messageController.addListener(_onTextChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatProvider.notifier).markConversationAsRead(widget.conversationId);
    });
  }

  @override
  void dispose() {
    _messageController.removeListener(_onTextChanged);
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _typingTimer?.cancel();
    _voiceService.dispose();
    ref.read(chatServiceProvider).setTyping(widget.conversationId, false);
    super.dispose();
  }

  void _onTextChanged() {
    if (_typingTimer?.isActive != true) {
      ref.read(chatServiceProvider).setTyping(widget.conversationId, true);
      _typingTimer = Timer(const Duration(seconds: 2), () {
        if (_messageController.text.isEmpty) {
          ref.read(chatServiceProvider).setTyping(widget.conversationId, false);
        }
      });
    }
  }

  void _onEmojiSelected(String emoji) {
    _messageController.text += emoji;
    _messageController.selection = TextSelection.fromPosition(
      TextPosition(offset: _messageController.text.length),
    );
  }

  void _toggleEmojiPicker() {
    if (_showEmojiPicker) {
      _focusNode.requestFocus();
    } else {
      _focusNode.unfocus();
    }
    setState(() {
      _showEmojiPicker = !_showEmojiPicker;
      _showGifPicker = false;
      _showAttachmentMenu = false;
    });
  }

  void _toggleGifPicker() {
    setState(() {
      _showGifPicker = !_showGifPicker;
      _showEmojiPicker = false;
      _showAttachmentMenu = false;
    });
    if (!_showGifPicker) {
      _focusNode.requestFocus();
    } else {
      _focusNode.unfocus();
    }
  }

  void _toggleAttachmentMenu() {
    setState(() {
      _showAttachmentMenu = !_showAttachmentMenu;
      _showEmojiPicker = false;
      _showGifPicker = false;
    });
  }

  // ============================================
  // VOICE MESSAGE
  // ============================================

  Future<void> _startVoiceRecording() async {
    final hasPermission = await _voiceService.hasPermission();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Povolte pristup k mikrofonu')),
        );
      }
      return;
    }

    await _voiceService.startRecording();
    setState(() => _isRecordingVoice = true);
  }

  Future<void> _stopRecordingAndSend() async {
    if (!_isRecordingVoice) return;
    final path = await _voiceService.stopRecording();
    if (path != null) {
      await _stopAndSendVoiceMessage(path);
    } else {
      setState(() => _isRecordingVoice = false);
    }
  }

  Future<void> _stopAndSendVoiceMessage(String path) async {
    setState(() {
      _isRecordingVoice = false;
      _isSending = true;
    });

    try {
      final chatService = ref.read(chatServiceProvider);
      final result = await _voiceService.uploadVoiceMessage(
        conversationId: widget.conversationId,
        filePath: path,
      );

      await chatService.sendVoiceMessage(
        conversationId: widget.conversationId,
        voiceUrl: result.url,
        durationSeconds: result.durationSeconds,
      );

      ref.invalidate(messagesProvider(widget.conversationId));
      _scrollToBottom();
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

  void _cancelVoiceRecording() {
    _voiceService.cancelRecording();
    setState(() => _isRecordingVoice = false);
  }

  // ============================================
  // LOCATION
  // ============================================

  Future<void> _sendLocation() async {
    setState(() => _showAttachmentMenu = false);

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Pristup k poloze zamitnut')),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Povolte pristup k poloze v nastaveni')),
          );
        }
        return;
      }

      setState(() => _isSending = true);

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final chatService = ref.read(chatServiceProvider);
      await chatService.sendLocationMessage(
        conversationId: widget.conversationId,
        latitude: position.latitude,
        longitude: position.longitude,
      );

      ref.invalidate(messagesProvider(widget.conversationId));
      _scrollToBottom();
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

  // ============================================
  // FILE PICKER
  // ============================================

  Future<void> _pickFile() async {
    setState(() => _showAttachmentMenu = false);

    // Na webu použij withData pro získání bytes přímo
    final result = await FilePicker.platform.pickFiles(withData: true);
    if (result == null || result.files.isEmpty || !mounted) return;

    final file = result.files.first;
    final fileBytes = file.bytes;
    if (fileBytes == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nepodařilo se načíst soubor')),
        );
      }
      return;
    }

    setState(() => _isSending = true);

    try {
      final chatService = ref.read(chatServiceProvider);
      final fileUrl = await chatService.uploadFile(
        conversationId: widget.conversationId,
        fileBytes: fileBytes,
        fileName: file.name,
      );

      await chatService.sendFileMessage(
        conversationId: widget.conversationId,
        fileUrl: fileUrl,
        fileName: file.name,
        fileSize: file.size,
        mimeType: _getMimeType(file.name),
      );

      ref.invalidate(messagesProvider(widget.conversationId));
      _scrollToBottom();
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

  String _getMimeType(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return 'application/pdf';
      case 'doc':
      case 'docx':
        return 'application/msword';
      case 'xls':
      case 'xlsx':
        return 'application/vnd.ms-excel';
      case 'ppt':
      case 'pptx':
        return 'application/vnd.ms-powerpoint';
      case 'zip':
        return 'application/zip';
      case 'txt':
        return 'text/plain';
      default:
        return 'application/octet-stream';
    }
  }

  // ============================================
  // GIF
  // ============================================

  Future<void> _sendGif(String gifUrl) async {
    setState(() {
      _showGifPicker = false;
      _isSending = true;
    });

    try {
      final chatService = ref.read(chatServiceProvider);
      await chatService.sendImageMessage(
        conversationId: widget.conversationId,
        imageUrl: gifUrl,
      );

      ref.invalidate(messagesProvider(widget.conversationId));
      _scrollToBottom();
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

  // ============================================
  // POLL
  // ============================================

  void _showCreatePollDialog() {
    setState(() => _showAttachmentMenu = false);

    showDialog(
      context: context,
      builder: (dialogContext) => CreatePollDialog(
        conversationId: widget.conversationId,
        onCreate: (question, options) async {
          final messenger = ScaffoldMessenger.of(dialogContext);
          try {
            final chatService = ref.read(chatServiceProvider);
            await chatService.createPoll(
              conversationId: widget.conversationId,
              question: question,
              options: options,
            );
            ref.invalidate(messagesProvider(widget.conversationId));
          } catch (e) {
            if (!mounted) return;
            messenger.showSnackBar(
              SnackBar(content: Text('Chyba: ${e.toString()}')),
            );
          }
        },
      ),
    );
  }

  // ============================================
  // HELPERS
  // ============================================

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _showForwardDialog(String messageId) {
    showDialog(
      context: context,
      builder: (context) => ForwardMessageDialog(
        messageId: messageId,
        currentConversationId: widget.conversationId,
      ),
    );
  }

  Future<void> _pickImage() async {
    setState(() => _showAttachmentMenu = false);
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );

    if (image == null || !mounted) return;

    setState(() => _isSending = true);

    try {
      final chatService = ref.read(chatServiceProvider);

      // Načti bytes z XFile (funguje na iOS i webu)
      final imageBytes = await image.readAsBytes();

      final imageUrl = await chatService.uploadImage(
        conversationId: widget.conversationId,
        fileBytes: imageBytes,
        fileName: image.name,
      );

      await chatService.sendImageMessage(
        conversationId: widget.conversationId,
        imageUrl: imageUrl,
      );

      ref.invalidate(messagesProvider(widget.conversationId));
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Chyba pri nahravani obrazku: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  void _setReplyTo(MessageModel message) {
    setState(() => _replyingTo = message);
    _focusNode.requestFocus();
  }

  void _cancelReply() {
    setState(() => _replyingTo = null);
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

      _scrollToBottom();
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
    final conversationAsync = ref.watch(conversationProvider(widget.conversationId));
    final currentUserId =
        ref.watch(chatProvider.notifier).chatService.currentUserId ?? '';

    final conversation = conversationAsync.value;
    final chatTitle = conversation?.getDisplayName(currentUserId) ?? 'Chat';
    final avatarUrl = conversation?.getDisplayAvatar(currentUserId);
    final otherUserId = conversation?.isDirect == true
        ? conversation?.getOtherParticipant(currentUserId)?.userId
        : null;

    // Listen to real-time messages
    ref.listen(messageStreamProvider(widget.conversationId), (_, next) {
      next.whenData((message) {
        ref.invalidate(messagesProvider(widget.conversationId));
      });
    });

    return Scaffold(
      appBar: _buildAppBar(chatTitle, avatarUrl, otherUserId),
      body: Column(
        children: [
          // Offline queue indicator
          OfflineQueueIndicator(conversationId: widget.conversationId),

          // Pinned messages bar
          PinnedMessagesBar(
            conversationId: widget.conversationId,
            onTap: (message) {
              // TODO: Scroll to message
            },
          ),

          // Encryption notice
          _buildEncryptionNotice(),

          // Typing indicator
          _buildTypingIndicator(),

          // Messages
          Expanded(
            child: _buildMessagesList(messagesAsync, currentUserId),
          ),

          // Reply preview
          if (_replyingTo != null)
            ReplyPreview(
              message: _replyingTo!,
              onCancel: _cancelReply,
            ),

          // Attachment menu
          if (_showAttachmentMenu)
            AttachmentMenu(
              onPickImage: _pickImage,
              onPickFile: _pickFile,
              onSendLocation: _sendLocation,
              onCreatePoll: _showCreatePollDialog,
            ),

          // Voice recording widget
          if (_isRecordingVoice)
            VoiceRecordingWidget(
              voiceService: _voiceService,
              onCancel: _cancelVoiceRecording,
              onComplete: _stopAndSendVoiceMessage,
            )
          else
            // Input
            MessageInput(
              controller: _messageController,
              focusNode: _focusNode,
              isSending: _isSending,
              showEmojiPicker: _showEmojiPicker,
              showGifPicker: _showGifPicker,
              showAttachmentMenu: _showAttachmentMenu,
              isRecordingVoice: _isRecordingVoice,
              onToggleEmojiPicker: _toggleEmojiPicker,
              onToggleGifPicker: _toggleGifPicker,
              onToggleAttachmentMenu: _toggleAttachmentMenu,
              onSendMessage: _sendMessage,
              onStartVoiceRecording: _startVoiceRecording,
              onStopVoiceRecording: _stopRecordingAndSend,
            ),

          // Emoji picker
          if (_showEmojiPicker)
            EmojiPickerWidget(
              onEmojiSelected: _onEmojiSelected,
            ),

          // GIF picker
          if (_showGifPicker)
            GifPickerWidget(
              onGifSelected: _sendGif,
            ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(String chatTitle, String? avatarUrl, String? otherUserId) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.pop(),
      ),
      title: GestureDetector(
        onTap: otherUserId != null ? () => context.push('/profile/$otherUserId') : null,
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
              child: avatarUrl == null
                  ? Text(
                      chatTitle.isNotEmpty ? chatTitle[0].toUpperCase() : '?',
                      style: const TextStyle(fontSize: 12),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chatTitle,
                    style: const TextStyle(fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      Icon(Icons.lock, size: 12, color: AppColors.success),
                      const SizedBox(width: 4),
                      Text(
                        'Sifrovano',
                        style: TextStyle(fontSize: 11, color: AppColors.success),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () => _showChatOptions(context),
        ),
      ],
    );
  }

  Widget _buildEncryptionNotice() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.success.withAlpha(15),
            AppColors.success.withAlpha(5),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock, size: 12, color: AppColors.success.withAlpha(180)),
          const SizedBox(width: 6),
          Text(
            'End-to-end sifrovano',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.success.withAlpha(180),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    final typingAsync = ref.watch(typingStreamProvider(widget.conversationId));

    return typingAsync.when(
      data: (typingUsers) => TypingIndicator(typingUsers: typingUsers),
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildMessagesList(AsyncValue<List<MessageModel>> messagesAsync, String currentUserId) {
    return messagesAsync.when(
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

            return MessageBubble(
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
              onReply: () => _setReplyTo(message),
              onForward: () => _showForwardDialog(message.id),
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
    );
  }

  void _showChatOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => ChatOptionsSheet(
        onDisappearingMessages: () {
          Navigator.pop(context);
          _showDisappearingMessagesOptions(context);
        },
        onSearch: () {
          Navigator.pop(context);
          _showMessageSearch(context);
        },
        onMute: () {
          Navigator.pop(context);
        },
        onBlock: () {
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showDisappearingMessagesOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DisappearingMessagesSheet(
        currentTtl: 0,
        onSelect: (ttl) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(ttl == 0 ? 'Mizici zpravy vypnuty' : 'Mizici zpravy zapnuty')),
          );
        },
      ),
    );
  }

  void _showMessageSearch(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => MessageSearchSheet(
          conversationId: widget.conversationId,
          scrollController: scrollController,
        ),
      ),
    );
  }
}
