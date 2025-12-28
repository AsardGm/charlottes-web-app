import 'package:flutter/material.dart';
import '../../models/comment_model.dart';
import '../../theme/theme.dart';
import '../comment_widget.dart';

/// Sekce komentářů pod příspěvkem
///
/// Zobrazuje seznam komentářů s možností mazání.
/// Obsahuje stavy pro načítání a prázdný seznam.
class CommentsSection extends StatelessWidget {
  /// Seznam komentářů
  final List<CommentModel> comments;

  /// Načítají se komentáře?
  final bool isLoading;

  /// ID aktuálního uživatele
  final String? userId;

  /// Je uživatel admin?
  final bool isAdmin;

  /// Callback pro smazání komentáře
  final Future<void> Function(CommentModel comment) onDelete;

  const CommentsSection({
    super.key,
    required this.comments,
    required this.isLoading,
    this.userId,
    required this.isAdmin,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nadpis sekce
          Text(
            'Komentáře (${comments.length})',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          // Obsah
          if (isLoading)
            _buildLoadingState()
          else if (comments.isEmpty)
            _buildEmptyState()
          else
            _buildCommentsList(),
        ],
      ),
    );
  }

  /// Sestaví stav načítání
  Widget _buildLoadingState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: CircularProgressIndicator(),
      ),
    );
  }

  /// Sestaví prázdný stav
  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text(
        'Zatím žádné komentáře',
        style: TextStyle(color: AppColors.textMuted),
      ),
    );
  }

  /// Sestaví seznam komentářů
  Widget _buildCommentsList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: comments.length,
      itemBuilder: (context, index) {
        final comment = comments[index];
        final canDelete = isAdmin || comment.authorId == userId;

        return CommentWidget(
          comment: comment,
          canDelete: canDelete,
          onDelete: () => onDelete(comment),
        );
      },
    );
  }
}
