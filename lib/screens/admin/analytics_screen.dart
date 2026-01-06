import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../services/admin_service.dart';
import '../../providers/user_provider.dart';
import '../../theme/theme.dart';
import '../../widgets/user_avatar.dart';
import '../../utils/helpers.dart';

/// Provider pro detailní statistiky
final detailedStatsProvider = FutureProvider<DetailedStats>((ref) async {
  return await ref.read(adminServiceProvider).getDetailedStats();
});

/// Obrazovka s rozšířenými statistikami a analytikou
class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(detailedStatsProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/admin'),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.analytics, size: 20),
            ),
            const SizedBox(width: 10),
            const Text('Analytika'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(detailedStatsProvider),
          ),
        ],
      ),
      body: statsAsync.when(
        data: (stats) => _buildContent(context, stats),
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: AppColors.error, size: 48),
              const SizedBox(height: 16),
              Text('Chyba: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(detailedStatsProvider),
                child: const Text('Zkusit znovu'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, DetailedStats stats) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Uživatelé sekce
          _buildSectionTitle(context, 'Uzivatele', Icons.people),
          const SizedBox(height: 12),
          _buildUserStats(stats),
          const SizedBox(height: 24),

          // Obsah sekce
          _buildSectionTitle(context, 'Obsah', Icons.article),
          const SizedBox(height: 12),
          _buildContentStats(stats),
          const SizedBox(height: 24),

          // Příspěvky podle typu
          _buildSectionTitle(context, 'Prispevky podle typu', Icons.category),
          const SizedBox(height: 12),
          _buildPostsByType(stats),
          const SizedBox(height: 24),

          // Top přispěvatelé
          _buildSectionTitle(context, 'Top prispevatele', Icons.star),
          const SizedBox(height: 12),
          _buildTopPosters(context, stats),
          const SizedBox(height: 24),

          // Reporty
          _buildSectionTitle(context, 'Reporty', Icons.report),
          const SizedBox(height: 12),
          _buildReportStats(stats),
          const SizedBox(height: 24),

          // Poslední aktivita
          _buildSectionTitle(context, 'Posledni aktivita', Icons.history),
          const SizedBox(height: 12),
          _buildRecentActivity(stats),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  Widget _buildUserStats(DetailedStats stats) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatTile(
                label: 'Celkem',
                value: stats.totalUsers.toString(),
                icon: Icons.people_alt,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatTile(
                label: 'Aktivnich (7d)',
                value: stats.activeUsers.toString(),
                icon: Icons.check_circle,
                color: Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatTile(
                label: 'Novych dnes',
                value: stats.newUsersToday.toString(),
                icon: Icons.person_add,
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatTile(
                label: 'Novych (7d)',
                value: stats.newUsersWeek.toString(),
                icon: Icons.trending_up,
                color: Colors.purple,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatTile(
                label: 'Zablokovanych',
                value: stats.blockedUsers.toString(),
                icon: Icons.block,
                color: Colors.red,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatTile(
                label: 'Adminu',
                value: stats.adminUsers.toString(),
                icon: Icons.admin_panel_settings,
                color: Colors.amber,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildContentStats(DetailedStats stats) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatTile(
                label: 'Prispevky',
                value: stats.totalPosts.toString(),
                subValue: '+${stats.postsToday} dnes',
                icon: Icons.article,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatTile(
                label: 'Komentare',
                value: stats.totalComments.toString(),
                subValue: '+${stats.commentsToday} dnes',
                icon: Icons.chat_bubble,
                color: Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatTile(
                label: 'Reakce',
                value: stats.totalReactions.toString(),
                icon: Icons.favorite,
                color: Colors.pink,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatTile(
                label: 'Prispevky (7d)',
                value: stats.postsWeek.toString(),
                icon: Icons.calendar_today,
                color: Colors.orange,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPostsByType(DetailedStats stats) {
    final types = {
      'discussion': {'label': 'Diskuze', 'icon': Icons.forum, 'color': Colors.blue},
      'question': {'label': 'Otazky', 'icon': Icons.help, 'color': Colors.orange},
      'announcement': {'label': 'Oznameni', 'icon': Icons.campaign, 'color': Colors.red},
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: types.entries.map((entry) {
          final count = stats.postsByType[entry.key] ?? 0;
          final total = stats.totalPosts;
          final percentage = total > 0 ? (count / total * 100).toStringAsFixed(1) : '0';
          final typeInfo = entry.value;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (typeInfo['color'] as Color).withAlpha(30),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    typeInfo['icon'] as IconData,
                    color: typeInfo['color'] as Color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        typeInfo['label'] as String,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: total > 0 ? count / total : 0,
                          backgroundColor: AppColors.surfaceLight,
                          valueColor: AlwaysStoppedAnimation(typeInfo['color'] as Color),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      count.toString(),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '$percentage%',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTopPosters(BuildContext context, DetailedStats stats) {
    if (stats.topPosters.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            'Zatim zadni prispevatele',
            style: TextStyle(color: AppColors.textMuted),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: stats.topPosters.length,
        separatorBuilder: (_, __) => Divider(
          height: 1,
          color: AppColors.surfaceLight,
        ),
        itemBuilder: (context, index) {
          final poster = stats.topPosters[index];
          final rank = index + 1;
          Color rankColor;
          switch (rank) {
            case 1:
              rankColor = Colors.amber;
              break;
            case 2:
              rankColor = Colors.grey.shade400;
              break;
            case 3:
              rankColor = Colors.orange.shade700;
              break;
            default:
              rankColor = AppColors.textMuted;
          }

          return ListTile(
            leading: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 24,
                  alignment: Alignment.center,
                  child: Text(
                    '#$rank',
                    style: TextStyle(
                      color: rankColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                UserAvatar(
                  imageUrl: poster['avatarUrl'] as String?,
                  name: poster['username'] as String,
                  size: 36,
                ),
              ],
            ),
            title: Text(poster['username'] as String),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(30),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '${poster['count']} prispevku',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ),
            onTap: () => context.push('/profile/${poster['userId']}'),
          );
        },
      ),
    );
  }

  Widget _buildReportStats(DetailedStats stats) {
    return Row(
      children: [
        Expanded(
          child: _StatTile(
            label: 'Cekajicich',
            value: stats.pendingReports.toString(),
            icon: Icons.pending_actions,
            color: stats.pendingReports > 0 ? Colors.red : Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatTile(
            label: 'Vyresenych dnes',
            value: stats.resolvedReportsToday.toString(),
            icon: Icons.check_circle,
            color: Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivity(DetailedStats stats) {
    if (stats.recentActivity.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            'Zatim zadna aktivita',
            style: TextStyle(color: AppColors.textMuted),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: stats.recentActivity.length,
        separatorBuilder: (_, __) => Divider(
          height: 1,
          color: AppColors.surfaceLight,
        ),
        itemBuilder: (context, index) {
          final activity = stats.recentActivity[index];
          final isPost = activity['type'] == 'post';
          final content = activity['content'] as String;
          final username = activity['username'] as String;
          final createdAt = DateTime.parse(activity['createdAt'] as String);

          return ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (isPost ? Colors.blue : Colors.green).withAlpha(30),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isPost ? Icons.article : Icons.chat_bubble,
                color: isPost ? Colors.blue : Colors.green,
                size: 20,
              ),
            ),
            title: Text(
              username,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              content.length > 50 ? '${content.substring(0, 50)}...' : content,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: AppColors.textMuted),
            ),
            trailing: Text(
              Helpers.formatTimeAgo(createdAt),
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Dlaždice pro statistiku
class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final String? subValue;
  final IconData icon;
  final Color color;

  const _StatTile({
    required this.label,
    required this.value,
    this.subValue,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
                  color: color.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const Spacer(),
              if (subValue != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    subValue!,
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
