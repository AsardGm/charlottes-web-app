import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/user_preferences_model.dart';
import '../../theme/theme.dart';
import '../../widgets/common/ripple_button.dart';

/// Step 1: Role selection screen
class RoleSelectionScreen extends ConsumerStatefulWidget {
  final Function(UserRole) onRoleSelected;

  const RoleSelectionScreen({
    super.key,
    required this.onRoleSelected,
  });

  @override
  ConsumerState<RoleSelectionScreen> createState() =>
      _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends ConsumerState<RoleSelectionScreen>
    with SingleTickerProviderStateMixin {
  UserRole? _selectedRole;
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

              // Progress indicator
              _buildProgressIndicator(1, 4),

              const SizedBox(height: 40),

              // Title
              FadeTransition(
                opacity: _animController,
                child: const Text(
                  'Kdo jsi především?',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Subtitle
              FadeTransition(
                opacity: _animController,
                child: Text(
                  'Přizpůsobíme aplikaci podle tvé role',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Role cards
              Expanded(
                child: ListView(
                  children: UserRole.values.map((role) {
                    return _buildRoleCard(role);
                  }).toList(),
                ),
              ),

              const SizedBox(height: 20),

              // Continue button
              AnimatedOpacity(
                opacity: _selectedRole != null ? 1.0 : 0.5,
                duration: const Duration(milliseconds: 200),
                child: PrimaryButton(
                  text: 'Pokračovat',
                  onPressed: _selectedRole != null
                      ? () => widget.onRoleSelected(_selectedRole!)
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

  Widget _buildRoleCard(UserRole role) {
    final isSelected = _selectedRole == role;

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0.3, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _animController,
        curve: Interval(
          0.2 * UserRole.values.indexOf(role),
          0.5 + (0.1 * UserRole.values.indexOf(role)),
          curve: Curves.easeOut,
        ),
      )),
      child: FadeTransition(
        opacity: _animController,
        child: GestureDetector(
          onTap: () {
            setState(() {
              _selectedRole = role;
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
                        spreadRadius: 0,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                // Emoji icon
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
                      role.emoji,
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                // Title & description
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        role.displayNameCz,
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
                        role.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                // Checkmark
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
