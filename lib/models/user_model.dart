class UserModel {
  final String id;
  final String username;
  final String? email;
  final String? avatarUrl;
  final String role;
  final bool isBlocked;
  final DateTime createdAt;
  // Extended profile fields
  final String? bio;
  final String? website;
  final String? location;
  final int followerCount;
  final int followingCount;
  final int postCount;

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
  });

  bool get isAdmin => role == 'admin';
  bool get isMember => role == 'member';

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
    );
  }

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
    };
  }

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
    );
  }
}
