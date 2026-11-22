// lib/services/rendezvous_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../models/rendez_vous.dart';

class RendezVousService {
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // ✅ En-têtes communs incluant le contournement de ngrok
  Map<String, String> _headers(String? token) => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'ngrok-skip-browser-warning': 'true', // ← INDISPENSABLE
        if (token != null) 'Authorization': 'Bearer $token',
      };

  // Récupérer tous les rendez-vous
  Future<List<RendezVous>> getRendezVous({String? statut}) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Non authentifié');

      // ✅ On ajoute un slash entre baseUrl et l'endpoint
      String url = '${AppConfig.baseUrl}/rendezvous';
      if (statut != null) {
        url += '?statut=$statut';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: _headers(token),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return (data['data'] as List)
              .map((item) => RendezVous.fromJson(item))
              .toList();
        }
      }
      return [];
    } catch (e) {
      print('❌ Erreur getRendezVous: $e');
      return [];
    }
  }

  // Récupérer les rendez-vous du jour
  Future<List<RendezVous>> getTodayRendezVous() async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Non authentifié');

      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/rendezvous/today'),
        headers: _headers(token),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return (data['data'] as List)
              .map((item) => RendezVous.fromJson(item))
              .toList();
        }
      }
      return [];
    } catch (e) {
      print('❌ Erreur getTodayRendezVous: $e');
      return [];
    }
  }

  // Créer un rendez-vous
  Future<RendezVous?> createRendezVous(RendezVous rendezvous) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Non authentifié');

      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/rendezvous'),
        headers: _headers(token),
        body: json.encode(rendezvous.toJson()),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return RendezVous.fromJson(data['data']);
        }
      }
      return null;
    } catch (e) {
      print('❌ Erreur createRendezVous: $e');
      return null;
    }
  }

  // Mettre à jour un rendez-vous
  Future<RendezVous?> updateRendezVous(int id, RendezVous rendezvous) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Non authentifié');

      final response = await http.put(
        Uri.parse('${AppConfig.baseUrl}/rendezvous/$id'),
        headers: _headers(token),
        body: json.encode(rendezvous.toJson()),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return RendezVous.fromJson(data['data']);
        }
      }
      return null;
    } catch (e) {
      print('❌ Erreur updateRendezVous: $e');
      return null;
    }
  }

  // Supprimer un rendez-vous
  Future<bool> deleteRendezVous(int id) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Non authentifié');

      final response = await http.delete(
        Uri.parse('${AppConfig.baseUrl}/rendezvous/$id'),
        headers: _headers(token),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      print('❌ Erreur deleteRendezVous: $e');
      return false;
    }
  }
}