import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

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

    // Vytvoření profilu
    if (response.user != null) {
      await _supabase.from('profiles').insert({
        'id': response.user!.id,
        'username': username,
        'email': email,
        'role': 'member',
        'is_blocked': false,
        'created_at': DateTime.now().toIso8601String(),
      });
    }

    return response;
  }

  /// Přihlášení uživatele
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Odhlášení uživatele
  Future<void> signOut() async {
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
}
