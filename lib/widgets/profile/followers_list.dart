import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/theme.dart';
import '../../models/user_model.dart';
import '../../providers/follow_provider.dart';
import '../../providers/auth_provider.dart';
import '../user_avatar.dart';
import 'follow_button.dart';

/// Typ seznamu - sledujici nebo sledovani
enum FollowListType { followers, following }

/// Modal se seznamem sledujicich nebo sledovanych
class FollowersListModal extends ConsumerStatefulWidget {
  /// ID uzivatele jehoz seznam zobrazujeme
  final String? userId;

  /// Typ seznamu
  final FollowListType type;

  /// Pocatecni tab index (pro prehled s taby)
  final int initialTabIndex;

  const FollowersListModal({
    super.key,
    this.userId,
    required this.type,
    this.initialTabIndex = 0,
  });

  /// Zobrazi modal se seznamem
  static Future<void> show(
    BuildContext context, {
    String? userId,
    required FollowListType type,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => FollowersListModal(
          userId: userId,
          type: type,
        ),
      ),
    );
  }

  /// Zobrazi modal s taby (sledujici + sledovani)
  static Future<void> showWithTabs(
    BuildContext context, {
    String? userId,
    int initialTabIndex = 0,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => _FollowersTabsModal(
          userId: userId,
          initialTabIndex: initialTabIndex,
        ),
      ),
    );
  }

  @override
  ConsumerState<FollowersListModal> createState() => _FollowersListModalState();
}

class _FollowersListModalState extends ConsumerState<FollowersListModal> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final listAsync = widget.type == FollowListType.followers
        ? ref.watch(followersProvider(widget.userId))
        : ref.watch(followingProvider(widget.userId));

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textMuted.withAlpha(50),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              widget.type == FollowListType.followers ? 'Sledujici' : 'Sleduje',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),

          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
              style: TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Hledat...',
                hintStyle: TextStyle(color: AppColors.textMuted),
                prefixIcon: Icon(Icons.search, color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // List
          Expanded(
            child: listAsync.when(
              data: (users) => _buildList(users),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Text(
                  'Chyba: ${error.toString()}',
                  style: TextStyle(color: AppColors.error),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<UserModel> users) {
    final filteredUsers = _searchQuery.isEmpty
        ? users
        : users.where((u) => u.username.toLowerCase().contains(_searchQuery)).toList();

    if (filteredUsers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: AppColors.textMuted.withAlpha(100),
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty
                  ? (widget.type == FollowListType.followers
                      ? 'Zatim zadni sledujici'
                      : 'Zatim nikoho nesleduje')
                  : 'Zadne vysledky',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: filteredUsers.length,
      itemBuilder: (context, index) => _UserListTile(
        user: filteredUsers[index],
        onTap: () {
          Navigator.pop(context);
          context.push('/profile/${filteredUsers[index].id}');
        },
      ),
    );
  }
}

/// Modal s taby pro sledujici a sledovane
class _FollowersTabsModal extends ConsumerStatefulWidget {
  final String? userId;
  final int initialTabIndex;

  const _FollowersTabsModal({
    this.userId,
    this.initialTabIndex = 0,
  });

  @override
  ConsumerState<_FollowersTabsModal> createState() => _FollowersTabsModalState();
}

class _FollowersTabsModalState extends ConsumerState<_FollowersTabsModal>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textMuted.withAlpha(50),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          const SizedBox(height: 8),

          // Tabs
          TabBar(
            controller: _tabController,
            labelColor: AppColors.textPrimary,
            unselectedLabelColor: AppColors.textMuted,
            indicatorColor: AppColors.primary,
            indicatorWeight: 2,
            tabs: const [
              Tab(text: 'Sledujici'),
              Tab(text: 'Sleduje'),
            ],
          ),

          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
              style: TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Hledat...',
                hintStyle: TextStyle(color: AppColors.textMuted),
                prefixIcon: Icon(Icons.search, color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),

          // Tab views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _FollowList(
                  userId: widget.userId,
                  type: FollowListType.followers,
                  searchQuery: _searchQuery,
                ),
                _FollowList(
                  userId: widget.userId,
                  type: FollowListType.following,
                  searchQuery: _searchQuery,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Samotny seznam uzivatelu
class _FollowList extends ConsumerWidget {
  final String? userId;
  final FollowListType type;
  final String searchQuery;

  const _FollowList({
    this.userId,
    required this.type,
    required this.searchQuery,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listAsync = type == FollowListType.followers
        ? ref.watch(followersProvider(userId))
        : ref.watch(followingProvider(userId));

    return listAsync.when(
      data: (users) {
        final filteredUsers = searchQuery.isEmpty
            ? users
            : users.where((u) => u.username.toLowerCase().contains(searchQuery)).toList();

        if (filteredUsers.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.people_outline,
                  size: 64,
                  color: AppColors.textMuted.withAlpha(100),
                ),
                const SizedBox(height: 16),
                Text(
                  searchQuery.isEmpty
                      ? (type == FollowListType.followers
                          ? 'Zatim zadni sledujici'
                          : 'Zatim nikoho nesleduje')
                      : 'Zadne vysledky',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: filteredUsers.length,
          itemBuilder: (context, index) => _UserListTile(
            user: filteredUsers[index],
            onTap: () {
              Navigator.pop(context);
              context.push('/profile/${filteredUsers[index].id}');
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Text(
          'Chyba: ${error.toString()}',
          style: TextStyle(color: AppColors.error),
        ),
      ),
    );
  }
}

/// Radek s uzivatelem
class _UserListTile extends ConsumerWidget {
  final UserModel user;
  final VoidCallback? onTap;

  const _UserListTile({
    required this.user,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider).value;
    final isCurrentUser = currentUser?.id == user.id;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: UserAvatar(
        imageUrl: user.avatarUrl,
        name: user.username,
        size: 48,
      ),
      title: Text(
        user.username,
        style: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: user.bio != null && user.bio!.isNotEmpty
          ? Text(
              user.bio!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
              ),
            )
          : null,
      trailing: isCurrentUser
          ? null
          : FollowButton(
              userId: user.id,
              compact: true,
            ),
      onTap: onTap,
    );
  }
}
