// lib/services/fcm_service.dart
import 'dart:convert';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
//import 'package:suivi_sante_pro/ces/auth_service.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
// ✅ Importer avec un alias pour éviter les conflits
import '../models/notification_model.dart' as app;

class FCMService {
  //static const String baseUrl = 'http://192.168.1.215:8000/api/';
  //static const String baseUrl = 'http://192.168.100.85:8000/api/';
  static const String baseUrl = String.fromEnvironment('API_URL', defaultValue: 'http://192.168.1.215:8001/api');
  static bool _isInitialized = false;
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;

  // ============================================================
  // INITIALISATION
  // ============================================================

  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // ✅ 1. Initialiser timezone
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Europe/Paris'));

      // ✅ 2. Initialiser Awesome Notifications
      await _initializeAwesomeNotifications();

      // ✅ 3. Initialiser Firebase Messaging
      await _initializeFirebaseMessaging();

      // ✅ 4. Demander les permissions
      await _requestPermissions();

      // ✅ 5. Enregistrer le token FCM
      await _registerFCMToken();

      _isInitialized = true;
      debugPrint('✅ FCMService initialisé avec succès');
    } catch (e) {
      debugPrint('❌ Erreur initialisation FCMService: $e');
    }
  }

  // ============================================================
  // AWESOME NOTIFICATIONS
  // ============================================================

  static Future<void> _initializeAwesomeNotifications() async {
    await AwesomeNotifications().initialize('resource://drawable/ic_launcher', [
      NotificationChannel(
        channelKey: 'basic_channel',
        channelName: 'Notifications de base',
        channelDescription: 'Notifications standards',
        defaultColor: Colors.blue,
        importance: NotificationImportance.High,
        channelShowBadge: true,
        playSound: true,
        enableVibration: true,
      ),
      NotificationChannel(
        channelKey: 'action_channel',
        channelName: 'Notifications avec actions',
        channelDescription: 'Notifications avec boutons',
        defaultColor: Colors.green,
        importance: NotificationImportance.Max,
        channelShowBadge: true,
        enableVibration: true,
      ),
      NotificationChannel(
        channelKey: 'scheduled_channel',
        channelName: 'Notifications programmées',
        channelDescription: 'Rappels programmés',
        defaultColor: Colors.orange,
        importance: NotificationImportance.High,
        channelShowBadge: true,
      ),
      NotificationChannel(
        channelKey: 'reminder_channel',
        channelName: 'Rappels',
        channelDescription: 'Rappels de médicaments et rendez-vous',
        defaultColor: Colors.red,
        importance: NotificationImportance.Max,
        channelShowBadge: true,
        enableVibration: true,
        playSound: true,
      ),
    ], debug: true);

    // ✅ Écouter les actions - CORRIGÉ
    AwesomeNotifications().setListeners(
      onActionReceivedMethod: _onActionReceivedMethod,
      onNotificationCreatedMethod:
          _onNotificationCreatedMethod, // ✅ Type correct
      onNotificationDisplayedMethod:
          _onNotificationDisplayedMethod, // ✅ Type correct
      onDismissActionReceivedMethod: _onDismissActionReceivedMethod,
    );
  }

  // ============================================================
  // FIREBASE MESSAGING
  // ============================================================

  static Future<void> _initializeFirebaseMessaging() async {
    final fcm = FirebaseMessaging.instance;

    await fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpened);

    FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);
  }

  // ============================================================
  // PERMISSIONS
  // ============================================================

  static Future<void> _requestPermissions() async {
    try {
      final status = await AwesomeNotifications()
          .requestPermissionToSendNotifications();
      debugPrint('📱 Permissions notification: $status');
    } catch (e) {
      debugPrint('❌ Erreur permissions: $e');
    }
  }

  // ============================================================
  // TOKEN FCM
  // ============================================================

  static Future<void> _registerFCMToken() async {
    try {
      final fcm = FirebaseMessaging.instance;
      final token = await fcm.getToken();

      if (token != null) {
        debugPrint('✅ Token FCM: $token');
        await _sendTokenToServer(token);
      }
    } catch (e) {
      debugPrint('❌ Erreur récupération token: $e');
    }
  }

  static Future<void> _sendTokenToServer(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final apiToken = prefs.getString('token');

      if (apiToken == null) return;

      final response = await http.post(
        Uri.parse('${baseUrl}fcm/register'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiToken',
        },
        body: jsonEncode({'token': token, 'device_type': 'android'}),
      );

      if (response.statusCode == 200) {
        debugPrint('✅ Token FCM envoyé au serveur');
      } else {
        debugPrint('❌ Erreur envoi token: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Erreur: $e');
    }
  }

  // ============================================================
  // GESTION DES MESSAGES
  // ============================================================

  static void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('📩 Message reçu (premier plan): ${message.data}');

    final title = message.notification?.title ?? 'Notification';
    final body = message.notification?.body ?? '';

    _showNotification(
      title: title,
      body: body,
      payload: jsonEncode(message.data),
    );
  }

  static Future<void> _handleMessageOpened(RemoteMessage message) async {
    debugPrint('🔔 Notification ouverte: ${message.data}');
    _navigateToScreen(message.data);
  }

  @pragma('vm:entry-point')
  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    debugPrint('📩 Message reçu (arrière-plan): ${message.data}');
  }

  // ============================================================
  // ACTIONS DES NOTIFICATIONS - CORRIGÉES
  // ============================================================

  @pragma("vm:entry-point")
  static Future<void> _onActionReceivedMethod(
    ReceivedAction receivedAction,
  ) async {
    debugPrint('🔔 Action reçue: ${receivedAction.buttonKeyPressed}');

    final payload = receivedAction.payload ?? {};
    final actionKey = receivedAction.buttonKeyPressed;

    if (actionKey == 'TAKE') {
      debugPrint('✅ Médicament pris !');
      await _updateMedicationStatus(payload);
    } else if (actionKey == 'REMIND') {
      debugPrint('⏰ Rappel dans 30 minutes');
      await _scheduleReminder(payload);
    } else if (actionKey == 'CONFIRM') {
      debugPrint('✅ Rendez-vous confirmé !');
      await _confirmAppointment(payload);
    } else if (actionKey == 'SNOOZE') {
      debugPrint('⏰ Reporté dans 15 minutes');
      await _scheduleSnooze(payload);
    }
  }

  // ✅ CORRIGÉ : Utiliser ReceivedNotification au lieu de NotificationModel
  @pragma("vm:entry-point")
  static Future<void> _onNotificationCreatedMethod(
    ReceivedNotification receivedNotification,
  ) async {
    debugPrint('📝 Notification créée: ${receivedNotification.id}');
  }

  // ✅ CORRIGÉ : Utiliser ReceivedNotification au lieu de NotificationModel
  @pragma("vm:entry-point")
  static Future<void> _onNotificationDisplayedMethod(
    ReceivedNotification receivedNotification,
  ) async {
    debugPrint('📱 Notification affichée: ${receivedNotification.id}');
  }

  @pragma("vm:entry-point")
  static Future<void> _onDismissActionReceivedMethod(
    ReceivedAction receivedAction,
  ) async {
    debugPrint('🗑️ Notification rejetée: ${receivedAction.id}');
  }

  // ============================================================
  // NAVIGATION
  // ============================================================

  static void _navigateToScreen(Map<String, dynamic> data) {
    final type = data['type'] ?? '';
    final screen = data['screen'] ?? '';

    final context = GlobalNavigator.navigatorKey.currentContext;
    if (context == null) return;

    switch (type) {
      case 'appointment':
        Navigator.pushNamed(context, '/rendezvous');
        break;
      case 'medication':
        Navigator.pushNamed(context, '/medicaments');
        break;
      case 'symptom':
        Navigator.pushNamed(context, '/symptomes');
        break;
      case 'health':
        Navigator.pushNamed(context, '/bilan');
        break;
      default:
        if (screen.isNotEmpty) {
          Navigator.pushNamed(context, screen);
        }
        break;
    }
  }

  // ============================================================
  // AFFICHER UNE NOTIFICATION
  // ============================================================

  static Future<void> _showNotification({
    required String title,
    required String body,
    String? payload,
    String channelKey = 'basic_channel',
  }) async {
    try {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
          channelKey: channelKey,
          title: title,
          body: body,
          payload: payload != null ? jsonDecode(payload) : null,
          displayOnForeground: true,
          displayOnBackground: true,
        ),
      );
    } catch (e) {
      debugPrint('❌ Erreur affichage notification: $e');
    }
  }

  // ✅ Méthode UNIQUE pour enregistrer un nouveau token (supprimer la version non-statique)
  static Future<void> registerNewToken() async {
    try {
      // Supprimer l'ancien token
      await _firebaseMessaging.deleteToken();

      // Générer un nouveau token
      String? newToken = await _firebaseMessaging.getToken();

      if (newToken != null) {
        print('✅ Nouveau token FCM: $newToken');

        // Récupérer le token d'authentification
        final prefs = await SharedPreferences.getInstance();
        final authToken = prefs.getString('token');

        if (authToken == null) {
          print('⚠️ Utilisateur non connecté, token non enregistré');
          return;
        }

        // Envoyer le token au serveur
        final response = await http.post(
          Uri.parse('http://192.168.1.215:8000/api/fcm/register'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $authToken',
          },
          body: jsonEncode({'token': newToken}),
        );

        if (response.statusCode == 200) {
          print('✅ Token FCM enregistré sur le serveur');
        } else {
          print('❌ Erreur enregistrement token: ${response.body}');
        }
      }
    } catch (e) {
      print('❌ Erreur registerNewToken: $e');
    }
  }

  // ============================================================
  // MÉTHODES PUBLIQUES
  // ============================================================

  static Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    await _showNotification(title: title, body: body, payload: payload);
  }

  static Future<void> showActionNotification({
    required int id,
    required String title,
    required String body,
    required List<NotificationActionButton> actions,
    String? payload,
  }) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: id,
        channelKey: 'action_channel',
        title: title,
        body: body,
        payload: payload != null ? jsonDecode(payload) : null,
        actionType: ActionType.Default,
      ),
      actionButtons: actions,
    );
  }

  static Future<void> showMedicationReminder({
    required int medicationId,
    required String medicationName,
    required String dosage,
  }) async {
    await showActionNotification(
      id: medicationId,
      title: '💊 Prendre votre médicament',
      body: '$medicationName ($dosage)',
      payload: jsonEncode({
        'medication_id': medicationId,
        'type': 'medication',
      }),
      actions: [
        NotificationActionButton(
          key: 'TAKE',
          label: '✅ Pris',
          actionType: ActionType.Default,
        ),
        NotificationActionButton(
          key: 'REMIND',
          label: '⏰ Rappeler',
          actionType: ActionType.Default,
        ),
      ],
    );
  }

  static Future<void> showAppointmentReminder({
    required int appointmentId,
    required String title,
    required String doctorName,
    required DateTime appointmentTime,
  }) async {
    final timeString =
        '${appointmentTime.hour.toString().padLeft(2, '0')}:${appointmentTime.minute.toString().padLeft(2, '0')}';

    await showActionNotification(
      id: appointmentId + 1000,
      title: '📅 Rappel rendez-vous',
      body: '$title avec Dr. $doctorName à $timeString',
      payload: jsonEncode({
        'appointment_id': appointmentId,
        'type': 'appointment',
      }),
      actions: [
        NotificationActionButton(
          key: 'CONFIRM',
          label: '✅ Confirmer',
          actionType: ActionType.Default,
        ),
        NotificationActionButton(
          key: 'SNOOZE',
          label: '⏰ Reporter',
          actionType: ActionType.Default,
        ),
      ],
    );
  }

  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
    bool repeats = false,
  }) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: id,
        channelKey: 'scheduled_channel',
        title: title,
        body: body,
        payload: payload != null ? jsonDecode(payload) : null,
      ),
      schedule: NotificationCalendar(
        year: scheduledTime.year,
        month: scheduledTime.month,
        day: scheduledTime.day,
        hour: scheduledTime.hour,
        minute: scheduledTime.minute,
        second: scheduledTime.second,
        repeats: repeats,
      ),
    );
  }

  static Future<void> scheduleDaily({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    String? payload,
  }) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: id,
        channelKey: 'scheduled_channel',
        title: title,
        body: body,
        payload: payload != null ? jsonDecode(payload) : null,
      ),
      schedule: NotificationCalendar(
        hour: hour,
        minute: minute,
        second: 0,
        repeats: true,
      ),
    );
  }

  static Future<void> cancelNotification(int id) async {
    await AwesomeNotifications().cancel(id);
  }

  static Future<void> cancelAllNotifications() async {
    await AwesomeNotifications().cancelAll();
  }

  // ============================================================
  // MÉTHODES PRIVÉES POUR LES ACTIONS
  // ============================================================

  static Future<void> _updateMedicationStatus(
    Map<String, dynamic> payload,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) return;

      final medicationId = payload['medication_id'];
      if (medicationId == null) return;

      await http.post(
        Uri.parse('${baseUrl}medicaments/$medicationId/taken'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('✅ Médicament $medicationId marqué comme pris');
    } catch (e) {
      debugPrint('❌ Erreur mise à jour médicament: $e');
    }
  }

  static Future<void> _confirmAppointment(Map<String, dynamic> payload) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) return;

      final appointmentId = payload['appointment_id'];
      if (appointmentId == null) return;

      await http.post(
        Uri.parse('${baseUrl}rendezvous/$appointmentId/confirm'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('✅ Rendez-vous $appointmentId confirmé');
    } catch (e) {
      debugPrint('❌ Erreur confirmation rendez-vous: $e');
    }
  }

  static Future<void> _scheduleReminder(Map<String, dynamic> payload) async {
    final medicationId = payload['medication_id'];
    if (medicationId == null) return;

    await scheduleNotification(
      id: medicationId + 10000,
      title: '⏰ Rappel médicament',
      body: 'N\'oubliez pas de prendre votre médicament',
      scheduledTime: DateTime.now().add(Duration(minutes: 30)),
      payload: jsonEncode({
        'medication_id': medicationId,
        'type': 'medication',
        'reminder': true,
      }),
    );
  }

  static Future<void> _scheduleSnooze(Map<String, dynamic> payload) async {
    final appointmentId = payload['appointment_id'];
    if (appointmentId == null) return;

    await scheduleNotification(
      id: appointmentId + 20000,
      title: '⏰ Rappel rendez-vous',
      body: 'N\'oubliez pas votre rendez-vous',
      scheduledTime: DateTime.now().add(Duration(minutes: 15)),
      payload: jsonEncode({
        'appointment_id': appointmentId,
        'type': 'appointment',
        'snooze': true,
      }),
    );
  }

  // ============================================================
  // MÉTHODE DE TEST
  // ============================================================

  // ✅ Méthode pour tester une notification locale
  static Future<void> testLocalNotification() async {
    await showNotification(
      title: '🔔 Test de notification',
      body: 'Ceci est une notification de test !',
      payload: jsonEncode({'type': 'test', 'screen': '/dashboard'}),
    );
  }
}

// ============================================================
// GLOBAL NAVIGATOR
// ============================================================

class GlobalNavigator {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
}
