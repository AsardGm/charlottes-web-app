import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/theme.dart';
import '../../providers/follow_provider.dart';
import '../../models/follow_request_model.dart';
import '../../widgets/user_avatar.dart';

/// Obrazovka pro spravu zadosti o sledovani
class FollowRequestsScreen extends ConsumerWidget {
  const FollowRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(pendingFollowRequestsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              context.go('/');
            }
          },
        ),
        title: Text(
          'Zadosti o sledovani',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: requestsAsync.when(
        data: (requests) {
          if (requests.isEmpty) {
            return _buildEmptyState();
          }
          return _buildRequestsList(context, ref, requests);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text('Chyba: ${error.toString()}'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(pendingFollowRequestsProvider),
                child: const Text('Zkusit znovu'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person_add_disabled,
              size: 48,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Zadne zadosti',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              'Zatim nemas zadne cekajici zadosti o sledovani',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestsList(
    BuildContext context,
    WidgetRef ref,
    List<FollowRequestModel> requests,
  ) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: requests.length,
      separatorBuilder: (_, _) => Divider(
        height: 1,
        color: AppColors.textMuted.withAlpha(20),
      ),
      itemBuilder: (context, index) {
        final request = requests[index];
        return _FollowRequestTile(request: request);
      },
    );
  }
}

/// Tile pro jednotlivou zadost
class _FollowRequestTile extends ConsumerStatefulWidget {
  final FollowRequestModel request;

  const _FollowRequestTile({required this.request});

  @override
  ConsumerState<_FollowRequestTile> createState() => _FollowRequestTileState();
}

class _FollowRequestTileState extends ConsumerState<_FollowRequestTile> {
  bool _isAccepting = false;
  bool _isRejecting = false;

  Future<void> _acceptRequest() async {
    if (_isAccepting || _isRejecting) return;

    setState(() => _isAccepting = true);

    try {
      await ref
          .read(followNotifierProvider.notifier)
          .acceptFollowRequest(widget.request.requesterId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('${widget.request.requester?.username ?? 'Uzivatel'} te nyni sleduje'),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Chyba: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isAccepting = false);
      }
    }
  }

  Future<void> _rejectRequest() async {
    if (_isAccepting || _isRejecting) return;

    setState(() => _isRejecting = true);

    try {
      await ref
          .read(followNotifierProvider.notifier)
          .rejectFollowRequest(widget.request.requesterId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Zadost odmitnuta'),
            backgroundColor: AppColors.surface,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Chyba: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRejecting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final requester = widget.request.requester;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Avatar
          GestureDetector(
            onTap: () => context.push('/profile/${widget.request.requesterId}'),
            child: UserAvatar(
              imageUrl: requester?.avatarUrl,
              name: requester?.username ?? '?',
              size: 50,
            ),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: GestureDetector(
              onTap: () => context.push('/profile/${widget.request.requesterId}'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    requester?.username ?? 'Neznamy uzivatel',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatTimeAgo(widget.request.createdAt),
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Buttons
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Accept button
              SizedBox(
                width: 80,
                height: 32,
                child: ElevatedButton(
                  onPressed: (_isAccepting || _isRejecting) ? null : _acceptRequest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isAccepting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Potvrdit',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 8),

              // Reject button
              SizedBox(
                width: 80,
                height: 32,
                child: OutlinedButton(
                  onPressed: (_isAccepting || _isRejecting) ? null : _rejectRequest,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    padding: EdgeInsets.zero,
                    side: BorderSide(color: AppColors.textMuted.withAlpha(50)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isRejecting
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.textMuted,
                          ),
                        )
                      : const Text(
                          'Smazat',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'prave ted';
    } else if (difference.inMinutes < 60) {
      return 'pred ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'pred ${difference.inHours} hod';
    } else if (difference.inDays < 7) {
      return 'pred ${difference.inDays} dny';
    } else {
      return '${date.day}.${date.month}.${date.year}';
    }
  }
}
