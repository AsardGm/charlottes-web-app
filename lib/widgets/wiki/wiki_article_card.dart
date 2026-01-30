import 'package:flutter/material.dart';
import '../../models/wiki_article_model.dart';
import '../../theme/theme.dart';

/// Karta clanku v seznamu wiki - polished cyberpunk design
class WikiArticleCard extends StatelessWidget {
  final WikiArticleModel article;
  final VoidCallback onTap;

  const WikiArticleCard({
    super.key,
    required this.article,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final catColor = article.category.color;
    final riskColor = article.riskLevel.color;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          splashColor: catColor.withAlpha(15),
          highlightColor: catColor.withAlpha(8),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.functionalSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.functionalBorder.withAlpha(150),
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(13),
              child: IntrinsicHeight(
                child: Row(
                  children: [
                    // Barevny accent pruh vlevo
                    Container(
                      width: 3.5,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            catColor,
                            catColor.withAlpha(60),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                    // Obsah
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                        child: Row(
                          children: [
                            // Ikona kategorie
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    catColor.withAlpha(35),
                                    catColor.withAlpha(12),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: catColor.withAlpha(50),
                                  width: 1,
                                ),
                              ),
                              child: Icon(
                                article.category.icon,
                                color: catColor,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Text obsah
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Title + risk badge
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          article.title,
                                          style: const TextStyle(
                                            color: AppColors.textPrimary,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            height: 1.2,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // Risk badge
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: riskColor.withAlpha(18),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(
                                            color: riskColor.withAlpha(50),
                                            width: 0.5,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              width: 5,
                                              height: 5,
                                              decoration: BoxDecoration(
                                                color: riskColor,
                                                shape: BoxShape.circle,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color:
                                                        riskColor.withAlpha(100),
                                                    blurRadius: 4,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              article.riskLevel.label,
                                              style: TextStyle(
                                                color: riskColor.withAlpha(220),
                                                fontSize: 9,
                                                fontWeight: FontWeight.w600,
                                                letterSpacing: 0.2,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  // Subtitle (chemicky vzorec)
                                  if (article.subtitle.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      article.subtitle,
                                      style: TextStyle(
                                        color: catColor.withAlpha(140),
                                        fontSize: 10,
                                        fontFamily: 'monospace',
                                        letterSpacing: 0.3,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                  const SizedBox(height: 4),
                                  // Summary
                                  Text(
                                    article.summary,
                                    style: const TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 11.5,
                                      height: 1.4,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  // Tags
                                  if (article.tags.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        ...article.tags.take(3).map((tag) {
                                          return Padding(
                                            padding:
                                                const EdgeInsets.only(right: 4),
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 7,
                                                vertical: 2.5,
                                              ),
                                              decoration: BoxDecoration(
                                                color: catColor.withAlpha(12),
                                                borderRadius:
                                                    BorderRadius.circular(5),
                                                border: Border.all(
                                                  color: catColor.withAlpha(35),
                                                  width: 0.5,
                                                ),
                                              ),
                                              child: Text(
                                                tag,
                                                style: TextStyle(
                                                  color:
                                                      catColor.withAlpha(180),
                                                  fontSize: 9.5,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          );
                                        }),
                                        if (article.tags.length > 3)
                                          Text(
                                            '+${article.tags.length - 3}',
                                            style: TextStyle(
                                              color: AppColors.textMuted
                                                  .withAlpha(120),
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 4),
                            // Chevron
                            Icon(
                              Icons.chevron_right_rounded,
                              color: catColor.withAlpha(80),
                              size: 22,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
