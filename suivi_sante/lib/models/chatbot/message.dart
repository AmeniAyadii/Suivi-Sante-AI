import 'package:flutter/material.dart';

/// Types de messages
enum MessageType {
  user,      // Message de l'utilisateur
  bot,       // Message du bot
  system,    // Message système
  urgent,    // Message d'urgence
}

/// Niveaux de gravité
enum Severity {
  low,       // Vert - Faible
  moderate,  // Orange - Modéré
  high,      // Rouge - Élevé
  urgent,    // 🔴 - Urgence immédiate
}

/// Actions rapides
class QuickAction {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final String type;
  final int priority;

  QuickAction({
    required this.label,
    required this.icon,
    required this.onTap,
    this.type = '',
    this.priority = 0,
  });

  // Convertir en Map pour JSON
  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'icon': icon.codePoint,
      'iconFontFamily': icon.fontFamily,
      'type': type,
      'priority': priority,
    };
  }

  // Créer depuis JSON
  factory QuickAction.fromJson(Map<String, dynamic> json) {
    return QuickAction(
      label: json['label'] ?? 'Action',
      icon: IconData(
        json['icon'] ?? 0xe0b0,
        fontFamily: json['iconFontFamily'] ?? 'MaterialIcons',
      ),
      type: json['type'] ?? '',
      priority: json['priority'] ?? 0,
      onTap: () {}, // OnTap ne peut pas être sérialisé
    );
  }
}

/// Modèle de message
class Message {
  final String id;
  final String content;
  final String? shortContent;
  final MessageType type;
  final DateTime timestamp;
  final Severity? severity;
  final bool isUrgent;
  final List<String>? symptoms;
  final List<String>? questions;
  final int confidence;
  final String? recommendation;
  final Map<String, dynamic>? snapshot;
  final List<QuickAction>? quickActions;
  final Map<String, dynamic>? rawData;

  Message({
    required this.id,
    required this.content,
    this.shortContent,
    required this.type,
    DateTime? timestamp,
    this.severity,
    this.isUrgent = false,
    this.symptoms,
    this.questions,
    this.confidence = 0,
    this.recommendation,
    this.snapshot,
    this.quickActions,
    this.rawData,
  }) : timestamp = timestamp ?? DateTime.now();

  // ---- Constructeurs simplifiés ----

