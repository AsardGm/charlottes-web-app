import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../theme/theme.dart';
import '../../models/conversation_model.dart';
import '../../providers/chat_provider.dart';

class ConversationsScreen extends ConsumerStatefulWidget {
  const ConversationsScreen({super.key});

  @override
  ConsumerState<ConversationsScreen> createState() =>
      _ConversationsScreenState();
}

class _ConversationsScreenState extends ConsumerState<ConversationsScreen> {
  bool _keysInitialized = false;

  @override
  void initState() {
    super.initState();
    // Inicializuj klíče na pozadí (neblokuje UI) - odloženo po buildu
    Future(() => _initKeysInBackground());
  }

  Future<void> _initKeysInBackground() async {
    if (_keysInitialized) return;
    try {
      await ref.read(chatProvider.notifier).initializeKeys();
      _keysInitialized = true;
    } catch (e) {
      // Ignoruj chyby při inicializaci klíčů - chat bude fungovat bez E2EE
      debugPrint('Failed to initialize keys: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final conversationsAsync = ref.watch(conversationsProvider);

    return Scaffold(
      body: conversationsAsync.when(
        data: (conversations) {
          if (conversations.isEmpty) {
            return _buildEmptyState();
          }
          return RefreshIndicator(
            onRefresh: () => ref.refresh(conversationsProvider.future),
            child: ListView.builder(
              itemCount: conversations.length,
              itemBuilder: (context, index) {
                final conversation = conversations[index];
                return _ConversationTile(
                  conversation: conversation,
                  onTap: () => context.push('/chat/${conversation.id}'),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text('Chyba: ${error.toString()}'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref.refresh(conversationsProvider),
                child: const Text('Zkusit znovu'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showNewChatDialog(context),
        child: const Icon(Icons.edit),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: 16),
          Text(
            'Zadne zpravy',
            style: TextStyle(
              fontSize: 18,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Zacni konverzaci s nekym!',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => _showNewChatDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Nova zprava'),
          ),
        ],
      ),
    );
  }

  void _showNewChatDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const _NewChatSheet(),
    );
  }
}

class _ConversationTile extends ConsumerWidget {
  final ConversationModel conversation;
  final VoidCallback onTap;

  const _ConversationTile({
    required this.conversation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserId =
        ref.watch(chatProvider.notifier).chatService.currentUserId ?? '';
    final displayName = conversation.getDisplayName(currentUserId);
    final displayAvatar = conversation.getDisplayAvatar(currentUserId);
    final lastMessage = conversation.lastMessage;
    final hasUnread = conversation.unreadCount > 0;

    // Zobraz preview zprávy nebo placeholder
    String messagePreview = 'Zahajte konverzaci';
    if (lastMessage != null) {
      if (lastMessage.isDeleted) {
        messagePreview = 'Zprava byla smazana';
      } else if (lastMessage.decryptedContent != null &&
          lastMessage.decryptedContent!.isNotEmpty) {
        messagePreview = lastMessage.decryptedContent!;
      } else {
        messagePreview = 'Nova zprava';
      }
    }

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: AppColors.surfaceLight,
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            // Avatar
            Stack(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.primary.withAlpha(40),
                  backgroundImage:
                      displayAvatar != null ? NetworkImage(displayAvatar) : null,
                  child: displayAvatar == null
                      ? Text(
                          displayName.isNotEmpty
                              ? displayName[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        )
                      : null,
                ),
                // Online indicator (placeholder)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.background,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name row
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          displayName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight:
                                hasUnread ? FontWeight.w600 : FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (conversation.isEncrypted)
                        Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: Icon(
                            Icons.lock,
                            size: 14,
                            color: AppColors.success,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Message preview
                  Text(
                    messagePreview,
                    style: TextStyle(
                      fontSize: 14,
                      color: hasUnread
                          ? AppColors.textSecondary
                          : AppColors.textMuted,
                      fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Time and badge
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (lastMessage != null)
                  Text(
                    timeago.format(lastMessage.createdAt, locale: 'cs'),
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          hasUnread ? AppColors.primary : AppColors.textMuted,
                      fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                if (hasUnread) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      conversation.unreadCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NewChatSheet extends ConsumerStatefulWidget {
  const _NewChatSheet();

  @override
  ConsumerState<_NewChatSheet> createState() => _NewChatSheetState();
}

class _NewChatSheetState extends ConsumerState<_NewChatSheet> {
  final _searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (query.length < 2) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final results =
          await ref.read(chatProvider.notifier).chatService.searchUsers(query);
      setState(() => _searchResults = results);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showCreateGroupDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const _CreateGroupSheet(),
    );
  }

  Future<void> _startConversation(String userId) async {
    try {
      final conversationId = await ref
          .read(chatProvider.notifier)
          .chatService
          .getOrCreateDirectConversation(userId);

      // Invaliduj seznam konverzací aby se nová konverzace zobrazila
      ref.invalidate(conversationsProvider);

      if (mounted) {
        Navigator.of(context).pop();
        context.push('/chat/$conversationId');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Chyba: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Nova zprava',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _showCreateGroupDialog(context);
                        },
                        icon: const Icon(Icons.group_add, size: 20),
                        label: const Text('Skupina'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Hledat uzivatele...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: _search,
                  ),
                ],
              ),
            ),
            // Results
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _searchResults.isEmpty
                      ? Center(
                          child: Text(
                            _searchController.text.length < 2
                                ? 'Zadej jmeno uzivatele'
                                : 'Zadni uzivatele nenalezeni',
                            style: TextStyle(color: AppColors.textMuted),
                          ),
                        )
                      : ListView.builder(
                          controller: scrollController,
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            final user = _searchResults[index];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundImage: user.avatarUrl != null
                                    ? NetworkImage(user.avatarUrl!)
                                    : null,
                                child: user.avatarUrl == null
                                    ? Text(user.username[0].toUpperCase())
                                    : null,
                              ),
                              title: Text(user.username),
                              trailing: const Icon(Icons.arrow_forward_ios,
                                  size: 16),
                              onTap: () => _startConversation(user.id),
                            );
                          },
                        ),
            ),
          ],
        );
      },
    );
  }
}

/// Widget pro vytvoření skupinového chatu
class _CreateGroupSheet extends ConsumerStatefulWidget {
  const _CreateGroupSheet();

