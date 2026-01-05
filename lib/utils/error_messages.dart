import 'dart:io';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

class ErrorMessages {
  /// Prevede jakoukoli chybu na user-friendly zpravu
  static String getReadableError(dynamic error) {
    // Network errors
    if (error is SocketException) {
      return 'Nelze se pripojit k internetu. Zkontrolujte pripojeni.';
    }

    if (error is TimeoutException) {
      return 'Pripojeni vyprselo. Zkuste to znovu.';
    }

    if (error is HandshakeException) {
      return 'Chyba zabezpeceneho pripojeni. Zkuste to pozdeji.';
    }

    // Supabase Auth errors
    if (error is AuthException) {
      return _getAuthError(error);
    }

    // Supabase Database errors
    if (error is PostgrestException) {
      return _getPostgrestError(error);
    }

    // Supabase Storage errors
    if (error is StorageException) {
      return _getStorageError(error);
    }

    // Generic error message check
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('network') ||
        errorString.contains('connection') ||
        errorString.contains('unreachable')) {
      return 'Chyba pripojeni. Zkontrolujte internet.';
    }

    if (errorString.contains('permission') ||
        errorString.contains('denied')) {
      return 'Pristup zamitnut. Zkontrolujte opravneni.';
    }

    if (errorString.contains('not found') ||
        errorString.contains('404')) {
      return 'Pozadovana polozka nebyla nalezena.';
    }

    if (errorString.contains('unauthorized') ||
        errorString.contains('401')) {
      return 'Nejste prihlaseni. Prihlaste se prosim.';
    }

    if (errorString.contains('forbidden') ||
        errorString.contains('403')) {
      return 'K teto akci nemate opravneni.';
    }

    if (errorString.contains('server') ||
        errorString.contains('500') ||
        errorString.contains('502') ||
        errorString.contains('503')) {
      return 'Server je docasne nedostupny. Zkuste to pozdeji.';
    }

    // Default fallback
    return 'Neco se pokazilo. Zkuste to prosim znovu.';
  }

  /// Auth specificke chyby
  static String _getAuthError(AuthException error) {
    final message = error.message.toLowerCase();

    if (message.contains('invalid login credentials') ||
        message.contains('invalid email or password')) {
      return 'Spatny email nebo heslo.';
    }

    if (message.contains('email not confirmed')) {
      return 'Potvrd te prosim svuj email.';
    }

    if (message.contains('user already registered') ||
        message.contains('already exists')) {
      return 'Tento email je jiz zaregistrovan.';
    }

    if (message.contains('password')) {
      if (message.contains('weak') || message.contains('short')) {
        return 'Heslo je prilis slabe. Pouzijte alespon 8 znaku.';
      }
      return 'Chyba hesla. Zkontrolujte zadane udaje.';
    }

    if (message.contains('email')) {
      if (message.contains('invalid')) {
        return 'Neplatny format emailu.';
      }
      return 'Chyba emailu. Zkontrolujte zadany email.';
    }

    if (message.contains('rate limit') || message.contains('too many')) {
      return 'Prilis mnoho pokusu. Pockejte chvili.';
    }

    if (message.contains('expired') || message.contains('session')) {
      return 'Vase relace vyprsela. Prihlaste se znovu.';
    }

    if (message.contains('network')) {
      return 'Chyba site. Zkontrolujte pripojeni.';
    }

    return 'Chyba prihlaseni. Zkuste to znovu.';
  }

  /// Database specificke chyby
  static String _getPostgrestError(PostgrestException error) {
    final code = error.code;

    // Unique constraint violation
    if (code == '23505') {
      return 'Tato polozka jiz existuje.';
    }

    // Foreign key violation
    if (code == '23503') {
      return 'Nelze smazat - polozka je pouzivana jinde.';
    }

    // Not null violation
    if (code == '23502') {
      return 'Chybi povinne udaje.';
    }

    // Check constraint violation
    if (code == '23514') {
      return 'Neplatna hodnota.';
    }

    // RLS policy violation
    if (code == '42501' || error.message.contains('policy')) {
      return 'K teto akci nemate opravneni.';
    }

    // Connection errors
    if (code?.startsWith('08') == true) {
      return 'Chyba pripojeni k databazi.';
    }

    return 'Chyba pri ukladani dat. Zkuste to znovu.';
  }

  /// Storage specificke chyby
  static String _getStorageError(StorageException error) {
    final message = error.message.toLowerCase();

    if (message.contains('file too large') || message.contains('size')) {
      return 'Soubor je prilis velky.';
    }

    if (message.contains('not found')) {
      return 'Soubor nebyl nalezen.';
    }

    if (message.contains('permission') || message.contains('policy')) {
      return 'Nemate opravneni k tomuto souboru.';
    }

    if (message.contains('format') || message.contains('type')) {
      return 'Nepodporovany format souboru.';
    }

    return 'Chyba pri nahravani souboru.';
  }

  /// Kratke zpravy pro SnackBar
  static String getShortError(dynamic error) {
    final full = getReadableError(error);
    // Zkratit pokud je prilis dlouhe
    if (full.length > 50) {
      return '${full.substring(0, 47)}...';
    }
    return full;
  }

  /// Zpravy pro specificke akce
  static String getActionError(String action, dynamic error) {
    final base = getReadableError(error);

    switch (action) {
      case 'login':
        return 'Prihlaseni selhalo: $base';
      case 'register':
        return 'Registrace selhala: $base';
      case 'post':
        return 'Prispevek se nepodarilo odeslat: $base';
      case 'comment':
        return 'Komentar se nepodarilo odeslat: $base';
      case 'message':
        return 'Zprava se nepodarila odeslat: $base';
      case 'upload':
        return 'Nahrani selhalo: $base';
      case 'delete':
        return 'Smazani selhalo: $base';
      case 'load':
        return 'Nacteni selhalo: $base';
      default:
        return base;
    }
  }
}
