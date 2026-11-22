// lib/services/tension_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/tension_measure.dart';
import '../models/tension_analysis.dart';
import 'auth_service.dart';
import 'dart:developer' as developer;

/// 📊 Service de gestion des mesures de tension artérielle
/// 
/// Gère toutes les communications avec l'API Laravel pour :
/// - CRUD des mesures
/// - Statistiques
/// - Analyses IA
/// - Prédictions
/// - Export de données
class TensionService {
  // ============================================
  // CONSTANTES
  // ============================================
  static const int DEFAULT_TIMEOUT = 30;
  static const int DEFAULT_LIMIT = 30;

  // ============================================
  // RÉFÉRENCES
  // ============================================
  final AuthService _authService = AuthService();

  // ============================================
  // MÉTHODES DE LOG
  // ============================================
  void _log(String message, {String level = 'INFO'}) {
    final timestamp = DateTime.now().toIso8601String();
    developer.log('[$timestamp] [$level] TensionService: $message');
  }

  void _logError(String message, dynamic error) {
    _log('❌ $message: $error', level: 'ERROR');
    if (error is Error) {
      developer.log('StackTrace: ${error.stackTrace}');
    }
  }

  // ============================================
  // GESTION DU TOKEN
  // ============================================
  
  /// 🔐 Récupérer le token d'authentification
  Future<String?> _getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('token');
    } catch (e) {
      _logError('Erreur lors de la récupération du token', e);
      return null;
    }
  }

  /// 📋 Préparer les headers HTTP
  Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  // ============================================
  // 🔥 UTILITAIRE : CONSTRUCTION D'URL
  // ============================================
  
  /// 🔗 Construire une URL sans doubles slashes
  String _buildUrl(String baseUrl, String endpoint) {
    // Supprimer le slash final de baseUrl si présent
    String cleanBase = baseUrl;
    if (cleanBase.endsWith('/')) {
      cleanBase = cleanBase.substring(0, cleanBase.length - 1);
    }
    
    // Supprimer le slash initial de endpoint si présent
    String cleanEndpoint = endpoint;
    if (cleanEndpoint.startsWith('/')) {
      cleanEndpoint = cleanEndpoint.substring(1);
    }
    
    return '$cleanBase/$cleanEndpoint';
  }

  // ============================================
  // MÉTHODES HTTP PRIVÉES
  // ============================================

  /// 📤 Requête GET
  Future<Map<String, dynamic>> _get(
    String endpoint, {
    Map<String, String>? queryParams,
  }) async {
    try {
      final baseUrl = AuthService.baseUrl;
      final url = _buildUrl(baseUrl, endpoint);
      var uri = Uri.parse(url);
      
      if (queryParams != null && queryParams.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParams);
      }

      final headers = await _getHeaders();
      _log('📤 GET Request: $uri');

      final response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: DEFAULT_TIMEOUT));

      _log('📥 Status Code: ${response.statusCode}');
      final bodyPreview = response.body.length > 200 
          ? '${response.body.substring(0, 200)}...' 
          : response.body;
      _log('📥 Body: $bodyPreview');

      return _handleResponse(response);
    } catch (e) {
      _logError('Erreur GET $endpoint', e);
      rethrow;
    }
  }

  /// 📤 Requête POST
  Future<Map<String, dynamic>> _post(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    try {
      final baseUrl = AuthService.baseUrl;
      final url = _buildUrl(baseUrl, endpoint);
      final uri = Uri.parse(url);
      final headers = await _getHeaders();

      _log('📤 POST Request: $uri');
      _log('📤 Data: ${_sanitizeData(data)}');

      final response = await http
          .post(
            uri,
            headers: headers,
            body: json.encode(data),
          )
          .timeout(const Duration(seconds: DEFAULT_TIMEOUT));

      _log('📥 Status Code: ${response.statusCode}');
      final bodyPreview = response.body.length > 200 
          ? '${response.body.substring(0, 200)}...' 
          : response.body;
      _log('📥 Body: $bodyPreview');

      return _handleResponse(response);
    } catch (e) {
      _logError('Erreur POST $endpoint', e);
      rethrow;
    }
  }

  /// 📤 Requête PUT
  Future<Map<String, dynamic>> _put(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    try {
      final baseUrl = AuthService.baseUrl;
      final url = _buildUrl(baseUrl, endpoint);
      final uri = Uri.parse(url);
      final headers = await _getHeaders();

      _log('📤 PUT Request: $uri');
      _log('📤 Data: ${_sanitizeData(data)}');

      final response = await http
          .put(
            uri,
            headers: headers,
            body: json.encode(data),
          )
          .timeout(const Duration(seconds: DEFAULT_TIMEOUT));

      _log('📥 Status Code: ${response.statusCode}');
      final bodyPreview = response.body.length > 200 
          ? '${response.body.substring(0, 200)}...' 
          : response.body;
      _log('📥 Body: $bodyPreview');

      return _handleResponse(response);
    } catch (e) {
      _logError('Erreur PUT $endpoint', e);
      rethrow;
    }
  }

  /// 📤 Requête DELETE
  Future<Map<String, dynamic>> _delete(String endpoint) async {
    try {
      final baseUrl = AuthService.baseUrl;
      final url = _buildUrl(baseUrl, endpoint);
      final uri = Uri.parse(url);
      final headers = await _getHeaders();

      _log('📤 DELETE Request: $uri');

      final response = await http
          .delete(uri, headers: headers)
          .timeout(const Duration(seconds: DEFAULT_TIMEOUT));

      _log('📥 Status Code: ${response.statusCode}');
      final bodyPreview = response.body.length > 200 
          ? '${response.body.substring(0, 200)}...' 
          : response.body;
      _log('📥 Body: $bodyPreview');

      return _handleResponse(response);
    } catch (e) {
      _logError('Erreur DELETE $endpoint', e);
      rethrow;
    }
  }

  // ============================================
  // GESTION DES RÉPONSES
  // ============================================

  /// 📋 Traiter la réponse HTTP
  Map<String, dynamic> _handleResponse(http.Response response) {
    try {
      final Map<String, dynamic> data = json.decode(response.body);

      // Succès
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return data;
      }

      // Erreur d'authentification
      if (response.statusCode == 401) {
        throw TensionException(
          'Session expirée. Veuillez vous reconnecter.',
          code: 'UNAUTHORIZED',
          statusCode: 401,
        );
      }

      // Accès refusé / Premium requis
      if (response.statusCode == 403) {
        throw TensionException(
          data['message'] ?? '🔒 Fonctionnalité Premium requise',
          code: 'PREMIUM_REQUIRED',
          statusCode: 403,
        );
      }

      // Erreur de validation
      if (response.statusCode == 422) {
        final errors = data['errors'] ?? data['data'] ?? {};
        throw TensionException(
          _formatValidationErrors(errors),
          code: 'VALIDATION_ERROR',
          statusCode: 422,
          errors: errors,
        );
      }

      // Erreur serveur
      if (response.statusCode >= 500) {
        throw TensionException(
          'Erreur serveur. Veuillez réessayer plus tard.',
          code: 'SERVER_ERROR',
          statusCode: response.statusCode,
        );
      }

      // Autres erreurs
      throw TensionException(
        data['message'] ?? data['error'] ?? 'Erreur inconnue',
        code: 'UNKNOWN_ERROR',
        statusCode: response.statusCode,
      );
    } on FormatException catch (e) {
      _logError('Erreur de format JSON', e);
      throw TensionException(
        'Erreur de format de réponse',
        code: 'PARSE_ERROR',
        statusCode: response.statusCode,
      );
    } on TensionException {
      rethrow;
    } catch (e) {
      _logError('Erreur inattendue', e);
      throw TensionException(
        'Une erreur inattendue est survenue',
        code: 'UNKNOWN_ERROR',
      );
    }
  }

  /// 📝 Formater les erreurs de validation
  String _formatValidationErrors(Map<String, dynamic> errors) {
    if (errors.isEmpty) return 'Erreur de validation';

    final messages = <String>[];
    errors.forEach((field, errorList) {
      if (errorList is List) {
        messages.add('$field: ${errorList.join(', ')}');
      } else if (errorList is String) {
        messages.add('$field: $errorList');
      }
    });

    return messages.join('\n');
  }

  /// 🔒 Nettoyer les données sensibles des logs
  Map<String, dynamic> _sanitizeData(Map<String, dynamic> data) {
    return data;
  }

  // ============================================
  // MÉTHODES PUBLIQUES - CRUD
  // ============================================

  /// 📊 Ajouter une mesure de tension
  // lib/services/tension_service.dart

