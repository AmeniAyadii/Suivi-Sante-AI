import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Service de communication avec l'API du chatbot IA
class ChatbotService {
  // ==================== CONFIGURATION ====================
  
  /// URL de base du service IA (Python/Flask)
  /// Pour l'émulateur Android : http://10.0.2.2:5000
  /// Pour un vrai téléphone : http://[IP_ORDINATEUR]:5000
  //static const String baseUrl = 'http://192.168.100.85:5000';
  static const String baseUrl = String.fromEnvironment('API_URL', defaultValue: 'http://192.168.1.215:8000/api');
  
  /// Timeout pour les requêtes
  static const Duration timeout = Duration(seconds: 30);
  
  // ==================== MÉTHODES PRINCIPALES ====================
  
  /// Envoyer un message au chatbot et recevoir une réponse
  static Future<Map<String, dynamic>> sendMessage(String message) async {
    try {
      // Récupérer l'ID de l'utilisateur connecté
      final userId = await _getUserId();
      
      // Construire l'URL
      final url = Uri.parse('$baseUrl/chatbot');
      
      // Préparer les données
      final data = {
        'message': message.trim(),
        'user_id': userId,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      print('📤 Envoi au chatbot: $message');
      
      // Envoyer la requête
      final response = await http.post(
        url,
        headers: _getHeaders(),
        body: json.encode(data),
      ).timeout(
        timeout,
        onTimeout: () {
          throw const ChatbotException(
            'Le serveur ne répond pas. Vérifiez que le service IA est démarré.',
            type: ChatbotExceptionType.timeout,
          );
        },
      );
      
      // Traiter la réponse
      return _handleResponse(response);
      
    } on ChatbotException {
      rethrow;
    } catch (e) {
      print('❌ Erreur Chatbot: $e');
      throw ChatbotException(
        'Erreur de connexion au service IA: $e',
        type: ChatbotExceptionType.network,
      );
    }
  }
  
  /// Envoyer un message avec gestion du contexte
  static Future<Map<String, dynamic>> sendMessageWithContext(
    String message, {
    List<Map<String, dynamic>>? context,
  }) async {
    try {
      final userId = await _getUserId();
      final url = Uri.parse('$baseUrl/chatbot');
      
      final data = {
        'message': message.trim(),
        'user_id': userId,
        'context': context ?? [],
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      print('📤 Envoi avec contexte: $message');
      
      final response = await http.post(
        url,
        headers: _getHeaders(),
        body: json.encode(data),
      ).timeout(
        timeout,
        onTimeout: () {
          throw const ChatbotException(
            'Le serveur ne répond pas.',
            type: ChatbotExceptionType.timeout,
          );
        },
      );
      
      return _handleResponse(response);
      
    } on ChatbotException {
      rethrow;
    } catch (e) {
      print('❌ Erreur Chatbot: $e');
      throw ChatbotException(
        'Erreur de connexion: $e',
        type: ChatbotExceptionType.network,
      );
    }
  }
  
  // ==================== MÉTHODES SPÉCIFIQUES ====================
  
  /// Analyser des symptômes
  static Future<Map<String, dynamic>> analyzeSymptoms(String description) async {
    try {
      final userId = await _getUserId();
      final url = Uri.parse('$baseUrl/chatbot/symptomes/analyze');
      
      final data = {
        'description': description.trim(),
        'user_id': userId,
      };
      
      final response = await http.post(
        url,
        headers: _getHeaders(),
        body: json.encode(data),
      ).timeout(
        timeout,
        onTimeout: () {
          throw const ChatbotException(
            'Le serveur ne répond pas.',
            type: ChatbotExceptionType.timeout,
          );
        },
      );
      
      return _handleResponse(response);
      
    } on ChatbotException {
      rethrow;
    } catch (e) {
      throw ChatbotException(
        'Erreur d\'analyse: $e',
        type: ChatbotExceptionType.network,
      );
    }
  }
  
  /// Ajouter un médicament via le chatbot
  static Future<Map<String, dynamic>> addMedicament({
    required String nom,
    required String dosage,
    required String frequence,
    String? prochainePrise,
    String? notes,
  }) async {
    try {
      final userId = await _getUserId();
      final url = Uri.parse('$baseUrl/chatbot/medicament');
      
      final data = {
        'user_id': userId,
        'nom': nom.trim(),
        'dosage': dosage.trim(),
        'frequence': frequence.trim(),
        'prochaine_prise': prochainePrise,
        'notes': notes?.trim(),
        'source': 'chatbot',
      };
      
      print('💊 Ajout médicament via chatbot: $nom');
      
      final response = await http.post(
        url,
        headers: _getHeaders(),
        body: json.encode(data),
      ).timeout(
        timeout,
        onTimeout: () {
          throw const ChatbotException(
            'Le serveur ne répond pas.',
            type: ChatbotExceptionType.timeout,
          );
        },
      );
      
      return _handleResponse(response);
      
    } on ChatbotException {
      rethrow;
    } catch (e) {
      throw ChatbotException(
        'Erreur d\'ajout: $e',
        type: ChatbotExceptionType.network,
      );
    }
  }
  
  /// Enregistrer un symptôme via le chatbot
  static Future<Map<String, dynamic>> saveSymptom({
    required String description,
    int niveau = 1,
    String? notes,
  }) async {
    try {
      final userId = await _getUserId();
      final url = Uri.parse('$baseUrl/chatbot/symptome');
      
      final data = {
        'user_id': userId,
        'description': description.trim(),
        'niveau': niveau.clamp(1, 10),
        'notes': notes?.trim(),
        'source': 'chatbot',
      };
      
      print('🩺 Enregistrement symptôme via chatbot: $description');
      
      final response = await http.post(
        url,
        headers: _getHeaders(),
        body: json.encode(data),
      ).timeout(
        timeout,
        onTimeout: () {
          throw const ChatbotException(
            'Le serveur ne répond pas.',
            type: ChatbotExceptionType.timeout,
          );
        },
      );
      
      return _handleResponse(response);
      
    } on ChatbotException {
      rethrow;
    } catch (e) {
      throw ChatbotException(
        'Erreur d\'enregistrement: $e',
        type: ChatbotExceptionType.network,
      );
    }
  }
  
  /// Récupérer l'historique des conversations
  static Future<List<Map<String, dynamic>>> getHistory({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final userId = await _getUserId();
      final url = Uri.parse('$baseUrl/chatbot/history')
          .replace(queryParameters: {
            'user_id': userId.toString(),
            'limit': limit.toString(),
            'offset': offset.toString(),
          });
      
      print('📜 Récupération de l\'historique...');
      
      final response = await http.get(
        url,
        headers: _getHeaders(),
      ).timeout(
        timeout,
        onTimeout: () {
          throw const ChatbotException(
            'Le serveur ne répond pas.',
            type: ChatbotExceptionType.timeout,
          );
        },
      );
      
      final data = _handleResponse(response);
      
      if (data['success'] == true && data['data'] != null) {
        return List<Map<String, dynamic>>.from(data['data']);
      }
      
      return [];
      
    } on ChatbotException {
      rethrow;
    } catch (e) {
      print('❌ Erreur historique: $e');
      return [];
    }
  }
  
  /// Supprimer l'historique des conversations
  static Future<bool> clearHistory() async {
    try {
      final userId = await _getUserId();
      final url = Uri.parse('$baseUrl/chatbot/history/clear');
      
      final data = {'user_id': userId};
      
      final response = await http.delete(
        url,
        headers: _getHeaders(),
        body: json.encode(data),
      ).timeout(
        timeout,
        onTimeout: () {
          throw const ChatbotException(
            'Le serveur ne répond pas.',
            type: ChatbotExceptionType.timeout,
          );
        },
      );
      
      final result = _handleResponse(response);
      return result['success'] == true;
      
    } on ChatbotException {
      rethrow;
    } catch (e) {
      print('❌ Erreur suppression historique: $e');
      return false;
    }
  }
  
  // ==================== UTILITAIRES ====================
  
  /// Vérifier si le service IA est disponible
  static Future<bool> isServiceAvailable() async {
    try {
      final url = Uri.parse('$baseUrl/health');
      final response = await http.get(
        url,
      ).timeout(const Duration(seconds: 3));
      
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
  
  /// Vérifier l'état du service avec plus de détails
  static Future<Map<String, dynamic>> checkServiceStatus() async {
    try {
      final url = Uri.parse('$baseUrl/health');
      final response = await http.get(
        url,
      ).timeout(const Duration(seconds: 3));
      
      if (response.statusCode == 200) {
        return {
          'available': true,
          'data': json.decode(response.body),
        };
      }
      
      return {
        'available': false,
        'message': 'Service indisponible',
      };
    } catch (e) {
      return {
        'available': false,
        'message': 'Erreur de connexion: $e',
      };
    }
  }
  
  // ==================== MÉTHODES PRIVÉES ====================
  
  /// Récupérer l'ID de l'utilisateur connecté
  static Future<int> _getUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString('user');
      
      if (userData != null) {
        final Map<String, dynamic> userMap = json.decode(userData);
        return userMap['id'] ?? 1;
      }
    } catch (e) {
      print('⚠️ Erreur récupération ID utilisateur: $e');
    }
    
    return 1; // ID par défaut
  }
  
  /// Récupérer les headers HTTP
  static Map<String, String> _getHeaders() {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'User-Agent': 'Flutter-Chatbot/1.0',
    };
  }
  
  /// Traiter la réponse du serveur
  static Map<String, dynamic> _handleResponse(http.Response response) {
    print('📥 Status: ${response.statusCode}');
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        final data = json.decode(response.body);
        return data;
      } catch (e) {
        throw ChatbotException(
          'Erreur de parsing de la réponse: $e',
          type: ChatbotExceptionType.parsing,
        );
      }
    } else if (response.statusCode == 404) {
      throw const ChatbotException(
        'Service IA non trouvé. Vérifiez l\'URL.',
        type: ChatbotExceptionType.notFound,
      );
    } else if (response.statusCode == 500) {
      throw const ChatbotException(
        'Erreur interne du serveur.',
        type: ChatbotExceptionType.server,
      );
    } else if (response.statusCode == 429) {
      throw const ChatbotException(
        'Trop de requêtes. Veuillez patienter.',
        type: ChatbotExceptionType.rateLimit,
      );
    } else {
      throw ChatbotException(
        'Erreur du serveur (${response.statusCode})',
        type: ChatbotExceptionType.unknown,
      );
    }
  }
}

