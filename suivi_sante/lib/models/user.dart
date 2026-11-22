import 'package:suivi_sante_pro/core/constants/enums/user_role.dart';


// ==================== MODÈLE DE DONNÉES LARAVEL ====================
class UserProfile {
  final int id;
  final String nom;
  final String email;
  final String? photoUrl;
  final int? age;
  final String? sexe;
  final double? taille;
  final double? poids;
  final String? telephone;
  final String? groupeSanguin;
  final String? allergies;
  final String? maladiesChroniques;
  final DateTime? dateInscription;
  final bool emailVerifie;
  final bool telephoneVerifie;
  final int points;
  final int medicaments;
  final int rendezVous;
  final double santeScore;
  final String? role;
  final bool isActive;

  UserProfile({
    required this.id,
    required this.nom,
    required this.email,
    this.photoUrl,
    this.age,
    this.sexe,
    this.taille,
    this.poids,
    this.telephone,
    this.groupeSanguin,
    this.allergies,
    this.maladiesChroniques,
    this.dateInscription,
    this.emailVerifie = false,
    this.telephoneVerifie = false,
    this.points = 0,
    this.medicaments = 0,
    this.rendezVous = 0,
    this.santeScore = 0.0,
    this.role,
    this.isActive = true,
  });

  // ✅ Factory pour Laravel - Structure standard
  factory UserProfile.fromLaravel(Map<String, dynamic> json) {
    // Laravel retourne souvent : { "user": { ... }, "status": "success" }
    // ou directement { "id": 1, "name": "..." }
    final data = json['user'] ?? json['data'] ?? json;
    
    return UserProfile(
      id: data['id']?.toInt() ?? 0,
      nom: data['nom']?.toString() ?? data['name']?.toString() ?? 'Utilisateur',
      email: data['email']?.toString() ?? '',
      photoUrl: data['photo_url']?.toString() ?? data['avatar']?.toString(),
      age: data['age'] != null ? data['age'].toInt() : null,
      sexe: data['sexe']?.toString() ?? data['gender']?.toString(),
      taille: data['taille'] != null ? data['taille'].toDouble() : null,
      poids: data['poids'] != null ? data['poids'].toDouble() : null,
      telephone: data['telephone']?.toString() ?? data['phone']?.toString(),
      groupeSanguin: data['groupe_sanguin']?.toString() ?? data['blood_type']?.toString(),
      allergies: data['allergies']?.toString(),
      maladiesChroniques: data['maladies_chroniques']?.toString() ?? data['chronic_diseases']?.toString(),
      dateInscription: data['created_at'] != null 
          ? DateTime.tryParse(data['created_at'].toString())
          : data['createdAt'] != null 
              ? DateTime.tryParse(data['createdAt'].toString())
              : null,
      emailVerifie: data['email_verified_at'] != null || data['email_verifie'] == true,
      telephoneVerifie: data['phone_verified_at'] != null || data['telephone_verifie'] == true,
      points: data['points']?.toInt() ?? 0,
      medicaments: data['medicaments']?.toInt() ?? data['medication_count']?.toInt() ?? 0,
      rendezVous: data['rendez_vous']?.toInt() ?? data['appointment_count']?.toInt() ?? 0,
      santeScore: data['sante_score'] != null ? data['sante_score'].toDouble() : 0.0,
      role: data['role']?.toString(),
      isActive: data['is_active'] ?? true,
    );
  }

  // Convertir en Map pour l'envoi vers Laravel
  Map<String, dynamic> toLaravel() {
    return {
      'nom': nom,
      'email': email,
      'age': age,
      'sexe': sexe,
      'taille': taille,
      'poids': poids,
      'telephone': telephone,
      'groupe_sanguin': groupeSanguin,
      'allergies': allergies,
      'maladies_chroniques': maladiesChroniques,
    };
  }
}

// ==================== NOUVELLE CLASSE USER POUR LES RÔLES ====================
class User {
  final int id;
  final String nom;
  final String email;
  final int? age;
  final String? sexe;
  final double? taille;
  final double? poids;
  final String? groupeSanguin;
  final String? allergies;
  final String? maladiesChroniques;
  final String? telephone;
  final bool isPremium;
  final String role;
  final String? specialite;
  final bool isActive;

  User({
    required this.id,
    required this.nom,
    required this.email,
    this.age,
    this.sexe,
    this.taille,
    this.poids,
    this.groupeSanguin,
    this.allergies,
    this.maladiesChroniques,
    this.telephone,
    this.isPremium = false,
    this.role = 'patient',
    this.specialite,
    this.isActive = true,
  });

  // ✅ Helper : convertir le rôle en enum
  UserRole get userRole => UserRole.fromString(role);

  // ✅ Factory depuis le JSON Laravel
  factory User.fromJson(Map<String, dynamic> json) {
    final data = json['user'] ?? json['data'] ?? json;
    return User(
      id: data['id']?.toInt() ?? 0,
      nom: data['nom']?.toString() ?? '',
      email: data['email']?.toString() ?? '',
      age: data['age'] != null ? data['age'].toInt() : null,
      sexe: data['sexe']?.toString(),
      taille: data['taille'] != null
          ? double.tryParse(data['taille'].toString())
          : null,
      poids: data['poids'] != null
          ? double.tryParse(data['poids'].toString())
          : null,
      groupeSanguin: data['groupe_sanguin']?.toString(),
      allergies: data['allergies']?.toString(),
      maladiesChroniques: data['maladies_chroniques']?.toString(),
      telephone: data['telephone']?.toString(),
      //isPremium: data['is_premium'] ?? false,
      isPremium: data['is_premium'] == 1 || data['is_premium'] == true,
      role: data['role']?.toString() ?? 'patient',
      specialite: data['specialite']?.toString(),
      isActive: data['is_active'] ?? true,
    );
  }

  // ✅ Convertir en JSON pour stockage local
  Map<String, dynamic> toJson() => {
    'id': id,
    'nom': nom,
    'email': email,
    'age': age,
    'sexe': sexe,
    'taille': taille,
    'poids': poids,
    'groupe_sanguin': groupeSanguin,
    'allergies': allergies,
    'maladies_chroniques': maladiesChroniques,
    'telephone': telephone,
    'is_premium': isPremium,
    'role': role,
    'specialite': specialite,
    'is_active': isActive,
  };
}