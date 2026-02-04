import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/theme.dart';
import '../../services/challenge_service.dart';
import '../../models/challenge_model.dart';

/// Challenges & Achievements Overview Screen
class ChallengesScreen extends ConsumerStatefulWidget {
  const ChallengesScreen({super.key});

  @override
  ConsumerState<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends ConsumerState<ChallengesScreen>
    with SingleTickerProviderStateMixin {
  final _challengeService = ChallengeService();
  late TabController _tabController;

  bool _isLoading = true;
  GamificationStats? _stats;
  List<Challenge> _allChallenges = [];
  List<UserChallenge> _userChallenges = [];
  List<UserAchievement> _userAchievements = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;

      final results = await Future.wait([
        _challengeService.getUserStats(userId),
        _challengeService.getChallenges(),
        _challengeService.getUserChallenges(userId),
        _challengeService.getUserAchievements(userId),
      ]);

      setState(() {
        _stats = results[0] as GamificationStats;
        _allChallenges = results[1] as List<Challenge>;
        _userChallenges = results[2] as List<UserChallenge>;
        _userAchievements = results[3] as List<UserAchievement>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Chyba při načítání: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: AppColors.surface,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Challenges',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              background: _isLoading
                  ? const SizedBox()
                  : _buildStatsHeader(),
            ),
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.accent,
              labelColor: AppColors.accent,
              unselectedLabelColor: AppColors.textMuted,
              tabs: const [
                Tab(text: 'Challenges'),
                Tab(text: 'Achievements'),
              ],
            ),
          ),
        ],
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildChallengesTab(),
                  _buildAchievementsTab(),
                ],
              ),
      ),
    );
  }

  Widget _buildStatsHeader() {
    if (_stats == null) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatChip(
                icon: Icons.stars,
                label: 'Level',
                value: _stats!.currentLevel.toString(),
              ),
              _buildStatChip(
                icon: Icons.emoji_events,
                label: 'Points',
                value: _stats!.totalPoints.toString(),
              ),
              _buildStatChip(
                icon: Icons.local_fire_department,
                label: 'Streak',
                value: '${_stats!.currentDailyStreak}d',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Level ${_stats!.currentLevel}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                  Text(
                    '${_stats!.pointsToNextLevel} to next',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _stats!.levelProgress,
                  backgroundColor: AppColors.functionalBorder,
                  valueColor: AlwaysStoppedAnimation(AppColors.accent),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: AppColors.accent, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
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
    );
  }

  Widget _buildChallengesTab() {
    final activeChallenges = _userChallenges
        .where((uc) => uc.status == 'in_progress')
        .toList();
    final completedChallenges = _userChallenges
        .where((uc) => uc.status == 'completed')
        .toList();

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (activeChallenges.isNotEmpty) ...[
            const Text(
              'Active Challenges',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            ...activeChallenges.map((uc) => _buildChallengeCard(uc)),
            const SizedBox(height: 24),
          ],
          const Text(
            'Available Challenges',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          ..._allChallenges.map((c) {
            final userChallenge = _userChallenges
                .where((uc) => uc.challengeId == c.id)
                .firstOrNull;
            if (userChallenge != null && userChallenge.status == 'in_progress') {
              return const SizedBox.shrink();
            }
            return _buildAvailableChallengeCard(c, userChallenge);
          }),
          if (completedChallenges.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text(
              'Completed',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            ...completedChallenges.map((uc) => _buildChallengeCard(uc)),
          ],
        ],
      ),
    );
  }

  Widget _buildChallengeCard(UserChallenge userChallenge) {
    final challenge = userChallenge.challenge;
    if (challenge == null) return const SizedBox();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getDifficultyColor(challenge.difficulty).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getCategoryIcon(challenge.category),
                  color: _getDifficultyColor(challenge.difficulty),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      challenge.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      challenge.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '+${challenge.points} pts',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${userChallenge.currentProgress} / ${userChallenge.targetProgress}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                  Text(
                    '${(userChallenge.progressPercent * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.accent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: userChallenge.progressPercent,
                  backgroundColor: AppColors.functionalBorder,
                  valueColor: AlwaysStoppedAnimation(
                    userChallenge.isCompleted
                        ? AppColors.success
                        : AppColors.accent,
                  ),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvailableChallengeCard(Challenge challenge, UserChallenge? userChallenge) {
    final isCompleted = userChallenge?.isCompleted ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: isCompleted
            ? Border.all(color: AppColors.success.withOpacity(0.5))
            : null,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getDifficultyColor(challenge.difficulty).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getCategoryIcon(challenge.category),
              color: _getDifficultyColor(challenge.difficulty),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  challenge.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  challenge.description,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (isCompleted)
            Icon(Icons.check_circle, color: AppColors.success, size: 24)
          else
            FilledButton(
              onPressed: () => _startChallenge(challenge.id),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              child: const Text('Start', style: TextStyle(fontSize: 12)),
            ),
        ],
      ),
    );
  }

  Widget _buildAchievementsTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.85,
        ),
        itemCount: _userAchievements.length,
        itemBuilder: (context, index) {
          final userAchievement = _userAchievements[index];
          final achievement = userAchievement.achievement;
          if (achievement == null) return const SizedBox();

          return _buildAchievementCard(achievement, userAchievement);
        },
      ),
    );
  }

  Widget _buildAchievementCard(Achievement achievement, UserAchievement userAchievement) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getRarityColor(achievement.rarity).withOpacity(0.5),
          width: 2,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _getRarityColor(achievement.rarity).withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getAchievementIcon(achievement.icon),
              color: _getRarityColor(achievement.rarity),
              size: 32,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            achievement.title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            achievement.rarity.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: _getRarityColor(achievement.rarity),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '+${achievement.points} pts',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startChallenge(String challengeId) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      await _challengeService.startChallenge(userId, challengeId);
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Challenge started!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty) {
      case 'easy':
        return AppColors.success;
      case 'medium':
        return AppColors.warning;
      case 'hard':
        return AppColors.error;
      case 'legendary':
        return const Color(0xFF9C27B0);
      default:
        return AppColors.textMuted;
    }
  }

  Color _getRarityColor(String rarity) {
    switch (rarity) {
      case 'common':
        return AppColors.textMuted;
      case 'rare':
        return AppColors.info;
      case 'epic':
        return const Color(0xFF9C27B0);
      case 'legendary':
        return const Color(0xFFFFB300);
      default:
        return AppColors.textMuted;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'tbreak':
        return Icons.pause_circle;
      case 'journal':
        return Icons.book;
      case 'cognitive':
        return Icons.psychology;
      case 'social':
        return Icons.people;
      case 'wellness':
        return Icons.favorite;
      default:
        return Icons.emoji_events;
    }
  }

  IconData _getAchievementIcon(String icon) {
    switch (icon) {
      case 'edit_note':
        return Icons.edit_note;
      case 'pause_circle':
        return Icons.pause_circle;
      case 'quiz':
        return Icons.quiz;
      case 'workspace_premium':
        return Icons.workspace_premium;
      case 'emoji_events':
        return Icons.emoji_events;
      case 'star':
        return Icons.star;
      case 'military_tech':
        return Icons.military_tech;
      case 'local_fire_department':
        return Icons.local_fire_department;
      case 'whatshot':
        return Icons.whatshot;
      default:
        return Icons.emoji_events;
    }
  }
}
