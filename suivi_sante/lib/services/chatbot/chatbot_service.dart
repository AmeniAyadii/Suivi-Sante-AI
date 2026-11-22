import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:suivi_sante_pro/config/app_config.dart';
import 'package:suivi_sante_pro/services/chatbot/appointment_service.dart';

class ChatbotException implements Exception {
  final String message;
  final int? statusCode;

  ChatbotException(this.message, {this.statusCode});

  String getUserFriendlyMessage() {
    if (statusCode == 401) {
      return '🔒 Session expirée. Veuillez vous reconnecter.';
    } else if (statusCode == 404) {
      return '🔍 Service non trouvé. Vérifiez la configuration.';
    } else if (statusCode == 500) {
      return '⚠️ Erreur serveur. Réessayez plus tard.';
    } else if (message.contains('timeout')) {
      return '⏰ Le serveur ne répond pas. Vérifiez votre connexion.';
    }
    return message;
  }
}

class ChatbotService {
  static String get baseUrl {
    final url = AppConfig.baseUrl;
    return url.endsWith('/') ? url : '$url/';
  }

  /// ✅ Récupérer le token (même clé que ApiService)
  // lib/services/chatbot/chatbot_service.dart

  /// ✅ Récupérer le token (utiliser la même clé que ApiService)
  // lib/services/chatbot/chatbot_service.dart

