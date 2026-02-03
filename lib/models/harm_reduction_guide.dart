import 'package:flutter/foundation.dart';

/// Harm Reduction Guide - Educational content model
@immutable
class HarmReductionGuide {
  final String id;
  final String category;
  final String title;
  final String subtitle;
  final String icon;
  final HarmReductionContent content;

  const HarmReductionGuide({
    required this.id,
    required this.category,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.content,
  });

  static List<HarmReductionGuide> get allGuides => [
        // Basics
        const HarmReductionGuide(
          id: 'start-low-go-slow',
          category: 'Základy',
          title: 'Start Low, Go Slow',
          subtitle: 'Zlaté pravidlo bezpečného dávkování',
          icon: '🐌',
          content: HarmReductionContent(
            keyPoints: [
              'Vždy začni s nízkou dávkou',
              'Počkej na plný účinek (15 min kouření, 2h edibles)',
              'Postupně zvyšuj pokud potřeba',
              'Nelze vzít zpět, ale můžeš přidat',
            ],
            recommendations: [
              '**Kouření:** 1-2 tahy pro začátečníky',
              '**Edibles:** 2.5-5mg THC, počkej 2 hodiny',
              '**Vaping:** Začni na nižší teplotě (160-180°C)',
            ],
            warnings: [
              'Nikdy nepřidávej u edibles dříve než za 2 hodiny',
              'Vysoká tolerance ≠ bezpečné vysoké dávky',
              'Předávkování je nepříjemné, ale projde to',
            ],
          ),
        ),
        const HarmReductionGuide(
          id: 'set-and-setting',
          category: 'Základy',
          title: 'Set & Setting',
          subtitle: 'Okolnosti určují 80% tvé zkušenosti',
          icon: '🧘',
          content: HarmReductionContent(
            keyPoints: [
              'Set (40%) = tvůj mentální stav',
              'Setting (40%) = prostředí kolem tebe',
              'Substance (20%) = co bereš',
              'Všechny 3 musí být v pohodě',
            ],
            recommendations: [
              'Ideální set: Relaxovaná mysl, pozitivní nálada, jasný záměr',
              'Ideální setting: Bezpečné místo, důvěryhodní lidé, čas na to',
              'Pokud set NEBO setting není OK → počkej',
            ],
            warnings: [
              'Špatná nálada + konopí = vyšší riziko paranoia',
              'Stresové prostředí = bad trip potenciál',
              'Nikdy pod tlakem ostatních',
            ],
          ),
        ),
        const HarmReductionGuide(
          id: 'tolerance-management',
          category: 'Tolerance',
          title: 'Správa tolerance',
          subtitle: 'Jak udržet toleranci nízkou',
          icon: '📉',
          content: HarmReductionContent(
            keyPoints: [
              'Tolerance roste s frekvencí použití',
              'Vyšší tolerance = více peněz, méně účinku',
              'T-breaky jsou nejefektivnější řešení',
              'Prevention is better than cure',
            ],
            recommendations: [
              'Dělej T-break každé 2-3 měsíce (minimálně týden)',
              'Preferuj 1-3x týdně místo daily use',
              'Rotuj strains a metody konzumace',
              'Používej Charlotte\'s T-Break Tracker',
            ],
            warnings: [
              '6+ měsíců daily use = vysoká tolerance',
              'Vysoká tolerance zvyšuje riziko závislosti',
              'Více ≠ lepší, jen dražší a rizikovější',
            ],
          ),
        ),

        // Methods
        const HarmReductionGuide(
          id: 'vaping-vs-smoking',
          category: 'Metody',
          title: 'Vaping vs. Kouření',
          subtitle: 'Nejbezpečnější metoda inhalace',
          icon: '💨',
          content: HarmReductionContent(
            keyPoints: [
              'Vaping je VÝZNAMNĚ bezpečnější pro plíce',
              'Žádné spalování = žádné karcinogeny',
              'Lepší kontrola teploty = efektivnější',
              'Lepší chuť (zachování terpenů)',
            ],
            recommendations: [
              'Teplota 160-180°C pro chuť a terpeny',
              'Teplota 180-200°C pro balanced THC',
              'Teplota 200-220°C pro maximální THC',
              'Investuj do kvalitního vaporizéru (long-term úspora)',
            ],
            warnings: [
              'Kouření poškozuje plíce (dehet, karcinogeny)',
              'I vaping má určitou zátěž pro dýchací cesty',
              'Nekvalitní vape pens mohou obsahovat škodlivé látky',
            ],
          ),
        ),
        const HarmReductionGuide(
          id: 'edibles-safety',
          category: 'Metody',
          title: 'Bezpečné edibles',
          subtitle: 'Jak se nedostat do problémů',
          icon: '🍪',
          content: HarmReductionContent(
            keyPoints: [
              'Nástup: 30 minut až 2 hodiny',
              'Trvání: 4-8 hodin (vs. 2-4h kouření)',
              '11-OH-THC je silnější než delta-9-THC',
              'Nejčastější příčina "green out"',
            ],
            recommendations: [
              'START: 2.5-5mg THC pro začátečníky',
              'Počkej MINIMÁLNĚ 2 hodiny před dalším',
              'Jez s tukem (lepší a předvídatelnější absorpce)',
              'Měj bezpečný setting (budeš high hodiny)',
            ],
            warnings: [
              'NIKDY nepřidávej dříve než za 2 hodiny',
              'Domácí edibles = nepředvídatelná síla',
              'Nekombinuj s alkoholem (intenzivnější účinek)',
              'Schovej před dětmi a domácími mazlíčky',
            ],
          ),
        ),

        // Health
        const HarmReductionGuide(
          id: 'mental-health',
          category: 'Zdraví',
          title: 'Mentální zdraví',
          subtitle: 'Kdy být extra opatrný',
          icon: '🧠',
          content: HarmReductionContent(
            keyPoints: [
              'Konopí může pomoci i uškodit mental health',
              'Rodinná anamnéza psychózy = vyšší riziko',
              'THC může vyvolat/zhoršit úzkost a depresi',
              'Mladý věk (<25) = vyšší zranitelnost',
            ],
            recommendations: [
              'Pokud máš úzkost: preferuj CBD-dominant strains',
              'Neužívej preventivně na úzkost/depresi (hledej terapii)',
              'Sleduj svoje reakce v Charlotte\'s deníku',
              'Komunikuj s terapeutem pokud bereš',
            ],
            warnings: [
              'Stop pokud: paranoia, halucinace, depersonalizace',
              'Rodinná anamnéza schizofrenie = vysoké riziko',
              'Pravidelné užívání může maskovat problémy',
              'Pokud mentální zdraví klesá → přeruš a hledej pomoc',
            ],
          ),
        ),
        const HarmReductionGuide(
          id: 'dependency-signs',
          category: 'Závislost',
          title: 'Znaky závislosti',
          subtitle: 'Jak poznat kdy máš problém',
          icon: '🔗',
          content: HarmReductionContent(
            keyPoints: [
              '9% uživatelů vyvinuje závislost',
              '16-30% při denním užívání nebo mladém věku',
              'Psychická, ne fyzická závislost',
              'DSM-5: 2+ kritérií = problém',
            ],
            recommendations: [
              'Sleduj frekvenci a množství konzumace',
              'Dělej pravidelné T-breaky (test kontroly)',
              'Ptej se: "Beru protože chci nebo protože musím?"',
              'Hledej podporu když si všimneš problému',
            ],
            warnings: [
              'Bereš hned po probuzení? Red flag.',
              'Nemůžeš přestat i když chceš? Problém.',
              'Zanedbáváš závazky kvůli konzumaci? Pozor.',
              'Lžeš o množství? Varovný signál.',
            ],
          ),
        ),

        // Safety
        const HarmReductionGuide(
          id: 'green-out-help',
          category: 'Bezpečnost',
          title: 'První pomoc: Green Out',
          subtitle: 'Co dělat při předávkování',
          icon: '🆘',
          content: HarmReductionContent(
            keyPoints: [
              'Green out = too much THC, nepříjemné ale ne nebezpečné',
              'Nikdy nikdo nezemřel na THC overdose',
              'Projde to do 3-6 hodin',
              'Nejčastěji u edibles',
            ],
            recommendations: [
              '1. ZKLIDNI SE - Nic ti nehrozí, projde to',
              '2. Lehni si v bezpečném prostředí',
              '3. Pij vodu (ne alkohol)',
              '4. Černý pepř - čichni nebo žvýkej (pomáhá s anxiety)',
              '5. CBD pokud máš (antagonizuje THC)',
              '6. Zavolej důvěryhodnou osobu',
            ],
            warnings: [
              'Symptomy: intenzivní paranoia, nevolnost, tachykardie',
              'Pokud vážné dýchací problémy → volej 155',
              'Lékaři jsou tu aby pomohli, ne soudili',
              'Nekombinuj s alkoholem nebo jinými substance',
            ],
          ),
        ),
        const HarmReductionGuide(
          id: 'driving-danger',
          category: 'Bezpečnost',
          title: 'Nikdy neřiď pod vlivem',
          subtitle: 'THC a řízení = smrtelná kombinace',
          icon: '🚗',
          content: HarmReductionContent(
            keyPoints: [
              'THC zhoršuje reakční čas o 20-30%',
              'Zhoršená koordinace a rozhodování',
              'Účinky trvají 4-6 hodin (i když se necítíš high)',
              'Kombinace s alkoholem je extrémně nebezpečná',
            ],
            recommendations: [
              'Počkej MINIMÁLNĚ 6 hodin po konzumaci',
              'Plánuj dopravu dopředu (taxi, MHD, spánek)',
              'Při edibles počkej ještě déle (8-12 hodin)',
              'Pokud denní uživatel: THC v krvi trvá týdny',
            ],
            warnings: [
              'Legální důsledky: ztráta řidičáku, pokuta, trest',
              'Morální důsledky: můžeš zabít sebe i ostatní',
              'Pojišťovna neplatí při nehodě pod vlivem',
              'Žádná výmluva to nestojí za',
            ],
          ),
        ),
      ];

