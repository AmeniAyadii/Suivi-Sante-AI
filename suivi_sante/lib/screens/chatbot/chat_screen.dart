// lib/screens/chatbot/chat_screen.dart

import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

import 'package:suivi_sante_pro/models/chatbot/message.dart';
import 'package:suivi_sante_pro/providers/chatbot/chat_provider.dart';
import 'package:suivi_sante_pro/widgets/chatbot/chat_bubble.dart';
import 'package:suivi_sante_pro/widgets/chatbot/message_input.dart';
import 'package:suivi_sante_pro/widgets/chatbot/typing_indicator.dart';
import 'package:suivi_sante_pro/widgets/chatbot/warning_banner.dart';

// ==================== CONFIGURATION ====================
class ChatConfig {
  static const int maxMessageLength = 2000;
  static const int messageHistoryLimit = 1000;
  static const double maxBubbleWidth = 0.75;
  static const Duration typingDelay = Duration(milliseconds: 1500);
  static const Duration messageAnimationDuration = Duration(milliseconds: 400);
  static const double scrollThreshold = 0.7;
}

// ==================== COULEURS THÈME ====================
class _ChatTheme {
  static const Color primary = Color(0xFF6C63FF);
  static const Color primaryDark = Color(0xFF8B83FF);
  static const Color accent = Color(0xFF4ECDC4);
  static const Color success = Color(0xFF10B981);
  static const Color danger = Color(0xFFEF4444);

  static const Color bgLight = Color(0xFFF0F4FF);
  static const Color bgLight2 = Color(0xFFE8EDF5);
  static const Color bgDark = Color(0xFF12121E);
  static const Color bgDark2 = Color(0xFF1A1A2E);
  static const Color surfaceDark = Color(0xFF2A2A3E);

  static const Color textLight = Color(0xFF1A1A2E);
  static const Color textMutedLight = Color(0xFF6B7280);
  static const Color textMutedDark = Color(0xFF9CA3AF);

  static Color primaryOf(bool dark) => dark ? primaryDark : primary;
}

