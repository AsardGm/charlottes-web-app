import '../models/quality_check_model.dart';

/// Database kvality a bezpečnosti - harm reduction guide
class QualityCheckData {
  // VISUAL INSPECTION
  static const List<QualityCheckItem> visualChecks = [
    QualityCheckItem(
      id: 'visual_trichomes',
      category: QualityCheckCategory.visual,
      title: 'Trichomy (krystalky)',
      description: 'Zdravé květy mají viditelné trichomy - průhledné/mléčné "krystalky"',
      type: CheckType.goodSign,
      bulletPoints: [
        'Průhledné nebo mléčně bílé hlavičky',
        'Rovnoměrně rozložené po květu',
        'Ne příliš lepkavé (může být chemický postřik)',
        'Přirozený třpyt, ne umělý lesk',
      ],
      imageHint: 'Lupy nebo makro foto odhalí skutečné trichomy vs chemický coating',
    ),
    QualityCheckItem(
      id: 'visual_color',
      category: QualityCheckCategory.visual,
      title: 'Barva květu',
      description: 'Přirozené barvy vs podezřelé odstíny',
      type: CheckType.neutralInfo,
      bulletPoints: [
        '✅ Zelená (různé odstíny), fialová, oranžová',
        '🚩 Příliš jasná/neonová zelená (možný postřik)',
        '🚩 Hnědá/šedá/plesnivá (špatné skladování)',
        '🚩 Bílý prášek (plíseň nebo chemický coating)',
      ],
      imageHint: 'Přirozené barvy jsou matné, ne lesklé jako lak',
    ),
    QualityCheckItem(
      id: 'visual_structure',
      category: QualityCheckCategory.visual,
      title: 'Struktura a konzistence',
      description: 'Jak by měl vypadat kvalitní květ',
      type: CheckType.goodSign,
      bulletPoints: [
        'Husté, ale ne kamenné (rock-hard může být PGR)',
        'Viditelné pistily (oranžové vlásky)',
        'Nerozpadá se na prach (over-dry)',
        'Není vlhký/lepkavý (plíseň risk)',
      ],
    ),
    QualityCheckItem(
      id: 'visual_seeds_stems',
      category: QualityCheckCategory.visual,
      title: 'Semínka a stonky',
      description: 'Red flags v obsahu',
      type: CheckType.redFlag,
      bulletPoints: [
        '🚩 Hodně semínek = špatná kvalita, opylený květ',
        '🚩 Tlustý stonek = platíš za váhu stonku',
        '✅ Minimum stonku, žádná semínka',
        'Trimming kvalita (dobře ostříhané listy)',
      ],
    ),
  ];

  // SMELL TEST
  static const List<QualityCheckItem> smellChecks = [
    QualityCheckItem(
      id: 'smell_terpenes',
      category: QualityCheckCategory.smell,
      title: 'Přírodní vs syntetické terpeny',
      description: 'Jak poznat umělý zápach',
      type: CheckType.redFlag,
      bulletPoints: [
        '✅ Přirozená vůně: komplexní, vrstevnatá, mění se',
        '🚩 Syntetická: příliš intenzivní, jednoduchá, "parfémová"',
        '🚩 Chemický zápach: benzín, plast, čistící prostředky',
        '🚩 Žádný zápach: pravděpodobně starý nebo syntetický',
      ],
      imageHint: 'Rozetři mezi prsty - přirozené terpeny se postupně uvolňují',
    ),
    QualityCheckItem(
      id: 'smell_spray',
      category: QualityCheckCategory.smell,
      title: 'Detekce chemických sprejů',
      description: 'Varovné signály postřiků',
      type: CheckType.redFlag,
      bulletPoints: [
        '🚩 Parfémová vůně (citrusové spreje)',
        '🚩 Příliš silná vůně okamžitě po otevření',
        '🚩 Zápach zmizí po pár hodinách (syntetické terpeny se rychle vypaří)',
        '🚩 "Lesklý" povrch + silná vůně = spray kombinace',
      ],
    ),
    QualityCheckItem(
      id: 'smell_mold',
      category: QualityCheckCategory.smell,
      title: 'Plíseň a kontaminace',
      description: 'Nebezpečné zápachy',
      type: CheckType.redFlag,
      bulletPoints: [
        '🚩 Plesňový/vlhký zápach (jako starý sklep)',
        '🚩 Hnilobný zápach',
        '🚩 Amoniak (špatné vytvrzování)',
        '❌ NIKDY nekuř plesnivou trávu - vážné zdravotní riziko',
      ],
    ),
  ];

