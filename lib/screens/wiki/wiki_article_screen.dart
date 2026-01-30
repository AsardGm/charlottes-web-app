import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/wiki_article_model.dart';
import '../../providers/wiki_provider.dart';
import '../../theme/theme.dart';
import '../../widgets/wiki/wiki_section_card.dart';

/// Detail wiki clanku
class WikiArticleScreen extends ConsumerWidget {
  final String slug;

  const WikiArticleScreen({super.key, required this.slug});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final article = ref.watch(wikiArticleBySlugProvider(slug));
    final relatedArticles = ref.watch(wikiRelatedArticlesProvider(slug));

    if (article == null) {
      return Scaffold(
        backgroundColor: AppColors.functionalBg,
        appBar: AppBar(
          backgroundColor: AppColors.functionalBg,
          title: const Text('Clanek nenalezen'),
        ),
        body: const Center(
          child: Text(
            'Clanek neexistuje',
            style: TextStyle(color: AppColors.textMuted),
          ),
        ),
      );
    }

    final catColor = article.category.color;

    return Scaffold(
      backgroundColor: AppColors.functionalBg,
      appBar: AppBar(
        backgroundColor: AppColors.functionalBg,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          article.title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          // Header
          _buildHeader(article, catColor),
          const SizedBox(height: 16),

          // Popis
          if (article.description.isNotEmpty)
            WikiSectionCard(
              icon: Icons.info_outline,
              iconColor: catColor,
              title: 'Co to je',
              type: WikiSectionType.text,
              textContent: article.description,
            ),

          // Ucinky
          if (article.effects.isNotEmpty)
            WikiSectionCard(
              icon: Icons.psychology_outlined,
              iconColor: const Color(0xFF22C55E),
              title: 'Ucinky',
              type: WikiSectionType.tags,
              tags: article.effects,
            ),

          // Rizika
          if (article.risks.isNotEmpty)
            WikiSectionCard(
              icon: Icons.warning_amber_rounded,
              iconColor: const Color(0xFFE62429),
              title: 'Rizika',
              type: WikiSectionType.list,
              listItems: article.risks,
            ),

          // Harm reduction
          if (article.harmReductionTips.isNotEmpty)
            WikiSectionCard(
              icon: Icons.shield_outlined,
              iconColor: const Color(0xFF8B5CF6),
              title: 'Harm Reduction',
              type: WikiSectionType.list,
              listItems: article.harmReductionTips,
            ),

          // Legalita
          if (article.legalStatus != null && article.legalStatus!.isNotEmpty)
            WikiSectionCard(
              icon: Icons.gavel,
              iconColor: const Color(0xFF2D6A8F),
              title: 'Legalita',
              type: WikiSectionType.text,
              textContent: article.legalStatus,
            ),

          // Technicka data
          if (article.technicalData.isNotEmpty)
            WikiSectionCard(
              icon: Icons.data_object,
              iconColor: AppColors.accent,
              title: 'Technicka data',
              type: WikiSectionType.keyValue,
              kvData: article.technicalData,
            ),

          // Brain Map odkaz pro terpeny
          if (article.category == WikiCategory.terpenes)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => context.push('/brain-map'),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF22C55E).withAlpha(20),
                          const Color(0xFF22C55E).withAlpha(8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF22C55E).withAlpha(60),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.hub_outlined,
                          color: const Color(0xFF22C55E),
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Zobrazit v Brain Map',
                                style: TextStyle(
                                  color: const Color(0xFF22C55E),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Interaktivni vizualizace terpenu',
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: const Color(0xFF22C55E).withAlpha(150),
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Souvisejici clanky
          if (relatedArticles.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 10, top: 4),
              child: Text(
                'SOUVISEJICI',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
            ),
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: relatedArticles.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final related = relatedArticles[index];
                  return _buildRelatedCard(context, related);
                },
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Disclaimer
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFC4A35A).withAlpha(8),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFFC4A35A).withAlpha(30),
                width: 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  color: const Color(0xFFC4A35A),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Pouze pro vzdelavaci ucely. Nenavadime k uzivani bez souhlasu. Informace nejsou lekarskou radou.',
                    style: TextStyle(
                      color: const Color(0xFFC4A35A).withAlpha(180),
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildHeader(WikiArticleModel article, Color catColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            catColor.withAlpha(15),
            catColor.withAlpha(5),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: catColor.withAlpha(40),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Category icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: catColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: catColor.withAlpha(80),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  article.category.icon,
                  color: catColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      article.title,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                    if (article.subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        article.subtitle,
                        style: TextStyle(
                          color: catColor.withAlpha(180),
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Risk badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: article.riskLevel.color.withAlpha(20),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: article.riskLevel.color.withAlpha(60),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: article.riskLevel.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Riziko: ${article.riskLevel.label}',
                      style: TextStyle(
                        color: article.riskLevel.color,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: catColor.withAlpha(15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: catColor.withAlpha(40),
                    width: 1,
                  ),
                ),
                child: Text(
                  article.category.label,
                  style: TextStyle(
                    color: catColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Summary
          Text(
            article.summary,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRelatedCard(BuildContext context, WikiArticleModel related) {
    final color = related.category.color;
    return Material(
      color: AppColors.functionalSurface,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: () => context.push('/wiki/article/${related.slug}'),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 160,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: color.withAlpha(40),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Icon(related.category.icon, color: color, size: 14),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      related.title,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                related.summary,
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 10,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
