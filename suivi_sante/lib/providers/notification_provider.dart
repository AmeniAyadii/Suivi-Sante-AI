
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

class NotificationProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = false;
  String? _error;
  int _nonLues = 0;

  List<Map<String, dynamic>> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get nonLues => _nonLues;

  // Construire correctement les URL sans doubles slashs
  Uri _notificationUrl(String path) {
    final base = AppConfig.baseUrl.replaceAll(RegExp(r'/+$'), '');
    final normalizedPath = path.replaceAll(RegExp(r'^/+'), '');

    return Uri.parse('$base/$normalizedPath');
  }

  Future<String?> _getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      print('📤 Token récupéré: ${token != null ? 'Présent' : 'Absent'}');

      return token;
    } catch (e) {
      print('❌ Erreur récupération token: $e');
      return null;
    }
  }

  // Charger les notifications
  Future<void> loadNotifications() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = await _getToken();

      if (token == null || token.isEmpty) {
        _error = 'Veuillez vous reconnecter';
        _isLoading = false;
        notifyListeners();
        return;
      }

      final uri = _notificationUrl('notifications');

      print('📤 URL complète: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📥 Status Code: ${response.statusCode}');
      print('📥 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));

        print('📥 Données décodées: $data');

        if (data['success'] == true) {
          if (data['data'] is List) {
            _notifications =
                List<Map<String, dynamic>>.from(data['data']);

            _nonLues = data['non_lues'] ?? 0;
            _error = null;

            print('✅ ${_notifications.length} notifications chargées');
            print('📊 Non lues: $_nonLues');
          } else if (data['data'] is Map &&
              data['data']['notifications'] is List) {
            _notifications = List<Map<String, dynamic>>.from(
              data['data']['notifications'],
            );

            _nonLues = data['data']['non_lues'] ?? 0;
            _error = null;

            print(
              '✅ ${_notifications.length} notifications chargées (format alternatif)',
            );
          } else {
            _error = 'Format de données invalide';
            print('❌ Format de données invalide');
          }
        } else {
          _error = data['message'] ?? 'Erreur de chargement';
          print('❌ Erreur API: ${data['message']}');
        }
      } else if (response.statusCode == 401) {
        _error = 'Session expirée. Veuillez vous reconnecter.';
        print('❌ Session expirée');
        await _logout();
      } else if (response.statusCode == 403) {
        _error = 'Accès refusé. Vérifiez les autorisations de votre compte.';
        print('❌ Accès refusé (403)');
      } else if (response.statusCode == 404) {
        _error = 'API non trouvée. Vérifiez l\'URL';
        print('❌ API non trouvée (404)');
        print('🔍 URL utilisée: $uri');
      } else {
        _error = 'Erreur de chargement (${response.statusCode})';
        print('❌ Erreur HTTP: ${response.statusCode}');
      }
    } catch (e) {
      _error = 'Erreur: $e';
      print('❌ Exception: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  // Envoyer une notification de test
  Future<bool> sendTestNotification() async {
    try {
      final token = await _getToken();

      if (token == null || token.isEmpty) {
        _error = 'Veuillez vous reconnecter';
        notifyListeners();
        return false;
      }

      print('📤 Envoi d\'une notification de test...');

      final response = await http.post(
        _notificationUrl('notifications/test'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📥 Status Code: ${response.statusCode}');
      print('📥 Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));

        print('✅ Notification de test envoyée: ${data['message']}');

        return true;
      } else {
        print('❌ Erreur envoi test: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ Erreur: $e');
      return false;
    }
  }

  // Marquer une notification comme lue
  Future<void> markAsRead(int id) async {
    try {
      final token = await _getToken();

      if (token == null || token.isEmpty) return;

      print('📖 Marquage de la notification $id comme lue');

      final response = await http.put(
        _notificationUrl('notifications/$id/read'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final index = _notifications.indexWhere((n) => n['id'] == id);

        if (index != -1) {
          _notifications[index]['lu'] = true;

          _nonLues = _notifications
              .where((n) => n['lu'] == false)
              .length;

          notifyListeners();

          print('✅ Notification $id marquée comme lue');
        }
      } else {
        print('❌ Erreur marquage: ${response.statusCode}');
        print('📥 Réponse: ${response.body}');
      }
    } catch (e) {
      print('❌ Erreur markAsRead: $e');
    }
  }

  // Marquer toutes les notifications comme lues
  Future<void> markAllAsRead() async {
    try {
      final token = await _getToken();

      if (token == null || token.isEmpty) return;

      print('📖 Marquage de toutes les notifications comme lues');

      final response = await http.put(
        _notificationUrl('notifications/read-all'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        for (var notification in _notifications) {
          notification['lu'] = true;
        }

        _nonLues = 0;

        notifyListeners();

        print('✅ Toutes les notifications marquées comme lues');
      } else {
        print('❌ Erreur marquage toutes: ${response.statusCode}');
        print('📥 Réponse: ${response.body}');
      }
    } catch (e) {
      print('❌ Erreur markAllAsRead: $e');
    }
  }

  // Supprimer une notification
  Future<void> deleteNotification(int id) async {
    try {
      final token = await _getToken();

      if (token == null || token.isEmpty) return;

      print('🗑️ Suppression de la notification $id');

      final response = await http.delete(
        _notificationUrl('notifications/$id'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        _notifications.removeWhere((n) => n['id'] == id);

        _nonLues = _notifications
            .where((n) => n['lu'] == false)
            .length;

        notifyListeners();

        print('✅ Notification $id supprimée');
      } else {
        print('❌ Erreur suppression: ${response.statusCode}');
        print('📥 Réponse: ${response.body}');
      }
    } catch (e) {
      print('❌ Erreur deleteNotification: $e');
    }
  }
}
