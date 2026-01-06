import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/post_model.dart';
import '../../providers/user_provider.dart';
import '../../theme/theme.dart';
import '../../widgets/user_avatar.dart';
import '../../utils/helpers.dart';

/// Provider pro připnuté příspěvky
final pinnedPostsProvider = FutureProvider<List<PostModel>>((ref) async {
  return await ref.read(adminServiceProvider).getPinnedPosts();
});

/// Obrazovka pro správu obsahu
class ContentManagementScreen extends ConsumerStatefulWidget {
  const ContentManagementScreen({super.key});

  @override
  ConsumerState<ContentManagementScreen> createState() => _ContentManagementScreenState();
}

class _ContentManagementScreenState extends ConsumerState<ContentManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/admin'),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.content_paste, size: 20),
            ),
            const SizedBox(width: 10),
            const Text('Sprava obsahu'),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Pripnute'),
            Tab(text: 'Broadcast'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _PinnedPostsTab(),
          _BroadcastTab(),
        ],
      ),
    );
  }
}

/// Tab pro připnuté příspěvky
class _PinnedPostsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pinnedAsync = ref.watch(pinnedPostsProvider);

    return pinnedAsync.when(
      data: (posts) => posts.isEmpty
          ? _buildEmptyState(context)
          : _buildPostsList(context, ref, posts),
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (error, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: AppColors.error, size: 48),
            const SizedBox(height: 16),
            Text('Chyba: $error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.invalidate(pinnedPostsProvider),
              child: const Text('Zkusit znovu'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.push_pin_outlined,
            size: 64,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: 16),
          Text(
            'Zadne pripnute prispevky',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pripnete prispevky z jejich detailu',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostsList(BuildContext context, WidgetRef ref, List<PostModel> posts) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        return _PinnedPostTile(
          post: post,
          onUnpin: () => _unpinPost(context, ref, post),
          onView: () => context.push('/post/${post.id}'),
        );
      },
    );
  }

  Future<void> _unpinPost(BuildContext context, WidgetRef ref, PostModel post) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Odepnout prispevek?'),
        content: const Text('Prispevek nebude zobrazen na zacatku feedu.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Zrusit'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.warning),
            child: const Text('Odepnout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(adminServiceProvider).unpinPost(post.id);
        ref.invalidate(pinnedPostsProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Prispevek odepnut'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Chyba: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }
}

/// Dlaždice připnutého příspěvku
class _PinnedPostTile extends StatelessWidget {
  final PostModel post;
  final VoidCallback onUnpin;
  final VoidCallback onView;

  const _PinnedPostTile({
    required this.post,
    required this.onUnpin,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withAlpha(50),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                UserAvatar(
                  imageUrl: post.author?.avatarUrl,
                  name: post.author?.username ?? 'Uzivatel',
                  size: 40,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.author?.username ?? 'Uzivatel',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        Helpers.formatTimeAgo(post.createdAt),
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.push_pin, color: AppColors.primary, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'Pripnuto',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              post.content.length > 150
                  ? '${post.content.substring(0, 150)}...'
                  : post.content,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          // Actions
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onView,
                    icon: const Icon(Icons.visibility, size: 18),
                    label: const Text('Zobrazit'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onUnpin,
                    icon: const Icon(Icons.push_pin_outlined, size: 18),
                    label: const Text('Odepnout'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.warning,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Tab pro broadcast
class _BroadcastTab extends ConsumerStatefulWidget {
  @override
  ConsumerState<_BroadcastTab> createState() => _BroadcastTabState();
}

class _BroadcastTabState extends ConsumerState<_BroadcastTab> {
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.warning.withAlpha(20),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.warning.withAlpha(50)),
            ),
            child: Row(
              children: [
                Icon(Icons.campaign, color: AppColors.warning),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hromadna zprava',
                        style: TextStyle(
                          color: AppColors.warning,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Zprava bude odeslana vsem uzivatelum jako notifikace',
                        style: TextStyle(
                          color: AppColors.warning.withAlpha(200),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Titulek
          Text(
            'Titulek',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              hintText: 'Zadejte titulek zpravy...',
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              prefixIcon: const Icon(Icons.title),
            ),
          ),
          const SizedBox(height: 16),

          // Zpráva
          Text(
            'Zprava',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _messageController,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: 'Napiste zpravu pro vsechny uzivatele...',
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Šablony
          Text(
            'Rychle sablony',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _TemplateChip(
                label: 'Udrzba',
                onTap: () {
                  _titleController.text = 'Planovana udrzba';
                  _messageController.text =
                      'Dnes v 22:00 probehne planovana udrzba serveru. Aplikace muze byt docasne nedostupna.';
                },
              ),
              _TemplateChip(
                label: 'Nova funkce',
                onTap: () {
                  _titleController.text = 'Nova funkce!';
                  _messageController.text =
                      'Prave jsme spustili novou funkci! Podivejte se do aplikace a vyzkousejte ji.';
                },
              ),
              _TemplateChip(
                label: 'Pravidla',
                onTap: () {
                  _titleController.text = 'Pripominuti pravidel';
                  _messageController.text =
                      'Prosime o dodrzovani pravidel komunity. Diky za pochopeni!';
                },
              ),
              _TemplateChip(
                label: 'Dekujeme',
                onTap: () {
                  _titleController.text = 'Dekujeme!';
                  _messageController.text =
                      'Dekujeme vam za to, ze jste soucasti nasi komunity!';
                },
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Odeslat
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSending ? null : _sendBroadcast,
              icon: _isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send),
              label: Text(_isSending ? 'Odesilam...' : 'Odeslat vsem'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendBroadcast() async {
    final title = _titleController.text.trim();
    final message = _messageController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Zadejte titulek'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    if (message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Zadejte zpravu'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    // Potvrzení
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Odeslat broadcast?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Zprava bude odeslana vsem uzivatelum:'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message.length > 100 ? '${message.substring(0, 100)}...' : message,
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Zrusit'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Odeslat'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isSending = true);

    try {
      await ref.read(adminServiceProvider).sendBroadcast(title, message);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Broadcast odeslan'),
            backgroundColor: AppColors.success,
          ),
        );
        _titleController.clear();
        _messageController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Chyba: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }
}

/// Chip pro šablonu
class _TemplateChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _TemplateChip({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
      backgroundColor: AppColors.surface,
      side: BorderSide(color: AppColors.surfaceLight),
    );
  }
}
