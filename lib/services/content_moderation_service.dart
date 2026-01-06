import 'package:supabase_flutter/supabase_flutter.dart';
import 'admin_service.dart';

/// Vysledek moderace obsahu
class ModerationResult {
  final bool isAllowed;
  final String? reason;
  final List<BannedWord> foundWords;
  final List<String> contextViolations; // Pro kontextove poruseni (prodej + polozka)
  final String recommendedAction; // 'allow', 'warn', 'delete', 'block'

  ModerationResult({
    required this.isAllowed,
    this.reason,
    this.foundWords = const [],
    this.contextViolations = const [],
    this.recommendedAction = 'allow',
  });

  factory ModerationResult.allowed() => ModerationResult(
        isAllowed: true,
        recommendedAction: 'allow',
      );

  factory ModerationResult.blocked({
    required String reason,
    List<BannedWord> foundWords = const [],
    List<String> contextViolations = const [],
    required String action,
  }) =>
      ModerationResult(
        isAllowed: false,
        reason: reason,
        foundWords: foundWords,
        contextViolations: contextViolations,
        recommendedAction: action,
      );
}

/// Vyjimka pro zakazany obsah
class ContentBlockedException implements Exception {
  final String message;
  final List<String> blockedWords;
  final String action;

  ContentBlockedException({
    required this.message,
    this.blockedWords = const [],
    required this.action,
  });

  @override
  String toString() => message;
}

