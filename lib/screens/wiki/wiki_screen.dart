import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/wiki_article_model.dart';
import '../../providers/wiki_provider.dart';
import '../../theme/theme.dart';
import '../../widgets/wiki/wiki_article_card.dart';

/// Wiki home screen - kategorie, search, seznam clanku
class WikiScreen extends ConsumerStatefulWidget {
  const WikiScreen({super.key});

  @override
  ConsumerState<WikiScreen> createState() => _WikiScreenState();
}

class _WikiScreenState extends ConsumerState<WikiScreen> {
  final _searchController = TextEditingController();
  bool _searchFocused = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredArticles = ref.watch(wikiFilteredArticlesProvider);
    final filter = ref.watch(wikiFilterProvider);

    return Scaffold(
      backgroundColor: AppColors.functionalBg,
      body: CustomScrollView(
        slivers: [
          // Custom header
          SliverToBoxAdapter(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    // Icon s glow
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.accent.withAlpha(30),
                            AppColors.accent.withAlpha(10),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.accent.withAlpha(80),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accent.withAlpha(20),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.menu_book_rounded,
                        color: AppColors.accent,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'WIKI',
                          style: TextStyle(
                            color: AppColors.accent,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 3,
                          ),
                        ),
                        Text(
                          'Encyklopedie kanabinoid\u016f a terpen\u016f',
                          style: TextStyle(
                            color: AppColors.textMuted.withAlpha(180),
                            fontSize: 11,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Pocet clanku badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withAlpha(15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.accent.withAlpha(40),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '${filteredArticles.length}',
                        style: TextStyle(
                          color: AppColors.accent.withAlpha(200),
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Accent divider line
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.accent.withAlpha(60),
                      AppColors.accent.withAlpha(15),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Search bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Focus(
                onFocusChange: (focused) {
                  setState(() => _searchFocused = focused);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: _searchFocused
                        ? [
                            BoxShadow(
                              color: AppColors.accent.withAlpha(15),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      ref.read(wikiFilterProvider.notifier).setQuery(value);
                      setState(() {}); // pro suffixIcon
                    },
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Hledat kanabinoidy, terpeny...',
                      hintStyle: TextStyle(
                        color: AppColors.functionalMuted.withAlpha(150),
                        fontSize: 13,
                      ),
                      prefixIcon: Padding(
                        padding: const EdgeInsets.only(left: 14, right: 10),
                        child: Icon(
                          Icons.search_rounded,
                          color: _searchFocused
                              ? AppColors.accent
                              : AppColors.functionalMuted,
                          size: 20,
                        ),
                      ),
                      prefixIconConstraints: const BoxConstraints(
                        minWidth: 44,
                        minHeight: 44,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                Icons.close_rounded,
                                color: AppColors.textMuted,
                                size: 18,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                ref
                                    .read(wikiFilterProvider.notifier)
                                    .setQuery('');
                                setState(() {});
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: AppColors.functionalSurface,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: AppColors.functionalBorder.withAlpha(120),
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: AppColors.accent.withAlpha(120),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Category chips
          SliverToBoxAdapter(
            child: SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildCategoryChip(
                    label: 'Vse',
                    color: AppColors.accent,
                    isSelected: filter.category == null,
                    onTap: () {
                      ref.read(wikiFilterProvider.notifier).setCategory(null);
                    },
                  ),
                  const SizedBox(width: 8),
                  ...WikiCategory.values.map((cat) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _buildCategoryChip(
                        label: cat.label,
                        color: cat.color,
                        icon: cat.icon,
                        isSelected: filter.category == cat,
                        onTap: () {
                          final current = filter.category;
                          ref.read(wikiFilterProvider.notifier).setCategory(
                                current == cat ? null : cat,
                              );
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),

          // Disclaimer - subtle
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.gold.withAlpha(120),
                    size: 13,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Pouze pro vzd\u011bl\u00e1vac\u00ed \u00fa\u010dely. Nenavad\u00edme k u\u017e\u00edv\u00e1n\u00ed.',
                      style: TextStyle(
                        color: AppColors.gold.withAlpha(100),
                        fontSize: 10,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Article list
          if (filteredArticles.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 40),
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.functionalSurface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.functionalBorder,
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        Icons.search_off_rounded,
                        color: AppColors.textMuted.withAlpha(80),
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '\u017d\u00e1dn\u00e9 \u010dl\u00e1nky nenalezeny',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Zkus jin\u00fd v\u00fdraz nebo kategorii',
                      style: TextStyle(
                        color: AppColors.textMuted.withAlpha(120),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final article = filteredArticles[index];
                    return WikiArticleCard(
                      article: article,
                      onTap: () =>
                          context.push('/wiki/article/${article.slug}'),
                    );
                  },
                  childCount: filteredArticles.length,
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  Widget _buildCategoryChip({
    required String label,
    required Color color,
    IconData? icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    color.withAlpha(40),
                    color.withAlpha(15),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                )
              : null,
          color: isSelected ? null : AppColors.functionalSurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? color.withAlpha(140) : AppColors.functionalBorder,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withAlpha(20),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                color: isSelected ? color : AppColors.functionalMuted,
                size: 14,
              ),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : AppColors.textMuted,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: isSelected ? 0.3 : 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
