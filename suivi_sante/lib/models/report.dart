// lib/models/report.dart
import 'package:flutter/material.dart';

class Report {
  final int id;
  final String title;
  final String type;
  final DateTime dateStart;
  final DateTime dateEnd;
  final String status;
  final DateTime createdAt;
  final Map<String, dynamic>? data;

  Report({
    required this.id,
    required this.title,
    required this.type,
    required this.dateStart,
    required this.dateEnd,
    required this.status,
    required this.createdAt,
    this.data,
  });

  String get typeLabel {
    switch (type) {
      case 'monthly':
        return 'Mensuel';
      case 'quarterly':
        return 'Trimestriel';
      case 'annual':
        return 'Annuel';
      case 'custom':
        return 'Personnalisé';
      default:
        return type;
    }
  }

  String get statusLabel {
    switch (status) {
      case 'completed':
        return 'Terminé';
      case 'pending':
        return 'En cours';
      case 'failed':
        return 'Échoué';
      default:
        return status;
    }
  }

  // ✅ GETTER POUR LA COULEUR DU STATUT
  Color get statusColor {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // ✅ GETTER POUR L'ICÔNE DU STATUT
  IconData get statusIcon {
    switch (status) {
      case 'completed':
        return Icons.check_circle;
      case 'pending':
        return Icons.hourglass_empty;
      case 'failed':
        return Icons.error;
      default:
        return Icons.help;
    }
  }

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      id: json['id'] ?? 0,
      title: json['title'] ?? 'Rapport',
      type: json['type'] ?? 'monthly',
      dateStart: json['date_start'] != null
          ? DateTime.parse(json['date_start'])
          : DateTime.now(),
      dateEnd: json['date_end'] != null
          ? DateTime.parse(json['date_end'])
          : DateTime.now(),
      status: json['status'] ?? 'pending',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      data: json['data'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'type': type,
      'date_start': dateStart.toIso8601String(),
      'date_end': dateEnd.toIso8601String(),
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'data': data,
    };
  }
}