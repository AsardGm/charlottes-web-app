import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/theme.dart';
import '../../services/strain_journal_service.dart';
import '../../models/strain_journal_model.dart';
import '../../widgets/common/shimmer_loading.dart';
import 'package:intl/intl.dart';

/// Strain Journal History Screen - List of all journal entries
class StrainJournalScreen extends ConsumerStatefulWidget {
  final String? strainId;

  const StrainJournalScreen({super.key, this.strainId});

  @override
  ConsumerState<StrainJournalScreen> createState() =>
      _StrainJournalScreenState();
}

class _StrainJournalScreenState extends ConsumerState<StrainJournalScreen> {
  final _journalService = StrainJournalService();
  final _searchController = TextEditingController();

  bool _isLoading = true;
  List<StrainJournalEntry> _entries = [];
  List<StrainJournalEntry> _filteredEntries = [];
  Map<String, dynamic>? _stats;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;

      final results = await Future.wait([
        _journalService.getJournalEntries(
          userId,
          strainId: widget.strainId,
        ),
        _journalService.getJournalStats(userId),
      ]);

      setState(() {
        _entries = results[0] as List<StrainJournalEntry>;
        _filteredEntries = _entries;
        _stats = results[1] as Map<String, dynamic>;
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

  void _filterEntries(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredEntries = _entries;
      } else {
        _filteredEntries = _entries.where((entry) {
          final titleMatch = entry.title?.toLowerCase().contains(query.toLowerCase()) ?? false;
          final strainMatch = entry.strainName?.toLowerCase().contains(query.toLowerCase()) ?? false;
          final notesMatch = entry.notes?.toLowerCase().contains(query.toLowerCase()) ?? false;
          return titleMatch || strainMatch || notesMatch;
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          if (_isLoading)
            _buildLoadingState()
          else if (_entries.isEmpty)
            _buildEmptyState()
          else ...[
            if (_stats != null) _buildStatsBar(),
            _buildSearchBar(),
            _buildEntriesList(),
          ],
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Navigate to create entry
          context.push('/strain-journal/create');
        },
        backgroundColor: AppColors.accent,
        icon: const Icon(Icons.add),
        label: const Text('New Entry'),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.surface,
      flexibleSpace: FlexibleSpaceBar(
        title: Row(
          children: [
            Icon(Icons.book, size: 24, color: AppColors.accent),
            const SizedBox(width: 8),
            Text(
              widget.strainId != null ? 'Strain Journal' : 'My Journal',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.filter_list),
          onPressed: () {
            _showFilterDialog();
          },
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          const ShimmerCard(height: 100),
          const SizedBox(height: 12),
          const ShimmerCard(height: 150),
          const SizedBox(height: 12),
          const ShimmerCard(height: 150),
        ]),
      ),
    );
  }

  Widget _buildStatsBar() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.accent.withOpacity(0.1),
              AppColors.primary.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(
              label: 'Entries',
              value: _stats!['total_entries'].toString(),
              icon: Icons.library_books,
            ),
            _buildStatItem(
              label: 'Strains',
              value: _stats!['unique_strains'].toString(),
              icon: Icons.grass,
            ),
            _buildStatItem(
              label: 'Avg Rating',
              value: (_stats!['avg_rating'] as double).toStringAsFixed(1),
              icon: Icons.star,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Column(
      children: [
        Icon(icon, color: AppColors.accent, size: 20),
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

  Widget _buildSearchBar() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: TextField(
          controller: _searchController,
          onChanged: _filterEntries,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Search entries...',
            hintStyle: TextStyle(color: AppColors.textMuted),
            prefixIcon: Icon(Icons.search, color: AppColors.textMuted),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear, color: AppColors.textMuted),
                    onPressed: () {
                      _searchController.clear();
                      _filterEntries('');
                    },
                  )
                : null,
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEntriesList() {
    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final entry = _filteredEntries[index];
            return _buildEntryCard(entry);
          },
          childCount: _filteredEntries.length,
        ),
      ),
    );
  }

  Widget _buildEntryCard(StrainJournalEntry entry) {
    final dateFormat = DateFormat('MMM d, yyyy • h:mm a');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: entry.isFavorite
            ? Border.all(color: AppColors.accent.withOpacity(0.3), width: 2)
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            context.push('/strain-journal/${entry.id}');
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.local_florist,
                        color: AppColors.accent,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.strainName ?? 'Unknown Strain',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            dateFormat.format(entry.consumedAt),
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (entry.isFavorite)
                      Icon(Icons.favorite, color: AppColors.accent, size: 20),
                  ],
                ),

                // Title & Rating
                if (entry.title != null || entry.overallRating != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (entry.title != null)
                        Expanded(
                          child: Text(
                            entry.title!,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      if (entry.overallRating != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.star,
                                size: 14,
                                color: AppColors.success,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                entry.overallRating!.toStringAsFixed(1),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.success,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],

                // Quick Effects Summary
                if (entry.isComplete) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      if (entry.mentalEffects.focus != null &&
                          entry.mentalEffects.focus! >= 7)
                        _buildEffectChip('Focus', Icons.center_focus_strong),
                      if (entry.mentalEffects.creativity != null &&
                          entry.mentalEffects.creativity! >= 7)
                        _buildEffectChip('Creative', Icons.palette),
                      if (entry.emotionalEffects.happiness != null &&
                          entry.emotionalEffects.happiness! >= 7)
                        _buildEffectChip('Happy', Icons.mood),
                      if (entry.physicalEffects.physicalRelaxation != null &&
                          entry.physicalEffects.physicalRelaxation! >= 7)
                        _buildEffectChip('Relaxed', Icons.self_improvement),
                      if (entry.physicalEffects.energyLevel != null &&
                          entry.physicalEffects.energyLevel! >= 7)
                        _buildEffectChip('Energetic', Icons.bolt),
                    ],
                  ),
                ],

                // AI Analysis Badge
                if (entry.hasAIAnalysis) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.psychology,
                        size: 14,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          entry.aiSummary!,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.primary,
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEffectChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.functionalBorder,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.accent),
          const SizedBox(width: 4),
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

  Widget _buildEmptyState() {
    return SliverFillRemaining(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.book_outlined,
                size: 64,
                color: AppColors.textMuted.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              const Text(
                'No Journal Entries Yet',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Start tracking your strain experiences',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Filter & Sort',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Icon(Icons.star, color: AppColors.accent),
                title: const Text('Favorites Only'),
                onTap: () {
                  Navigator.pop(context);
                  // Implement favorites filter
                },
              ),
              ListTile(
                leading: Icon(Icons.psychology, color: AppColors.primary),
                title: const Text('AI Analyzed'),
                onTap: () {
                  Navigator.pop(context);
                  // Implement AI analyzed filter
                },
              ),
              ListTile(
                leading: Icon(Icons.sort, color: AppColors.textMuted),
                title: const Text('Sort by Rating'),
                onTap: () {
                  Navigator.pop(context);
                  // Implement rating sort
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
