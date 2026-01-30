import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../models/post_model.dart';

/// Model pro rozšířené statistiky
class DetailedStats {
  final int totalUsers;
  final int activeUsers; // aktivní za posledních 7 dní
  final int newUsersToday;
  final int newUsersWeek;
  final int blockedUsers;
  final int adminUsers;

  final int totalPosts;
  final int postsToday;
  final int postsWeek;

  final int totalComments;
  final int commentsToday;

  final int totalReactions;

  final int pendingReports;
  final int resolvedReportsToday;

  final Map<String, int> postsByType; // discussion, question, announcement
  final List<Map<String, dynamic>> topPosters; // top 5 uživatelů
  final List<Map<String, dynamic>> recentActivity; // poslední aktivity

  DetailedStats({
    required this.totalUsers,
    required this.activeUsers,
    required this.newUsersToday,
    required this.newUsersWeek,
    required this.blockedUsers,
    required this.adminUsers,
    required this.totalPosts,
    required this.postsToday,
    required this.postsWeek,
    required this.totalComments,
    required this.commentsToday,
    required this.totalReactions,
    required this.pendingReports,
    required this.resolvedReportsToday,
    required this.postsByType,
    required this.topPosters,
    required this.recentActivity,
  });
}

/// Model pro audit log
class AuditLogEntry {
  final String id;
  final String adminId;
  final String adminUsername;
  final String action;
  final String? targetUserId;
  final String? targetUsername;
  final String? details;
  final DateTime createdAt;

  AuditLogEntry({
    required this.id,
    required this.adminId,
    required this.adminUsername,
    required this.action,
    this.targetUserId,
    this.targetUsername,
    this.details,
    required this.createdAt,
  });

