import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/theme.dart';

/// Moderní chip pro výběr typu vlákna
///
/// Obsahuje animace, haptic feedback a různé styly zobrazení.
class ThreadTypeChip extends StatefulWidget {
  /// Textový popisek (název typu)
  final String label;

  /// Emoji ikona typu
  final String emoji;

  /// Barva typu (použitá pro zvýraznění)
  final Color color;

  /// Je tento typ aktuálně vybrán?
  final bool isSelected;

  /// Callback při kliknutí
  final VoidCallback onTap;

  /// Styl chipu
  final ThreadChipStyle style;

  /// Zobrazit počet (badge)
  final int? count;

  /// Kompaktní verze
  final bool compact;

  const ThreadTypeChip({
    super.key,
    required this.label,
    required this.emoji,
    required this.color,
    required this.isSelected,
    required this.onTap,
    this.style = ThreadChipStyle.modern,
    this.count,
    this.compact = false,
  });

  @override
  State<ThreadTypeChip> createState() => _ThreadTypeChipState();
}

class _ThreadTypeChipState extends State<ThreadTypeChip>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _controller.reverse();
    HapticFeedback.lightImpact();
    widget.onTap();
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: _buildChip(),
          );
        },
      ),
    );
  }

  Widget _buildChip() {
    switch (widget.style) {
      case ThreadChipStyle.modern:
        return _buildModernChip();
      case ThreadChipStyle.pill:
        return _buildPillChip();
      case ThreadChipStyle.card:
        return _buildCardChip();
      case ThreadChipStyle.minimal:
        return _buildMinimalChip();
      case ThreadChipStyle.neon:
        return _buildNeonChip();
    }
  }

  Widget _buildModernChip() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.symmetric(
        horizontal: widget.compact ? 12 : 16,
        vertical: widget.compact ? 8 : 10,
      ),
      decoration: BoxDecoration(
        gradient: widget.isSelected
            ? LinearGradient(
                colors: [
                  widget.color.withAlpha(50),
                  widget.color.withAlpha(25),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : LinearGradient(
                colors: [
                  AppColors.surface,
                  AppColors.surfaceLight.withAlpha(150),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: BorderRadius.circular(widget.compact ? 16 : 24),
        border: Border.all(
          color: widget.isSelected
              ? widget.color.withAlpha(180)
              : _isPressed
                  ? widget.color.withAlpha(60)
                  : Colors.white.withAlpha(10),
          width: widget.isSelected ? 1.5 : 1,
        ),
        boxShadow: [
          if (widget.isSelected)
            BoxShadow(
              color: widget.color.withAlpha(40),
              blurRadius: 12,
              offset: const Offset(0, 4),
              spreadRadius: -2,
            ),
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: _buildContent(),
    );
  }

  Widget _buildPillChip() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.symmetric(
        horizontal: widget.compact ? 14 : 18,
        vertical: widget.compact ? 8 : 12,
      ),
      decoration: BoxDecoration(
        color: widget.isSelected ? widget.color : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(50),
        boxShadow: widget.isSelected
            ? [
                BoxShadow(
                  color: widget.color.withAlpha(60),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.emoji,
            style: TextStyle(
              fontSize: widget.compact ? 14 : 16,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            widget.label,
            style: TextStyle(
              fontSize: widget.compact ? 12 : 13,
              fontWeight: FontWeight.w600,
              color: widget.isSelected ? Colors.white : AppColors.textSecondary,
            ),
          ),
          if (widget.count != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: widget.isSelected
                    ? Colors.white.withAlpha(40)
                    : widget.color.withAlpha(30),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                widget.count.toString(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: widget.isSelected ? Colors.white : widget.color,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCardChip() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      width: widget.compact ? 80 : 100,
      padding: EdgeInsets.all(widget.compact ? 10 : 14),
      decoration: BoxDecoration(
        color: widget.isSelected
            ? widget.color.withAlpha(20)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.isSelected
              ? widget.color.withAlpha(100)
              : Colors.white.withAlpha(8),
          width: 1.5,
        ),
        boxShadow: widget.isSelected
            ? [
                BoxShadow(
                  color: widget.color.withAlpha(30),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: widget.color.withAlpha(widget.isSelected ? 40 : 20),
              shape: BoxShape.circle,
            ),
            child: Text(
              widget.emoji,
              style: TextStyle(fontSize: widget.compact ? 18 : 22),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.label,
            style: TextStyle(
              fontSize: widget.compact ? 11 : 12,
              fontWeight: widget.isSelected ? FontWeight.w700 : FontWeight.w500,
              color: widget.isSelected ? widget.color : AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (widget.count != null) ...[
            const SizedBox(height: 4),
            Text(
              widget.count.toString(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMinimalChip() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: EdgeInsets.symmetric(
        horizontal: widget.compact ? 10 : 14,
        vertical: widget.compact ? 6 : 8,
      ),
      decoration: BoxDecoration(
        color: widget.isSelected
            ? widget.color.withAlpha(15)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: widget.isSelected
              ? widget.color.withAlpha(60)
              : Colors.transparent,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.emoji,
            style: TextStyle(fontSize: widget.compact ? 12 : 14),
          ),
          const SizedBox(width: 6),
          Text(
            widget.label,
            style: TextStyle(
              fontSize: widget.compact ? 12 : 13,
              fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.w400,
              color: widget.isSelected ? widget.color : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNeonChip() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.symmetric(
        horizontal: widget.compact ? 14 : 18,
        vertical: widget.compact ? 10 : 12,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(widget.compact ? 12 : 16),
        border: Border.all(
          color: widget.isSelected
              ? widget.color
              : AppColors.textMuted.withAlpha(30),
          width: widget.isSelected ? 2 : 1,
        ),
        boxShadow: widget.isSelected
            ? [
                BoxShadow(
                  color: widget.color.withAlpha(80),
                  blurRadius: 16,
                  spreadRadius: -4,
                ),
                BoxShadow(
                  color: widget.color.withAlpha(40),
                  blurRadius: 8,
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: widget.isSelected
                  ? widget.color.withAlpha(30)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              widget.emoji,
              style: TextStyle(
                fontSize: widget.compact ? 14 : 16,
                shadows: widget.isSelected
                    ? [
                        Shadow(
                          color: widget.color,
                          blurRadius: 12,
                        ),
                      ]
                    : null,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            widget.label,
            style: TextStyle(
              fontSize: widget.compact ? 12 : 14,
              fontWeight: widget.isSelected ? FontWeight.w700 : FontWeight.w500,
              color: widget.isSelected ? widget.color : AppColors.textSecondary,
              shadows: widget.isSelected
                  ? [
                      Shadow(
                        color: widget.color.withAlpha(100),
                        blurRadius: 8,
                      ),
                    ]
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Emoji s animovaným pozadím
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.all(widget.isSelected ? 4 : 2),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? widget.color.withAlpha(30)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            widget.emoji,
            style: TextStyle(
              fontSize: widget.compact ? 14 : 16,
              shadows: widget.isSelected
                  ? [Shadow(color: widget.color.withAlpha(100), blurRadius: 8)]
                  : null,
            ),
          ),
        ),
        SizedBox(width: widget.compact ? 6 : 10),

        // Název typu s animací
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: TextStyle(
            fontSize: widget.compact ? 12 : 13,
            fontWeight: widget.isSelected ? FontWeight.w700 : FontWeight.w500,
            color: widget.isSelected ? widget.color : AppColors.textSecondary,
            letterSpacing: widget.isSelected ? 0.3 : 0,
          ),
          child: Text(widget.label),
        ),

        // Badge s počtem
        if (widget.count != null) ...[
          const SizedBox(width: 8),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: widget.isSelected
                  ? widget.color.withAlpha(40)
                  : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              _formatCount(widget.count!),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: widget.isSelected ? widget.color : AppColors.textMuted,
              ),
            ),
          ),
        ],
      ],
    );
  }

  String _formatCount(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}k';
    }
    return count.toString();
  }
}

/// Styly thread type chipu
enum ThreadChipStyle {
  /// Moderní gradient (výchozí)
  modern,

  /// Pill shape s plnou barvou
  pill,

  /// Vertikální karta
  card,

  /// Minimalistický
  minimal,

  /// Neon efekt
  neon,
}

/// Badge pro počet příspěvků určitého typu
class ThreadTypeBadge extends StatelessWidget {
  final int count;
  final Color color;
  final bool small;

  const ThreadTypeBadge({
    super.key,
    required this.count,
    required this.color,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 4 : 6,
        vertical: small ? 1 : 2,
      ),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(small ? 6 : 8),
        border: Border.all(
          color: color.withAlpha(50),
          width: 1,
        ),
      ),
      child: Text(
        _formatCount(count),
        style: TextStyle(
          fontSize: small ? 9 : 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    }
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}
