import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/friend.dart';
import '../models/friend_request.dart';
import '../models/user_search_result.dart';
import '../models/friend_invitation.dart';
import 'supabase_service.dart';
import 'auth_service.dart';

class FriendsService {
  final SupabaseClient _supabase = SupabaseService.client;
  final AuthService _authService = AuthService();

  // ============================================
  // FRIEND REQUESTS
  // ============================================

  /// Send a friend request to a user
  Future<String> sendFriendRequest(String receiverId) async {
    try {
      final userId = _authService.getUserIdOrNull();
      if (userId == null) {
        throw Exception('Vous devez être connecté pour envoyer une demande');
      }

      final response = await _supabase.rpc(
        'send_friend_request',
        params: {'p_sender_id': userId, 'p_receiver_id': receiverId},
      );

      return response as String;
    } catch (e) {
      throw Exception('Erreur lors de l\'envoi de la demande: $e');
    }
  }

  /// Accept a friend request
  Future<String> acceptFriendRequest(String requestId) async {
    try {
      final userId = _authService.getUserIdOrNull();
      if (userId == null) {
        throw Exception('Vous devez être connecté');
      }

      final response = await _supabase.rpc(
        'accept_friend_request',
        params: {'p_request_id': requestId, 'p_user_id': userId},
      );

      return response as String; // Returns friendship_id
    } catch (e) {
      throw Exception('Erreur lors de l\'acceptation: $e');
    }
  }

  /// Decline a friend request
  Future<void> declineFriendRequest(String requestId) async {
    try {
      final userId = _authService.getUserIdOrNull();
      if (userId == null) {
        throw Exception('Vous devez être connecté');
      }

      await _supabase.rpc(
        'decline_friend_request',
        params: {'p_request_id': requestId, 'p_user_id': userId},
      );
    } catch (e) {
      throw Exception('Erreur lors du refus: $e');
    }
  }

  /// Cancel a sent friend request
  Future<void> cancelFriendRequest(String requestId) async {
    try {
      await _supabase
          .from('friend_requests')
          .update({'status': 'cancelled'})
          .eq('id', requestId);
    } catch (e) {
      throw Exception('Erreur lors de l\'annulation: $e');
    }
  }

  /// Get pending friend requests (received)
  Future<List<FriendRequest>> getPendingRequests() async {
    try {
      final userId = _authService.getUserIdOrNull();
      if (userId == null) return [];

      final response = await _supabase
          .from('friend_requests')
          .select('''
            *,
            sender:users!sender_id (username, avatar_url)
          ''')
          .eq('receiver_id', userId)
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => FriendRequest.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des demandes: $e');
    }
  }

  /// Get sent friend requests
  Future<List<FriendRequest>> getSentRequests() async {
    try {
      final userId = _authService.getUserIdOrNull();
      if (userId == null) return [];

      final response = await _supabase
          .from('friend_requests')
          .select('''
            *,
            receiver:users!receiver_id (username, avatar_url)
          ''')
          .eq('sender_id', userId)
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => FriendRequest.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception(
        'Erreur lors de la récupération des demandes envoyées: $e',
      );
    }
  }

  // ============================================
  // FRIENDS MANAGEMENT
  // ============================================

  /// Get list of friends
  Future<List<Friend>> getFriends() async {
    try {
      final userId = _authService.getUserIdOrNull();
      if (userId == null) return [];

      final response = await _supabase.rpc(
        'get_friends_list',
        params: {'p_user_id': userId},
      );

      return (response as List).map((json) => Friend.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des amis: $e');
    }
  }

  /// Remove a friend
  Future<void> removeFriend(String friendId) async {
    try {
      final userId = _authService.getUserIdOrNull();
      if (userId == null) {
        throw Exception('Vous devez être connecté');
      }

      await _supabase.rpc(
        'remove_friendship',
        params: {'p_user_id': userId, 'p_friend_id': friendId},
      );
    } catch (e) {
      throw Exception('Erreur lors de la suppression de l\'ami: $e');
    }
  }

  // ============================================
  // USER SEARCH
  // ============================================

  /// Search users by username
  Future<List<UserSearchResult>> searchUsers(String query) async {
    try {
      final userId = _authService.getUserIdOrNull();
      if (userId == null) return [];

      if (query.isEmpty) return [];

      final response = await _supabase.rpc(
        'search_users_for_friends',
        params: {'p_user_id': userId, 'p_query': query, 'p_limit': 20},
      );

      return (response as List)
          .map((json) => UserSearchResult.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la recherche: $e');
    }
  }

  /// Search user by friend code
  Future<UserSearchResult?> searchByFriendCode(String code) async {
    try {
      final userId = _authService.getUserIdOrNull();
      if (userId == null) return null;

      if (code.isEmpty || code.length != 6) return null;

      final response = await _supabase.rpc(
        'search_user_by_friend_code',
        params: {'p_user_id': userId, 'p_friend_code': code.toUpperCase()},
      );

      if (response == null || (response as List).isEmpty) return null;

      return UserSearchResult.fromJson((response as List).first);
    } catch (e) {
      throw Exception('Erreur lors de la recherche par code: $e');
    }
  }

  // ============================================
  // EMAIL INVITATIONS
  // ============================================

  /// Invite a friend by email
  Future<String> inviteFriendByEmail(String email) async {
    try {
      final userId = _authService.getUserIdOrNull();
      if (userId == null) {
        throw Exception('Vous devez être connecté');
      }

      // Generate token
      final tokenResponse = await _supabase.rpc('generate_invitation_token');
      final token = tokenResponse as String;

      // Create invitation
      final response = await _supabase
          .from('friend_invitations')
          .insert({
            'inviter_id': userId,
            'invitee_email': email.toLowerCase(),
            'invitation_token': token,
          })
          .select()
          .single();

      // TODO: Call Edge Function to send email
      // await _supabase.functions.invoke('send-friend-invitation', body: {
      //   'invitation_id': response['id'],
      //   'email': email,
      //   'token': token,
      // });

      return response['id'] as String;
    } catch (e) {
      throw Exception('Erreur lors de l\'envoi de l\'invitation: $e');
    }
  }

  /// Get sent email invitations
  Future<List<FriendInvitation>> getFriendInvitations() async {
    try {
      final userId = _authService.getUserIdOrNull();
      if (userId == null) return [];

      final response = await _supabase
          .from('friend_invitations')
          .select()
          .eq('inviter_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => FriendInvitation.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des invitations: $e');
    }
  }

  // ============================================
  // STATISTICS
  // ============================================

  /// Get friend count
  Future<int> getFriendCount() async {
    try {
      final friends = await getFriends();
      return friends.length;
    } catch (e) {
      return 0;
    }
  }

  /// Get pending requests count (for badge)
  Future<int> getPendingRequestsCount() async {
    try {
      final requests = await getPendingRequests();
      return requests.length;
    } catch (e) {
      return 0;
    }
  }
}