/// 📊 Ajouter une mesure de tension
// lib/services/tension_service.dart

/// 📊 Ajouter une mesure de tension
Future<TensionMeasure> addMeasure(TensionMeasure measure) async {
  try {
    _log('📊 Ajout d\'une mesure: ${measure.systolic}/${measure.diastolic}');

    final data = {
      'systolic': measure.systolic,
      'diastolic': measure.diastolic,
      'heart_rate': measure.heartRate,
      'measure_date': measure.measureDate.toIso8601String(),
      'notes': measure.notes ?? '',
      'position': measure.position ?? 'assis',
      'arm': measure.arm ?? 'gauche',
      'is_premium': measure.isPremium ?? false,
    };

    _log('📤 Data envoyée: $data');

    final response = await _post('/tension/measures', data);
    
    _log('📥 Réponse reçue: $response');

    // 🔥 Vérifier différents formats de réponse
    Map<String, dynamic> measureData;
    
    if (response['data'] != null && response['data'] is Map) {
      measureData = response['data'];
    } else if (response['measure'] != null && response['measure'] is Map) {
      measureData = response['measure'];
    } else if (response['id'] != null) {
      // Si la réponse est directement la mesure
      measureData = response;
    } else {
      _log('❌ Format de réponse inattendu: $response');
      throw TensionException(
        response['message'] ?? 'Format de réponse inattendu',
        code: 'INVALID_RESPONSE',
      );
    }

    _log('✅ Mesure ajoutée avec succès ID: ${measureData['id']}');
    return TensionMeasure.fromJson(measureData);
    
  } catch (e) {
    _logError('Erreur addMeasure', e);
    rethrow;
  }
}

  /// 📋 Récupérer l'historique des mesures
  Future<List<TensionMeasure>> getHistory({
    int limit = DEFAULT_LIMIT,
    int page = 1,
    String? period,
    String? category,
  }) async {
    try {
      _log('📋 Récupération de l\'historique (page $page, limit $limit)');

      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
        if (period != null) 'period': period,
        if (category != null) 'category': category,
      };

      final response = await _get('/tension/measures', queryParams: queryParams);

      if (response['success'] == true && response['data'] != null) {
        final List<dynamic> measures = response['data'];
        _log('✅ ${measures.length} mesures récupérées');
        return measures.map((item) => TensionMeasure.fromJson(item)).toList();
      }

      return [];
    } catch (e) {
      _logError('Erreur getHistory', e);
      return [];
    }
  }

  /// 📊 Récupérer la dernière mesure
  Future<TensionMeasure?> getLastMeasure() async {
    try {
      _log('📊 Récupération de la dernière mesure');

      final response = await _get('/tension/measures/last');

      if (response['success'] == true && response['data'] != null) {
        return TensionMeasure.fromJson(response['data']);
      }
      return null;
    } catch (e) {
      _logError('Erreur getLastMeasure', e);
      return null;
    }
  }

  /// 📊 Récupérer une mesure par ID
  Future<TensionMeasure?> getMeasureById(int id) async {
    try {
      _log('📊 Récupération de la mesure ID: $id');

      final response = await _get('/tension/measures/$id');

      if (response['success'] == true && response['data'] != null) {
        return TensionMeasure.fromJson(response['data']);
      }
      return null;
    } catch (e) {
      _logError('Erreur getMeasureById', e);
      return null;
    }
  }

  /// 📝 Mettre à jour une mesure
  Future<TensionMeasure> updateMeasure(int id, TensionMeasure measure) async {
    try {
      _log('📝 Mise à jour de la mesure ID: $id');

      final data = measure.toJson();
      data['position'] = measure.position ?? 'assis';
      data['arm'] = measure.arm ?? 'gauche';

      final response = await _put('/tension/measures/$id', data);

      if (response['success'] == true && response['data'] != null) {
        _log('✅ Mesure mise à jour avec succès');
        return TensionMeasure.fromJson(response['data']);
      } else {
        throw TensionException(
          response['message'] ?? 'Erreur lors de la mise à jour',
          code: 'UPDATE_FAILED',
        );
      }
    } catch (e) {
      _logError('Erreur updateMeasure', e);
      rethrow;
    }
  }

  /// 🗑️ Supprimer une mesure
  Future<bool> deleteMeasure(int id) async {
    try {
      _log('🗑️ Suppression de la mesure ID: $id');

      final response = await _delete('/tension/measures/$id');

      if (response['success'] == true) {
        _log('✅ Mesure supprimée avec succès');
        return true;
      }
      return false;
    } catch (e) {
      _logError('Erreur deleteMeasure', e);
      return false;
    }
  }

  // ============================================
  // MÉTHODES PUBLIQUES - STATISTIQUES
  // ============================================

  /// 📈 Récupérer les statistiques des mesures
  Future<Map<String, dynamic>> getStatistics() async {
    try {
      _log('📈 Récupération des statistiques');

      final response = await _get('/tension/statistics');

      if (response['success'] == true && response['data'] != null) {
        return response['data'];
      }

      return _defaultStatistics();
    } catch (e) {
      _logError('Erreur getStatistics', e);
      return _defaultStatistics();
    }
  }

  /// 📊 Statistiques par défaut
  Map<String, dynamic> _defaultStatistics() {
    return {
      'total': 0,
      'average_systolic': 0,
      'average_diastolic': 0,
      'average_heart_rate': 0,
      'min_systolic': 0,
      'max_systolic': 0,
      'min_diastolic': 0,
      'max_diastolic': 0,
      'normal_count': 0,
      'warning_count': 0,
      'danger_count': 0,
      'last_measure': null,
    };
  }

  /// 📊 Récupérer les mesures par période
  Future<List<TensionMeasure>> getMeasuresByPeriod(String period) async {
    try {
      _log('📊 Récupération des mesures pour la période: $period');

      final response = await _get('/tension/measures/period/$period');

      if (response['success'] == true && response['data'] != null) {
        final List<dynamic> measures = response['data'];
        return measures.map((item) => TensionMeasure.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      _logError('Erreur getMeasuresByPeriod', e);
      return [];
    }
  }

  // ============================================
  // MÉTHODES PUBLIQUES - ANALYSE & IA
  // ============================================

  /// 🤖 Analyse des tendances (Premium)
  Future<TensionAnalysis> analyzeTrends(List<TensionMeasure> measures) async {
    try {
      if (measures.length < 3) {
        throw TensionException(
          'Minimum 3 mesures nécessaires pour l\'analyse',
          code: 'INSUFFICIENT_DATA',
        );
      }

      _log('🤖 Analyse des tendances (${measures.length} mesures)');

      final data = measures.map((m) => {
            'date': m.measureDate.toIso8601String(),
            'systolic': m.systolic,
            'diastolic': m.diastolic,
            'heart_rate': m.heartRate,
          }).toList();

      final response = await _post('/tension/analyze/trends', {
        'measures': data,
      });

      if (response['success'] == true && response['data'] != null) {
        _log('✅ Analyse terminée avec succès');
        return TensionAnalysis.fromJson(response['data']);
      } else {
        throw TensionException(
          response['message'] ?? 'Erreur lors de l\'analyse',
          code: 'ANALYSIS_FAILED',
        );
      }
    } catch (e) {
      _logError('Erreur analyzeTrends', e);
      rethrow;
    }
  }

  /// 🔮 Prédictions (Premium)
  Future<Map<String, dynamic>> predict(
    List<TensionMeasure> measures,
    int daysAhead,
  ) async {
    try {
      if (measures.length < 3) {
        throw TensionException(
          'Minimum 3 mesures nécessaires pour les prédictions',
          code: 'INSUFFICIENT_DATA',
        );
      }

      if (daysAhead < 1 || daysAhead > 30) {
        throw TensionException(
          'Le nombre de jours doit être entre 1 et 30',
          code: 'INVALID_DAYS',
        );
      }

      _log('🔮 Prédictions sur $daysAhead jours (${measures.length} mesures)');

      final data = measures.map((m) => ({
            'date': m.measureDate.toIso8601String(),
            'systolic': m.systolic,
            'diastolic': m.diastolic,
            'heart_rate': m.heartRate,
          })).toList();

      final response = await _post('/tension/predict', {
        'measures': data,
        'days_ahead': daysAhead,
      });

      if (response['success'] == true && response['data'] != null) {
        _log('✅ Prédictions générées avec succès');
        return response['data'];
      } else {
        throw TensionException(
          response['message'] ?? 'Erreur lors de la prédiction',
          code: 'PREDICTION_FAILED',
        );
      }
    } catch (e) {
      _logError('Erreur predict', e);
      rethrow;
    }
  }

  // ============================================
  // MÉTHODES PUBLIQUES - EXPORT
  // ============================================

  /// 📤 Exporter les mesures
  Future<String> exportMeasures(String format, {String? period}) async {
    try {
      _log('📤 Export des mesures en format: $format');

      final queryParams = <String, String>{
        'format': format,
        if (period != null) 'period': period,
      };

      final response = await _get('/tension/export', queryParams: queryParams);

      if (response['success'] == true && response['data'] != null) {
        final url = response['data']['url'] ?? '';
        _log('✅ Export disponible: $url');
        return url;
      }
      return '';
    } catch (e) {
      _logError('Erreur exportMeasures', e);
      return '';
    }
  }

  // ============================================
  // MÉTHODES PUBLIQUES - ALERTES
  // ============================================

  /// 🔔 Récupérer les alertes
  Future<Map<String, dynamic>> getAlerts() async {
    try {
      _log('🔔 Récupération des alertes');

      final response = await _get('/tension/alerts');

      if (response['success'] == true && response['data'] != null) {
        return response['data'];
      }
      return {'alerts': [], 'unread_count': 0};
    } catch (e) {
      _logError('Erreur getAlerts', e);
      return {'alerts': [], 'unread_count': 0};
    }
  }

  /// ✅ Marquer une alerte comme lue
  Future<bool> markAlertAsRead(int alertId) async {
    try {
      _log('✅ Marquage de l\'alerte $alertId comme lue');

      final response = await _put('/tension/alerts/$alertId/read', {});

      if (response['success'] == true) {
        return true;
      }
      return false;
    } catch (e) {
      _logError('Erreur markAlertAsRead', e);
      return false;
    }
  }

  // ============================================
  // MÉTHODES PUBLIQUES - UTILITAIRES
  // ============================================

  /// ✅ Vérifier si l'API est accessible
  Future<bool> checkHealth() async {
    try {
      _log('🏥 Vérification de la santé de l\'API');

      final baseUrl = AuthService.baseUrl;
      final url = _buildUrl(baseUrl, '/health');
      final uri = Uri.parse(url);
      
      final response = await http
          .get(uri)
          .timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      _logError('Erreur checkHealth', e);
      return false;
    }
  }
}

// ============================================
// EXCEPTION PERSONNALISÉE
// ============================================

/// 🚨 Exception spécifique au service de tension
class TensionException implements Exception {
  final String message;
  final String code;
  final int? statusCode;
  final Map<String, dynamic>? errors;

  TensionException(
    this.message, {
    this.code = 'UNKNOWN',
    this.statusCode,
    this.errors,
  });

  @override
  String toString() => 'TensionException: $message (code: $code)';
}