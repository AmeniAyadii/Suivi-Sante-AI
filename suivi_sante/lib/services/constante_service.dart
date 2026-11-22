
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/constante_vitale.dart';
import '../models/alerte_sante.dart';
import '../utils/constants.dart';

class ConstanteService {
  final String baseUrl = ApiConstants.baseUrl;

  // Construction centralisée des URL
  // baseUrl doit contenir /api à la fin ou non.
  Uri _buildUri(String endpoint, {Map<String, String>? queryParams}) {
    String base = baseUrl.replaceAll(RegExp(r'/+$'), '');

    // Évite d'ajouter /api deux fois.
    if (!base.endsWith('/api')) {
      base = '$base/api';
    }

    final path = endpoint.replaceAll(RegExp(r'^/+'), '');
    final uri = Uri.parse('$base/$path');

    return uri.replace(
      queryParameters: queryParams == null || queryParams.isEmpty
          ? null
          : queryParams,
    );
  }

  // ============ GESTION DES CONSTANTES ============

  Future<Map<String, dynamic>> getConstantes({
    String? periode,
    String? dateDebut,
    String? dateFin,
    List<String>? types,
  }) async {
    try {
      final token = await _getToken();
      final queryParams = <String, String>{};

      if (periode != null) queryParams['periode'] = periode;
      if (dateDebut != null) queryParams['date_debut'] = dateDebut;
      if (dateFin != null) queryParams['date_fin'] = dateFin;
      if (types != null && types.isNotEmpty) {
        queryParams['types'] = types.join(',');
      }

      final uri = _buildUri(
        'constantes',
        queryParams: queryParams,
      );

      debugPrint('📤 GET Constantes: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': ApiConstants.accept,
        },
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Timeout - Le serveur ne répond pas');
        },
      );

