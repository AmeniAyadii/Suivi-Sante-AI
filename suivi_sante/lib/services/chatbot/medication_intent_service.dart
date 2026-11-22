// lib/services/chatbot/medication_intent_service.dart
import 'package:suivi_sante_pro/services/chatbot/medication_service.dart';

class MedicationIntentService {
  final MedicationService _medicationService = MedicationService();

  /// Détecter si le message concerne les médicaments
  bool isMedicationIntent(String message) {
    final lower = message.toLowerCase();
    final keywords = [
      'médicament',
      'médicaments',
      'traitement',
      'doliprane',
      'ibuprofène',
      'aspirine',
      'spasfon',
      'paracétamol',
      'prendre',
      'ajouter',
      'liste',
      'stock',
      'ordonnance',
      'interaction',
      'pris',
      'prise',
      'observance',
    ];

    return keywords.any((keyword) => lower.contains(keyword));
  }

  /// Traiter une intention médicamenteuse
  Future<Map<String, dynamic>> processMedicationIntent(
    String message,
    String userId,
  ) async {
    final lower = message.toLowerCase();

    // 1. Ajouter un médicament
    if (lower.contains('ajouter') ||
        lower.contains('prendre') ||
        lower.contains('nouveau')) {
      return await _handleAddMedication(message, userId);
    }

    // 2. Liste des médicaments
    if (lower.contains('liste') ||
        lower.contains('mes médicaments') ||
        lower.contains('traitements')) {
      return await _handleListMedications(userId);
    }

    // 3. Stock et alertes
    if (lower.contains('stock') ||
        lower.contains('alerte') ||
        lower.contains('plus de')) {
      return await _handleStockAlerts(userId);
    }

    // 4. Prise du jour
    if (lower.contains('aujourd\'hui') ||
        lower.contains('prise') ||
        lower.contains('prendre')) {
      return await _handleTodayTakings(userId);
    }

    // 5. Observance
    if (lower.contains('observance') ||
        lower.contains('suivi') ||
        lower.contains('pris')) {
      return await _handleObservance(userId);
    }

    // 6. Interactions
    if (lower.contains('interaction') || lower.contains('interagit')) {
      return await _handleInteraction(message, userId);
    }

    return {
      'success': false,
      'message':
          'Je n\'ai pas compris votre demande concernant les médicaments. Pouvez-vous préciser ?',
      'type': 'medication_error',
    };
  }

