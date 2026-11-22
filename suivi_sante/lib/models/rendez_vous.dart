// lib/models/rendez_vous.dart

class RendezVous {
  final int? id;
  final int userId;
  final String titre;
  final String? medecinNom;
  final DateTime dateHeure;
  final String? lieu;
  final String? notes;
  final String statut;
  final bool rappelEnvoye;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  RendezVous({
    this.id,
    required this.userId,
    required this.titre,
    this.medecinNom,
    required this.dateHeure,
    this.lieu,
    this.notes,
    this.statut = 'à_venir',
    this.rappelEnvoye = false,
    this.createdAt,
    this.updatedAt,
  });

  factory RendezVous.fromJson(Map<String, dynamic> json) {
    return RendezVous(
      id: json['id'],
      userId: json['user_id'],
      titre: json['titre'] ?? 'Rendez-vous',
      medecinNom: json['medecin_nom'],
      dateHeure: DateTime.parse(json['date_heure']),
      lieu: json['lieu'],
      notes: json['notes'],
      statut: json['statut'] ?? 'à_venir',
      rappelEnvoye: json['rappel_envoye'] ?? false,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'titre': titre,
      'medecin_nom': medecinNom,
      'date_heure': dateHeure.toIso8601String(),
      'lieu': lieu,
      'notes': notes,
      'statut': statut,
    };
  }

  bool get isAVenir => statut == 'à_venir';
  bool get isPasse => statut == 'passé';
  bool get isAnnule => statut == 'annulé';
  bool get isToday => dateHeure.day == DateTime.now().day &&
                       dateHeure.month == DateTime.now().month &&
                       dateHeure.year == DateTime.now().year;

  String get formattedDate {
    return '${dateHeure.day}/${dateHeure.month}/${dateHeure.year} à ${dateHeure.hour.toString().padLeft(2, '0')}:${dateHeure.minute.toString().padLeft(2, '0')}';
  }
}