// ==================== EXCEPTIONS PERSONNALISÉES ====================

/// Types d'exceptions du chatbot
enum ChatbotExceptionType {
  network,
  timeout,
  server,
  parsing,
  notFound,
  rateLimit,
  unknown,
  unauthorized,
}

/// Exception personnalisée pour le chatbot
class ChatbotException implements Exception {
  final String message;
  final ChatbotExceptionType type;
  final dynamic originalError;
  
  const ChatbotException(
    this.message, {
    this.type = ChatbotExceptionType.unknown,
    this.originalError,
  });
  
  @override
  String toString() {
    return 'ChatbotException: $message (Type: $type)';
  }
  
  /// Obtenir un message utilisateur adapté
  String getUserFriendlyMessage() {
    switch (type) {
      case ChatbotExceptionType.network:
        return 'Problème de connexion réseau. Vérifiez votre connexion.';
      case ChatbotExceptionType.timeout:
        return 'Le serveur ne répond pas. Veuillez réessayer.';
      case ChatbotExceptionType.server:
        return 'Problème technique sur le serveur. Réessayez plus tard.';
      case ChatbotExceptionType.parsing:
        return 'Erreur de communication avec le serveur.';
      case ChatbotExceptionType.notFound:
        return 'Service IA non disponible.';
      case ChatbotExceptionType.rateLimit:
        return 'Trop de requêtes. Veuillez patienter.';
      case ChatbotExceptionType.unauthorized:
        return 'Session expirée. Veuillez vous reconnecter.';
      default:
        return message.isNotEmpty ? message : 'Une erreur est survenue.';
    }
  }
}

