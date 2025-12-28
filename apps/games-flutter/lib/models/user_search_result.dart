class UserSearchResult {
  final String userId;
  final String username;
  final String? avatarUrl;
  final String? friendCode;
  final bool isFriend;
  final bool hasPendingRequest;

  UserSearchResult({
    required this.userId,
    required this.username,
    this.avatarUrl,
    this.friendCode,
    required this.isFriend,
    required this.hasPendingRequest,
  });

  factory UserSearchResult.fromJson(Map<String, dynamic> json) {
    return UserSearchResult(
      userId: json['user_id'] as String,
      username: json['username'] as String? ?? 'Utilisateur',
      avatarUrl: json['avatar_url'] as String?,
      friendCode: json['friend_code'] as String?,
      isFriend: json['is_friend'] as bool? ?? false,
      hasPendingRequest: json['has_pending_request'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'username': username,
      'avatar_url': avatarUrl,
      'friend_code': friendCode,
      'is_friend': isFriend,
      'has_pending_request': hasPendingRequest,
    };
  }

  bool get canSendRequest => !isFriend && !hasPendingRequest;
}
