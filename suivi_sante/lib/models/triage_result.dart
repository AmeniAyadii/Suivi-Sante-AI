// lib/models/triage_result.dart
// Modèle représentant le résultat de la prédiction

import 'package:flutter/material.dart';

class TriageResult {
  final int triageAcuity;
  final double confidence;
  final Map<String, double> probabilities;
  final String label;
  final String colorHex;
  final String emoji;
  final String urgency;
  final String recommendation;
  final int maxWaitMinutes;
  final String timestamp;

  TriageResult({
    required this.triageAcuity,
    required this.confidence,
    required this.probabilities,
    required this.label,
    required this.colorHex,
    required this.emoji,
    required this.urgency,
    required this.recommendation,
    required this.maxWaitMinutes,
    required this.timestamp,
  });

  factory TriageResult.fromJson(Map<String, dynamic> json) {
    return TriageResult(
      triageAcuity: json['triage_acuity'] ?? 0,
      confidence: (json['confidence'] ?? 0).toDouble(),
      probabilities: Map<String, double>.from(
        (json['probabilities'] ?? {}).map(
          (k, v) => MapEntry(k, (v as num).toDouble()),
        ),
      ),
      label: json['label'] ?? '',
      colorHex: json['color'] ?? '#000000',
      emoji: json['emoji'] ?? '',
      urgency: json['urgency'] ?? '',
      recommendation: json['recommendation'] ?? '',
      maxWaitMinutes: json['max_wait_minutes'] ?? 0,
      timestamp: json['timestamp'] ?? '',
    );
  }

  /// Convertit le hex en Color Flutter
  Color get color {
    final hex = colorHex.replaceFirst('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }
}