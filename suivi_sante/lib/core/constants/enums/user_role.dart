enum UserRole {
  patient,
  doctor,
  admin;

  static UserRole fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'doctor':
      case 'medecin':
      case 'médecin':
        return UserRole.doctor;
      case 'admin':
        return UserRole.admin;
      default:
        return UserRole.patient;
    }
  }

  String get value => name;

  String get label {
    switch (this) {
      case UserRole.doctor:
        return 'Médecin';
      case UserRole.admin:
        return 'Administrateur';
      case UserRole.patient:
        return 'Patient';
    }
  }
}