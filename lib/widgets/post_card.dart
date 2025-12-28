import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/post_model.dart';
import '../providers/auth_provider.dart';
import '../providers/posts_provider.dart';
import '../utils/helpers.dart';
import '../theme/theme.dart';
import 'user_avatar.dart';

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

    try {
      await ref.read(reactionServiceProvider).toggleReaction(
            postId: _post.id,
            type: type,
          );

      // Refresh post data
      final updatedPost = await ref.read(postServiceProvider).getPost(_post.id);
      if (updatedPost != null && mounted) {
        setState(() => _post = updatedPost);
        ref.read(postsProvider.notifier).updatePostLocally(updatedPost);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Chyba: ${e.toString()}')),
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
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withAlpha(8),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(40),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
                child: Row(
                  children: [
                    // Avatar with gradient border
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: (_post.author?.isAdmin ?? false)
                            ? AppColors.primaryGradient
                            : null,
                        border: (_post.author?.isAdmin ?? false)
                            ? null
                            : Border.all(color: AppColors.surfaceLight, width: 2),
                      ),
                      child: UserAvatar(
                        imageUrl: _post.author?.avatarUrl,
                        name: _post.author?.username ?? 'Uzivatel',
                        size: 40,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  _post.author?.username ?? 'Uzivatel',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                    color: AppColors.textPrimary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (_post.author?.isAdmin ?? false) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: AppColors.primaryGradient,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'ADMIN',
                                    style: TextStyle(
                                      color: Colors.white,
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
                              color: AppColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (canDelete)
                      PopupMenuButton(
                        icon: Icon(Icons.more_horiz, color: AppColors.textMuted, size: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                                const SizedBox(width: 12),
                                Text('Smazat', style: TextStyle(color: AppColors.error)),
                              ],
                            ),
                          ),
                        ],
                        onSelected: (value) {
                          if (value == 'delete') {
                            _showDeleteDialog();
                          }
                        },
                      ),
                  ],
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Text(
                  _post.content,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.4,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 6,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Image
              if (_post.imageUrl != null) ...[
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: _post.imageUrl!,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                            strokeWidth: 2,
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.broken_image_outlined,
                          color: AppColors.textMuted, size: 40),
                      ),
                    ),
                  ),
                ),
              ],

              // Stats & Actions
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Row(
                  children: [
                    // Comments count
                    _StatBadge(
                      icon: Icons.chat_bubble_outline,
                      count: _post.commentCount,
                      label: 'komentaru',
                    ),
                    const Spacer(),
                    // Quick like button
                    _QuickReactionButton(
                      isLiked: userId != null && _post.getUserReactionType(userId) == 'like',
                      count: _post.totalReactions,
                      onTap: () => _handleReaction('like'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Smazat prispevek?'),
        content: const Text('Tato akce je nevratna.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Zrusit'),
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
}

/// Stat badge widget pro zobrazení počtu komentářů atd.
class _StatBadge extends StatelessWidget {
  final IconData icon;
  final int count;
  final String label;

  const _StatBadge({
    required this.icon,
    required this.count,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: AppColors.textMuted),
        const SizedBox(width: 6),
        Text(
          '$count $label',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// Quick reaction button (like)
class _QuickReactionButton extends StatelessWidget {
  final bool isLiked;
  final int count;
  final VoidCallback onTap;

  const _QuickReactionButton({
    required this.isLiked,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isLiked
                ? AppColors.primary.withAlpha(25)
                : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isLiked
                  ? AppColors.primary.withAlpha(100)
                  : Colors.white.withAlpha(10),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                size: 18,
                color: isLiked ? AppColors.primary : AppColors.textMuted,
              ),
              if (count > 0) ...[
                const SizedBox(width: 6),
                Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isLiked ? AppColors.primary : AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