  factory AuditLogEntry.fromJson(Map<String, dynamic> json) {
    final admin = json['admin'] as Map<String, dynamic>?;
    final target = json['target'] as Map<String, dynamic>?;
    return AuditLogEntry(
      id: json['id'] as String,
      adminId: json['admin_id'] as String,
      adminUsername: admin?['username'] as String? ?? 'Unknown',
      action: json['action'] as String,
      targetUserId: json['target_user_id'] as String?,
      targetUsername: target?['username'] as String?,
      details: json['details'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

/// Model pro zakázaná slova
class BannedWord {
  final String id;
  final String word;
  final String action; // warn, delete, block
  final DateTime createdAt;

  BannedWord({
    required this.id,
    required this.word,
    required this.action,
    required this.createdAt,
  });

  factory BannedWord.fromJson(Map<String, dynamic> json) {
    return BannedWord(
      id: json['id'] as String,
      word: json['word'] as String,
      action: json['action'] as String? ?? 'warn',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

/// Služba pro administraci aplikace
///
/// Poskytuje funkce pro správu uživatelů a příspěvků,
/// přístupné pouze administrátorům.
class AdminService {
  /// Supabase klient
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Získá seznam všech uživatelů
  Future<List<UserModel>> getAllUsers() async {
    final response = await _supabase
        .from('profiles')
        .select()
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => UserModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Vyhledá uživatele podle username (pro @mentions)
  Future<List<UserModel>> searchUsers(String query, {int limit = 10}) async {
    final response = await _supabase
        .from('profiles')
        .select()
        .ilike('username', '%$query%')
        .eq('is_blocked', false)
        .limit(limit)
        .order('username');

    return (response as List)
        .map((json) => UserModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Zablokuje uživatele
  Future<void> blockUser(String userId) async {
    await _supabase
        .from('profiles')
        .update({'is_blocked': true})
        .eq('id', userId);
  }

  /// Odblokuje uživatele
  Future<void> unblockUser(String userId) async {
    await _supabase
        .from('profiles')
        .update({'is_blocked': false})
        .eq('id', userId);
  }

  /// Nastaví roli uživatele
  Future<void> setUserRole(String userId, String role) async {
    final response = await _supabase
        .from('profiles')
        .update({'role': role})
        .eq('id', userId)
        .select()
        .single();

    // Ověření, že se role skutečně změnila
    if (response['role'] != role) {
      throw Exception('Nepodařilo se změnit roli uživatele. Zkontrolujte oprávnění.');
    }

    await logAction(
      action: role == 'admin' ? 'make_admin' : 'remove_admin',
      targetUserId: userId,
      details: 'Nova role: $role',
    );
  }

  /// Povýší uživatele na admina
  Future<void> makeAdmin(String userId) async {
    await setUserRole(userId, 'admin');
  }

  /// Degraduje uživatele na člena
  Future<void> makeMember(String userId) async {
    await setUserRole(userId, 'member');
  }

  /// Získá seznam všech příspěvků (pro administraci)
  Future<List<PostModel>> getAllPosts({int limit = 50, int offset = 0}) async {
    final response = await _supabase
        .from('posts')
        .select('''
          *,
          profiles!posts_author_id_fkey(*),
          comments(*, profiles!comments_author_id_fkey(*)),
          reactions(*)
        ''')
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return (response as List)
        .map((json) => PostModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Smaže příspěvek včetně souvisejících dat
  Future<void> deletePost(String postId) async {
    // Nejprve smaž komentáře a reakce
    await _supabase.from('comments').delete().eq('post_id', postId);
    await _supabase.from('reactions').delete().eq('post_id', postId);
    // Pak smaž samotný příspěvek
    await _supabase.from('posts').delete().eq('id', postId);
  }

  /// Získá statistiky aplikace
  ///
  /// Vrací počty uživatelů, příspěvků, komentářů a reakcí.
  Future<Map<String, int>> getStats() async {
    final usersResponse = await _supabase.from('profiles').select('id');
    final postsResponse = await _supabase.from('posts').select('id');
    final commentsResponse = await _supabase.from('comments').select('id');
    final reactionsResponse = await _supabase.from('reactions').select('id');

    return {
      'users': (usersResponse as List).length,
      'posts': (postsResponse as List).length,
      'comments': (commentsResponse as List).length,
      'reactions': (reactionsResponse as List).length,
    };
  }

  /// Získá rozšířené statistiky
  Future<DetailedStats> getDetailedStats() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekAgo = today.subtract(const Duration(days: 7));

    // Uživatelé
    final allUsers = await _supabase.from('profiles').select('id, role, is_blocked, created_at, last_seen');
    final usersList = allUsers as List;
    final totalUsers = usersList.length;
    final blockedUsers = usersList.where((u) => u['is_blocked'] == true).length;
    final adminUsers = usersList.where((u) => u['role'] == 'admin').length;
    final newUsersToday = usersList.where((u) {
      final createdAt = DateTime.tryParse(u['created_at'] ?? '');
      return createdAt != null && createdAt.isAfter(today);
    }).length;
    final newUsersWeek = usersList.where((u) {
      final createdAt = DateTime.tryParse(u['created_at'] ?? '');
      return createdAt != null && createdAt.isAfter(weekAgo);
    }).length;
    final activeUsers = usersList.where((u) {
      final lastSeen = DateTime.tryParse(u['last_seen'] ?? '');
      return lastSeen != null && lastSeen.isAfter(weekAgo);
    }).length;

    // Příspěvky
    final allPosts = await _supabase.from('posts').select('id, thread_type_id, created_at, thread_types(name)');
    final postsList = allPosts as List;
    final totalPosts = postsList.length;
    final postsToday = postsList.where((p) {
      final createdAt = DateTime.tryParse(p['created_at'] ?? '');
      return createdAt != null && createdAt.isAfter(today);
    }).length;
    final postsWeek = postsList.where((p) {
      final createdAt = DateTime.tryParse(p['created_at'] ?? '');
      return createdAt != null && createdAt.isAfter(weekAgo);
    }).length;

    // Příspěvky podle typu
    final postsByType = <String, int>{};
    for (final post in postsList) {
      final threadType = post['thread_types'] as Map<String, dynamic>?;
      final type = threadType?['name'] as String? ?? 'discussion';
      postsByType[type] = (postsByType[type] ?? 0) + 1;
    }

    // Komentáře
    final allComments = await _supabase.from('comments').select('id, created_at');
    final commentsList = allComments as List;
    final totalComments = commentsList.length;
    final commentsToday = commentsList.where((c) {
      final createdAt = DateTime.tryParse(c['created_at'] ?? '');
      return createdAt != null && createdAt.isAfter(today);
    }).length;

    // Reakce
    final allReactions = await _supabase.from('reactions').select('id');
    final totalReactions = (allReactions as List).length;

    // Reporty
    int pendingReports = 0;
    int resolvedReportsToday = 0;
    try {
      final pendingResp = await _supabase.from('reports').select('id').eq('status', 'pending');
      pendingReports = (pendingResp as List).length;
      final resolvedResp = await _supabase.from('reports').select('id, resolved_at').eq('status', 'resolved');
      resolvedReportsToday = (resolvedResp as List).where((r) {
        final resolvedAt = DateTime.tryParse(r['resolved_at'] ?? '');
        return resolvedAt != null && resolvedAt.isAfter(today);
      }).length;
    } catch (_) {
      // Tabulka reports nemusí existovat
    }

    // Top posteři
    final topPostersResp = await _supabase.from('posts')
        .select('author_id, profiles!posts_author_id_fkey(username, avatar_url)')
        .order('created_at', ascending: false)
        .limit(100);
    final postsForTop = topPostersResp as List;
    final posterCounts = <String, Map<String, dynamic>>{};
    for (final post in postsForTop) {
      final authorId = post['author_id'] as String;
      final profile = post['profiles'] as Map<String, dynamic>?;
      if (posterCounts.containsKey(authorId)) {
        posterCounts[authorId]!['count'] = (posterCounts[authorId]!['count'] as int) + 1;
      } else {
        posterCounts[authorId] = {
          'userId': authorId,
          'username': profile?['username'] ?? 'Unknown',
          'avatarUrl': profile?['avatar_url'],
          'count': 1,
        };
      }
    }
    final topPosters = posterCounts.values.toList()
      ..sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));
    final top5Posters = topPosters.take(5).toList();

    // Poslední aktivity (kombinace příspěvků a komentářů)
    final recentPosts = await _supabase.from('posts')
        .select('id, content, created_at, profiles!posts_author_id_fkey(username)')
        .order('created_at', ascending: false)
        .limit(5);
    final recentComments = await _supabase.from('comments')
        .select('id, content, created_at, profiles!comments_author_id_fkey(username)')
        .order('created_at', ascending: false)
        .limit(5);

    final recentActivity = <Map<String, dynamic>>[];
    for (final post in recentPosts as List) {
      recentActivity.add({
        'type': 'post',
        'content': post['content'],
        'username': (post['profiles'] as Map?)?['username'] ?? 'Unknown',
        'createdAt': post['created_at'],
      });
    }
    for (final comment in recentComments as List) {
      recentActivity.add({
        'type': 'comment',
        'content': comment['content'],
        'username': (comment['profiles'] as Map?)?['username'] ?? 'Unknown',
        'createdAt': comment['created_at'],
      });
    }
    recentActivity.sort((a, b) => (b['createdAt'] as String).compareTo(a['createdAt'] as String));

    return DetailedStats(
      totalUsers: totalUsers,
      activeUsers: activeUsers,
      newUsersToday: newUsersToday,
      newUsersWeek: newUsersWeek,
      blockedUsers: blockedUsers,
      adminUsers: adminUsers,
      totalPosts: totalPosts,
      postsToday: postsToday,
      postsWeek: postsWeek,
      totalComments: totalComments,
      commentsToday: commentsToday,
      totalReactions: totalReactions,
      pendingReports: pendingReports,
      resolvedReportsToday: resolvedReportsToday,
      postsByType: postsByType,
      topPosters: top5Posters,
      recentActivity: recentActivity.take(10).toList(),
    );
  }

  // ==================== AUDIT LOG ====================

  /// Zaznamená akci do audit logu
  Future<void> logAction({
    required String action,
    String? targetUserId,
    String? details,
  }) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) return;

    try {
      await _supabase.from('audit_log').insert({
        'admin_id': currentUserId,
        'action': action,
        'target_user_id': targetUserId,
        'details': details,
      });
    } catch (_) {
      // Audit log tabulka nemusí existovat
    }
  }

  /// Získá audit log
  Future<List<AuditLogEntry>> getAuditLog({int limit = 50, int offset = 0}) async {
    try {
      final response = await _supabase
          .from('audit_log')
          .select('''
            *,
            admin:profiles!audit_log_admin_id_fkey(username),
            target:profiles!audit_log_target_user_id_fkey(username)
          ''')
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List)
          .map((json) => AuditLogEntry.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ==================== ZAKÁZANÁ SLOVA ====================

  /// Získá seznam zakázaných slov
  Future<List<BannedWord>> getBannedWords() async {
    try {
      final response = await _supabase
          .from('banned_words')
          .select()
          .order('word');

      return (response as List)
          .map((json) => BannedWord.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Přidá zakázané slovo
  Future<void> addBannedWord(String word, String action) async {
    await _supabase.from('banned_words').insert({
      'word': word.toLowerCase(),
      'action': action,
    });
    await logAction(action: 'add_banned_word', details: 'Slovo: $word, Akce: $action');
  }

  /// Odstraní zakázané slovo
  Future<void> removeBannedWord(String id) async {
    await _supabase.from('banned_words').delete().eq('id', id);
    await logAction(action: 'remove_banned_word', details: 'ID: $id');
  }

  /// Zkontroluje text na zakázaná slova
  Future<List<BannedWord>> checkForBannedWords(String text) async {
    final bannedWords = await getBannedWords();
    final lowerText = text.toLowerCase();
    return bannedWords.where((bw) => lowerText.contains(bw.word)).toList();
  }

  // ==================== DOČASNÉ BANY ====================

  /// Dočasně zablokuje uživatele
  Future<void> temporaryBan(String userId, Duration duration, String reason) async {
    final banUntil = DateTime.now().add(duration);
    await _supabase.from('profiles').update({
      'is_blocked': true,
      'ban_until': banUntil.toIso8601String(),
      'ban_reason': reason,
    }).eq('id', userId);
    await logAction(
      action: 'temporary_ban',
      targetUserId: userId,
      details: 'Doba: ${duration.inHours}h, Důvod: $reason',
    );
  }

  /// Zkontroluje a odblokuje uživatele s vypršeným banem
  Future<void> checkExpiredBans() async {
    final now = DateTime.now().toIso8601String();
    await _supabase
        .from('profiles')
        .update({'is_blocked': false, 'ban_until': null, 'ban_reason': null})
        .eq('is_blocked', true)
        .lt('ban_until', now);
  }

  // ==================== BROADCAST ====================

  /// Odešle broadcast zprávu všem uživatelům
  Future<void> sendBroadcast(String title, String message) async {
    final users = await _supabase.from('profiles').select('id');
    final currentUserId = _supabase.auth.currentUser?.id;

    for (final user in users as List) {
      final userId = user['id'] as String;
      if (userId != currentUserId) {
        await _supabase.from('notifications').insert({
          'user_id': userId,
          'type': 'broadcast',
          'title': title,
          'body': message,
          'data': {'from': 'admin'},
        });
      }
    }
    await logAction(action: 'send_broadcast', details: 'Titul: $title');
  }

  // ==================== PŘIPNUTÉ PŘÍSPĚVKY ====================

  /// Připne příspěvek
  Future<void> pinPost(String postId) async {
    await _supabase.from('posts').update({'is_pinned': true}).eq('id', postId);
    await logAction(action: 'pin_post', details: 'Post ID: $postId');
  }

  /// Odepne příspěvek
  Future<void> unpinPost(String postId) async {
    await _supabase.from('posts').update({'is_pinned': false}).eq('id', postId);
    await logAction(action: 'unpin_post', details: 'Post ID: $postId');
  }

  /// Získá připnuté příspěvky
  Future<List<PostModel>> getPinnedPosts() async {
    final response = await _supabase
        .from('posts')
        .select('''
          *,
          profiles!posts_author_id_fkey(*),
          comments(*, profiles!comments_author_id_fkey(*)),
          reactions(*)
        ''')
        .eq('is_pinned', true)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => PostModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // ==================== GDPR EXPORT ====================

  /// Exportuje data uživatele (GDPR)
  Future<Map<String, dynamic>> exportUserData(String userId) async {
    final profile = await _supabase.from('profiles').select().eq('id', userId).single();
    final posts = await _supabase.from('posts').select().eq('author_id', userId);
    final comments = await _supabase.from('comments').select().eq('author_id', userId);
    final reactions = await _supabase.from('reactions').select().eq('user_id', userId);

    await logAction(action: 'gdpr_export', targetUserId: userId);

    return {
      'profile': profile,
      'posts': posts,
      'comments': comments,
      'reactions': reactions,
      'exported_at': DateTime.now().toIso8601String(),
    };
  }

  /// Smaže všechna data uživatele (GDPR)
  Future<void> deleteUserData(String userId) async {
    // Smaž reakce
    await _supabase.from('reactions').delete().eq('user_id', userId);
    // Smaž komentáře
    await _supabase.from('comments').delete().eq('author_id', userId);
    // Smaž příspěvky (včetně jejich komentářů a reakcí)
    final userPosts = await _supabase.from('posts').select('id').eq('author_id', userId);
    for (final post in userPosts as List) {
      await deletePost(post['id'] as String);
    }
    // Anonymizuj profil
    await _supabase.from('profiles').update({
      'username': 'Smazaný uživatel',
      'bio': null,
      'avatar_url': null,
      'is_blocked': true,
    }).eq('id', userId);

    await logAction(action: 'gdpr_delete', targetUserId: userId);
  }

  // ==================== VAROVÁNÍ UŽIVATELE ====================

  /// Odešle varování uživateli
  Future<void> sendWarning(String userId, String message) async {
    await _supabase.from('notifications').insert({
      'user_id': userId,
      'type': 'warning',
      'title': 'Varovani od administratora',
      'body': message,
      'data': {'from': 'admin'},
    });
    await logAction(action: 'send_warning', targetUserId: userId, details: message);
  }
}
