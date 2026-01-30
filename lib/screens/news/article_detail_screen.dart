import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/news_article_model.dart';
import '../../theme/theme.dart';

class ArticleDetailScreen extends StatefulWidget {
  final String articleId;

  const ArticleDetailScreen({super.key, required this.articleId});

  @override
  State<ArticleDetailScreen> createState() => _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends State<ArticleDetailScreen> {
  bool _hasReadArticle = false;
  bool _xpClaimed = false;

  final Map<String, NewsArticleModel> _articles = {
    '1': NewsArticleModel(
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
    '2': NewsArticleModel(
      id: '2',
      title: 'ČR: Novela zákona o konopí míří do sněmovny',
      tldr: 'Vláda schválila novelu umožňující cannabis kluby a domácí pěstování do 5 rostlin.',
      whyItMatters: 'První reálný krok k dekriminalizaci v ČR. Pokud projde, změní to život tisícům lidí.',
      content: '''
Česká vláda schválila dlouho očekávanou novelu zákona o návykových látkách.

## Hlavní body novely:

1. Cannabis kluby - neziskové organizace mohou pěstovat pro členy
2. Domácí pěstování - až 5 rostlin pro osobní potřebu
3. Dekriminalizace - držení do 25g nebude trestné
4. Řidičáky - nové limity THC v krvi

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
    '3': NewsArticleModel(
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

CBD skupina: 42% snížení úzkosti
Placebo skupina: 12% snížení úzkosti

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
    '4': NewsArticleModel(
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
    '5': NewsArticleModel(
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
    '6': NewsArticleModel(
      id: '6',
      title: 'Cannabis Cup 2025: Nejlepší strain je český!',
      tldr: 'Strain "Bohemian Haze" od českého grower kolektivu vyhrál prestižní High Times Cannabis Cup v kategorii Sativa.',
      whyItMatters: 'Důkaz, že česká genetika patří ke světové špičce. Národní hrdost!',
      content: '''
Na letošním High Times Cannabis Cup v Amsterdamu zvítězil český strain Bohemian Haze.

## O vítězném strainu

- Název: Bohemian Haze
- Typ: Sativa (85%)
- THC: 24%
- Terpeny: Terpinolene, Limonene, Pinene
- Genetika: Czech Haze x Super Silver

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
    '7': NewsArticleModel(
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
    '8': NewsArticleModel(
      id: '8',
      title: 'Genetics Report: Top 5 strainů roku 2025',
      tldr: 'Runtz, Gelato 41, Jealousy, Gary Payton a Zoap dominují trhu. Trend směřuje k dezertovým profilům.',
      whyItMatters: 'Víš co je teď hot. Můžeš hledat tyto genetiky nebo jejich kříže.',
      content: '''
Analýza prodejních dat z legálních trhů odhaluje top genetiky roku.

## Top 5 strainů 2025

1. Runtz
- Rodič: Zkittlez x Gelato
- Profil: Sladký, ovocný
- THC: 19-29%

2. Gelato 41
- Rodič: Sunset Sherbet x Thin Mint GSC
- Profil: Krémový, dezertový
- THC: 20-25%

3. Jealousy
- Rodič: Sherbert Bx1 x Gelato 41
- Profil: Komplexní, zemitý
- THC: 25-30%

4. Gary Payton
- Rodič: The Y x Snowman
- Profil: Sladký, plynový
- THC: 20-25%

5. Zoap
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
  };

  NewsArticleModel? get _article => _articles[widget.articleId];

  void _claimXP() {
    if (_xpClaimed) return;
    setState(() => _xpClaimed = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Text('✨', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text('+${_article?.xpReward ?? 15} XP za přečtení!'),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted) setState(() => _hasReadArticle = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final article = _article;

    if (article == null) {
      return Scaffold(
        backgroundColor: AppColors.functionalBg,
        appBar: AppBar(
          backgroundColor: AppColors.functionalBg,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(
          child: Text('Článek nenalezen', style: TextStyle(color: Colors.white)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.functionalBg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppColors.functionalBg,
            pinned: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => context.pop(),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.bookmark_border, color: Colors.white),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.share, color: Colors.white),
                onPressed: () {},
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withAlpha(30),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          article.category.label,
                          style: TextStyle(color: AppColors.accent, fontSize: 13),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        article.region.label,
                        style: TextStyle(color: AppColors.functionalMuted),
                      ),
                      const Spacer(),
                      if (article.isVerified)
                        Row(
                          children: [
                            const Icon(Icons.verified, color: Colors.blue, size: 16),
                            const SizedBox(width: 4),
                            const Text(
                              'Ověřeno',
                              style: TextStyle(color: Colors.blue, fontSize: 12),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    article.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        article.source,
                        style: TextStyle(color: AppColors.accent),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.access_time, color: AppColors.functionalMuted, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${article.readTimeMinutes} min čtení',
                        style: TextStyle(color: AppColors.functionalMuted),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        article.timeAgo,
                        style: TextStyle(color: AppColors.functionalMuted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withAlpha(20),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.accent.withAlpha(50)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text('⚡', style: TextStyle(fontSize: 18)),
                            const SizedBox(width: 8),
                            Text(
                              'TL;DR',
                              style: TextStyle(
                                color: AppColors.accent,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          article.tldr,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.amber.withAlpha(20),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.withAlpha(50)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text('💡', style: TextStyle(fontSize: 18)),
                            const SizedBox(width: 8),
                            const Text(
                              'Proč tě to má zajímat',
                              style: TextStyle(
                                color: Colors.amber,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          article.whyItMatters,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    article.content,
                    style: TextStyle(
                      color: AppColors.functionalMuted,
                      fontSize: 16,
                      height: 1.7,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: article.tags.map((tag) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.functionalSurface,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '#$tag',
                        style: TextStyle(color: AppColors.functionalMuted, fontSize: 13),
                      ),
                    )).toList(),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _hasReadArticle && !_xpClaimed ? _claimXP : null,
                      icon: Text(_xpClaimed ? '✅' : '✨', style: const TextStyle(fontSize: 20)),
                      label: Text(
                        _xpClaimed
                            ? 'XP získáno!'
                            : _hasReadArticle
                                ? 'Získat +${article.xpReward} XP'
                                : 'Čti dál pro XP...',
                        style: TextStyle(
                          color: _xpClaimed ? Colors.white : Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _xpClaimed
                            ? Colors.green
                            : _hasReadArticle
                                ? Colors.amber
                                : AppColors.functionalSurface,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}