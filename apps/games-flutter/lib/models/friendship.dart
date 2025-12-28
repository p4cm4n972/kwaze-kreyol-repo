class Friendship {
  final String id;
  final String userIdA;
  final String userIdB;
  final DateTime createdAt;

  Friendship({
    required this.id,
    required this.userIdA,
    required this.userIdB,
    required this.createdAt,
  });

  factory Friendship.fromJson(Map<String, dynamic> json) {
    return Friendship(
      id: json['id'] as String,
      userIdA: json['user_id_a'] as String,
      userIdB: json['user_id_b'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id_a': userIdA,
      'user_id_b': userIdB,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Get the friend's ID given the current user's ID
  String getFriendId(String currentUserId) {
    return currentUserId == userIdA ? userIdB : userIdA;
  }
}
