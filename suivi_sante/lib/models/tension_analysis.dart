// lib/models/tension_analysis.dart

import 'package:flutter/material.dart';

class TensionAnalysis {
  final String summary;
  final String recommendation;
  final String severityLevel;
  final Map<String, dynamic>? details;
  final Map<String, dynamic>? statistics;
  final Map<String, dynamic>? predictions;

  TensionAnalysis({
    required this.summary,
    required this.recommendation,
    required this.severityLevel,
    this.details,
    this.statistics,
    this.predictions,
  });

  factory TensionAnalysis.fromJson(Map<String, dynamic> json) {
    return TensionAnalysis(
      summary: json['summary'] ?? '',
      recommendation: json['recommendation'] ?? '',
      severityLevel: json['severity_level'] ?? 'normal',
      details: json['details'],
      statistics: json['statistics'],
      predictions: json['predictions'],
    );
  }

  Color get severityColor {
    switch (severityLevel) {
      case 'danger':
        return Colors.red;
      case 'warning':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  IconData get severityIcon {
    switch (severityLevel) {
      case 'danger':
        return Icons.error;
      case 'warning':
        return Icons.warning;
      default:
        return Icons.check_circle;
    }
  }

  String get severityLabel {
    switch (severityLevel) {
      case 'danger':
        return '⚠️ Urgent';
      case 'warning':
        return '⚠️ Attention';
      default:
        return '✅ Normal';
    }
  }
}