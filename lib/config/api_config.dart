/// Konfigurace API klicu pro externi sluzby
///
/// DULEZITE: Pro produkci presunout tyto hodnoty do:
/// - Environment variables
/// - Secure storage
/// - Backend proxy
///
/// Nikdy nevkladejte citlive API klice primo do zdrojoveho kodu!
class ApiConfig {
  /// Tenor API klic pro GIF vyhledavani
  /// Ziskat na: https://developers.google.com/tenor/guides/quickstart
  ///
  /// Pro produkci pouzijte:
  /// - String.fromEnvironment('TENOR_API_KEY')
  /// - nebo flutter_dotenv package
  static const String tenorApiKey = String.fromEnvironment(
    'TENOR_API_KEY',
    defaultValue: 'AIzaSyBJIvOxLJOz-yBlO7NfQRo8r_SWJVJ22Wg', // Dev fallback
  );

  /// Tenor client key pro identifikaci aplikace
  static const String tenorClientKey = String.fromEnvironment(
    'TENOR_CLIENT_KEY',
    defaultValue: 'charlotte_web_app',
  );

  /// Kontrola, zda jsou API klice nastaveny z environment
  static bool get isProduction =>
      tenorApiKey != 'AIzaSyBJIvOxLJOz-yBlO7NfQRo8r_SWJVJ22Wg';
}
