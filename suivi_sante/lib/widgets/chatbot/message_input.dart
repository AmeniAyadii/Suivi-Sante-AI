// lib/widgets/chatbot/message_input.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:avatar_glow/avatar_glow.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:suivi_sante_pro/utils/chatbot/colors.dart';

class MessageInput extends StatefulWidget {
  final Function(String) onSendMessage;
  final bool isProcessing;

  const MessageInput({
    super.key,
    required this.onSendMessage,
    this.isProcessing = false,
  });

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final stt.SpeechToText _speech = stt.SpeechToText();

  bool _isListening = false;
  bool _isInitialized = false;
  bool _isPermissionGranted = false;
  bool _isProcessingVoice = false;
  String? _speechError;
  Timer? _listeningTimer;
  int _retryCount = 0;

  @override
  void initState() {
    super.initState();
    _checkMicrophonePermission();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _listeningTimer?.cancel();
    _speech.stop();
    super.dispose();
  }

  // ✅ Vérifier la permission microphone
  Future<void> _checkMicrophonePermission() async {
    try {
      final status = await Permission.microphone.status;
      print('📱 Statut microphone: $status');

      if (status.isGranted) {
        setState(() => _isPermissionGranted = true);
        await _initSpeech();
      } else if (status.isDenied) {
        final result = await Permission.microphone.request();
        print('📱 Résultat demande permission: $result');

        if (result.isGranted) {
          setState(() => _isPermissionGranted = true);
          await _initSpeech();
        } else {
          setState(() {
            _isPermissionGranted = false;
            _speechError = 'Permission microphone refusée';
          });
        }
      } else if (status.isPermanentlyDenied) {
        setState(() {
          _isPermissionGranted = false;
          _speechError = 'Permission microphone définitivement refusée';
        });
        _showOpenSettingsDialog();
      }
    } catch (e) {
      print('❌ Erreur vérification permission: $e');
      setState(() {
        _isPermissionGranted = false;
        _speechError = 'Erreur de permission';
      });
    }
  }

