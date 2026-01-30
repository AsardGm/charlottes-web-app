import '../models/myth_buster_model.dart';

/// Database mýtů a faktů o konopí
class MythBusterData {
  static final List<CannabisMyth> allMyths = [
    // GENETICS MYTHS
    CannabisMyth(
      id: 'myth_indica_sleep',
      mythStatement: 'Indica = spánek, Sativa = energie',
      isTrue: false,
      reality: 'MÝTUS!',
      explanation:
          'Indica/Sativa rozdělení je outdated. Účinky závisí na terpenech a celkovém chemotvaru, ne na tvaru listu. Myrcene tě uspí, limonene tě probere - ať už je to "indica" nebo "sativa".',
      category: MythCategory.genetics,
      xpReward: 15,
    ),
    CannabisMyth(
      id: 'myth_thc_percentage',
      mythStatement: 'Víc % THC = lepší efekt',
      isTrue: false,
      reality: 'MÝTUS!',
      explanation:
          'Entourage efekt > THC%. Strain s 15% THC a správnými terpeny může být silnější než 25% THC bez terpenů. Chemovar (profil) > procenta.',
      category: MythCategory.compounds,
      xpReward: 15,
    ),
    CannabisMyth(
      id: 'myth_thc_relax',
      mythStatement: 'THC = relax a klid',
      isTrue: false,
      reality: 'ZÁLEŽÍ!',
      explanation:
          'THC může způsobit úzkost u citlivých lidí nebo vysokých dávek. Pro relax je často lepší CBD:THC ratio (např. 1:1) nebo nízké dávky. Set & setting hrají roli.',
      category: MythCategory.effects,
      xpReward: 15,
    ),
    CannabisMyth(
      id: 'myth_cbd_no_psycho',
      mythStatement: 'CBD nemá žádné psychoaktivní účinky',
      isTrue: false,
      reality: 'ČÁSTEČNĚ PRAVDA',
      explanation:
          'CBD není intoxikující (nebudeš "high"), ale JE psychoaktivní - ovlivňuje mood, anxiety, vnímání bolesti. Psychoaktivní ≠ intoxikující.',
      category: MythCategory.compounds,
      xpReward: 10,
    ),
    CannabisMyth(
      id: 'myth_terpenes_matter',
      mythStatement: 'Terpeny ovlivňují efekt stejně jako kanabinoidy',
      isTrue: true,
      reality: 'PRAVDA!',
      explanation:
          'Terpeny nejsou jen vůně. Myrcene zesiluje THC, limonene zlepšuje náladu, linalool uklidňuje. Proto stejný % THC má různé efekty u různých strainů.',
      category: MythCategory.compounds,
      xpReward: 15,
    ),
    CannabisMyth(
      id: 'myth_tolerance',
      mythStatement: 'Tolerance se dá resetovat jen T-breakem',
      isTrue: false,
      reality: 'MÝTUS!',
      explanation:
          'Rotace strainů s různými chemovary může snížit toleranci bez pauzy. CB1 receptory reagují jinak na různé profily. Variety > frequency.',
      category: MythCategory.consumption,
      xpReward: 15,
    ),
    CannabisMyth(
      id: 'myth_edibles_same',
      mythStatement: 'Edibles = jen delší kouření',
      isTrue: false,
      reality: 'MÝTUS!',
      explanation:
          'THC v edibles se v játrech mění na 11-hydroxy-THC - 2-3× silnější než běžné THC. Proto jsou edibles intenzivnější a trvají 6-8h místo 2-3h.',
      category: MythCategory.consumption,
      xpReward: 15,
    ),
    CannabisMyth(
      id: 'myth_purple_stronger',
      mythStatement: 'Fialové strainy jsou silnější',
      isTrue: false,
      reality: 'MÝTUS!',
      explanation:
          'Fialová barva = anthokyany (pigmenty), nemá nic společného se silou. Je to estetika + genetika + teplota pěstování. Žádný vztah k THC.',
      category: MythCategory.genetics,
      xpReward: 10,
    ),
    CannabisMyth(
      id: 'myth_mango_boost',
      mythStatement: 'Mango zesiluje účinky THC',
      isTrue: true,
      reality: 'PRAVDA!',
      explanation:
          'Mango obsahuje myrcene, terpen který zvyšuje permeabilitu BBB (blood-brain barrier) a umožňuje THC rychleji proniknout do mozku. Jezte mango 45 min před.',
      category: MythCategory.effects,
      xpReward: 10,
    ),
    CannabisMyth(
      id: 'myth_landrace_pure',
      mythStatement: 'Landrace strainy jsou "čisté" a nejlepší',
      isTrue: false,
      reality: 'ROMANTIZACE',
      explanation:
          'Landrace jsou originální geografické odrůdy, ale nejsou automaticky "lepší". Moderní hybridy mají optimalizované profily. Nostalgie ≠ kvalita.',
      category: MythCategory.genetics,
      xpReward: 10,
    ),
    CannabisMyth(
      id: 'myth_cbd_counter',
      mythStatement: 'CBD přímo neutralizuje THC',
      isTrue: false,
      reality: 'ZJEDNODUŠENÍ',
      explanation:
          'CBD neruší THC, ale moduluje jeho účinky přes různé receptory. Snižuje anxiety a paranoiu, ale neblokuje high. Je to spolupráce, ne antagonismus.',
      category: MythCategory.compounds,
      xpReward: 15,
    ),
    CannabisMyth(
      id: 'myth_chronic_lazy',
      mythStatement: 'Chronické užívání = amotivační syndrom',
      isTrue: false,
      reality: 'KONTROVERZNÍ',
      explanation:
          'Amotivační syndrom není potvrzený jako přímý důsledek. Může být symptom deprese nebo špatného strain matche. Někteří lidé jsou produktivnější s konopím.',
      category: MythCategory.effects,
      xpReward: 15,
    ),
  ];

  /// Get myths by category
  static List<CannabisMyth> getMythsByCategory(MythCategory category) {
    return allMyths.where((myth) => myth.category == category).toList();
  }

  /// Get random myth
  static CannabisMyth getRandomMyth() {
    allMyths.shuffle();
    return allMyths.first;
  }

  /// Get myth by ID
  static CannabisMyth? getMythById(String id) {
    try {
      return allMyths.firstWhere((myth) => myth.id == id);
    } catch (e) {
      return null;
    }
  }
}
