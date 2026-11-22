// lib/models/alerte_sante.dart

import 'package:flutter/material.dart';

class AlerteSante {
  final int id;
  final int userId;
  final TypeAlerte typeAlerte;
  final NiveauGravite niveauGravite;
  final String message;
  final int? constanteId;
  final bool estLue;
  final bool estResolue;
  final DateTime dateCreation;
  final DateTime? dateResolution;
  final String? commentaireResolution;

  AlerteSante({
    required this.id,
    required this.userId,
    required this.typeAlerte,
    required this.niveauGravite,
    required this.message,
    this.constanteId,
    this.estLue = false,
    this.estResolue = false,
    required this.dateCreation,
    this.dateResolution,
    this.commentaireResolution,
  });

  factory AlerteSante.fromJson(Map<String, dynamic> json) {
    return AlerteSante(
      id: _parseInt(json['id']),
      userId: _parseInt(json['user_id']),
      typeAlerte: TypeAlerte.fromString(_parseString(json['type_alerte'])),
      niveauGravite: NiveauGravite.fromString(_parseString(json['niveau_gravite'])),
      message: _parseString(json['message']),
      constanteId: _parseIntNullable(json['constante_id']),
      estLue: json['est_lue'] == 1 || json['est_lue'] == true,
      estResolue: json['est_resolue'] == 1 || json['est_resolue'] == true,
      dateCreation: _parseDateTime(json['date_creation']),
      dateResolution: json['date_resolution'] != null 
          ? _parseDateTime(json['date_resolution']) 
          : null,
      commentaireResolution: json['commentaire_resolution']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type_alerte': typeAlerte.value,
      'niveau_gravite': niveauGravite.value,
      'message': message,
      'constante_id': constanteId,
      'est_lue': estLue ? 1 : 0,
      'est_resolue': estResolue ? 1 : 0,
      'date_creation': dateCreation.toIso8601String(),
      'date_resolution': dateResolution?.toIso8601String(),
      'commentaire_resolution': commentaireResolution,
    };
  }