  /// ✅ Récupérer le token (utiliser 'token' comme dans AuthService)
  static Future<String?> _getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // ✅ Utiliser 'token' (pas 'auth_token')
      final token = prefs.getString('token');
      print(
        '🔑 Token récupéré: ${token != null ? '✅ Présent (${token.substring(0, 10)}...)' : '❌ Absent'}',
      );
      return token;
    } catch (e) {
      print('❌ Erreur récupération token: $e');
      return null;
    }
  }

  // lib/services/chatbot/chatbot_service.dart

  /// ✅ Vérifier si le service IA est disponible
  static Future<bool> isServiceAvailable() async {
    try {
      final response = await http
          .get(
            Uri.parse('${baseUrl}llm/health'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// ✅ Détecter si le message concerne les médicaments
  static bool isMedicationIntent(String message) {
    final lower = message.toLowerCase();
    final keywords = [
      'médicament',
      'médicaments',
      'traitement',
      'traitements',
      'doliprane',
      'ibuprofène',
      'aspirine',
      'spasfon',
      'paracétamol',
      'amoxicilline',
      'ventoline',
      'imodium',
      'antibiotique',
      'ajouter',
      'prendre',
      'liste',
      'stock',
      'ordonnance',
      'interaction',
      'pris',
      'prise',
      'observance',
      'pilulier',
      'comprimé',
      'gélule',
      'sirop',
      'injection',
      'renouveler',
      'médoc',
      'medoc',
      'cachet',
      'pillule',
    ];
    return keywords.any((keyword) => lower.contains(keyword));
  }

  /// ✅ Traiter une demande de médicaments
  // lib/services/chatbot/chatbot_service.dart

  /// ✅ Traiter une demande de médicaments (CORRIGÉ)
  static Future<Map<String, dynamic>> handleMedicationIntent(
    String message,
  ) async {
    print('🔵 Traitement intention médicamenteuse: $message');

    final lower = message.toLowerCase();

    print('🔍 Vérification des conditions:');
    print(
      '  - ADD: ${lower.contains('ajouter') || lower.contains('ajoute') || lower.contains('nouveau') || (lower.contains('prendre') && (lower.contains('matin') || lower.contains('soir') || lower.contains('midi')))}',
    );
    print(
      '  - LIST: ${lower.contains('liste') || lower.contains('mes') || (lower.contains('tous') && lower.contains('médicament'))}',
    );
    print(
      '  - STOCK: ${lower.contains('stock') || lower.contains('alerte') || lower.contains('manque')}',
    );
    print(
      '  - TODAY: ${lower.contains('aujourd\'hui') || lower.contains('today') || lower.contains('prise') || lower.contains('prendre')}',
    );
    print(
      '  - OBSERVANCE: ${lower.contains('observance') || lower.contains('suivi') || lower.contains('taux')}',
    );
    print(
      '  - INTERACTION: ${lower.contains('interaction') || lower.contains('interagit') || lower.contains('danger')}',
    );
    print(
      '  - RENEW: ${lower.contains('renouveler') || lower.contains('ordonnance')}',
    );

    // ✅ ADD : Ajouter un médicament
    if (lower.contains('ajouter') ||
        lower.contains('ajoute') ||
        lower.contains('nouveau') ||
        (lower.contains('prendre') &&
            (lower.contains('matin') ||
                lower.contains('soir') ||
                lower.contains('midi')))) {
      print('✅ Condition ADD remplie');
      return await _addMedicationFromMessage(message);
    }

    // ✅ LIST : Lister les médicaments
    if (lower.contains('liste') ||
        lower.contains('mes') ||
        (lower.contains('tous') && lower.contains('médicament'))) {
      print('✅ Condition LIST remplie');
      return await _listMedications();
    }

    // ✅ STOCK : Vérifier le stock
    if (lower.contains('stock') ||
        lower.contains('alerte') ||
        lower.contains('manque')) {
      print('✅ Condition STOCK remplie');
      return await _checkStock();
    }

    // ✅ TODAY : Prise du jour (AVEC PLUS DE MOTS-CLÉS)
    if (lower.contains('aujourd\'hui') ||
        lower.contains('today') ||
        lower.contains('prise') ||
        lower.contains('prendre') ||
        lower.contains('jour') && lower.contains('prendre') ||
        lower.contains('quoi') && lower.contains('prendre')) {
      print('✅ Condition TODAY remplie');
      return await _getTodayTakings();
    }

    // ✅ OBSERVANCE : Suivi d'observance
    if (lower.contains('observance') ||
        lower.contains('suivi') ||
        lower.contains('taux')) {
      print('✅ Condition OBSERVANCE remplie');
      return await _getObservance();
    }

    // ✅ INTERACTION : Vérifier les interactions
    if (lower.contains('interaction') ||
        lower.contains('interagit') ||
        lower.contains('danger')) {
      print('✅ Condition INTERACTION remplie');
      return await _checkInteractionFromMessage(message);
    }

    // ✅ RENEW : Renouvellement d'ordonnance
    if (lower.contains('renouveler') || lower.contains('ordonnance')) {
      print('✅ Condition RENEW remplie');
      return await _generateRenewalFromMessage(message);
    }

    print('❌ Aucune condition remplie');
    return {
      'success': false,
      'message':
          'Je n\'ai pas compris votre demande concernant les médicaments. Pouvez-vous préciser ?',
      'type': 'medication_error',
      'severity': 'low',
      'severity_level': 'green',
      'severity_label': '🟢 Information',
    };
  }

  /// ✅ Ajouter un médicament
  // lib/services/chatbot/chatbot_service.dart

  /// ✅ Ajouter un médicament (avec logs détaillés)
  static Future<Map<String, dynamic>> _addMedicationFromMessage(
    String message,
  ) async {
    print('🔵 _addMedicationFromMessage DEBUT');

    try {
      print('🔵 Étape 1: Récupération du token...');
      final token = await _getToken();
      print(
        '🔵 Token: ${token != null ? "Présent (${token.substring(0, 10)}...)" : "Absent"}',
      );

      if (token == null || token.isEmpty) {
        print('❌ Token manquant');
        return {
          'success': false,
          'message': '🔒 Veuillez vous connecter pour ajouter des médicaments.',
          'type': 'medication_error',
        };
      }

      print('🔵 Étape 2: Extraction des informations...');
      final name = _extractMedicationName(message);
      final dosage = _extractDosage(message);
      final times = _extractTimes(message);
      print('🔵 Nom: $name, Dosage: $dosage, Times: $times');

      final body = {
        'text': message,
        if (name.isNotEmpty) 'nom': name,
        if (dosage.isNotEmpty) 'dosage': dosage,
        'stock_actuel': 30,
        if (times.isNotEmpty) 'horaires_prises': times,
      };
      print('🔵 Body: $body');

      // ✅ URL CORRECTE AVEC v1
      final url = '${baseUrl}medications';
      print('🔵 Étape 3: Envoi requête à $url');

      final response = await http
          .post(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));

      print('🔵 Étape 4: Réponse reçue - Statut: ${response.statusCode}');
      print('🔵 Réponse: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        print('🔵 Data décodée: $data');

        if (data['success'] == true) {
          print('✅ Succès!');
          String responseMessage =
              data['message'] ?? '✅ Médicament ajouté avec succès !';

          if (data['data']?['has_interactions'] == true) {
            final interactions = data['data']['interactions'] ?? [];
            if (interactions.isNotEmpty) {
              responseMessage += '\n\n⚠️ **Interactions détectées :**';
              for (var interaction in interactions) {
                responseMessage +=
                    '\n   • ${interaction['medicament_a']} ↔ ${interaction['medicament_b']}';
                if (interaction['spacing_hours'] != null &&
                    interaction['spacing_hours'] > 0) {
                  responseMessage +=
                      ' (⏰ Espacez de ${interaction['spacing_hours']}h)';
                }
              }
            }
          }

          return {
            'success': true,
            'message': responseMessage,
            'type': 'medication_added',
            'severity': data['data']?['has_interactions'] == true
                ? 'moderate'
                : 'low',
            'severity_level': data['data']?['has_interactions'] == true
                ? 'orange'
                : 'green',
            'severity_label': data['data']?['has_interactions'] == true
                ? '🟠 Interaction détectée'
                : '🟢 Ajout réussi',
            'data': data['data'],
          };
        } else {
          print('❌ data["success"] est false');
          return {
            'success': false,
            'message': data['message'] ?? '❌ Erreur lors de l\'ajout.',
            'type': 'medication_error',
          };
        }
      } else if (response.statusCode == 401) {
        print('❌ Token expiré (401)');
        return {
          'success': false,
          'message': '🔒 Session expirée. Veuillez vous reconnecter.',
          'type': 'medication_error',
        };
      } else {
        print('❌ Erreur HTTP ${response.statusCode}');
        return {
          'success': false,
          'message': '❌ Erreur serveur (${response.statusCode}).',
          'type': 'medication_error',
        };
      }
    } catch (e) {
      print('❌ EXCEPTION: $e');
      print('❌ Stack trace: ${StackTrace.current}');
      return {
        'success': false,
        'message': '❌ Erreur de connexion : ${e.toString()}',
        'type': 'medication_error',
      };
    }
  }

  /// ✅ Lister les médicaments
  static Future<Map<String, dynamic>> _listMedications() async {
    try {
      final token = await _getToken();

      if (token == null || token.isEmpty) {
        return {
          'success': false,
          'message': '🔒 Veuillez vous connecter.',
          'type': 'medication_error',
        };
      }

      final url = '${baseUrl}medications';
      print('📤 URL: $url');

      final response = await http
          .get(
            Uri.parse(url),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 15));

      print('📥 Statut liste: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final medications = data['data'] ?? [];

        if (medications.isEmpty) {
          return {
            'success': true,
            'message': '📋 Vous n\'avez aucun médicament enregistré.',
            'type': 'medication_list_empty',
            'severity': 'low',
            'severity_level': 'green',
            'severity_label': '🟢 Liste vide',
          };
        }

        String responseMessage = "📋 **Vos médicaments :**\n\n";
        for (var med in medications) {
          responseMessage += "🩺 **${med['nom']}**";
          if (med['dosage'] != null) {
            responseMessage += " (${med['dosage']})";
          }
          responseMessage += "\n";
          responseMessage +=
              "   💊 Stock : ${med['stock_actuel'] ?? 0} comprimés\n";
          if (med['horaires_prises'] != null &&
              med['horaires_prises'].isNotEmpty) {
            final horaires = med['horaires_prises'] as List;
            responseMessage += "   📅 ${horaires.join(', ')}\n";
          }
          responseMessage +=
              "   📊 Statut : ${med['statut'] == 'actif' ? '✅ Actif' : '⏸️ Inactif'}\n";
          responseMessage += "\n";
        }

        return {
          'success': true,
          'message': responseMessage,
          'type': 'medication_list',
          'severity': 'low',
          'severity_level': 'green',
          'severity_label': '🟢 Liste des médicaments',
          'data': medications,
        };
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'message': '🔒 Session expirée.',
          'type': 'medication_error',
        };
      } else {
        return {
          'success': false,
          'message': '❌ Erreur (${response.statusCode}).',
          'type': 'medication_error',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': '❌ Erreur de connexion : ${e.toString()}',
        'type': 'medication_error',
      };
    }
  }

  /// ✅ Vérifier le stock
  static Future<Map<String, dynamic>> _checkStock() async {
    try {
      final token = await _getToken();

      if (token == null || token.isEmpty) {
        return {
          'success': false,
          'message': '🔒 Veuillez vous connecter.',
          'type': 'medication_error',
        };
      }

      final url = '${baseUrl}medications/stock-alerts';
      print('📤 URL: $url');

      final response = await http
          .get(
            Uri.parse(url),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final alerts = data['data']?['alerts'] ?? [];

        if (alerts.isEmpty) {
          return {
            'success': true,
            'message': '✅ Tous vos médicaments sont bien approvisionnés !',
            'type': 'stock_alerts_ok',
            'severity': 'low',
            'severity_level': 'green',
            'severity_label': '🟢 Stock OK',
          };
        }

        String responseMessage = "⚠️ **Alertes de stock :**\n\n";
        for (var alert in alerts) {
          final emoji = alert['severity'] == 'danger' ? '🚨' : '⚠️';
          responseMessage += "$emoji **${alert['medicament_nom']}**\n";
          responseMessage += "   ${alert['message']}\n\n";
        }

        return {
          'success': true,
          'message': responseMessage,
          'type': 'stock_alerts',
          'severity': 'moderate',
          'severity_level': 'orange',
          'severity_label': '🟠 Stock faible',
          'data': alerts,
        };
      } else {
        return {
          'success': false,
          'message': '❌ Erreur (${response.statusCode}).',
          'type': 'medication_error',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': '❌ Erreur de connexion : ${e.toString()}',
        'type': 'medication_error',
      };
    }
  }

  /// ✅ Obtenir les prises du jour
  /// ✅ Obtenir les prises du jour (CORRIGÉ)
  static Future<Map<String, dynamic>> _getTodayTakings() async {
    try {
      final token = await _getToken();

      if (token == null || token.isEmpty) {
        return {
          'success': false,
          'message': '🔒 Veuillez vous connecter.',
          'type': 'medication_error',
        };
      }

      final url = '${baseUrl}medications/today-takings';
      print('📤 URL: $url');

      final response = await http
          .get(
            Uri.parse(url),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 15));

      print('📥 Statut today-takings: ${response.statusCode}');
      print('📥 Réponse: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final takings = data['data'] ?? [];

        if (takings.isEmpty) {
          // ✅ CORRECT
          return {
            'success': true,
            'message':
                '✅ Aucune prise prévue pour aujourd\'hui. 😊\n\nProfitez de cette journée pour vous reposer !',
            'type': 'today_takings_empty',
            'severity': 'low',
            'severity_level': 'green',
            'severity_label': '🟢 Aucune prise',
          };
          ;
        }

        String responseMessage = "📅 **Prise du jour :**\n\n";
        for (var taking in takings) {
          final time = DateTime.parse(taking['prise_prevue']);
          final med = taking['medicament'] ?? {};
          responseMessage += "🩺 **${med['nom'] ?? 'Médicament'}**\n";
          responseMessage +=
              "   ⏰ ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}\n";
          if (med['dosage'] != null) {
            responseMessage += "   💊 ${med['dosage']}\n";
          }
          final status = taking['statut'] ?? 'prevue';
          final statusLabel = status == 'prevue'
              ? '⏳ À prendre'
              : (status == 'prise' ? '✅ Pris' : '❌ Oublié');
          responseMessage += "   📊 $statusLabel\n\n";
        }

        return {
          'success': true,
          'message': responseMessage,
          'type': 'today_takings',
          'severity': 'low',
          'severity_level': 'green',
          'severity_label': '🟢 Prise du jour',
          'data': takings,
        };
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'message': '🔒 Session expirée.',
          'type': 'medication_error',
        };
      } else {
        print('❌ Erreur HTTP ${response.statusCode}');
        return {
          'success': false,
          'message':
              '❌ Erreur lors du chargement des prises (${response.statusCode}).',
          'type': 'medication_error',
        };
      }
    } catch (e) {
      print('❌ Erreur _getTodayTakings: $e');
      return {
        'success': false,
        'message': '❌ Erreur de connexion : ${e.toString()}',
        'type': 'medication_error',
      };
    }
  }

  /// ✅ Obtenir l'observance
  static Future<Map<String, dynamic>> _getObservance() async {
    try {
      final token = await _getToken();

      if (token == null || token.isEmpty) {
        return {
          'success': false,
          'message': '🔒 Veuillez vous connecter.',
          'type': 'medication_error',
        };
      }

      final url = '${baseUrl}medications/observance-summary?period=week';
      print('📤 URL: $url');

      final response = await http
          .get(
            Uri.parse(url),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final summary = data['data'] ?? {};

        final taux = summary['taux_observance'] ?? 0;
        final emoji = taux >= 80 ? '✅' : (taux >= 50 ? '⚠️' : '❌');

        String responseMessage = "📊 **Résumé d'observance :**\n\n";
        responseMessage += "   • Total : ${summary['total'] ?? 0}\n";
        responseMessage += "   • Pris : ${summary['prises'] ?? 0} ✅\n";
        responseMessage += "   • Oubliés : ${summary['oubliees'] ?? 0} ❌\n";
        responseMessage += "   • Taux : $taux% $emoji\n";

        return {
          'success': true,
          'message': responseMessage,
          'type': 'observance',
          'severity': taux >= 80 ? 'low' : (taux >= 50 ? 'moderate' : 'high'),
          'severity_level': taux >= 80
              ? 'green'
              : (taux >= 50 ? 'orange' : 'red'),
          'severity_label': taux >= 80
              ? '🟢 Bonne observance'
              : (taux >= 50
                    ? '🟠 Observance moyenne'
                    : '🔴 Observance à améliorer'),
          'data': summary,
        };
      } else {
        return {
          'success': false,
          'message': '❌ Erreur (${response.statusCode}).',
          'type': 'medication_error',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': '❌ Erreur de connexion : ${e.toString()}',
        'type': 'medication_error',
      };
    }
  }

  /// ✅ Vérifier les interactions
  static Future<Map<String, dynamic>> _checkInteractionFromMessage(
    String message,
  ) async {
    final name = _extractMedicationName(message);

    if (name.isEmpty) {
      return {
        'success': false,
        'message': '❌ Quel médicament souhaitez-vous vérifier ?',
        'type': 'medication_error',
      };
    }

    try {
      final token = await _getToken();

      if (token == null || token.isEmpty) {
        return {
          'success': false,
          'message': '🔒 Veuillez vous connecter.',
          'type': 'medication_error',
        };
      }

      final url = '${baseUrl}medications/check-interactions';
      print('📤 URL: $url');

      final response = await http
          .post(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'nom': name}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final interactions = data['data']?['interactions'] ?? [];

        if (interactions.isEmpty) {
          return {
            'success': true,
            'message': "✅ Aucune interaction détectée pour **$name**.",
            'type': 'interaction_ok',
            'severity': 'low',
            'severity_level': 'green',
            'severity_label': '🟢 Aucune interaction',
          };
        }

        String responseMessage =
            "⚠️ **Interactions détectées pour $name :**\n\n";
        for (var interaction in interactions) {
          final emoji = interaction['severity'] == 'high'
              ? '🔴'
              : (interaction['severity'] == 'moderate' ? '🟠' : '🟡');
          responseMessage +=
              "$emoji **${interaction['medicament_a']}** ↔ **${interaction['medicament_b']}**\n";
          responseMessage += "   📝 ${interaction['description']}\n";
          responseMessage += "   💡 ${interaction['recommendation']}\n\n";
        }

        return {
          'success': true,
          'message': responseMessage,
          'type': 'interactions',
          'severity': 'moderate',
          'severity_level': 'orange',
          'severity_label': '🟠 Interactions détectées',
          'data': interactions,
        };
      } else {
        return {
          'success': false,
          'message': '❌ Erreur (${response.statusCode}).',
          'type': 'medication_error',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': '❌ Erreur de connexion : ${e.toString()}',
        'type': 'medication_error',
      };
    }
  }

  /// ✅ Générer un renouvellement
  // lib/services/chatbot/chatbot_service.dart

  /// ✅ Générer un renouvellement (CORRIGÉ)
  // lib/services/chatbot/chatbot_service.dart

  /// ✅ Générer un renouvellement (CORRIGÉ)
  static Future<Map<String, dynamic>> _generateRenewalFromMessage(
    String message,
  ) async {
    print('🔵 _generateRenewalFromMessage DEBUT');

    final name = _extractMedicationName(message);
    print('🔵 Nom extrait: $name');

    if (name.isEmpty) {
      return {
        'success': false,
        'message':
            '❌ Pour quel médicament souhaitez-vous un renouvellement ?\n\nExemple : "Renouveler Doliprane"',
        'type': 'medication_error',
        'severity': 'low',
        'severity_level': 'green',
        'severity_label': '🟢 Information',
      };
    }

    try {
      final token = await _getToken();

      if (token == null || token.isEmpty) {
        return {
          'success': false,
          'message': '🔒 Veuillez vous connecter.',
          'type': 'medication_error',
          'severity': 'moderate',
          'severity_level': 'orange',
          'severity_label': '🔒 Authentification requise',
        };
      }

      // ✅ Étape 1: Récupérer la liste des médicaments
      print('🔵 Étape 1: Recherche du médicament...');
      final listUrl = _buildUrl('api/medications');
      print('📤 URL liste: $listUrl');

      final listResponse = await http
          .get(
            Uri.parse(listUrl),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 15));

      print('📥 Statut liste: ${listResponse.statusCode}');

      if (listResponse.statusCode != 200) {
        return {
          'success': false,
          'message':
              '❌ Erreur lors de la récupération de la liste des médicaments.',
          'type': 'medication_error',
        };
      }

      final data = jsonDecode(listResponse.body);
      final medications = data['data'] ?? [];
      print('🔵 Médicaments trouvés: ${medications.length}');

      // ✅ CORRECTION: Utiliser une fonction qui retourne un booléen
      dynamic med;
      for (var m in medications) {
        if (m['nom'] != null &&
            m['nom'].toLowerCase().contains(name.toLowerCase())) {
          med = m;
          break;
        }
      }

      if (med == null) {
        return {
          'success': false,
          'message':
              '❌ Médicament "$name" non trouvé dans votre liste.\n\nVoulez-vous l\'ajouter ?',
          'type': 'medication_error',
          'severity': 'low',
          'severity_level': 'green',
          'severity_label': '🟢 Information',
        };
      }

      print('🔵 Médicament trouvé: ${med['nom']} (ID: ${med['id']})');

      // ✅ Étape 2: Générer le message de renouvellement
      print('🔵 Étape 2: Génération du message de renouvellement...');

      // ✅ Construire un message formaté sans appel API supplémentaire
      String formattedMessage = '📝 **Message de renouvellement :**\n\n';
      formattedMessage += 'Bonjour Docteur,\n\n';
      formattedMessage +=
          'Je souhaiterais renouveler mon ordonnance pour **${med['nom']}** (${med['dosage'] ?? 'Dosage non spécifié'}).\n\n';
      formattedMessage +=
          '📅 Date de début : ${med['date_debut'] ?? 'Non spécifiée'}\n';
      formattedMessage +=
          '💊 Stock restant : ${med['stock_actuel'] ?? 0} comprimés\n';
      if (med['horaires_prises'] != null &&
          (med['horaires_prises'] as List).isNotEmpty) {
        formattedMessage +=
            '📋 Posologie : ${(med['horaires_prises'] as List).join(', ')}\n\n';
      }
      formattedMessage += 'Cordialement,\nVotre patient.';

      return {
        'success': true,
        'message': formattedMessage,
        'type': 'renewal',
        'severity': 'low',
        'severity_level': 'green',
        'severity_label': '🟢 Renouvellement préparé',
        'actions': ['send_renewal', 'edit_renewal'],
      };
    } catch (e) {
      print('❌ Erreur _generateRenewalFromMessage: $e');

      // ✅ Fallback: retourner un message générique
      return {
        'success': true,
        'message':
            '📝 **Message de renouvellement :**\n\n'
            'Bonjour Docteur,\n\n'
            'Je souhaiterais renouveler mon ordonnance pour **$name**.\n\n'
            '📅 Je prends ce traitement depuis plusieurs mois.\n'
            '💊 Il me reste environ 5 comprimés.\n\n'
            'Cordialement,\n'
            'Votre patient.',
        'type': 'renewal',
        'severity': 'low',
        'severity_level': 'green',
        'severity_label': '🟢 Renouvellement préparé',
        'actions': ['send_renewal', 'edit_renewal'],
      };
    }
  }

  // lib/services/chatbot/chatbot_service.dart

  /// ✅ Construire une URL propre
  // lib/services/chatbot/chatbot_service.dart

  /// ✅ Construire une URL propre
  // lib/services/chatbot/chatbot_service.dart

  /// ✅ Construire une URL propre (CORRIGÉ)
  static String _buildUrl(String path) {
    final base = AppConfig.baseUrl;
    // Enlever le slash final s'il existe
    String cleanBase = base.endsWith('/')
        ? base.substring(0, base.length - 1)
        : base;
    // S'assurer que le chemin commence par un slash
    String cleanPath = path.startsWith('/') ? path : '/$path';
    final url = '$cleanBase$cleanPath';
    print('🔵 URL construite: $url');
    return url;
  }

  // Dans _handleAddAppointment, utiliser _buildUrl
  final url = _buildUrl('api/appointments/check-conflicts'); // ✅ Bon
  // Au lieu de '${baseUrl}api/appointments/check-conflicts'  // ❌ Double api

  // ==================== MÉTHODES D'EXTRACTION ====================

  static String _extractMedicationName(String message) {
    final lower = message.toLowerCase();
    final medications = [
      'doliprane',
      'ibuprofène',
      'aspirine',
      'spasfon',
      'paracétamol',
      'amoxicilline',
      'ventoline',
      'imodium',
      'paracetamol',
      'efferalgan',
      'dafalgan',
      'smecta',
      'advil',
      'nurofen',
      'kardegic',
    ];

    for (final med in medications) {
      if (lower.contains(med)) {
        return med;
      }
    }
    return '';
  }

  static String _extractDosage(String message) {
    final regex = RegExp(r'(\d+)\s*(mg|g|ml|µg)', caseSensitive: false);
    final match = regex.firstMatch(message);
    if (match != null) {
      return '${match.group(1)}${match.group(2)}';
    }
    return '';
  }

  static List<String> _extractTimes(String message) {
    final lower = message.toLowerCase();
    final times = <String>[];

    if (lower.contains('matin')) times.add('08:00');
    if (lower.contains('midi')) times.add('12:00');
    if (lower.contains('soir')) times.add('20:00');
    if (lower.contains('8h')) times.addAll(['08:00', '16:00', '00:00']);
    if (lower.contains('12h')) times.addAll(['08:00', '20:00']);

    return times.isNotEmpty ? times : ['08:00'];
  }

  // lib/services/chatbot/chatbot_service.dart

  /// ✅ Détecter les intentions de rendez-vous
  static bool isAppointmentIntent(String message) {
    final lower = message.toLowerCase();
    final keywords = [
      'rendez-vous',
      'rdv',
      'rendezvous',
      'prendre rendez-vous',
      'prendre rdv',
      'consulter',
      'consultation',
      'médecin',
      'docteur',
      'dr',
      'généraliste',
      'spécialiste',
      'annuler rendez-vous',
      'annuler rdv',
      'mes rendez-vous',
      'mes rdv',
      'rappeler rendez-vous',
    ];
    return keywords.any((keyword) => lower.contains(keyword));
  }

  /// ✅ Traiter une intention de rendez-vous
  static Future<Map<String, dynamic>> handleAppointmentIntent(
    String message,
  ) async {
    print('🔵 Traitement intention rendez-vous: $message');

    final lower = message.toLowerCase();

    // Ajouter un rendez-vous
    if (lower.contains('prendre') &&
        (lower.contains('rendez-vous') || lower.contains('rdv'))) {
      return await _handleAddAppointment(message);
    }

    // Liste des rendez-vous
    if ((lower.contains('mes') && lower.contains('rendez-vous')) ||
        lower.contains('liste rendez-vous') ||
        lower.contains('voir mes rdv')) {
      return await _handleListAppointments();
    }

    // Annuler un rendez-vous
    if (lower.contains('annuler') &&
        (lower.contains('rendez-vous') || lower.contains('rdv'))) {
      return await _handleCancelAppointment(message);
    }

    // Aujourd'hui
    if (lower.contains('aujourd\'hui') &&
        (lower.contains('rendez-vous') || lower.contains('rdv'))) {
      return await _handleTodayAppointments();
    }

    return {
      'success': false,
      'message':
          'Je n\'ai pas compris votre demande concernant les rendez-vous.',
      'type': 'appointment_error',
      'severity': 'low',
      'severity_level': 'green',
      'severity_label': '🟢 Information',
    };
  }

  // lib/services/chatbot/chatbot_service.dart

  // ==================== MÉTHODES DE RENDEZ-VOUS ====================

  /// ✅ Gérer l'ajout d'un rendez-vous
  /// ✅ Gérer l'ajout d'un rendez-vous (CORRIGÉ)
  static Future<Map<String, dynamic>> _handleAddAppointment(
    String message,
  ) async {
    print('🔵 _handleAddAppointment: $message');

    final extracted = _extractAppointmentInfo(message);
    print('🔵 Informations extraites: $extracted');

    // ✅ Vérifier si le médecin est trouvé
    if (extracted['medecin_nom'] == null) {
      return {
        'success': false,
        'message':
            '📅 Pour prendre un rendez-vous, indiquez le nom du médecin.\n\n'
            'Exemple : "Prendre rendez-vous avec Dr Martin"',
        'type': 'appointment_error',
        'severity': 'low',
        'severity_level': 'green',
        'severity_label': '🟢 Information',
      };
    }

    // ✅ Si la date n'est pas trouvée, utiliser aujourd'hui
    if (extracted['date_heure'] == null) {
      final now = DateTime.now();
      final defaultDate = '${now.year}-${now.month}-${now.day} 09:00:00';
      extracted['date_heure'] = defaultDate;
      extracted['date'] = '${now.year}-${now.month}-${now.day}';
      extracted['time'] = '09:00';
      print('📅 Date par défaut: $defaultDate');
    }

    try {
      // ✅ Vérifier les conflits
      final conflictCheck = await AppointmentService.checkConflicts(
        dateHeure: extracted['date_heure'],
        duration: 30,
      );

      if (conflictCheck['has_conflict'] == true) {
        final conflicts = conflictCheck['conflicts'] ?? [];
        String conflictMessage = '⚠️ **Conflit de rendez-vous détecté !**\n\n';
        conflictMessage += 'Vous avez déjà un rendez-vous à cette heure :\n';

        for (var conflict in conflicts) {
          conflictMessage +=
              '• **${conflict['medecin_nom']}** le ${conflict['date_heure']}';
          if (conflict['lieu'] != null) {
            conflictMessage += ' (${conflict['lieu']})';
          }
          conflictMessage += '\n';
        }

        conflictMessage +=
            '\nSouhaitez-vous déplacer l\'un de ces rendez-vous ?';

        return {
          'success': false,
          'has_conflict': true,
          'message': conflictMessage,
          'conflicts': conflicts,
          'type': 'appointment_conflict',
          'severity': 'moderate',
          'severity_level': 'orange',
          'severity_label': '🟠 Conflit détecté',
          'actions': ['view_appointments', 'reschedule'],
        };
      }

      // ✅ Ajouter le rendez-vous AVEC titre
      final result = await AppointmentService.addAppointment(
        medecinNom: extracted['medecin_nom'],
        dateHeure: extracted['date_heure'],
        duration: 30,
        lieu: extracted['lieu'],
        motif: extracted['motif'] ?? 'Consultation',
        medecinSpecialite: extracted['medecin_specialite'],
        medecinTelephone: extracted['medecin_telephone'],
        titre: 'Consultation avec ${extracted['medecin_nom']}',
      );

      if (result['success']) {
        // ✅ Utiliser _formatDate
        final formattedDate = _formatDate(extracted['date_heure']);

        return {
          'success': true,
          'message':
              '✅ Rendez-vous ajouté avec succès !\n\n'
              '🩺 **${extracted['medecin_nom']}**\n'
              '📅 $formattedDate\n'
              '📍 ${extracted['lieu'] ?? 'Lieu à préciser'}\n\n'
              '📋 Un rappel vous sera envoyé 24h avant.',
          'type': 'appointment_added',
          'severity': 'low',
          'severity_level': 'green',
          'severity_label': '🟢 Rendez-vous ajouté',
          'data': result['data'],
          'actions': ['view_appointments', 'generate_briefing'],
        };
      } else {
        return {
          'success': false,
          'message':
              '❌ Erreur lors de l\'ajout du rendez-vous: ${result['message']}',
          'type': 'appointment_error',
          'severity': 'low',
          'severity_level': 'green',
          'severity_label': '🟢 Information',
        };
      }
    } catch (e) {
      print('❌ Erreur _handleAddAppointment: $e');
      return {
        'success': false,
        'message': '❌ Erreur de connexion: $e',
        'type': 'appointment_error',
      };
    }
  }

  /// ✅ Gérer la liste des rendez-vous
  static Future<Map<String, dynamic>> _handleListAppointments() async {
    print('🔵 _handleListAppointments');

    try {
      final appointments = await AppointmentService.getAppointments();

      if (appointments.isEmpty) {
        return {
          'success': true,
          'message':
              '📅 Vous n\'avez aucun rendez-vous enregistré.\n\n'
              'Souhaitez-vous en prendre un ?',
          'type': 'appointment_list_empty',
          'severity': 'low',
          'severity_level': 'green',
          'severity_label': '🟢 Liste vide',
          'actions': ['add_appointment'],
        };
      }

      String responseMessage = '📋 **Vos rendez-vous :**\n\n';
      for (var app in appointments) {
        final date = DateTime.parse(app['date_heure']);
        final statusEmoji = app['statut'] == 'confirmé'
            ? '✅'
            : app['statut'] == 'annulé'
            ? '❌'
            : app['statut'] == 'passé'
            ? '📌'
            : '⏳';

        responseMessage += '$statusEmoji **${app['medecin_nom']}**\n';
        responseMessage +=
            '   📅 ${date.day}/${date.month}/${date.year} à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}\n';
        if (app['lieu'] != null) {
          responseMessage += '   📍 ${app['lieu']}\n';
        }
        responseMessage += '   📊 Statut : ${app['statut']}\n\n';
      }

      return {
        'success': true,
        'message': responseMessage,
        'type': 'appointment_list',
        'severity': 'low',
        'severity_level': 'green',
        'severity_label': '🟢 Liste des rendez-vous',
        'data': appointments,
        'actions': ['add_appointment', 'view_today'],
      };
    } catch (e) {
      print('❌ Erreur _handleListAppointments: $e');
      return {
        'success': false,
        'message': '❌ Erreur lors du chargement des rendez-vous: $e',
        'type': 'appointment_error',
      };
    }
  }

  // lib/services/chatbot/chatbot_service.dart

  // ==================== MÉTHODES D'EXTRACTION POUR RENDEZ-VOUS ====================

  /// ✅ Extraire les informations d'un rendez-vous depuis un message
  static Map<String, dynamic> _extractAppointmentInfo(String message) {
    final result = <String, dynamic>{};
    final clean = message.trim().toLowerCase();

    // ✅ 1. Extraire le nom du médecin
    final doctorName = _extractDoctorName(message);
    if (doctorName.isNotEmpty) {
      result['medecin_nom'] = 'Dr $doctorName';
      print('🔵 Médecin trouvé: Dr $doctorName');
    } else {
      print('⚠️ Aucun médecin trouvé');
    }

    // ✅ 2. Extraire la date
    String? dateStr;

    // 2a. Aujourd'hui
    if (clean.contains('aujourd\'hui') || clean.contains('today')) {
      final now = DateTime.now();
      dateStr = '${now.year}-${now.month}-${now.day}';
      print('📅 Date: Aujourd\'hui ($dateStr)');
    }
    // 2b. Demain
    else if (clean.contains('demain') || clean.contains('tomorrow')) {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      dateStr = '${tomorrow.year}-${tomorrow.month}-${tomorrow.day}';
      print('📅 Date: Demain ($dateStr)');
    }
    // 2c. Après-demain
    else if (clean.contains('après-demain') ||
        clean.contains('after tomorrow')) {
      final afterTomorrow = DateTime.now().add(const Duration(days: 2));
      dateStr =
          '${afterTomorrow.year}-${afterTomorrow.month}-${afterTomorrow.day}';
      print('📅 Date: Après-demain ($dateStr)');
    }
    // 2d. Format 15/07 ou 15-07
    else {
      final dateRegex1 = RegExp(r'(\d{1,2})\s*[/-]\s*(\d{1,2})');
      final match1 = dateRegex1.firstMatch(clean);
      if (match1 != null) {
        final day = int.parse(match1.group(1)!);
        final month = int.parse(match1.group(2)!);
        final year = DateTime.now().year;
        dateStr = '$year-$month-$day';
        print('📅 Date trouvée (format JJ/MM): $dateStr');
      }
    }

    // 2e. Format 15 juillet
    if (dateStr == null) {
      final moisMap = {
        'janvier': 1,
        'février': 2,
        'mars': 3,
        'avril': 4,
        'mai': 5,
        'juin': 6,
        'juillet': 7,
        'août': 8,
        'septembre': 9,
        'octobre': 10,
        'novembre': 11,
        'décembre': 12,
        'jan': 1,
        'fev': 2,
        'mar': 3,
        'avr': 4,
        'jun': 6,
        'jui': 7,
        'aou': 8,
        'sep': 9,
        'oct': 10,
        'nov': 11,
        'dec': 12,
      };

      final moisRegex = RegExp(
        r'(\d{1,2})\s*(janvier|février|mars|avril|mai|juin|juillet|août|septembre|octobre|novembre|décembre|jan|fev|mar|avr|mai|jun|jui|aou|sep|oct|nov|dec)',
      );
      final moisMatch = moisRegex.firstMatch(clean);
      if (moisMatch != null) {
        final day = int.parse(moisMatch.group(1)!);
        final monthName = moisMatch.group(2)?.toLowerCase();
        if (monthName != null && moisMap.containsKey(monthName)) {
          final month = moisMap[monthName];
          final year = DateTime.now().year;
          dateStr = '$year-$month-$day';
          print('📅 Date trouvée (format JJ Mois): $dateStr');
        }
      }
    }

    if (dateStr != null) {
      result['date'] = dateStr;
    }

    // ✅ 3. Extraire l'heure
    String? timeStr;

    // 3a. Format 14h ou 14h00 ou 14:00
    final timeRegex1 = RegExp(r'(\d{1,2})\s*[:hH]\s*(\d{2})?');
    final matchTime1 = timeRegex1.firstMatch(clean);
    if (matchTime1 != null) {
      final hour = int.parse(matchTime1.group(1)!);
      final minute = matchTime1.group(2) != null
          ? int.parse(matchTime1.group(2)!)
          : 0;
      if (hour >= 0 && hour <= 23 && minute >= 0 && minute <= 59) {
        timeStr =
            '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
        print('⏰ Heure trouvée: $timeStr');
      }
    }

    // 3b. Format 14 heures
    if (timeStr == null) {
      final timeRegex2 = RegExp(r'(\d{1,2})\s+heures?');
      final matchTime2 = timeRegex2.firstMatch(clean);
      if (matchTime2 != null) {
        final hour = int.parse(matchTime2.group(1)!);
        if (hour >= 0 && hour <= 23) {
          timeStr = '${hour.toString().padLeft(2, '0')}:00';
          print('⏰ Heure trouvée: $timeStr');
        }
      }
    }

    if (timeStr != null) {
      result['time'] = timeStr;
    }

    // ✅ Construire la date complète
    if (result.containsKey('date') && result.containsKey('time')) {
      result['date_heure'] = '${result['date']} ${result['time']}:00';
      print('📅 Date complète: ${result['date_heure']}');
    } else if (result.containsKey('date')) {
      // Si seulement la date, mettre 9h par défaut
      result['date_heure'] = '${result['date']} 09:00:00';
      result['time'] = '09:00';
      print('📅 Date complète (défaut 9h): ${result['date_heure']}');
    } else {
      print('⚠️ Date non trouvée');
    }

    // ✅ Extraire le lieu
    final lieuRegex = RegExp(r'(?:à|chez)\s+([A-Za-z\s\d]+?)(?:\s+le|\s+à|$)');
    final lieuMatch = lieuRegex.firstMatch(clean);
    if (lieuMatch != null && lieuMatch.group(1) != null) {
      final lieu = lieuMatch.group(1)?.trim();
      if (lieu != null && lieu.isNotEmpty && lieu.length > 2) {
        result['lieu'] = lieu;
      }
    }

    // ✅ Extraire le motif
    final motifRegex = RegExp(r'(?:pour|motif:)\s+(.+?)(?:\.|$)');
    final motifMatch = motifRegex.firstMatch(clean);
    if (motifMatch != null) {
      result['motif'] = motifMatch.group(1)?.trim();
    }

    print('🔵 Résultat final: $result');
    return result;
  }

  /// ✅ Extraire le nom du médecin
  static String _extractDoctorName(String message) {
    final clean = message.trim();

    // 1. Chercher "Dr" ou "Docteur" suivi d'un nom
    final patterns = [
      RegExp(
        r'Docteur\s+([A-Za-zéèêëàâôûïç\s]+?)(?:\s+aujourd|\s+le|\s+à|$)',
        caseSensitive: false,
      ),
      RegExp(
        r'Dr\.?\s+([A-Za-zéèêëàâôûïç\s]+?)(?:\s+aujourd|\s+le|\s+à|$)',
        caseSensitive: false,
      ),
      RegExp(r'Dr\.?\s*([A-Za-zéèêëàâôûïç]+)', caseSensitive: false),
      RegExp(r'Docteur\s*([A-Za-zéèêëàâôûïç]+)', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(clean);
      if (match != null) {
        final name = match.group(1)?.trim();
        if (name != null && name.isNotEmpty && name.length > 1) {
          // ✅ Ne prendre que le premier mot si plusieurs
          final parts = name.split(RegExp(r'\s+'));
          if (parts.isNotEmpty && parts[0].length > 1) {
            return parts[0];
          }
          return name;
        }
      }
    }

    // 2. Fallback: chercher des noms de médecins connus
    final commonNames = [
      'Martin',
      'Dupont',
      'Durand',
      'Bernard',
      'Thomas',
      'Petit',
      'Robert',
      'Richard',
      'Michel',
      'Lefevre',
      'Moreau',
      'Simon',
    ];
    for (final name in commonNames) {
      if (clean.toLowerCase().contains(name.toLowerCase())) {
        return name;
      }
    }

    return '';
  }

  /// ✅ Extraire l'ID d'un rendez-vous depuis un message
  static int? _extractAppointmentId(String message) {
    // Chercher un ID numérique
    final idRegex = RegExp(r'#(\d+)', caseSensitive: false);
    final idMatch = idRegex.firstMatch(message);
    if (idMatch != null) {
      return int.tryParse(idMatch.group(1)!);
    }

    // Chercher par nom de médecin
    final doctorRegex = RegExp(
      r'(?:Dr|Docteur|Dr\.)\s*([A-Za-z]+)',
      caseSensitive: false,
    );
    final doctorMatch = doctorRegex.firstMatch(message);
    if (doctorMatch != null) {
      final doctorName = doctorMatch.group(1)?.toLowerCase();
      // TODO: Chercher l'ID du rendez-vous par nom de médecin
      // Pour l'instant, retourner null
    }

    return null;
  }

  /// ✅ Formater une date en français
  static String _formatDate(String dateTime) {
    try {
      final date = DateTime.parse(dateTime);
      final months = [
        'janvier',
        'février',
        'mars',
        'avril',
        'mai',
        'juin',
        'juillet',
        'août',
        'septembre',
        'octobre',
        'novembre',
        'décembre',
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year} à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTime;
    }
  }

  /// ✅ Formater une date en version courte
  static String _formatDateShort(String dateTime) {
    try {
      final date = DateTime.parse(dateTime);
      return '${date.day}/${date.month}/${date.year} à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTime;
    }
  }

  /// ✅ Gérer l'annulation d'un rendez-vous
  static Future<Map<String, dynamic>> _handleCancelAppointment(
    String message,
  ) async {
    print('🔵 _handleCancelAppointment: $message');

    // ✅ Extraire l'ID du rendez-vous du message
    final appointmentId = _extractAppointmentId(message);

    if (appointmentId == null) {
      return {
        'success': false,
        'message':
            '❌ Pour annuler un rendez-vous, précisez lequel.\n\n'
            'Exemple : "Annuler mon rendez-vous avec Dr Martin"',
        'type': 'appointment_error',
        'severity': 'low',
        'severity_level': 'green',
        'severity_label': '🟢 Information',
      };
    }

    try {
      final result = await AppointmentService.cancelAppointment(appointmentId);

      if (result['success']) {
        return {
          'success': true,
          'message':
              '❌ Rendez-vous annulé avec succès.\n\n'
              'Vous pouvez en prendre un autre à tout moment.',
          'type': 'appointment_cancelled',
          'severity': 'low',
          'severity_level': 'green',
          'severity_label': '🟢 Rendez-vous annulé',
          'actions': ['add_appointment', 'view_appointments'],
        };
      } else {
        return {
          'success': false,
          'message': '❌ Erreur lors de l\'annulation: ${result['message']}',
          'type': 'appointment_error',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': '❌ Erreur de connexion: $e',
        'type': 'appointment_error',
      };
    }
  }

  /// ✅ Gérer les rendez-vous du jour
  static Future<Map<String, dynamic>> _handleTodayAppointments() async {
    print('🔵 _handleTodayAppointments');

    try {
      final appointments = await AppointmentService.getTodayAppointments();

      if (appointments.isEmpty) {
        return {
          'success': true,
          'message':
              '📅 Aucun rendez-vous aujourd\'hui.\n\n'
              'Profitez de votre journée ! 😊',
          'type': 'appointment_today_empty',
          'severity': 'low',
          'severity_level': 'green',
          'severity_label': '🟢 Aucun rendez-vous',
          'actions': ['add_appointment', 'view_appointments'],
        };
      }

      String responseMessage = '📅 **Vos rendez-vous aujourd\'hui :**\n\n';
      for (var app in appointments) {
        final date = DateTime.parse(app['date_heure']);
        responseMessage += '🩺 **${app['medecin_nom']}**\n';
        responseMessage +=
            '   ⏰ ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}\n';
        if (app['lieu'] != null) {
          responseMessage += '   📍 ${app['lieu']}\n';
        }
        responseMessage += '   📊 Statut : ${app['statut']}\n\n';
      }

      return {
        'success': true,
        'message': responseMessage,
        'type': 'appointment_today',
        'severity': 'low',
        'severity_level': 'green',
        'severity_label': '🟢 Rendez-vous du jour',
        'data': appointments,
        'actions': ['view_appointments', 'generate_briefing'],
      };
    } catch (e) {
      return {
        'success': false,
        'message': '❌ Erreur: $e',
        'type': 'appointment_error',
      };
    }
  }

  // ==================== MÉTHODES D'EXTRACTION ====================

  /// ✅ Extraire les informations d'un rendez-vous depuis un message
  // lib/services/chatbot/chatbot_service.dart

  /// ✅ Extraire les informations d'un rendez-vous depuis un message (CORRIGÉ)
  // lib/services/chatbot/chatbot_service.dart

  /// ✅ Extraire les informations d'un rendez-vous (version complète corrigée)

  // ==================== MÉTHODES EXISTANTES ====================

  static Future<Map<String, dynamic>> sendMessage(String message) async {
    try {
      final token = await _getToken();

      if (token == null || token.isEmpty) {
        throw ChatbotException('Veuillez vous connecter', statusCode: 401);
      }

      final response = await http
          .post(
            Uri.parse('${baseUrl}llm/chat'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: json.encode({'message': message, 'type': 'symptom_analysis'}),
          )
          .timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        return {
          'success': true,
          'type': data['type'] ?? 'general',
          'message': data['message'] ?? data['content'] ?? 'Réponse reçue',
          'suggestions': data['suggestions'] ?? [],
          'data': data['data'] ?? {},
          'severity': data['severity'] ?? 'moderate',
          'severity_level': data['severity_level'] ?? 'green',
          'severity_label': data['severity_label'] ?? '🟢 Autosoins',
          'time_context': data['time_context'],
          'comorbidities': data['comorbidities'],
          'snapshot': data['snapshot'],
          'actions': data['actions'] ?? [],
          'advice': data['advice'] ?? '',
          'possible_causes': data['possible_causes'] ?? [],
          'emergency_alert': data['emergency_alert'] ?? false,
          'suggest_doctor': data['suggest_doctor'] ?? false,
          'suggest_medication': data['suggest_medication'] ?? false,
        };
      } else if (response.statusCode == 401) {
        throw ChatbotException('Session expirée', statusCode: 401);
      } else {
        throw ChatbotException(
          'Erreur: ${response.statusCode} - ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } on ChatbotException {
      rethrow;
    } catch (e) {
      throw ChatbotException(e.toString());
    }
  }

  static Future<Map<String, dynamic>> analyzeSymptoms(String symptoms) async {
    try {
      final token = await _getToken();

      if (token == null || token.isEmpty) {
        throw ChatbotException('Veuillez vous connecter', statusCode: 401);
      }

      final response = await http
          .post(
            Uri.parse('${baseUrl}llm/analyze'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: json.encode({
              'symptoms': symptoms,
              'type': 'cognitive_analysis',
            }),
          )
          .timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        return {
          'success': true,
          'type': 'symptom_analysis',
          'severity': data['severity'] ?? 'moderate',
          'severity_level': data['severity_level'] ?? 'green',
          'severity_label': data['severity_label'] ?? '🟢 Autosoins',
          'possible_causes': data['possible_causes'] ?? [],
          'advice': data['advice'] ?? '',
          'message': data['message'] ?? 'Analyse terminée',
          'suggest_doctor': data['suggest_doctor'] ?? false,
          'suggest_medication': data['suggest_medication'] ?? false,
          'emergency_alert': data['emergency_alert'] ?? false,
          'actions': data['actions'] ?? [],
          'time_context': data['time_context'],
          'comorbidities': data['comorbidities'],
          'snapshot': data['snapshot'],
        };
      } else if (response.statusCode == 401) {
        throw ChatbotException('Session expirée', statusCode: 401);
      } else {
        throw ChatbotException(
          'Erreur: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on ChatbotException {
      rethrow;
    } catch (e) {
      throw ChatbotException(e.toString());
    }
  }

  static Future<bool> clearHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('chat_history');
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<String> getUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('user_id') ?? '1';
    } catch (e) {
      return '1';
    }
  }

  // lib/services/chatbot/chatbot_service.dart

  /// ✅ Détecter l'intention d'utiliser le Scheduler Vocal
  static bool isVoiceSchedulerIntent(String message) {
    final lower = message.toLowerCase();
    final keywords = [
      'pas de place',
      'pas de créneau',
      'pas disponible',
      'appeler le cabinet',
      'appeler le secrétariat',
      'négocier',
      'trouver un créneau',
      'plus de disponibilité',
      'appel vocal',
    ];
    return keywords.any((keyword) => lower.contains(keyword));
  }

  /// ✅ Traiter l'intention Scheduler Vocal
  static Future<Map<String, dynamic>> handleVoiceSchedulerIntent(
    String message,
  ) async {
    print('🔵 Traitement Scheduler Vocal: $message');

    final extracted = _extractAppointmentInfo(message);

    if (extracted['medecin_nom'] == null) {
      return {
        'success': false,
        'message':
            '📞 Pour utiliser le Scheduler Vocal, indiquez :\n\n'
            '• Le nom du médecin\n'
            '• Le numéro du cabinet\n\n'
            'Exemple : "Appeler le cabinet du Dr Martin"',
        'type': 'voice_scheduler_error',
        'severity': 'low',
        'severity_level': 'green',
        'severity_label': '🟢 Information',
      };
    }

    return {
      'success': true,
      'type': 'voice_scheduler',
      'data': {
        'doctor_name': extracted['medecin_nom'],
        'cabinet_phone': _extractPhoneNumber(message) ?? null,
        'date': extracted['date'],
        'time': extracted['time'],
      },
      'message':
          '📞 Dernière option : je peux appeler le cabinet pour négocier un créneau.',
      'severity': 'low',
      'severity_level': 'green',
      'severity_label': '🟢 Scheduler Vocal',
      'actions': ['voice_schedule'],
    };
  }

  /// ✅ Extraire un numéro de téléphone
  static String? _extractPhoneNumber(String message) {
    final regex = RegExp(r'(?:(?:\+|00)33|0)\s*[1-9](?:[\s.-]?\d{2}){4}');
    final match = regex.firstMatch(message);
    return match?.group(0)?.trim();
  }
}
