import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/theme.dart';
import '../../providers/follow_provider.dart';
import '../../services/follow_service.dart';

/// Tlacitko pro sledovani/odsledovani uzivatele s podporou soukromych uctu
class FollowButton extends ConsumerStatefulWidget {
  /// ID uzivatele ke sledovani
  final String userId;

  /// Kompaktni varianta (mensi tlacitko)
  final bool compact;

  /// Callback po zmene stavu sledovani
  final void Function(FollowStatus status)? onStatusChanged;

  const FollowButton({
    super.key,
    required this.userId,
    this.compact = false,
    this.onStatusChanged,
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

  Future<void> _toggleFollow(FollowStatus currentStatus) async {
    if (_isLoading) return;

    setState(() => _isLoading = true);
    _animationController.forward();

    try {
      final newStatus = await ref
          .read(followNotifierProvider.notifier)
          .toggleFollowOrRequest(widget.userId);

      widget.onStatusChanged?.call(newStatus);
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
    final statusAsync = ref.watch(followStatusProvider(widget.userId));

    return statusAsync.when(
      data: (status) => _buildButton(status),
      loading: () => _buildButton(FollowStatus.notFollowing, isLoadingState: true),
      error: (_, _) => _buildButton(FollowStatus.notFollowing),
    );
  }

  Widget _buildButton(FollowStatus status, {bool isLoadingState = false}) {
    final showLoading = _isLoading || isLoadingState;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        child: widget.compact
            ? _buildCompactButton(status, showLoading)
            : _buildFullButton(status, showLoading),
      ),
    );
  }

  Widget _buildFullButton(FollowStatus status, bool showLoading) {
    final (backgroundColor, foregroundColor, borderSide, text, icon) = _getButtonStyle(status);

    return SizedBox(
      height: 36,
      child: ElevatedButton(
        onPressed: showLoading ? null : () => _toggleFollow(status),
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: borderSide,
          ),
        ),
        child: showLoading
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: foregroundColor,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 16, color: foregroundColor),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    text,
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

  Widget _buildCompactButton(FollowStatus status, bool showLoading) {
    final (backgroundColor, foregroundColor, borderSide, text, _) = _getButtonStyle(status);

    return SizedBox(
      height: 32,
      child: OutlinedButton(
        onPressed: showLoading ? null : () => _toggleFollow(status),
        style: OutlinedButton.styleFrom(
          backgroundColor: status == FollowStatus.notFollowing
              ? AppColors.primary
              : Colors.transparent,
          foregroundColor: foregroundColor,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          side: borderSide,
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
                  color: foregroundColor,
                ),
              )
            : Text(
                text,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
      ),
    );
  }

  /// Vrací styl tlačítka podle stavu
  (Color, Color, BorderSide, String, IconData?) _getButtonStyle(FollowStatus status) {
    switch (status) {
      case FollowStatus.following:
        return (
          AppColors.surface,
          AppColors.textPrimary,
          BorderSide(color: AppColors.textMuted.withAlpha(50)),
          'Sledujete',
          Icons.check,
        );
      case FollowStatus.requested:
        return (
          AppColors.surface,
          AppColors.textSecondary,
          BorderSide(color: AppColors.textMuted.withAlpha(50)),
          'Pozadano',
          Icons.schedule,
        );
      case FollowStatus.notFollowing:
        return (
          AppColors.primary,
          Colors.white,
          BorderSide.none,
          'Sledovat',
          null,
        );
    }
  }
}

/// Ikonove tlacitko pro sledovani (pouziti v listech)
class FollowIconButton extends ConsumerStatefulWidget {
  final String userId;
  final double size;
  final void Function(FollowStatus status)? onStatusChanged;

  const FollowIconButton({
    super.key,
    required this.userId,
    this.size = 24,
    this.onStatusChanged,
  });

  @override
  ConsumerState<FollowIconButton> createState() => _FollowIconButtonState();
}

class _FollowIconButtonState extends ConsumerState<FollowIconButton> {
  bool _isLoading = false;

  Future<void> _toggleFollow(FollowStatus currentStatus) async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final newStatus = await ref
          .read(followNotifierProvider.notifier)
          .toggleFollowOrRequest(widget.userId);
      widget.onStatusChanged?.call(newStatus);
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
    final statusAsync = ref.watch(followStatusProvider(widget.userId));

    return statusAsync.when(
      data: (status) => _buildIcon(status),
      loading: () => SizedBox(
        width: widget.size,
        height: widget.size,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppColors.textMuted,
        ),
      ),
      error: (_, _) => _buildIcon(FollowStatus.notFollowing),
    );
  }

  Widget _buildIcon(FollowStatus status) {
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

    final (icon, color) = _getIconStyle(status);

    return GestureDetector(
      onTap: () => _toggleFollow(status),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: status == FollowStatus.following
              ? AppColors.primary.withAlpha(20)
              : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: widget.size,
          color: color,
        ),
      ),
    );
  }

  (IconData, Color) _getIconStyle(FollowStatus status) {
    switch (status) {
      case FollowStatus.following:
        return (Icons.person_remove, AppColors.primary);
      case FollowStatus.requested:
        return (Icons.schedule, AppColors.textMuted);
      case FollowStatus.notFollowing:
        return (Icons.person_add, AppColors.textMuted);
    }
  }
}
