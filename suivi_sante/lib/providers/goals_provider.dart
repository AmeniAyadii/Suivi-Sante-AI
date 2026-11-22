
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:suivi_sante_pro/models/goal.dart';
import 'package:suivi_sante_pro/models/challenge.dart';
import 'package:suivi_sante_pro/models/achievement.dart';
import 'package:suivi_sante_pro/services/goal_api_service.dart';

class GoalsProvider extends ChangeNotifier {
  late final GoalApiService apiService;

  List<Goal> _goals = [];
  List<Challenge> _challenges = [];
  List<Achievement> _achievements = [];

  GoalCategory? _selectedCategory;
  bool _isLoading = false;
  bool _isLoadingChallenges = false;
  bool _isLoadingAchievements = false;
  String? _error;
  int _currentStreak = 0;
  int _bestStreak = 0;
  bool _isDisposed = false;

  GoalsProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      debugPrint(
        '🏆 GoalsProvider initialisé avec token: '
        '${token.isNotEmpty ? "✅ Présent" : "❌ Aucun"}',
      );

      apiService = GoalApiService(
        // Adresse du serveur sans /api
        // GoalApiService ajoute lui-même le préfixe /api
        baseUrl: 'http://192.168.1.5:8001',
        token: token,
      );

      if (token.isNotEmpty && !_isDisposed) {
        await loadGoals();
        await loadChallenges();
        await loadAchievements();
      }
    } catch (e) {
      debugPrint('❌ Erreur initialisation GoalsProvider: $e');
    }
  }

  void updateToken(String newToken) {
    if (apiService.token != newToken) {
      apiService.updateToken(newToken);

      debugPrint(
        '🔄 Token mis à jour dans GoalsProvider: '
        '${newToken.isNotEmpty ? "✅ Présent" : "❌ Aucun"}',
      );

      if (newToken.isNotEmpty) {
        loadGoals();
        loadChallenges();
        loadAchievements();
      }
    }
  }

  // ============================================================
  // GETTERS PUBLICS
  // ============================================================

  List<Goal> get goals => _goals;
  List<Challenge> get challenges => _challenges;
  List<Achievement> get achievements => _achievements;
  GoalCategory? get selectedCategory => _selectedCategory;
  bool get isLoading => _isLoading;
  bool get isLoadingChallenges => _isLoadingChallenges;
  bool get isLoadingAchievements => _isLoadingAchievements;
  String? get error => _error;
  int get currentStreak => _currentStreak;
  int get bestStreak => _bestStreak;

  List<Goal> get filteredGoals {
    if (_selectedCategory == null) return _goals;
    return _goals.where((g) => g.category == _selectedCategory).toList();
  }

  // ============================================================
  // MÉTHODES DE CHARGEMENT
  // ============================================================

  Future<void> loadGoals() async {
    if (_isDisposed) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _goals = await apiService.getGoals();

      if (!_isDisposed) {
        _isLoading = false;
        notifyListeners();
        debugPrint('✅ ${_goals.length} objectifs chargés');
      }
    } catch (e) {
      if (!_isDisposed) {
        _error = e.toString();
        _isLoading = false;
        notifyListeners();
        debugPrint('❌ Erreur loadGoals: $e');
      }
    }
  }

  Future<void> loadChallenges() async {
    if (_isDisposed) return;

    _isLoadingChallenges = true;
    notifyListeners();

    try {
      _challenges = await apiService.getChallenges();

      if (!_isDisposed) {
        _isLoadingChallenges = false;
        notifyListeners();
        debugPrint('✅ ${_challenges.length} défis chargés');
      }
    } catch (e) {
      if (!_isDisposed) {
        _challenges = [];
        _isLoadingChallenges = false;
        notifyListeners();
        debugPrint('ℹ️ Aucun défi disponible: $e');
      }
    }
  }

  Future<void> loadAchievements() async {
    if (_isDisposed) return;

    _isLoadingAchievements = true;
    notifyListeners();

    try {
      _achievements = await apiService.getAchievements();

      if (!_isDisposed) {
        _isLoadingAchievements = false;
        notifyListeners();
        debugPrint('✅ ${_achievements.length} récompenses chargées');
      }
    } catch (e) {
      if (!_isDisposed) {
        _achievements = [];
        _isLoadingAchievements = false;
        notifyListeners();
        debugPrint('ℹ️ Aucune récompense disponible: $e');
      }
    }
  }

  // ============================================================
  // MÉTHODES DE GESTION DES OBJECTIFS
  // ============================================================

  Future<void> addGoal(Goal goal) async {
    if (_isDisposed) return;

    try {
      _isLoading = true;
      notifyListeners();

      final newGoal = await apiService.createGoal(goal);
      _goals.insert(0, newGoal);

      _isLoading = false;
      notifyListeners();
      debugPrint('✅ Objectif ajouté: ${newGoal.title}');
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      debugPrint('❌ Erreur addGoal: $e');
      rethrow;
    }
  }

  Future<void> updateGoal(Goal goal) async {
    if (_isDisposed) return;

    try {
      _isLoading = true;
      notifyListeners();

      final index = _goals.indexWhere((g) => g.id == goal.id);

      if (index != -1) {
        _goals[index] = goal;
      } else {
        _goals.insert(0, goal);
      }

      _isLoading = false;
      notifyListeners();
      debugPrint('✅ Objectif mis à jour: ${goal.title}');
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      debugPrint('❌ Erreur updateGoal: $e');
      rethrow;
    }
  }

  Future<void> updateGoalProgress(String goalId, double value) async {
    if (_isDisposed) return;

    try {
      final updatedGoal =
          await apiService.updateGoalProgress(goalId, value);

      final index = _goals.indexWhere((g) => g.id == goalId);

      if (index != -1) {
        _goals[index] = updatedGoal;
        notifyListeners();
        debugPrint('✅ Progression mise à jour: $goalId -> $value');
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      debugPrint('❌ Erreur updateGoalProgress: $e');
      rethrow;
    }
  }

  Future<void> deleteGoal(String goalId) async {
    if (_isDisposed) return;

    try {
      await apiService.deleteGoal(goalId);

      _goals.removeWhere((g) => g.id == goalId);
      notifyListeners();

      debugPrint('✅ Objectif supprimé: $goalId');
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      debugPrint('❌ Erreur deleteGoal: $e');
      rethrow;
    }
  }

  // ============================================================
  // MÉTHODES DE GESTION DES DÉFIS
  // ============================================================

  Future<void> joinChallenge(String challengeId) async {
    if (_isDisposed) return;

    try {
      await apiService.joinChallenge(challengeId);
      await loadChallenges();

      debugPrint('✅ Défi rejoint: $challengeId');
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      debugPrint('❌ Erreur joinChallenge: $e');
      rethrow;
    }
  }

  // ============================================================
  // MÉTHODES DE FILTRAGE
  // ============================================================

  void setCategoryFilter(GoalCategory? category) {
    if (_isDisposed) return;

    _selectedCategory = category;
    notifyListeners();

    debugPrint('📊 Filtre appliqué: ${category?.name ?? "Tous"}');
  }

  void clearError() {
    if (_isDisposed) return;

    _error = null;
    notifyListeners();
  }

  // ============================================================
  // MÉTHODES DE STATISTIQUES
  // ============================================================

  int get completedGoalsCount {
    return _goals.where((g) => g.isCompleted).length;
  }

  double get averageProgress {
    if (_goals.isEmpty) return 0;

    final total = _goals.fold<double>(
      0,
      (sum, goal) => sum + goal.progress,
    );

    return total / _goals.length;
  }

  // ============================================================
  // CYCLE DE VIE
  // ============================================================

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
    debugPrint('🗑️ GoalsProvider disposé');
  }
}
