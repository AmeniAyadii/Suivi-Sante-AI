// lib/services/firebase_notification_service.dart

import 'package:firebase_messaging/firebase_messaging.dart';
//import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:suivi_sante_pro/services/scan_service.dart';
import 'notification_service.dart';

class FirebaseNotificationService {
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;

  static Future<void> initialize() async {
    // Demander la permission
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    print('Permission status: ${settings.authorizationStatus}');

    // Récupérer le token FCM
    final token = await _firebaseMessaging.getToken();
    print('FCM Token: $token');

    // Sauvegarder le token sur le serveur
    await saveTokenToServer(token);

    // Écouter les messages en premier plan
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Message reçu en premier plan: ${message.notification?.title}');

      // Afficher une notification locale
      NotificationService.sendNotification(
        title: message.notification?.title ?? 'Notification',
        body: message.notification?.body ?? '',
        payload: message.data['payload'],
      );
    });

    // Écouter les messages en arrière-plan
    FirebaseMessaging.onBackgroundMessage(_backgroundMessageHandler);

    // Gérer l'ouverture de l'application depuis une notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Ouverture depuis notification: ${message.data}');
      _handleNavigation(message.data);
    });
  }

  // Handler pour les messages en arrière-plan
  @pragma('vm:entry-point')
  static Future<void> _backgroundMessageHandler(RemoteMessage message) async {
    print('Message reçu en arrière-plan: ${message.notification?.title}');

    // Sauvegarder la notification dans une base de données locale
    await saveNotificationLocally(message);

    // Afficher une notification locale
    await NotificationService.sendNotification(
      title: message.notification?.title ?? 'Notification',
      body: message.notification?.body ?? '',
      payload: message.data['payload'],
    );
  }

  static void _handleNavigation(Map<String, dynamic> data) {
    final payload = data['payload'];
    if (payload != null) {
      // Naviguer vers la page appropriée
      if (payload.startsWith('appointment_')) {
        // Naviguer vers les rendez-vous
      } else if (payload.startsWith('medication_')) {
        // Naviguer vers les médicaments
      }
    }
  }

  static Future<void> saveTokenToServer(String? token) async {
    if (token == null) return;

    try {
      // Envoyer le token au backend Laravel
      final service = ScanService();
      await service.saveFcmToken(token);
    } catch (e) {
      print('Erreur lors de l\'enregistrement du token: $e');
    }
  }

  static Future<void> saveNotificationLocally(RemoteMessage message) async {
    // Sauvegarder dans une base de données locale
    // Utiliser SQLite ou SharedPreferences
  }
}
