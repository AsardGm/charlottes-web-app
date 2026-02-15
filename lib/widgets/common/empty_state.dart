import 'package:flutter/material.dart';
import '../../theme/theme.dart';

/// Universal empty state widget with icon, title, subtitle and optional action
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? iconColor;
  final double iconSize;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
    this.iconColor,
    this.iconSize = 80,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = iconColor ?? Theme.of(context).colorScheme.primary;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final mutedColor = Theme.of(context).textTheme.bodySmall?.color ?? textColor.withValues(alpha: 0.6);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Spider/Icon illustration
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: iconSize,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 24),

            // Title
            Text(
              title,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Subtitle
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 15,
                color: mutedColor,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),

            // Action button (optional)
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add_rounded),
                label: Text(actionLabel!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Predefined empty states for common scenarios
class EmptyStates {
  EmptyStates._();

  /// No posts in feed
  static Widget noPosts({VoidCallback? onCreatePost}) {
    return EmptyState(
      icon: Icons.article_outlined,
      title: 'Ještě tu nic není',
      subtitle: 'Buď první kdo přidá příspěvek!\nSdílej své zkušenosti s komunitou.',
      actionLabel: onCreatePost != null ? 'Vytvořit příspěvek' : null,
      onAction: onCreatePost,
    );
  }

  /// No search results
  static Widget noSearchResults(String query) {
    return EmptyState(
      icon: Icons.search_off_rounded,
      title: 'Nic nenalezeno',
      subtitle: 'Pro "$query" jsme nic nenašli.\nZkus jiné klíčové slovo.',
    );
  }

  /// No comments
  static Widget noComments({VoidCallback? onAddComment}) {
    return EmptyState(
      icon: Icons.chat_bubble_outline_rounded,
      title: 'Zatím žádné komentáře',
      subtitle: 'Buď první kdo okomentuje!\nSdílej své myšlenky.',
      actionLabel: onAddComment != null ? 'Přidat komentář' : null,
      onAction: onAddComment,
      iconSize: 64,
    );
  }

  /// No notifications
  static Widget noNotifications() {
    return EmptyState(
      icon: Icons.notifications_none_rounded,
      title: 'Žádné notifikace',
      subtitle: 'Až se něco stane, dáme ti vědět!\nVšechny notifikace uvidíš tady.',
      iconColor: AppColors.accent,
    );
  }

  /// No bookmarks
  static Widget noBookmarks({VoidCallback? onExplore}) {
    return EmptyState(
      icon: Icons.bookmark_border_rounded,
      title: 'Žádné záložky',
      subtitle: 'Ukládej zajímavé příspěvky\na najdeš je tady kdykoliv.',
      actionLabel: onExplore != null ? 'Prozkoumat' : null,
      onAction: onExplore,
      iconColor: AppColors.gold,
    );
  }

  /// No challenges
  static Widget noChallenges({VoidCallback? onBrowse}) {
    return EmptyState(
      icon: Icons.emoji_events_outlined,
      title: 'Žádné výzvy',
      subtitle: 'Splň výzvy a získej odměny!\nProzkumej dostupné výzvy.',
      actionLabel: onBrowse != null ? 'Zobrazit výzvy' : null,
      onAction: onBrowse,
      iconColor: AppColors.primary,
    );
  }

  /// No chat messages
  static Widget noMessages() {
    return EmptyState(
      icon: Icons.chat_outlined,
      title: 'Žádné zprávy',
      subtitle: 'Začni konverzaci s někým\nz komunity!',
      iconColor: AppColors.accent,
      iconSize: 64,
    );
  }

  /// No followers/following
  static Widget noUsers(String type) {
    return EmptyState(
      icon: Icons.people_outline_rounded,
      title: type == 'followers' ? 'Žádní sledující' : 'Nikoho nesleduješ',
      subtitle: type == 'followers'
          ? 'Až tě někdo začne sledovat,\nzobrazí se tady.'
          : 'Začni sledovat zajímavé lidi\nz komunity!',
    );
  }

  /// Error state - iconColor will be set from context in builder
  static Widget error({
    required String message,
    VoidCallback? onRetry,
  }) {
    return Builder(
      builder: (context) => EmptyState(
        icon: Icons.error_outline_rounded,
        title: 'Něco se pokazilo',
        subtitle: message,
        actionLabel: onRetry != null ? 'Zkusit znovu' : null,
        onAction: onRetry,
        iconColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  /// Network error - iconColor will be set from context in builder
  static Widget networkError({VoidCallback? onRetry}) {
    return Builder(
      builder: (context) => EmptyState(
        icon: Icons.wifi_off_rounded,
        title: 'Žádné připojení',
        subtitle: 'Zkontroluj připojení k internetu\na zkus to znovu.',
        actionLabel: onRetry != null ? 'Zkusit znovu' : null,
        onAction: onRetry,
        iconColor: Theme.of(context).colorScheme.error,
      ),
    );
  }
}
