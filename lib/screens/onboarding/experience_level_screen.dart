import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/user_preferences_model.dart';
import '../../theme/theme.dart';
import '../../widgets/common/ripple_button.dart';

/// Step 2: Experience level selection
class ExperienceLevelScreen extends ConsumerStatefulWidget {
  final Function(ExperienceLevel) onLevelSelected;

  const ExperienceLevelScreen({
    super.key,
    required this.onLevelSelected,
  });

  @override
  ConsumerState<ExperienceLevelScreen> createState() =>
      _ExperienceLevelScreenState();
}

class _ExperienceLevelScreenState
    extends ConsumerState<ExperienceLevelScreen>
    with SingleTickerProviderStateMixin {
  ExperienceLevel? _selectedLevel;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.functionalBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              _buildProgressIndicator(2, 4),
              const SizedBox(height: 40),

              FadeTransition(
                opacity: _animController,
                child: const Text(
                  'Jaká je tvoje zkušenost?',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              FadeTransition(
                opacity: _animController,
                child: Text(
                  'Pomůže nám to přizpůsobit obsah',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),

              const SizedBox(height: 40),

              Expanded(
                child: ListView(
                  children: ExperienceLevel.values.map((level) {
                    return _buildLevelCard(level);
                  }).toList(),
                ),
              ),

              const SizedBox(height: 20),

              AnimatedOpacity(
                opacity: _selectedLevel != null ? 1.0 : 0.5,
                duration: const Duration(milliseconds: 200),
                child: PrimaryButton(
                  text: 'Pokračovat',
                  onPressed: _selectedLevel != null
                      ? () => widget.onLevelSelected(_selectedLevel!)
                      : null,
                  width: double.infinity,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(int current, int total) {
    return Row(
      children: List.generate(total, (index) {
        final isActive = index < current;
        return Expanded(
          child: Container(
            height: 4,
            margin: EdgeInsets.only(right: index < total - 1 ? 8 : 0),
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.accent
                  : AppColors.accent.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildLevelCard(ExperienceLevel level) {
    final isSelected = _selectedLevel == level;

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0.3, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _animController,
        curve: Interval(
          0.2 * ExperienceLevel.values.indexOf(level),
          0.5 + (0.1 * ExperienceLevel.values.indexOf(level)),
          curve: Curves.easeOut,
        ),
      )),
      child: FadeTransition(
        opacity: _animController,
        child: GestureDetector(
          onTap: () {
            setState(() {
              _selectedLevel = level;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.accent.withValues(alpha: 0.15)
                  : AppColors.functionalSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? AppColors.accent
                    : AppColors.functionalBorder.withValues(alpha: 0.3),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.accent.withValues(alpha: 0.3),
                        blurRadius: 12,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.accent.withValues(alpha: 0.2)
                        : AppColors.functionalBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      level.emoji,
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        level.displayName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? AppColors.accent
                              : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        level.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedScale(
                  scale: isSelected ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.elasticOut,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 18,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
