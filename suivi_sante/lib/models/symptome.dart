import 'package:flutter/material.dart';

class Symptome {
  final int? id;
  final int userId;
  final String description;
  final int niveau;
  final DateTime dateEnregistrement;
  final String? notes;
  final String? type;
  final String? duree;
  final String? frequence;
  final String? status;

  Symptome({
    this.id,
    required this.userId,
    required this.description,
    required this.niveau,
    required this.dateEnregistrement,
    this.notes,
    this.type,
    this.duree,
    this.frequence,
    this.status,
  });

  factory Symptome.fromJson(Map<String, dynamic> json) {
    return Symptome(
      id: json['id'],
      userId: json['user_id'],
      description: json['description'] ?? '',
      niveau: json['niveau'] ?? 1,
      dateEnregistrement: json['date_enregistrement'] != null
          ? DateTime.parse(json['date_enregistrement'])
          : DateTime.now(),
      notes: json['notes'],
      type: json['type'],
      duree: json['duree'],
      frequence: json['frequence'],
      status: json['status'] ?? 'actif',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'niveau': niveau,
      'type': type,
      'duree': duree,
      'frequence': frequence,
      'notes': notes,
      'status': status,
    };
  }

  String get severityLabel {
    if (niveau <= 2) return 'Très léger';
    if (niveau <= 3) return 'Léger';
    if (niveau <= 5) return 'Modéré';
    if (niveau <= 7) return 'Intense';
    if (niveau <= 9) return 'Très intense';
    return 'Extrême';
  }

  Color get severityColor {
    if (niveau <= 3) return Colors.green;
    if (niveau <= 5) return Colors.orange;
    if (niveau <= 7) return Colors.red;
    return Colors.purple;
  }

  IconData get severityIcon {
    if (niveau <= 3) return Icons.sentiment_very_satisfied;
    if (niveau <= 5) return Icons.sentiment_neutral;
    if (niveau <= 7) return Icons.sentiment_dissatisfied;
    return Icons.sentiment_very_dissatisfied;
  }

  String get statusLabel {
    switch (status) {
      case 'actif':
        return 'Actif';
      case 'resolu':
        return 'Résolu';
      case 'en_amelioration':
        return 'En amélioration';
      case 'aggravation':
        return 'Aggravation';
      default:
        return 'Non défini';
    }
  }

  Color get statusColor {
    switch (status) {
      case 'actif':
        return Colors.blue;
      case 'resolu':
        return Colors.green;
      case 'en_amelioration':
        return Colors.orange;
      case 'aggravation':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData get typeIcon {
    switch (type) {
      case 'douleur':
        return Icons.healing;
      case 'fatigue':
        return Icons.battery_alert;
      case 'digestif':
        return Icons.restaurant;
      case 'respiratoire':
        return Icons.air;
      case 'neurologique':
        return Icons.psychology;
      case 'cardiaque':
        return Icons.favorite;
      case 'musculaire':
        return Icons.fitness_center;
      case 'cutane':
        return Icons.pin;
      default:
        return Icons.medical_services;
    }
  }

  String get typeLabel {
    switch (type) {
      case 'douleur':
        return 'Douleur';
      case 'fatigue':
        return 'Fatigue';
      case 'digestif':
        return 'Digestif';
      case 'respiratoire':
        return 'Respiratoire';
      case 'neurologique':
        return 'Neurologique';
      case 'cardiaque':
        return 'Cardiaque';
      case 'musculaire':
        return 'Musculaire';
      case 'cutane':
        return 'Cutane';
      default:
        return 'Général';
    }
  }
}