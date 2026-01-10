class AppUser {
  final String id;
  final String email;
  final String? username;
  final String? avatarUrl;
  final String? friendCode;
  final String? postalCode;
  final String? phone;
  final String role;
  final DateTime createdAt;

  AppUser({
    required this.id,
    required this.email,
    this.username,
    this.avatarUrl,
    this.friendCode,
    this.postalCode,
    this.phone,
    this.role = 'user',
    required this.createdAt,
  });

  /// Vérifie si l'utilisateur est administrateur
  bool get isAdmin => role == 'admin';

  /// Vérifie si l'utilisateur est contributeur ou admin
  bool get isContributor => role == 'contributor' || role == 'admin';

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      email: json['email'] as String,
      username: json['username'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      friendCode: json['friend_code'] as String?,
      postalCode: json['postal_code'] as String?,
      phone: json['phone'] as String?,
      role: json['role'] as String? ?? 'user',
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
      'postal_code': postalCode,
      'phone': phone,
      'role': role,
      'created_at': createdAt.toIso8601String(),
    };
  }

  AppUser copyWith({
    String? id,
    String? email,
    String? username,
    String? avatarUrl,
    String? friendCode,
    String? postalCode,
    String? phone,
    String? role,
    DateTime? createdAt,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      friendCode: friendCode ?? this.friendCode,
      postalCode: postalCode ?? this.postalCode,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
