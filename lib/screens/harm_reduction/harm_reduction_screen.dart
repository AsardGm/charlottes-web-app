import 'package:flutter/material.dart';
import '../../models/harm_reduction_guide.dart';
import '../../theme/theme.dart';

/// Harm Reduction Education Hub
/// Provides educational resources and safety guidelines
class HarmReductionScreen extends StatefulWidget {
  const HarmReductionScreen({super.key});

  @override
  State<HarmReductionScreen> createState() => _HarmReductionScreenState();
}

class _HarmReductionScreenState extends State<HarmReductionScreen> {
  String _selectedCategory = 'Základy';

  @override
  Widget build(BuildContext context) {
    final filteredGuides = HarmReductionGuide.getByCategory(_selectedCategory);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with gradient
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF1A4A1A),
                      const Color(0xFF0D2A0D),
                      AppColors.surface,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF66BB6A).withValues(alpha:0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF66BB6A).withValues(alpha:0.3),
                            ),
                          ),
                          child: const Icon(
                            Icons.local_hospital,
                            color: Color(0xFF66BB6A),
                            size: 32,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'HARM REDUCTION',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Vzdělávací průvodce pro bezpečnější konzumaci',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha:0.7),
                            fontSize: 13,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Category filter
          SliverPersistentHeader(
            pinned: true,
            delegate: _CategoryFilterDelegate(
              categories: HarmReductionGuide.allCategories,
              selectedCategory: _selectedCategory,
              onCategorySelected: (category) {
                setState(() => _selectedCategory = category);
              },
            ),
          ),

          // Guides list
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final guide = filteredGuides[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _GuideCard(
                      guide: guide,
                      onTap: () => _showGuideDetail(context, guide),
                    ),
                  );
                },
                childCount: filteredGuides.length,
              ),
            ),
          ),

          // Quick tips section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: _QuickTipsCard(),
            ),
          ),

          // Bottom padding
          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
    );
  }

  void _showGuideDetail(BuildContext context, HarmReductionGuide guide) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Handle
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha:0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Header
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF66BB6A).withValues(alpha:0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF66BB6A).withValues(alpha:0.3),
                          ),
                        ),
                        child: Text(
                          guide.icon,
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              guide.title,
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              guide.subtitle,
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                        color: AppColors.textMuted,
                      ),
                    ],
                  ),
                ),
                // Content
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Key points
                        _buildSection(
                          title: '🎯 Klíčové body',
                          items: guide.content.keyPoints,
                          color: const Color(0xFF2196F3),
                        ),
                        const SizedBox(height: 24),
                        // Recommendations
                        _buildSection(
                          title: '✅ Doporučení',
                          items: guide.content.recommendations,
                          color: const Color(0xFF66BB6A),
                        ),
                        const SizedBox(height: 24),
                        // Warnings
                        _buildSection(
                          title: '⚠️ Varování',
                          items: guide.content.warnings,
                          color: const Color(0xFFFF9800),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<String> items,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...items.map((item) {
          // Handle bold markdown **text**
          final parts = <TextSpan>[];
          final regex = RegExp(r'\*\*(.*?)\*\*');
          var lastEnd = 0;

          for (final match in regex.allMatches(item)) {
            if (match.start > lastEnd) {
              parts.add(TextSpan(text: item.substring(lastEnd, match.start)));
            }
            parts.add(TextSpan(
              text: match.group(1),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ));
            lastEnd = match.end;
          }

          if (lastEnd < item.length) {
            parts.add(TextSpan(text: item.substring(lastEnd)));
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 8, right: 12),
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        height: 1.6,
                      ),
                      children: parts.isEmpty ? [TextSpan(text: item)] : parts,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

// Guide Card Widget
class _GuideCard extends StatelessWidget {
  final HarmReductionGuide guide;
  final VoidCallback onTap;

  const _GuideCard({
    required this.guide,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.functionalSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF66BB6A).withValues(alpha:0.2),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFF66BB6A).withValues(alpha:0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF66BB6A).withValues(alpha:0.3),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      guide.icon,
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
                        guide.title,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        guide.subtitle,
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 13,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: const Color(0xFF66BB6A).withValues(alpha:0.5),
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Quick Tips Card
class _QuickTipsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A4A1A), Color(0xFF0D2A0D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF66BB6A).withValues(alpha:0.3),
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF66BB6A).withValues(alpha:0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.lightbulb,
                  color: Color(0xFF66BB6A),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Rychlá připomínka',
                style: TextStyle(
                  color: Color(0xFF66BB6A),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            HarmReductionTips.getRandomTip(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// Category Filter Delegate
class _CategoryFilterDelegate extends SliverPersistentHeaderDelegate {
  final List<String> categories;
  final String selectedCategory;
  final Function(String) onCategorySelected;

  _CategoryFilterDelegate({
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = category == selectedCategory;

          return GestureDetector(
            onTap: () => onCategorySelected(category),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF66BB6A).withValues(alpha:0.2)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF66BB6A)
                      : AppColors.functionalBorder,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Text(
                category,
                style: TextStyle(
                  color: isSelected ? const Color(0xFF66BB6A) : AppColors.textMuted,
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  double get maxExtent => 60;

  @override
  double get minExtent => 60;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) => true;
}
