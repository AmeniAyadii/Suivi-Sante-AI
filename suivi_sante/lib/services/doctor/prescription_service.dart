import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class PrescriptionService {
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

  Future<Map<String, dynamic>> createPrescription({
    required int patientId,
    required String instructions,
    required List<Map<String, dynamic>> medicaments,
  }) async {
    final token = await _token();
    final res = await http.post(
      Uri.parse('$baseUrl/prescriptions'),
      headers: _headers(token),
      body: jsonEncode({
        'patient_id': patientId,
        'instructions': instructions,
        'medicaments': medicaments,
      }),
    );

    final data = jsonDecode(res.body);
    if (res.statusCode == 201) {
      return data;
    }
    throw Exception(data['message'] ?? 'Erreur lors de la création');
  }
}