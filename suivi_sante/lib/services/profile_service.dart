// lib/services/profile_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ProfileService {
  // ✅ URL NGROK
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://unlivable-omnivore-thrive.ngrok-free.dev/api',
  );

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // ✅ Headers avec ngrok-skip-browser-warning
  Future<Map<String, String>> _headers() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'ngrok-skip-browser-warning': 'true', // ✅ INDISPENSABLE
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Mettre à jour le profil
  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    try {
      final headers = await _headers();
      final response = await http
          .put(
            Uri.parse('$baseUrl/profile'),
            headers: headers,
            body: json.encode(data),
          )
          .timeout(const Duration(seconds: 15));

      print('📥 updateProfile Status: ${response.statusCode}');
      print('📥 updateProfile Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw Exception('Erreur ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ Erreur updateProfile: $e');
      rethrow;
    }
  }

  /// Upload photo de profil
  Future<Map<String, dynamic>> uploadPhoto(File file) async {
    try {
      final token = await _getToken();
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/profile/photo'),
      );

      request.headers.addAll({
        'Accept': 'application/json',
        'ngrok-skip-browser-warning': 'true', // ✅ INDISPENSABLE
        if (token != null) 'Authorization': 'Bearer $token',
      });

      request.files.add(await http.MultipartFile.fromPath('photo', file.path));

      final streamedResponse = await request.send().timeout(
            const Duration(seconds: 30),
          );
      final response = await http.Response.fromStream(streamedResponse);

      print('📥 uploadPhoto Status: ${response.statusCode}');
      print('📥 uploadPhoto Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        return {
          'success': false,
          'message': 'Erreur ${response.statusCode}',
        };
      }
    } catch (e) {
      print('❌ Erreur uploadPhoto: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Récupérer le profil
  Future<Map<String, dynamic>> getProfile() async {
    try {
      final headers = await _headers();
      final response = await http
          .get(
            Uri.parse('$baseUrl/profile'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Erreur ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Erreur getProfile: $e');
      rethrow;
    }
  }
}