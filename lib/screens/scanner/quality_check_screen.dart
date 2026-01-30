import 'package:flutter/material.dart';
import '../../theme/theme.dart';
import '../../models/quality_check_model.dart';
import '../../data/quality_check_data.dart';
import '../../utils/haptic_utils.dart';

/// Quality Check Guide - Jak poznat kvalitní vs nebezpečnou trávu
class QualityCheckScreen extends StatefulWidget {
  const QualityCheckScreen({super.key});

  @override
  State<QualityCheckScreen> createState() => _QualityCheckScreenState();
}

class _QualityCheckScreenState extends State<QualityCheckScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<QualityCheckCategory> _categories = [
    QualityCheckCategory.visual,
    QualityCheckCategory.smell,
    QualityCheckCategory.synthetic,
    QualityCheckCategory.sprays,
    QualityCheckCategory.extracts,
    QualityCheckCategory.organic,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        HapticUtils.selectionClick();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.functionalBg,
      appBar: AppBar(
        title: const Text('Quality Check Guide'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Container(
            color: AppColors.functionalSurface,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorColor: AppColors.accent,
              labelColor: AppColors.accent,
              unselectedLabelColor: AppColors.textMuted,
              tabs: _categories.map((cat) {
                return Tab(
                  icon: Icon(cat.icon, size: 20),
                  text: cat.labelCs,
                );
              }).toList(),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Warning banner
          _buildWarningBanner(),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildVisualTab(),
                _buildSmellTab(),
                _buildSyntheticTab(),
                _buildSpraysTab(),
                _buildExtractsTab(),
                _buildOrganicTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningBanner() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.error.withAlpha(30),
            AppColors.error.withAlpha(10),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.error.withAlpha(80),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.warning, color: AppColors.error, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Harm Reduction Tool: Tenhle guide ti pomůže vyhnout se nebezpečným substancím.',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisualTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Vizuální kontrola'),
          const SizedBox(height: 12),
          ...QualityCheckData.visualChecks.map((item) => _buildCheckItem(item)),
          const SizedBox(height: 24),
          _buildQuickRefSection(),
        ],
      ),
    );
  }

  Widget _buildSmellTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Test zápachu'),
          const SizedBox(height: 12),
          ...QualityCheckData.smellChecks.map((item) => _buildCheckItem(item)),
        ],
      ),
    );
  }

  Widget _buildSyntheticTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Syntetické cannabinoidy'),
          const SizedBox(height: 8),
          Text(
            'VAROVÁNÍ: Syntetické cannabinoidy nejsou Cannabis. Jsou extrémně nebezpečné.',
            style: TextStyle(
              color: AppColors.error,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          ...QualityCheckData.syntheticWarnings.map((warning) => _buildSyntheticWarning(warning)),
        ],
      ),
    );
  }

  Widget _buildSpraysTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Chemické postřiky'),
          const SizedBox(height: 8),
          Text(
            'Dealer může přidat různé chemikálie pro váhu, vůni, nebo vzhled.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          ...QualityCheckData.sprayChecks.map((item) => _buildCheckItem(item)),
        ],
      ),
    );
  }

  Widget _buildExtractsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Typy extraktů'),
          const SizedBox(height: 8),
          Text(
            'Různé metody extrakce = různá bezpečnost a kvalita',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          ...QualityCheckData.extractTypes.map((extract) => _buildExtractCard(extract)),
        ],
      ),
    );
  }

  Widget _buildOrganicTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Organic vs Chemical'),
          const SizedBox(height: 12),
          ...QualityCheckData.organicChecks.map((item) => _buildCheckItem(item)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontFamily: 'MightySpidey',
        fontSize: 18,
        color: AppColors.accent,
        letterSpacing: 1,
      ),
    );
  }

  Widget _buildCheckItem(QualityCheckItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.functionalSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: item.type.color.withAlpha(60),
          width: 2,
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: item.type.color.withAlpha(30),
              shape: BoxShape.circle,
            ),
            child: Icon(
              item.category.icon,
              color: item.type.color,
              size: 20,
            ),
          ),
          title: Text(
            item.title,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              item.type.label,
              style: TextStyle(
                color: item.type.color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          children: [
            Text(
              item.description,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            ...item.bulletPoints.map((point) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• ',
                    style: TextStyle(
                      color: AppColors.accent,
                      fontSize: 14,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      point,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            )),
            if (item.imageHint != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.accent.withAlpha(10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lightbulb_outline, color: AppColors.accent, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.imageHint!,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSyntheticWarning(SyntheticWarning warning) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.functionalSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: warning.severity.color.withAlpha(80),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: warning.severity.color,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  warning.severity.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  warning.substance,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            warning.commonNames,
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: warning.severity.color.withAlpha(20),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              warning.danger,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'JAK POZNAT:',
            style: TextStyle(
              color: AppColors.accent,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          ...warning.howToSpot.map((point) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '• ',
                  style: TextStyle(
                    color: warning.severity.color,
                    fontSize: 14,
                  ),
                ),
                Expanded(
                  child: Text(
                    point,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildExtractCard(ExtractInfo extract) {
    final qualityColor = extract.qualityRating == 'Premium'
        ? AppColors.gold
        : extract.qualityRating == 'Good'
            ? AppColors.success
            : AppColors.error;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.functionalSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.functionalBorder,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (extract.isSolventless)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withAlpha(30),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'SOLVENTLESS',
                    style: TextStyle(
                      color: AppColors.success,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  extract.name,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: qualityColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  extract.qualityRating,
                  style: TextStyle(
                    color: qualityColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            extract.method,
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.accent.withAlpha(10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              extract.safety,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 12),
          ...extract.characteristics.map((char) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Icon(Icons.check, color: AppColors.accent, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    char,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildQuickRefSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'RYCHLÉ TESTY',
          style: TextStyle(
            fontFamily: 'MightySpidey',
            fontSize: 18,
            color: AppColors.accent,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 12),
        ...QualityCheckData.quickRefCards.map((card) => _buildQuickRefCard(card)),
      ],
    );
  }

  Widget _buildQuickRefCard(QuickRefCard card) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.functionalSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.accent.withAlpha(40),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            card.title,
            style: TextStyle(
              color: AppColors.accent,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            card.question,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ...card.answers.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '→ ',
                    style: TextStyle(
                      color: AppColors.accent,
                      fontSize: 14,
                    ),
                  ),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                        children: [
                          TextSpan(
                            text: '${entry.key}: ',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          TextSpan(text: entry.value),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
