// lib/services/symptome_service.dart
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:suivi_sante_pro/config/app_config.dart';
import '../models/symptome.dart';

// ============================================================================
// LOGGER INTÉGRÉ
// ============================================================================
class SymptomeServiceLogger {
  static const String _tag = '🩺 SymptomeService';
  
  static void info(String message) {
    final log = '$_tag - ℹ️ $message';
    print(log);
    developer.log(log, name: 'INFO', time: DateTime.now());
  }
  
  static void debug(String message) {
    final log = '$_tag - 🐛 $message';
    print(log);
    developer.log(log, name: 'DEBUG', time: DateTime.now());
  }
  
  static void error(String message, {dynamic error, StackTrace? stackTrace}) {
    final log = '$_tag - ❌ $message';
    print(log);
    if (error != null) print('Erreur: $error');
    if (stackTrace != null) print(stackTrace);
    developer.log(log, name: 'ERROR', time: DateTime.now(), error: error, stackTrace: stackTrace);
  }
  
  static void success(String message) {
    final log = '$_tag - ✅ $message';
    print(log);
    developer.log(log, name: 'SUCCESS', time: DateTime.now());
  }
  
  static void warning(String message) {
    final log = '$_tag - ⚠️ $message';
    print(log);
    developer.log(log, name: 'WARNING', time: DateTime.now());
  }
  
  static void performance(String operation, Duration duration) {
    final log = '$_tag - ⏱️ $operation: ${duration.inMilliseconds}ms';
    print(log);
    developer.log(log, name: 'PERFORMANCE', time: DateTime.now());
  }
  
  static void api(String method, String endpoint, {Map<String, dynamic>? request, Map<String, dynamic>? response, int? statusCode}) {
    final log = '''
$_tag - 🌐 $method $endpoint
  Status: $statusCode
  Request: ${request != null ? _formatJson(request) : 'N/A'}
  Response: ${response != null ? _formatJson(response) : 'N/A'}''';
    print(log);
    developer.log(log, name: 'API', time: DateTime.now());
  }
  
  static String _formatJson(Map<String, dynamic> data) {
    try {
      return const JsonEncoder.withIndent('  ').convert(data);
    } catch (_) {
      return data.toString();
    }
  }
}

// ============================================================================
// SERVICE PRINCIPAL
// ============================================================================
class SymptomeService {
  // ✅ Configuration de l'URL (à modifier selon votre environnement)
  //static const String baseUrl = 'http://192.168.1.215:8000/api/';
  
  //static const String baseUrl = 'http://192.168.100.85:8000/api/';
  //static const String baseUrl = 'http://10.0.2.2:8000/api/'; // Pour émulateur
  // ✅ Utilise AppConfig pour lire l'URL ngrok
//static String get baseUrl => '${AppConfig.baseUrl}/medicaments/';
// ✅ APRÈS
static String get baseUrl => '${AppConfig.baseUrl}';

  // ==========================================================================
  // TOKEN
  // ==========================================================================
  Future<String?> _getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (token != null) {
        final display = token.length > 10 ? '${token.substring(0, 10)}...' : token;
        SymptomeServiceLogger.debug('🔑 Token récupéré: $display');
      } else {
        SymptomeServiceLogger.warning('⚠️ Aucun token trouvé');
      }
      
