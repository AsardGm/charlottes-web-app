import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../theme/theme.dart';
import '../../../models/conversation_model.dart';
import '../../../providers/chat_provider.dart';

/// Widget pro vyhledavani ve zpravach
class MessageSearchSheet extends ConsumerStatefulWidget {
  final String conversationId;
  final ScrollController scrollController;
  final Function(MessageModel)? onMessageTap;

  const MessageSearchSheet({
    super.key,
    required this.conversationId,
    required this.scrollController,
    this.onMessageTap,
  });

  @override
  ConsumerState<MessageSearchSheet> createState() => _MessageSearchSheetState();
}

class _MessageSearchSheetState extends ConsumerState<MessageSearchSheet> {
  final _searchController = TextEditingController();
  List<MessageModel> _results = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (query.length < 2) {
      setState(() => _results = []);
      return;
    }

    setState(() => _isSearching = true);

    try {
      final messages = await ref.read(messagesProvider(widget.conversationId).future);
      final filtered = messages.where((m) {
        final content = m.decryptedContent?.toLowerCase() ?? '';
        return content.contains(query.toLowerCase());
      }).toList();

      setState(() => _results = filtered);
    } finally {
      setState(() => _isSearching = false);
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
          child: TextField(
            controller: _searchController,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Hledat ve zpravach...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: _search,
          ),
        ),
        // Results
        Expanded(
          child: _isSearching
              ? const Center(child: CircularProgressIndicator())
              : _results.isEmpty
                  ? Center(
                      child: Text(
                        _searchController.text.length < 2
                            ? 'Zadej alespon 2 znaky'
                            : 'Zadne vysledky',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    )
                  : ListView.builder(
                      controller: widget.scrollController,
                      itemCount: _results.length,
                      itemBuilder: (context, index) {
                        final message = _results[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primary.withAlpha(40),
                            child: Text(
                              message.sender?.username[0].toUpperCase() ?? '?',
                              style: TextStyle(color: AppColors.primary),
                            ),
                          ),
                          title: Text(
                            message.decryptedContent ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            timeago.format(message.createdAt, locale: 'cs'),
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            widget.onMessageTap?.call(message);
                          },
                        );
                      },
                    ),
        ),
      ],
    );
  }
}
