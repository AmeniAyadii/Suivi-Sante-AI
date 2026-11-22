import 'package:flutter/material.dart';
import 'package:suivi_sante_pro/models/chatbot/message.dart';
import 'package:suivi_sante_pro/services/chatbot/appointment_service.dart';
import 'package:suivi_sante_pro/services/chatbot/chatbot_service.dart';
import 'package:suivi_sante_pro/services/chatbot/voice_scheduler_service.dart';
import 'dart:convert'; // ✅ AJOUTÉ
import 'package:http/http.dart' as http; // ✅ AJOUTÉ
import 'package:shared_preferences/shared_preferences.dart'; // ✅ AJOUTÉ

class ChatProvider extends ChangeNotifier {
  final ChatbotService _service = ChatbotService();
  List<Message> _messages = [];
  bool _isLoading = false;
  String? _error;

  List<Message> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void addWelcomeMessage() {
    if (_messages.isEmpty) {
      _messages.add(
        Message.bot(
          'Bonjour ! Je suis votre Assistant Santé. 😊\n\n'
          'Je peux vous aider à :\n'
          '• Analyser vos symptômes avec une intelligence avancée\n'
          '• Détecter le contexte temporel\n'
          '• Prendre en compte vos antécédents médicaux\n'
          '• Évaluer la gravité de vos symptômes\n\n'
          'Comment puis-je vous assister aujourd\'hui ?',
          quickActions: [
            QuickAction(
              label: '🩺 Analyser symptômes',
              icon: Icons.health_and_safety,
              onTap: () => handleQuickAction('symptoms'),
              type: 'symptoms',
              priority: 1,
            ),
            QuickAction(
              label: '💊 Médicaments',
              icon: Icons.medication,
              onTap: () => handleQuickAction('view_medications'),
              type: 'view_medications',
              priority: 2,
            ),
            QuickAction(
              label: '📅 Rendez-vous',
              icon: Icons.calendar_today,
              onTap: () => handleQuickAction('view_appointments'),
              type: 'view_appointments',
              priority: 3,
            ),
          ],
        ),
      );
      notifyListeners();
    }
  }

  /// ✅ Détection des symptômes avec plus de mots-clés
  bool _isSymptomsQuery(String text) {
    final keywords = [
      'symptôme',
      'symptome',
      'mal',
      'douleur',
      'fatigue',
      'fièvre',
      'fievre',
      'toux',
      'nausée',
      'nausee',
      'vomi',
      'vomissement',
      'maux',
      'tête',
      'tete',
      'dos',
      'ventre',
      'gorge',
      'grippe',
      'rhume',
      'allergie',
      'migraine',
      'vertige',
      'étourdissement',
      'etourdissement',
      'courbature',
      'frisson',
      'transpiration',
      'essoufflement',
      'sueur',
      'sueurs',
      'malaise',
      'faiblesse',
      'perte connaissance',
      'palpitation',
      'cardiaque',
      'saignement',
      'brûlure',
      'brulure',
    ];
    final lowerText = text.toLowerCase();
    return keywords.any((keyword) => lowerText.contains(keyword));
  }

  /// ✅ Parser la sévérité avec plus de cas
  Severity? _parseSeverity(String? severity) {
    if (severity == null) return null;
    final lower = severity.toLowerCase();
    switch (lower) {
      case 'low':
      case 'faible':
      case 'vert':
        return Severity.low;
      case 'moderate':
      case 'moyen':
      case 'modéré':
      case 'moderee':
      case 'orange':
        return Severity.moderate;
      case 'high':
      case 'eleve':
      case 'elevé':
      case 'rouge':
        return Severity.high;
      case 'emergency':
      case 'urgent':
      case 'critique':
        return Severity.urgent;
      default:
        return null;
    }
  }