  /// Message de l'utilisateur
  factory Message.user(String content) {
    return Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      type: MessageType.user,
    );
  }

  /// Message du bot (simple)
  factory Message.bot(
    String content, {
    Severity? severity,
    bool isUrgent = false,
    List<QuickAction>? quickActions,
    List<String>? symptoms,
    List<String>? questions,
    int confidence = 0,
    String? recommendation,
    Map<String, dynamic>? snapshot,
  }) {
    return Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      type: MessageType.bot,
      severity: severity,
      isUrgent: isUrgent,
      quickActions: quickActions,
      symptoms: symptoms,
      questions: questions,
      confidence: confidence,
      recommendation: recommendation,
      snapshot: snapshot,
    );
  }

  /// Message d'urgence
  factory Message.urgent(String content) {
    return Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      type: MessageType.urgent,
      severity: Severity.urgent,
      isUrgent: true,
    );
  }

  /// Message système
  factory Message.system(String content) {
    return Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      type: MessageType.system,
    );
  }

  // ---- Constructeur depuis l'API ----

  /// Créer un message depuis la réponse de l'API
  factory Message.fromApiResponse(Map<String, dynamic> json, {required MessageType type}) {
    // Parser la gravité
    Severity? severity;
    if (json['gravite'] != null) {
      switch (json['gravite']) {
        case 'vert':
          severity = Severity.low;
          break;
        case 'orange':
          severity = Severity.moderate;
          break;
        case 'rouge':
          severity = Severity.high;
          break;
        case 'urgent':
          severity = Severity.urgent;
          break;
      }
    }

    // Le message formaté est déjà prêt !
    String content = json['message'] ?? json['resume'] ?? 'Je n\'ai pas pu générer de réponse.';
    String? shortContent = json['short_message'];

    // Construire les actions rapides
    List<QuickAction> actions = [];
    if (json['quick_actions'] != null && json['quick_actions'] is List) {
      for (var action in json['quick_actions']) {
        actions.add(QuickAction(
          label: action['label'] ?? 'Action',
          icon: _getIconFromString(action['icon'] ?? ''),
          onTap: () {},
          type: action['type'] ?? '',
          priority: action['priority'] ?? 0,
        ));
      }
    }

    // Si pas d'actions dans la réponse, en générer
    if (actions.isEmpty) {
      if (json['urgence'] == true) {
        actions.add(QuickAction(
          label: '🚨 Appeler le 15',
          icon: Icons.emergency,
          onTap: () {},
          type: 'emergency',
          priority: 1,
        ));
      }
      if (json['gravite'] == 'orange' || json['gravite'] == 'rouge') {
        actions.add(QuickAction(
          label: '📅 Prendre RDV',
          icon: Icons.calendar_month,
          onTap: () {},
          type: 'appointment',
          priority: 2,
        ));
      }
      if (json['gravite'] == 'vert' || json['gravite'] == 'low') {
        actions.add(QuickAction(
          label: '💾 Enregistrer',
          icon: Icons.save,
          onTap: () {},
          type: 'save',
          priority: 3,
        ));
      }
    }

    return Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      shortContent: shortContent,
      type: type,
      severity: severity,
      isUrgent: json['urgence'] ?? false,
      symptoms: json['symptomes'] != null ? List<String>.from(json['symptomes']) : null,
      questions: json['questions'] != null ? List<String>.from(json['questions']) : null,
      confidence: json['confiance'] ?? 0,
      recommendation: json['recommandation'],
      snapshot: json['snapshot'],
      quickActions: actions.isNotEmpty ? actions : null,
      rawData: json,
    );
  }

  /// Convertir un nom d'icône en IconData
  static IconData _getIconFromString(String iconName) {
    switch (iconName) {
      case 'emergency':
        return Icons.emergency;
      case 'calendar_month':
        return Icons.calendar_month;
      case 'save':
        return Icons.save;
      case 'medication':
        return Icons.medication;
      case 'health_and_safety':
        return Icons.health_and_safety;
      case 'warning':
        return Icons.warning;
      default:
        return Icons.smart_button;
    }
  }

  // ========== MÉTHODES JSON ==========
  
  /// Convertir en Map pour JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'shortContent': shortContent,
      'type': type.toString().split('.').last,
      'timestamp': timestamp.toIso8601String(),
      'severity': severity?.toString().split('.').last,
      'isUrgent': isUrgent,
      'symptoms': symptoms,
      'questions': questions,
      'confidence': confidence,
      'recommendation': recommendation,
      'snapshot': snapshot,
      'quickActions': quickActions?.map((e) => e.toJson()).toList(),
      'rawData': rawData,
    };
  }

  /// Créer un Message depuis JSON
  factory Message.fromJson(Map<String, dynamic> json) {
    // Parser le type
    MessageType type = MessageType.user;
    final typeStr = json['type'] as String? ?? '';
    switch (typeStr) {
      case 'user':
        type = MessageType.user;
        break;
      case 'bot':
        type = MessageType.bot;
        break;
      case 'system':
        type = MessageType.system;
        break;
      case 'urgent':
        type = MessageType.urgent;
        break;
    }

    // Parser la sévérité
    Severity? severity;
    final severityStr = json['severity'] as String?;
    if (severityStr != null) {
      switch (severityStr) {
        case 'low':
          severity = Severity.low;
          break;
        case 'moderate':
          severity = Severity.moderate;
          break;
        case 'high':
          severity = Severity.high;
          break;
        case 'urgent':
          severity = Severity.urgent;
          break;
      }
    }

    // Parser les actions rapides
    List<QuickAction>? quickActions;
    if (json['quickActions'] != null && json['quickActions'] is List) {
      quickActions = (json['quickActions'] as List)
          .map((e) => QuickAction.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return Message(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      content: json['content'] ?? '',
      shortContent: json['shortContent'],
      type: type,
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      severity: severity,
      isUrgent: json['isUrgent'] ?? false,
      symptoms: json['symptoms'] != null 
          ? List<String>.from(json['symptoms'])
          : null,
      questions: json['questions'] != null
          ? List<String>.from(json['questions'])
          : null,
      confidence: json['confidence'] ?? 0,
      recommendation: json['recommendation'],
      snapshot: json['snapshot'],
      quickActions: quickActions,
      rawData: json['rawData'],
    );
  }

  /// Vérifier si le message est du bot
  bool get isBot => type == MessageType.bot;

  /// Vérifier si le message est de l'utilisateur
  bool get isUser => type == MessageType.user;

  /// Obtenir la couleur associée à la sévérité
  Color get severityColor {
    switch (severity) {
      case Severity.low:
        return Colors.green;
      case Severity.moderate:
        return Colors.orange;
      case Severity.high:
        return Colors.red;
      case Severity.urgent:
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }

  /// Obtenir le label de la sévérité
  String get severityLabel {
    switch (severity) {
      case Severity.low:
        return 'Faible';
      case Severity.moderate:
        return 'Modéré';
      case Severity.high:
        return 'Élevé';
      case Severity.urgent:
        return '⚠️ URGENT';
      default:
        return 'Inconnu';
    }
  }

  /// Obtenir l'icône de la sévérité
  IconData get severityIcon {
    switch (severity) {
      case Severity.low:
        return Icons.check_circle_outline;
      case Severity.moderate:
        return Icons.warning_amber_outlined;
      case Severity.high:
        return Icons.error_outline;
      case Severity.urgent:
        return Icons.emergency;
      default:
        return Icons.help_outline;
    }
  }
}