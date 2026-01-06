import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/post_model.dart';
import '../providers/auth_provider.dart';
import '../providers/posts_provider.dart';
import '../services/share_service.dart';
import '../services/report_service.dart';
import '../utils/helpers.dart';
import '../utils/haptic_utils.dart';
import '../theme/theme.dart';
import 'user_avatar.dart';
import 'common/mention_text_field.dart';
import 'report_dialog.dart';

/// Post karta s Functional Dark designem
class PostCard extends ConsumerStatefulWidget {
  final PostModel post;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const PostCard({
    super.key,
    required this.post,
    this.onTap,
    this.onDelete,
  });

  @override
  ConsumerState<PostCard> createState() => _PostCardState();
}

class _PostCardState extends ConsumerState<PostCard> {
  late PostModel _post;

  @override
  void initState() {
    super.initState();
    _post = widget.post;
  }

  @override
  void didUpdateWidget(PostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.post != widget.post) {
      _post = widget.post;
    }
  }

  Future<void> _handleReaction(String type) async {
    final userId = ref.read(authServiceProvider).currentUser?.id;
    if (userId == null) return;

    HapticUtils.lightImpact();

    try {
      await ref.read(reactionServiceProvider).toggleReaction(
            postId: _post.id,
            type: type,
          );

      final updatedPost = await ref.read(postServiceProvider).getPost(_post.id);
      if (updatedPost != null && mounted) {
        setState(() => _post = updatedPost);
        ref.read(postsProvider.notifier).updatePostLocally(updatedPost);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Chyba: ${e.toString()}'),
            backgroundColor: AppColors.functionalSurface,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final userId = ref.read(authServiceProvider).currentUser?.id;
    final isAdmin = currentUser.value?.isAdmin ?? false;
    final isOwner = _post.authorId == userId;
    final canDelete = isAdmin || isOwner;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.functionalSurface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header - Avatar, jmeno, cas
                _buildHeader(canDelete: canDelete, isOwner: isOwner),

                const SizedBox(height: 12),

                // Content
                MentionText(
                  text: _post.content,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: Colors.white,
                  ),
                  maxLines: 6,
                  overflow: TextOverflow.ellipsis,
                  onMentionTap: (username) => _navigateToUserProfile(username),
                  onHashtagTap: (hashtag) => _navigateToHashtag(hashtag),
                ),

                // Image
                if (_post.imageUrl != null) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: _post.imageUrl!,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        height: 180,
                        color: AppColors.functionalBorder,
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.accent,
                            strokeWidth: 2,
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        height: 180,
                        color: AppColors.functionalBorder,
                        child: Icon(
                          Icons.broken_image_outlined,
                          color: AppColors.functionalMuted,
                          size: 40,
                        ),
                      ),
                    ),
                  ),
                ],

                // Divider
                Container(
                  margin: const EdgeInsets.only(top: 16),
                  height: 1,
                  color: AppColors.functionalBorder,
                ),

                // Actions
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: _buildActions(userId),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Header s avatarem a info
  Widget _buildHeader({required bool canDelete, required bool isOwner}) {
    return Row(
      children: [
        // Avatar - kliknutím na profil
        GestureDetector(
          onTap: () => context.push('/profile/${_post.authorId}'),
          child: UserAvatar(
            imageUrl: _post.author?.avatarUrl,
            name: _post.author?.username ?? 'Uzivatel',
            size: 40,
          ),
        ),
        const SizedBox(width: 12),
        // Info - kliknutím na profil
        Expanded(
          child: GestureDetector(
            onTap: () => context.push('/profile/${_post.authorId}'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        _post.author?.username ?? 'Uzivatel',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (_post.author?.isAdmin ?? false) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withAlpha(30),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: AppColors.accent.withAlpha(100),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          'ADMIN',
                          style: TextStyle(
                            color: AppColors.accent,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  Helpers.formatTimeAgo(_post.createdAt),
                  style: TextStyle(
                    color: AppColors.functionalMuted,
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        ),
        // Menu - vzdy zobrazeno
        PopupMenuButton(
          icon: Icon(
            Icons.more_horiz,
            color: AppColors.functionalMuted,
            size: 20,
          ),
          color: AppColors.functionalSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          itemBuilder: (context) => [
            // Nahlasit - pro vsechny krome vlastnika
            if (!isOwner)
              PopupMenuItem(
                value: 'report',
                child: Row(
                  children: [
                    Icon(Icons.flag_outlined, color: AppColors.functionalMuted, size: 18),
                    const SizedBox(width: 10),
                    Text('Nahlasit', style: TextStyle(color: AppColors.textPrimary)),
                  ],
                ),
              ),
            // Smazat - pouze pro vlastnika nebo admina
            if (canDelete)
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: AppColors.error, size: 18),
                    const SizedBox(width: 10),
                    Text('Smazat', style: TextStyle(color: AppColors.error)),
                  ],
                ),
              ),
          ],
          onSelected: (value) {
            if (value == 'delete') {
              _showDeleteDialog();
            } else if (value == 'report') {
              _showReportDialog();
            }
          },
        ),
      ],
    );
  }

  /// Action bar
  Widget _buildActions(String? userId) {
    return Row(
      children: [
        // Comments
        _ActionButton(
          icon: Icons.chat_bubble_outline,
          label: '${_post.commentCount}',
          onTap: widget.onTap,
        ),
        const SizedBox(width: 16),
        // Share
        _ActionButton(
          icon: Icons.share_outlined,
          onTap: () {
            HapticUtils.lightImpact();
            ShareService.sharePost(_post);
          },
        ),
        const Spacer(),
        // Like
        _LikeButton(
          isLiked: userId != null && _post.getUserReactionType(userId) == 'like',
          count: _post.totalReactions,
          onTap: () => _handleReaction('like'),
        ),
      ],
    );
  }

  void _navigateToUserProfile(String username) {
    context.push('/search?q=@$username');
  }

  void _navigateToHashtag(String hashtag) {
    context.push('/search?q=%23$hashtag');
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.functionalSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          'Smazat prispevek?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Tato akce je nevratna.',
          style: TextStyle(color: AppColors.functionalMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Zrusit',
              style: TextStyle(color: AppColors.functionalMuted),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onDelete?.call();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Smazat'),
          ),
        ],
      ),
    );
  }

  void _showReportDialog() {
    ReportDialog.show(
      context: context,
      contentType: ReportContentType.post,
      contentId: _post.id,
      contentPreview: _post.content.length > 100
          ? '${_post.content.substring(0, 100)}...'
          : _post.content,
    );
  }
}

/// Action button
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String? label;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: AppColors.functionalMuted,
            ),
            if (label != null) ...[
              const SizedBox(width: 6),
              Text(
                label!,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.functionalMuted,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Like button
class _LikeButton extends StatelessWidget {
  final bool isLiked;
  final int count;
  final VoidCallback onTap;

  const _LikeButton({
    required this.isLiked,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isLiked
              ? AppColors.accent.withAlpha(25)
              : AppColors.functionalBorder.withAlpha(100),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isLiked ? AppColors.accent : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
              size: 16,
              color: isLiked ? AppColors.accent : AppColors.functionalMuted,
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isLiked ? AppColors.accent : AppColors.functionalMuted,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
