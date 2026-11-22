import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class StatistiqueService {
  // ✅ URL NGROK (remplacez par la vôtre si elle change)
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://unlivable-omnivore-thrive.ngrok-free.dev/api',
  );

  // ==================== GESTION DU TOKEN ====================
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

  // ==================== MÉTHODE GÉNÉRIQUE ====================
  Future<Map<String, dynamic>> _getRequest(
    String endpoint, {
    Map<String, String>? queryParams,
    bool returnEmptyOnError = true,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        print('❌ Token absent - Utilisateur non authentifié');
        throw Exception('Veuillez vous reconnecter');
      }

      var uri = Uri.parse('$baseUrl/$endpoint');
      if (queryParams != null && queryParams.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParams);
      }

      print('📤 GET Request: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'ngrok-skip-browser-warning': 'true', // ✅ INDISPENSABLE POUR NGROK
          'Authorization': 'Bearer $token',
        },
      );

      print('📥 Status Code: ${response.statusCode}');
      print('📥 Body: ${response.body.length > 500 ? '${response.body.substring(0, 500)}...' : response.body}');

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          if (data['success'] == true) {
            return data['data'] ?? {};
          } else {
            throw Exception(data['message'] ?? 'Erreur inconnue');
          }
        } catch (e) {
          print('⚠️ Erreur de parsing JSON: $e');
          if (returnEmptyOnError) return {};
          rethrow;
        }
      } else if (response.statusCode == 401) {
        throw Exception('Session expirée. Veuillez vous reconnecter.');
      } else if (response.statusCode == 422) {
        return {};
      } else if (response.statusCode == 404) {
        print('⚠️ Endpoint non trouvé: $endpoint');
        return {};
      } else {
        throw Exception('Erreur serveur (${response.statusCode})');
      }
    } catch (e) {
      print('❌ Erreur _getRequest pour $endpoint: $e');
      if (returnEmptyOnError) return {};
      rethrow;
    }
  }

  // ==================== MÉTHODES SPÉCIFIQUES ====================
  Future<Map<String, dynamic>> getGlobalStats({String period = 'month'}) async {
    return _getRequest('statistiques/global', queryParams: {'period': period});
  }

  Future<Map<String, dynamic>> getMedicationStats() async {
    return _getRequest('statistiques/medicaments', returnEmptyOnError: true);
  }

  Future<Map<String, dynamic>> getSymptomStats({String period = 'month'}) async {
    return _getRequest('statistiques/symptomes', queryParams: {'period': period});
  }

  Future<Map<String, dynamic>> getAppointmentStats() async {
    return _getRequest('statistiques/rendezvous', returnEmptyOnError: true);
  }

  Future<Map<String, dynamic>> getHealthStats() async {
    return _getRequest('statistiques/sante');
  }

  // ==================== MÉTHODES DE TEST ====================
  Future<void> testEndpoint(String endpoint, {Map<String, String>? queryParams}) async {
    try {
      final token = await _getToken();
      if (token == null) return;

      var uri = Uri.parse('$baseUrl/$endpoint');
      if (queryParams != null && queryParams.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParams);
      }

      print('📤 Test URL: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'ngrok-skip-browser-warning': 'true', // ✅ AJOUT
          'Authorization': 'Bearer $token',
        },
      );

      print('📥 Test Status: ${response.statusCode}');
      print('📥 Test Body: ${response.body}');
    } catch (e) {
      print('❌ Test error: $e');
    }
  }

  Future<void> testAllEndpoints() async {
    await testEndpoint('statistiques/global', queryParams: {'period': 'month'});
    await testEndpoint('statistiques/medicaments');
    await testEndpoint('statistiques/symptomes', queryParams: {'period': 'month'});
    await testEndpoint('statistiques/rendezvous');
    await testEndpoint('statistiques/sante');
  }

  // ==================== UTILITAIRES ====================
  Future<bool> isAuthenticated() async {
    final token = await _getToken();
    return token != null;
  }

  Future<Map<String, dynamic>> getStatsSafe(
    Future<Map<String, dynamic>> Function() getStats,
  ) async {
    try {
      return await getStats();
    } catch (e) {
      print('⚠️ Erreur silencieuse: $e');
      return {};
    }
  }

  Future<Map<String, Map<String, dynamic>>> getAllStats({String period = 'month'}) async {
    try {
      final results = await Future.wait([
        getGlobalStats(period: period),
        getMedicationStats(),
        getSymptomStats(period: period),
        getAppointmentStats(),
        getHealthStats(),
      ]);

      return {
        'global': results[0],
        'medication': results[1],
        'symptom': results[2],
        'appointment': results[3],
        'health': results[4],
      };
    } catch (e) {
      print('❌ Erreur getAllStats: $e');
      return {
        'global': {},
        'medication': {},
        'symptom': {},
        'appointment': {},
        'health': {},
      };
    }
  }
}