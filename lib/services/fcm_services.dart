import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class FcmService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  Future<void> initLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    // On crée un canal de haute importance pour forcer l'affichage de la bulle
    const channel = AndroidNotificationChannel(
      'high_importance_channel', // id
      'Notifications Importantes', // name
      description: 'Ce canal est utilisé pour les notifications prioritaires.',
      importance: Importance.max,
    );

    // Enregistrement du canal (pour Android 8+)
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await _localNotifications.initialize(
      settings: const InitializationSettings(android: androidSettings),
    );
  }

  void listenForegroundMessages() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification != null) {
        _localNotifications.show(
          id: notification.hashCode,
          title: notification.title,
          body: notification.body,
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              'high_importance_channel', 
              'Notifications Importantes',
              importance: Importance.max,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
            ),
          ),
        );
      }
    });
  }

  Future<void> initAfterLogin({
    required Future<void> Function(String) onTokenReady,
  }) async {
    // 1. Demander la permission (obligatoire sur iOS, et sur Android 13+)
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      return;
    }

    // 2. Récupérer le token actuel
    final token = await _messaging.getToken();
    if (token != null) {
      await onTokenReady(token);
    }
    
    // Inscription au topic pour les tests (Module 12)
    try {
      await FirebaseMessaging.instance.subscribeToTopic('vip_customers');
      print('✅ Inscription au topic vip_customers réussie');
    } catch (e) {
      print('❌ Erreur inscription topic: $e');
    }

    // 3. Écouter le renouvellement du token
    _messaging.onTokenRefresh.listen((newToken) async {
      await onTokenReady(newToken);
    });
  }
}
