import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AdminSettingsService {
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://192.168.1.5:8001/api/',
  );

  Future<String?> _token() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Map<String, String> _headers(String? token) => {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'ngrok-skip-browser-warning': 'true',
      };

  Future<Map<String, dynamic>> getSettings() async {
    final token = await _token();
    final res = await http.get(
      Uri.parse('$baseUrl/admin/settings'),
      headers: _headers(token),
    );
    if (res.statusCode == 200) {
      return json.decode(res.body)['data'];
    }
    throw Exception('Erreur ${res.statusCode}: ${res.body}');
  }

  Future<void> updateSettings(List<Map<String, dynamic>> settings) async {
    final token = await _token();
    final res = await http.put(
      Uri.parse('$baseUrl/admin/settings'),
      headers: _headers(token),
      body: json.encode({'settings': settings}),
    );
    if (res.statusCode != 200) {
      throw Exception('Erreur ${res.statusCode}: ${res.body}');
    }
  }

  Future<void> resetSettings() async {
    final token = await _token();
    final res = await http.post(
      Uri.parse('$baseUrl/admin/settings/reset'),
      headers: _headers(token),
    );
    if (res.statusCode != 200) {
      throw Exception('Erreur ${res.statusCode}: ${res.body}');
    }
  }
}