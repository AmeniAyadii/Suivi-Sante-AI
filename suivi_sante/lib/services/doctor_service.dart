import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class DoctorService {
  // ✅ URL ngrok avec /api à la fin
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://192.168.1.5:8001/api/',
  );

  Future<String?> _token() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // ✅ En-têtes communs avec ngrok
  Map<String, String> _headers(String? token) => {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'ngrok-skip-browser-warning': 'true',
      };

  // ==================== DASHBOARD ====================
  Future<Map<String, dynamic>> getDashboard() async {
    final token = await _token();
    final res = await http.get(
      Uri.parse('$baseUrl/doctor/dashboard'), // ✅ /api/doctor/dashboard
      headers: _headers(token),
    );
    if (res.statusCode == 200) return json.decode(res.body)['stats'];
    throw Exception('Erreur ${res.statusCode}');
  }

  // ==================== PATIENTS ====================
  Future<List<dynamic>> getPatients({String? search}) async {
    final token = await _token();
    final params = <String, String>{};
    if (search != null && search.isNotEmpty) params['search'] = search;

    final uri = Uri.parse('$baseUrl/doctor/patients')
        .replace(queryParameters: params.isEmpty ? null : params);

    final res = await http.get(uri, headers: _headers(token));
    if (res.statusCode == 200) return json.decode(res.body)['patients'] ?? [];
    throw Exception('Erreur ${res.statusCode}');
  }

  Future<Map<String, dynamic>> getPatientDetail(int id) async {
    final token = await _token();
    final res = await http.get(
      Uri.parse('$baseUrl/doctor/patients/$id'),
      headers: _headers(token),
    );
    if (res.statusCode == 200) return json.decode(res.body);
    throw Exception('Erreur ${res.statusCode}');
  }

  // ==================== RENDEZ-VOUS ====================
  Future<List<dynamic>> getRendezvous({
    String? statut,
    String? periode,
    String? search,
  }) async {
    final token = await _token();
    final params = <String, String>{};
    if (statut != null && statut != 'all') params['statut'] = statut;
    if (periode != null) params['periode'] = periode;
    if (search != null && search.isNotEmpty) params['search'] = search;

    final uri = Uri.parse('$baseUrl/doctor/rendezvous')
        .replace(queryParameters: params.isEmpty ? null : params);

    final res = await http.get(uri, headers: _headers(token));
    if (res.statusCode == 200) return json.decode(res.body)['rendezvous'] ?? [];
    throw Exception('Erreur ${res.statusCode}');
  }

  Future<void> updateRendezvousStatus(int id, String statut) async {
    final token = await _token();
    final res = await http.patch(
      Uri.parse('$baseUrl/doctor/rendezvous/$id/status'),
      headers: _headers(token),
      body: json.encode({'statut': statut}),
    );
    if (res.statusCode != 200) throw Exception('Erreur ${res.statusCode}');
  }

  // ==================== PRESCRIPTIONS ====================
  Future<List<dynamic>> getPrescriptions({String? statut, String? search}) async {
    final token = await _token();
    final params = <String, String>{};
    if (statut != null && statut != 'all') params['statut'] = statut;
    if (search != null && search.isNotEmpty) params['search'] = search;

    final uri = Uri.parse('$baseUrl/doctor/prescriptions')
        .replace(queryParameters: params.isEmpty ? null : params);

    final res = await http.get(uri, headers: _headers(token));
    if (res.statusCode == 200) return json.decode(res.body)['prescriptions'] ?? [];
    throw Exception('Erreur ${res.statusCode}');
  }

  Future<Map<String, dynamic>> createPrescription({
    required int patientId,
    required String nom,
    String? dosage,
    String? frequence,
    String? prochainePrise,
    String? notes,
  }) async {
    final token = await _token();
    final body = {
      'patient_id': patientId,
      'nom': nom,
      if (dosage != null) 'dosage': dosage,
      if (frequence != null) 'frequence': frequence,
      if (prochainePrise != null) 'prochaine_prise': prochainePrise,
      if (notes != null) 'notes': notes,
    };

    final res = await http.post(
      Uri.parse('$baseUrl/doctor/prescriptions'),
      headers: _headers(token),
      body: json.encode(body),
    );

    if (res.statusCode == 200 || res.statusCode == 201) {
      return json.decode(res.body);
    }
    final error = json.decode(res.body);
    throw Exception(error['message'] ?? 'Erreur ${res.statusCode}');
  }

  Future<void> updateMedicamentStatus(int id, String statut) async {
    final token = await _token();
    final res = await http.patch(
      Uri.parse('$baseUrl/doctor/prescriptions/$id/status'),
      headers: _headers(token),
      body: json.encode({'statut': statut}),
    );
    if (res.statusCode != 200) throw Exception('Erreur ${res.statusCode}');
  }

  // ==================== PROFIL ====================
  Future<Map<String, dynamic>> getProfile() async {
    final token = await _token();
    final res = await http.get(
      Uri.parse('$baseUrl/doctor/profile'),
      headers: _headers(token),
    );
    if (res.statusCode == 200) return json.decode(res.body)['doctor'];
    throw Exception('Erreur ${res.statusCode}');
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    final token = await _token();
    final res = await http.put(
      Uri.parse('$baseUrl/doctor/profile'),
      headers: _headers(token),
      body: json.encode(data),
    );
    if (res.statusCode == 200) return json.decode(res.body)['doctor'];
    throw Exception('Erreur ${res.statusCode}');
  }
    Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<List<dynamic>> getHistorique() async {
  final token = await _getToken();
  final response = await http.get(
    Uri.parse('$baseUrl/doctor/historique'),
    headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    },
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return data['data'] ?? [];
  }
  throw Exception('Erreur lors du chargement de l\'historique');
}

Future<Map<String, dynamic>> getAgenda(String date) async {
  final token = await _getToken();
  final response = await http.get(
    Uri.parse('$baseUrl/doctor/agenda?date=$date'),
    headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'ngrok-skip-browser-warning': 'true',
    },
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  }
  throw Exception('Erreur lors du chargement de l\'agenda');
}

Future<Map<String, dynamic>> createRendezvous({
  required int patientId,
  required String titre,
  required DateTime dateHeure,
  int duree = 30,
  String type = 'Consultation',
  String? lieu,
  String? notes,
}) async {
  final token = await _token();
  final body = {
    'patient_id': patientId,
    'titre': titre,
    'date_heure': dateHeure.toIso8601String(),
    'duree': duree,
    'type': type,
    if (lieu != null && lieu.isNotEmpty) 'lieu': lieu,
    if (notes != null && notes.isNotEmpty) 'notes': notes,
  };

  final res = await http.post(
    Uri.parse('$baseUrl/doctor/rendezvous'),
    headers: _headers(token),
    body: json.encode(body),
  );

  if (res.statusCode == 200 || res.statusCode == 201) {
    return json.decode(res.body);
  }
  final error = json.decode(res.body);
  throw Exception(error['message'] ?? 'Erreur ${res.statusCode}');
}
}