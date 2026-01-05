/// Model uživatele
///
/// Reprezentuje uživatele v aplikaci včetně profilových informací
/// a statistik sledování.
class UserModel {
  /// Unikátní ID uživatele (UUID)
  final String id;

  /// Uživatelské jméno
  final String username;

  /// E-mailová adresa
  final String? email;

  /// URL profilového obrázku
  final String? avatarUrl;

  /// Role uživatele: 'admin' nebo 'member'
  final String role;

  /// Je uživatel zablokován?
  final bool isBlocked;

  /// Datum registrace
  final DateTime createdAt;

  // === Rozšířené profilové údaje ===

  /// Krátký popis / bio
  final String? bio;

  /// Webová stránka
  final String? website;

  /// Lokalita / město
  final String? location;

  /// Počet sledujících
  final int followerCount;

  /// Počet sledovaných
  final int followingCount;

  /// Počet příspěvků
  final int postCount;

  /// Je účet soukromý?
  final bool isPrivate;

  UserModel({
    required this.id,
    required this.username,
    this.email,
    this.avatarUrl,
    required this.role,
    required this.isBlocked,
    required this.createdAt,
    this.bio,
    this.website,
    this.location,
    this.followerCount = 0,
    this.followingCount = 0,
    this.postCount = 0,
    this.isPrivate = false,
  });

  /// Je uživatel admin?
  bool get isAdmin => role == 'admin';

  /// Je uživatel běžný člen?
  bool get isMember => role == 'member';

  /// Vytvoří model z JSON dat (z Supabase)
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      username: json['username'] as String? ?? 'Uživatel',
      email: json['email'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      role: json['role'] as String? ?? 'member',
      isBlocked: json['is_blocked'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      bio: json['bio'] as String?,
      website: json['website'] as String?,
      location: json['location'] as String?,
      followerCount: json['follower_count'] as int? ?? 0,
      followingCount: json['following_count'] as int? ?? 0,
      postCount: json['post_count'] as int? ?? 0,
      isPrivate: json['is_private'] as bool? ?? false,
    );
  }

  /// Převede model na JSON pro uložení
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'avatar_url': avatarUrl,
      'role': role,
      'is_blocked': isBlocked,
      'created_at': createdAt.toIso8601String(),
      'bio': bio,
      'website': website,
      'location': location,
      'follower_count': followerCount,
      'following_count': followingCount,
      'post_count': postCount,
      'is_private': isPrivate,
    };
  }

  /// Vytvoří kopii s upravenými hodnotami
  UserModel copyWith({
    String? id,
    String? username,
    String? email,
    String? avatarUrl,
    String? role,
    bool? isBlocked,
    DateTime? createdAt,
    String? bio,
    String? website,
    String? location,
    int? followerCount,
    int? followingCount,
    int? postCount,
    bool? isPrivate,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      isBlocked: isBlocked ?? this.isBlocked,
      createdAt: createdAt ?? this.createdAt,
      bio: bio ?? this.bio,
      website: website ?? this.website,
      location: location ?? this.location,
      followerCount: followerCount ?? this.followerCount,
      followingCount: followingCount ?? this.followingCount,
      postCount: postCount ?? this.postCount,
      isPrivate: isPrivate ?? this.isPrivate,
    );
  }
}
