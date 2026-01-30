import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/news_article_model.dart';
import '../../theme/theme.dart';

class NewsFeedScreen extends StatefulWidget {
  const NewsFeedScreen({super.key});

  @override
  State<NewsFeedScreen> createState() => _NewsFeedScreenState();
}

class _NewsFeedScreenState extends State<NewsFeedScreen> {
  NewsCategory? _selectedCategory;
  NewsRegion? _selectedRegion;

  final List<NewsArticleModel> _articles = [
    // LEGISLATIVA
    NewsArticleModel(
      id: '1',
      title: 'Německo spouští legální prodej cannabis',
      tldr: 'Od 1. července 2024 mohou licencované obchody v Německu prodávat cannabis dospělým. Limit je 25g na osobu.',
      whyItMatters: 'Německo je největší trh v EU. Tohle změní celou evropskou debatu a může urychlit legalizaci i v ČR.',
      content: '''
Německo oficálně spustilo regulovaný prodej cannabis pro rekreační účely. Jde o historický moment pro celou Evropu.

## Co to znamená v praxi?

- Dospělí (18+) mohou koupit až 25g cannabis měsíčně
- Prodej pouze v licencovaných obchodech
- THC limit 15% pro osoby do 21 let
- Domácí pěstování až 3 rostliny

## Dopad na EU

Německo jako největší ekonomika EU vytváří precedent. Analytici očekávají dominový efekt v dalších zemích.

## Co to znamená pro ČR?

Česká vláda již avizovala, že sleduje německý model. Ministryně zdravotnictví nevyloučila podobnou úpravu do roku 2026.
      ''',
      category: NewsCategory.legislation,
      region: NewsRegion.eu,
      source: 'Deutsche Welle',
      publishedAt: DateTime.now().subtract(const Duration(hours: 5)),
      readTimeMinutes: 4,
      xpReward: 20,
      tags: ['Německo', 'Legalizace', 'EU'],
    ),
    NewsArticleModel(
      id: '2',
      title: 'ČR: Novela zákona o konopí míří do sněmovny',
      tldr: 'Vláda schválila novelu umožňující cannabis kluby a domácí pěstování do 5 rostlin.',
      whyItMatters: 'První reálný krok k dekriminalizaci v ČR. Pokud projde, změní to život tisícům lidí.',
      content: '''
Česká vláda schválila dlouho očekávanou novelu zákona o návykových látkách.

## Hlavní body novely:

1. **Cannabis kluby** - neziskové organizace mohou pěstovat pro členy
2. **Domácí pěstování** - až 5 rostlin pro osobní potřebu
3. **Dekriminalizace** - držení do 25g nebude trestné
4. **Řidičáky** - nové limity THC v krvi

## Časový plán

- Únor 2025: První čtení
- Květen 2025: Hlasování
- 2026: Účinnost (optimistický scénář)

## Opozice

Část opozice již avizovala odpor. Očekává se bouřlivá debata.
      ''',
      category: NewsCategory.legislation,
      region: NewsRegion.cz,
      source: 'iROZHLAS',
      publishedAt: DateTime.now().subtract(const Duration(hours: 12)),
      readTimeMinutes: 3,
      xpReward: 15,
      tags: ['ČR', 'Novela', 'Dekriminalizace'],
    ),

    // VĚDA
    NewsArticleModel(
      id: '3',
      title: 'Studie: CBD snižuje úzkost o 40% bez vedlejších účinků',
      tldr: 'Randomizovaná studie na 300 pacientech ukázala významné snížení úzkosti při denním užívání 25mg CBD.',
      whyItMatters: 'Další důkaz, že CBD funguje. Tohle můžeš ukázat skeptickému doktorovi.',
      content: '''
Nová studie publikovaná v Journal of Clinical Psychology přináší silné důkazy o účinnosti CBD.

## Metodologie

- 300 účastníků s diagnostikovanou úzkostnou poruchou
- Dvojitě zaslepená, placebo-kontrolovaná
- 8 týdnů sledování
- Dávka: 25mg CBD denně

## Výsledky

| Skupina | Snížení úzkosti |
|---------|-----------------|
| CBD | 42% |
| Placebo | 12% |

## Vedlejší účinky

Minimální - pouze 3% hlásilo mírnou ospalost. Žádné vážné nežádoucí účinky.

## Závěr autorů

"CBD představuje bezpečnou a účinnou alternativu k tradičním anxiolytikům."
      ''',
      category: NewsCategory.science,
      region: NewsRegion.world,
      source: 'Journal of Clinical Psychology',
      publishedAt: DateTime.now().subtract(const Duration(days: 1)),
      readTimeMinutes: 5,
      xpReward: 25,
      tags: ['CBD', 'Úzkost', 'Studie'],
    ),
    NewsArticleModel(
      id: '4',
      title: 'Průlom: Vědci identifikovali gen zodpovědný za paranoidní reakce',
      tldr: 'Genetická varianta CYP2C9 ovlivňuje, jak tělo metabolizuje THC. Lidé s variantou *3 mají 3x vyšší riziko paranoi.',
      whyItMatters: 'V budoucnu budeš moci zjistit genetickým testem, jestli ti hrozí paranoia. Personalizovaná medicína.',
      content: '''
Výzkumníci z Stanford University publikovali přelomový objev v časopise Nature Genetics.

## O co jde?

Gen CYP2C9 kóduje enzym, který metabolizuje THC v játrech. Existují 3 varianty:
- *1 (normální)
- *2 (snížená aktivita)
- *3 (velmi snížená aktivita)

## Výsledky

Lidé s variantou *3:
- THC zůstává v těle 3x déle
- 3x vyšší riziko paranoidních reakcí
- Doporučená dávka: 1/3 standardní

## Praktické využití

Genetické testy by mohly být součástí lékařské konzultace před předepsáním cannabis.
      ''',
      category: NewsCategory.science,
      region: NewsRegion.world,
      source: 'Nature Genetics',
      publishedAt: DateTime.now().subtract(const Duration(days: 2)),
      readTimeMinutes: 6,
      xpReward: 30,
      tags: ['Genetika', 'THC', 'Paranoia', 'Výzkum'],
    ),

    // KULTURA
    NewsArticleModel(
      id: '5',
      title: 'Snoop Dogg investuje do české cannabis firmy',
      tldr: 'Rapper Snoop Dogg prostřednictvím svého fondu Casa Verde investoval do pražského startupu Kanabio.',
      whyItMatters: 'Signál, že ČR je na mapě globálního cannabis byznysu. Může přitáhnout další investory.',
      content: '''
Legendární rapper a cannabis podnikatel Snoop Dogg oznámil investici do české společnosti Kanabio.

## O Kanabio

- Založeno 2021 v Praze
- Vývoj CBD produktů
- 45 zaměstnanců
- Export do 12 zemí EU

## Detaily investice

- Částka: nezveřejněna (odhad 2-5M USD)
- Fond: Casa Verde Capital
- Účel: expanze do Německa

## Komentář Snoop Dogga

"Czech Republic has amazing potential. The culture, the people, the quality - it's all there."
      ''',
      category: NewsCategory.culture,
      region: NewsRegion.cz,
      source: 'Forbes',
      publishedAt: DateTime.now().subtract(const Duration(days: 1)),
      readTimeMinutes: 3,
      xpReward: 15,
      tags: ['Snoop Dogg', 'Investice', 'Startup'],
    ),
    NewsArticleModel(
      id: '6',
      title: 'Cannabis Cup 2025: Nejlepší strain je český!',
      tldr: 'Strain "Bohemian Haze" od českého grower kolektivu vyhrál prestižní High Times Cannabis Cup v kategorii Sativa.',
      whyItMatters: 'Důkaz, že česká genetika patří ke světové špičce. Národní hrdost!',
      content: '''
Na letošním High Times Cannabis Cup v Amsterdamu zvítězil český strain Bohemian Haze.

## O vítězném strainu

- **Název:** Bohemian Haze
- **Typ:** Sativa (85%)
- **THC:** 24%
- **Terpeny:** Terpinolene, Limonene, Pinene
- **Genetika:** Czech Haze x Super Silver

## Hodnocení poroty

"Exceptional terpene profile, clean high, perfect cure. Czech growers showed world-class quality."

## Tým

Kolektiv "Prague Genetics" - 5 growérů, kteří pracují společně od roku 2018.
      ''',
      category: NewsCategory.culture,
      region: NewsRegion.world,
      source: 'High Times',
      publishedAt: DateTime.now().subtract(const Duration(days: 3)),
      readTimeMinutes: 4,
      xpReward: 20,
      tags: ['Cannabis Cup', 'Sativa', 'ČR'],
    ),

    // INDUSTRY
    NewsArticleModel(
      id: '7',
      title: 'Trend 2025: Nano-emulze a rychlonástupné edibles',
      tldr: 'Nová technologie nano-emulzí umožňuje edibles s nástupem účinku do 15 minut místo 1-2 hodin.',
      whyItMatters: 'Konec předávkování edibles! Rychlejší nástup = lepší kontrola dávkování.',
      content: '''
Nano-emulzní technologie mění svět edibles.

## Jak to funguje?

Tradiční edibles:
- THC se vstřebává v játrech
- Nástup: 60-120 minut
- Nepředvídatelné

Nano-emulze:
- THC rozbitý na nano-částice
- Vstřebává se již v ústech
- Nástup: 10-15 minut
- Konzistentní účinek

## Produkty na trhu

- Nano gummies (USA, Kanada)
- Nano nápoje
- Sublinguální spreje

## Dostupnost v EU

Očekává se v Německu od 2025. V ČR zatím nedostupné.
      ''',
      category: NewsCategory.industry,
      region: NewsRegion.world,
      source: 'Cannabis Business Times',
      publishedAt: DateTime.now().subtract(const Duration(hours: 18)),
      readTimeMinutes: 4,
      xpReward: 20,
      tags: ['Edibles', 'Technologie', 'Nano'],
    ),
    NewsArticleModel(
      id: '8',
      title: 'Genetics Report: Top 5 strainů roku 2025',
      tldr: 'Runtz, Gelato 41, Jealousy, Gary Payton a Zoap dominují trhu. Trend směřuje k dezertovým profilům.',
      whyItMatters: 'Víš co je teď hot. Můžeš hledat tyto genetiky nebo jejich kříže.',
      content: '''
Analýza prodejních dat z legálních trhů odhaluje top genetiky roku.

## Top 5 strainů 2025

### 1. Runtz
- Rodič: Zkittlez x Gelato
- Profil: Sladký, ovocný
- THC: 19-29%

### 2. Gelato 41
- Rodič: Sunset Sherbet x Thin Mint GSC
- Profil: Krémový, dezertový
- THC: 20-25%

### 3. Jealousy
- Rodič: Sherbert Bx1 x Gelato 41
- Profil: Komplexní, zemitý
- THC: 25-30%

### 4. Gary Payton
- Rodič: The Y x Snowman
- Profil: Sladký, plynový
- THC: 20-25%

### 5. Zoap
- Rodič: Rainbow Sherbert x Pink Guava
- Profil: Ovocný, tropický
- THC: 25-28%

## Trend

Dezertové, sladké profily dominují. Klasické "skunky" jsou na ústupu.
      ''',
      category: NewsCategory.industry,
      region: NewsRegion.world,
      source: 'Leafly',
      publishedAt: DateTime.now().subtract(const Duration(days: 2)),
      readTimeMinutes: 5,
      xpReward: 25,
      tags: ['Genetika', 'Trendy', 'Top 5'],
    ),
  ];

