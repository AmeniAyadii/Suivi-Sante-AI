import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../services/chatbot_service.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen>
    with TickerProviderStateMixin {
  // ==================== CONTRÔLEURS ====================
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  final ScrollController _scrollController = ScrollController();

  // ==================== RECONNAISSANCE VOCALE ====================
  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool _isLoading = false;
  bool _isTyping = false;

  // ==================== ANIMATIONS ====================
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // ==================== SUJETS DE CONVERSATION ====================
  String _currentTopic = 'general';
  final Map<String, dynamic> _conversationContext = {};

  // ==================== SUGGESTIONS ====================
  final List<Map<String, dynamic>> _quickSuggestions = [
    {'icon': '🩺', 'label': 'Analyser symptômes', 'action': 'Analyser mes symptômes'},
    {'icon': '💊', 'label': 'Ajouter médicament', 'action': 'Ajouter un médicament'},
    {'icon': '📅', 'label': 'Voir rendez-vous', 'action': 'Voir mes rendez-vous'},
    {'icon': '💡', 'label': 'Conseils santé', 'action': 'Conseils santé'},
    {'icon': '📋', 'label': 'Mon profil', 'action': 'Afficher mon profil'},
    {'icon': '❓', 'label': 'Aide', 'action': 'Que pouvez-vous faire ?'},
  ];

  // ==================== INITIALISATION ====================
  @override
  void initState() {
    super.initState();
    _initAnimations();
    _initializeSpeech();
    _addWelcomeMessage();
    _checkServerStatus();
  }

  void _initAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    _animationController.forward();
  }

  void _initializeSpeech() {
    _speech = stt.SpeechToText();
  }

  void _addWelcomeMessage() {
    final now = DateTime.now();
    final greeting = _getGreeting();

    _messages.add({
      'role': 'bot',
      'message':
          '$greeting ! 👋\n\nJe suis votre **assistant santé intelligent**.\n\n'
          '💪 **Je peux vous aider avec :**\n\n'
          '🩺 **Analyser vos symptômes**\n'
          '• Décrivez vos symptômes\n'
          '• Je vous donnerai des recommandations\n'
          '• Je détecterai les urgences\n\n'
          '💊 **Gérer vos médicaments**\n'
          '• Ajouter un médicament\n'
          '• Rappels de prise\n'
          '• Vérifier les interactions\n\n'
          '📅 **Gérer vos rendez-vous**\n'
          '• Ajouter un rendez-vous\n'
          '• Voir vos rendez-vous\n'
          '• Modifier ou annuler\n\n'
          '🗣️ **Utilisez le microphone** pour dicter votre message.\n\n'
          'Comment puis-je vous aider aujourd\'hui ?',
      'timestamp': now,
      'type': 'welcome',
      'actions': ['Analyser mes symptômes', 'Ajouter un médicament', 'Voir mes rendez-vous'],
    });
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bonjour';
    if (hour < 18) return 'Bon après-midi';
    return 'Bonsoir';
  }

  Future<void> _checkServerStatus() async {
    final status = await ChatbotService.isServiceAvailable();
    if (!status && mounted) {
      setState(() {
        _messages.add({
          'role': 'bot',
          'message': '⚠️ **Service IA indisponible**\n\n'
              'Le service IA est actuellement hors ligne.\n\n'
              '💡 **Vérifiez que :**\n'
              '• Le serveur Python est démarré\n'
              '• La commande : `python run.py` dans `ai_service`\n\n'
              'Je peux quand même répondre avec ma base de connaissances !',
          'timestamp': DateTime.now(),
          'isError': true,
          'type': 'error',
        });
      });
    }
  }

  // ==================== ENVOI DE MESSAGE ====================
  Future<void> _sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    // Ajouter le message utilisateur
    setState(() {
      _messages.add({
        'role': 'user',
        'message': message.trim(),
        'timestamp': DateTime.now(),
        'type': 'user',
      });
      _isLoading = true;
      _isTyping = true;
    });

    _scrollToBottom();

    try {
      final response = await ChatbotService.sendMessage(message.trim());

      setState(() => _isTyping = false);

      if (response['type'] != 'error') {
        String botResponse = response['message'] ?? 
            'Je n\'ai pas compris. Pouvez-vous reformuler ?';
        
        // Ajouter des actions suggérées
        List<String> actions = [];
        if (response['suggestions'] != null && response['suggestions'] is List) {
          actions = List<String>.from(response['suggestions']);
        }

        setState(() {
          _messages.add({
            'role': 'bot',
            'message': botResponse,
            'timestamp': DateTime.now(),
            'type': response['type'] ?? 'info',
            'actions': actions,
            'data': response['data'],
          });
        });

        // Traiter les actions spécifiques
        await _handleSpecificActions(response);

      } else {
        setState(() {
          _messages.add({
            'role': 'bot',
            'message': '⚠️ ${response['message'] ?? 'Une erreur est survenue'}',
            'timestamp': DateTime.now(),
            'isError': true,
            'type': 'error',
          });
        });
      }
    } on ChatbotException catch (e) {
      setState(() => _isTyping = false);
      setState(() {
        _messages.add({
          'role': 'bot',
          'message': '⚠️ **Erreur**\n\n${e.getUserFriendlyMessage()}\n\n'
              '💡 Vérifiez votre connexion au serveur IA.',
          'timestamp': DateTime.now(),
          'isError': true,
          'type': 'error',
        });
      });
    } catch (e) {
      setState(() => _isTyping = false);
      setState(() {
        _messages.add({
          'role': 'bot',
          'message': '⚠️ **Erreur inattendue**\n\n$e',
          'timestamp': DateTime.now(),
          'isError': true,
          'type': 'error',
        });
      });
    } finally {
      setState(() => _isLoading = false);
      _scrollToBottom();
    }
  }

  Future<void> _handleSpecificActions(Map<String, dynamic> response) async {
    final type = response['type'];
    final data = response['data'];

    // Analyse des symptômes
    if (type == 'symptom_analysis' && data != null) {
      _showSymptomAnalysisDialog(data);
    }

    // Ajout de médicament
    if (type == 'medication_add' && data != null) {
      _showMedicationAddedDialog(data);
    }

    // Ajout de rendez-vous
    if (type == 'appointment_add' && data != null) {
      _showAppointmentAddedDialog(data);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ==================== RECONNAISSANCE VOCALE ====================
  Future<void> _startListening() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (status) {
          if (status == 'done') {
            setState(() => _isListening = false);
          }
        },
        onError: (error) {
          setState(() => _isListening = false);
          _showSnackBar('Erreur de reconnaissance vocale', Colors.red);
        },
      );

      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (result) {
            setState(() {
              _messageController.text = result.recognizedWords;
            });
          },
          listenFor: const Duration(seconds: 10),
          pauseFor: const Duration(seconds: 5),
          partialResults: true,
          localeId: 'fr_FR',
        );
      } else {
        _showSnackBar('Reconnaissance vocale non disponible', Colors.orange);
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  // ==================== ACTIONS RAPIDES ====================
  void _sendQuickSuggestion(String suggestion) {
    _messageController.text = suggestion;
    _sendMessage(suggestion);
  }

  void _sendAction(String action) {
    _sendMessage(action);
  }

  // ==================== DIALOGUES ====================
  void _showSymptomAnalysisDialog(Map<String, dynamic> data) {
    final symptoms = data['symptoms'] ?? [];
    final severity = data['severity'] ?? {};
    final recommendations = data['recommendations'] ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '🩺 Analyse des symptômes',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(),
            // Content
            Flexible(flex: 1, child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Symptômes détectés
                    const Text(
                      '🔍 Symptômes détectés',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: symptoms.map((symptom) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.blue.shade200,
                            ),
                          ),
                          child: Text(
                            symptom,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Niveau de gravité
                    const Text(
                      '📊 Niveau de gravité',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _getSeverityColor(severity['level'] ?? 'moderate')
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _getSeverityColor(severity['level'] ?? 'moderate')
                              .withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _getSeverityIcon(severity['level'] ?? 'moderate'),
                            color: _getSeverityColor(severity['level'] ?? 'moderate'),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getSeverityLabel(severity['level'] ?? 'moderate'),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: _getSeverityColor(severity['level'] ?? 'moderate'),
                                ),
                              ),
                              Text(
                                severity['description'] ?? 'Surveillez vos symptômes',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Recommandations
                    if (recommendations.isNotEmpty) ...[
                      const Text(
                        '📋 Recommandations',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...recommendations.map((rec) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                rec.contains('⚠️') ? Icons.warning : Icons.check_circle,
                                color: rec.contains('⚠️') ? Colors.orange : Colors.green,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  rec,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                    const SizedBox(height: 16),

                    // Avertissement
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.orange.shade200,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.orange,
                          ),
                          const SizedBox(width: 12),
                          const Flexible(
                            child: Text(
                              'Ceci n\'est pas un avis médical professionnel. Consultez toujours un médecin.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.orange,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Boutons d'action
                    Row(
                      children: [
                        Flexible(flex: 1, child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _sendMessage('Enregistrer ces symptômes');
                            },
                            icon: const Icon(Icons.save),
                            label: const Text('Enregistrer'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade700,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(flex: 1, child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _sendMessage('Prendre rendez-vous avec un médecin');
                            },
                            icon: const Icon(Icons.calendar_month),
                            label: const Text('Prendre RDV'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.blue.shade700,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMedicationAddedDialog(Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Row(
          children: [
            Icon(Icons.medication, color: Colors.green),
            SizedBox(width: 12),
            Text('💊 Médicament ajouté'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '✅ ${data['nom'] ?? 'Médicament'}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (data['dosage'] != null)
              Text('💊 Dosage: ${data['dosage']}'),
            if (data['frequence'] != null)
              Text('🔄 Fréquence: ${data['frequence']}'),
            if (data['prochaine_prise'] != null)
              Text(
                '⏰ Prochaine prise: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(data['prochaine_prise']))}',
              ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.notifications, color: Colors.green, size: 16),
                  SizedBox(width: 8),
                  Text(
                    'Un rappel a été programmé',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showAppointmentAddedDialog(Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Row(
          children: [
            Icon(Icons.calendar_month, color: Colors.blue),
            SizedBox(width: 12),
            Text('📅 Rendez-vous ajouté'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '✅ ${data['titre'] ?? 'Rendez-vous'}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (data['medecin'] != null)
              Text('👨‍⚕️ ${data['medecin']}'),
            if (data['date'] != null)
              Text('📅 Date: ${data['date']}'),
            if (data['heure'] != null)
              Text('⏰ Heure: ${data['heure']}'),
            if (data['lieu'] != null)
              Text('📍 Lieu: ${data['lieu']}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // ==================== UTILITAIRES DE SÉVÉRITÉ ====================
  Color _getSeverityColor(String level) {
    switch (level) {
      case 'low':
        return Colors.green;
      case 'moderate':
        return Colors.orange;
      case 'high':
        return Colors.red;
      case 'critical':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getSeverityIcon(String level) {
    switch (level) {
      case 'low':
        return Icons.sentiment_satisfied;
      case 'moderate':
        return Icons.sentiment_neutral;
      case 'high':
        return Icons.sentiment_dissatisfied;
      case 'critical':
        return Icons.error;
      default:
        return Icons.help;
    }
  }

  String _getSeverityLabel(String level) {
    switch (level) {
      case 'low':
        return '🟢 Faible';
      case 'moderate':
        return '🟡 Modéré';
      case 'high':
        return '🔴 Élevé';
      case 'critical':
        return '🚨 Critique';
      default:
        return 'Non défini';
    }
  }

  // ==================== MÉTADONNÉES ====================
  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _clearChat() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Effacer la conversation'),
        content: const Text('Voulez-vous vraiment effacer tout l\'historique ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              await ChatbotService.clearHistory();
              setState(() {
                _messages.clear();
                _addWelcomeMessage();
              });
              Navigator.pop(context);
              _showSnackBar('Conversation effacée', Colors.blue);
            },
            child: const Text(
              'Effacer',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== DISPOSE ====================
  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _animationController.dispose();
    if (_isListening) {
      _speech.stop();
    }
    super.dispose();
  }

  // ==================== BUILD ====================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  // ==================== APP BAR ====================
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.health_and_safety,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Assistant Santé IA',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                'Intelligent • Sécurisé',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ],
      ),
      backgroundColor: Colors.green.shade700,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _checkServerStatus,
          tooltip: 'Vérifier le serveur',
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: _clearChat,
          tooltip: 'Effacer la conversation',
        ),
      ],
    );
  }

  // ==================== BODY ====================
  Widget _buildBody() {
    return Column(
      children: [
        Flexible(flex: 1, child: _messages.isEmpty
              ? _buildEmptyState()
              : _buildMessagesList(),
        ),
        if (_isTyping) _buildTypingIndicator(),
        _buildQuickSuggestions(),
        _buildInputArea(),
      ],
    );
  }

  // ==================== ÉTAT VIDE ====================
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.chat_bubble_outline,
              size: 60,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Assistant Santé IA',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Posez vos questions santé',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== LISTE DES MESSAGES ====================
  Widget _buildMessagesList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final msg = _messages[index];
        final isUser = msg['role'] == 'user';
        final isError = msg['isError'] ?? false;

        return Animate(
          effects: [
            FadeEffect(duration: 300.ms),
            MoveEffect(
              duration: 300.ms,
              begin: Offset(isUser ? 20 : -20, 0),
              end: Offset.zero,
            ),
          ],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMessageBubble(msg, isUser, isError),
              if (!isUser && msg['actions'] != null && (msg['actions'] as List).isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 56, top: 8),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: (msg['actions'] as List).map((action) {
                      return ActionChip(
                        label: Text(
                          action,
                          style: const TextStyle(fontSize: 12),
                        ),
                        onPressed: () => _sendAction(action),
                        backgroundColor: Colors.blue.shade50,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: Colors.blue.shade200,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // ==================== BULLE DE MESSAGE ====================
  Widget _buildMessageBubble(Map<String, dynamic> msg, bool isUser, bool isError) {
    final timestamp = msg['timestamp'] as DateTime?;
    final message = msg['message'] as String;
    final type = msg['type'] ?? '';

    return Padding(
      padding: EdgeInsets.only(
        bottom: 12,
        left: isUser ? 60 : 0,
        right: isUser ? 0 : 60,
      ),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser)
            Container(
              margin: const EdgeInsets.only(right: 8),
              child: CircleAvatar(
                radius: 20,
                backgroundColor: Colors.green.shade700,
                child: const Icon(
                  Icons.health_and_safety,
                  size: 22,
                  color: Colors.white,
                ),
              ),
            ),
          Flexible(flex: 1, child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isUser
                    ? Colors.blue.shade600
                    : isError
                        ? Colors.red.shade50
                        : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: isUser ? const Radius.circular(16) : const Radius.circular(4),
                  topRight: isUser ? const Radius.circular(4) : const Radius.circular(16),
                  bottomLeft: const Radius.circular(16),
                  bottomRight: const Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (type.isNotEmpty && !isUser)
                    Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _getTypeLabel(type),
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  if (isError)
                    const Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.orange,
                          size: 16,
                        ),
                        SizedBox(width: 4),
                        Text(
                          '⚠️ Attention',
                          style: TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  Text(
                    message,
                    style: TextStyle(
                      color: isUser ? Colors.white : Colors.black87,
                      fontSize: 15,
                      height: 1.6,
                    ),
                  ),
                  if (timestamp != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        _formatTime(timestamp),
                        style: TextStyle(
                          color: isUser
                              ? Colors.white.withOpacity(0.6)
                              : Colors.grey.shade500,
                          fontSize: 10,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (isUser)
            Container(
              margin: const EdgeInsets.only(left: 8),
              child: CircleAvatar(
                radius: 20,
                backgroundColor: Colors.blue.shade600,
                child: const Icon(
                  Icons.person,
                  size: 22,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _getTypeLabel(String type) {
    final labels = {
      'symptom_analysis': '🩺 Analyse des symptômes',
      'medication_add': '💊 Médicament',
      'medication_info': '💊 Information',
      'appointment': '📅 Rendez-vous',
      'greeting': '👋 Salutation',
      'help': '❓ Aide',
      'urgent': '🚨 Urgence',
      'general': '💡 Information',
    };
    return labels[type] ?? '💡 Information';
  }

  // ==================== INDICATEUR DE FRAPPE ====================
  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.green.shade700,
            child: const Icon(
              Icons.health_and_safety,
              size: 16,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDotAnimation(0),
                const SizedBox(width: 4),
                _buildDotAnimation(1),
                const SizedBox(width: 4),
                _buildDotAnimation(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDotAnimation(int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: Colors.green.shade400,
        shape: BoxShape.circle,
      ),
    );
  }

  // ==================== SUGGESTIONS RAPIDES ====================
  Widget _buildQuickSuggestions() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _quickSuggestions.length,
        itemBuilder: (context, index) {
          final suggestion = _quickSuggestions[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ActionChip(
              avatar: Text(
                suggestion['icon'],
                style: const TextStyle(fontSize: 16),
              ),
              label: Text(
                suggestion['label'],
                style: const TextStyle(fontSize: 12),
              ),
              onPressed: () => _sendQuickSuggestion(suggestion['action']),
              backgroundColor: Colors.white,
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: Colors.grey.shade300,
                  width: 0.5,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ==================== ZONE DE SAISIE ====================
  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Bouton microphone
            IconButton(
              icon: Icon(
                _isListening ? Icons.stop_circle : Icons.mic,
                color: _isListening ? Colors.red : Colors.green.shade700,
                size: 30,
              ),
              onPressed: _startListening,
              tooltip: _isListening ? 'Arrêter l\'écoute' : 'Démarrer l\'écoute',
            ),
            // Champ de saisie
            Flexible(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: _isListening ? Colors.red : Colors.grey.shade300,
                    width: 1,
                  ),
                ),
                child: TextField(
                  controller: _messageController,
                  maxLines: null,
                  minLines: 1,
                  decoration: InputDecoration(
                    hintText: _isListening
                        ? '🎤 Écoute en cours...'
                        : 'Écrivez votre message...',
                    hintStyle: TextStyle(
                      color: _isListening ? Colors.red : Colors.grey.shade500,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  style: const TextStyle(fontSize: 16),
                  onSubmitted: (value) {
                    if (value.trim().isNotEmpty) {
                      _sendMessage(value);
                      _messageController.clear();
                    }
                  },
                  enabled: !_isListening,
                ),
              ),
            ),
            // Bouton d'envoi
            IconButton(
              icon: Icon(
                Icons.send_rounded,
                color: _messageController.text.trim().isNotEmpty
                    ? Colors.green.shade700
                    : Colors.grey.shade400,
                size: 28,
              ),
              onPressed: _messageController.text.trim().isNotEmpty
                  ? () {
                      _sendMessage(_messageController.text);
                      _messageController.clear();
                    }
                  : null,
              tooltip: 'Envoyer',
            ),
          ],
        ),
      ),
    );
  }

  // ==================== UTILITAIRES ====================
  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'À l\'instant';
    } else if (difference.inMinutes < 60) {
      return 'Il y a ${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return 'Il y a ${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays}j';
    } else {
      return '${time.day}/${time.month}/${time.year}';
    }
  }
}

