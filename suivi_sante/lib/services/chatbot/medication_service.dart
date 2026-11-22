// lib/services/medication_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class MedicationService {
  final String baseUrl = 'http://192.168.100.85:8000/api';
  String? _authToken;

  MedicationService() {
    _loadToken();
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString('auth_token');
  }

  Map<String, String> _getHeaders() {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (_authToken != null) 'Authorization': 'Bearer $_authToken',
    };
  }

  /// Ajouter un médicament avec reconnaissance vocale
  Future<Map<String, dynamic>> addMedication({
    String? text,
    String? nom,
    String? dosage,
    int? stockActuel,
    List<String>? horairesPrises,
    String? dateDebut,
    String? dateFin,
    String? instructions,
  }) async {
    try {
      final body = {
        if (text != null) 'text': text,
        if (nom != null) 'nom': nom,
        if (dosage != null) 'dosage': dosage,
        if (stockActuel != null) 'stock_actuel': stockActuel,
        if (horairesPrises != null) 'horaires_prises': horairesPrises,
        if (dateDebut != null) 'date_debut': dateDebut,
        if (dateFin != null) 'date_fin': dateFin,
        if (instructions != null) 'instructions': instructions,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/medications'),
        headers: _getHeaders(),
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'],
          'data': data['data'],
          'has_interactions': data['data']['has_interactions'] ?? false,
          'interactions': data['data']['interactions'] ?? [],
        };
      } else {
        return {
          'success': false,
          'error': 'Erreur lors de l\'ajout du médicament',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Vérifier les interactions
  Future<Map<String, dynamic>> checkInteractions(String nom) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/medications/check-interactions'),
        headers: _getHeaders(),
        body: jsonEncode({'nom': nom}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'has_interactions': data['data']['has_interactions'],
          'interactions': data['data']['interactions'],
        };
      }
      return {'success': false, 'has_interactions': false};
    } catch (e) {
      return {'success': false, 'has_interactions': false};
    }
  }

  /// Vérifier les alertes de stock
  Future<Map<String, dynamic>> checkStockAlerts() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/medications/stock-alerts'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'has_alerts': data['data']['has_alerts'],
          'alerts': data['data']['alerts'],
        };
      }
      return {'success': false, 'has_alerts': false};
    } catch (e) {
      return {'success': false, 'has_alerts': false};
    }
  }

  /// Enregistrer une prise
  Future<Map<String, dynamic>> recordTaking({
    required int takingId,
    required bool taken,
    String source = 'manual',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/medications/record-taking'),
        headers: _getHeaders(),
        body: jsonEncode({
          'taking_id': takingId,
          'taken': taken,
          'source': source,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'],
          'data': data['data'],
        };
      }
      return {'success': false};
    } catch (e) {
      return {'success': false};
    }
  }

  /// Marquer une prise comme prise (raccourci vocal)
  Future<Map<String, dynamic>> markTakingAsTaken(int medicamentId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/medications/mark-taken'),
        headers: _getHeaders(),
        body: jsonEncode({
          'medicament_id': medicamentId,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'],
          'data': data['data'],
        };
      }
      return {'success': false};
    } catch (e) {
      return {'success': false};
    }
  }

  /// Obtenir le résumé d'observance
  Future<Map<String, dynamic>> getObservanceSummary({String period = 'week'}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/medications/observance-summary?period=$period'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data['data'],
        };
      }
      return {'success': false};
    } catch (e) {
      return {'success': false};
    }
  }

  /// Générer un message de renouvellement
  Future<Map<String, dynamic>> generateRenewalMessage(int medicamentId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/medications/renewal-message'),
        headers: _getHeaders(),
        body: jsonEncode({
          'medicament_id': medicamentId,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['data']['message'],
        };
      }
      return {'success': false};
    } catch (e) {
      return {'success': false};
    }
  }

  /// Obtenir les prises du jour
  Future<List<dynamic>> getTodayTakings() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/medications/today-takings'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Obtenir la liste des médicaments
  Future<List<dynamic>> getMedications() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/medications'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'];
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}