import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:suivi_sante_pro/models/chatbot/message.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  final String baseUrl = 'http://192.168.100.85:8000/api/';

  String? _authToken;

  ApiService() {
    _loadToken();
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString('auth_token');
  }

  /// ✅ Méthode principale pour envoyer un message
  Future<Map<String, dynamic>> sendMessage(
    String text,
    List<Message> history,
  ) async {
    try {
      print('📤 Envoi: $text');

      final response = await http.post(
        Uri.parse('$baseUrl/chat'),
        headers: _getHeaders(),
        body: jsonEncode({
          'message': text,
          'history': history
              .map(
                (m) => {
                  'content': m.content,
                  'type': m.type.toString().split('.').last,
                },
              )
              .toList(),
          'context': {
            'userId': await _getUserId(),
            'timestamp': DateTime.now().toIso8601String(),
          },
        }),
      );

      print('📥 Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('📥 Données reçues: ${data.toString().substring(0, 200)}...');

        // ✅ Si la réponse a une structure 'data'
        Map<String, dynamic> rawData;
        if (data['success'] == true && data['data'] != null) {
          rawData = data['data'];
        } else {
          rawData = data;
        }

        // ✅ FORMATER LE MESSAGE POUR L'UTILISATEUR
        return _formatResponseForUser(rawData);
      } else {
        throw Exception('Erreur API: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Erreur: $e');
      return _getFallbackResponse(text);
    }
  }

  /// ✅ FORMATER la réponse JSON en un message lisible
  Map<String, dynamic> _formatResponseForUser(Map<String, dynamic> raw) {
    print('🔄 Formatage de la réponse...');

    // Si le message est déjà formaté, le retourner
    if (raw['message'] != null && raw['message'] is String) {
      return raw;
    }

    // --- Construire le message formaté ---
    List<String> parts = [];

    // 1️⃣ Symptômes
    List<String> symptomes = [];
    if (raw['symptomes'] != null && raw['symptomes'] is List) {
      symptomes = List<String>.from(raw['symptomes']);
    }

    if (symptomes.isNotEmpty) {
      parts.add('🩺 **Symptômes détectés :** ${symptomes.join(', ')}');
    } else {
      parts.add('🩺 Aucun symptôme spécifique détecté.');
    }

    // 2️⃣ Niveau de gravité
    String gravite = raw['gravite'] ?? 'vert';
    Map<String, String> graviteLabels = {
      'vert': '🟢 Faible',
      'orange': '🟠 Modéré',
      'rouge': '🔴 Élevé - URGENT',
    };
    parts.add(
      '📊 **Niveau de gravité :** ${graviteLabels[gravite] ?? gravite}',
    );

    // 3️⃣ Confiance
    int confiance = raw['confiance'] ?? 0;
    String confidenceLabel = confiance >= 80
        ? 'Élevée'
        : (confiance >= 50 ? 'Moyenne' : 'Faible');
    parts.add('🎯 **Confiance :** $confidenceLabel ($confiance%)');

    // 4️⃣ Résumé
    if (raw['resume'] != null && raw['resume'].toString().isNotEmpty) {
      parts.add('📝 **Résumé :** ${raw['resume']}');
    }

    // 5️⃣ Questions
    List<String> questions = [];
    if (raw['questions'] != null && raw['questions'] is List) {
      questions = List<String>.from(raw['questions']);
    }
    if (questions.isNotEmpty) {
      String questionList = questions.map((q) => '   • $q').join('\n');
      parts.add('❓ **Pour mieux vous aider :**\n$questionList');
    }

    // 6️⃣ Recommandation
    if (raw['recommandation'] != null &&
        raw['recommandation'].toString().isNotEmpty) {
      parts.add('💡 **Recommandation :** ${raw['recommandation']}');
    }

    // 7️⃣ Avertissement médical
    parts.add(
      '\n⚠️ **Rappel important :** Cette analyse ne remplace pas un avis médical professionnel.',
    );

    // 8️⃣ Urgence
    if (raw['urgence'] == true) {
      parts.add(
        '\n🚨 **⚠️ URGENCE DÉTECTÉE !** Consultez immédiatement un médecin ou appelez le 15 (SAMU).',
      );
    }

    // --- Construire le message final ---
    String formattedMessage = parts.join('\n\n');

    // --- Construire les actions rapides ---
    List<Map<String, dynamic>> quickActions = [];

    if (raw['urgence'] == true) {
      quickActions.add({
        'label': '🚨 Appeler le 15',
        'icon': 'emergency',
        'type': 'emergency',
        'priority': 1,
      });
    }

    if (gravite == 'orange' || gravite == 'rouge' || raw['urgence'] == true) {
      quickActions.add({
        'label': '📅 Prendre RDV',
        'icon': 'calendar_month',
        'type': 'appointment',
        'priority': 2,
      });
    }

    if (symptomes.isNotEmpty) {
      quickActions.add({
        'label': '💾 Enregistrer',
        'icon': 'save',
        'type': 'save_symptoms',
        'priority': 3,
      });
    }

    // --- Construire la réponse finale ---
    Map<String, dynamic> formattedResponse = {
      // ✅ Le message formaté pour l'utilisateur
      'message': formattedMessage,
      'short_message': symptomes.isNotEmpty
          ? '${symptomes.join(', ')} - ${graviteLabels[gravite] ?? gravite}'
          : 'Analyse des symptômes',

      // ✅ Données structurées pour le traitement
      'symptomes': symptomes,
      'questions': questions,
      'gravite': gravite,
      'urgence': raw['urgence'] ?? false,
      'confiance': confiance,
      'resume':
          raw['resume'] ??
          (symptomes.isNotEmpty
              ? 'Symptômes : ${symptomes.join(', ')}'
              : 'Aucun symptôme'),
      'recommandation':
          raw['recommandation'] ??
          'Surveillez vos symptômes. Consultez un médecin si nécessaire.',
      'snapshot':
          raw['snapshot'] ??
          {
            'date': DateTime.now().toIso8601String(),
            'symptomes': symptomes,
            'niveau': gravite,
            'resume': raw['resume'] ?? 'Analyse des symptômes',
          },
      'quick_actions': quickActions,
      'metadata': {
        'timestamp': DateTime.now().toIso8601String(),
        'model': raw['model'] ?? 'llama3.2:3b',
      },
    };

    print('✅ Message formaté: ${formattedMessage.substring(0, 100)}...');
    return formattedResponse;
  }

  /// ✅ Réponse de fallback locale
  Map<String, dynamic> _getFallbackResponse(String text) {
    final lower = text.toLowerCase();
    final symptoms = <String>[];

    if (lower.contains('tête') || lower.contains('migraine'))
      symptoms.add('maux de tête');
    if (lower.contains('fièvre')) symptoms.add('fièvre');
    if (lower.contains('toux')) symptoms.add('toux');
    if (lower.contains('ventre') || lower.contains('estomac'))
      symptoms.add('douleurs abdominales');
    if (lower.contains('fatigue')) symptoms.add('fatigue');
    if (lower.contains('nausée')) symptoms.add('nausée');

    final isUrgent =
        lower.contains('douleur thoracique') ||
        lower.contains('essoufflement') ||
        lower.contains('difficulté respiratoire');

    final gravite = isUrgent
        ? 'rouge'
        : (symptoms.length > 2 ? 'orange' : 'vert');
    final confiance = symptoms.isNotEmpty ? (isUrgent ? 75 : 60) : 30;

    // Construire le message formaté
    final parts = <String>[];

    if (symptoms.isNotEmpty) {
      parts.add('🩺 **Symptômes détectés :** ${symptoms.join(', ')}');
    } else {
      parts.add('🩺 Je n\'ai pas clairement identifié de symptômes.');
    }

    final graviteLabels = {
      'vert': '🟢 Faible',
      'orange': '🟠 Modéré',
      'rouge': '🔴 Élevé - URGENT',
    };
    parts.add(
      '📊 **Niveau de gravité :** ${graviteLabels[gravite] ?? gravite}',
    );

    final confidenceLabel = confiance >= 80
        ? 'Élevée'
        : (confiance >= 50 ? 'Moyenne' : 'Faible');
    parts.add('🎯 **Confiance :** $confidenceLabel ($confiance%)');

    if (symptoms.isEmpty) {
      parts.add('❓ **Pouvez-vous décrire précisément vos symptômes ?**');
    } else {
      parts.add('❓ **Depuis combien de temps avez-vous ces symptômes ?**');
    }

    if (isUrgent) {
      parts.add(
        '🚨 **⚠️ URGENCE DÉTECTÉE !** Consultez immédiatement un médecin ou appelez le 15 (SAMU).',
      );
    } else {
      parts.add(
        '💡 **Recommandation :** Surveillez vos symptômes. Reposez-vous et hydratez-vous. Consultez si nécessaire.',
      );
    }

    parts.add(
      '\n⚠️ **Rappel :** Cette analyse ne remplace pas un avis médical professionnel.',
    );

    // Actions rapides
    List<Map<String, dynamic>> actions = [];
    if (isUrgent) {
      actions.add({
        'label': '🚨 Appeler le 15',
        'icon': 'emergency',
        'type': 'emergency',
        'priority': 1,
      });
    }
    if (gravite == 'orange' || gravite == 'rouge') {
      actions.add({
        'label': '📅 Prendre RDV',
        'icon': 'calendar_month',
        'type': 'appointment',
        'priority': 2,
      });
    }
    if (symptoms.isNotEmpty) {
      actions.add({
        'label': '💾 Enregistrer',
        'icon': 'save',
        'type': 'save_symptoms',
        'priority': 3,
      });
    }

    return {
      'message': parts.join('\n\n'),
      'short_message': symptoms.isNotEmpty
          ? '${symptoms.join(', ')} - ${graviteLabels[gravite] ?? gravite}'
          : 'Aucun symptôme identifié',
      'symptomes': symptoms,
      'questions': ['Depuis combien de temps ?'],
      'gravite': gravite,
      'urgence': isUrgent,
      'confiance': confiance,
      'resume': symptoms.isNotEmpty
          ? 'Symptômes : ${symptoms.join(', ')}'
          : 'Aucun symptôme clairement identifié',
      'recommandation': isUrgent
          ? '⚠️ Consultez immédiatement un médecin ou appelez le 15 !'
          : 'Surveillez vos symptômes. Reposez-vous et hydratez-vous. Consultez si nécessaire.',
      'snapshot': {
        'date': DateTime.now().toIso8601String(),
        'symptomes': symptoms,
        'niveau': gravite,
        'resume': symptoms.isNotEmpty
            ? 'Symptômes : ${symptoms.join(', ')}'
            : 'Aucun symptôme',
      },
      'quick_actions': actions,
      'metadata': {
        'timestamp': DateTime.now().toIso8601String(),
        'fallback': true,
      },
    };
  }

  /// ✅ Alias de sendMessage
  Future<Map<String, dynamic>> chat(String text, List<Message> history) async {
    return sendMessage(text, history);
  }

  /// ✅ Headers HTTP
  Map<String, String> _getHeaders() {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (_authToken != null) 'Authorization': 'Bearer $_authToken',
    };
  }

  /// ✅ Récupérer l'ID utilisateur
  Future<String> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_id') ?? 'anonymous';
  }

  /// ✅ Vérifier la santé du service
  Future<bool> checkHealth() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
        headers: _getHeaders(),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// ✅ Extraire des informations
  Future<Map<String, dynamic>> extractInfo(String text, String type) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/extract'),
        headers: _getHeaders(),
        body: jsonEncode({'message': text, 'type': type}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? {};
      }
      return {};
    } catch (e) {
      print('❌ Extract Info Error: $e');
      return {};
    }
  }
}
