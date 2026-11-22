import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class DoctorListService {
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://unlivable-omnivore-thrive.ngrok-free.dev/api',
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

  /// GET /api/doctors
  Future<List<Map<String, dynamic>>> getDoctors() async {
    final token = await _token();
    final res = await http.get(
      Uri.parse('$baseUrl/doctors'),
      headers: _headers(token),
    );
    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      return List<Map<String, dynamic>>.from(data['data'] ?? []);
    }
    throw Exception('Erreur ${res.statusCode}');
  }

  /// GET /api/doctors/{id}/availability?date=YYYY-MM-DD
  Future<Map<String, dynamic>> getAvailability(int doctorId, DateTime date) async {
    final token = await _token();
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final res = await http.get(
      Uri.parse('$baseUrl/doctors/$doctorId/availability?date=$dateStr'),
      headers: _headers(token),
    );
    if (res.statusCode == 200) {
      return json.decode(res.body)['data'] ?? {};
    }
    throw Exception('Erreur ${res.statusCode}');
  }

  
}