  /// Ajouter un médicament
  Future<Map<String, dynamic>> _handleAddMedication(
    String message,
    String userId,
  ) async {
    try {
      final result = await _medicationService.addMedication(text: message);

      if (result['success']) {
        String response = "✅ Médicament ajouté avec succès !\n\n";
        response += "🩺 **${result['data']['medicament']['nom']}** ";
        response +=
            "(${result['data']['medicament']['dosage'] ?? 'Dosage non spécifié'})\n";
        response +=
            "📅 Prise : ${result['data']['medicament']['horaires_prises']?.join(', ') ?? 'À préciser'}\n";
        response +=
            "💊 Stock : ${result['data']['medicament']['stock_actuel']} comprimés\n";

        // Vérifier les interactions
        if (result['has_interactions'] == true) {
          response += "\n⚠️ **Interactions détectées :**\n";
          for (var interaction in result['interactions'] ?? []) {
            response +=
                "   • ${interaction['medicament_a']} ↔ ${interaction['medicament_b']}\n";
            response += "     💡 ${interaction['recommendation']}\n";
          }
        }

        return {
          'success': true,
          'message': response,
          'type': 'medication_added',
          'data': result['data'],
        };
      } else {
        return {
          'success': false,
          'message':
              '❌ Erreur lors de l\'ajout du médicament. Veuillez réessayer.',
          'type': 'medication_error',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': '❌ Une erreur est survenue : $e',
        'type': 'medication_error',
      };
    }
  }

  /// Lister les médicaments
  Future<Map<String, dynamic>> _handleListMedications(String userId) async {
    try {
      final medications = await _medicationService.getMedications();

      if (medications.isEmpty) {
        return {
          'success': true,
          'message':
              '📋 Vous n\'avez aucun médicament enregistré. Souhaitez-vous en ajouter un ?',
          'type': 'medication_list_empty',
        };
      }

      String response = "📋 **Vos médicaments :**\n\n";
      for (var med in medications) {
        response += "🩺 **${med['nom']}**";
        if (med['dosage'] != null) {
          response += " (${med['dosage']})";
        }
        response += "\n";
        response += "   💊 Stock : ${med['stock_actuel']} comprimés\n";
        response +=
            "   📅 ${med['horaires_prises']?.join(', ') ?? 'Horaires non définis'}\n";
        response +=
            "   📊 Statut : ${med['statut'] == 'actif' ? '✅ Actif' : '⏸️ Inactif'}\n\n";
      }

      return {
        'success': true,
        'message': response,
        'type': 'medication_list',
        'data': medications,
      };
    } catch (e) {
      return {
        'success': false,
        'message': '❌ Erreur lors du chargement de la liste : $e',
        'type': 'medication_error',
      };
    }
  }

  /// Vérifier les alertes de stock
  Future<Map<String, dynamic>> _handleStockAlerts(String userId) async {
    try {
      final result = await _medicationService.checkStockAlerts();

      if (!result['has_alerts']) {
        return {
          'success': true,
          'message': '✅ Tous vos médicaments sont bien approvisionnés !',
          'type': 'stock_alerts_ok',
        };
      }

      String response = "⚠️ **Alertes de stock :**\n\n";
      for (var alert in result['alerts']) {
        final emoji = alert['severity'] == 'danger' ? '🚨' : '⚠️';
        response += "$emoji **${alert['medicament_nom']}**\n";
        response += "   ${alert['message']}\n";
        if (alert['action'] == 'renew_prescription') {
          response +=
              "   💡 Souhaitez-vous que je prépare un message pour votre médecin ?\n";
        }
        response += "\n";
      }

      return {
        'success': true,
        'message': response,
        'type': 'stock_alerts',
        'data': result['alerts'],
      };
    } catch (e) {
      return {
        'success': false,
        'message': '❌ Erreur lors de la vérification des stocks : $e',
        'type': 'medication_error',
      };
    }
  }

  /// Voir les prises du jour
  Future<Map<String, dynamic>> _handleTodayTakings(String userId) async {
    try {
      final takings = await _medicationService.getTodayTakings();

      if (takings.isEmpty) {
        return {
          'success': true,
          'message':
              '✅ Aucune prise prévue pour aujourd\'hui. Profitez-en pour vous reposer ! 😊',
          'type': 'today_takings_empty',
        };
      }

      String response = "📅 **Prise du jour :**\n\n";
      for (var taking in takings) {
        final time = DateTime.parse(taking['prise_prevue']);
        response += "🩺 **${taking['medicament']['nom']}**\n";
        response +=
            "   ⏰ Heure : ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}\n";
        response +=
            "   💊 ${taking['medicament']['dosage'] ?? 'Dosage non spécifié'}\n";
        response +=
            "   📊 Statut : ${taking['statut'] == 'prevue' ? '⏳ À prendre' : '✅ Pris'}\n\n";
      }

      return {
        'success': true,
        'message': response,
        'type': 'today_takings',
        'data': takings,
      };
    } catch (e) {
      return {
        'success': false,
        'message': '❌ Erreur lors du chargement des prises : $e',
        'type': 'medication_error',
      };
    }
  }

  /// Voir l'observance
  Future<Map<String, dynamic>> _handleObservance(String userId) async {
    try {
      final result = await _medicationService.getObservanceSummary(
        period: 'week',
      );

      if (!result['success']) {
        return {
          'success': false,
          'message': '❌ Erreur lors du chargement des statistiques.',
          'type': 'medication_error',
        };
      }

      final data = result['data'];
      String response = "📊 **Résumé d'observance (semaine) :**\n\n";
      response += "   • Total des prises : ${data['total']}\n";
      response += "   • Prises effectuées : ${data['prises']} ✅\n";
      response += "   • Prises oubliées : ${data['oubliees']} ❌\n";
      response += "   • Taux d'observance : ${data['taux_observance']}%\n\n";

      if (data['details_par_medicament'] != null &&
          data['details_par_medicament'].isNotEmpty) {
        response += "**Par médicament :**\n";
        for (var detail in data['details_par_medicament']) {
          final emoji = detail['taux'] >= 80
              ? '✅'
              : (detail['taux'] >= 50 ? '⚠️' : '❌');
          response +=
              "   $emoji ${detail['medicament_nom']} : ${detail['taux']}%\n";
        }
      }

      return {
        'success': true,
        'message': response,
        'type': 'observance',
        'data': data,
      };
    } catch (e) {
      return {
        'success': false,
        'message': '❌ Erreur lors du chargement des statistiques : $e',
        'type': 'medication_error',
      };
    }
  }

  /// Vérifier les interactions
  Future<Map<String, dynamic>> _handleInteraction(
    String message,
    String userId,
  ) async {
    // Extraire le nom du médicament du message
    final lower = message.toLowerCase();
    String medicationName = '';

    final commonMedications = [
      'doliprane',
      'ibuprofène',
      'paracétamol',
      'aspirine',
      'spasfon',
    ];

    for (var med in commonMedications) {
      if (lower.contains(med)) {
        medicationName = med;
        break;
      }
    }

    if (medicationName.isEmpty) {
      return {
        'success': false,
        'message': '❌ Quel médicament souhaitez-vous vérifier ?',
        'type': 'medication_error',
      };
    }

    try {
      final result = await _medicationService.checkInteractions(medicationName);

      if (!result['has_interactions']) {
        return {
          'success': true,
          'message': "✅ Aucune interaction détectée pour **$medicationName**.",
          'type': 'interaction_ok',
        };
      }

      String response =
          "⚠️ **Interactions détectées pour $medicationName :**\n\n";
      for (var interaction in result['interactions']) {
        final emoji = interaction['severity'] == 'high'
            ? '🔴'
            : (interaction['severity'] == 'moderate' ? '🟠' : '🟡');
        response +=
            "$emoji **${interaction['medicament_a']}** ↔ **${interaction['medicament_b']}**\n";
        response += "   📝 ${interaction['description']}\n";
        response += "   💡 ${interaction['recommendation']}\n";
        if (interaction['spacing_hours'] > 0) {
          response +=
              "   ⏰ Espacez les prises de ${interaction['spacing_hours']} heures\n";
        }
        response += "\n";
      }

      return {
        'success': true,
        'message': response,
        'type': 'interactions',
        'data': result['interactions'],
      };
    } catch (e) {
      return {
        'success': false,
        'message': '❌ Erreur lors de la vérification des interactions : $e',
        'type': 'medication_error',
      };
    }
  }
}
