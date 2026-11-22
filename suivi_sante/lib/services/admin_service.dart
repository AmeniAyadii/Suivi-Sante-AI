import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AdminService {
  // ✅ URL ngrok avec /api à la fin
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://192.168.1.5:8001/api/',
  );

  Future<String?> _token() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // ✅ Ajout de l'en-tête ngrok dans tous les appels
  Map<String, String> _headers(String? token) => {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'ngrok-skip-browser-warning': 'true', // ✅ INDISPENSABLE
      };

  Future<List<dynamic>> getUsers() async {
    final token = await _token();
    final res = await http.get(
      Uri.parse('$baseUrl/admin/users'), // ✅ /api/admin/users
      headers: _headers(token),
    );
    if (res.statusCode == 200) return json.decode(res.body)['users'] ?? [];
    throw Exception('Erreur ${res.statusCode}');
  }

  Future<void> assignRole(int userId, String role) async {
    final token = await _token();
    final res = await http.post(
      Uri.parse('$baseUrl/admin/users/$userId/role'),
      headers: _headers(token),
      body: json.encode({'role': role}),
    );
    if (res.statusCode != 200) throw Exception('Erreur ${res.statusCode}');
  }

  Future<Map<String, dynamic>> getStats() async {
    final token = await _token();
    final res = await http.get(
      Uri.parse('$baseUrl/admin/stats'),
      headers: _headers(token),
    );
    if (res.statusCode == 200) return json.decode(res.body)['stats'];
    throw Exception('Erreur ${res.statusCode}');
  }

  Future<List<dynamic>> getPendingDoctors() async {
    final token = await _token();
    final res = await http.get(
      Uri.parse('$baseUrl/admin/doctors/pending'),
      headers: _headers(token),
    );
    if (res.statusCode == 200) return json.decode(res.body)['doctors'] ?? [];
    throw Exception('Erreur ${res.statusCode}');
  }

  Future<void> validateDoctor(int userId) async {
    final token = await _token();
    final res = await http.post(
      Uri.parse('$baseUrl/admin/doctors/$userId/validate'),
      headers: _headers(token),
    );
    if (res.statusCode != 200) throw Exception('Erreur ${res.statusCode}');
  }

  Future<Map<String, dynamic>> getRecentActivity() async {
    final token = await _token();
    final res = await http.get(
      Uri.parse('$baseUrl/admin/activity'),
      headers: _headers(token),
    );
    if (res.statusCode == 200) return json.decode(res.body)['activity'];
    throw Exception('Erreur ${res.statusCode}');
  }

  // ==================== RENDEZ-VOUS ====================

  Future<Map<String, dynamic>> getAppointments({
    String? statut,
    String? periode,
    String? search,
    int page = 1,
  }) async {
    final token = await _token();

    final params = <String, String>{'page': page.toString()};
    if (statut != null && statut != 'all') params['statut'] = statut;
    if (periode != null) params['periode'] = periode;
    if (search != null && search.isNotEmpty) params['search'] = search;

    final uri = Uri.parse('$baseUrl/admin/appointments')
        .replace(queryParameters: params);

    final res = await http.get(uri, headers: _headers(token));

    if (res.statusCode == 200) return json.decode(res.body);
    throw Exception('Erreur ${res.statusCode}: ${res.body}');
  }

  Future<Map<String, dynamic>> getAppointmentsStats() async {
    final token = await _token();
    final res = await http.get(
      Uri.parse('$baseUrl/admin/appointments/stats'),
      headers: _headers(token),
    );
    if (res.statusCode == 200) return json.decode(res.body)['stats'];
    throw Exception('Erreur ${res.statusCode}');
  }

  Future<void> updateAppointmentStatus(int id, String statut) async {
    final token = await _token();
    final res = await http.patch(
      Uri.parse('$baseUrl/admin/appointments/$id/status'),
      headers: _headers(token),
      body: json.encode({'statut': statut}),
    );
    if (res.statusCode != 200) throw Exception('Erreur ${res.statusCode}');
  }

  Future<void> deleteAppointment(int id) async {
    final token = await _token();
    final res = await http.delete(
      Uri.parse('$baseUrl/admin/appointments/$id'),
      headers: _headers(token),
    );
    if (res.statusCode != 200) throw Exception('Erreur ${res.statusCode}');
  }

  // ==================== MÉDICAMENTS ====================

  Future<Map<String, dynamic>> getMedicaments({
    String? statut,
    String? stock,
    String? search,
    int page = 1,
  }) async {
    final token = await _token();

    final params = <String, String>{'page': page.toString()};
    if (statut != null && statut != 'all') params['statut'] = statut;
    if (stock != null) params['stock'] = stock;
    if (search != null && search.isNotEmpty) params['search'] = search;

    final uri = Uri.parse('$baseUrl/admin/medicaments')
        .replace(queryParameters: params);

    final res = await http.get(uri, headers: _headers(token));

    if (res.statusCode == 200) return json.decode(res.body);
    throw Exception('Erreur ${res.statusCode}: ${res.body}');
  }

  Future<Map<String, dynamic>> getMedicamentsStats() async {
    final token = await _token();
    final res = await http.get(
      Uri.parse('$baseUrl/admin/medicaments/stats'),
      headers: _headers(token),
    );
    if (res.statusCode == 200) return json.decode(res.body)['stats'];
    throw Exception('Erreur ${res.statusCode}');
  }

  Future<void> updateMedicamentStatus(int id, String statut) async {
    final token = await _token();
    final res = await http.patch(
      Uri.parse('$baseUrl/admin/medicaments/$id/status'),
      headers: _headers(token),
      body: json.encode({'statut': statut}),
    );
    if (res.statusCode != 200) throw Exception('Erreur ${res.statusCode}');
  }

  Future<void> deleteMedicament(int id) async {
    final token = await _token();
    final res = await http.delete(
      Uri.parse('$baseUrl/admin/medicaments/$id'),
      headers: _headers(token),
    );
    if (res.statusCode != 200) throw Exception('Erreur ${res.statusCode}');
  }

  // ==================== NOTIFICATIONS ====================

  Future<Map<String, dynamic>> getNotifications({
    String? statut,
    String? cible,
    String? search,
    int page = 1,
  }) async {
    final token = await _token();
    final params = <String, String>{'page': page.toString()};
    if (statut != null && statut != 'all') params['statut'] = statut;
    if (cible != null && cible != 'all') params['cible'] = cible;
    if (search != null && search.isNotEmpty) params['search'] = search;

    final uri = Uri.parse('$baseUrl/admin/notifications')
        .replace(queryParameters: params);

    final res = await http.get(uri, headers: _headers(token));
    if (res.statusCode == 200) return json.decode(res.body);
    throw Exception('Erreur ${res.statusCode}: ${res.body}');
  }

  Future<Map<String, dynamic>> getNotificationsStats() async {
    final token = await _token();
    final res = await http.get(
      Uri.parse('$baseUrl/admin/notifications/stats'),
      headers: _headers(token),
    );
    if (res.statusCode == 200) return json.decode(res.body)['stats'];
    throw Exception('Erreur ${res.statusCode}');
  }

  Future<Map<String, dynamic>> sendNotification({
    required String titre,
    required String message,
    required String cible,
    String? cibleValeur,
    String? deepLink,
  }) async {
    final token = await _token();
    final body = {
      'titre': titre,
      'message': message,
      'cible': cible,
      if (cibleValeur != null) 'cible_valeur': cibleValeur,
      if (deepLink != null && deepLink.isNotEmpty) 'deep_link': deepLink,
    };

    final res = await http.post(
      Uri.parse('$baseUrl/admin/notifications'),
      headers: _headers(token),
      body: json.encode(body),
    );

    if (res.statusCode == 200 || res.statusCode == 201) {
      return json.decode(res.body);
    }
    final errorBody = json.decode(res.body);
    throw Exception(errorBody['message'] ?? 'Erreur ${res.statusCode}');
  }

  Future<void> deleteNotification(int id) async {
    final token = await _token();
    final res = await http.delete(
      Uri.parse('$baseUrl/admin/notifications/$id'),
      headers: _headers(token),
    );
    if (res.statusCode != 200) throw Exception('Erreur ${res.statusCode}');
  }

  /// Récupérer la liste des utilisateurs (pour le sélecteur)
  Future<List<dynamic>> getUsersForSelector() async {
    final token = await _token();
    final res = await http.get(
      Uri.parse('$baseUrl/admin/users'),
      headers: _headers(token),
    );
    if (res.statusCode == 200) return json.decode(res.body)['users'] ?? [];
    throw Exception('Erreur ${res.statusCode}');
  }
}