  // SYNTHETIC CANNABINOIDS
  static const List<SyntheticWarning> syntheticWarnings = [
    SyntheticWarning(
      substance: 'HHC (Hexahydrocannabinol)',
      commonNames: 'HHC vapes, HHC flowers',
      danger: 'Polosyntetický cannabinoid. Není přirozeně se vyskytující v rostlině. Neznámé dlouhodobé účinky.',
      howToSpot: [
        'Prodáváno jako "legální THC"',
        'Často v prémiové ceně s marketingem',
        'Vapes s HHC často mají chemickou chuť',
        'Efekt je jiný než klasické THC - méně předvídatelný',
      ],
      severity: SeverityLevel.medium,
    ),
    SyntheticWarning(
      substance: 'K2 / Spice (Syntetické cannabinoidy)',
      commonNames: 'K2, Spice, "Legal High", herbal incense',
      danger: 'EXTRÉMNĚ NEBEZPEČNÉ. Umělé chemikálie napodobující THC. Riziko psychózy, záchvatů, smrti.',
      howToSpot: [
        '❌ Prodáváno jako "legal high" nebo "not for human consumption"',
        '❌ Neuvěřitelně nízká cena',
        '❌ Homogenní zelená hmota (vypadá stříkaně)',
        '❌ Chemický zápach, příliš silné účinky',
      ],
      severity: SeverityLevel.extreme,
    ),
    SyntheticWarning(
      substance: 'Delta-8 THC',
      commonNames: 'Delta-8, D8',
      danger: 'Polosyntetický. Vyrobeno chemickou konverzí z CBD. Může obsahovat vedlejší produkty.',
      howToSpot: [
        'Prodáváno jako "legal THC alternative"',
        'Často v destilátové formě',
        'Lab testy často chybí nebo neúplné',
        'Mírně jiný efekt než Delta-9 THC',
      ],
      severity: SeverityLevel.medium,
    ),
    SyntheticWarning(
      substance: 'THCO (THC-O-Acetate)',
      commonNames: 'THC-O, ATHC',
      danger: 'Zcela syntetický. Velmi silný, nepředvídatelné účinky. Bezpečnost neznámá.',
      howToSpot: [
        'Marketing jako "3x silnější než THC"',
        'Vždy synteticky vyrobený',
        'Velmi silné psychoaktivní účinky',
        'Prodáváno v "legal gray zone"',
      ],
      severity: SeverityLevel.high,
    ),
  ];

