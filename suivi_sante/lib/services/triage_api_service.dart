// lib/services/triage_api_service.dart
// Service pour appeler l'API FastAPI avec logs complets

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/patient.dart';
import '../models/triage_result.dart';

class TriageApiService {
  // ============================================
  // CONFIGURATION
  // ============================================
  
  /// IP de votre PC sur le réseau local
  /// ⚠️ Changez cette valeur si votre IP change
  static const String PHYSICAL_DEVICE_IP = '192.168.1.5';
  
  /// Port de l'API FastAPI (8001 pour éviter conflit avec Laravel)
  static const int API_PORT = 8002;
  
  /// Timeout pour les requêtes
  static const Duration REQUEST_TIMEOUT = Duration(seconds: 20);
  static const Duration HEALTH_TIMEOUT = Duration(seconds: 5);

  // ============================================
  // BASE URL DYNAMIQUE
  // ============================================
  
  static String get baseUrl {
    // Web (navigateur)
    if (kIsWeb) {
      final url = 'http://127.0.0.1:$API_PORT';
      debugPrint('🌐 [API] Plateforme : WEB');
      debugPrint('🌐 [API] Base URL : $url');
      return url;
    }
    
    // Android
    if (Platform.isAndroid) {
      // Sur émulateur Android, 10.0.2.2 = localhost du PC hôte
      // Mais si vous testez sur un appareil physique, il faut l'IP locale
      // On utilise l'IP locale pour supporter les deux cas
      final url = 'http://$PHYSICAL_DEVICE_IP:$API_PORT';
      debugPrint('🤖 [API] Plateforme : ANDROID');
      debugPrint('🤖 [API] Base URL : $url');
      debugPrint('🤖 [API] Note : Si c\'est un émulateur, remplacez par http://10.0.2.2:$API_PORT');
      return url;
    }
    
    // iOS
    if (Platform.isIOS) {
      final url = 'http://$PHYSICAL_DEVICE_IP:$API_PORT';
      debugPrint('🍎 [API] Plateforme : iOS');
      debugPrint('🍎 [API] Base URL : $url');
      return url;
    }
    
    // Autres (Desktop, etc.)
    final url = 'http://$PHYSICAL_DEVICE_IP:$API_PORT';
    debugPrint('💻 [API] Plateforme : AUTRE');
    debugPrint('💻 [API] Base URL : $url');
    return url;
  }

  // ============================================
  // HEALTH CHECK
  // ============================================
  
  /// Vérifie que l'API est accessible
  Future<bool> checkHealth() async {
    final url = '$baseUrl/health';
    
    _logHeader('HEALTH CHECK');
    _log('📍 URL', url);
    
    try {
      final stopwatch = Stopwatch()..start();
      
      final response = await http
          .get(
            Uri.parse(url),
            headers: {
              'Accept': 'application/json',
            },
          )
          .timeout(HEALTH_TIMEOUT);
      
      stopwatch.stop();
      
      _log('⏱️  Durée', '${stopwatch.elapsedMilliseconds} ms');
      _log('📥 Status', '${response.statusCode}');
      _log('📥 Body', response.body);
      
      if (response.statusCode == 200) {
        //final data = jsonDecode(response.body);
        // ✅ APRÈS (UTF-8 correct)
final data = jsonDecode(utf8.decode(response.bodyBytes));
        final isHealthy = data['status'] == 'ok';
        _log('✅ Résultat', isHealthy ? 'API OK' : 'API dégradée');
        _logFooter();
        return isHealthy;
      }
      
      _log('❌ Résultat', 'Status ${response.statusCode}');
      _logFooter();
      return false;
    } catch (e) {
      _log('❌ Erreur', e.toString());
      _logFooter();
      return false;
    }
  }

  // ============================================
  // PRÉDICTION
  // ============================================
  
