// lib/services/goal_api_service.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/goal.dart';
import '../models/challenge.dart';
import '../models/achievement.dart';

class GoalApiService {
  // ==================== PROPRIÉTÉS ====================
  final String baseUrl;
  String? _token;
  bool _isInitialized = false;

  // ==================== CONSTRUCTEUR ====================
  GoalApiService({
    required this.baseUrl,
    String? token,
  }) {
    _token = token;
    _isInitialized = token != null && token.isNotEmpty;
    
    debugPrint('🏆 GoalApiService créé');
    debugPrint('📤 Base URL: $baseUrl');
    debugPrint('📤 Token présent: ${_isInitialized ? "✅ Oui" : "❌ Non"}');
  }

  // ==================== GETTERS ====================
  String? get token => _token;
  bool get isInitialized => _isInitialized && _token != null && _token!.isNotEmpty;

  // ==================== MÉTHODES D'INITIALISATION ====================
  
  Future<void> init() async {
    if (_isInitialized && _token != null && _token!.isNotEmpty) {
      debugPrint('✅ GoalApiService déjà initialisé');
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (token != null && token.isNotEmpty) {
        _token = token;
        _isInitialized = true;
        debugPrint('✅ GoalApiService initialisé avec token de SharedPreferences');
      } else {
        debugPrint('⚠️ Aucun token trouvé dans SharedPreferences');
        _isInitialized = false;
      }
    } catch (e) {
      debugPrint('❌ Erreur init GoalApiService: $e');
      _isInitialized = false;
    }
  }

  void updateToken(String newToken) {
    if (newToken.isNotEmpty) {
      _token = newToken;
      _isInitialized = true;
      debugPrint('🔄 Token mis à jour dans GoalApiService: ✅ Présent');
    } else {
      _token = null;
      _isInitialized = false;
      debugPrint('🔄 Token mis à jour dans GoalApiService: ❌ Aucun');
    }
  }

  void _ensureInitialized() {
    if (!isInitialized) {
      throw Exception('GoalApiService non initialisé. Appeler init() d\'abord.');
    }
  }

  /// ✅ Headers avec ngrok-skip-browser-warning
  Map<String, String> get _headers {
    _ensureInitialized();
    return {
      'Authorization': 'Bearer $_token',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'ngrok-skip-browser-warning': 'true', // ✅ INDISPENSABLE pour ngrok
    };
  }

  // ============================================================
  // OBJECTIFS
  // ============================================================

  Future<List<Goal>> getGoals({
    String? category,
    String? status,
    int page = 1,
  }) async {
    try {
      if (!isInitialized) {
        await init();
      }
      _ensureInitialized();

      debugPrint('📤 getGoals appelé');
      
      final queryParams = <String, String>{};
      if (category != null) queryParams['category'] = category;
      if (status != null) queryParams['status'] = status;
      queryParams['page'] = page.toString();

      final uri = Uri.parse('$baseUrl/api/goals')
          .replace(queryParameters: queryParams);
      
      debugPrint('📤 URL: $uri');
      debugPrint('📤 Headers: Authorization: Bearer ${_token != null ? "✅ Présent" : "❌ Aucun"}');
      
      final response = await http.get(uri, headers: _headers);
      
      debugPrint('📥 Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('📥 Data keys: ${data.keys}');
        
        if (data['success'] == true) {
          List goalsList = [];
          
          if (data['data'] is List) {
            goalsList = data['data'] as List;
            debugPrint('📥 Structure: liste directe de ${goalsList.length} éléments');
          } 
          else if (data['data'] is Map && data['data'].containsKey('data')) {
            goalsList = data['data']['data'] as List? ?? [];
            debugPrint('📥 Structure: paginée de ${goalsList.length} éléments');
          } 
          else {
            goalsList = [];
            debugPrint('📥 Structure inconnue, liste vide');
          }
          
          debugPrint('✅ ${goalsList.length} objectifs chargés');
          return goalsList.map((e) => Goal.fromJson(e)).toList();
        } else {
          throw Exception(data['message'] ?? 'Erreur lors du chargement');
        }
      } else {
        debugPrint('❌ Erreur: ${response.body}');
        throw Exception('Failed to load goals: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ getGoals Error: $e');
      rethrow;
    }
  }

  Future<Goal> createGoal(Goal goal) async {
    try {
      if (!isInitialized) {
        await init();
      }
      _ensureInitialized();

      debugPrint('📤 createGoal appelé');
      debugPrint('📤 Titre: ${goal.title}');
      
      final body = goal.toJson();
      debugPrint('📤 Body: ${json.encode(body)}');
      
      final response = await http.post(
        Uri.parse('$baseUrl/api/goals'),
        headers: _headers,
        body: json.encode(body),
      );

      debugPrint('📥 Status: ${response.statusCode}');
      debugPrint('📥 Body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          debugPrint('✅ Goal créé avec succès: ${data['data']['id']}');
          return Goal.fromJson(data['data']);
        } else {
          throw Exception(data['message'] ?? 'Erreur lors de la création');
        }
      } else {
        final errorData = json.decode(response.body);
        debugPrint('❌ Erreur: ${errorData['message'] ?? response.body}');
        throw Exception('Failed to create goal: ${errorData['message'] ?? response.body}');
      }
    } catch (e) {
      debugPrint('❌ createGoal Error: $e');
      rethrow;
    }
  }