  @override
  ConsumerState<_CreateGroupSheet> createState() => _CreateGroupSheetState();
}

class _CreateGroupSheetState extends ConsumerState<_CreateGroupSheet> {
  final _nameController = TextEditingController();
  final _searchController = TextEditingController();
  final List<String> _selectedUserIds = [];
  final List<dynamic> _selectedUsers = [];
  List<dynamic> _searchResults = [];
  bool _isLoading = false;
  bool _isCreating = false;

  @override
  void dispose() {
    _nameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (query.length < 2) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final results =
          await ref.read(chatProvider.notifier).chatService.searchUsers(query);
      // Filtruj už vybrané uživatele
      final filtered = results.where((u) => !_selectedUserIds.contains(u.id)).toList();
      setState(() => _searchResults = filtered);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _addUser(dynamic user) {
    setState(() {
      _selectedUserIds.add(user.id);
      _selectedUsers.add(user);
      _searchResults = _searchResults.where((u) => u.id != user.id).toList();
      _searchController.clear();
    });
  }

  void _removeUser(String userId) {
    setState(() {
      _selectedUserIds.remove(userId);
      _selectedUsers.removeWhere((u) => u.id == userId);
    });
  }

  Future<void> _createGroup() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Zadej nazev skupiny')),
      );
      return;
    }

    if (_selectedUserIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vyber alespon jednoho uzivatele')),
      );
      return;
    }

    setState(() => _isCreating = true);

    try {
      final conversationId = await ref.read(chatProvider.notifier).createGroup(
            name: name,
            memberIds: _selectedUserIds,
          );

      ref.invalidate(conversationsProvider);

      if (mounted && conversationId != null) {
        Navigator.of(context).pop();
        context.push('/chat/$conversationId');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Chyba: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Nova skupina',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      _isCreating
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : TextButton(
                              onPressed: _createGroup,
                              child: const Text('Vytvorit'),
                            ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Group name
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      hintText: 'Nazev skupiny',
                      prefixIcon: const Icon(Icons.group),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Selected users
                  if (_selectedUsers.isNotEmpty) ...[
                    SizedBox(
                      height: 60,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _selectedUsers.length,
                        itemBuilder: (context, index) {
                          final user = _selectedUsers[index];
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Stack(
                              children: [
                                Column(
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundImage: user.avatarUrl != null
                                          ? NetworkImage(user.avatarUrl!)
                                          : null,
                                      child: user.avatarUrl == null
                                          ? Text(user.username[0].toUpperCase())
                                          : null,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      user.username,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                                Positioned(
                                  right: -4,
                                  top: -4,
                                  child: GestureDetector(
                                    onTap: () => _removeUser(user.id),
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        color: AppColors.error,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        size: 12,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  // Search users
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Pridat uzivatele...',
                      prefixIcon: const Icon(Icons.person_add),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: _search,
                  ),
                ],
              ),
            ),
            // Search results
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _searchResults.isEmpty
                      ? Center(
                          child: Text(
                            _searchController.text.length < 2
                                ? 'Hledej uzivatele k pridani'
                                : 'Zadni uzivatele nenalezeni',
                            style: TextStyle(color: AppColors.textMuted),
                          ),
                        )
                      : ListView.builder(
                          controller: scrollController,
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            final user = _searchResults[index];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundImage: user.avatarUrl != null
                                    ? NetworkImage(user.avatarUrl!)
                                    : null,
                                child: user.avatarUrl == null
                                    ? Text(user.username[0].toUpperCase())
                                    : null,
                              ),
                              title: Text(user.username),
                              trailing: IconButton(
                                icon: Icon(Icons.add_circle,
                                    color: AppColors.primary),
                                onPressed: () => _addUser(user),
                              ),
                            );
                          },
                        ),
            ),
          ],
        );
      },
    );
  }
}
