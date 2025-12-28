class AppUser {
  final String id;
  final String email;
  final String? username;
  final String? avatarUrl;
  final String? friendCode;
  final DateTime createdAt;

  AppUser({
    required this.id,
    required this.email,
    this.username,
    this.avatarUrl,
    this.friendCode,
    required this.createdAt,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      email: json['email'] as String,
      username: json['username'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      friendCode: json['friend_code'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'avatar_url': avatarUrl,
      'friend_code': friendCode,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
