import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/theme.dart';
import '../../providers/bookmark_provider.dart';

/// Spodní panel s uloženými příspěvky
///
/// Zobrazuje seznam záložek uživatele s možností
/// odebrání záložky a přechodu na detail příspěvku.
class BookmarksSheet extends ConsumerWidget {
  const BookmarksSheet({super.key});

  /// Zobrazí spodní panel se záložkami
  static void show(BuildContext context) {
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
        builder: (context, scrollController) => _BookmarksContent(
          scrollController: scrollController,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Tento widget se nepoužívá přímo, ale přes statickou metodu show()
    return const SizedBox.shrink();
  }
}

/// Vnitřní obsah spodního panelu
class _BookmarksContent extends ConsumerWidget {
  /// Controller pro scrollování
  final ScrollController scrollController;

  const _BookmarksContent({
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarksAsync = ref.watch(bookmarkNotifierProvider);

    return Column(
      children: [
        // Úchyt pro tažení
        Container(
          width: 40,
          height: 4,
          margin: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.textMuted,
            borderRadius: BorderRadius.circular(2),
          ),
        ),

        // Hlavička
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Uložené příspěvky',
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

        // Seznam záložek
        Expanded(
          child: bookmarksAsync.when(
            data: (bookmarks) => _buildBookmarksList(context, ref, bookmarks),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(
              child: Text('Chyba: ${error.toString()}'),
            ),
          ),
        ),
      ],
    );
  }

  /// Sestaví seznam záložek
  Widget _buildBookmarksList(
    BuildContext context,
    WidgetRef ref,
    List<dynamic> bookmarks,
  ) {
    // Prázdný stav
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
              'Žádné uložené příspěvky',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ],
        ),
      );
    }

    // Seznam záložek
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
            post.author?.username ?? 'Neznámý',
            style: TextStyle(color: AppColors.textMuted),
          ),
          // Tlačítko pro odebrání záložky
          trailing: IconButton(
            icon: const Icon(Icons.bookmark, color: AppColors.primary),
            onPressed: () {
              ref
                  .read(bookmarkNotifierProvider.notifier)
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
  }
}