// ==================== WIDGET PRINCIPAL ====================
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  // Contrôleurs
  late final ScrollController _scrollController;
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  // États
  bool _isAppBarVisible = true;
  double _lastScrollOffset = 0;
  bool _isUserScrolling = false;
  Timer? _scrollTimer;

  // Voice & Speech
  final FlutterTts _flutterTts = FlutterTts();
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  bool _isListening = false;
  bool _isSpeaking = false;
  bool _speechAvailable = false;
  String? _speechError;

  // Logs
  final List<String> _messageLogs = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // 1) Contrôleurs d'abord (obligatoire avant tout setState/scroll)
    _initializeControllers();

    // 2) Services voix (async, ne bloquent pas le build)
    _initializeSpeechToText();
    _initializeTextToSpeech();

    // 3) Message de bienvenue après le premier frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<ChatProvider>();
      if (provider.messages.isEmpty) {
        provider.addWelcomeMessage();
      }
    });
  }

  void _initializeControllers() {
    _scrollController = ScrollController()..addListener(_onScroll);

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..forward();

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _initializeSpeechToText() async {
    try {
      final available = await _speechToText.initialize(
        onStatus: (status) {
          if (!mounted) return;
          setState(() {
            _isListening = status == 'listening';
            if (status == 'done' || status == 'notListening') {
              _isListening = false;
            }
          });
        },
        onError: (error) {
          if (!mounted) return;
          setState(() {
            _speechError = error.errorMsg;
            _isListening = false;
          });
          _log('Speech error: ${error.errorMsg}', level: 'error');
        },
      );

      if (!mounted) return;
      setState(() {
        _speechAvailable = available;
        if (!available) {
          _speechError = 'La reconnaissance vocale n\'est pas disponible';
        }
      });
    } catch (e) {
      _log('Speech initialization failed: $e', level: 'error');
      if (!mounted) return;
      setState(() {
        _speechAvailable = false;
        _speechError = 'Erreur d\'initialisation de la voix';
      });
    }
  }

  Future<void> _initializeTextToSpeech() async {
    try {
      await _flutterTts.setLanguage('fr-FR');
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setPitch(1.0);
      await _flutterTts.setVolume(1.0);

      _flutterTts.setStartHandler(() {
        if (mounted) setState(() => _isSpeaking = true);
      });
      _flutterTts.setCompletionHandler(() {
        if (mounted) setState(() => _isSpeaking = false);
      });
      _flutterTts.setCancelHandler(() {
        if (mounted) setState(() => _isSpeaking = false);
      });
      _flutterTts.setErrorHandler((msg) {
        if (mounted) setState(() => _isSpeaking = false);
        _log('TTS error: $msg', level: 'error');
      });
    } catch (e) {
      _log('TTS initialization failed: $e', level: 'error');
    }
  }

  // ==================== LOGGING ====================
  void _log(String message, {String level = 'info', dynamic data}) {
    final timestamp = DateTime.now().toIso8601String();
    final logMessage = '[ChatScreen] $message';

    final emoji = switch (level) {
      'error' => '❌',
      'warning' => '⚠️',
      'debug' => '🔍',
      'success' => '✅',
      _ => 'ℹ️',
    };

    developer.log('$emoji $logMessage', name: 'ChatScreen', error: data);

    _messageLogs.add('[$timestamp] $logMessage');
    if (_messageLogs.length > ChatConfig.messageHistoryLimit) {
      _messageLogs.removeAt(0);
    }
  }

  // ==================== SCROLL ====================
  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final currentOffset = _scrollController.offset;

    if (currentOffset > _lastScrollOffset + 20 && _isAppBarVisible) {
      setState(() => _isAppBarVisible = false);
    } else if (currentOffset < _lastScrollOffset - 20 && !_isAppBarVisible) {
      setState(() => _isAppBarVisible = true);
    }
    _lastScrollOffset = currentOffset;

    if (!_isUserScrolling) {
      setState(() => _isUserScrolling = true);
    }
    _scrollTimer?.cancel();
    _scrollTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _isUserScrolling = false);
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
      );
    });
  }

  // ==================== VOICE TO TEXT ====================
  Future<void> _startListening() async {
    if (_isListening) {
      await _speechToText.stop();
      if (mounted) setState(() => _isListening = false);
      return;
    }

    if (!_speechAvailable) {
      setState(() => _speechError =
          'La reconnaissance vocale n\'est pas disponible');
      return;
    }

    setState(() => _speechError = null);

    try {
      await _speechToText.listen(
        onResult: (result) {
          if (!result.finalResult) return;
          final text = result.recognizedWords.trim();
          if (text.isEmpty) return;
          if (!mounted) return;

          context.read<ChatProvider>().sendMessage(text);
          _scrollToBottom();
          setState(() => _isListening = false);
        },
        listenMode: stt.ListenMode.dictation,
        localeId: 'fr_FR',
        cancelOnError: true,
        partialResults: false,
      );

      if (mounted) setState(() => _isListening = true);
    } catch (e) {
      _log('Listen error: $e', level: 'error');
      if (mounted) {
        setState(() {
          _speechError = 'Erreur lors de l\'écoute';
          _isListening = false;
        });
      }
    }
  }

  // ==================== TEXT TO SPEECH ====================
  Future<void> _speakText(String text) async {
    if (text.trim().isEmpty) return;

    if (_isSpeaking) {
      await _flutterTts.stop();
      if (mounted) setState(() => _isSpeaking = false);
      return;
    }

    try {
      await _flutterTts.speak(text);
      if (mounted) setState(() => _isSpeaking = true);
    } catch (e) {
      _log('Speak error: $e', level: 'error');
    }
  }

  // ==================== SHARE ====================
  Future<void> _shareConversation() async {
    try {
      final provider = context.read<ChatProvider>();
      if (provider.messages.isEmpty) {
        if (!mounted) return;
        _showSnack('Aucune conversation à partager');
        return;
      }

      final buffer = StringBuffer();
      buffer.writeln('=== Conversation Assistant Santé ===\n');
      buffer.writeln(
          'Date: ${DateTime.now().toLocal().toString().split(' ')[0]}');
      buffer.writeln('Messages: ${provider.messages.length}\n');
      buffer.writeln('--- Messages ---\n');

      for (final message in provider.messages) {
        final sender =
            message.type == MessageType.user ? '👤 Moi' : '🤖 Assistant';
        final ts = message.timestamp;
        final hh = ts.hour.toString().padLeft(2, '0');
        final mm = ts.minute.toString().padLeft(2, '0');
        buffer.writeln('$sender: ${message.content}');
        buffer.writeln('$hh:$mm\n');
      }

      buffer.writeln('--- Fin de la conversation ---');
      buffer.writeln('Partagé depuis l\'application Suivi Santé');

      await Share.share(
        buffer.toString(),
        subject: 'Conversation avec l\'Assistant Santé',
      );

      _log('Conversation shared successfully', level: 'success');
    } catch (e) {
      _log('Share error: $e', level: 'error');
      if (!mounted) return;
      _showSnack('Erreur lors du partage: $e', isError: true);
    }
  }

  // ==================== COPY ====================
  void _copyMessage(String content) {
    Clipboard.setData(ClipboardData(text: content));
    if (!mounted) return;
    _showSnack('📋 Message copié dans le presse-papiers', isSuccess: true);
  }

  // ==================== HELPERS SNACK ====================
  void _showSnack(
    String message, {
    bool isError = false,
    bool isSuccess = false,
  }) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? _ChatTheme.danger
            : isSuccess
                ? _ChatTheme.success
                : null,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ==================== DISPOSE ====================
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _fadeController.dispose();
    _scrollTimer?.cancel();
    _flutterTts.stop();
    _speechToText.stop();
    super.dispose();
  }

  // ==================== BUILD ====================
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor:
            isDark ? _ChatTheme.bgDark : Colors.white,
        systemNavigationBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: isDark ? _ChatTheme.bgDark : _ChatTheme.bgLight,
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SafeArea(
            child: Stack(
              children: [
                Positioned.fill(child: _buildBackground(isDark)),
                if (!isDark) ..._buildDecorations(),
                Column(
                  children: [
                    _buildGlassAppBar(isDark),
                    const WarningBanner(),
                    Flexible(
                      child: Consumer<ChatProvider>(
                        builder: (context, provider, _) {
                          return FadeTransition(
                            opacity: _fadeAnimation,
                            child: _buildMessageList(provider, isDark),
                          );
                        },
                      ),
                    ),
                    _buildTypingIndicator(),
                    _buildMessageInput(isDark),
                  ],
                ),
                Positioned(
                  bottom: 100,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Consumer<ChatProvider>(
                      builder: (context, provider, _) {
                        if (!_scrollController.hasClients) {
                          return const SizedBox.shrink();
                        }
                        final pos = _scrollController.position;
                        final shouldShow = provider.messages.isNotEmpty &&
                            pos.pixels <
                                pos.maxScrollExtent *
                                    ChatConfig.scrollThreshold &&
                            !_isUserScrolling;
                        return AnimatedOpacity(
                          opacity: shouldShow ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 400),
                          child: IgnorePointer(
                            ignoring: !shouldShow,
                            child: _buildScrollDownButton(isDark),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==================== FOND ====================
  Widget _buildBackground(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [_ChatTheme.bgDark2, _ChatTheme.bgDark]
              : [
                  Colors.white,
                  _ChatTheme.bgLight,
                  _ChatTheme.bgLight2,
                ],
        ),
      ),
    );
  }

  List<Widget> _buildDecorations() {
    return [
      Positioned(
        top: -100,
        right: -100,
        child: Container(
          width: 300,
          height: 300,
          decoration: BoxDecoration(
            gradient: RadialGradient(colors: [
              _ChatTheme.primary.withOpacity(0.05),
              Colors.transparent,
            ]),
            shape: BoxShape.circle,
          ),
        ),
      ),
      Positioned(
        bottom: -50,
        left: -50,
        child: Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            gradient: RadialGradient(colors: [
              _ChatTheme.accent.withOpacity(0.05),
              Colors.transparent,
            ]),
            shape: BoxShape.circle,
          ),
        ),
      ),
    ];
  }

  // ==================== APP BAR ====================
  Widget _buildGlassAppBar(bool isDark) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: _isAppBarVisible ? 90 : 0,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? _ChatTheme.bgDark2.withOpacity(0.85)
            : Colors.white.withOpacity(0.85),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.06),
            blurRadius: 30,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.black.withOpacity(0.05),
            width: 1,
          ),
        ),
      ),
      child: ClipRect(
        child: Row(
          children: [
            _buildGlassButton(
              icon: Icons.arrow_back_ios_new_rounded,
              onTap: () => Navigator.pop(context),
              isDark: isDark,
            ),
            const SizedBox(width: 8),
            _buildAnimatedAvatar(isDark),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Assistant Santé',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: isDark
                          ? Colors.white
                          : _ChatTheme.textLight,
                      letterSpacing: -0.3,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 1),
                  Row(
                    children: [
                      const Icon(Icons.circle,
                          size: 6, color: _ChatTheme.success),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Consumer<ChatProvider>(
                          builder: (context, provider, _) {
                            final status = provider.isLoading
                                ? 'En train d\'écrire...'
                                : 'En ligne';
                            return Text(
                              status,
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark
                                    ? _ChatTheme.textMutedDark
                                    : _ChatTheme.textMutedLight,
                                fontWeight: FontWeight.w400,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildGlassActionButton(
                  icon: Icons.history_rounded,
                  onTap: _showHistoryDialog,
                  isDark: isDark,
                ),
                _buildGlassActionButton(
                  icon: Icons.share_rounded,
                  onTap: _shareConversation,
                  isDark: isDark,
                ),
                _buildGlassActionButton(
                  icon: Icons.more_vert_rounded,
                  onTap: _showOptionsMenu,
                  isDark: isDark,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassActionButton({
    required IconData icon,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(
            icon,
            size: 20,
            color: isDark ? _ChatTheme.textMutedDark : _ChatTheme.textMutedLight,
          ),
        ),
      ),
    );
  }

  Widget _buildGlassButton({
    required IconData icon,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    final color = _ChatTheme.primaryOf(isDark);
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              color.withOpacity(0.15),
              color.withOpacity(0.05),
            ]),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.15), width: 1),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }

  Widget _buildAnimatedAvatar(bool isDark) {
    final color = _ChatTheme.primaryOf(isDark);
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Icon(Icons.health_and_safety,
              color: Colors.white, size: 20),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                color: _ChatTheme.success,
                shape: BoxShape.circle,
                border: Border.fromBorderSide(
                  BorderSide(color: Colors.white, width: 2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== MESSAGE INPUT ====================
  Widget _buildMessageInput(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? _ChatTheme.bgDark2.withOpacity(0.9)
            : Colors.white.withOpacity(0.9),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_speechError != null)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.red.shade50,
              child: Row(
                children: [
                  Icon(Icons.error_outline,
                      color: Colors.red.shade700, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _speechError!,
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _speechError = null),
                    child: Icon(Icons.close,
                        color: Colors.red.shade700, size: 16),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              IconButton(
                onPressed: _speechAvailable ? _startListening : null,
                icon: Icon(
                  _isListening ? Icons.mic_off : Icons.mic,
                  color: _isListening
                      ? Colors.red
                      : (_speechAvailable
                          ? (isDark ? Colors.white : null)
                          : Colors.grey),
                ),
                tooltip: _isListening
                    ? 'Arrêter l\'écoute'
                    : 'Démarrer l\'écoute',
              ),
              Expanded(
                child: Consumer<ChatProvider>(
                  builder: (context, provider, _) {
                    return MessageInput(
                      key: const ValueKey('message_input'),
                      onSendMessage: (text) async {
                        if (text.trim().isEmpty) return;
                        await provider.sendMessage(text);
                        _scrollToBottom();
                      },
                      isProcessing: provider.isLoading,
                    );
                  },
                ),
              ),
              IconButton(
                onPressed: () {
                  if (!mounted) return;
                  final provider = context.read<ChatProvider>();
                  final botMessages = provider.messages
                      .where((m) => m.type == MessageType.bot)
                      .toList();
                  if (botMessages.isNotEmpty) {
                    _speakText(botMessages.last.content);
                  } else {
                    _showSnack('Aucun message de l\'assistant à lire');
                  }
                },
                icon: Icon(
                  _isSpeaking ? Icons.volume_off : Icons.volume_up,
                  color: _isSpeaking
                      ? Colors.green
                      : (isDark ? Colors.white : null),
                ),
                tooltip: _isSpeaking
                    ? 'Arrêter la lecture'
                    : 'Lire le dernier message',
              ),
              const SizedBox(width: 4),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== TYPING INDICATOR ====================
  Widget _buildTypingIndicator() {
    return Consumer<ChatProvider>(
      builder: (context, provider, _) {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          transitionBuilder: (child, animation) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.5),
                end: Offset.zero,
              ).animate(animation),
              child: FadeTransition(opacity: animation, child: child),
            );
          },
          child: provider.isLoading
              ? const TypingIndicator()
              : const SizedBox.shrink(),
        );
      },
    );
  }

  // ==================== LISTE DES MESSAGES ====================
  Widget _buildMessageList(ChatProvider provider, bool isDark) {
    if (provider.messages.isEmpty) {
      return _buildEmptyState(isDark);
    }

    return Column(
      children: [
        if (provider.error != null && provider.error!.isNotEmpty)
          _buildErrorBanner(provider.error!, isDark),
        Flexible(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(vertical: 12),
            itemCount: provider.messages.length,
            itemBuilder: (context, index) {
              final message = provider.messages[index];
              final isPreviousSameUser = index > 0 &&
                  provider.messages[index - 1].type == message.type;

              return _AnimatedMessageItem(
                key: ValueKey('msg_${message.id ?? index}'),
                index: index,
                message: message,
                isPreviousSameUser: isPreviousSameUser,
                onCopy: () => _copyMessage(message.content),
                onSpeak: () => _speakText(message.content),
                isDark: isDark,
              );
            },
          ),
        ),
        _buildQuickActions(provider, isDark),
      ],
    );
  }

  Widget _buildErrorBanner(String error, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.red.shade900.withOpacity(0.3)
            : Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.red.shade700 : Colors.red.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: isDark ? Colors.red.shade300 : Colors.red.shade700,
            size: 20,
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              error,
              style: TextStyle(
                color:
                    isDark ? Colors.red.shade300 : Colors.red.shade700,
                fontSize: 13,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== ACTIONS RAPIDES ====================
  Widget _buildQuickActions(ChatProvider provider, bool isDark) {
    if (provider.messages.isEmpty) return const SizedBox.shrink();

    final lastMessage = provider.messages.last;
    final quickActions = lastMessage.quickActions;
    if (quickActions == null || quickActions.isEmpty) {
      return const SizedBox.shrink();
    }

    final color = _ChatTheme.primaryOf(isDark);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        alignment: WrapAlignment.start,
        children: quickActions.map((action) {
          return ActionChip(
            label: Text(
              action.label ?? '',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white : null,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            avatar: Icon(
              action.icon ?? Icons.chat_bubble_outline,
              size: 16,
              color: color,
            ),
            onPressed: () {
              final tap = action.onTap;
              if (tap != null) {
                tap();
              } else {
                provider.sendMessage(action.label ?? '');
              }
            },
            backgroundColor: color.withOpacity(0.1),
            side: BorderSide.none,
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          );
        }).toList(),
      ),
    );
  }

  // ==================== ÉTAT VIDE ====================
  Widget _buildEmptyState(bool isDark) {
    final color = _ChatTheme.primaryOf(isDark);
    final textColor = isDark ? Colors.white : _ChatTheme.textLight;
    final subTextColor =
        isDark ? _ChatTheme.textMutedDark : _ChatTheme.textMutedLight;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withOpacity(0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 40,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: const Icon(Icons.health_and_safety,
                color: Colors.white, size: 56),
          ),
          const SizedBox(height: 32),
          Text(
            'Comment puis-je vous aider ?',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Décrivez vos symptômes ou posez une question',
            style: TextStyle(fontSize: 14, color: subTextColor),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              _buildSuggestionChip('🩺 J\'ai mal à la tête', isDark),
              _buildSuggestionChip('🤒 J\'ai de la fièvre', isDark),
              _buildSuggestionChip('💊 Mes médicaments', isDark),
              _buildSuggestionChip('📅 Prendre rendez-vous', isDark),
              _buildSuggestionChip('😰 Je suis fatigué', isDark),
              _buildSuggestionChip('🌙 Problèmes de sommeil', isDark),
            ],
          ),
          const SizedBox(height: 32),
          Consumer<ChatProvider>(
            builder: (context, provider, _) {
              return TextButton.icon(
                onPressed: () async {
                  final isHealthy = await provider.checkHealth();
                  if (!mounted) return;
                  _showSnack(
                    isHealthy
                        ? '✅ Serveur connecté !'
                        : '❌ Serveur indisponible — vérifiez le backend.',
                    isError: !isHealthy,
                    isSuccess: isHealthy,
                  );
                },
                icon: Icon(Icons.wifi, color: color),
                label: Text(
                  'Vérifier la connexion',
                  style: TextStyle(color: color),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: color.withOpacity(0.3)),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Consumer<ChatProvider>(
            builder: (context, provider, _) {
              final hasError =
                  provider.error != null && provider.error!.isNotEmpty;
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: hasError ? Colors.red : Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    hasError ? 'Serveur déconnecté' : 'Serveur connecté',
                    style: TextStyle(
                      fontSize: 12,
                      color: hasError ? Colors.red : Colors.green,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: _showLogsDialog,
            icon: Icon(Icons.terminal, size: 20, color: subTextColor),
            label: Text(
              'Afficher les logs',
              style: TextStyle(color: subTextColor, fontSize: 12),
            ),
            style: TextButton.styleFrom(foregroundColor: subTextColor),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionChip(String label, bool isDark) {
    final color = _ChatTheme.primaryOf(isDark);
    return ActionChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: color,
        ),
        overflow: TextOverflow.ellipsis,
      ),
      onPressed: () {
        if (!mounted) return;
        final text = label
            .replaceAll(RegExp(r'[🩺💊📅😰🌙🤒💪]'), '')
            .trim();
        context.read<ChatProvider>().sendMessage(text);
        _scrollToBottom();
      },
      backgroundColor: color.withOpacity(0.08),
      side: BorderSide.none,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
    );
  }

  // ==================== BOUTON SCROLL ====================
  Widget _buildScrollDownButton(bool isDark) {
    final color = _ChatTheme.primaryOf(isDark);
    return Material(
      elevation: 8,
      shadowColor: color.withOpacity(0.2),
      borderRadius: BorderRadius.circular(25),
      child: InkWell(
        onTap: _scrollToBottom,
        borderRadius: BorderRadius.circular(25),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? _ChatTheme.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withOpacity(0.3)
                    : Colors.black.withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.keyboard_arrow_down_rounded,
                  color: color, size: 22),
              const SizedBox(width: 6),
              Text(
                'Nouveaux messages',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              const SizedBox(width: 6),
              CircleAvatar(
                radius: 10,
                backgroundColor: color,
                child: const Text('✨', style: TextStyle(fontSize: 10)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== DIALOGUES ====================
  void _showHistoryDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? _ChatTheme.bgDark2 : Colors.white,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        height: MediaQuery.of(ctx).size.height * 0.6,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.grey.shade700
                      : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Icon(Icons.history_rounded,
                    color: _ChatTheme.primaryOf(isDark)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Historique des conversations',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : null,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Consumer<ChatProvider>(
                builder: (context, provider, _) {
                  if (provider.messages.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat_bubble_outline_rounded,
                              size: 48,
                              color: isDark
                                  ? Colors.grey.shade600
                                  : Colors.grey.shade400),
                          const SizedBox(height: 12),
                          Text(
                            'Aucune conversation',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.separated(
                    itemCount: provider.messages.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      color: isDark
                          ? Colors.grey.shade800
                          : Colors.grey.shade200,
                    ),
                    itemBuilder: (context, index) {
                      final message = provider.messages[index];
                      final isUser = message.type == MessageType.user;
                      final ts = message.timestamp;
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isUser
                              ? _ChatTheme.accent.withOpacity(0.15)
                              : _ChatTheme.primaryOf(isDark)
                                  .withOpacity(0.15),
                          child: Icon(
                            isUser
                                ? Icons.person
                                : Icons.health_and_safety,
                            color: isUser
                                ? _ChatTheme.accent
                                : _ChatTheme.primaryOf(isDark),
                            size: 20,
                          ),
                        ),
                        title: Text(
                          message.content.length > 60
                              ? '${message.content.substring(0, 60)}...'
                              : message.content,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.white : null,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Text(
                          '${ts.hour.toString().padLeft(2, '0')}:${ts.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? Colors.grey.shade600
                                : Colors.grey.shade400,
                          ),
                        ),
                        onTap: () => Navigator.pop(ctx),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showOptionsMenu() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? _ChatTheme.bgDark2 : Colors.white,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.grey.shade700
                      : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildOptionTile(
              isDark: isDark,
              icon: Icons.delete_forever_rounded,
              title: 'Effacer la conversation',
              subtitle: 'Supprimer tous les messages',
              color: Colors.red,
              onTap: () {
                Navigator.pop(ctx);
                _showClearConfirmation();
              },
            ),
            const Divider(height: 4),
            _buildOptionTile(
              isDark: isDark,
              icon: Icons.share_rounded,
              title: 'Partager',
              subtitle: 'Partager la conversation avec un proche',
              color: _ChatTheme.accent,
              onTap: () {
                Navigator.pop(ctx);
                _shareConversation();
              },
            ),
            const Divider(height: 4),
            _buildOptionTile(
              isDark: isDark,
              icon: Icons.help_outline_rounded,
              title: 'Aide et conseils',
              subtitle: 'Comment utiliser l\'assistant',
              color: Colors.orange,
              onTap: () {
                Navigator.pop(ctx);
                _showHelpDialog();
              },
            ),
            const Divider(height: 4),
            _buildOptionTile(
              isDark: isDark,
              icon: Icons.terminal,
              title: 'Voir les logs',
              subtitle: 'Afficher les logs de debug',
              color: Colors.purple,
              onTap: () {
                Navigator.pop(ctx);
                _showLogsDialog();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required bool isDark,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 15,
          color: isDark ? Colors.white : null,
        ),
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: isDark
              ? _ChatTheme.textMutedDark
              : _ChatTheme.textMutedLight,
        ),
        overflow: TextOverflow.ellipsis,
      ),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      trailing: Icon(
        Icons.arrow_forward_ios_rounded,
        size: 16,
        color: isDark ? Colors.grey.shade600 : _ChatTheme.textMutedDark,
      ),
    );
  }

  void _showHelpDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: isDark ? _ChatTheme.bgDark2 : Colors.white,
        title: Row(
          children: [
            Icon(Icons.help_outline_rounded,
                color: _ChatTheme.primaryOf(isDark)),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                'Comment utiliser l\'assistant',
                style: TextStyle(
                  color: isDark ? Colors.white : null,
                  fontSize: 16,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHelpItem('💬', 'Parlez ou tapez vos symptômes', isDark),
            _buildHelpItem('🎤', 'Utilisez le micro pour dicter', isDark),
            _buildHelpItem('🔊', 'Écoutez les réponses de l\'assistant', isDark),
            _buildHelpItem('🩺', 'Analyse des symptômes en temps réel', isDark),
            _buildHelpItem('💊', 'Gestion des médicaments et rappels', isDark),
            _buildHelpItem('📅', 'Organisation des rendez-vous', isDark),
            _buildHelpItem('📤', 'Partage de conversations', isDark),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(
              foregroundColor: isDark ? Colors.grey.shade400 : null,
            ),
            child: const Text('Compris'),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpItem(String icon, String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? Colors.grey.shade300
                    : _ChatTheme.textMutedLight,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _showClearConfirmation() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: isDark ? _ChatTheme.bgDark2 : Colors.white,
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.orange),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                'Effacer la conversation',
                style: TextStyle(
                  color: isDark ? Colors.white : null,
                  fontSize: 16,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer tous les messages ?',
          style: TextStyle(
            color:
                isDark ? Colors.grey.shade300 : _ChatTheme.textMutedLight,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(
              foregroundColor: isDark ? Colors.grey.shade400 : null,
            ),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<ChatProvider>().clearMessages();
              _messageLogs.clear();
              _showSnack('🗑️ Conversation effacée', isSuccess: true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Effacer'),
          ),
        ],
      ),
    );
  }

  void _showLogsDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: isDark ? _ChatTheme.bgDark2 : Colors.white,
        title: Row(
          children: [
            Icon(Icons.terminal, color: _ChatTheme.primaryOf(isDark)),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                'Logs de la session',
                style: TextStyle(
                  color: isDark ? Colors.white : null,
                  fontSize: 16,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: _messageLogs.isEmpty
              ? Center(
                  child: Text(
                    'Aucun log disponible',
                    style: TextStyle(
                      color: isDark ? Colors.grey.shade500 : null,
                    ),
                  ),
                )
              : ListView.separated(
                  itemCount: _messageLogs.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    color: isDark
                        ? Colors.grey.shade800
                        : Colors.grey.shade200,
                  ),
                  itemBuilder: (context, index) {
                    final log = _messageLogs[index];
                    final color = log.contains('✅') || log.contains('ℹ️')
                        ? (isDark
                            ? Colors.green.shade300
                            : Colors.green.shade700)
                        : log.contains('❌') || log.contains('⚠️')
                            ? (isDark
                                ? Colors.red.shade300
                                : Colors.red.shade700)
                            : (isDark
                                ? Colors.grey.shade300
                                : Colors.black87);
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        log,
                        style: TextStyle(
                          fontSize: 11,
                          fontFamily: 'monospace',
                          color: color,
                        ),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _messageLogs.clear();
              setState(() {});
            },
            style: TextButton.styleFrom(
              foregroundColor: isDark ? Colors.grey.shade400 : null,
            ),
            child: const Text('Effacer les logs'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: _ChatTheme.primaryOf(isDark),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
}

// ==================== WIDGET DE MESSAGE ANIMÉ ====================
class _AnimatedMessageItem extends StatefulWidget {
  final int index;
  final Message message;
  final bool isPreviousSameUser;
  final VoidCallback onCopy;
  final VoidCallback onSpeak;
  final bool isDark;

  const _AnimatedMessageItem({
    super.key,
    required this.index,
    required this.message,
    required this.isPreviousSameUser,
    required this.onCopy,
    required this.onSpeak,
    required this.isDark,
  });

  @override
  State<_AnimatedMessageItem> createState() => _AnimatedMessageItemState();
}

class _AnimatedMessageItemState extends State<_AnimatedMessageItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacityAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    final delay = Duration(milliseconds: widget.index * 40);
    final isBot = widget.message.type == MessageType.bot;

    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, isBot ? 0.15 : 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    Future.delayed(delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isBot = widget.message.type == MessageType.bot;

    // ✅ CORRECTION : on appelle ChatBubble avec le bon paramètre.
    // ⚠️ Adapter le nom ('isPreviousSameUser') au constructeur réel de ChatBubble.
    return FadeTransition(
      opacity: _opacityAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Stack(
          children: [
            ChatBubble(
  message: widget.message,
),
            Positioned(
              right: isBot ? 8 : null,
              left: isBot ? null : 8,
              top: 8,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _actionBtn(
                    icon: Icons.copy_rounded,
                    onTap: widget.onCopy,
                  ),
                  if (isBot) ...[
                    const SizedBox(width: 4),
                    _actionBtn(
                      icon: Icons.volume_up_rounded,
                      onTap: widget.onSpeak,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionBtn({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: widget.isDark
                ? Colors.grey.shade800.withOpacity(0.7)
                : Colors.grey.shade200.withOpacity(0.7),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            size: 14,
            color: widget.isDark
                ? Colors.grey.shade400
                : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }
}