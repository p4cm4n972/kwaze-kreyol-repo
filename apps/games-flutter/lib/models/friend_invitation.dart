class FriendInvitation {
  final String id;
  final String inviterId;
  final String inviteeEmail;
  final String status;
  final String invitationToken;
  final DateTime createdAt;
  final DateTime expiresAt;
  final DateTime? acceptedAt;
  final String? acceptedByUserId;

  FriendInvitation({
    required this.id,
    required this.inviterId,
    required this.inviteeEmail,
    required this.status,
    required this.invitationToken,
    required this.createdAt,
    required this.expiresAt,
    this.acceptedAt,
    this.acceptedByUserId,
  });

  factory FriendInvitation.fromJson(Map<String, dynamic> json) {
    return FriendInvitation(
      id: json['id'] as String,
      inviterId: json['inviter_id'] as String,
      inviteeEmail: json['invitee_email'] as String,
      status: json['status'] as String? ?? 'sent',
      invitationToken: json['invitation_token'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      expiresAt: DateTime.parse(json['expires_at'] as String),
      acceptedAt: json['accepted_at'] != null
          ? DateTime.parse(json['accepted_at'] as String)
          : null,
      acceptedByUserId: json['accepted_by_user_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'inviter_id': inviterId,
      'invitee_email': inviteeEmail,
      'status': status,
      'invitation_token': invitationToken,
      'created_at': createdAt.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
      if (acceptedAt != null) 'accepted_at': acceptedAt!.toIso8601String(),
      if (acceptedByUserId != null) 'accepted_by_user_id': acceptedByUserId,
    };
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isPending => status == 'sent' && !isExpired;
}
