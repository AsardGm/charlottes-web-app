import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/user_preferences_model.dart';
import '../../providers/personalization_provider.dart';
import '../../widgets/common/spider_loader.dart';
import 'role_selection_screen.dart';
import 'experience_level_screen.dart';
import 'interests_screen.dart';
import 'goals_screen.dart';

/// Smart onboarding flow coordinator
/// Řídí průchod 4 onboarding screens a uloží preferences
class SmartOnboardingFlow extends ConsumerStatefulWidget {
  const SmartOnboardingFlow({super.key});

  @override
  ConsumerState<SmartOnboardingFlow> createState() =>
      _SmartOnboardingFlowState();
}

class _SmartOnboardingFlowState extends ConsumerState<SmartOnboardingFlow> {
  int _currentStep = 0;
  UserRole? _selectedRole;
  ExperienceLevel? _selectedLevel;
  List<UserInterest>? _selectedInterests;
  List<UserGoal>? _selectedGoals;
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    if (_isSaving) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SpiderLoader(size: 60),
              SizedBox(height: 24),
              Text(
                'Přizpůsobuji aplikaci...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return PopScope(
      canPop: _currentStep == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _currentStep > 0) {
          setState(() {
            _currentStep--;
          });
        }
      },
      child: _buildCurrentStep(),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return RoleSelectionScreen(
          onRoleSelected: _handleRoleSelected,
        );
      case 1:
        return ExperienceLevelScreen(
          onLevelSelected: _handleLevelSelected,
        );
      case 2:
        return InterestsScreen(
          onInterestsSelected: _handleInterestsSelected,
        );
      case 3:
        return GoalsScreen(
          onGoalsSelected: _handleGoalsSelected,
        );
      default:
        return const SizedBox();
    }
  }

  void _handleRoleSelected(UserRole role) {
    setState(() {
      _selectedRole = role;
      _currentStep = 1;
    });
  }

  void _handleLevelSelected(ExperienceLevel level) {
    setState(() {
      _selectedLevel = level;
      _currentStep = 2;
    });
  }

  void _handleInterestsSelected(List<UserInterest> interests) {
    setState(() {
      _selectedInterests = interests;
      _currentStep = 3;
    });
  }

  Future<void> _handleGoalsSelected(List<UserGoal> goals) async {
    setState(() {
      _selectedGoals = goals;
      _isSaving = true;
    });

    try {
      final service = ref.read(personalizationServiceProvider);

      // Save všechny preferences najednou
      await service.completeOnboarding(
        role: _selectedRole!,
        experienceLevel: _selectedLevel!,
        interests: _selectedInterests!,
        goals: goals,
      );

      // Refresh preferences provider
      ref.invalidate(userPreferencesProvider);

      if (!mounted) return;

      // Navigate to home
      context.go('/');
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Chyba při ukládání: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
