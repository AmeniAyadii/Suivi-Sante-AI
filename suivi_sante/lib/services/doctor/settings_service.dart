import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
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

  Future<bool> updateSettings(Map<String, dynamic> settings) async {
    final token = await _token();
    final res = await http.put(
      Uri.parse('$baseUrl/user/settings'),
      headers: _headers(token),
      body: jsonEncode(settings),
    );
    return res.statusCode == 200;
  }
}