  List<NewsArticleModel> get _filteredArticles {
    return _articles.where((article) {
      if (_selectedCategory != null && article.category != _selectedCategory) {
        return false;
      }
      if (_selectedRegion != null && article.region != _selectedRegion) {
        return false;
      }
      return true;
    }).toList()
      ..sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.functionalBg,
      appBar: AppBar(
        backgroundColor: AppColors.functionalBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          '📰 Ganja News',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.accent.withAlpha(30),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Text('✨', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 4),
                Text(
                  'XP za čtení',
                  style: TextStyle(color: AppColors.accent, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filters
          _buildFilters(),
          
          // Articles
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredArticles.length,
              itemBuilder: (context, index) {
                return _buildArticleCard(_filteredArticles[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.functionalBg,
        border: Border(
          bottom: BorderSide(color: AppColors.functionalBorder.withAlpha(100)),
        ),
      ),
      child: Column(
        children: [
          // Category filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(
                  label: '📋 Vše',
                  isSelected: _selectedCategory == null,
                  onTap: () => setState(() => _selectedCategory = null),
                ),
                const SizedBox(width: 8),
                ...NewsCategory.values.map((cat) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _buildFilterChip(
                    label: cat.label,
                    isSelected: _selectedCategory == cat,
                    onTap: () => setState(() => _selectedCategory = cat),
                  ),
                )),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Region filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(
                  label: '🌐 Vše',
                  isSelected: _selectedRegion == null,
                  onTap: () => setState(() => _selectedRegion = null),
                  small: true,
                ),
                const SizedBox(width: 8),
                ...NewsRegion.values.map((region) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _buildFilterChip(
                    label: region.label,
                    isSelected: _selectedRegion == region,
                    onTap: () => setState(() => _selectedRegion = region),
                    small: true,
                  ),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    bool small = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: small ? 12 : 14,
          vertical: small ? 6 : 8,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent.withAlpha(30) : AppColors.functionalSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.accent : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.accent : Colors.white,
            fontSize: small ? 12 : 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildArticleCard(NewsArticleModel article) {
    return GestureDetector(
      onTap: () => context.push('/news/${article.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.functionalSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.functionalBorder.withAlpha(50)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withAlpha(30),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    article.category.emoji,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  article.region.label,
                  style: TextStyle(color: AppColors.functionalMuted, fontSize: 12),
                ),
                const Spacer(),
                Text(
                  article.timeAgo,
                  style: TextStyle(color: AppColors.functionalMuted, fontSize: 12),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Title
            Text(
              article.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold,
                height: 1.3,
              ),
            ),

            const SizedBox(height: 10),

            // TL;DR
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.functionalBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TL;DR',
                    style: TextStyle(
                      color: AppColors.accent,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    article.tldr,
                    style: TextStyle(
                      color: AppColors.functionalMuted,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Footer
            Row(
              children: [
                Icon(Icons.access_time, color: AppColors.functionalMuted, size: 14),
                const SizedBox(width: 4),
                Text(
                  '${article.readTimeMinutes} min',
                  style: TextStyle(color: AppColors.functionalMuted, fontSize: 12),
                ),
                const SizedBox(width: 16),
                Text(
                  article.source,
                  style: TextStyle(color: AppColors.functionalMuted, fontSize: 12),
                ),
                if (article.isVerified) ...[
                  const SizedBox(width: 4),
                  Icon(Icons.verified, color: Colors.blue, size: 14),
                ],
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber.withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Text('✨', style: TextStyle(fontSize: 12)),
                      const SizedBox(width: 4),
                      Text(
                        '+${article.xpReward} XP',
                        style: const TextStyle(
                          color: Colors.amber,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}