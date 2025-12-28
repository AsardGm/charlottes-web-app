import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/profile/profile.dart';

/// Obrazovka profilu uživatele
///
/// Zobrazuje informace o přihlášeném uživateli včetně avataru,
/// statistik, menu položek a možnosti odhlášení.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final isAdmin = ref.watch(isAdminProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        actions: const [
          // Zvoneček s notifikacemi
          NotificationBadge(),
        ],
      ),
      body: userAsync.when(
        data: (user) {
          // Nepřihlášený uživatel
          if (user == null) {
            return const Center(
              child: Text('Nepřihlášený uživatel'),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const SizedBox(height: 16),

                // === Avatar s tlačítkem editace ===
                ProfileAvatar(
                  imageUrl: user.avatarUrl,
                  username: user.username,
                  isAdmin: user.isAdmin,
                ),

                const SizedBox(height: 16),

                // === Uživatelské jméno ===
                Text(
                  user.username,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),

                // === Bio (volitelné) ===
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

                // === Badge role ===
                RoleBadge(isAdmin: user.isAdmin),

                const SizedBox(height: 24),

                // === Statistiky ===
                ProfileStatsRow(
                  postCount: user.postCount,
                  followerCount: user.followerCount,
                  followingCount: user.followingCount,
                ),

                const SizedBox(height: 24),

                // === Menu - Hlavní akce ===
                ProfileMenuCard(
                  children: [
                    ProfileMenuItem(
                      icon: Icons.person_outline,
                      title: 'Upravit profil',
                      onTap: () => context.go('/edit-profile'),
                    ),
                    ProfileMenuItem(
                      icon: Icons.bookmark_outline,
                      title: 'Uložené příspěvky',
                      onTap: () => BookmarksSheet.show(context),
                    ),
                    ProfileMenuItem(
                      icon: Icons.search,
                      title: 'Vyhledávání',
                      onTap: () => context.go('/search'),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // === Menu - Nastavení ===
                ProfileMenuCard(
                  children: [
                    // Admin panel (pouze pro adminy)
                    if (isAdmin)
                      ProfileMenuItem(
                        icon: Icons.admin_panel_settings,
                        title: 'Administrace',
                        subtitle: 'Správa uživatelů a příspěvků',
                        onTap: () => context.go('/admin'),
                      ),
                    ProfileMenuItem(
                      icon: Icons.settings_outlined,
                      title: 'Nastavení',
                      onTap: () => context.go('/settings'),
                    ),
                    ProfileMenuItem(
                      icon: Icons.help_outline,
                      title: 'Nápověda',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Připravujeme...')),
                        );
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // === Menu - Odhlášení ===
                ProfileMenuCard(
                  children: [
                    ProfileMenuItem(
                      icon: Icons.logout,
                      title: 'Odhlásit se',
                      iconColor: AppColors.error,
                      titleColor: AppColors.error,
                      onTap: () => LogoutDialog.show(context),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // === Datum registrace ===
                Text(
                  'Člen od: ${_formatDate(user.createdAt)}',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),

                const SizedBox(height: 8),

                // === Verze aplikace ===
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
        error: (error, _) => Center(
          child: Text('Chyba: ${error.toString()}'),
        ),
      ),
    );
  }

  /// Formátuje datum na český formát
  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }
}
