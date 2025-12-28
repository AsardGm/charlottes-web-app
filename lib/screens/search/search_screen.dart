import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app.dart';
import '../../providers/search_provider.dart';
import '../../widgets/user_avatar.dart';
import '../../widgets/post_card.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
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
      onChanged: _onSearch,
      textInputAction: TextInputAction.search,
      onSubmitted: _onSearch,
    );
  }

  Widget _buildInitialState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 64,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: 16),
          Text(
            'Zadej hledany vyraz',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: 16),
          Text(
            'Zadne vysledky',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Zkus jiny hledany vyraz',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
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
        return ListTile(
          leading: UserAvatar(
            imageUrl: user.avatarUrl,
            name: user.username,
            size: 48,
          ),
          title: Row(
            children: [
              Text(
                user.username,
                style: const TextStyle(fontWeight: FontWeight.w600),
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
              : null,
          trailing: Text(
            '${user.followerCount} sledujicich',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textMuted,
            ),
          ),
          onTap: () {
            // TODO: Navigate to user profile
          },
        );
      },
    );
  }
}
