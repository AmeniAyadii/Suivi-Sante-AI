// lib/services/chatbot/voice_scheduler_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:suivi_sante_pro/config/app_config.dart';

class VoiceSchedulerService {
  static Future<String?> _getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('token');
    } catch (e) {
      return null;
    }
  }

  static Map<String, String> _getHeaders(String? token) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// ✅ Construire une URL propre (CORRIGÉ - Version finale)
  // lib/services/chatbot/voice_scheduler_service.dart

  // ✅ Version ultra-simple (remplacez _buildUrl par cette fonction)
  static String _buildUrl(String path) {
    // Nettoyer la base
    String base = AppConfig.baseUrl;
    if (base.endsWith('/')) {
      base = base.substring(0, base.length - 1);
    }

    // Nettoyer le chemin
    String cleanPath = path;
    if (cleanPath.startsWith('/')) {
      cleanPath = cleanPath.substring(1);
    }

    // Si la base se termine par /api et le chemin commence par api/
    if (base.endsWith('/api') && cleanPath.startsWith('api/')) {
      cleanPath = cleanPath.substring(4);
    }

    // Construire l'URL
    String url = '$base/$cleanPath';

    // Supprimer les doubles slashes (sauf après http:)
    url = url.replaceAll(RegExp(r'(?<!http:)/{2,}'), '/');

    print('🔵 URL: $url');
    return url;
  }

  /// ✅ Démarrer le Scheduler Vocal
  static Future<Map<String, dynamic>> startScheduler({
    required String doctorName,
    String? cabinetPhone,
    String? date,
    String? time,
  }) async {
    try {
      final token = await _getToken();

      if (token == null || token.isEmpty) {
        return {'success': false, 'message': '🔒 Veuillez vous connecter.'};
      }

      // ✅ URL finale: http://192.168.1.215:8000/api/voice-scheduler/start
      final url = _buildUrl('voice-scheduler/start');
      print('📤 URL: $url');

      final body = {
        'doctor_name': doctorName,
        if (cabinetPhone != null) 'cabinet_phone': cabinetPhone,
        if (date != null) 'date': date,
        if (time != null) 'time': time,
      };
      print('📤 Body: $body');

      final response = await http
          .post(
            Uri.parse(url),
            headers: _getHeaders(token),
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));

      print('📥 Statut: ${response.statusCode}');
      print('📥 Réponse: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'message': 'Erreur (${response.statusCode})'};
      }
    } catch (e) {
      print('❌ Erreur startScheduler: $e');
      return {'success': false, 'message': 'Erreur de connexion: $e'};
    }
  }

  /// ✅ Accepter un créneau alternatif
  static Future<Map<String, dynamic>> acceptAlternative(int callId) async {
    try {
      final token = await _getToken();

      if (token == null || token.isEmpty) {
        return {'success': false, 'message': '🔒 Veuillez vous connecter.'};
      }

      final url = _buildUrl('voice-scheduler/$callId/accept');
      print('📤 URL: $url');

      final response = await http
          .post(Uri.parse(url), headers: _getHeaders(token))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'message': 'Erreur (${response.statusCode})'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Erreur: $e'};
    }
  }

  /// ✅ Refuser un créneau alternatif
  static Future<Map<String, dynamic>> rejectAlternative(int callId) async {
    try {
      final token = await _getToken();

      if (token == null || token.isEmpty) {
        return {'success': false, 'message': '🔒 Veuillez vous connecter.'};
      }

      final url = _buildUrl('voice-scheduler/$callId/reject');
      print('📤 URL: $url');

      final response = await http
          .post(Uri.parse(url), headers: _getHeaders(token))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'message': 'Erreur (${response.statusCode})'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Erreur: $e'};
    }
  }

  /// ✅ Obtenir le statut d'un appel
  static Future<Map<String, dynamic>> getStatus(int callId) async {
    try {
      final token = await _getToken();

      if (token == null || token.isEmpty) {
        return {'success': false, 'message': '🔒 Veuillez vous connecter.'};
      }

      final url = _buildUrl('voice-scheduler/$callId/status');
      print('📤 URL: $url');

      final response = await http
          .get(Uri.parse(url), headers: _getHeaders(token))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'message': 'Erreur (${response.statusCode})'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Erreur: $e'};
    }
  }
}