  /// ✅ Construire les actions rapides
  List<QuickAction>? _buildQuickActions(Map<String, dynamic> response) {
    final actions = <QuickAction>[];

    // Action urgence (priorité élevée)
    if (response['emergency_alert'] == true ||
        response['urgence'] == true ||
        response['gravite'] == 'rouge') {
      actions.add(
        QuickAction(
          label: '🚨 Appeler le 15',
          icon: Icons.emergency,
          onTap: () => handleQuickAction('emergency'),
          type: 'emergency',
          priority: 0,
        ),
      );
    }

    // Action rendez-vous (depuis l'analyse des symptômes)
    if (response['suggest_doctor'] == true ||
        response['gravite'] == 'orange' ||
        response['gravite'] == 'rouge') {
      actions.add(
        QuickAction(
          label: '📅 Prendre RDV',
          icon: Icons.calendar_month,
          onTap: () => handleQuickAction('add_appointment'),
          type: 'add_appointment',
          priority: 1,
        ),
      );
    }

    // Action médicament
    if (response['suggest_medication'] == true ||
        response['gravite'] == 'vert') {
      actions.add(
        QuickAction(
          label: '💊 Ajouter médicament',
          icon: Icons.medication,
          onTap: () => handleQuickAction('add_medication'),
          type: 'medication',
          priority: 2,
        ),
      );
    }

    // Action enregistrer les symptômes
    if (response['snapshot'] != null) {
      actions.add(
        QuickAction(
          label: '💾 Enregistrer',
          icon: Icons.save,
          onTap: () =>
              handleQuickAction('save_symptoms', data: response['snapshot']),
          type: 'save_symptoms',
          priority: 3,
        ),
      );
    }

    // ✅ Action liste des médicaments (pour les réponses médicamenteuses)
    if (response['type'] == 'medication_list' ||
        response['type'] == 'medication_added' ||
        response['type'] == 'stock_alerts' ||
        response['type'] == 'today_takings') {
      actions.add(
        QuickAction(
          label: '📋 Voir liste',
          icon: Icons.list_alt,
          onTap: () => handleQuickAction('view_medications'),
          type: 'view_medications',
          priority: 4,
        ),
      );
    }

    // Action ajouter un médicament (pour les listes vides)
    if (response['type'] == 'medication_list_empty') {
      actions.add(
        QuickAction(
          label: '➕ Ajouter un médicament',
          icon: Icons.add,
          onTap: () => handleQuickAction('add_medication'),
          type: 'add_medication',
          priority: 1,
        ),
      );
    }

    // ✅ Actions Rendez-vous
    if (response['type'] == 'appointment_added' ||
        response['type'] == 'appointment_list' ||
        response['type'] == 'appointment_today') {
      actions.add(
        QuickAction(
          label: '📅 Voir RDV',
          icon: Icons.calendar_month,
          onTap: () => handleQuickAction('view_appointments'),
          type: 'view_appointments',
          priority: 5,
        ),
      );
      actions.add(
        QuickAction(
          label: '📋 Briefing',
          icon: Icons.info_outline,
          onTap: () =>
              handleQuickAction('generate_briefing', data: response['data']),
          type: 'generate_briefing',
          priority: 6,
        ),
      );
    }

    if (response['type'] == 'appointment_list_empty') {
      actions.add(
        QuickAction(
          label: '📅 Prendre RDV',
          icon: Icons.add,
          onTap: () => handleQuickAction('add_appointment'),
          type: 'add_appointment',
          priority: 1,
        ),
      );
    }

    if (response['type'] == 'appointment_conflict') {
      actions.add(
        QuickAction(
          label: '📅 Voir mes RDV',
          icon: Icons.list_alt,
          onTap: () => handleQuickAction('view_appointments'),
          type: 'view_appointments',
          priority: 1,
        ),
      );
      actions.add(
        QuickAction(
          label: '🔄 Reporter',
          icon: Icons.update,
          onTap: () => handleQuickAction('reschedule'),
          type: 'reschedule',
          priority: 2,
        ),
      );
    }

    // ✅ Actions Scheduler Vocal
    if (response['type'] == 'voice_scheduler') {
      actions.add(
        QuickAction(
          label: '📞 Appeler le cabinet',
          icon: Icons.phone,
          onTap: () =>
              handleQuickAction('voice_schedule', data: response['data']),
          type: 'voice_schedule',
          priority: 1,
        ),
      );
    }

    // Trier par priorité
    actions.sort((a, b) => a.priority.compareTo(b.priority));

    return actions.isNotEmpty ? actions : null;
  }

  /// ✅ Vérifier la santé du service
  Future<bool> checkHealth() async {
    try {
      return await ChatbotService.isServiceAvailable();
    } catch (e) {
      print('❌ Health check error: $e');
      return false;
    }
  }

  /// ✅ Effacer tous les messages
  void clearMessages() {
    _messages.clear();
    _error = null;
    addWelcomeMessage();
    notifyListeners();
  }

