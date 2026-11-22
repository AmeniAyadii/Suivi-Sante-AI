import 'dart:ui';

import 'package:flutter/material.dart';

class NEWS2Score {
  // Seuils d'alerte [citation:5]
  static const int SCORE_URGENT = 5;
  static const int SCORE_EMERGENCY = 7;

  static int calculate({
    required int respirationRate,
    required int oxygenSaturation,
    required bool onOxygen,
    required int pulseRate,
    required int systolicBP,
    required double temperature,
  }) {
    int score = 0;

    // Fréquence respiratoire (par minute)
    if (respirationRate <= 8) score += 3;
    else if (respirationRate <= 11) score += 1;
    else if (respirationRate <= 20) score += 0;
    else if (respirationRate <= 24) score += 1;
    else score += 3;

    // Saturation en oxygène (%)
    if (oxygenSaturation <= 91) score += 3;
    else if (oxygenSaturation <= 93) score += 2;
    else if (oxygenSaturation <= 95) score += 1;
    else score += 0;

    // Oxygénothérapie
    score += onOxygen ? 2 : 0;

    // Pouls (par minute)
    if (pulseRate <= 40) score += 3;
    else if (pulseRate <= 50) score += 1;
    else if (pulseRate <= 90) score += 0;
    else if (pulseRate <= 110) score += 1;
    else if (pulseRate <= 130) score += 2;
    else score += 3;

    // Pression systolique (mmHg)
    if (systolicBP <= 90) score += 3;
    else if (systolicBP <= 100) score += 2;
    else if (systolicBP <= 110) score += 1;
    else if (systolicBP <= 219) score += 0;
    else score += 3;

    // Température (°C)
    if (temperature <= 35.0) score += 3;
    else if (temperature <= 36.0) score += 1;
    else if (temperature <= 38.0) score += 0;
    else if (temperature <= 39.0) score += 1;
    else score += 3;

    return score;
  }

  static String getAlertLevel(int score) {
    if (score >= SCORE_EMERGENCY) return '🚨 URGENCE VITALE - Appelez les secours';
    if (score >= SCORE_URGENT) return '⚠️ URGENCE - Consultez un médecin dans l\'heure';
    if (score >= 3) return '⚡ Surveillance recommandée';
    return '✅ Tout va bien';
  }

  static Color getAlertColor(int score) {
    if (score >= SCORE_EMERGENCY) return Colors.red;
    if (score >= SCORE_URGENT) return Colors.orange;
    if (score >= 3) return Colors.yellow;
    return Colors.green;
  }
}