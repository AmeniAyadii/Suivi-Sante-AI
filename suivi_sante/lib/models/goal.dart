// lib/models/goal.dart
import 'package:equatable/equatable.dart';

enum GoalCategory {
  medication,
  exercise,
  nutrition,
  sleep,
  hydration,
  weight,
  bloodPressure,
  bloodSugar,
  stress,
  other,
}

enum GoalStatus {
  notStarted,
  inProgress,
  completed,
  failed,
}

class GoalMilestone {
  final String id;
  final String title;
  final double targetValue;
  final bool isCompleted;
  final DateTime? completedDate;

  GoalMilestone({
    required this.id,
    required this.title,
    required this.targetValue,
    this.isCompleted = false,
    this.completedDate,
  });

  factory GoalMilestone.fromJson(Map<String, dynamic> json) {
    return GoalMilestone(
      id: json['id'].toString(),
      title: json['title'] ?? '',
      targetValue: _parseDouble(json['target_value']),
      isCompleted: json['is_completed'] ?? false,
      completedDate: json['completed_date'] != null 
          ? DateTime.parse(json['completed_date']) 
          : null,
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'target_value': targetValue,
    };
  }
}

class Goal extends Equatable {
  final String id;
  final String title;
  final String? description;
  final GoalCategory category;
  final double targetValue;
  final double currentValue;
  final String unit;
  final GoalStatus status;
  final DateTime startDate;
  final DateTime? targetDate;
  final DateTime? completedDate;
  final int progressPercentage;
  final List<GoalMilestone> milestones;
  final bool isRecurring;
  final String? recurrencePattern;
  final List<String> reminders;
  final String icon;
  final String colorHex;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Goal({
    required this.id,
    required this.title,
    this.description,
    required this.category,
    required this.targetValue,
    required this.currentValue,
    required this.unit,
    required this.status,
    required this.startDate,
    this.targetDate,
    this.completedDate,
    required this.progressPercentage,
    this.milestones = const [],
    this.isRecurring = false,
    this.recurrencePattern,
    this.reminders = const [],
    this.icon = '🎯',
    this.colorHex = '#4CAF50',
    required this.createdAt,
    required this.updatedAt,
  });

  double get progress => progressPercentage / 100;
  bool get isCompleted => status == GoalStatus.completed;
  
  bool get isOverdue {
    if (targetDate == null) return false;
    return targetDate!.isBefore(DateTime.now()) && !isCompleted;
  }

  String get timeRemaining {
    if (targetDate == null) return 'Pas de date limite';
    
    final difference = targetDate!.difference(DateTime.now());
    if (difference.isNegative) return 'Dépassé';
    
    final days = difference.inDays;
    if (days > 30) {
      final months = (days / 30).floor();
      return '$months mois restants';
    } else if (days > 7) {
      final weeks = (days / 7).floor();
      return '$weeks semaines restantes';
    } else if (days > 1) {
      return '$days jours restants';
    } else if (days == 1) {
      return '1 jour restant';
    } else {
      final hours = difference.inHours;
      return '$hours heures restantes';
    }
  }

  // ✅ Conversion Flutter -> Laravel (snake_case)
  String _categoryToLaravelFormat() {
    switch (category) {
      case GoalCategory.bloodPressure:
        return 'blood_pressure';
      case GoalCategory.bloodSugar:
        return 'blood_sugar';
      case GoalCategory.stress:
        return 'stress';
      default:
        return category.name;
    }
  }

  // ✅ Conversion Laravel -> Flutter
  static GoalCategory _parseCategoryFromLaravel(String value) {
    switch (value) {
      case 'blood_pressure':
        return GoalCategory.bloodPressure;
      case 'blood_sugar':
        return GoalCategory.bloodSugar;
      case 'stress':
        return GoalCategory.stress;
      default:
        return GoalCategory.values.firstWhere(
          (e) => e.name == value,
          orElse: () => GoalCategory.other,
        );
    }
  }

  static GoalStatus _parseStatus(String value) {
    return GoalStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => GoalStatus.notStarted,
    );
  }

  // ✅ Parseur de nombres sécurisé
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is double) return value.toInt();
    return 0;
  }

  factory Goal.fromJson(Map<String, dynamic> json) {
    return Goal(
      id: json['id'].toString(),
      title: json['title'] ?? '',
      description: json['description'],
      category: _parseCategoryFromLaravel(json['category'] ?? 'other'),
      targetValue: _parseDouble(json['target_value']),
      currentValue: _parseDouble(json['current_value']),
      unit: json['unit'] ?? '',
      status: _parseStatus(json['status'] ?? 'not_started'),
      startDate: json['start_date'] != null 
          ? DateTime.parse(json['start_date']) 
          : DateTime.now(),
      targetDate: json['target_date'] != null 
          ? DateTime.parse(json['target_date']) 
          : null,
      completedDate: json['completed_date'] != null 
          ? DateTime.parse(json['completed_date']) 
          : null,
      progressPercentage: _parseInt(json['progress_percentage']),
      milestones: (json['milestones'] as List?)
          ?.map((e) => GoalMilestone.fromJson(e))
          .toList() ?? [],
      isRecurring: json['is_recurring'] ?? false,
      recurrencePattern: json['recurrence_pattern'],
      reminders: (json['reminders'] as List?)?.cast<String>() ?? [],
      icon: json['icon'] ?? '🎯',
      colorHex: json['color_hex'] ?? '#4CAF50',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'category': _categoryToLaravelFormat(),
      'target_value': targetValue,
      'unit': unit,
      'target_date': targetDate?.toIso8601String(),
      'start_date': startDate.toIso8601String(),
      'is_recurring': isRecurring,
      'recurrence_pattern': recurrencePattern,
      'icon': icon,
      'color_hex': colorHex,
      'milestones': milestones.map((e) => e.toJson()).toList(),
      'reminders': reminders,
    };
  }

  Goal copyWith({
    String? id,
    String? title,
    String? description,
    GoalCategory? category,
    double? targetValue,
    double? currentValue,
    String? unit,
    GoalStatus? status,
    DateTime? startDate,
    DateTime? targetDate,
    DateTime? completedDate,
    int? progressPercentage,
    List<GoalMilestone>? milestones,
    bool? isRecurring,
    String? recurrencePattern,
    List<String>? reminders,
    String? icon,
    String? colorHex,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Goal(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      targetValue: targetValue ?? this.targetValue,
      currentValue: currentValue ?? this.currentValue,
      unit: unit ?? this.unit,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      targetDate: targetDate ?? this.targetDate,
      completedDate: completedDate ?? this.completedDate,
      progressPercentage: progressPercentage ?? this.progressPercentage,
      milestones: milestones ?? this.milestones,
      isRecurring: isRecurring ?? this.isRecurring,
      recurrencePattern: recurrencePattern ?? this.recurrencePattern,
      reminders: reminders ?? this.reminders,
      icon: icon ?? this.icon,
      colorHex: colorHex ?? this.colorHex,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id, title, category, targetValue, currentValue, unit, 
    status, progressPercentage, milestones, isCompleted,
  ];
}