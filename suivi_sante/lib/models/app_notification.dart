class AppNotification {
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
  final DateTime? dateEnvoi;
  final DateTime createdAt;

  AppNotification({
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
    this.dateEnvoi,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      titre: json['titre'] ?? '',
      message: json['message'] ?? '',
      type: json['type'] ?? 'info',
      icon: json['icon'],
      couleur: json['couleur'],
      data: json['data'] is Map ? Map<String, dynamic>.from(json['data']) : null,
      lu: json['lu'] == true || json['lu'] == 1,
      lien: json['lien'],
      dateEnvoi: json['date_envoi'] != null
          ? DateTime.tryParse(json['date_envoi'])
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  AppNotification copyWith({bool? lu}) {
    return AppNotification(
      id: id,
      userId: userId,
      titre: titre,
      message: message,
      type: type,
      icon: icon,
      couleur: couleur,
      data: data,
      lu: lu ?? this.lu,
      lien: lien,
      dateEnvoi: dateEnvoi,
      createdAt: createdAt,
    );
  }
}