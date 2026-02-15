import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/theme.dart';
import '../../providers/search_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/user_avatar.dart';
import '../../widgets/post_card.dart';
import '../../widgets/profile/follow_button.dart';
import '../../widgets/common/empty_state.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    // Cancel previous timer
    _debounceTimer?.cancel();

    // Start new timer - search after 300ms of inactivity
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      ref.read(searchNotifierProvider.notifier).search(query);
    });
  }

  void _onSearchSubmitted(String query) {
    // Immediate search when user presses enter
    _debounceTimer?.cancel();
    ref.read(searchNotifierProvider.notifier).search(query);
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: _buildSearchField(),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
          tabs: const [
            Tab(text: 'Prispevky'),
            Tab(text: 'Uzivatele'),
          ],
        ),
      ),
      body: searchState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : searchState.query.isEmpty
              ? _buildInitialState()
              : searchState.isEmpty
                  ? _buildEmptyState()
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildPostsTab(searchState),
                        _buildUsersTab(searchState),
                      ],
                    ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      autofocus: true,
      decoration: InputDecoration(
        hintText: 'Hledat...',
        border: InputBorder.none,
        filled: false,
        contentPadding: EdgeInsets.zero,
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  _searchController.clear();
                  ref.read(searchNotifierProvider.notifier).clear();
                },
              )
            : null,
      ),
      style: const TextStyle(fontSize: 18),
      onChanged: _onSearchChanged,
      textInputAction: TextInputAction.search,
      onSubmitted: _onSearchSubmitted,
    );
  }

  Widget _buildInitialState() {
    return EmptyState(
      icon: Icons.search_rounded,
      title: 'Začni hledat',
      subtitle: 'Zadej hledaný výraz\na prohlédni příspěvky a uživatele.',
      iconColor: AppColors.accent,
    );
  }

  Widget _buildEmptyState() {
    final query = ref.read(searchNotifierProvider).query;
    return EmptyStates.noSearchResults(query);
  }

  Widget _buildPostsTab(SearchState searchState) {
    if (searchState.posts.isEmpty) {
      return Center(
        child: Text(
          'Zadne prispevky',
          style: TextStyle(color: AppColors.textMuted),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 100),
      itemCount: searchState.posts.length,
      itemBuilder: (context, index) {
        final post = searchState.posts[index];
        return PostCard(
          post: post,
          onTap: () => context.go('/post/${post.id}'),
        );
      },
    );
  }

  Widget _buildUsersTab(SearchState searchState) {
    final currentUser = ref.watch(currentUserProvider).value;

    if (searchState.users.isEmpty) {
      return Center(
        child: Text(
          'Zadni uzivatele',
          style: TextStyle(color: AppColors.textMuted),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: searchState.users.length,
      itemBuilder: (context, index) {
        final user = searchState.users[index];
        final isCurrentUser = currentUser?.id == user.id;

        return ListTile(
          leading: UserAvatar(
            imageUrl: user.avatarUrl,
            name: user.username,
            size: 48,
          ),
          title: Row(
            children: [
              Flexible(
                child: Text(
                  user.username,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (user.isAdmin) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'ADMIN',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
          subtitle: user.bio != null
              ? Text(
                  user.bio!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: AppColors.textMuted),
                )
              : Text(
                  '${user.followerCount} sledujicich',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
          trailing: isCurrentUser
              ? null
              : FollowButton(
                  userId: user.id,
                  compact: true,
                ),
          onTap: () {
            // Otevri profil uzivatele
            context.push('/profile/${user.id}');
          },
        );
      },
    );
  }
}