/// Sluzba pro moderaci obsahu
///
/// Kontroluje prispevky a komentare na zakazana slova
/// a dalsi nevhodny obsah pred publikovanim.
class ContentModerationService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Cache zakazanych slov (obnovuje se kazdych 5 minut)
  List<BannedWord>? _cachedBannedWords;
  DateTime? _cacheTime;
  static const _cacheDuration = Duration(minutes: 5);

  /// Slova indikujici prodej/nabidku/obchod
  static const List<String> _sellingWords = [
    'prodej', 'prodam', 'prodavam', 'nabizim', 'nabidka',
    'koupit', 'koupim', 'kupuji', 'shenim', 'sehnat',
    'cena', 'kc', 'czk', 'korun', 'za', 'levne', 'sleva',
    'dodam', 'dodani', 'zaslu', 'zasilka', 'postou',
    'vymena', 'vymenim', 'swap', 'trade', 'trading',
    'sell', 'selling', 'buy', 'buying', 'price',
    'kontakt', 'dm', 'piste', 'ozvete', 'telegram', 'signal', 'wickr',
  ];

  /// Zakazane polozky k prodeji (drogy, zbrane, porno atd.)
  static const List<String> _prohibitedItems = [
    // Drogy
    'marihuana', 'marijuana', 'konopi', 'trava', 'huleni', 'joint',
    'kokain', 'cocaine', 'koks', 'snow', 'bile',
    'heroin', 'smack', 'horse',
    'pervitin', 'meth', 'crystal', 'ice', 'pernik',
    'lsd', 'acid', 'tripy', 'houbicky', 'lysohlávky',
    'extaze', 'mdma', 'molly', 'ecstasy',
    'speed', 'amfetamin',
    'crack', 'fentanyl',
    'thc', 'cbd', 'hash', 'hasis',
    'pregabalin', 'lyrica', 'tramadol', 'xanax', 'benzos',
    // Zbrane
    'pistole', 'revolver', 'puska', 'samopal', 'zbran',
    'naboje', 'strelivo', 'munice',
    'nuz', 'maceta', 'boxer', 'teleskop',
    'gun', 'weapon', 'ammo', 'ammunition',
    // Pornografie/nelegalni obsah
    'cp', 'detskaporno', 'childporn',
    // Dalsi nelegalni
    'kradene', 'stolen', 'fake', 'falesne', 'padělek',
    'hacknute', 'cracked', 'warez',
  ];

  /// Ziska seznam zakazanych slov (s cache)
  Future<List<BannedWord>> _getBannedWords() async {
    if (_cachedBannedWords != null &&
        _cacheTime != null &&
        DateTime.now().difference(_cacheTime!) < _cacheDuration) {
      return _cachedBannedWords!;
    }

    try {
      final response = await _supabase.from('banned_words').select().order('word');

      _cachedBannedWords = (response as List)
          .map((json) => BannedWord.fromJson(json as Map<String, dynamic>))
          .toList();
      _cacheTime = DateTime.now();
      return _cachedBannedWords!;
    } catch (_) {
      return [];
    }
  }

  /// Vymaze cache (volat po pridani/odebrani zakazaneho slova)
  void invalidateCache() {
    _cachedBannedWords = null;
    _cacheTime = null;
  }

  /// Zkontroluje zda text obsahuje nabidku/prodej zakazanych polozek
  List<String> _checkProhibitedSales(String text) {
    final lowerText = text.toLowerCase();
    final violations = <String>[];

    // Najdi vsechna prodejni slova v textu
    final foundSellingWords = <String>[];
    for (final word in _sellingWords) {
      if (lowerText.contains(word)) {
        foundSellingWords.add(word);
      }
    }

    // Pokud nejsou zadna prodejni slova, neni co resit
    if (foundSellingWords.isEmpty) return [];

    // Najdi zakazane polozky
    for (final item in _prohibitedItems) {
      final pattern = RegExp(r'\b' + RegExp.escape(item) + r'\b', caseSensitive: false);
      if (pattern.hasMatch(lowerText)) {
        violations.add(item);
      }
    }

    return violations;
  }

  /// Zkontroluje text na zakazana slova
  ///
  /// Vraci ModerationResult s informacemi o nalezenych slovech
  /// a doporucene akci.
  Future<ModerationResult> checkContent(String text) async {
    if (text.isEmpty) return ModerationResult.allowed();

    final lowerText = text.toLowerCase();

    // 1. Kontrola prodeje zakazanych polozek (kontextova)
    final prohibitedSales = _checkProhibitedSales(text);
    if (prohibitedSales.isNotEmpty) {
      return ModerationResult.blocked(
        reason: 'Prodej nebo nabidka zakazanych polozek neni povolena. '
            'Detekovane polozky: ${prohibitedSales.join(", ")}',
        contextViolations: prohibitedSales,
        action: 'delete',
      );
    }

    // 2. Kontrola primo zakazanych slov z databaze
    final bannedWords = await _getBannedWords();
    if (bannedWords.isEmpty) return ModerationResult.allowed();

    final foundWords = <BannedWord>[];

    for (final bw in bannedWords) {
      // Kontrola celeho slova pomoci regex
      final pattern = RegExp(r'\b' + RegExp.escape(bw.word) + r'\b', caseSensitive: false);
      if (pattern.hasMatch(lowerText)) {
        foundWords.add(bw);
      }
    }

    if (foundWords.isEmpty) return ModerationResult.allowed();

    // Urcit nejprisnejsi akci
    String action = 'warn';
    for (final word in foundWords) {
      if (word.action == 'block') {
        action = 'block';
        break;
      } else if (word.action == 'delete' && action != 'block') {
        action = 'delete';
      }
    }

    final wordList = foundWords.map((w) => w.word).join(', ');
    String reason;
    switch (action) {
      case 'block':
        reason = 'Obsah obsahuje zakazana slova: $wordList. Vas ucet muze byt zablokovany.';
        break;
      case 'delete':
        reason = 'Obsah obsahuje nevhodna slova: $wordList. Prispevek nebude publikovan.';
        break;
      default:
        reason = 'Obsah obsahuje potencialne nevhodna slova: $wordList.';
    }

    return ModerationResult.blocked(
      reason: reason,
      foundWords: foundWords,
      action: action,
    );
  }

  /// Zkontroluje obsah a vyhodi vyjimku pokud je zakazan
  ///
  /// Pouziti: await moderationService.validateContent(text);
  /// Vyhodi ContentBlockedException pokud je obsah nevhodny.
  Future<void> validateContent(String text) async {
    final result = await checkContent(text);

    if (!result.isAllowed && (result.recommendedAction == 'delete' || result.recommendedAction == 'block')) {
      // Spojit zakazana slova a kontextova poruseni
      final allBlockedWords = [
        ...result.foundWords.map((w) => w.word),
        ...result.contextViolations,
      ];
      throw ContentBlockedException(
        message: result.reason ?? 'Obsah obsahuje zakazana slova',
        blockedWords: allBlockedWords,
        action: result.recommendedAction,
      );
    }
  }

  /// Zkontroluje obsah a vrati true pokud je v poradku, false pokud ne
  Future<bool> isContentAllowed(String text) async {
    final result = await checkContent(text);
    return result.isAllowed || result.recommendedAction == 'warn';
  }

  /// Zaloguje pokus o publikovani zakazaneho obsahu
  Future<void> logBlockedContent({
    required String userId,
    required String contentType, // 'post' nebo 'comment'
    required String content,
    required List<String> foundWords,
  }) async {
    try {
      await _supabase.from('audit_log').insert({
        'admin_id': userId, // V tomto pripade je to uzivatel, ktery se pokusil publikovat
        'action': 'blocked_content_attempt',
        'details': 'Typ: $contentType, Nalezena slova: ${foundWords.join(", ")}, Obsah: ${content.substring(0, content.length > 100 ? 100 : content.length)}...',
      });
    } catch (_) {
      // Ignorovat chyby pri logovani
    }
  }
}