  /// ✅ Envoyer un message avec analyse cognitive avancée
  Future<void> sendMessage(String text) async {
    _messages.add(Message.user(text));
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('📤 Message envoyé: $text');

      // ✅ 1. VÉRIFIER D'ABORD LE SCHEDULER VOCAL
      if (ChatbotService.isVoiceSchedulerIntent(text)) {
        print('🔵 Intention Scheduler Vocal détectée');
        final response = await ChatbotService.handleVoiceSchedulerIntent(text);

        if (response['success'] == true) {
          print('✅ Réponse Scheduler Vocal reçue');
          _messages.add(
            Message.bot(
              response['message'],
              severity: _parseSeverity(response['severity']),
              quickActions: _buildQuickActions(response),
            ),
          );
          _isLoading = false;
          notifyListeners();
          return;
        } else {
          print('⚠️ Gestion Scheduler Vocal échouée, passage à l\'IA');
        }
      }

      // ✅ 2. VÉRIFIER LES RENDEZ-VOUS
      if (ChatbotService.isAppointmentIntent(text)) {
        print('🔵 Intention rendez-vous détectée');
        final response = await ChatbotService.handleAppointmentIntent(text);

        if (response['success'] == true) {
          print('✅ Réponse rendez-vous reçue');
          _messages.add(
            Message.bot(
              response['message'],
              severity: _parseSeverity(response['severity']),
              quickActions: _buildQuickActions(response),
            ),
          );
          _isLoading = false;
          notifyListeners();
          return;
        } else {
          print('⚠️ Gestion rendez-vous échouée, passage à l\'IA');
        }
      }

      // ✅ 3. ENSUITE VÉRIFIER LES MÉDICAMENTS
      if (ChatbotService.isMedicationIntent(text)) {
        print('🔵 Intention médicamenteuse détectée');
        final response = await ChatbotService.handleMedicationIntent(text);

        if (response['success'] == true) {
          print('✅ Réponse médicaments reçue');
          _messages.add(
            Message.bot(
              response['message'],
              severity: _parseSeverity(response['severity']),
              quickActions: _buildQuickActions(response),
            ),
          );
          _isLoading = false;
          notifyListeners();
          return;
        } else {
          print('⚠️ Gestion médicaments échouée, passage à l\'IA');
        }
      }

      // ✅ 4. SINON, DÉTECTER SI C'EST UNE REQUÊTE DE SYMPTÔMES
      final isSymptoms = _isSymptomsQuery(text);
      print('🔵 Message standard (symptômes: $isSymptoms)');

      Map<String, dynamic> response;
      if (isSymptoms) {
        response = await ChatbotService.analyzeSymptoms(text);
      } else {
        response = await ChatbotService.sendMessage(text);
      }

      if (response['success'] == true) {
        String content = response['message'] ?? _buildRichMessage(response);
        Severity? severity = _parseSeverity(
          response['severity'] ??
              response['gravite'] ??
              response['severity_label'],
        );
        final actions = _buildQuickActions(response);

        _messages.add(
          Message.bot(content, severity: severity, quickActions: actions),
        );
      } else {
        _messages.add(
          Message.bot(
            'Désolé, je rencontre un problème. Pouvez-vous reformuler ? 🙏',
            severity: Severity.moderate,
          ),
        );
      }
    } on ChatbotException catch (e) {
      _error = e.message;
      final userMessage = e.getUserFriendlyMessage();
      _messages.add(Message.bot(userMessage, severity: Severity.moderate));
    } catch (e) {
      String errorMsg = e.toString();
      _error = errorMsg;

      if (errorMsg.contains('401') || errorMsg.contains('Unauthenticated')) {
        _messages.add(
          Message.bot(
            '🔒 Votre session a expiré. Veuillez vous reconnecter.',
            severity: Severity.moderate,
          ),
        );
      } else if (errorMsg.contains('timeout') || errorMsg.contains('Timeout')) {
        _messages.add(
          Message.bot(
            '⏰ Le serveur met trop de temps à répondre. Veuillez réessayer.',
            severity: Severity.moderate,
          ),
        );
      } else if (errorMsg.contains('500') || errorMsg.contains('Server')) {
        _messages.add(
          Message.bot(
            '🔧 Le serveur rencontre un problème technique. Veuillez réessayer plus tard.',
            severity: Severity.moderate,
          ),
        );
      } else if (errorMsg.contains('404') || errorMsg.contains('Not Found')) {
        _messages.add(
          Message.bot(
            '🔍 Service non disponible. Veuillez contacter le support.',
            severity: Severity.moderate,
          ),
        );
      } else {
        final cleanError = errorMsg
            .replaceFirst('Exception: ', '')
            .replaceFirst('Error: ', '')
            .replaceAll('_', ' ');
        _messages.add(
          Message.bot('❌ Erreur : $cleanError', severity: Severity.moderate),
        );
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// ✅ Construire un message enrichi avec toutes les données d'analyse
  String _buildRichMessage(Map<String, dynamic> response) {
    StringBuffer message = StringBuffer();

    String severityLabel = '🟡 Analyse';
    final gravite = response['gravite'] ?? response['severity'] ?? '';
    switch (gravite) {
      case 'vert':
      case 'low':
        severityLabel = '🟢 Gravité faible';
        break;
      case 'orange':
      case 'moderate':
        severityLabel = '🟠 Gravité modérée';
        break;
      case 'rouge':
      case 'high':
        severityLabel = '🔴 Gravité élevée';
        break;
      case 'urgent':
      case 'emergency':
      case 'critique':
        severityLabel = '🚨 URGENCE !';
        break;
    }
    message.writeln('$severityLabel\n');

    if (response['message'] != null &&
        response['message'] is String &&
        response['message'] != 'Analyse terminée') {
      message.writeln('${response['message']}\n');
    }

    if (response['symptomes'] != null && response['symptomes'].isNotEmpty) {
      final symptomes = response['symptomes'] is List
          ? response['symptomes']
          : [response['symptomes']];
      message.writeln('🩺 **Symptômes détectés :**');
      for (final symptome in symptomes) {
        message.writeln('• $symptome');
      }
      message.writeln('');
    }

    if (response['time_context'] != null) {
      final time = response['time_context'];
      message.writeln('⏰ **Contexte temporel :**');
      if (time['duration'] != null) {
        message.writeln('• Depuis ${time['duration']} ${time['unit'] ?? ''}');
      }
      if (time['human_readable'] != null) {
        message.writeln('• ${time['human_readable']}');
      }
      message.writeln('');
    }

    if (response['possible_causes'] != null &&
        response['possible_causes'].isNotEmpty) {
      final causes = response['possible_causes'] is List
          ? response['possible_causes']
          : [response['possible_causes']];
      message.writeln('🔍 **Causes possibles :**');
      for (final cause in causes) {
        message.writeln('• $cause');
      }
      message.writeln('');
    }

    if (response['questions'] != null && response['questions'].isNotEmpty) {
      final questions = response['questions'] is List
          ? response['questions']
          : [response['questions']];
      message.writeln('❓ **Pour mieux vous aider :**');
      for (final question in questions) {
        message.writeln('• $question');
      }
      message.writeln('');
    }

    if (response['comorbidities'] != null) {
      final comorb = response['comorbidities'];
      if (comorb['interactions'] != null && comorb['interactions'].isNotEmpty) {
        message.writeln('📋 **Contexte médical pris en compte :**');
        for (final interaction in comorb['interactions']) {
          message.writeln('• $interaction');
        }
        message.writeln('');
      }
    }

    if (response['advice'] != null && response['advice'].isNotEmpty) {
      message.writeln('💡 **Conseils :**');
      message.writeln('${response['advice']}\n');
    }

    if (response['recommandation'] != null &&
        response['recommandation'].isNotEmpty) {
      message.writeln('💡 **Recommandation :**');
      message.writeln('${response['recommandation']}\n');
    }

    if (response['emergency_alert'] == true ||
        response['urgence'] == true ||
        gravite == 'rouge') {
      message.writeln('🚨 **⚠️ URGENCE DÉTECTÉE !**');
      message.writeln(
        'Consultez immédiatement un médecin ou appelez le 15 (SAMU).',
      );
      message.writeln('');
    }

    message.writeln('---');
    message.writeln('⚠️ **Rappel important :**');
    message.writeln(
      'Cette analyse ne remplace pas un avis médical professionnel.',
    );
    message.writeln('En cas d\'urgence, contactez le 15.');

    if (response['snapshot'] != null) {
      message.writeln('\n📸 **Snapshot Santé enregistré**');
      message.writeln('Un résumé de cet épisode a été sauvegardé.');
    }

    if (response['confiance'] != null) {
      final confiance = response['confiance'];
      final niveau = confiance >= 80
          ? 'Élevée'
          : (confiance >= 50 ? 'Moyenne' : 'Faible');
      message.writeln(
        '\n🎯 **Confiance de l\'analyse :** $niveau ($confiance%)',
      );
    }

    return message.toString();
  }

  /// ✅ Obtenir les actions rapides comme listes (pour UI)
  List<QuickAction>? getQuickActionsForMessage(int index) {
    if (index < _messages.length) {
      return _messages[index].quickActions;
    }
    return null;
  }

  /// ✅ Supprimer un message spécifique
  void deleteMessage(int index) {
    if (index < _messages.length) {
      _messages.removeAt(index);
      notifyListeners();
    }
  }

  /// ✅ Modifier le dernier message
  void updateLastMessage(String newContent) {
    if (_messages.isNotEmpty) {
      final lastIndex = _messages.length - 1;
      final oldMessage = _messages[lastIndex];
      _messages[lastIndex] = Message.bot(
        newContent,
        severity: oldMessage.severity,
        quickActions: oldMessage.quickActions,
      );
      notifyListeners();
    }
  }

  /// ✅ Ajouter un message système
  void addSystemMessage(String content, {Severity? severity}) {
    _messages.add(Message.bot(content, severity: severity ?? Severity.low));
    notifyListeners();
  }

  /// ✅ Ajouter un message d'urgence
  void addUrgentMessage(String content) {
    _messages.add(
      Message.bot(
        content,
        severity: Severity.urgent,
        quickActions: [
          QuickAction(
            label: '🚨 Appeler le 15',
            icon: Icons.emergency,
            onTap: () => handleQuickAction('emergency'),
            type: 'emergency',
            priority: 0,
          ),
        ],
      ),
    );
    notifyListeners();
  }

  // ==================== GESTION DES ACTIONS ====================

  /// ✅ Gérer les actions rapides
  void handleQuickAction(String type, {dynamic data}) {
    print('⚡ Action: $type');
    print('📦 Data: $data');

    switch (type) {
      case 'view_medications':
        _showMedicationsList();
        break;
      case 'add_medication':
        _showAddMedicationDialog();
        break;
      case 'emergency':
        _triggerEmergency();
        break;
      case 'symptoms':
        _showSymptomsHelp();
        break;
      case 'save_symptoms':
        _saveSymptoms(data);
        break;
      case 'view_appointments':
        _showAppointmentsList();
        break;
      case 'add_appointment':
        _showAddAppointmentDialog();
        break;
      case 'confirm_appointment':
        _confirmAppointment(data);
        break;
      case 'cancel_appointment':
        _cancelAppointment(data);
        break;
      case 'generate_briefing':
        _generateBriefing(data);
        break;
      case 'reschedule':
        _rescheduleAppointment(data);
        break;
      case 'voice_schedule':
        _startVoiceScheduling(data);
        break;
      case 'accept_alternative':
        _acceptAlternative(data);
        break;
      case 'reject_alternative':
        _rejectAlternative(data);
        break;
      case 'view_calls':
        _viewCalls();
        break;
      default:
        print('⚠️ Action non reconnue: $type');
        _messages.add(
          Message.bot(
            '⚠️ Cette fonctionnalité sera bientôt disponible.',
            severity: Severity.low,
          ),
        );
        notifyListeners();
    }
  }

  // ==================== ACTIONS MÉDICAMENTS ====================

  Future<void> _showMedicationsList() async {
    print('📋 Affichage de la liste des médicaments');

    _messages.add(
      Message.bot(
        '📋 Chargement de votre liste de médicaments...',
        severity: Severity.low,
      ),
    );
    notifyListeners();

    try {
      final response = await ChatbotService.handleMedicationIntent(
        'mes médicaments',
      );

      if (response['success'] == true) {
        _messages.add(
          Message.bot(
            response['message'],
            severity: _parseSeverity(response['severity']),
            quickActions: _buildQuickActions(response),
          ),
        );
      } else {
        _messages.add(
          Message.bot(
            '❌ Erreur lors du chargement de la liste.',
            severity: Severity.moderate,
          ),
        );
      }
    } catch (e) {
      _messages.add(
        Message.bot('❌ Erreur: ${e.toString()}', severity: Severity.moderate),
      );
    }
    notifyListeners();
  }

  void _showAddMedicationDialog() {
    print('➕ Ouverture du dialogue d\'ajout de médicament');
    _messages.add(
      Message.bot(
        '💊 Pour ajouter un médicament, tapez :\n\n'
        '"Ajouter mon Doliprane 1000mg que je prends le matin"\n\n'
        'Ou utilisez la reconnaissance vocale 🎤',
        severity: Severity.low,
      ),
    );
    notifyListeners();
  }

  void _triggerEmergency() {
    print('🚨 ALERTE URGENCE DÉCLENCHÉE');
    _messages.add(
      Message.bot(
        '🚨 **ALERTE URGENCE**\n\n'
        'Les secours ont été notifiés.\n'
        'Restez calme et suivez les instructions.',
        severity: Severity.urgent,
        quickActions: [
          QuickAction(
            label: '📞 Appeler le 15',
            icon: Icons.phone,
            onTap: () => handleQuickAction('emergency'),
            type: 'emergency',
            priority: 0,
          ),
        ],
      ),
    );
    notifyListeners();
  }

  void _showSymptomsHelp() {
    print('🩺 Aide symptômes');
    _messages.add(
      Message.bot(
        '🩺 **Analyse des symptômes**\n\n'
        'Décrivez vos symptômes en détail :\n'
        '• Localisation (tête, ventre, poitrine...)\n'
        '• Intensité (légère, modérée, intense)\n'
        '• Durée (depuis combien de temps)\n'
        '• Symptômes associés\n\n'
        'Exemple : "J\'ai mal à la tête depuis 2 jours avec de la fièvre"',
        severity: Severity.low,
      ),
    );
    notifyListeners();
  }

  void _saveSymptoms(dynamic data) {
    print('💾 Sauvegarde des symptômes');
    _messages.add(
      Message.bot(
        '✅ Symptômes enregistrés avec succès !\n\n'
        '📸 Un snapshot de votre état de santé a été créé.',
        severity: Severity.low,
      ),
    );
    notifyListeners();
  }

  // ==================== ACTIONS RENDEZ-VOUS ====================

  Future<void> _showAppointmentsList() async {
    print('📅 Affichage de la liste des rendez-vous');

    _messages.add(
      Message.bot(
        '📅 Chargement de vos rendez-vous...',
        severity: Severity.low,
      ),
    );
    notifyListeners();

    try {
      final appointments = await AppointmentService.getAppointments();

      if (appointments.isEmpty) {
        _messages.add(
          Message.bot(
            '📅 Vous n\'avez aucun rendez-vous enregistré.\n\n'
            'Souhaitez-vous en prendre un ?',
            severity: Severity.low,
            quickActions: [
              QuickAction(
                label: '📅 Prendre RDV',
                icon: Icons.calendar_month,
                onTap: () => handleQuickAction('add_appointment'),
                type: 'add_appointment',
                priority: 1,
              ),
            ],
          ),
        );
        notifyListeners();
        return;
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

      _messages.add(
        Message.bot(
          responseMessage,
          severity: Severity.low,
          quickActions: [
            QuickAction(
              label: '📅 Prendre RDV',
              icon: Icons.calendar_month,
              onTap: () => handleQuickAction('add_appointment'),
              type: 'add_appointment',
              priority: 1,
            ),
            QuickAction(
              label: '📋 Briefing',
              icon: Icons.info_outline,
              onTap: () => handleQuickAction('generate_briefing'),
              type: 'generate_briefing',
              priority: 2,
            ),
          ],
        ),
      );
      notifyListeners();
    } catch (e) {
      _messages.add(
        Message.bot(
          '❌ Erreur lors du chargement des rendez-vous: $e',
          severity: Severity.moderate,
        ),
      );
      notifyListeners();
    }
  }

  void _showAddAppointmentDialog() {
    print('📅 Ouverture du dialogue d\'ajout de rendez-vous');
    _messages.add(
      Message.bot(
        '📅 Pour prendre un rendez-vous, tapez :\n\n'
        '"Prendre rendez-vous avec Dr Martin le 15/07 à 14h"\n\n'
        'Je vous aiderai à vérifier les disponibilités.',
        severity: Severity.low,
      ),
    );
    notifyListeners();
  }

  void _confirmAppointment(dynamic data) {
    print('✅ Confirmation du rendez-vous');
    _messages.add(
      Message.bot(
        '✅ Rendez-vous confirmé avec succès !\n\n'
        '📅 Vous recevrez un rappel 24h avant.',
        severity: Severity.low,
      ),
    );
    notifyListeners();
  }

  void _cancelAppointment(dynamic data) {
    print('❌ Annulation du rendez-vous');
    _messages.add(
      Message.bot(
        '❌ Rendez-vous annulé.\n\n'
        'Vous pouvez en prendre un autre à tout moment.',
        severity: Severity.low,
      ),
    );
    notifyListeners();
  }

  void _generateBriefing(dynamic data) {
    print('📋 Génération du briefing');
    _messages.add(
      Message.bot(
        '📋 **Briefing du rendez-vous**\n\n'
        '📝 Pensez à amener vos analyses.\n'
        '🩺 Voici la liste des symptômes enregistrés cette semaine.\n'
        '💊 N\'oubliez pas la liste de vos médicaments.\n\n'
        '📍 Vérifiez l\'adresse du cabinet.\n'
        '⏰ Arrivez 10 minutes en avance.',
        severity: Severity.low,
      ),
    );
    notifyListeners();
  }

  void _rescheduleAppointment(dynamic data) {
    print('🔄 Report du rendez-vous');
    _messages.add(
      Message.bot(
        '🔄 Pour reporter votre rendez-vous, tapez :\n\n'
        '"Reporter mon rendez-vous avec Dr Martin au 20/07 à 10h"\n\n'
        'Je vérifierai les disponibilités.',
        severity: Severity.low,
      ),
    );
    notifyListeners();
  }

  // ==================== ACTIONS SCHEDULER VOCAL ====================

  /// ✅ Lancer le Scheduler Vocal
  Future<void> _startVoiceScheduling(dynamic data) async {
    print('📞 Démarrage du Scheduler Vocal');
    print('📞 Data: $data');

    if (data == null) {
      _messages.add(
        Message.bot(
          '❌ Informations manquantes pour l\'appel.',
          severity: Severity.moderate,
        ),
      );
      notifyListeners();
      return;
    }

    _messages.add(
      Message.bot(
        '📞 Je vais appeler le cabinet du Dr ${data['doctor_name'] ?? 'Médecin'} pour négocier un créneau...\n\n'
        '⏳ Cela peut prendre quelques minutes. Je vous tiens informé.',
        severity: Severity.low,
      ),
    );
    notifyListeners();

    try {
      final result = await VoiceSchedulerService.startScheduler(
        doctorName: data['doctor_name'] ?? '',
        cabinetPhone: data['cabinet_phone'],
        date: data['date'],
        time: data['time'],
      );

      if (result['success']) {
        final callData = result['data'];
        final status = callData['status'] ?? 'pending';

        switch (status) {
          case 'calling':
            _messages.add(
              Message.bot(
                '📞 J\'appelle le secrétariat du Dr ${data['doctor_name']}...\n\n'
                '⏳ En attente de réponse...',
                severity: Severity.low,
              ),
            );
            break;

          case 'negotiating':
            _showAlternativeProposal(callData);
            break;

          case 'confirmed':
            _showAppointmentConfirmed(callData);
            break;

          default:
            _messages.add(
              Message.bot(
                '📞 Appel en cours...\n\n'
                '🔄 Je vous informerai dès que j\'aurai une réponse.',
                severity: Severity.low,
              ),
            );
        }
      } else {
        _messages.add(
          Message.bot(
            '❌ Impossible de joindre le cabinet.\n\n'
            '${result['message'] ?? 'Veuillez réessayer plus tard.'}',
            severity: Severity.moderate,
            quickActions: [
              QuickAction(
                label: '🔄 Réessayer',
                icon: Icons.refresh,
                onTap: () => handleQuickAction('voice_schedule', data: data),
                type: 'voice_schedule',
                priority: 1,
              ),
              QuickAction(
                label: '📅 Voir autres créneaux',
                icon: Icons.calendar_month,
                onTap: () => handleQuickAction('view_appointments'),
                type: 'view_appointments',
                priority: 2,
              ),
            ],
          ),
        );
      }
      notifyListeners();
    } catch (e) {
      _messages.add(
        Message.bot(
          '❌ Erreur lors de l\'appel: ${e.toString()}',
          severity: Severity.moderate,
        ),
      );
      notifyListeners();
    }
  }

  /// ✅ Afficher une proposition alternative
  void _showAlternativeProposal(Map<String, dynamic> data) {
    print('📞 Créneau alternatif proposé');

    final callId = data['call_id'] ?? 0;
    final alternative = data['alternative'] ?? {};
    final date = alternative['date'] ?? 'Date à préciser';
    final time = alternative['time'] ?? 'Heure à préciser';
    final doctorName = data['doctor_name'] ?? 'Médecin';

    _messages.add(
      Message.bot(
        '📞 **Nouveau créneau proposé !**\n\n'
        'Le secrétariat du Dr $doctorName propose :\n'
        '📅 $date à $time\n\n'
        'Souhaitez-vous accepter ce créneau ?',
        severity: Severity.low,
        quickActions: [
          QuickAction(
            label: '✅ Accepter',
            icon: Icons.check_circle,
            onTap: () => handleQuickAction('accept_alternative', data: callId),
            type: 'accept_alternative',
            priority: 1,
          ),
          QuickAction(
            label: '❌ Refuser',
            icon: Icons.cancel,
            onTap: () => handleQuickAction('reject_alternative', data: callId),
            type: 'reject_alternative',
            priority: 2,
          ),
        ],
      ),
    );
    notifyListeners();
  }

  /// ✅ Accepter un créneau alternatif
  Future<void> _acceptAlternative(dynamic data) async {
    print('✅ Acceptation du créneau alternatif');
    print('📦 Data: $data');

    try {
      final result = await VoiceSchedulerService.acceptAlternative(data);

      if (result['success']) {
        final appointment = result['data']['appointment'] ?? {};
        _showAppointmentConfirmed({
          'appointment': appointment,
          'doctor_name': appointment['medecin_nom'] ?? 'Médecin',
          'date_heure': appointment['date_heure'] ?? 'Date à confirmer',
        });
      } else {
        _messages.add(
          Message.bot(
            '❌ Erreur lors de la confirmation: ${result['message']}',
            severity: Severity.moderate,
          ),
        );
      }
      notifyListeners();
    } catch (e) {
      _messages.add(
        Message.bot('❌ Erreur: ${e.toString()}', severity: Severity.moderate),
      );
      notifyListeners();
    }
  }

  /// ✅ Refuser un créneau alternatif
  Future<void> _rejectAlternative(dynamic data) async {
    print('❌ Refus du créneau alternatif');
    print('📦 Data: $data');

    try {
      final result = await VoiceSchedulerService.rejectAlternative(data);

      if (result['success']) {
        _messages.add(
          Message.bot(
            '❌ Créneau refusé.\n\n'
            'Je vais continuer à chercher d\'autres disponibilités.',
            severity: Severity.low,
            quickActions: [
              QuickAction(
                label: '🔍 Chercher autre chose',
                icon: Icons.search,
                onTap: () => handleQuickAction('view_appointments'),
                type: 'view_appointments',
                priority: 1,
              ),
              QuickAction(
                label: '📞 Rappeler le cabinet',
                icon: Icons.phone,
                onTap: () => handleQuickAction('voice_schedule'),
                type: 'voice_schedule',
                priority: 2,
              ),
            ],
          ),
        );
      }
      notifyListeners();
    } catch (e) {
      _messages.add(
        Message.bot('❌ Erreur: ${e.toString()}', severity: Severity.moderate),
      );
      notifyListeners();
    }
  }

  /// ✅ Afficher la confirmation du rendez-vous
  void _showAppointmentConfirmed(Map<String, dynamic> data) {
    print('✅ Rendez-vous confirmé via Scheduler Vocal');

    final appointment = data['appointment'] ?? {};
    final doctorName = data['doctor_name'] ?? 'Médecin';
    final dateTime = data['date_heure'] ?? 'Date à confirmer';

    _messages.add(
      Message.bot(
        '✅ **Rendez-vous confirmé !**\n\n'
        '🩺 Dr $doctorName\n'
        '📅 $dateTime\n'
        '📍 Cabinet médical\n\n'
        '📋 Un récapitulatif vous a été envoyé par notification.',
        severity: Severity.low,
        quickActions: [
          QuickAction(
            label: '📋 Voir briefing',
            icon: Icons.info_outline,
            onTap: () =>
                handleQuickAction('generate_briefing', data: appointment),
            type: 'generate_briefing',
            priority: 1,
          ),
          QuickAction(
            label: '📅 Voir RDV',
            icon: Icons.calendar_month,
            onTap: () => handleQuickAction('view_appointments'),
            type: 'view_appointments',
            priority: 2,
          ),
        ],
      ),
    );
    notifyListeners();
  }

  /// ✅ Voir l'historique des appels
  Future<void> _viewCalls() async {
    print('📞 Voir l\'historique des appels');

    // TODO: Implémenter la liste des appels
    _messages.add(
      Message.bot(
        '📞 **Historique des appels**\n\n'
        'Fonctionnalité en cours de développement...',
        severity: Severity.low,
      ),
    );
    notifyListeners();
  }
}
