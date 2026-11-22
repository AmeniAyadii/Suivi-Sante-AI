// lib/services/appointment_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:suivi_sante_pro/config/app_config.dart';

class AppointmentService {
  static String get baseUrl {
    final url = AppConfig.baseUrl;
    return url.endsWith('/') ? url : '$url/';
  }

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

  /// ✅ Ajouter un rendez-vous
  static Future<Map<String, dynamic>> addAppointment({
    required String medecinNom,
    required String dateHeure,
    int duration = 30,
    String? lieu,
    String? type,
    String? motif,
    String? medecinSpecialite,
    String? medecinTelephone,
    String? medecinEmail,
    String? adresse,
    String? codePostal,
    String? ville,
    String? lienVisio,
    String? titre, // ✅ AJOUTER
  }) async {
    try {
      final token = await _getToken();

      final body = {
        'medecin_nom': medecinNom,
        'date_heure': dateHeure,
        'duration': duration,
        'titre': titre ?? 'Consultation médicale', // ✅ Titre par défaut
        if (lieu != null) 'lieu': lieu,
        if (type != null) 'type': type,
        if (motif != null) 'motif': motif,
        if (medecinSpecialite != null) 'medecin_specialite': medecinSpecialite,
        if (medecinTelephone != null) 'medecin_telephone': medecinTelephone,
        if (medecinEmail != null) 'medecin_email': medecinEmail,
        if (adresse != null) 'adresse': adresse,
        if (codePostal != null) 'code_postal': codePostal,
        if (ville != null) 'ville': ville,
        if (lienVisio != null) 'lien_visio': lienVisio,
      };

      final url = _buildUrl('api/appointments');
      print('📤 URL: $url');
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

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'],
          'data': data['data'],
        };
      } else if (response.statusCode == 409) {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'has_conflict': true,
          'conflicts': data['conflicts'] ?? [],
          'message': data['message'] ?? 'Conflit de rendez-vous détecté',
        };
      } else {
        return {'success': false, 'message': 'Erreur (${response.statusCode})'};
      }
    } catch (e) {
      print('❌ Erreur addAppointment: $e');
      return {'success': false, 'message': 'Erreur de connexion: $e'};
    }
  }

  /// ✅ Vérifier les conflits
  static Future<Map<String, dynamic>> checkConflicts({
    required String dateHeure,
    int duration = 30,
  }) async {
    try {
      final token = await _getToken();

      final url = _buildUrl('api/appointments/check-conflicts');
      print('📤 URL: $url');

      final response = await http
          .post(
            Uri.parse(url),
            headers: _getHeaders(token),
            body: jsonEncode({'date_heure': dateHeure, 'duration': duration}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'has_conflict': data['has_conflict'] ?? false,
          'conflicts': data['conflicts'] ?? [],
          'message': data['message'],
        };
      } else {
        return {'success': false, 'has_conflict': false, 'conflicts': []};
      }
    } catch (e) {
      return {
        'success': false,
        'has_conflict': false,
        'conflicts': [],
        'message': 'Erreur: $e',
      };
    }
  }

  /// ✅ Suggérer des rendez-vous à partir des symptômes
  static Future<Map<String, dynamic>> suggestFromSymptoms(
    List<String> symptoms,
  ) async {
    try {
      final token = await _getToken();

      final url = _buildUrl('api/appointments/suggest-from-symptoms');
      print('📤 URL: $url');

      final response = await http
          .post(
            Uri.parse(url),
            headers: _getHeaders(token),
            body: jsonEncode({'symptoms': symptoms}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data['data'] ?? []};
      } else {
        return {'success': false, 'data': []};
      }
    } catch (e) {
      return {'success': false, 'data': [], 'message': 'Erreur: $e'};
    }
  }

  /// ✅ Générer un briefing
  static Future<Map<String, dynamic>> generateBriefing(
    int appointmentId,
  ) async {
    try {
      final token = await _getToken();

      final url = _buildUrl('api/appointments/$appointmentId/briefing');
      print('📤 URL: $url');

      final response = await http
          .post(Uri.parse(url), headers: _getHeaders(token))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data['data']};
      } else {
        return {'success': false, 'message': 'Erreur (${response.statusCode})'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Erreur: $e'};
    }
  }

  /// ✅ Obtenir les rendez-vous du jour
  static Future<List<dynamic>> getTodayAppointments() async {
    try {
      final token = await _getToken();

      final url = _buildUrl('api/appointments/today');
      print('📤 URL: $url');

      final response = await http
          .get(Uri.parse(url), headers: _getHeaders(token))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? [];
      } else {
        return [];
      }
    } catch (e) {
      print('❌ Erreur getTodayAppointments: $e');
      return [];
    }
  }

  /// ✅ Obtenir les rendez-vous à venir
  static Future<List<dynamic>> getUpcomingAppointments() async {
    try {
      final token = await _getToken();

      final url = _buildUrl('api/appointments/upcoming');
      print('📤 URL: $url');

      final response = await http
          .get(Uri.parse(url), headers: _getHeaders(token))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? [];
      } else {
        return [];
      }
    } catch (e) {
      print('❌ Erreur getUpcomingAppointments: $e');
      return [];
    }
  }

  /// ✅ Obtenir la liste des rendez-vous
  static Future<List<dynamic>> getAppointments() async {
    try {
      final token = await _getToken();

      final url = _buildUrl('api/appointments');
      print('📤 URL: $url');

      final response = await http
          .get(Uri.parse(url), headers: _getHeaders(token))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? [];
      } else {
        return [];
      }
    } catch (e) {
      print('❌ Erreur getAppointments: $e');
      return [];
    }
  }

  /// ✅ Annuler un rendez-vous
  static Future<Map<String, dynamic>> cancelAppointment(
    int appointmentId,
  ) async {
    try {
      final token = await _getToken();

      final url = _buildUrl('api/appointments/$appointmentId');
      print('📤 URL: $url');

      final response = await http
          .delete(Uri.parse(url), headers: _getHeaders(token))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Rendez-vous annulé',
        };
      } else {
        return {'success': false, 'message': 'Erreur (${response.statusCode})'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Erreur: $e'};
    }
  }

  /// ✅ Confirmer un rendez-vous
  static Future<Map<String, dynamic>> confirmAppointment(
    int appointmentId,
  ) async {
    try {
      final token = await _getToken();

      final url = _buildUrl('api/appointments/$appointmentId/confirm');
      print('📤 URL: $url');

      final response = await http
          .post(Uri.parse(url), headers: _getHeaders(token))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Rendez-vous confirmé',
          'data': data['data'],
        };
      } else {
        return {'success': false, 'message': 'Erreur (${response.statusCode})'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Erreur: $e'};
    }
  }

  /// ✅ Construire une URL propre
  static String _buildUrl(String path) {
    final base = AppConfig.baseUrl;
    String cleanBase = base.endsWith('/')
        ? base.substring(0, base.length - 1)
        : base;
    String cleanPath = path.startsWith('/') ? path : '/$path';
    return '$cleanBase$cleanPath';
  }
}