  Future<Goal> updateGoalProgress(String goalId, double value) async {
    try {
      if (!isInitialized) {
        await init();
      }
      _ensureInitialized();

      debugPrint('📤 updateGoalProgress: $goalId -> $value');
      
      final response = await http.post(
        Uri.parse('$baseUrl/api/goals/$goalId/progress'),
        headers: _headers,
        body: json.encode({'value': value}),
      );

      debugPrint('📥 Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return Goal.fromJson(data['data']);
        } else {
          throw Exception(data['message'] ?? 'Erreur lors de la mise à jour');
        }
      } else {
        throw Exception('Failed to update progress: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ updateGoalProgress Error: $e');
      rethrow;
    }
  }

  Future<void> deleteGoal(String goalId) async {
    try {
      if (!isInitialized) {
        await init();
      }
      _ensureInitialized();

      debugPrint('📤 deleteGoal: $goalId');
      
      final response = await http.delete(
        Uri.parse('$baseUrl/api/goals/$goalId'),
        headers: _headers,
      );

      debugPrint('📥 Status: ${response.statusCode}');
      
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete goal: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ deleteGoal Error: $e');
      rethrow;
    }
  }

  // ============================================================
  // DÉFIS
  // ============================================================

  Future<List<Challenge>> getChallenges({bool upcoming = false}) async {
    try {
      if (!isInitialized) {
        await init();
      }
      
      if (!isInitialized) {
        debugPrint('ℹ️ Service non initialisé, retour liste vide');
        return [];
      }

      final queryParams = upcoming ? {'upcoming': 'true'} : <String, String>{};
      final uri = Uri.parse('$baseUrl/api/challenges')
          .replace(queryParameters: queryParams);

      debugPrint('📤 getChallenges: $uri');
      
      final response = await http.get(uri, headers: _headers);
      
      debugPrint('📥 Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final challengesData = data['data'] as List? ?? [];
          return challengesData.map((e) => Challenge.fromJson(e)).toList();
        } else {
          if (data['message']?.contains('Aucun défi') == true) {
            return [];
          }
          throw Exception(data['message'] ?? 'Erreur lors du chargement');
        }
      } else {
        if (response.statusCode == 404 || response.statusCode == 500) {
          debugPrint('ℹ️ Aucun défi disponible (status ${response.statusCode})');
          return [];
        }
        throw Exception('Failed to load challenges: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ getChallenges Error: $e');
      return [];
    }
  }

  Future<void> joinChallenge(String challengeId) async {
    try {
      if (!isInitialized) {
        await init();
      }
      _ensureInitialized();

      debugPrint('📤 joinChallenge: $challengeId');
      
      final response = await http.post(
        Uri.parse('$baseUrl/api/challenges/$challengeId/join'),
        headers: _headers,
      );

      debugPrint('📥 Status: ${response.statusCode}');

      if (response.statusCode != 200) {
        throw Exception('Failed to join challenge: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ joinChallenge Error: $e');
      rethrow;
    }
  }

  // ============================================================
  // RÉCOMPENSES
  // ============================================================

  Future<List<Achievement>> getAchievements() async {
    try {
      if (!isInitialized) {
        await init();
      }
      
      if (!isInitialized) {
        debugPrint('ℹ️ Service non initialisé, retour liste vide');
        return [];
      }

      debugPrint('📤 getAchievements');
      
      final response = await http.get(
        Uri.parse('$baseUrl/api/achievements'),
        headers: _headers,
      );
      
      debugPrint('📥 Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final achievementsData = data['data'] as List? ?? [];
          return achievementsData.map((e) => Achievement.fromJson(e)).toList();
        } else {
          if (data['message']?.contains('Aucune récompense') == true) {
            return [];
          }
          throw Exception(data['message'] ?? 'Erreur lors du chargement');
        }
      } else {
        if (response.statusCode == 404 || response.statusCode == 500) {
          debugPrint('ℹ️ Aucune récompense disponible (status ${response.statusCode})');
          return [];
        }
        throw Exception('Failed to load achievements: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ getAchievements Error: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getAchievementStats() async {
    try {
      if (!isInitialized) {
        await init();
      }
      
      if (!isInitialized) {
        debugPrint('ℹ️ Service non initialisé, retour stats par défaut');
        return {
          'total_points': 0,
          'total_achievements': 0,
          'recent_achievements': [],
        };
      }

      debugPrint('📤 getAchievementStats');
      
      final response = await http.get(
        Uri.parse('$baseUrl/api/achievements/stats'),
        headers: _headers,
      );
      
      debugPrint('📥 Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['data'];
        } else {
          throw Exception(data['message'] ?? 'Erreur lors du chargement');
        }
      } else {
        if (response.statusCode == 404 || response.statusCode == 500) {
          return {
            'total_points': 0,
            'total_achievements': 0,
            'recent_achievements': [],
          };
        }
        throw Exception('Failed to load achievement stats: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ getAchievementStats Error: $e');
      return {
        'total_points': 0,
        'total_achievements': 0,
        'recent_achievements': [],
      };
    }
  }

  // ============================================================
  // MÉTHODE UTILITAIRE
  // ============================================================

  void reset() {
    _token = null;
    _isInitialized = false;
    debugPrint('🔄 GoalApiService réinitialisé');
  }
}