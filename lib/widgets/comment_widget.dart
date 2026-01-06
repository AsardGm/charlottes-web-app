import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/comment_model.dart';
import '../services/report_service.dart';
import '../utils/helpers.dart';
import 'user_avatar.dart';
import 'report_dialog.dart';

class CommentWidget extends StatelessWidget {
  final CommentModel comment;
  final bool canDelete;
  final bool isOwner;
  final VoidCallback? onDelete;

  const CommentWidget({
    super.key,
    required this.comment,
    this.canDelete = false,
    this.isOwner = false,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar - kliknutím na profil
          GestureDetector(
            onTap: () => context.push('/profile/${comment.authorId}'),
            child: UserAvatar(
              imageUrl: comment.author?.avatarUrl,
              name: comment.author?.username ?? 'Uzivatel',
              size: 32,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.withAlpha(25),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // Jméno - kliknutím na profil
                          GestureDetector(
                            onTap: () => context.push('/profile/${comment.authorId}'),
                            child: Text(
                              comment.author?.username ?? 'Uzivatel',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          if (comment.author?.isAdmin ?? false) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Admin',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        comment.content,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      Helpers.formatTimeAgo(comment.createdAt),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                    // Nahlasit - pouze pro cizi komentare
                    if (!isOwner) ...[
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () => _showReportDialog(context),
                        child: Text(
                          'Nahlasit',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                    // Smazat - pouze pro vlastnika nebo admina
                    if (canDelete) ...[
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: onDelete,
                        child: Text(
                          'Smazat',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.red[400],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showReportDialog(BuildContext context) {
    ReportDialog.show(
      context: context,
      contentType: ReportContentType.comment,
      contentId: comment.id,
      contentPreview: comment.content.length > 100
          ? '${comment.content.substring(0, 100)}...'
          : comment.content,
    );
  }
}