      debugPrint('📥 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('✅ Constantes chargées avec succès');
        return data;
      } else if (response.statusCode == 401) {
        throw Exception('Session expirée - Veuillez vous reconnecter');
      } else if (response.statusCode == 404) {
        return {
          'data': {
            'constantes': [],
            'statistiques': {},
            'chart_data': {}
          }
        };
      } else {
        throw Exception('Erreur ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Erreur getConstantes: $e');
      rethrow;
    }
  }

  Future<ConstanteVitale> addConstante({
    required String typeConstante,
    required double valeur,
    required String unite,
    required DateTime dateMesure,
    String? notes,
  }) async {
    try {
      final token = await _getToken();

      final body = {
        'type_constante': typeConstante,
        'valeur': valeur,
        'unite': unite,
        'date_mesure': dateMesure.toIso8601String(),
        'notes': notes,
      };

      debugPrint('📤 POST Constante: $body');

      final response = await http.post(
        _buildUri('constantes'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': ApiConstants.contentType,
          'Accept': ApiConstants.accept,
        },
        body: json.encode(body),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Timeout - Le serveur ne répond pas');
        },
      );

      debugPrint('📥 Response status: ${response.statusCode}');

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return ConstanteVitale.fromJson(data['data']);
      } else {
        throw Exception('Erreur ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Erreur addConstante: $e');
      rethrow;
    }
  }

  // ============ GESTION DES ALERTES ============

  Future<List<AlerteSante>> getAlertes({bool? nonLues}) async {
    try {
      final token = await _getToken();
      final queryParams = <String, String>{};

      if (nonLues != null) {
        queryParams['non_lues'] = nonLues.toString();
      }

      final uri = _buildUri(
        'alertes',
        queryParams: queryParams,
      );

      debugPrint('📤 GET Alertes: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': ApiConstants.accept,
        },
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Timeout - Le serveur ne répond pas');
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> alertesJson = data['data'] ?? [];
        return alertesJson
            .map((json) => AlerteSante.fromJson(json))
            .toList();
      } else if (response.statusCode == 404) {
        return [];
      } else {
        throw Exception('Erreur ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('⚠️ Erreur getAlertes: $e');
      return [];
    }
  }

  Future<void> marquerAlerteLue(int id) async {
    try {
      final token = await _getToken();

      final response = await http.put(
        _buildUri('alertes/$id/lire'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': ApiConstants.accept,
        },
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Timeout - Le serveur ne répond pas');
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Erreur ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Erreur marquerAlerteLue: $e');
      rethrow;
    }
  }

  Future<void> marquerAlerteResolue(int id) async {
    try {
      final token = await _getToken();

      final response = await http.put(
        _buildUri('alertes/$id/resoudre'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': ApiConstants.accept,
        },
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Timeout - Le serveur ne répond pas');
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Erreur ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Erreur marquerAlerteResolue: $e');
      rethrow;
    }
  }

  // ============ SEUILS ============

  Future<Map<String, dynamic>> getSeuils() async {
    try {
      final token = await _getToken();

      final response = await http.get(
        _buildUri('seuils'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': ApiConstants.accept,
        },
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Timeout - Le serveur ne répond pas');
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {'data': {}};
      }
    } catch (e) {
      debugPrint('⚠️ Erreur getSeuils: $e');
      return {'data': {}};
    }
  }

  Future<void> updateSeuils({
    required String typeConstante,
    double? minNormal,
    double? maxNormal,
    double? minAlerte,
    double? maxAlerte,
  }) async {
    try {
      final token = await _getToken();

      final body = {
        'type_constante': typeConstante,
        'min_normal': minNormal,
        'max_normal': maxNormal,
        'min_alerte': minAlerte,
        'max_alerte': maxAlerte,
      };

      final response = await http.post(
        _buildUri('seuils'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': ApiConstants.contentType,
          'Accept': ApiConstants.accept,
        },
        body: json.encode(body),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Timeout - Le serveur ne répond pas');
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Erreur ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Erreur updateSeuils: $e');
      rethrow;
    }
  }

  // ============ CORRÉLATION ============

  Future<Map<String, dynamic>> getCorrelationSymptomes({
    int jours = 7,
  }) async {
    try {
      final token = await _getToken();

      final response = await http.get(
        _buildUri(
          'correlation-symptomes',
          queryParams: {'jours': jours.toString()},
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': ApiConstants.accept,
        },
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Timeout - Le serveur ne répond pas');
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {'data': {}};
      }
    } catch (e) {
      debugPrint('⚠️ Erreur getCorrelationSymptomes: $e');
      return {'data': {}};
    }
  }

  // ============ EXPORT CSV ============

  Future<String> exportCSV(List<String> types) async {
    try {
      final token = await _getToken();
      final queryParams = {'types': types.join(',')};

      final uri = _buildUri(
        'export-constantes',
        queryParams: queryParams,
      );

      debugPrint('📤 GET Export CSV: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'text/csv, application/json',
        },
      ).timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          throw Exception('Timeout - Le serveur ne répond pas');
        },
      );

      debugPrint('📥 Response status: ${response.statusCode}');
      debugPrint('📥 Response headers: ${response.headers}');

      if (response.statusCode == 200) {
        return response.body;
      } else if (response.statusCode == 404) {
        throw Exception('Aucune donnée à exporter');
      } else {
        throw Exception('Erreur ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Erreur exportCSV: $e');
      rethrow;
    }
  }

  // ============ MÉTHODES PRIVÉES ============

  Future<String> _getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null || token.isEmpty) {
        throw Exception('Token d\'authentification manquant');
      }

      return token;
    } catch (e) {
      debugPrint('❌ Erreur _getToken: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getHistorique({
    String? type,
    String? dateDebut,
    String? dateFin,
    int page = 1,
  }) async {
    try {
      final token = await _getToken();

      final queryParams = <String, String>{
        'page': page.toString(),
        'per_page': '15',
        if (type != null) 'type': type,
        if (dateDebut != null) 'date_debut': dateDebut,
        if (dateFin != null) 'date_fin': dateFin,
      };

      final uri = _buildUri(
        'constantes/historique',
        queryParams: queryParams,
      );

      debugPrint('📤 GET Historique: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': ApiConstants.accept,
          'ngrok-skip-browser-warning': ApiConstants.ngrokSkip,
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Erreur ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Erreur getHistorique: $e');
      rethrow;
    }
  }
}
