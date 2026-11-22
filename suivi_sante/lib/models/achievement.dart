import 'dart:ui';

import 'package:equatable/equatable.dart';

enum AchievementType {
  medication,
  exercise,
  nutrition,
  sleep,
  consistency,
  streak,
  community,
}

class Achievement extends Equatable {
  final String id;
  final String title;
  final String description;
  final String icon;
  final String colorHex;
  final AchievementType type;
  final int level;
  final int points;
  final DateTime? unlockedAt;
  final bool isUnlocked;
  final Map<String, dynamic>? requirements;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.colorHex,
    required this.type,
    required this.level,
    required this.points,
    this.unlockedAt,
    this.isUnlocked = false,
    this.requirements,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'].toString(),
      title: json['title'] ?? 'Récompense',
      description: json['description'] ?? '',
      icon: json['icon'] ?? '🏅',
      colorHex: json['color_hex'] ?? '#FFD700',
      type: _parseType(json['type']),
      level: json['level'] ?? 1,
      points: json['points'] ?? 0,
      unlockedAt: json['unlocked_at'] != null 
          ? DateTime.parse(json['unlocked_at']) 
          : null,
      isUnlocked: json['is_unlocked'] ?? false,
      requirements: json['requirements'] as Map<String, dynamic>?,
    );
  }

  static AchievementType _parseType(String value) {
    return AchievementType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AchievementType.consistency,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'icon': icon,
      'color_hex': colorHex,
      'type': type.name,
      'level': level,
      'points': points,
      'unlocked_at': unlockedAt?.toIso8601String(),
      'is_unlocked': isUnlocked,
      'requirements': requirements,
    };
  }

  Achievement copyWith({
    String? id,
    String? title,
    String? description,
    String? icon,
    String? colorHex,
    AchievementType? type,
    int? level,
    int? points,
    DateTime? unlockedAt,
    bool? isUnlocked,
    Map<String, dynamic>? requirements,
  }) {
    return Achievement(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      colorHex: colorHex ?? this.colorHex,
      type: type ?? this.type,
      level: level ?? this.level,
      points: points ?? this.points,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      requirements: requirements ?? this.requirements,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    icon,
    colorHex,
    type,
    level,
    points,
    unlockedAt,
    isUnlocked,
    requirements,
  ];
}

// Extension pour les méthodes utilitaires
extension AchievementExtension on Achievement {
  bool get isRecentlyUnlocked {
    if (unlockedAt == null) return false;
    final difference = DateTime.now().difference(unlockedAt!);
    return difference.inDays < 7;
  }

  String get levelDisplay {
    switch (level) {
      case 1:
        return '🥉 Bronze';
      case 2:
        return '🥈 Argent';
      case 3:
        return '🥇 Or';
      case 4:
        return '💎 Platine';
      case 5:
        return '👑 Diamant';
      default:
        return '⭐ Niveau $level';
    }
  }

  String get typeDisplay {
    switch (type) {
      case AchievementType.medication:
        return '💊 Médicaments';
      case AchievementType.exercise:
        return '🏃 Exercice';
      case AchievementType.nutrition:
        return '🍎 Nutrition';
      case AchievementType.sleep:
        return '😴 Sommeil';
      case AchievementType.consistency:
        return '📊 Régularité';
      case AchievementType.streak:
        return '🔥 Série';
      case AchievementType.community:
        return '🤝 Communauté';
    }
  }

  Color getColor() {
    return Color(int.parse(colorHex.replaceFirst('#', ''), radix: 16));
  }
}