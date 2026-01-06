import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/comment_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/posts_provider.dart';
import '../../services/comment_service.dart';
import '../../services/content_moderation_service.dart';
import '../../theme/theme.dart';
import '../../widgets/post_card.dart';
import '../../widgets/post_detail/post_detail.dart';

/// Obrazovka detailu příspěvku
///
/// Zobrazuje příspěvek s kompletními informacemi,
/// seznam komentářů a možnost přidat nový komentář.
class PostDetailScreen extends ConsumerStatefulWidget {
  /// ID příspěvku k zobrazení
  final String postId;

  const PostDetailScreen({
    super.key,
    required this.postId,
  });

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  /// Controller pro textové pole komentáře
  final _commentController = TextEditingController();

  /// Služba pro práci s komentáři
  final _commentService = CommentService();

  /// Seznam komentářů
  List<CommentModel> _comments = [];

  /// Načítají se komentáře?
  bool _isLoadingComments = true;

  /// Odesílá se komentář?
  bool _isPostingComment = false;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  /// Načte komentáře k příspěvku
  Future<void> _loadComments() async {
    try {
      final comments = await _commentService.getComments(widget.postId);
      if (mounted) {
        setState(() {
          _comments = comments;
          _isLoadingComments = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingComments = false);
      }
    }
  }

  /// Zobrazí dialog o zablokovaném obsahu
  void _showContentBlockedDialog(String message, List<String> blockedWords) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.functionalSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Komentar nelze odeslat',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: TextStyle(color: AppColors.functionalMuted, fontSize: 14),
            ),
            if (blockedWords.isNotEmpty) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: blockedWords.map((word) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.withAlpha(50),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withAlpha(100)),
                  ),
                  child: Text(
                    word,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                )).toList(),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Rozumim', style: TextStyle(color: AppColors.accent)),
          ),
        ],
      ),
    );
  }

  /// Odešle nový komentář
  Future<void> _postComment() async {
    if (_commentController.text.trim().isEmpty) return;

    setState(() => _isPostingComment = true);

    try {
      final comment = await _commentService.addComment(
        postId: widget.postId,
        content: _commentController.text.trim(),
      );

      setState(() {
        _comments.add(comment);
        _commentController.clear();
      });

      // Aktualizovat příspěvek (počet komentářů)
      ref.invalidate(singlePostProvider(widget.postId));
    } on ContentBlockedException catch (e) {
      if (mounted) {
        _showContentBlockedDialog(e.message, e.blockedWords);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Chyba: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPostingComment = false);
      }
    }
  }

  /// Smaže komentář
  Future<void> _deleteComment(CommentModel comment) async {
    try {
      await _commentService.deleteComment(comment.id);
      setState(() {
        _comments.removeWhere((c) => c.id == comment.id);
      });
      // Aktualizovat příspěvek (počet komentářů)
      ref.invalidate(singlePostProvider(widget.postId));
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
    // Sledované stavy
    final postAsync = ref.watch(singlePostProvider(widget.postId));
    final currentUser = ref.watch(currentUserProvider);
    final userId = ref.read(authServiceProvider).currentUser?.id;
    final isAdmin = currentUser.value?.isAdmin ?? false;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        title: const Text('Příspěvek'),
      ),
      body: postAsync.when(
        data: (post) {
          // Příspěvek nenalezen
          if (post == null) {
            return const Center(
              child: Text('Příspěvek nenalezen'),
            );
          }

          return Column(
            children: [
              // === Hlavní obsah ===
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Karta příspěvku
                      PostCard(
                        post: post,
                        onDelete: () async {
                          await ref
                              .read(postsProvider.notifier)
                              .deletePost(post.id);
                          if (!mounted) return;
                          context.go('/');
                        },
                      ),
                      const Divider(),

                      // Sekce komentářů
                      CommentsSection(
                        comments: _comments,
                        isLoading: _isLoadingComments,
                        userId: userId,
                        isAdmin: isAdmin,
                        onDelete: _deleteComment,
                      ),

                      // Mezera pro vstupní pole
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),

              // === Vstupní pole komentáře ===
              CommentInput(
                controller: _commentController,
                isPosting: _isPostingComment,
                onPost: _postComment,
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text('Chyba: ${error.toString()}'),
        ),
      ),
    );
  }
}
