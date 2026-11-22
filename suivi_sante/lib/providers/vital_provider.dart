// lib/providers/vital_provider.dart

import 'dart:io';
import 'dart:math';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/constante_vitale.dart';
import '../models/alerte_sante.dart';
import '../services/constante_service.dart';

/// Provider pour la gestion des signes vitaux
/// Gère le chargement, l'ajout et le suivi des constantes vitales
class VitalProvider extends ChangeNotifier {
  final ConstanteService _service = ConstanteService();

  // ============ DONNÉES ============
  List<ConstanteVitale> _constantes = [];
  List<AlerteSante> _alertes = [];
  Map<String, dynamic> _correlations = {};
  Map<String, dynamic> _seuils = {};

  // ============ ÉTATS HISTORIQUE ============
  List<ConstanteVitale> _historique = [];
  bool _isHistoriqueLoading = false;
  bool _hasMoreHistorique = true;
  int _currentPageHistorique = 1;
  String? _filtreTypeHistorique;

  bool _isLoading = false;
  String? _error;

  // ============ GETTERS ============
  List<ConstanteVitale> get constantes => List.unmodifiable(_constantes);
  List<AlerteSante> get alertes => List.unmodifiable(_alertes);
  
  List<AlerteSante> get alertesNonLues => 
      _alertes.where((a) => !a.estLue).toList();
  
  List<AlerteSante> get alertesCritiques => 
      _alertes.where((a) => a.estUrgente).toList();
  
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  bool get hasData => _constantes.isNotEmpty;
  int get totalMesures => _constantes.length;
  int get totalAlertes => _alertes.length;

  // Getters Historique
  List<ConstanteVitale> get historique => _historique;
  bool get isHistoriqueLoading => _isHistoriqueLoading;
  bool get hasMoreHistorique => _hasMoreHistorique;
  String? get filtreTypeHistorique => _filtreTypeHistorique;

  // ============ CHARGEMENT DES CONSTANTES ============
  
