import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/health_assessment.dart';

class HealthAssessmentService {
  // ✅ URL NGROK
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://unlivable-omnivore-thrive.ngrok-free.dev/api',
  );

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // ✅ En-têtes communs incluant le contournement ngrok
  Map<String, String> _headers(String? token) => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'ngrok-skip-browser-warning': 'true', // ✅ INDISPENSABLE
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Future<HealthAssessment> getLatest() async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/health-assessment/latest'),
        headers: _headers(token),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return HealthAssessment.fromJson(data['data']);
      }
      throw Exception('Erreur ${response.statusCode}');
    } catch (e) {
      throw Exception('Erreur: $e');
    }
  }

  Future<List<HealthAssessment>> getHistory() async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/health-assessment/history'),
        headers: _headers(token),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['data'] as List)
            .map((item) => HealthAssessment.fromJson(item))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<HealthAssessment> saveAssessment(Map<String, dynamic> data) async {
    try {
      final token = await _getToken();
      final response = await http.post(
        Uri.parse('$baseUrl/health-assessment'),
        headers: _headers(token),
        body: json.encode(data),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final result = json.decode(response.body);
        return HealthAssessment.fromJson(result['data']);
      } 
      // ✅ AJOUT : Gestion spécifique de l'erreur 422 (Validation Laravel)
      else if (response.statusCode == 422) {
        final result = json.decode(response.body);
        final errors = result['errors'] as Map<String, dynamic>?;
        
        if (errors != null && errors.isNotEmpty) {
          // On formate les erreurs pour qu'elles soient lisibles
          final errorMessages = errors.entries
              .map((e) => "• ${e.key} : ${(e.value as List).join(', ')}")
              .join('\n');
          throw Exception('Erreurs de validation :\n$errorMessages');
        }
        throw Exception(result['message'] ?? 'Données invalides');
      } 
      else {
        throw Exception('Erreur serveur (${response.statusCode})');
      }
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }
}