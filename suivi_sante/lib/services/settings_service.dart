import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  //static const String baseUrl = 'http://192.168.100.85:8000/api/';
  //static const String baseUrl = 'http://192.168.1.215:8000/api/';
  //static const String baseUrl = String.fromEnvironment('API_URL', defaultValue: 'http://192.168.1.215:8000/api');
  // Remplace l'adresse IP par ton URL ngrok
//static const String baseUrl = 'https://unlivable-omnivore-thrive.ngrok-free.dev/api/';
static const String baseUrl = 'http://192.168.1.5:8001/api/';

  Future<Map<String, dynamic>> getSettings() async {
    try {
      final token = await _getToken();
      final url = Uri.parse('${baseUrl}settings');
      
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Connexion au serveur impossible');
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['data'];
        }
        throw Exception('Erreur de chargement');
      } else {
        throw Exception('Erreur ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur: $e');
    }
  }

  Future<Map<String, dynamic>> updateSettings(Map<String, dynamic> settings) async {
    try {
      final token = await _getToken();
      final url = Uri.parse('${baseUrl}settings');
      
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: json.encode(settings),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Connexion au serveur impossible');
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data;
        }
        throw Exception(data['message'] ?? 'Erreur de mise à jour');
      } else {
        throw Exception('Erreur ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur: $e');
    }
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }
}