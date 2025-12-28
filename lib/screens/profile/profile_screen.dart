import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/bookmark_provider.dart';
import '../../widgets/user_avatar.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final isAdmin = ref.watch(isAdminProvider);
    final unreadCount = ref.watch(unreadCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        actions: [
          // Notification bell with badge
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () => context.go('/notifications'),
              ),
              unreadCount.when(
                data: (count) => count > 0
                    ? Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            count > 9 ? '9+' : '$count',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
        ],
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null) {
            return const Center(child: Text('Neprihlaseny uzivatel'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const SizedBox(height: 16),

                // Avatar with edit button
                Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: user.isAdmin ? AppColors.primaryGradient : null,
                        border: user.isAdmin
                            ? null
                            : Border.all(color: AppColors.surfaceLight, width: 3),
                      ),
                      child: UserAvatar(
                        imageUrl: user.avatarUrl,
                        name: user.username,
                        size: 100,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () => context.go('/edit-profile'),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.background,
                              width: 3,
                            ),
                          ),
                          child: const Icon(
                            Icons.edit,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Username
                Text(
                  user.username,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),

                // Bio
                if (user.bio != null && user.bio!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    user.bio!,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],

                const SizedBox(height: 8),

                // Role badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: user.isAdmin ? AppColors.primaryGradient : null,
                    color: user.isAdmin ? null : AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    user.isAdmin ? 'Admin' : 'Clen',
                    style: TextStyle(
                      color: user.isAdmin ? Colors.white : AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Stats row
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withAlpha(8),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _StatItem(
                        count: user.postCount,
                        label: 'Prispevky',
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: Colors.white.withAlpha(10),
                      ),
                      _StatItem(
                        count: user.followerCount,
                        label: 'Sledujici',
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: Colors.white.withAlpha(10),
                      ),
                      _StatItem(
                        count: user.followingCount,
                        label: 'Sleduje',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Menu items
                _MenuCard(
                  children: [
                    _MenuItem(
                      icon: Icons.person_outline,
                      title: 'Upravit profil',
                      onTap: () => context.go('/edit-profile'),
                    ),
                    _MenuItem(
                      icon: Icons.bookmark_outline,
                      title: 'Ulozene prispevky',
                      onTap: () {
                        // Show bookmarks bottom sheet
                        _showBookmarksSheet(context, ref);
                      },
                    ),
                    _MenuItem(
                      icon: Icons.search,
                      title: 'Vyhledavani',
                      onTap: () => context.go('/search'),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                _MenuCard(
                  children: [
                    if (isAdmin)
                      _MenuItem(
                        icon: Icons.admin_panel_settings,
                        title: 'Administrace',
                        subtitle: 'Sprava uzivatelu a prispevku',
                        onTap: () => context.go('/admin'),
                      ),
                    _MenuItem(
                      icon: Icons.settings_outlined,
                      title: 'Nastaveni',
                      onTap: () => context.go('/settings'),
                    ),
                    _MenuItem(
                      icon: Icons.help_outline,
                      title: 'Napoveda',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Pripravujeme...')),
                        );
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                _MenuCard(
                  children: [
                    _MenuItem(
                      icon: Icons.logout,
                      title: 'Odhlasit se',
                      iconColor: AppColors.error,
                      titleColor: AppColors.error,
                      onTap: () => _showLogoutDialog(context, ref),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                Text(
                  'Clen od: ${_formatDate(user.createdAt)}',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  "Charlotte's Web v1.0.0",
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Chyba: ${error.toString()}')),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }

  void _showBookmarksSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          final bookmarksAsync = ref.watch(bookmarkNotifierProvider);

          return Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.textMuted,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Ulozene prispevky',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: bookmarksAsync.when(
                  data: (bookmarks) {
                    if (bookmarks.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.bookmark_outline,
                              size: 48,
                              color: AppColors.textMuted,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Zadne ulozene prispevky',
                              style: TextStyle(color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: bookmarks.length,
                      itemBuilder: (context, index) {
                        final post = bookmarks[index];
                        return ListTile(
                          title: Text(
                            post.content,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            post.author?.username ?? 'Neznamy',
                            style: TextStyle(color: AppColors.textMuted),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.bookmark, color: AppColors.primary),
                            onPressed: () {
                              ref.read(bookmarkNotifierProvider.notifier)
                                  .removeBookmark(post.id);
                            },
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            context.go('/post/${post.id}');
                          },
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
            ],
          );
        },
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Odhlasit se?'),
        content: const Text('Opravdu se chcete odhlasit?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Zrusit'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(authNotifierProvider.notifier).signOut();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Odhlasit'),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final int count;
  final String label;

  const _StatItem({
    required this.count,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '$count',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}

class _MenuCard extends StatelessWidget {
  final List<Widget> children;

  const _MenuCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withAlpha(8),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1)
              Divider(height: 1, color: Colors.white.withAlpha(5)),
          ],
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? titleColor;

  const _MenuItem({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.iconColor,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? AppColors.textSecondary),
      title: Text(
        title,
        style: TextStyle(
          color: titleColor ?? AppColors.textPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
              ),
            )
          : null,
      trailing: Icon(
        Icons.chevron_right,
        color: iconColor ?? AppColors.textMuted,
      ),
      onTap: onTap,
    );
  }
}
