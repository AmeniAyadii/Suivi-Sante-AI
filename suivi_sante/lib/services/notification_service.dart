
// lib/services/notification_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  // Backend Laravel local
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://192.168.1.5:8001/api',
  );

  // Construction sécurisée des URL
  Uri _endpoint(String path, [Map<String, String>? queryParameters]) {
    final base = baseUrl.replaceAll(RegExp(r'/+$'), '');
    final normalizedPath = path.replaceAll(RegExp(r'^/+'), '');

    return Uri.parse('$base/$normalizedPath')
        .replace(queryParameters: queryParameters);
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Map<String, String> _headers(String token) => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

  // Récupérer les notifications
  Future<Map<String, dynamic>> getNotifications({
    int limit = 50,
  }) async {
    final token = await _getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Non authentifié : token manquant');
    }

    final url = _endpoint(
      'notifications',
      {'limit': limit.toString()},
    );

    print('🔔 GET Notifications : $url');

    final response = await http.get(
      url,
      headers: _headers(token),
    );

    print('📥 Status : ${response.statusCode}');
    print('📥 Réponse : ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));

      if (data is Map<String, dynamic>) {
        return data;
      }

      throw Exception('Format de réponse API inattendu');
    }

    throw Exception(
      'Erreur notifications (${response.statusCode}) : ${response.body}',
    );
  }

  // Affichage local d'une notification
  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    print('🔔 Notification : $title');
    print('📱 Message : $body');
  }

  // Marquer une notification comme lue
  Future<void> markAsRead(int notificationId) async {
    await _sendRequest(
      'PUT',
      'notifications/$notificationId/read',
    );
  }

  // Tout marquer comme lu
  Future<void> markAllAsRead() async {
    await _sendRequest(
      'PUT',
      'notifications/read-all',
    );
  }

  // Supprimer une notification
  Future<void> deleteNotification(int notificationId) async {
    await _sendRequest(
      'DELETE',
      'notifications/$notificationId',
    );
  }

  // Méthode HTTP commune
  Future<void> _sendRequest(String method, String path) async {
    final token = await _getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Non authentifié : token manquant');
    }

    final url = _endpoint(path);

    print('🔔 $method : $url');

    late http.Response response;

    switch (method) {
      case 'PUT':
        response = await http.put(
          url,
          headers: _headers(token),
        );
        break;

      case 'DELETE':
        response = await http.delete(
          url,
          headers: _headers(token),
        );
        break;

      default:
        throw Exception('Méthode HTTP non supportée : $method');
    }

    print('📥 Status : ${response.statusCode}');
    print('📥 Réponse : ${response.body}');

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception(
        'Erreur HTTP ${response.statusCode} : ${response.body}',
      );
    }
  }
}