      return token;
    } catch (e) {
      SymptomeServiceLogger.error('Erreur récupération token', error: e);
      return null;
    }
  }

  // ==========================================================================
  // RÉCUPÉRER LES SYMPTÔMES
  // ==========================================================================
  Future<List<Symptome>> getSymptomes() async {
    SymptomeServiceLogger.info('📥 Récupération des symptômes');
    final stopwatch = Stopwatch()..start();
    
    try {
      final token = await _getToken();
      final url = Uri.parse('${baseUrl}symptomes');
      
      SymptomeServiceLogger.api('GET', url.toString());

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      stopwatch.stop();
      SymptomeServiceLogger.performance('Récupération des symptômes', stopwatch.elapsed);

      SymptomeServiceLogger.debug('📥 Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        SymptomeServiceLogger.api('GET', url.toString(), response: data, statusCode: response.statusCode);
        
        if (data['success'] == true) {
          final List<dynamic> symptomesData = data['data'] ?? [];
          final symptomes = symptomesData.map((item) => Symptome.fromJson(item)).toList();
          SymptomeServiceLogger.success('✅ ${symptomes.length} symptômes récupérés');
          return symptomes;
        } else {
          SymptomeServiceLogger.warning('⚠️ success=false: ${data['message']}');
          return [];
        }
      } else if (response.statusCode == 401) {
        SymptomeServiceLogger.error('🔒 Non authentifié - Token invalide');
        return [];
      } else {
        SymptomeServiceLogger.error('❌ Erreur ${response.statusCode}', error: response.body);
        return [];
      }
      
    } catch (e, stackTrace) {
      stopwatch.stop();
      SymptomeServiceLogger.error('Erreur récupération des symptômes', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  // ==========================================================================
  // STATISTIQUES
  // ==========================================================================
  Future<Map<String, dynamic>> getStats() async {
    SymptomeServiceLogger.info('📊 Récupération des statistiques');
    final stopwatch = Stopwatch()..start();
    
    try {
      final token = await _getToken();
      final url = Uri.parse('${baseUrl}symptomes/stats');
      
      SymptomeServiceLogger.api('GET', url.toString());

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      stopwatch.stop();
      SymptomeServiceLogger.performance('Récupération des statistiques', stopwatch.elapsed);

      SymptomeServiceLogger.debug('📥 Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        SymptomeServiceLogger.api('GET', url.toString(), response: data, statusCode: response.statusCode);
        
        if (data['success'] == true) {
          SymptomeServiceLogger.success('✅ Statistiques récupérées');
          return data['data'] ?? {};
        } else {
          SymptomeServiceLogger.warning('⚠️ success=false: ${data['message']}');
          return {};
        }
      } else {
        SymptomeServiceLogger.error('❌ Erreur ${response.statusCode}', error: response.body);
        return {};
      }
      
    } catch (e, stackTrace) {
      stopwatch.stop();
      SymptomeServiceLogger.error('Erreur récupération des statistiques', error: e, stackTrace: stackTrace);
      return {};
    }
  }

  // ==========================================================================
  // CRÉER UN SYMPTÔME
  // ==========================================================================
  Future<Symptome> createSymptome(Map<String, dynamic> data) async {
    SymptomeServiceLogger.info('➕ Création d\'un symptôme');
    final stopwatch = Stopwatch()..start();
    
    try {
      final token = await _getToken();
      final url = Uri.parse('${baseUrl}symptomes');
      
      SymptomeServiceLogger.api('POST', url.toString(), request: data);

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: json.encode(data),
      ).timeout(const Duration(seconds: 10));

      stopwatch.stop();
      SymptomeServiceLogger.performance('Création du symptôme', stopwatch.elapsed);

      SymptomeServiceLogger.debug('📥 Status: ${response.statusCode}');
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        final result = json.decode(response.body);
        SymptomeServiceLogger.api('POST', url.toString(), response: result, statusCode: response.statusCode);
        
        if (result['success'] == true) {
          final symptome = Symptome.fromJson(result['data']);
          SymptomeServiceLogger.success('✅ Symptôme créé: ${symptome.description}');
          return symptome;
        } else {
          throw Exception(result['message'] ?? 'Erreur de création');
        }
      } else if (response.statusCode == 401) {
        SymptomeServiceLogger.error('🔒 Non authentifié');
        throw Exception('Session expirée, veuillez vous reconnecter');
      } else {
        SymptomeServiceLogger.error('❌ Erreur ${response.statusCode}', error: response.body);
        throw Exception('Erreur ${response.statusCode}: ${response.body}');
      }
      
    } catch (e, stackTrace) {
      stopwatch.stop();
      SymptomeServiceLogger.error('Erreur création du symptôme', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  // ==========================================================================
  // METTRE À JOUR UN SYMPTÔME
  // ==========================================================================
  Future<Symptome> updateSymptome(int id, Map<String, dynamic> data) async {
    SymptomeServiceLogger.info('✏️ Mise à jour du symptôme #$id');
    final stopwatch = Stopwatch()..start();
    
    try {
      final token = await _getToken();
      final url = Uri.parse('${baseUrl}symptomes/$id');
      
      SymptomeServiceLogger.api('PUT', url.toString(), request: data);

      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: json.encode(data),
      ).timeout(const Duration(seconds: 10));

      stopwatch.stop();
      SymptomeServiceLogger.performance('Mise à jour du symptôme', stopwatch.elapsed);

      SymptomeServiceLogger.debug('📥 Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        SymptomeServiceLogger.api('PUT', url.toString(), response: result, statusCode: response.statusCode);
        
        if (result['success'] == true) {
          final symptome = Symptome.fromJson(result['data']);
          SymptomeServiceLogger.success('✅ Symptôme #$id mis à jour');
          return symptome;
        } else {
          throw Exception(result['message'] ?? 'Erreur de mise à jour');
        }
      } else if (response.statusCode == 404) {
        SymptomeServiceLogger.warning('⚠️ Symptôme #$id non trouvé');
        throw Exception('Symptôme non trouvé');
      } else if (response.statusCode == 401) {
        SymptomeServiceLogger.error('🔒 Non authentifié');
        throw Exception('Session expirée, veuillez vous reconnecter');
      } else {
        SymptomeServiceLogger.error('❌ Erreur ${response.statusCode}', error: response.body);
        throw Exception('Erreur ${response.statusCode}: ${response.body}');
      }
      
    } catch (e, stackTrace) {
      stopwatch.stop();
      SymptomeServiceLogger.error('Erreur mise à jour du symptôme', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  // ==========================================================================
  // ✅ RÉSOUDRE UN SYMPTÔME (Utilisation de PATCH)
  // ==========================================================================
  Future<Symptome> resolveSymptome(int id) async {
    SymptomeServiceLogger.info('✅ Résolution du symptôme #$id');
    final stopwatch = Stopwatch()..start();
    
    try {
      final token = await _getToken();
      final url = Uri.parse('${baseUrl}symptomes/$id');
      
      final requestData = {
        'status': 'resolu',
      };
      
      SymptomeServiceLogger.api('PATCH', url.toString(), request: requestData);

      final response = await http.patch(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: json.encode(requestData),
      ).timeout(const Duration(seconds: 10));

      stopwatch.stop();
      SymptomeServiceLogger.performance('Résolution du symptôme', stopwatch.elapsed);

      SymptomeServiceLogger.debug('📥 Status: ${response.statusCode}');
      SymptomeServiceLogger.debug('📥 Response: ${response.body}');
      
      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        SymptomeServiceLogger.api('PATCH', url.toString(), response: result, statusCode: response.statusCode);
        
        // ✅ Gérer les deux formats de réponse possibles
        if (result['success'] == true && result['data'] != null) {
          final symptome = Symptome.fromJson(result['data']);
          SymptomeServiceLogger.success('✅ Symptôme #$id résolu avec succès');
          return symptome;
        } else if (result['id'] != null) {
          // Si l'API retourne directement les données
          final symptome = Symptome.fromJson(result);
          SymptomeServiceLogger.success('✅ Symptôme #$id résolu avec succès');
          return symptome;
        } else {
          throw Exception(result['message'] ?? 'Erreur de résolution');
        }
      } else if (response.statusCode == 404) {
        SymptomeServiceLogger.warning('⚠️ Symptôme #$id non trouvé');
        throw Exception('Symptôme #$id non trouvé');
      } else if (response.statusCode == 401) {
        SymptomeServiceLogger.error('🔒 Non authentifié');
        throw Exception('Session expirée, veuillez vous reconnecter');
      } else {
        SymptomeServiceLogger.error('❌ Erreur ${response.statusCode}', error: response.body);
        throw Exception('Erreur ${response.statusCode}: ${response.body}');
      }
      
    } catch (e, stackTrace) {
      stopwatch.stop();
      SymptomeServiceLogger.error('Erreur résolution du symptôme', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  // ==========================================================================
  // SUPPRIMER UN SYMPTÔME
  // ==========================================================================
  Future<void> deleteSymptome(int id) async {
    SymptomeServiceLogger.info('🗑️ Suppression du symptôme #$id');
    final stopwatch = Stopwatch()..start();
    
    try {
      final token = await _getToken();
      final url = Uri.parse('${baseUrl}symptomes/$id');
      
      SymptomeServiceLogger.api('DELETE', url.toString());

      final response = await http.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      stopwatch.stop();
      SymptomeServiceLogger.performance('Suppression du symptôme', stopwatch.elapsed);

      SymptomeServiceLogger.debug('📥 Status: ${response.statusCode}');
      
      if (response.statusCode == 200 || response.statusCode == 204) {
        SymptomeServiceLogger.success('✅ Symptôme #$id supprimé avec succès');
        return;
      } else if (response.statusCode == 404) {
        SymptomeServiceLogger.warning('⚠️ Symptôme #$id non trouvé');
        throw Exception('Symptôme #$id non trouvé');
      } else if (response.statusCode == 401) {
        SymptomeServiceLogger.error('🔒 Non authentifié');
        throw Exception('Session expirée, veuillez vous reconnecter');
      } else {
        SymptomeServiceLogger.error('❌ Erreur ${response.statusCode}', error: response.body);
        throw Exception('Erreur ${response.statusCode}: ${response.body}');
      }
      
    } catch (e, stackTrace) {
      stopwatch.stop();
      SymptomeServiceLogger.error('Erreur suppression du symptôme', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  // ==========================================================================
  // ANALYSE DES SYMPTÔMES
  // ==========================================================================
  Future<Map<String, dynamic>> analyzeSymptoms(List<Symptome> symptomes) async {
    SymptomeServiceLogger.info('🤖 Analyse de ${symptomes.length} symptômes');
    final stopwatch = Stopwatch()..start();
    
    try {
      final token = await _getToken();
      final url = Uri.parse('${baseUrl}symptomes/analyze');
      
      final requestData = {
        'symptomes': symptomes.map((s) => s.toJson()).toList(),
      };
      
      SymptomeServiceLogger.api('POST', url.toString(), request: requestData);

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: json.encode(requestData),
      ).timeout(const Duration(seconds: 30));

      stopwatch.stop();
      SymptomeServiceLogger.performance('Analyse des symptômes', stopwatch.elapsed);

      SymptomeServiceLogger.debug('📥 Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        SymptomeServiceLogger.api('POST', url.toString(), response: data, statusCode: response.statusCode);
        
        if (data['success'] == true) {
          SymptomeServiceLogger.success('✅ Analyse terminée');
          return data['data'] ?? {};
        } else {
          return data;
        }
      } else {
        SymptomeServiceLogger.error('❌ Erreur ${response.statusCode}', error: response.body);
        throw Exception('Erreur ${response.statusCode}: ${response.body}');
      }
      
    } catch (e, stackTrace) {
      stopwatch.stop();
      SymptomeServiceLogger.error('Erreur analyse des symptômes', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
}