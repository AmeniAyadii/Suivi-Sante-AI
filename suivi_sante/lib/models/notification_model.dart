// lib/models/notification_model.dart
class NotificationModel {
  final int id;
  final int userId;
  final String titre;
  final String message;
  final String type;
  final String? icon;
  final String? couleur;
  final Map<String, dynamic>? data;
  final bool lu;
  final String? lien;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.titre,
    required this.message,
    required this.type,
    this.icon,
    this.couleur,
    this.data,
    required this.lu,
    this.lien,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      titre: json['titre'] ?? '',
      message: json['message'] ?? '',
      type: json['type'] ?? 'info',
      icon: json['icon'],
      couleur: json['couleur'],
      data: json['data'] is Map ? json['data'] : null,
      lu: json['lu'] ?? false,
      lien: json['lien'],
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'titre': titre,
      'message': message,
      'type': type,
      'icon': icon,
      'couleur': couleur,
      'data': data,
      'lu': lu,
      'lien': lien,
      'created_at': createdAt.toIso8601String(),
    };
  }
}