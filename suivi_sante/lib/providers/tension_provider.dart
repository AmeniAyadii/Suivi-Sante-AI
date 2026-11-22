// lib/providers/tension_provider.dart

import 'package:flutter/material.dart';
import '../models/tension_measure.dart';
import '../models/tension_analysis.dart';
import '../services/tension_service.dart';
import 'dart:developer' as developer;

/// 📊 Provider pour la gestion des mesures de tension artérielle
/// 
/// Gère :
/// - L'ajout de mesures
/// - L'analyse des tendances
/// - Les prédictions IA
/// - L'état de chargement et les erreurs
class TensionProvider extends ChangeNotifier {
  // ============================================
  // SERVICES
  // ============================================
  final TensionService _service = TensionService();

  // ============================================
  // ÉTAT
  // ============================================
  List<TensionMeasure> _measures = [];
  TensionAnalysis? _analysis;
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;

  // ============================================
  // GETTERS
  // ============================================
  List<TensionMeasure> get measures => _measures;
  TensionAnalysis? get analysis => _analysis;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasData => _measures.isNotEmpty;
  bool get hasAnalysis => _analysis != null;
  bool get canAnalyze => _measures.length >= 3;
  int get measureCount => _measures.length;
  bool get isInitialized => _isInitialized;

  // ============================================
  // STATISTIQUES CALCULÉES
  // ============================================
  double get averageSystolic {
    if (_measures.isEmpty) return 0;
    return _measures.map((m) => m.systolic.toDouble()).reduce((a, b) => a + b) / _measures.length;
  }

  double get averageDiastolic {
    if (_measures.isEmpty) return 0;
    return _measures.map((m) => m.diastolic.toDouble()).reduce((a, b) => a + b) / _measures.length;
  }

  double? get averageHeartRate {
    final heartRates = _measures.where((m) => m.heartRate != null).map((m) => m.heartRate!.toDouble()).toList();
    if (heartRates.isEmpty) return null;
    return heartRates.reduce((a, b) => a + b) / heartRates.length;
  }

  TensionMeasure? get lastMeasure {
    if (_measures.isEmpty) return null;
    return _measures.first;
  }

  TensionMeasure? get oldestMeasure {
    if (_measures.isEmpty) return null;
    return _measures.last;
  }

  // ============================================
  // MÉTHODES DE LOG
  // ============================================
  void _log(String message, {String level = 'INFO'}) {
    final timestamp = DateTime.now().toIso8601String();
    developer.log('[$timestamp] [$level] TensionProvider: $message');
  }

  void _logError(String message, dynamic error) {
    _log('❌ $message: $error', level: 'ERROR');
    if (error is Error) {
      developer.log('StackTrace: ${error.stackTrace}');
    }
  }

  // ============================================
  // INITIALISATION
  // ============================================
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    _log('🚀 Initialisation du TensionProvider');
    _isLoading = true;
    notifyListeners();

