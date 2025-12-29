import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../theme/theme.dart';

/// Styl reputacniho badge
enum ReputationStyle {
  /// Jednoduchy s cislem
  simple,

  /// S ikonou pavuciny
  web,

  /// Animovany
  animated,

  /// Kompaktni (jen cislo)
  compact,
}

/// Badge zobrazujici reputaci uzivatele (pavoici vlakna)
class ReputationBadge extends StatefulWidget {
  /// Pocet vlaken (lajku)
  final int webs;

  /// Styl badge
  final ReputationStyle style;

  /// Velikost
  final double size;

  /// Zobrazit popisek?
  final bool showLabel;

  /// Callback pri kliknuti
  final VoidCallback? onTap;

  const ReputationBadge({
    super.key,
    required this.webs,
    this.style = ReputationStyle.web,
    this.size = 40,
    this.showLabel = true,
    this.onTap,
  });

  @override
  State<ReputationBadge> createState() => _ReputationBadgeState();
}

class _ReputationBadgeState extends State<ReputationBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.style == ReputationStyle.animated) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    switch (widget.style) {
      case ReputationStyle.simple:
        return _buildSimple();
      case ReputationStyle.web:
        return _buildWeb();
      case ReputationStyle.animated:
        return _buildAnimated();
      case ReputationStyle.compact:
        return _buildCompact();
    }
  }

  Widget _buildSimple() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.favorite,
          size: widget.size * 0.5,
          color: _getColor(),
        ),
        const SizedBox(width: 4),
        Text(
          _formatNumber(widget.webs),
          style: TextStyle(
            fontSize: widget.size * 0.4,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        if (widget.showLabel) ...[
          const SizedBox(width: 4),
          Text(
            'vlaken',
            style: TextStyle(
              fontSize: widget.size * 0.3,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildWeb() {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _getColor().withAlpha(50),
            _getColor().withAlpha(100),
          ],
        ),
        border: Border.all(
          color: _getColor(),
          width: 2,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Pavucina na pozadi
          CustomPaint(
            size: Size(widget.size * 0.8, widget.size * 0.8),
            painter: _MiniWebPainter(color: _getColor().withAlpha(80)),
          ),
          // Cislo
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _formatNumber(widget.webs),
                style: TextStyle(
                  fontSize: widget.size * 0.3,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              if (widget.showLabel)
                Text(
                  '🕸️',
                  style: TextStyle(fontSize: widget.size * 0.2),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnimated() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: _buildWeb(),
        );
      },
    );
  }

  Widget _buildCompact() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getColor().withAlpha(30),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getColor().withAlpha(100),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('🕸️', style: TextStyle(fontSize: widget.size * 0.3)),
          const SizedBox(width: 4),
          Text(
            _formatNumber(widget.webs),
            style: TextStyle(
              fontSize: widget.size * 0.3,
              fontWeight: FontWeight.w600,
              color: _getColor(),
            ),
          ),
        ],
      ),
    );
  }

  Color _getColor() {
    // Barva podle poctu vlaken
    if (widget.webs >= 10000) return const Color(0xFFFFD700); // Zlata
    if (widget.webs >= 5000) return const Color(0xFFE53935); // Cervena
    if (widget.webs >= 1000) return const Color(0xFFBA68C8); // Fialova
    if (widget.webs >= 500) return const Color(0xFF64B5F6); // Modra
    if (widget.webs >= 100) return const Color(0xFF81C784); // Zelena
    return AppColors.textMuted; // Seda
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    }
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}

/// Mini pavucina painter
class _MiniWebPainter extends CustomPainter {
  final Color color;

  _MiniWebPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Paprsky
    for (int i = 0; i < 8; i++) {
      final angle = (i / 8) * 2 * math.pi;
      final endX = center.dx + radius * math.cos(angle);
      final endY = center.dy + radius * math.sin(angle);
      canvas.drawLine(center, Offset(endX, endY), paint);
    }

    // Kruznice
    for (int i = 1; i <= 2; i++) {
      canvas.drawCircle(center, radius * i / 3, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Widget pro zobrazeni reputacnich statistik
class ReputationStats extends StatelessWidget {
  final int webs;
  final int givenWebs;
  final int receivedToday;
  final VoidCallback? onDetailsTap;

  const ReputationStats({
    super.key,
    required this.webs,
    this.givenWebs = 0,
    this.receivedToday = 0,
    this.onDetailsTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Column(
        children: [
          // Hlavni reputace
          Row(
            children: [
              ReputationBadge(
                webs: webs,
                style: ReputationStyle.animated,
                size: 60,
                showLabel: false,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pavoici vlakna',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getReputationTitle(webs),
                      style: TextStyle(
                        fontSize: 13,
                        color: _getReputationColor(webs),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),

          // Statistiky
          Row(
            children: [
              _buildStat('Prijato', webs, Icons.arrow_downward),
              const SizedBox(width: 16),
              _buildStat('Dano', givenWebs, Icons.arrow_upward),
              const SizedBox(width: 16),
              _buildStat('Dnes', receivedToday, Icons.today),
            ],
          ),

          if (onDetailsTap != null) ...[
            const SizedBox(height: 16),
            TextButton(
              onPressed: onDetailsTap,
              child: Text(
                'Zobrazit historii',
                style: TextStyle(color: AppColors.primary),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStat(String label, int value, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 18, color: AppColors.textMuted),
          const SizedBox(height: 4),
          Text(
            _formatNumber(value),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    }
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  String _getReputationTitle(int webs) {
    if (webs >= 10000) return 'Legendární tkadlec 👑';
    if (webs >= 5000) return 'Mistr pavučin 🖤';
    if (webs >= 1000) return 'Zkušený tkadlec 🕸️';
    if (webs >= 500) return 'Aktivní člen 🎯';
    if (webs >= 100) return 'Rostoucí talent 🕷️';
    return 'Nováček 🥚';
  }

  Color _getReputationColor(int webs) {
    if (webs >= 10000) return const Color(0xFFFFD700);
    if (webs >= 5000) return const Color(0xFFE53935);
    if (webs >= 1000) return const Color(0xFFBA68C8);
    if (webs >= 500) return const Color(0xFF64B5F6);
    if (webs >= 100) return const Color(0xFF81C784);
    return AppColors.textMuted;
  }
}
