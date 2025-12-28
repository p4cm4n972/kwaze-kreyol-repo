class Friend {
  final String id;
  final String username;
  final String? avatarUrl;
  final String? friendCode;
  final DateTime friendshipCreatedAt;
  final bool isOnline;

  Friend({
    required this.id,
    required this.username,
    this.avatarUrl,
    this.friendCode,
    required this.friendshipCreatedAt,
    this.isOnline = false,
  });

  factory Friend.fromJson(Map<String, dynamic> json) {
    return Friend(
      id: json['friend_id'] as String,
      username: json['username'] as String? ?? 'Utilisateur',
      avatarUrl: json['avatar_url'] as String?,
      friendCode: json['friend_code'] as String?,
      friendshipCreatedAt: DateTime.parse(
        json['friendship_created_at'] as String,
      ),
      isOnline: json['is_online'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'friend_id': id,
      'username': username,
      'avatar_url': avatarUrl,
      'friend_code': friendCode,
      'friendship_created_at': friendshipCreatedAt.toIso8601String(),
      'is_online': isOnline,
    };
  }
}
