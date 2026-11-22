import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';

class PermissionService {
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  /// Vérifie et demande la permission du microphone
  Future<bool> requestMicrophonePermission() async {
    try {
      // Vérifier si la permission est déjà accordée
      final status = await Permission.microphone.status;
      
      print('📱 État actuel de la permission microphone: $status');
      
      if (status.isGranted) {
        print('✅ Permission déjà accordée');
        return true;
      }
      
      if (status.isDenied) {
        print('📱 Demande de permission...');
        // Demander la permission
        final result = await Permission.microphone.request();
        print('📱 Résultat de la demande: $result');
        
        if (result.isGranted) {
          print('✅ Permission accordée');
          return true;
        } else {
          print('❌ Permission refusée');
          return false;
        }
      }
      
      if (status.isPermanentlyDenied) {
        print('🔒 Permission définitivement refusée');
        return false;
      }
      
      return false;
    } on PlatformException catch (e) {
      print('❌ Erreur permission microphone: $e');
      return false;
    } catch (e) {
      print('❌ Erreur inattendue: $e');
      return false;
    }
  }

  /// Vérifie l'état de la permission
  Future<bool> checkMicrophonePermission() async {
    final status = await Permission.microphone.status;
    print('📱 État permission: $status');
    return status.isGranted;
  }

  /// Ouvre les paramètres de l'application
  Future<void> openSettings() async {
    await openAppSettings();
  }
}

/// Helper pour afficher les dialogues avec contexte
class PermissionHelper {
  static Future<bool> showPermissionDialog({
    required BuildContext context,
    required String title,
    required String message,
    bool showSettings = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                showSettings ? Icons.settings : Icons.mic_off,
                color: showSettings ? Colors.orange : Colors.red,
                size: 28,
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue.shade700,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        showSettings
                            ? 'Activez le microphone dans Paramètres > Applications > Suivi Santé > Permissions'
                            : 'Pour utiliser la fonction vocale, nous avons besoin de votre autorisation.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Non, merci'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context, true);
                
                if (showSettings) {
                  // Ouvrir les paramètres
                  await PermissionService().openSettings();
                } else {
                  // Demander la permission
                  final granted = await PermissionService().requestMicrophonePermission();
                  
                  if (granted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.white),
                            SizedBox(width: 10),
                            Text('✅ Microphone activé avec succès'),
                          ],
                        ),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Row(
                          children: [
                            Icon(Icons.error, color: Colors.white),
                            SizedBox(width: 10),
                            Text('❌ Permission non accordée'),
                          ],
                        ),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: showSettings ? Colors.orange : Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(showSettings ? 'Ouvrir les paramètres' : 'Autoriser'),
            ),
          ],
        );
      },
    );
    
    return result ?? false;
  }
}