  static List<String> get allCategories => [
        'Základy',
        'Metody',
        'Tolerance',
        'Závislost',
        'Zdraví',
        'Bezpečnost',
      ];

  static List<HarmReductionGuide> getByCategory(String category) {
    return allGuides.where((guide) => guide.category == category).toList();
  }
}

/// Content structure for harm reduction guides
@immutable
class HarmReductionContent {
  final List<String> keyPoints;
  final List<String> recommendations;
  final List<String> warnings;

  const HarmReductionContent({
    required this.keyPoints,
    required this.recommendations,
    required this.warnings,
  });
}

/// Quick harm reduction tips for consumption logging
class HarmReductionTips {
  static List<String> get beforeConsumption => [
        '✅ Znám svou dávku a strain',
        '✅ Jsem v dobrém mentálním stavu',
        '✅ Mám bezpečné prostředí',
        '✅ Mám čas (žádný pressure)',
        '❌ Nebudu řídit další 6+ hodin',
      ];

  static List<String> get duringConsumption => [
        '🐌 Start low, go slow',
        '⏱️ Počkej na plný účinek',
        '💧 Zůstaň hydratovaný',
        '🍽️ Něco v žaludku pomáhá',
        '🎵 Příjemná atmosféra = lepší experience',
      ];

  static List<String> get afterConsumption => [
        '📝 Zaznamenej zkušenost v deníku',
        '🧠 Všimni si účinků (pozitivní i negativní)',
        '⏰ Naplánuj T-break pokud používáš často',
        '💚 Poslechni svoje tělo',
        '🚫 Neřiď minimálně 6 hodin',
      ];

  static String getRandomTip() {
    final allTips = [...beforeConsumption, ...duringConsumption, ...afterConsumption];
    allTips.shuffle();
    return allTips.first;
  }

  static List<String> getTipsForContext(String context) {
    switch (context) {
      case 'before':
        return beforeConsumption;
      case 'during':
        return duringConsumption;
      case 'after':
        return afterConsumption;
      default:
        return beforeConsumption;
    }
  }
}