    try {
      // Charger les données depuis le cache ou l'API
      await _loadCachedData();
      _isInitialized = true;
      _log('✅ Initialisation terminée - ${_measures.length} mesures chargées');
    } catch (e) {
      _logError('Erreur lors de l\'initialisation', e);
      _error = 'Erreur de chargement des données';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadCachedData() async {
    // TODO: Implémenter le chargement depuis le cache
    // Pour l'instant, charger des données d'exemple
    if (_measures.isEmpty) {
      _addDefaultData();
    }
  }

  // ============================================
  // DONNÉES PAR DÉFAUT
  // ============================================
  void _addDefaultData() {
    _log('📊 Ajout des données par défaut');
    final now = DateTime.now();
    _measures = [
      TensionMeasure(
        systolic: 118,
        diastolic: 76,
        heartRate: 72,
        measureDate: now.subtract(const Duration(days: 7)),
        category: 'normal',
      ),
      TensionMeasure(
        systolic: 120,
        diastolic: 78,
        heartRate: 70,
        measureDate: now.subtract(const Duration(days: 5)),
        category: 'normal',
      ),
      TensionMeasure(
        systolic: 125,
        diastolic: 82,
        heartRate: 75,
        measureDate: now.subtract(const Duration(days: 3)),
        category: 'normal',
      ),
      TensionMeasure(
        systolic: 128,
        diastolic: 85,
        heartRate: 78,
        measureDate: now.subtract(const Duration(days: 1)),
        category: 'normal',
      ),
    ];
  }

  // ============================================
  // CRUD - MESURES
  // ============================================
  
  /// 📊 Ajouter une mesure
  // lib/providers/tension_provider.dart


// lib/providers/tension_provider.dart

Future<bool> addMeasure(TensionMeasure measure) async {
  _log('📤 Ajout d\'une mesure: ${measure.systolic}/${measure.diastolic}');
  
  _isLoading = true;
  _error = null;
  notifyListeners();

  try {
    final result = await _service.addMeasure(measure);
    _log('📥 Résultat reçu: ${result.systolic}/${result.diastolic}');
    
    _measures.insert(0, result);
    _analysis = null;
    
    _log('✅ Mesure ajoutée avec succès (${_measures.length} mesures totales)');
    _isLoading = false;
    notifyListeners();
    return true;
    
  } on TensionException catch (e) {
    _logError('Erreur TensionException', e);
    _error = e.message;
    _isLoading = false;
    notifyListeners();
    return false;
  } catch (e) {
    _logError('Erreur lors de l\'ajout de la mesure', e);
    _error = _formatErrorMessage(e);
    _isLoading = false;
    notifyListeners();
    return false;
  }
}

  /// 🗑️ Supprimer une mesure
  Future<bool> deleteMeasure(TensionMeasure measure) async {
    _log('🗑️ Suppression de la mesure du ${measure.formattedDate}');
    
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // TODO: Appel API pour supprimer
      // await _service.deleteMeasure(measure.id!);
      
      _measures.removeWhere((m) => m.id == measure.id);
      _analysis = null;
      
      _log('✅ Mesure supprimée avec succès');
      _isLoading = false;
      notifyListeners();
      return true;
      
    } catch (e) {
      _logError('Erreur lors de la suppression', e);
      _error = _formatErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// 🔄 Mettre à jour une mesure
  Future<bool> updateMeasure(TensionMeasure measure) async {
    _log('📝 Mise à jour de la mesure du ${measure.formattedDate}');
    
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // TODO: Appel API pour mettre à jour
      // await _service.updateMeasure(measure);
      
      final index = _measures.indexWhere((m) => m.id == measure.id);
      if (index != -1) {
        _measures[index] = measure;
      }
      
      _analysis = null;
      
      _log('✅ Mesure mise à jour avec succès');
      _isLoading = false;
      notifyListeners();
      return true;
      
    } catch (e) {
      _logError('Erreur lors de la mise à jour', e);
      _error = _formatErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ============================================
  // ANALYSE IA
  // ============================================
  
  /// 🤖 Analyser les tendances
  Future<bool> analyzeTrends() async {
    if (_measures.length < 3) {
      _log('⚠️ Pas assez de données pour l\'analyse (${_measures.length}/3)');
      _error = 'Minimum 3 mesures nécessaires pour l\'analyse';
      notifyListeners();
      return false;
    }

    _log('🤖 Début de l\'analyse des tendances (${_measures.length} mesures)');
    
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _analysis = await _service.analyzeTrends(_measures);
      _log('✅ Analyse terminée - Sévérité: ${_analysis?.severityLevel}');
      _isLoading = false;
      notifyListeners();
      return true;
      
    } on Exception catch (e) {
      _logError('Erreur lors de l\'analyse', e);
      _error = _formatErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// 🔮 Prédictions
  Future<Map<String, dynamic>?> predict(int daysAhead) async {
    if (_measures.length < 3) {
      _log('⚠️ Pas assez de données pour les prédictions (${_measures.length}/3)');
      _error = 'Minimum 3 mesures nécessaires pour les prédictions';
      notifyListeners();
      return null;
    }

    _log('🔮 Début des prédictions sur $daysAhead jours');
    
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _service.predict(_measures, daysAhead);
      
      if (result != null && result['available'] == true) {
        _log('✅ Prédictions terminées avec succès');
      } else {
        _log('⚠️ Prédictions non disponibles');
        _error = 'Prédictions non disponibles';
      }
      
      _isLoading = false;
      notifyListeners();
      return result;
      
    } on Exception catch (e) {
      _logError('Erreur lors des prédictions', e);
      _error = _formatErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // ============================================
  // RÉINITIALISATION
  // ============================================
  
  /// 🔄 Réinitialiser toutes les données
  void reset() {
    _log('🔄 Réinitialisation des données');
    _measures = [];
    _analysis = null;
    _error = null;
    _isLoading = false;
    _isInitialized = false;
    notifyListeners();
  }

  /// 🧹 Nettoyer les données d'exemple
  void clearSampleData() {
    _log('🧹 Nettoyage des données d\'exemple');
    _measures = [];
    _analysis = null;
    _error = null;
    notifyListeners();
  }

  /// 📊 Ajouter des données d'exemple (pour la démo)
  void addSampleData() {
    _log('📊 Ajout des données d\'exemple');
    _addDefaultData();
    notifyListeners();
  }

  /// ❌ Effacer l'erreur
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // ============================================
  // UTILITAIRES
  // ============================================
  
  String _formatErrorMessage(dynamic error) {
    if (error is String) return error;
    if (error is Exception) {
      final message = error.toString();
      // Nettoyer le message
      final cleanMessage = message.replaceAll('Exception: ', '');
      return cleanMessage;
    }
    return 'Une erreur inattendue est survenue';
  }

  /// 📈 Obtenir les mesures pour un graphique
  List<Map<String, dynamic>> getChartData() {
    return _measures.map((m) => {
      'date': m.measureDate,
      'systolic': m.systolic,
      'diastolic': m.diastolic,
      'heartRate': m.heartRate,
    }).toList();
  }

  /// 📊 Obtenir les statistiques des 7 derniers jours
  Map<String, dynamic> getWeeklyStats() {
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    final recentMeasures = _measures.where((m) => m.measureDate.isAfter(sevenDaysAgo)).toList();
    
    if (recentMeasures.isEmpty) {
      return {
        'count': 0,
        'avgSystolic': 0,
        'avgDiastolic': 0,
        'maxSystolic': 0,
        'maxDiastolic': 0,
        'minSystolic': 0,
        'minDiastolic': 0,
      };
    }

    final systolics = recentMeasures.map((m) => m.systolic.toDouble()).toList();
    final diastolics = recentMeasures.map((m) => m.diastolic.toDouble()).toList();

    return {
      'count': recentMeasures.length,
      'avgSystolic': systolics.reduce((a, b) => a + b) / systolics.length,
      'avgDiastolic': diastolics.reduce((a, b) => a + b) / diastolics.length,
      'maxSystolic': systolics.reduce((a, b) => a > b ? a : b),
      'maxDiastolic': diastolics.reduce((a, b) => a > b ? a : b),
      'minSystolic': systolics.reduce((a, b) => a < b ? a : b),
      'minDiastolic': diastolics.reduce((a, b) => a < b ? a : b),
    };
  }

  /// 🏷️ Obtenir la catégorie dominante
  String get dominantCategory {
    if (_measures.isEmpty) return 'Aucune donnée';
    
    final categories = _measures.map((m) => m.category ?? 'unknown').toList();
    final categoryCount = <String, int>{};
    
    for (final category in categories) {
      categoryCount[category] = (categoryCount[category] ?? 0) + 1;
    }
    
    return categoryCount.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  // ============================================
  // OVERRIDES
  // ============================================
  
  @override
  void dispose() {
    _log('🧹 Nettoyage du TensionProvider');
    super.dispose();
  }
}