  Future<void> loadConstantes({
    String? dateDebut,
    String? dateFin,
    List<String>? types,
  }) async {
    if (_isLoading) return;
    
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _service.getConstantes(
        dateDebut: dateDebut,
        dateFin: dateFin,
        types: types,
      );
      
      final List<dynamic> constantesJson = data['data']?['constantes'] ?? [];
      _constantes = constantesJson
          .map((json) => ConstanteVitale.fromJson(json))
          .toList();
      
      await _loadSeuils();
      await loadAlertes();
      
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Erreur loadConstantes: $e');
      _constantes = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  // ============ HISTORIQUE DES CONSTANTES ============

  Future<void> loadHistorique({
  String? type,
  bool refresh = false,
}) async {
  if (_isHistoriqueLoading) return;

  if (refresh) {
    _currentPageHistorique = 1;
    _historique = [];
    _hasMoreHistorique = true;
    _filtreTypeHistorique = type;
  }

  if (!_hasMoreHistorique) return;

  _isHistoriqueLoading = true;
  notifyListeners();

  try {
    final data = await _service.getHistorique(
      type: _filtreTypeHistorique,
      page: _currentPageHistorique,
    );

    // ✅ Correction robuste : Gérer à la fois une liste et un objet paginé
    List<dynamic> dataJson = [];
    final rawData = data['data'];

    if (rawData is Map<String, dynamic>) {
      // Cas 1 : Pagination Laravel classique
      dataJson = rawData['data'] ?? [];
    } else if (rawData is List) {
      // Cas 2 : Le serveur renvoie directement une liste
      dataJson = rawData;
    }

    final nouvelles = dataJson
        .map((json) => ConstanteVitale.fromJson(json))
        .toList();

    _historique.addAll(nouvelles);
    
    // Si on a reçu moins de 15 éléments, c'est la fin de la liste
    _hasMoreHistorique = nouvelles.length == 15; 
    _currentPageHistorique++;
  } catch (e) {
    debugPrint('❌ Erreur loadHistorique: $e');
  } finally {
    _isHistoriqueLoading = false;
    notifyListeners();
  }
}

  void setFiltreTypeHistorique(String? type) {
    if (_filtreTypeHistorique == type) return;
    loadHistorique(type: type, refresh: true);
  }

  // ============ EXPORT CSV ============

  Future<void> exportCSV({List<String>? types}) async {
  try {
    const defaultTypes = [
      'tension_systolique',
      'tension_diastolique',
      'frequence_cardiaque',
      'temperature',
      'glycemie'
    ];
    
    // 1. Récupérer le CSV depuis le serveur
    final csvContent = await _service.exportCSV(types ?? defaultTypes);
    
    // 2. Sauvegarder le fichier dans le dossier temporaire (pas besoin de permission)
    final directory = await getTemporaryDirectory();
    final fileName = 'constantes_vitales_${DateTime.now().toIso8601String().split('T').first}.csv';
    final filePath = '${directory.path}/$fileName';
    final file = File(filePath);
    await file.writeAsString(csvContent);
    
    debugPrint('✅ CSV sauvegardé: $filePath');
    
    // 3. Partager le fichier
    await Share.shareXFiles(
      [XFile(filePath)],
      text: '📊 Export des constantes vitales - ${DateTime.now().toIso8601String().split('T').first}',
    );
    
  } catch (e) {
    debugPrint('❌ Erreur exportCSV: $e');
    rethrow;
  }
}

  Future<bool> _isAndroidVersionGreaterOrEqual(int targetSdk) async {
    try {
      final androidInfo = await _getAndroidInfo();
      return androidInfo.version.sdkInt >= targetSdk;
    } catch (e) {
      return false;
    }
  }

  Future<AndroidDeviceInfo> _getAndroidInfo() async {
    final deviceInfo = DeviceInfoPlugin();
    return await deviceInfo.androidInfo;
  }

  // ============ ALERTES ============
  
  Future<void> loadAlertes({bool? nonLues}) async {
    try {
      _alertes = await _service.getAlertes(nonLues: nonLues);
      notifyListeners();
    } catch (e) {
      debugPrint('⚠️ Erreur loadAlertes: $e');
      _alertes = [];
    }
  }

  Future<void> marquerAlerteLue(int id) async {
    try {
      await _service.marquerAlerteLue(id);
      final index = _alertes.indexWhere((a) => a.id == id);
      if (index != -1) {
        _alertes[index] = _alertes[index].copyWith(estLue: true);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ Erreur marquerAlerteLue: $e');
      rethrow;
    }
  }

  Future<void> marquerAlerteResolue(int id) async {
    try {
      await _service.marquerAlerteResolue(id);
      final index = _alertes.indexWhere((a) => a.id == id);
      if (index != -1) {
        _alertes[index] = _alertes[index].copyWith(
          estResolue: true,
          dateResolution: DateTime.now(),
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ Erreur marquerAlerteResolue: $e');
      rethrow;
    }
  }

  Future<void> marquerToutesAlertesLues() async {
    try {
      final nonLues = _alertes.where((a) => !a.estLue).toList();
      for (final alerte in nonLues) {
        await _service.marquerAlerteLue(alerte.id);
      }
      _alertes = _alertes.map((a) {
        return a.estLue ? a : a.copyWith(estLue: true);
      }).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Erreur marquerToutesAlertesLues: $e');
      rethrow;
    }
  }

  // ============ AJOUT DE MESURE ============
  
  Future<ConstanteVitale> addConstante({
    required String typeConstante,
    required double valeur,
    required String unite,
    required DateTime dateMesure,
    String? notes,
  }) async {
    try {
      final constante = await _service.addConstante(
        typeConstante: typeConstante,
        valeur: valeur,
        unite: unite,
        dateMesure: dateMesure,
        notes: notes,
      );
      _constantes.insert(0, constante);
      notifyListeners();
      
      await loadAlertes();
      await _loadSeuils();
      
      return constante;
    } catch (e) {
      debugPrint('❌ Erreur addConstante: $e');
      rethrow;
    }
  }

  // ============ ANALYSE DES DONNÉES ============
  
  double? getDerniereValeur(TypeConstante type) {
    final filtered = _constantes
        .where((c) => c.typeConstante == type.value)
        .toList();
    
    if (filtered.isEmpty) {
      final fallback = _constantes
          .where((c) => c.typeConstante == type.name)
          .toList();
      if (fallback.isNotEmpty) {
        return fallback.first.valeur;
      }
    }
    
    if (filtered.isEmpty) return null;
    return filtered.first.valeur;
  }

  double? getValeurAtDate(TypeConstante type, DateTime date) {
    final filtered = _constantes
        .where((c) => 
            c.typeConstante == type.value &&
            c.dateMesure.year == date.year &&
            c.dateMesure.month == date.month &&
            c.dateMesure.day == date.day)
        .toList();
    if (filtered.isEmpty) return null;
    return filtered.first.valeur;
  }

  List<ConstanteVitale> getValeursByType(TypeConstante type) {
    return _constantes
        .where((c) => c.typeConstante == type.value)
        .toList();
  }

  double? getMoyenne(TypeConstante type) {
    final values = getValeursByType(type);
    if (values.isEmpty) return null;
    return values.map((c) => c.valeur).reduce((a, b) => a + b) / values.length;
  }

  double? getMinimum(TypeConstante type) {
    final values = getValeursByType(type);
    if (values.isEmpty) return null;
    return values.map((c) => c.valeur).reduce((a, b) => a < b ? a : b);
  }

  double? getMaximum(TypeConstante type) {
    final values = getValeursByType(type);
    if (values.isEmpty) return null;
    return values.map((c) => c.valeur).reduce((a, b) => a > b ? a : b);
  }

  // ============ STATUT ET TENDANCE ============
  
  String getStatut(TypeConstante type) {
    final valeur = getDerniereValeur(type);
    if (valeur == null) return 'Aucune mesure';
    
    final seuil = type.seuils;
    if (seuil.isEmpty) return 'Normal';
    
    final min = seuil['min']!;
    final max = seuil['max']!;
    
    if (valeur < min * 0.8 || valeur > max * 1.2) {
      return 'Critique';
    }
    
    if (valeur < min || valeur > max) {
      return 'Alerte';
    }
    
    return 'Normal';
  }

  String getTendance(TypeConstante type) {
    final filtered = _constantes
        .where((c) => c.typeConstante == type.value)
        .take(7)
        .toList();
    
    if (filtered.length < 2) return 'Stable';
    
    final sorted = filtered.toList()..sort((a, b) => a.dateMesure.compareTo(b.dateMesure));
    
    if (sorted.length < 2) return 'Stable';
    
    final first = sorted.first.valeur;
    final last = sorted.last.valeur;
    
    if (first == 0) return 'Stable';
    
    final variation = ((last - first) / first) * 100;
    
    if (variation > 2) return 'Hausse de ${variation.toStringAsFixed(1)}%';
    if (variation < -2) return 'Baisse de ${(-variation).toStringAsFixed(1)}%';
    return 'Stable';
  }

  String getTendanceDescription(TypeConstante type) {
    final tendance = getTendance(type);
    if (tendance.contains('Hausse')) {
      return '📈 $tendance - Surveillance recommandée';
    } else if (tendance.contains('Baisse')) {
      return '📉 $tendance - À surveiller';
    }
    return '✅ $tendance - Bonne stabilité';
  }

  // ============ DONNÉES POUR GRAPHIQUES ============
  
  List<Map<String, dynamic>> getChartData(TypeConstante type, {int jours = 7}) {
    final filtered = _constantes
        .where((c) => c.typeConstante == type.value)
        .take(jours)
        .toList()
        .reversed
        .toList();
    
    const joursSemaine = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    
    if (filtered.isEmpty) {
      return List.generate(jours, (index) {
        final dayIndex = index % 7;
        return {
          'label': joursSemaine[dayIndex],
          'value': 0.0,
        };
      });
    }
    
    return filtered.map((c) {
      final dayIndex = c.dateMesure.weekday - 1;
      return {
        'label': joursSemaine[dayIndex.clamp(0, 6)],
        'value': c.valeur,
      };
    }).toList();
  }

  Map<String, dynamic> getCircularChartData(TypeConstante type) {
    final valeur = getDerniereValeur(type);
    final maxValue = type == TypeConstante.frequenceCardiaque ? 120 : 
                     type == TypeConstante.temperature ? 40 : 200;
    
    return {
      'value': valeur ?? 0,
      'max': maxValue,
      'percentage': valeur != null ? (valeur / maxValue).clamp(0.0, 1.0) : 0.0,
    };
  }

  // ============ CORRÉLATIONS ============
  
  Future<Map<String, dynamic>> getCorrelations({int jours = 7}) async {
    try {
      final data = await _service.getCorrelationSymptomes(jours: jours);
      _correlations = data['data'] ?? {};
      notifyListeners();
      return _correlations;
    } catch (e) {
      debugPrint('❌ Erreur getCorrelations: $e');
      return {};
    }
  }

  // ============ SEUILS PERSONNALISÉS ============
  
  Future<void> _loadSeuils() async {
    try {
      final data = await _service.getSeuils();
      if (data['data'] is Map) {
        _seuils = Map<String, dynamic>.from(data['data']);
      } else {
        _seuils = {};
      }
    } catch (e) {
      debugPrint('⚠️ Erreur loadSeuils: $e');
      _seuils = {};
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
      await _service.updateSeuils(
        typeConstante: typeConstante,
        minNormal: minNormal,
        maxNormal: maxNormal,
        minAlerte: minAlerte,
        maxAlerte: maxAlerte,
      );
      await _loadSeuils();
    } catch (e) {
      debugPrint('❌ Erreur updateSeuils: $e');
      rethrow;
    }
  }

  Map<String, double>? getSeuil(String typeConstante) {
    final seuil = _seuils[typeConstante];
    if (seuil == null) return null;
    return {
      'minNormal': (seuil['min_normal'] ?? 0).toDouble(),
      'maxNormal': (seuil['max_normal'] ?? 0).toDouble(),
      'minAlerte': (seuil['min_alerte'] ?? 0).toDouble(),
      'maxAlerte': (seuil['max_alerte'] ?? 0).toDouble(),
    };
  }

  // ============ CORRÉLATIONS ENTRE CONSTANTES ============
  
  double? getCorrelation(TypeConstante type1, TypeConstante type2) {
    final valeurs1 = getValeursByType(type1);
    final valeurs2 = getValeursByType(type2);
    
    if (valeurs1.length < 2 || valeurs2.length < 2) return null;
    
    final paired = <double, double>{};
    for (final v1 in valeurs1) {
      for (final v2 in valeurs2) {
        if (v1.dateMesure.day == v2.dateMesure.day &&
            v1.dateMesure.month == v2.dateMesure.month) {
          paired[v1.valeur] = v2.valeur;
          break;
        }
      }
    }
    
    if (paired.length < 2) return null;
    
    final x = paired.keys.toList();
    final y = paired.values.toList();
    
    final meanX = x.reduce((a, b) => a + b) / x.length;
    final meanY = y.reduce((a, b) => a + b) / y.length;
    
    var covariance = 0.0;
    var varX = 0.0;
    var varY = 0.0;
    
    for (int i = 0; i < x.length; i++) {
      final dx = x[i] - meanX;
      final dy = y[i] - meanY;
      covariance += dx * dy;
      varX += dx * dx;
      varY += dy * dy;
    }
    
    if (varX == 0 || varY == 0) return null;
    
    return covariance / sqrt(varX * varY);
  }

  // ============ STATISTIQUES GLOBALES ============
  
  Map<String, dynamic> getGlobalStats() {
    final stats = <String, dynamic>{};
    for (final type in TypeConstante.values) {
      final values = getValeursByType(type);
      if (values.isNotEmpty) {
        stats[type.name] = {
          'total': values.length,
          'moyenne': values.map((c) => c.valeur).reduce((a, b) => a + b) / values.length,
          'min': values.map((c) => c.valeur).reduce((a, b) => a < b ? a : b),
          'max': values.map((c) => c.valeur).reduce((a, b) => a > b ? a : b),
          'derniere': values.first.valeur,
          'statut': getStatut(type),
          'tendance': getTendance(type),
        };
      }
    }
    return stats;
  }

  // ============ RÉINITIALISATION ============
  
  void clearData() {
    _constantes.clear();
    _alertes.clear();
    _correlations.clear();
    _seuils.clear();
    _historique.clear();
    _error = null;
    notifyListeners();
  }

  // ============ CORRÉLATIONS AVEC SYMPTÔMES ============
  
  Future<void> _loadCorrelations() async {
    try {
      _correlations = await getCorrelations();
    } catch (e) {
      _correlations = {};
    }
  }

  List<String> getCorrelationInsights() {
    final insights = <String>[];
    
    for (final type in TypeConstante.values) {
      final statut = getStatut(type);
      if (statut == 'Alerte' || statut == 'Critique') {
        insights.add('⚠️ ${type.label} en $statut - Consultez votre médecin');
      }
    }
    
    for (final type in TypeConstante.values) {
      final tendance = getTendance(type);
      if (tendance.contains('Hausse de')) {
        final parts = tendance.split('de ');
        if (parts.length > 1) {
          final pourcentageStr = parts[1].replaceAll('%', '');
          final pourcentage = double.tryParse(pourcentageStr);
          if (pourcentage != null && pourcentage > 10) {
            insights.add('📈 ${type.label} en hausse significative (+${pourcentage.toStringAsFixed(0)}%)');
          }
        }
      }
    }
    
    return insights;
  }
}