// lib/models/tension_measure.dart

import 'package:flutter/material.dart';

class TensionMeasure {
  final int? id;
  final int systolic;
  final int diastolic;
  final int? heartRate;
  final DateTime measureDate;
  final String? notes;
  final String? category;
  final String? position;     // ✅ Ajouté pour la position (assis, debout, couché)
  final String? arm;          // ✅ Ajouté pour le bras (gauche, droit)
  final bool? isPremium;      // ✅ Ajouté pour les fonctionnalités premium

  TensionMeasure({
    this.id,
    required this.systolic,
    required this.diastolic,
    this.heartRate,
    required this.measureDate,
    this.notes,
    this.category,
    this.position,
    this.arm,
    this.isPremium,
  });

  factory TensionMeasure.fromJson(Map<String, dynamic> json) {
    return TensionMeasure(
      id: json['id'],
      systolic: json['systolic']?.toInt() ?? 0,
      diastolic: json['diastolic']?.toInt() ?? 0,
      heartRate: json['heart_rate']?.toInt(),
      measureDate: json['measure_date'] != null
          ? DateTime.parse(json['measure_date'])
          : DateTime.now(),
      notes: json['notes'],
      category: json['category'],
      position: json['position'] ?? 'assis',
      arm: json['arm'] ?? 'gauche',
      isPremium: json['is_premium'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'systolic': systolic,
      'diastolic': diastolic,
      'heart_rate': heartRate,
      'measure_date': measureDate.toIso8601String(),
      'notes': notes,
      'position': position,
      'arm': arm,
      'is_premium': isPremium,
    };
  }

  // ==================== GETTERS ====================

  String get formattedDate => 
      '${_dayName(measureDate.weekday)} ${measureDate.day}/${measureDate.month}';

  String get formattedTime =>
      '${measureDate.hour.toString().padLeft(2, '0')}:${measureDate.minute.toString().padLeft(2, '0')}';

  String get formattedDateTime =>
      '$formattedDate à $formattedTime';

  String get formattedFullDate =>
      '${measureDate.day}/${measureDate.month}/${measureDate.year}';

  String get formattedFullDateTime =>
      '$formattedFullDate à $formattedTime';

  String get formattedTimeLeft {
    final now = DateTime.now();
    final diff = now.difference(measureDate);
    
    if (diff.inDays > 0) {
      return 'Il y a ${diff.inDays} jour${diff.inDays > 1 ? 's' : ''}';
    } else if (diff.inHours > 0) {
      return 'Il y a ${diff.inHours} heure${diff.inHours > 1 ? 's' : ''}';
    } else if (diff.inMinutes > 0) {
      return 'Il y a ${diff.inMinutes} minute${diff.inMinutes > 1 ? 's' : ''}';
    } else {
      return 'À l\'instant';
    }
  }

  String get readingText =>
      '$systolic/$diastolic ${heartRate != null ? '($heartRate bpm)' : ''}';

  // ==================== CATÉGORISATION ====================

  String get categoryLabel {
    switch (category) {
      case 'low':
        return 'Basse';
      case 'high':
        return 'Élevée';
      case 'crisis':
        return 'Crise';
      default:
        return 'Normale';
    }
  }

  Color get statusColor {
    switch (category) {
      case 'low':
        return Colors.blue;
      case 'high':
        return Colors.orange;
      case 'crisis':
        return Colors.red;
      default:
        return Colors.green;
    }
  }

  Color get backgroundColor {
    return statusColor.withOpacity(0.1);
  }

  IconData get statusIcon {
    switch (category) {
      case 'low':
        return Icons.arrow_downward;
      case 'high':
        return Icons.arrow_upward;
      case 'crisis':
        return Icons.warning_amber_rounded;
      default:
        return Icons.check_circle_rounded;
    }
  }

  String get statusDescription {
    switch (category) {
      case 'low':
        return 'Tension basse - Surveillez vos symptômes';
      case 'high':
        return 'Tension élevée - Consultez un médecin';
      case 'crisis':
        return '⚠️ Crise hypertensive - Urgence médicale !';
      default:
        return 'Tension normale - Continuez vos bonnes habitudes';
    }
  }

  // ==================== VALIDATION ====================

  bool get isLow => category == 'low';
  bool get isHigh => category == 'high';
  bool get isCrisis => category == 'crisis';
  bool get isNormal => category == 'normal' || category == null;

  bool get hasHeartRate => heartRate != null && heartRate! > 0;

  bool get isValid => systolic > 0 && diastolic > 0;

  // ==================== MÉTHODES UTILITAIRES ====================

  TensionMeasure copyWith({
    int? id,
    int? systolic,
    int? diastolic,
    int? heartRate,
    DateTime? measureDate,
    String? notes,
    String? category,
    String? position,
    String? arm,
    bool? isPremium,
  }) {
    return TensionMeasure(
      id: id ?? this.id,
      systolic: systolic ?? this.systolic,
      diastolic: diastolic ?? this.diastolic,
      heartRate: heartRate ?? this.heartRate,
      measureDate: measureDate ?? this.measureDate,
      notes: notes ?? this.notes,
      category: category ?? this.category,
      position: position ?? this.position,
      arm: arm ?? this.arm,
      isPremium: isPremium ?? this.isPremium,
    );
  }

  Map<String, dynamic> toJsonWithId() {
    return {
      ...toJson(),
      'id': id,
    };
  }

  // ==================== PRIVÉES ====================

  String _dayName(int day) {
    const days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    return days[day - 1];
  }

  // ==================== COMPARAISON ====================

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TensionMeasure &&
        other.id == id &&
        other.systolic == systolic &&
        other.diastolic == diastolic &&
        other.measureDate == measureDate;
  }

  @override
  int get hashCode => id.hashCode ^ systolic.hashCode ^ diastolic.hashCode ^ measureDate.hashCode;

  @override
  String toString() {
    return 'TensionMeasure(id: $id, systolic: $systolic, diastolic: $diastolic, date: $formattedDateTime)';
  }
}