  void _showOpenSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission microphone'),
        content: const Text(
          'La permission microphone a été définitivement refusée. '
          'Veuillez l\'activer dans les paramètres de l\'application.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await openAppSettings();
            },
            child: const Text('Ouvrir paramètres'),
          ),
        ],
      ),
    );
  }

  // ✅ Initialiser la reconnaissance vocale
  Future<void> _initSpeech() async {
    try {
      print('🎤 Initialisation de la reconnaissance vocale...');

      final available = await _speech.initialize(
        onError: (error) {
          print('❌ Erreur speech: ${error.errorMsg}');
          if (mounted) {
            setState(() {
              _speechError = error.errorMsg;
              _isListening = false;
              _isProcessingVoice = false;
            });
          }
        },
        onStatus: (status) {
          print('🎤 Statut speech: $status');
          if (mounted) {
            if (status == 'notListening' && _isListening) {
              setState(() => _isListening = false);
            }
            if (status == 'done') {
              setState(() {
                _isListening = false;
                _isProcessingVoice = false;
              });
            }
          }
        },
      );

      if (mounted) {
        setState(() {
          _isInitialized = available;
          if (!available) {
            _speechError = 'La reconnaissance vocale n\'est pas disponible';
          }
        });
      }

      print('🎤 Speech initialisé: $available');
    } catch (e) {
      print('❌ Erreur d\'initialisation: $e');
      if (mounted) {
        setState(() {
          _isInitialized = false;
          _speechError = 'Erreur d\'initialisation';
        });
      }
    }
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isNotEmpty && !widget.isProcessing) {
      widget.onSendMessage(text);
      _controller.clear();
      _focusNode.unfocus();
    }
  }

  Future<void> _stopListening() async {
    _listeningTimer?.cancel();
    if (mounted) {
      setState(() {
        _isListening = false;
        _isProcessingVoice = false;
      });
    }
    try {
      await _speech.stop();
    } catch (e) {
      print('❌ Erreur arrêt: $e');
    }
    print('⏹️ Écoute arrêtée');
  }

  void _startTimeoutTimer() {
    _listeningTimer?.cancel();
    _listeningTimer = Timer(const Duration(seconds: 20), () async {
      if (_isListening) {
        print('⏰ Timeout, arrêt automatique');
        await _stopListening();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⏰ Temps d\'écoute dépassé'),
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 1),
            ),
          );
        }
      }
    });
  }

  // ✅ Méthode principale de reconnaissance vocale optimisée
  Future<void> _startListening() async {
    try {
      print('🎤 Démarrage de l\'écoute...');

      if (_isProcessingVoice) {
        print('⏳ Déjà en cours de traitement...');
        return;
      }

      if (!_isPermissionGranted) {
        await _checkMicrophonePermission();
        if (!_isPermissionGranted) {
          _showSnackBar('⚠️ Permission microphone refusée');
          return;
        }
      }

      if (!_isInitialized) {
        await _initSpeech();
        if (!_isInitialized) {
          _showSnackBar('⚠️ La reconnaissance vocale n\'est pas disponible');
          return;
        }
      }

      // ✅ Arrêter toute écoute en cours
      if (_speech.isListening) {
        await _speech.stop();
        await Future.delayed(const Duration(milliseconds: 200));
      }

      if (mounted) {
        setState(() {
          _isProcessingVoice = true;
          _speechError = null;
        });
      }

      // ✅ Démarrer l'écoute - D'abord essayer le mode cloud
      bool result = await _speech.listen(
        onResult: (result) {
          final recognizedText = result.recognizedWords;
          print(
            '🎤 Résultat: "$recognizedText" (final: ${result.finalResult})',
          );

          if (recognizedText.isNotEmpty && mounted) {
            setState(() {
              _controller.text = recognizedText;
            });
          }

          if (result.finalResult && recognizedText.isNotEmpty) {
            _listeningTimer?.cancel();
            if (mounted) {
              setState(() {
                _isListening = false;
                _isProcessingVoice = false;
              });
            }
            Future.delayed(const Duration(milliseconds: 300), () {
              if (_controller.text.isNotEmpty && mounted) {
                _sendMessage();
              }
            });
            final isSuccess = result == true;
          }
        },
        listenOptions: stt.SpeechListenOptions(
          listenMode: stt.ListenMode.dictation,
          cancelOnError: false,
          partialResults: true,
          onDevice: false, // ✅ Mode cloud d'abord
          sampleRate: 16000,
          autoPunctuation: true,
          //timeOut: const Duration(seconds: 20),
        ),
        localeId: 'fr_FR',
      );

      // ✅ Si le mode cloud échoue, essayer le mode local
      if (!result) {
        print('❌ Échec mode cloud, tentative mode local...');
        await _speech.stop();
        await Future.delayed(const Duration(milliseconds: 200));

        result = await _speech.listen(
          onResult: (result) {
            final recognizedText = result.recognizedWords;
            print(
              '🎤 Résultat (local): "$recognizedText" (final: ${result.finalResult})',
            );

            if (recognizedText.isNotEmpty && mounted) {
              setState(() {
                _controller.text = recognizedText;
              });
            }

            if (result.finalResult && recognizedText.isNotEmpty) {
              _listeningTimer?.cancel();
              if (mounted) {
                setState(() {
                  _isListening = false;
                  _isProcessingVoice = false;
                });
              }
              Future.delayed(const Duration(milliseconds: 300), () {
                if (_controller.text.isNotEmpty && mounted) {
                  _sendMessage();
                }
              });
            }
          },
          listenOptions: stt.SpeechListenOptions(
            listenMode: stt.ListenMode.dictation,
            cancelOnError: false,
            partialResults: true,
            onDevice: true, // ✅ Mode local
            sampleRate: 16000,
            //timeOut: const Duration(seconds: 20),
          ),
          localeId: 'fr_FR',
        );
      }

      if (mounted) {
        if (result == true) {
          print('✅ Écoute démarrée avec succès');
          setState(() {
            _isListening = true;
            _isProcessingVoice = false;
          });
          _startTimeoutTimer();
        } else {
          print('❌ Échec démarrage écoute');
          setState(() {
            _isListening = false;
            _isProcessingVoice = false;
            _speechError = 'Impossible de démarrer l\'écoute';
          });
          _showSnackBar('⚠️ Impossible de démarrer l\'écoute');
        }
      }
    } catch (e) {
      print('❌ Erreur écoute: $e');
      if (mounted) {
        setState(() {
          _isListening = false;
          _isProcessingVoice = false;
          _speechError = 'Erreur: ${e.toString().substring(0, 30)}...';
        });
      }
      _listeningTimer?.cancel();
      _showSnackBar('❌ Erreur de reconnaissance vocale');
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _toggleListening() async {
    print('🎤 Toggle listening...');

    if (_isListening) {
      await _stopListening();
      return;
    }

    if (_isProcessingVoice) {
      print('⏳ Traitement en cours...');
      return;
    }

    setState(() {
      _speechError = null;
    });

    await _startListening();
  }

  @override
  Widget build(BuildContext context) {
    final bool canUseMic = _isPermissionGranted && _isInitialized;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // ✅ Bouton Microphone
          AvatarGlow(
            animate: _isListening,
            glowColor: AppColors.primary,
            endRadius: 35,
            duration: const Duration(milliseconds: 2000),
            repeatPauseDuration: const Duration(milliseconds: 100),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.isProcessing || _isProcessingVoice
                    ? null
                    : _toggleListening,
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _isListening
                        ? AppColors.severityUrgent.withOpacity(0.15)
                        : (_isProcessingVoice
                              ? Colors.orange.withOpacity(0.15)
                              : (canUseMic
                                    ? AppColors.primaryLight
                                    : Colors.grey.shade200)),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _isListening
                          ? AppColors.severityUrgent
                          : (_isProcessingVoice
                                ? Colors.orange
                                : (canUseMic
                                      ? AppColors.primary.withOpacity(0.3)
                                      : Colors.grey.shade300)),
                      width: 2,
                    ),
                  ),
                  child: _isProcessingVoice
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.orange),
                          ),
                        )
                      : Icon(
                          _isListening
                              ? Icons.mic
                              : (_speechError != null && !canUseMic
                                    ? Icons.mic_off
                                    : Icons.mic_none),
                          color: _isListening
                              ? AppColors.severityUrgent
                              : (_isProcessingVoice
                                    ? Colors.orange
                                    : (canUseMic
                                          ? AppColors.primary
                                          : Colors.grey.shade400)),
                          size: 22,
                        ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),

          // ✅ Champ de texte
          Flexible(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: _isListening
                      ? AppColors.severityUrgent.withOpacity(0.3)
                      : (_isProcessingVoice
                            ? Colors.orange.withOpacity(0.3)
                            : Colors.transparent),
                  width: 2,
                ),
              ),
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                maxLines: 5,
                minLines: 1,
                onSubmitted: (_) => _sendMessage(),
                enabled:
                    !widget.isProcessing &&
                    !_isListening &&
                    !_isProcessingVoice,
                decoration: InputDecoration(
                  hintText: _isListening
                      ? '🎤 Écoute en cours...'
                      : (_isProcessingVoice
                            ? '⏳ Traitement...'
                            : (!canUseMic && _speechError != null
                                  ? '⚠️ $_speechError'
                                  : 'Décrivez vos symptômes ou demandez...')),
                  hintStyle: TextStyle(
                    color: _isListening
                        ? AppColors.severityUrgent
                        : (_isProcessingVoice
                              ? Colors.orange
                              : (!canUseMic && _speechError != null
                                    ? Colors.red.shade400
                                    : Colors.grey.shade400)),
                    fontSize: 14,
                    fontWeight: _isListening
                        ? FontWeight.w500
                        : FontWeight.normal,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  prefixIcon: _isListening || _isProcessingVoice
                      ? const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(
                                AppColors.primary,
                              ),
                            ),
                          ),
                        )
                      : null,
                  suffixIcon:
                      _controller.text.isNotEmpty &&
                          !_isListening &&
                          !_isProcessingVoice
                      ? IconButton(
                          onPressed: () => _controller.clear(),
                          icon: const Icon(Icons.clear, size: 18),
                          splashRadius: 20,
                        )
                      : null,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),

          // ✅ Bouton Envoyer
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: Material(
              color:
                  (_controller.text.isNotEmpty &&
                      !widget.isProcessing &&
                      !_isListening &&
                      !_isProcessingVoice)
                  ? AppColors.primary
                  : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(30),
              child: InkWell(
                onTap: _isListening ? _stopListening : _sendMessage,
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        (_controller.text.isNotEmpty &&
                            !widget.isProcessing &&
                            !_isListening &&
                            !_isProcessingVoice)
                        ? AppColors.primary
                        : Colors.grey.shade300,
                  ),
                  child: widget.isProcessing || _isProcessingVoice
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : Icon(
                          _isListening ? Icons.stop : Icons.send_rounded,
                          color: (_controller.text.isNotEmpty && !_isListening)
                              ? Colors.white
                              : Colors.grey.shade500,
                          size: 22,
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
