import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/theme.dart';
import '../../providers/follow_provider.dart';

/// Tlacitko pro sledovani/odsledovani uzivatele
class FollowButton extends ConsumerStatefulWidget {
  /// ID uzivatele ke sledovani
  final String userId;

  /// Kompaktni varianta (mensi tlacitko)
  final bool compact;

  /// Callback po zmene stavu sledovani
  final void Function(bool isFollowing)? onFollowChanged;

  const FollowButton({
    super.key,
    required this.userId,
    this.compact = false,
    this.onFollowChanged,
  });

  @override
  ConsumerState<FollowButton> createState() => _FollowButtonState();
}

class _FollowButtonState extends ConsumerState<FollowButton>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _toggleFollow(bool currentlyFollowing) async {
    if (_isLoading) return;

    setState(() => _isLoading = true);
    _animationController.forward();

    try {
      final isNowFollowing =
          await ref.read(followNotifierProvider.notifier).toggleFollow(widget.userId);

      widget.onFollowChanged?.call(isNowFollowing);
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
        _animationController.reverse();
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFollowingAsync = ref.watch(isFollowingProvider(widget.userId));

    return isFollowingAsync.when(
      data: (isFollowing) => _buildButton(isFollowing),
      loading: () => _buildButton(false, isLoadingState: true),
      error: (_, _) => _buildButton(false),
    );
  }

  Widget _buildButton(bool isFollowing, {bool isLoadingState = false}) {
    final showLoading = _isLoading || isLoadingState;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        child: widget.compact
            ? _buildCompactButton(isFollowing, showLoading)
            : _buildFullButton(isFollowing, showLoading),
      ),
    );
  }

  Widget _buildFullButton(bool isFollowing, bool showLoading) {
    return SizedBox(
      height: 36,
      child: ElevatedButton(
        onPressed: showLoading ? null : () => _toggleFollow(isFollowing),
        style: ElevatedButton.styleFrom(
          backgroundColor: isFollowing ? AppColors.surface : AppColors.primary,
          foregroundColor: isFollowing ? AppColors.textPrimary : Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: isFollowing
                ? BorderSide(color: AppColors.textMuted.withAlpha(50))
                : BorderSide.none,
          ),
        ),
        child: showLoading
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: isFollowing ? AppColors.textPrimary : Colors.white,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isFollowing) ...[
                    Icon(
                      Icons.check,
                      size: 16,
                      color: AppColors.textPrimary,
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    isFollowing ? 'Sledujete' : 'Sledovat',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildCompactButton(bool isFollowing, bool showLoading) {
    return SizedBox(
      height: 32,
      child: OutlinedButton(
        onPressed: showLoading ? null : () => _toggleFollow(isFollowing),
        style: OutlinedButton.styleFrom(
          backgroundColor: isFollowing ? Colors.transparent : AppColors.primary,
          foregroundColor: isFollowing ? AppColors.textPrimary : Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          side: BorderSide(
            color: isFollowing ? AppColors.textMuted.withAlpha(80) : AppColors.primary,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        child: showLoading
            ? SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: isFollowing ? AppColors.textMuted : Colors.white,
                ),
              )
            : Text(
                isFollowing ? 'Sledujete' : 'Sledovat',
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
      ),
    );
  }
}

/// Ikonove tlacitko pro sledovani (pouziti v listech)
class FollowIconButton extends ConsumerStatefulWidget {
  final String userId;
  final double size;
  final void Function(bool isFollowing)? onFollowChanged;

  const FollowIconButton({
    super.key,
    required this.userId,
    this.size = 24,
    this.onFollowChanged,
  });

  @override
  ConsumerState<FollowIconButton> createState() => _FollowIconButtonState();
}

class _FollowIconButtonState extends ConsumerState<FollowIconButton> {
  bool _isLoading = false;

  Future<void> _toggleFollow(bool currentlyFollowing) async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final isNowFollowing =
          await ref.read(followNotifierProvider.notifier).toggleFollow(widget.userId);
      widget.onFollowChanged?.call(isNowFollowing);
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
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFollowingAsync = ref.watch(isFollowingProvider(widget.userId));

    return isFollowingAsync.when(
      data: (isFollowing) => _buildIcon(isFollowing),
      loading: () => SizedBox(
        width: widget.size,
        height: widget.size,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppColors.textMuted,
        ),
      ),
      error: (_, _) => _buildIcon(false),
    );
  }

  Widget _buildIcon(bool isFollowing) {
    if (_isLoading) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppColors.primary,
        ),
      );
    }

    return GestureDetector(
      onTap: () => _toggleFollow(isFollowing),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isFollowing ? AppColors.primary.withAlpha(20) : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          isFollowing ? Icons.person_remove : Icons.person_add,
          size: widget.size,
          color: isFollowing ? AppColors.primary : AppColors.textMuted,
        ),
      ),
    );
  }
}
