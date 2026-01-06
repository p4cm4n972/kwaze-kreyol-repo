import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'supabase_service.dart';

// Handler pour les messages en arrière-plan
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  if (kDebugMode) {
    debugPrint('Message reçu en arrière-plan: ${message.messageId}');
  }
}

class PushNotificationService {
  static final PushNotificationService _instance =
      PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  String? _fcmToken;

  String? get fcmToken => _fcmToken;

  // Initialiser Firebase Messaging
  Future<void> initialize() async {
    try {
      // Demander la permission
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        if (kDebugMode) {
          debugPrint('Permission de notification accordée');
        }

        // Obtenir le token FCM
        _fcmToken = await _messaging.getToken();
        if (kDebugMode) {
          debugPrint('FCM Token: $_fcmToken');
        }

        // Sauvegarder le token dans Supabase pour l'utilisateur connecté
        if (_fcmToken != null) {
          await _saveFCMToken(_fcmToken!);
        }

        // Écouter les changements de token
        _messaging.onTokenRefresh.listen((newToken) async {
          _fcmToken = newToken;
          await _saveFCMToken(newToken);
        });

        // Handler pour les messages en premier plan
        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

        // Handler pour les messages en arrière-plan
        FirebaseMessaging.onBackgroundMessage(
            _firebaseMessagingBackgroundHandler);

        // Handler pour quand l'utilisateur clique sur une notification
        FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

        // Vérifier si l'app a été ouverte depuis une notification
        RemoteMessage? initialMessage =
            await _messaging.getInitialMessage();
        if (initialMessage != null) {
          _handleMessageOpenedApp(initialMessage);
        }
      } else {
        if (kDebugMode) {
          debugPrint('Permission de notification refusée');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Erreur lors de l\'initialisation FCM: $e');
      }
    }
  }

  // Sauvegarder le token FCM dans Supabase
  Future<void> _saveFCMToken(String token) async {
    try {
      final userId = SupabaseService.instance.currentUser?.id;
      if (userId != null) {
        await SupabaseService.client.from('users').update({
          'fcm_token': token,
        }).eq('id', userId);

        if (kDebugMode) {
          debugPrint('Token FCM sauvegardé dans Supabase');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Erreur lors de la sauvegarde du token FCM: $e');
      }
    }
  }

  // Gérer les messages reçus en premier plan
  void _handleForegroundMessage(RemoteMessage message) {
    if (kDebugMode) {
      debugPrint('Message reçu en premier plan: ${message.messageId}');
      debugPrint('Titre: ${message.notification?.title}');
      debugPrint('Corps: ${message.notification?.body}');
      debugPrint('Data: ${message.data}');
    }

    // Ici vous pouvez afficher une notification locale
    // ou mettre à jour l'UI directement
  }

  // Gérer quand l'utilisateur clique sur une notification
  void _handleMessageOpenedApp(RemoteMessage message) {
    if (kDebugMode) {
      debugPrint('Notification cliquée: ${message.messageId}');
      debugPrint('Data: ${message.data}');
    }

    // Navigation vers l'écran approprié selon le type de notification
    final data = message.data;
    if (data.containsKey('type')) {
      switch (data['type']) {
        case 'invitation':
          // Naviguer vers l'écran des invitations
          final sessionId = data['session_id'];
          if (sessionId != null) {
            // TODO: Navigation vers la session
            if (kDebugMode) {
              debugPrint('Ouvrir invitation pour session: $sessionId');
            }
          }
          break;
        case 'round_update':
          // Naviguer vers la session active
          final sessionId = data['session_id'];
          if (sessionId != null) {
            // TODO: Navigation vers la session
            if (kDebugMode) {
              debugPrint('Ouvrir session: $sessionId');
            }
          }
          break;
        case 'game_completed':
          // Naviguer vers les résultats
          final sessionId = data['session_id'];
          if (sessionId != null) {
            // TODO: Navigation vers les résultats
            if (kDebugMode) {
              debugPrint('Ouvrir résultats session: $sessionId');
            }
          }
          break;
      }
    }
  }

  // Envoyer une notification via Supabase Edge Function
  Future<void> sendNotification({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      await SupabaseService.client.functions.invoke(
        'send-notification',
        body: {
          'user_id': userId,
          'title': title,
          'body': body,
          'data': data ?? {},
        },
      );

      if (kDebugMode) {
        debugPrint('Notification envoyée à $userId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Erreur lors de l\'envoi de la notification: $e');
      }
    }
  }

  // S'abonner à un topic (pour les notifications de groupe)
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      if (kDebugMode) {
        debugPrint('Abonné au topic: $topic');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Erreur lors de l\'abonnement au topic: $e');
      }
    }
  }

  // Se désabonner d'un topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      if (kDebugMode) {
        debugPrint('Désabonné du topic: $topic');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Erreur lors du désabonnement du topic: $e');
      }
    }
  }
}