  // CHEMICAL SPRAYS & PESTICIDES
  static const List<QualityCheckItem> sprayChecks = [
    QualityCheckItem(
      id: 'spray_terpene',
      category: QualityCheckCategory.sprays,
      title: 'Syntetické terpenové spraye',
      description: 'Jak poznat napraskanou vůni',
      type: CheckType.redFlag,
      bulletPoints: [
        '🚩 Příliš intenzivní vůně (jako parfém)',
        '🚩 Vůně zmizí po pár dnech (přirozené terpeny vydrží)',
        '🚩 Jednoduchá vůně (např. jen "citrus" bez komplexity)',
        '🚩 Lepkavý/mokrý povrch',
      ],
    ),
    QualityCheckItem(
      id: 'spray_glass',
      category: QualityCheckCategory.sprays,
      title: 'Skleněný prášek (Glass spray)',
      description: 'EXTRÉMNĚ NEBEZPEČNÉ - přidání váhy',
      type: CheckType.redFlag,
      bulletPoints: [
        '❌ Přidává se pro váhu, vypadá jako trichomy',
        '❌ Test: Rozdrť trochu na černém povrchu - sklo třpytá jinak',
        '❌ Test: CD scratch test - sklo škrábe CD',
        '❌ ZDRAVOTNÍ RIZIKO: inhalace skla ničí plíce',
      ],
    ),
    QualityCheckItem(
      id: 'spray_sugar',
      category: QualityCheckCategory.sprays,
      title: 'Cukr/Sirup spray',
      description: 'Přidání váhy a "lepkavosti"',
      type: CheckType.redFlag,
      bulletPoints: [
        '🚩 Příliš lepkavé (jako med)',
        '🚩 Sladká chuť při vykuřování',
        '🚩 Karamelizuje při zapálení',
        '🚩 Přitahuje hmyz/plíseň',
      ],
    ),
    QualityCheckItem(
      id: 'spray_pgr',
      category: QualityCheckCategory.sprays,
      title: 'PGR (Plant Growth Regulators)',
      description: 'Chemické růstové regulátory',
      type: CheckType.redFlag,
      bulletPoints: [
        '🚩 Neuvěřitelně husté, "kamenné" buds',
        '🚩 Málo trichomů přes hustotu',
        '🚩 Hnědé/oranžové pistily úplně zašlé',
        '🚩 Slabý zápach přes velikost',
      ],
    ),
  ];

  // EXTRACT TYPES
  static const List<ExtractInfo> extractTypes = [
    ExtractInfo(
      name: 'Rosin',
      method: 'Solventless - pouze teplo a tlak',
      safety: '✅ NEJBEZPEČNĚJŠÍ - žádná rozpouštědla',
      characteristics: [
        'Zlatá/jantarová barva',
        'Plný terpenový profil',
        'Dražší (náročnější výroba)',
        'Měkká, vosk-like konzistence',
      ],
      isSolventless: true,
      qualityRating: 'Premium',
    ),
    ExtractInfo(
      name: 'Live Rosin',
      method: 'Rosin z čerstvě zmrazených rostlin',
      safety: '✅ PREMIUM - nejlepší terpeny',
      characteristics: [
        'Světlá barva, "sauce" konzistence',
        'Extrémně aromatický',
        'Velmi drahý',
        'Nejlepší terpenový profil',
      ],
      isSolventless: true,
      qualityRating: 'Premium',
    ),
    ExtractInfo(
      name: 'BHO (Butane Hash Oil)',
      method: 'Extrakce butanem',
      safety: '⚠️ Bezpečný pokud SPRÁVNĚ purged (čištěný)',
      characteristics: [
        'Různé formy: shatter, wax, crumble',
        'High potency',
        'Musí být lab tested (zbytkový butane)',
        'Kvalita závisí na purging procesu',
      ],
      isSolventless: false,
      qualityRating: 'Good',
    ),
    ExtractInfo(
      name: 'CO2 Extract',
      method: 'Superkritická CO2 extrakce',
      safety: '✅ Bezpečný - CO2 se úplně odpaří',
      characteristics: [
        'Čistý produkt',
        'Často v cartridges',
        'Dobrá kontrola terpenů',
        'Průmyslová metoda',
      ],
      isSolventless: false,
      qualityRating: 'Good',
    ),
    ExtractInfo(
      name: 'Distillate',
      method: 'Destilace - ultra čištění',
      safety: '⚠️ Čistý THC, ale BEZ terpenů',
      characteristics: [
        'Téměř čirý, velmi vysoké THC%',
        'Žádné terpeny (často se přidávají zpět)',
        'Žádná chuť/vůně bez přidaných terpenů',
        'Často v levných cartridges',
      ],
      isSolventless: false,
      qualityRating: 'Good',
    ),
    ExtractInfo(
      name: 'PHO (Propane Hash Oil)',
      method: 'Extrakce propanem',
      safety: '⚠️ Podobné jako BHO',
      characteristics: [
        'Často lepší terpenová retence než BHO',
        'Budder/batter konzistence',
        'Musí být správně purged',
        'Lab testy důležité',
      ],
      isSolventless: false,
      qualityRating: 'Good',
    ),
    ExtractInfo(
      name: 'Rick Simpson Oil (RSO)',
      method: 'Alkoholová extrakce, full-spectrum',
      safety: '⚠️ Pro orální užití, NE pro dabbing',
      characteristics: [
        'Tmavá, hustá pasta',
        'Full-spectrum (všechny kanabinoidy)',
        'Primárně medicinální použití',
        'Vysoká dávka',
      ],
      isSolventless: false,
      qualityRating: 'Good',
    ),
  ];