  // ============ MÉTHODES DE PARSING ROBUSTES ============

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is num) return value.toInt();
    return 0;
  }

  static int? _parseIntNullable(dynamic value) {
    if (value == null) return null;
    return _parseInt(value);
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

  // ============ GETTERS UTILITAIRES ============

  bool get estActive => !estResolue;
  bool get estUrgente => 
      niveauGravite == NiveauGravite.critique || 
      niveauGravite == NiveauGravite.eleve;

  String get niveauGraviteTexte {
    switch (niveauGravite) {
      case NiveauGravite.faible:
        return 'Faible';
      case NiveauGravite.moder:
        return 'Modéré';
      case NiveauGravite.eleve:
        return 'Élevé';
      case NiveauGravite.critique:
        return 'Critique';
    }
  }

  Color get niveauCouleur {
    switch (niveauGravite) {
      case NiveauGravite.faible:
        return Colors.green;
      case NiveauGravite.moder:
        return Colors.orange;
      case NiveauGravite.eleve:
        return Colors.orange.shade800;
      case NiveauGravite.critique:
        return Colors.red;
    }
  }

  IconData get typeIcone {
    switch (typeAlerte) {
      case TypeAlerte.tensionElevee:
      case TypeAlerte.tensionBasse:
        return Icons.heart_broken;
      case TypeAlerte.fievre:
        return Icons.thermostat;
      case TypeAlerte.hypoglycemie:
      case TypeAlerte.hyperglycemie:
        return Icons.bloodtype;
      case TypeAlerte.tachycardie:
      case TypeAlerte.bradycardie:
        return Icons.favorite;
      case TypeAlerte.saturationBasse:
        return Icons.air;
      case TypeAlerte.poidsAnormal:
        return Icons.monitor_weight;
      case TypeAlerte.personnalise:
        return Icons.notifications_active;
      case TypeAlerte.correlation:
        return Icons.analytics;
    }
  }

  String get typeTexte {
    switch (typeAlerte) {
      case TypeAlerte.tensionElevee:
        return 'Hypertension artérielle';
      case TypeAlerte.tensionBasse:
        return 'Hypotension artérielle';
      case TypeAlerte.fievre:
        return 'Fièvre';
      case TypeAlerte.hypoglycemie:
        return 'Hypoglycémie';
      case TypeAlerte.hyperglycemie:
        return 'Hyperglycémie';
      case TypeAlerte.tachycardie:
        return 'Tachycardie';
      case TypeAlerte.bradycardie:
        return 'Bradycardie';
      case TypeAlerte.saturationBasse:
        return 'Désaturation en oxygène';
      case TypeAlerte.poidsAnormal:
        return 'Poids anormal';
      case TypeAlerte.personnalise:
        return 'Alerte personnalisée';
      case TypeAlerte.correlation:
        return 'Corrélation symptômes-constantes';
    }
  }

  String get typeEmoji {
    switch (typeAlerte) {
      case TypeAlerte.tensionElevee:
      case TypeAlerte.tensionBasse:
        return '❤️';
      case TypeAlerte.fievre:
        return '🌡️';
      case TypeAlerte.hypoglycemie:
      case TypeAlerte.hyperglycemie:
        return '🩸';
      case TypeAlerte.tachycardie:
      case TypeAlerte.bradycardie:
        return '💓';
      case TypeAlerte.saturationBasse:
        return '🫁';
      case TypeAlerte.poidsAnormal:
        return '⚖️';
      case TypeAlerte.personnalise:
        return '🔔';
      case TypeAlerte.correlation:
        return '📊';
    }
  }

  String get tempsEcoule {
    final difference = DateTime.now().difference(dateCreation);
    if (difference.inDays >= 1) {
      return 'Il y a ${difference.inDays} jour${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours >= 1) {
      return 'Il y a ${difference.inHours} heure${difference.inHours > 1 ? 's' : ''}';
    } else if (difference.inMinutes >= 1) {
      return 'Il y a ${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''}';
    } else {
      return 'À l\'instant';
    }
  }

  AlerteSante copyWith({
    int? id,
    int? userId,
    TypeAlerte? typeAlerte,
    NiveauGravite? niveauGravite,
    String? message,
    int? constanteId,
    bool? estLue,
    bool? estResolue,
    DateTime? dateCreation,
    DateTime? dateResolution,
    String? commentaireResolution,
  }) {
    return AlerteSante(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      typeAlerte: typeAlerte ?? this.typeAlerte,
      niveauGravite: niveauGravite ?? this.niveauGravite,
      message: message ?? this.message,
      constanteId: constanteId ?? this.constanteId,
      estLue: estLue ?? this.estLue,
      estResolue: estResolue ?? this.estResolue,
      dateCreation: dateCreation ?? this.dateCreation,
      dateResolution: dateResolution ?? this.dateResolution,
      commentaireResolution: commentaireResolution ?? this.commentaireResolution,
    );
  }
}

enum TypeAlerte {
  tensionElevee('tension_elevee'),
  tensionBasse('tension_basse'),
  fievre('fievre'),
  hypoglycemie('hypoglycemie'),
  hyperglycemie('hyperglycemie'),
  tachycardie('tachycardie'),
  bradycardie('bradycardie'),
  saturationBasse('saturation_basse'),
  poidsAnormal('poids_anormal'),
  personnalise('personnalise'),
  correlation('correlation');

  final String value;
  const TypeAlerte(this.value);

  static TypeAlerte fromString(String value) {
    return TypeAlerte.values.firstWhere(
      (e) => e.value == value,
      orElse: () => TypeAlerte.personnalise,
    );
  }
}

enum NiveauGravite {
  faible('faible'),
  moder('modere'),
  eleve('eleve'),
  critique('critique');

  final String value;
  const NiveauGravite(this.value);

  static NiveauGravite fromString(String value) {
    return NiveauGravite.values.firstWhere(
      (e) => e.value == value,
      orElse: () => NiveauGravite.moder,
    );
  }
}