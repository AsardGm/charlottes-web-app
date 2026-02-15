import 'dart:ui';
import 'package:flutter/material.dart';
import '../../services/haptic_service.dart';

/// iOS-style context menu that appears on long press
/// Similar to iMessage/Telegram context menus
class IOSContextMenu extends StatelessWidget {
  final Widget child;
  final List<ContextMenuAction> actions;
  final bool enableHaptic;
  final VoidCallback? onOpen;
  final VoidCallback? onClose;

  const IOSContextMenu({
    super.key,
    required this.child,
    required this.actions,
    this.enableHaptic = true,
    this.onOpen,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: (details) {
        if (enableHaptic) {
          HapticService.medium();
        }
        onOpen?.call();
        _showContextMenu(context, details.globalPosition);
      },
      child: child,
    );
  }

  void _showContextMenu(BuildContext context, Offset position) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => _ContextMenuOverlay(
        position: position,
        actions: actions,
        onDismiss: () {
          overlayEntry.remove();
          onClose?.call();
        },
      ),
    );

    overlay.insert(overlayEntry);
  }
}

class _ContextMenuOverlay extends StatefulWidget {
  final Offset position;
  final List<ContextMenuAction> actions;
  final VoidCallback onDismiss;

  const _ContextMenuOverlay({
    required this.position,
    required this.actions,
    required this.onDismiss,
  });

  @override
  State<_ContextMenuOverlay> createState() => _ContextMenuOverlayState();
}

class _ContextMenuOverlayState extends State<_ContextMenuOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleDismiss() {
    _controller.reverse().then((_) => widget.onDismiss());
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    // Calculate menu position (ensure it's visible on screen)
    double left = widget.position.dx - 100;
    double top = widget.position.dy - 100;

    if (left < 20) left = 20;
    if (left + 200 > size.width - 20) left = size.width - 220;
    if (top < 80) top = 80;
    if (top + (widget.actions.length * 60) > size.height - 80) {
      top = size.height - (widget.actions.length * 60) - 80;
    }

    return Stack(
      children: [
        // Backdrop with blur
        Positioned.fill(
          child: GestureDetector(
            onTap: _handleDismiss,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.3),
                ),
              ),
            ),
          ),
        ),

        // Context menu
        Positioned(
          left: left,
          top: top,
          child: ScaleTransition(
            scale: _scaleAnimation,
            alignment: Alignment.center,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: _ContextMenuCard(
                actions: widget.actions,
                onActionTap: (action) {
                  _handleDismiss();
                  action.onTap();
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ContextMenuCard extends StatelessWidget {
  final List<ContextMenuAction> actions;
  final Function(ContextMenuAction) onActionTap;

  const _ContextMenuCard({
    required this.actions,
    required this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final borderColor = Theme.of(context).dividerTheme.color ?? Theme.of(context).colorScheme.outline;

    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: surfaceColor.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < actions.length; i++) ...[
              _ContextMenuActionButton(
                action: actions[i],
                onTap: () => onActionTap(actions[i]),
              ),
              if (i < actions.length - 1)
                Divider(
                  height: 1,
                  thickness: 1,
                  color: borderColor.withValues(alpha: 0.3),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ContextMenuActionButton extends StatefulWidget {
  final ContextMenuAction action;
  final VoidCallback onTap;

  const _ContextMenuActionButton({
    required this.action,
    required this.onTap,
  });

  @override
  State<_ContextMenuActionButton> createState() =>
      _ContextMenuActionButtonState();
}

class _ContextMenuActionButtonState extends State<_ContextMenuActionButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final secondaryColor = Theme.of(context).textTheme.bodyMedium?.color ?? textColor.withValues(alpha: 0.7);

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: () {
        HapticService.light();
        widget.onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        color: _isPressed
            ? primaryColor.withValues(alpha: 0.15)
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Icon
            Icon(
              widget.action.icon,
              size: 20,
              color: widget.action.isDestructive
                  ? Colors.red
                  : widget.action.color ?? textColor,
            ),
            const SizedBox(width: 12),

            // Label
            Expanded(
              child: Text(
                widget.action.label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: widget.action.isDestructive
                      ? Colors.red
                      : widget.action.color ?? textColor,
                ),
              ),
            ),

            // Trailing icon (for submenu, etc.)
            if (widget.action.trailingIcon != null) ...[
              const SizedBox(width: 8),
              Icon(
                widget.action.trailingIcon,
                size: 16,
                color: secondaryColor.withValues(alpha: 0.6),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Context menu action definition
class ContextMenuAction {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;
  final bool isDestructive;
  final IconData? trailingIcon;
  final bool enabled;

  const ContextMenuAction({
    required this.label,
    required this.icon,
    required this.onTap,
    this.color,
    this.isDestructive = false,
    this.trailingIcon,
    this.enabled = true,
  });
}