  // ORGANIC VS CHEMICAL
  static const List<QualityCheckItem> organicChecks = [
    QualityCheckItem(
      id: 'organic_growing',
      category: QualityCheckCategory.organic,
      title: 'Organic / Bio pěstování',
      description: 'Co znamená "organic" cannabis',
      type: CheckType.goodSign,
      bulletPoints: [
        '✅ Organic soil / living soil',
        '✅ Přírodní hnojiva (kompost, guano)',
        '✅ Žádné syntetické pesticidy',
        '✅ Čistá voda (filtrovaná/pramenitá)',
      ],
    ),
    QualityCheckItem(
      id: 'organic_flush',
      category: QualityCheckCategory.organic,
      title: 'Flushing (proplachování)',
      description: 'Odstranění reziduí před sklizní',
      type: CheckType.goodSign,
      bulletPoints: [
        '✅ 1-2 týdny čistá voda před sklizní',
        '✅ Odstraní zbytkové soli a hnojiva',
        '✅ Poznáš podle: bílý popel, hladká kouř',
        '🚩 Špatný flush: černý popel, drsný kouř, chemická chuť',
      ],
    ),
    QualityCheckItem(
      id: 'organic_cure',
      category: QualityCheckCategory.organic,
      title: 'Proper curing (vytvrzování)',
      description: 'Rozdíl mezi rushed a quality cure',
      type: CheckType.goodSign,
      bulletPoints: [
        '✅ 2-4 týdny vytvrzování minimum',
        '✅ Hladká kouř, plná chuť',
        '✅ Správná vlhkost (60-65% RH)',
        '🚩 Quick-dry: drsná kouř, slabá chuť, "zelený" zápach',
      ],
    ),
  ];

  // QUICK REFERENCE CARDS
  static const List<QuickRefCard> quickRefCards = [
    QuickRefCard(
      title: 'Ash Test',
      question: 'Jakou barvu má popel?',
      answers: {
        'Bílý/šedý popel': '✅ Dobře propláchlá, čistá tráva',
        'Černý popel': '🚩 Špatný flush, zbytkové chemikálie',
        'Tvrdý popel (nerozpadá se)': '🚩 Možné kontaminanty',
      },
    ),
    QuickRefCard(
      title: 'Water Test',
      question: 'Co se stane když dáš kousek do vody?',
      answers: {
        'Klesne na dno': '✅ Normální',
        'Plave na povrchu': '⚠️ Možná příliš suchá nebo lehká',
        'Voda se zbarví': '🚩 Možný spray/coating',
        'Lesklá vrstva na vodě': '🚩 Olej/chemický spray',
      },
    ),
    QuickRefCard(
      title: 'Light Test',
      question: 'Jak vypadá pod světlem/lupou?',
      answers: {
        'Průhledné/mléčné trichomy': '✅ Přirozené',
        'Třpytivý prášek (jiný než trichomy)': '🚩 Možné sklo/chemický coating',
        'Lesklý povrch': '🚩 Spray/coating',
        'Husté trichomy, ale slabý zápach': '🚩 Možné PGR',
      },
    ),
  ];

  /// Get all checks by category
  static List<QualityCheckItem> getByCategory(QualityCheckCategory category) {
    switch (category) {
      case QualityCheckCategory.visual:
        return visualChecks;
      case QualityCheckCategory.smell:
        return smellChecks;
      case QualityCheckCategory.sprays:
        return sprayChecks;
      case QualityCheckCategory.organic:
        return organicChecks;
      default:
        return [];
    }
  }

  /// Get all data
  static List<QualityCheckItem> get allChecks => [
        ...visualChecks,
        ...smellChecks,
        ...sprayChecks,
        ...organicChecks,
      ];
}