// ==================== MODÈLE DE CONVERSATION ====================

/// Modèle de message pour l'interface utilisateur
class ChatMessage {
  final String id;
  final String message;
  final bool isUser;
  final DateTime timestamp;
  final String? type;
  final Map<String, dynamic>? metadata;
  final bool isError;
  
  ChatMessage({
    this.id = '',
    required this.message,
    required this.isUser,
    DateTime? timestamp,
    this.type,
    this.metadata,
    this.isError = false,
  }) : timestamp = timestamp ?? DateTime.now();
  
  /// Créer un message utilisateur
  factory ChatMessage.user(String message) {
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      message: message,
      isUser: true,
    );
  }
  
  /// Créer un message du chatbot
  factory ChatMessage.bot(String message, {String? type, Map<String, dynamic>? metadata}) {
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      message: message,
      isUser: false,
      type: type,
      metadata: metadata,
    );
  }
  
  /// Créer un message d'erreur
  factory ChatMessage.error(String message) {
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      message: message,
      isUser: false,
      isError: true,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'message': message,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
      'type': type,
      'metadata': metadata,
      'isError': isError,
    };
  }
  
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] ?? '',
      message: json['message'] ?? '',
      isUser: json['isUser'] ?? false,
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp']) 
          : null,
      type: json['type'],
      metadata: json['metadata'],
      isError: json['isError'] ?? false,
    );
  }
}

// ==================== CONSTANTES ====================

/// Constantes pour les types de messages
class ChatMessageType {
  static const String welcome = 'welcome';
  static const String symptom = 'symptom';
  static const String medication = 'medication';
  static const String appointment = 'appointment';
  static const String general = 'general';
  static const String help = 'help';
  static const String urgent = 'urgent';
  static const String error = 'error';
  static const String info = 'info';
  static const String greeting = 'greeting';
}