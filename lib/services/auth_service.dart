import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import 'web_push_service.dart';
import 'mobile_push_service.dart';

/// Služba pro autentizaci uživatelů
///
/// Zajišťuje registraci, přihlášení, odhlášení a správu profilu.
/// Používá Supabase Auth pro autentizaci.
class AuthService {
  /// Supabase klient
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Aktuálně přihlášený uživatel (Supabase User)
  User? get currentUser => _supabase.auth.currentUser;

  /// Je uživatel přihlášen?
  bool get isAuthenticated => currentUser != null;

  /// Stream změn stavu autentizace
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  /// Registrace nového uživatele
  ///
  /// Vytvoří účet a profil v databázi.
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    // Vytvoření účtu
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
    );

    // Profil se vytvoří automaticky přes trigger v databázi
    // Pokud trigger selže, vytvoříme ho ručně
    if (response.user != null) {
      try {
        // Zkontroluj jestli profil existuje
        final existing = await _supabase
            .from('profiles')
            .select()
            .eq('id', response.user!.id)
            .maybeSingle();

        if (existing == null) {
          await _supabase.from('profiles').insert({
            'id': response.user!.id,
            'username': username,
            'role': 'member',
            'is_blocked': false,
          });
        }
      } catch (_) {
        // Trigger už profil vytvořil
      }
    }

    return response;
  }

  /// Přihlášení uživatele
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );

    // Registruj push token po přihlášení
    if (response.user != null) {
      if (kIsWeb) {
        WebPushService.instance.onUserLoggedIn();
      } else if (Platform.isIOS || Platform.isAndroid) {
        MobilePushService.instance.onUserLoggedIn(response.user!.id);
      }
    }

    return response;
  }

  /// Odhlášení uživatele
  Future<void> signOut() async {
    // Odregistruj push token před odhlášením
    final userId = currentUser?.id;
    if (kIsWeb) {
      await WebPushService.instance.onUserLoggedOut();
    } else if (!kIsWeb && (Platform.isIOS || Platform.isAndroid) && userId != null) {
      await MobilePushService.instance.onUserLoggedOut(userId);
    }

    await _supabase.auth.signOut();
  }

  /// Získá profil aktuálního uživatele
  Future<UserModel?> getCurrentProfile() async {
    final user = currentUser;
    if (user == null) return null;

    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (response == null) return null;
      return UserModel.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  /// Aktualizuje profil uživatele
  Future<void> updateProfile({
    String? username,
    String? avatarUrl,
  }) async {
    final user = currentUser;
    if (user == null) return;

    final updates = <String, dynamic>{};
    if (username != null) updates['username'] = username;
    if (avatarUrl != null) updates['avatar_url'] = avatarUrl;

    if (updates.isNotEmpty) {
      await _supabase.from('profiles').update(updates).eq('id', user.id);
    }
  }

  /// Odešle email pro reset hesla
  Future<void> resetPassword(String email) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }

  /// Změní heslo přihlášeného uživatele
  Future<void> updatePassword(String newPassword) async {
    await _supabase.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }

  /// Ověří aktuální heslo (re-autentizace)
  Future<bool> verifyCurrentPassword(String password) async {
    final user = currentUser;
    if (user?.email == null) return false;

    try {
      await _supabase.auth.signInWithPassword(
        email: user!.email!,
        password: password,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Získá aktivní sessions uživatele
  Future<Session?> getCurrentSession() async {
    return _supabase.auth.currentSession;
  }

  /// Aktualizuje nastavení soukromí (is_private)
  Future<void> updatePrivacySettings({required bool isPrivate}) async {
    final user = currentUser;
    if (user == null) return;

    await _supabase.from('profiles').update({
      'is_private': isPrivate,
    }).eq('id', user.id);
  }
}
