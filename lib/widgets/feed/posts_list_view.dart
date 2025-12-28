import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/theme.dart';
import '../../models/post_model.dart';
import '../post_card.dart';
import 'empty_feed_state.dart';

/// Widget pro zobrazení seznamu příspěvků
///
/// Zobrazuje příspěvky v scrollovatelném seznamu s podporou
/// pro nekonečné scrollování (infinite scroll).
class PostsListView extends StatelessWidget {
  /// Seznam příspěvků k zobrazení
  final List<PostModel> posts;

  /// ScrollController pro detekci scrollování
  final ScrollController scrollController;

  /// Jsou k dispozici další příspěvky?
  final bool hasMore;

  /// Callback pro smazání příspěvku
  final Future<void> Function(String postId) onDeletePost;

  /// Callback volaný po úspěšném smazání
  final VoidCallback? onDeleteSuccess;

  /// Callback volaný při chybě mazání
  final void Function(Object error)? onDeleteError;

  const PostsListView({
    super.key,
    required this.posts,
    required this.scrollController,
    required this.hasMore,
    required this.onDeletePost,
    this.onDeleteSuccess,
    this.onDeleteError,
  });

  @override
  Widget build(BuildContext context) {
    // Prázdný stav
    if (posts.isEmpty) {
      return const EmptyFeedState();
    }

    // Seznam příspěvků
    return ListView.builder(
      controller: scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: 8, bottom: 100),
      itemCount: posts.length + (hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        // Indikátor načítání dalších
        if (index >= posts.length) {
          return _buildLoadingIndicator();
        }

        final post = posts[index];
        return PostCard(
          post: post,
          onTap: () => context.go('/post/${post.id}'),
          onDelete: () => _handleDelete(context, post.id),
        );
      },
    );
  }

  /// Sestaví indikátor načítání dalších příspěvků
  Widget _buildLoadingIndicator() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }

  /// Zpracuje mazání příspěvku
  Future<void> _handleDelete(BuildContext context, String postId) async {
    try {
      await onDeletePost(postId);
      onDeleteSuccess?.call();
    } catch (e) {
      onDeleteError?.call(e);
    }
  }
}
