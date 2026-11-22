class DoctorAppointment {
  final int id;
  final String titre;
  final String patientNom;
  final String patientTelephone;
  final DateTime dateHeure;
  final int duree;
  final String statut;
  final String type;
  final String? lieu;
  final String? notes;

  DoctorAppointment({
    required this.id,
    required this.titre,
    required this.patientNom,
    required this.patientTelephone,
    required this.dateHeure,
    required this.duree,
    required this.statut,
    required this.type,
    this.lieu,
    this.notes,
  });

  factory DoctorAppointment.fromJson(Map<String, dynamic> json) {
    // ✅ Parse et conversion en heure locale
    final parsedDate = DateTime.parse(json['date_heure'].toString()).toLocal();

    return DoctorAppointment(
      id: json['id'] ?? 0,
      titre: json['titre'] ?? 'RDV',
      patientNom: json['patient_nom'] ?? 'Patient',
      patientTelephone: json['patient_telephone'] ?? '-',
      dateHeure: parsedDate,
      duree: json['duree'] ?? 30,
      statut: json['statut'] ?? 'à_venir',
      type: json['type'] ?? 'Consultation',
      lieu: json['lieu'],
      notes: json['notes'],
    );
  }
}