  /// Prédit le niveau de triage
    /// Prédit le niveau de triage
  Future<TriageResult> predictTriage(Patient patient) async {
    final url = '$baseUrl/predict';
    final body = jsonEncode(patient.toJson());
    
    _logHeader('PRÉDICTION DE TRIAGE');
    _log('📍 URL', url);
    _log('📦 Body', body);
    _log('📦 Taille body', '${body.length} caractères');
    
    try {
      final stopwatch = Stopwatch()..start();
      
      // ✅ MODIFICATION 1 et 2 : headers avec charset=utf-8 + body en bytes
      final response = await http
          .post(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json; charset=utf-8',  // ✅
              'Accept': 'application/json; charset=utf-8',        // ✅
            },
            body: utf8.encode(body),                               // ✅
          )
          .timeout(REQUEST_TIMEOUT);
      
      stopwatch.stop();
      
      _log('⏱️  Durée', '${stopwatch.elapsedMilliseconds} ms');
      _log('📥 Status', '${response.statusCode}');
      _log('📥 Headers', response.headers.toString());
      
      // ✅ MODIFICATION 3 : décoder la réponse en UTF-8
      final decodedBody = utf8.decode(response.bodyBytes);         // ✅
      _log('📥 Body', decodedBody);
      
      // ----- Succès -----
      if (response.statusCode == 200) {
        try {
          // ✅ MODIFICATION 3 (suite) : parser le body décodé
          final data = jsonDecode(decodedBody);                    // ✅
          final result = TriageResult.fromJson(data);
          
          _log('✅ Résultat', 'Niveau ${result.triageAcuity} (${result.label})');
          _log('✅ Confiance', '${(result.confidence * 100).toStringAsFixed(1)}%');
          _log('✅ Emoji reçu', '"${result.emoji}" (codePoint: ${result.emoji.runes.first})');  // ✅ Debug
          _logFooter();
          
          return result;
        } catch (e) {
          _log('❌ Parsing JSON', e.toString());
          _logFooter();
          throw Exception(
            'Réponse invalide du serveur.\n\n'
            'Le JSON reçu ne peut pas être parsé.\n'
            'Body : $decodedBody\n\n'
            'Erreur : $e',
          );
        }
      }
      
      // ----- Erreur HTTP (4xx, 5xx) -----
      _log('❌ Erreur HTTP', 'Status ${response.statusCode}');
      _logFooter();
      
      throw Exception(
        'Erreur serveur (${response.statusCode})\n\n'
        'Le serveur a retourné une erreur.\n'
        'Body : $decodedBody',
      );
      
    } on SocketException catch (e) {
      _log('❌ SocketException', e.toString());
      _log('❌ Cause', _getSocketErrorMessage(e, url));
      _logFooter();
      throw Exception(_getSocketErrorMessage(e, url));
      
    } on TimeoutException catch (e) {
      _log('❌ TimeoutException', e.toString());
      _logFooter();
      throw Exception(
        '⏱️  Délai d\'attente dépassé (${REQUEST_TIMEOUT.inSeconds} sec)\n\n'
        'L\'API met trop de temps à répondre.\n\n'
        'URL testée : $url',
      );
      
    } on FormatException catch (e) {
      _log('❌ FormatException', e.toString());
      _logFooter();
      throw Exception(
        '📄 Réponse invalide du serveur\n\n'
        'URL testée : $url\n\n'
        'Détail : $e',
      );
      
    } on HttpException catch (e) {
      _log('❌ HttpException', e.toString());
      _logFooter();
      throw Exception('Erreur HTTP : ${e.message}\n\nURL testée : $url');
      
    } catch (e) {
      _log('❌ Erreur inconnue', e.toString());
      _log('❌ Type', e.runtimeType.toString());
      _logFooter();
      throw Exception(
        'Erreur de prédiction :\n\n'
        '$e\n\n'
        'URL testée : $url',
      );
    }
  }

  // ============================================
  // MESSAGES D'ERREUR DÉTAILLÉS
  // ============================================
  
  String _getSocketErrorMessage(SocketException e, String url) {
    final osError = e.osError;
    final errorCode = osError?.errorCode;
    final message = osError?.message ?? e.message;
    
    // Messages selon le code d'erreur
    String hint = '';
    switch (errorCode) {
      case 61:  // Connection refused (macOS/iOS)
      case 111: // Connection refused (Linux)
      case 10061: // Connection refused (Windows)
        hint = '🚫 Le serveur refuse la connexion\n\n'
               'Causes possibles :\n'
               '1. ❌ L\'API FastAPI N\'EST PAS DÉMARRÉE\n'
               '2. ❌ L\'API écoute sur un autre port\n'
               '3. ❌ Un pare-feu bloque la connexion\n\n'
               '➡️  Solution : Démarrez l\'API avec :\n'
               '   .\\venv\\Scripts\\python.exe -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8001';
        break;
        
      case 110: // Connection timed out
      case 10060: // Connection timed out (Windows)
        hint = '⏱️  Délai de connexion dépassé\n\n'
               'Causes possibles :\n'
               '1. ❌ L\'IP $PHYSICAL_DEVICE_IP est incorrecte\n'
               '2. ❌ Vous n\'êtes pas sur le même WiFi\n'
               '3. ❌ Le pare-feu bloque la connexion\n\n'
               '➡️  Vérifiez votre IP avec : ipconfig';
        break;
        
      case 113: // No route to host
      case 10065: // No route to host (Windows)
        hint = '🛣️  Aucune route vers le serveur\n\n'
               'Causes possibles :\n'
               '1. ❌ L\'appareil n\'est pas sur le même réseau\n'
               '2. ❌ L\'IP du serveur est incorrecte\n\n'
               '➡️  Vérifiez que PC et téléphone sont sur le même WiFi';
        break;
        
      default:
        hint = '🔌 Impossible de contacter le serveur\n\n'
               'Erreur : $message\n'
               'Code : $errorCode\n\n'
               'URL testée : $url';
    }
    
    return 'IMPOSSIBLE DE SE CONNECTER À L\'API\n\n'
           '$hint\n\n'
           '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'
           '📋 DIAGNOSTIC :\n'
           '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'
           '• URL utilisée    : $url\n'
           '• IP configurée   : $PHYSICAL_DEVICE_IP\n'
           '• Port configuré  : $API_PORT\n'
           '• Erreur système  : $message (code $errorCode)\n\n'
           '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'
           '✅ VÉRIFICATIONS À FAIRE :\n'
           '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'
           '1. L\'API FastAPI est démarrée ?\n'
           '   curl.exe http://$PHYSICAL_DEVICE_IP:$API_PORT/health\n\n'
           '2. Votre IP est correcte ?\n'
           '   ipconfig\n\n'
           '3. Le pare-feu autorise le port $API_PORT ?\n'
           '   netsh advfirewall firewall add rule name="FastAPI" dir=in action=allow protocol=TCP localport=$API_PORT\n\n'
           '4. Vous êtes sur le même WiFi ?';
  }

  // ============================================
  // LOGS
  // ============================================
  
  void _logHeader(String title) {
    debugPrint('');
    debugPrint('╔══════════════════════════════════════════════════════╗');
    debugPrint('║  🚀 $title');
    debugPrint('╠══════════════════════════════════════════════════════╣');
  }
  
  void _logFooter() {
    debugPrint('╚══════════════════════════════════════════════════════╝');
    debugPrint('');
  }
  
  void _log(String label, String value) {
    // Tronquer les valeurs trop longues
    final displayValue = value.length > 200 
        ? '${value.substring(0, 200)}... (${value.length} chars)' 
        : value;
    debugPrint('║ $label : $displayValue');
  }
}