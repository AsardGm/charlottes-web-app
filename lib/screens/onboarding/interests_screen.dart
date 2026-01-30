import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/user_preferences_model.dart';
import '../../theme/theme.dart';
import '../../widgets/common/ripple_button.dart';

/// Step 3: Interests selection (multi-select)
class InterestsScreen extends ConsumerStatefulWidget {
  final Function(List<UserInterest>) onInterestsSelected;

  const InterestsScreen({
    super.key,
    required this.onInterestsSelected,
  });

  @override
  ConsumerState<InterestsScreen> createState() => _InterestsScreenState();
}

class _InterestsScreenState extends ConsumerState<InterestsScreen>
    with SingleTickerProviderStateMixin {
  final Set<UserInterest> _selectedInterests = {};
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

  void _toggleInterest(UserInterest interest) {
    setState(() {
      if (_selectedInterests.contains(interest)) {
        _selectedInterests.remove(interest);
      } else {
        _selectedInterests.add(interest);
      }
    });
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
              _buildProgressIndicator(3, 4),
              const SizedBox(height: 40),

              FadeTransition(
                opacity: _animController,
                child: const Text(
                  'Co tě zajímá?',
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
                  'Vyber alespoň 1 oblast (můžeš i víc)',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.3,
                  children: UserInterest.values.map((interest) {
                    return _buildInterestCard(interest);
                  }).toList(),
                ),
              ),

              const SizedBox(height: 20),

              AnimatedOpacity(
                opacity: _selectedInterests.isNotEmpty ? 1.0 : 0.5,
                duration: const Duration(milliseconds: 200),
                child: PrimaryButton(
                  text: _selectedInterests.isEmpty
                      ? 'Vyber alespoň 1'
                      : 'Pokračovat (${_selectedInterests.length})',
                  onPressed: _selectedInterests.isNotEmpty
                      ? () =>
                          widget.onInterestsSelected(_selectedInterests.toList())
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

  Widget _buildInterestCard(UserInterest interest) {
    final isSelected = _selectedInterests.contains(interest);
    final index = UserInterest.values.indexOf(interest);

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0.3, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _animController,
        curve: Interval(
          0.1 * (index % 4),
          0.3 + (0.1 * (index % 4)),
          curve: Curves.easeOut,
        ),
      )),
      child: FadeTransition(
        opacity: _animController,
        child: GestureDetector(
          onTap: () => _toggleInterest(interest),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(16),
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
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Emoji
                Text(
                  interest.emoji,
                  style: const TextStyle(fontSize: 36),
                ),

                const SizedBox(height: 8),

                // Name
                Text(
                  interest.displayName,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color:
                        isSelected ? AppColors.accent : AppColors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 8),

                // Checkmark
                AnimatedScale(
                  scale: isSelected ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.elasticOut,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 16,
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
