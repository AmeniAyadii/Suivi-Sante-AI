import 'package:flutter/material.dart';

class AppColors {
  // Couleurs principales
  static const Color primary = Color(0xFF2563EB);      // Bleu professionnel
  static const Color primaryLight = Color(0xFFDBEAFE);
  static const Color primaryDark = Color(0xFF1D4ED8);
  
  // Couleurs secondaires
  static const Color secondary = Color(0xFF059669);     // Vert santé
  static const Color secondaryLight = Color(0xFFD1FAE5);
  
  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient urgentGradient = LinearGradient(
    colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Niveaux de gravité
  static const Color severityLow = Color(0xFF22C55E);    // Vert
  static const Color severityModerate = Color(0xFFF59E0B); // Orange
  static const Color severityUrgent = Color(0xFFEF4444);   // Rouge
  
  // Messages
  static const Color userBubble = Color(0xFF2563EB);
  static const Color botBubble = Color(0xFFF3F4F6);
  
  // Textes
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textLight = Color(0xFF9CA3AF);
  
  // Fond
  static const Color background = Color(0xFFF8FAFC);
  
  // Statut
  static const Color online = Color(0xFF22C55E);
  static const Color offline = Color(0xFFEF4444);
}