// lib/models/constante_vitale.dart

import 'package:flutter/material.dart';

class ConstanteVitale {
  final int id;
  final String typeConstante;
  final double valeur;
  final String unite;
  final DateTime dateMesure;
  final String? notes;
  final bool estAnormal;

  ConstanteVitale({
    required this.id,
    required this.typeConstante,
    required this.valeur,
    required this.unite,
    required this.dateMesure,
    this.notes,
    this.estAnormal = false,
  });

  factory ConstanteVitale.fromJson(Map<String, dynamic> json) {
    return ConstanteVitale(
      id: _parseInt(json['id']),
      typeConstante: _parseString(json['type_constante']),
      valeur: _parseDouble(json['valeur']),
      unite: _parseString(json['unite']),
      dateMesure: _parseDateTime(json['date_mesure']),
      notes: json['notes']?.toString(),
      estAnormal: json['est_anormal'] == 1 || json['est_anormal'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
    'type_constante': typeConstante,
    'valeur': valeur,
    'unite': unite,
    'date_mesure': dateMesure.toIso8601String(),
    'notes': notes,
  };

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is num) return value.toInt();
    return 0;
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      final cleaned = value.replaceAll(',', '.');
      return double.tryParse(cleaned) ?? 0.0;
    }
    if (value is num) return value.toDouble();
    return 0.0;
  }

  static String _parseString(dynamic value) {
    if (value == null) return '';
    return value.toString();
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    try {
      return DateTime.parse(value.toString());
    } catch (_) {
      return DateTime.now();
    }
  }

  ConstanteVitale copyWith({
    int? id,
    String? typeConstante,
    double? valeur,
    String? unite,
    DateTime? dateMesure,
    String? notes,
    bool? estAnormal,
  }) {
    return ConstanteVitale(
      id: id ?? this.id,
      typeConstante: typeConstante ?? this.typeConstante,
      valeur: valeur ?? this.valeur,
      unite: unite ?? this.unite,
      dateMesure: dateMesure ?? this.dateMesure,
      notes: notes ?? this.notes,
      estAnormal: estAnormal ?? this.estAnormal,
    );
  }

  @override
  String toString() {
    return 'ConstanteVitale(id: $id, type: $typeConstante, valeur: $valeur $unite, date: $dateMesure)';
  }
}

// ============ ENUM ============

enum TypeConstante {
  tensionSystolique('tension_systolique'),
  tensionDiastolique('tension_diastolique'),
  frequenceCardiaque('frequence_cardiaque'),
  temperature('temperature'),
  glycemie('glycemie'),
  saturationOxygene('saturation_oxygene'),
  poids('poids'),
  imc('IMC');

  final String value;
  const TypeConstante(this.value);
}

// ============ EXTENSION ============

extension TypeConstanteExtension on TypeConstante {
  String get label {
    switch (this) {
      case TypeConstante.tensionSystolique:
        return 'Tension Systolique';
      case TypeConstante.tensionDiastolique:
        return 'Tension Diastolique';
      case TypeConstante.frequenceCardiaque:
        return 'Fréquence Cardiaque';
      case TypeConstante.temperature:
        return 'Température';
      case TypeConstante.glycemie:
        return 'Glycémie';
      case TypeConstante.saturationOxygene:
        return 'Saturation Oxygène';
      case TypeConstante.poids:
        return 'Poids';
      case TypeConstante.imc:
        return 'IMC';
    }
  }

  String get icon {
    switch (this) {
      case TypeConstante.tensionSystolique:
      case TypeConstante.tensionDiastolique:
        return '❤️';
      case TypeConstante.frequenceCardiaque:
        return '💓';
      case TypeConstante.temperature:
        return '🌡️';
      case TypeConstante.glycemie:
        return '🩸';
      case TypeConstante.saturationOxygene:
        return '🫁';
      case TypeConstante.poids:
        return '⚖️';
      case TypeConstante.imc:
        return '📊';
    }
  }

  String get uniteParDefaut {
    switch (this) {
      case TypeConstante.tensionSystolique:
      case TypeConstante.tensionDiastolique:
        return 'mmHg';
      case TypeConstante.frequenceCardiaque:
        return 'BPM';
      case TypeConstante.temperature:
        return '°C';
      case TypeConstante.glycemie:
        return 'g/L';
      case TypeConstante.saturationOxygene:
        return '%';
      case TypeConstante.poids:
        return 'kg';
      case TypeConstante.imc:
        return 'kg/m²';
    }
  }

  // ✅ AJOUT DU GETTER SEUILS
  Map<String, double> get seuils {
    switch (this) {
      case TypeConstante.tensionSystolique:
        return {'min': 90, 'max': 140};
      case TypeConstante.tensionDiastolique:
        return {'min': 60, 'max': 90};
      case TypeConstante.frequenceCardiaque:
        return {'min': 50, 'max': 100};
      case TypeConstante.temperature:
        return {'min': 36.0, 'max': 37.5};
      case TypeConstante.glycemie:
        return {'min': 0.7, 'max': 1.4};
      case TypeConstante.saturationOxygene:
        return {'min': 95, 'max': 100};
      case TypeConstante.poids:
        return {'min': 0, 'max': 300};
      case TypeConstante.imc:
        return {'min': 18.5, 'max': 25};
    }
  }

  // ✅ AJOUT DE LA MÉTHODE getStatut
  String getStatut(double valeur) {
    final seuil = seuils;
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

  // ✅ AJOUT DE LA MÉTHODE isNormal
  bool isNormal(double valeur) {
    final seuil = seuils;
    if (seuil.isEmpty) return true;
    return valeur >= seuil['min']! && valeur <= seuil['max']!;
  }
}