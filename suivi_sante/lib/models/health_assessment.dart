import 'package:flutter/material.dart';

class HealthAssessment {
  final int? id;
  final int userId;
  final DateTime assessmentDate;
  final double? weight;
  final double? height;
  final double? bmi;
  final int? bloodPressureSystolic;
  final int? bloodPressureDiastolic;
  final int? heartRate;
  final double? temperature;
  final double? bloodSugar;
  final double? cholesterol;
  final double? sleepHours;
  final int? exerciseMinutes;
  final int? waterIntake;
  final int? stressLevel;
  final String? mood;
  final String? notes;
  final int? overallScore;
  final List<String>? recommendations;
  final String? status;

  HealthAssessment({
    this.id,
    required this.userId,
    required this.assessmentDate,
    this.weight,
    this.height,
    this.bmi,
    this.bloodPressureSystolic,
    this.bloodPressureDiastolic,
    this.heartRate,
    this.temperature,
    this.bloodSugar,
    this.cholesterol,
    this.sleepHours,
    this.exerciseMinutes,
    this.waterIntake,
    this.stressLevel,
    this.mood,
    this.notes,
    this.overallScore,
    this.recommendations,
    this.status,
  });

  factory HealthAssessment.fromJson(Map<String, dynamic> json) {
    return HealthAssessment(
      id: json['id'],
      userId: json['user_id'],
      assessmentDate: DateTime.parse(json['assessment_date']),
      weight: json['weight']?.toDouble(),
      height: json['height']?.toDouble(),
      bmi: json['bmi']?.toDouble(),
      bloodPressureSystolic: json['blood_pressure_systolic'],
      bloodPressureDiastolic: json['blood_pressure_diastolic'],
      heartRate: json['heart_rate'],
      temperature: json['temperature']?.toDouble(),
      bloodSugar: json['blood_sugar']?.toDouble(),
      cholesterol: json['cholesterol']?.toDouble(),
      sleepHours: json['sleep_hours']?.toDouble(),
      exerciseMinutes: json['exercise_minutes'],
      waterIntake: json['water_intake'],
      stressLevel: json['stress_level'],
      mood: json['mood'],
      notes: json['notes'],
      overallScore: json['overall_score'],
      recommendations: json['recommendations'] != null
          ? List<String>.from(json['recommendations'])
          : null,
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'assessment_date': assessmentDate.toIso8601String(),
      'weight': weight,
      'height': height,
      'bmi': bmi,
      'blood_pressure_systolic': bloodPressureSystolic,
      'blood_pressure_diastolic': bloodPressureDiastolic,
      'heart_rate': heartRate,
      'temperature': temperature,
      'blood_sugar': bloodSugar,
      'cholesterol': cholesterol,
      'sleep_hours': sleepHours,
      'exercise_minutes': exerciseMinutes,
      'water_intake': waterIntake,
      'stress_level': stressLevel,
      'mood': mood,
      'notes': notes,
      'overall_score': overallScore,
      'recommendations': recommendations,
      'status': status,
    };
  }

  String get bmiLabel {
    if (bmi == null) return 'Non calculé';
    if (bmi! < 18.5) return 'Insuffisance pondérale';
    if (bmi! < 25) return 'Poids normal';
    if (bmi! < 30) return 'Surpoids';
    if (bmi! < 35) return 'Obésité modérée';
    if (bmi! < 40) return 'Obésité sévère';
    return 'Obésité morbide';
  }

  Color get bmiColor {
    if (bmi == null) return Colors.grey;
    if (bmi! < 18.5) return Colors.orange;
    if (bmi! < 25) return Colors.green;
    if (bmi! < 30) return Colors.yellow;
    if (bmi! < 35) return Colors.orange;
    if (bmi! < 40) return Colors.red;
    return Colors.red;
  }

  String get bloodPressureLabel {
    if (bloodPressureSystolic == null || bloodPressureDiastolic == null) {
      return 'Non mesuré';
    }
    if (bloodPressureSystolic! < 120 && bloodPressureDiastolic! < 80) {
      return 'Normale';
    }
    if (bloodPressureSystolic! < 130 && bloodPressureDiastolic! < 80) {
      return 'Élevée';
    }
    if (bloodPressureSystolic! < 140 && bloodPressureDiastolic! < 90) {
      return 'Hypertension stade 1';
    }
    return 'Hypertension stade 2';
  }

  String get overallScoreLabel {
    if (overallScore == null) return 'Non évalué';
    if (overallScore! >= 90) return 'Excellente';
    if (overallScore! >= 75) return 'Bonne';
    if (overallScore! >= 60) return 'Moyenne';
    if (overallScore! >= 40) return 'À améliorer';
    return 'Critique';
  }

  Color get overallScoreColor {
    if (overallScore == null) return Colors.grey;
    if (overallScore! >= 90) return Colors.green;
    if (overallScore! >= 75) return Colors.lightGreen;
    if (overallScore! >= 60) return Colors.orange;
    if (overallScore! >= 40) return Colors.deepOrange;
    return Colors.red;
  }
}