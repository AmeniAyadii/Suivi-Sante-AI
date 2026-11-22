// lib/core/constants/api_constants.dart
import 'package:flutter/foundation.dart';

class ApiConstants {
  // ✅ On utilise l'URL de ngrok (avec /api à la fin)
  static const String localBaseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://192.168.1.5:8001/api/', // ← Nouvelle URL
  );
  
  static const String productionBaseUrl = 'http://192.168.1.5:8001/api/';
  
  static String get baseUrl {
    if (kDebugMode) {
      return localBaseUrl;
    }
    return productionBaseUrl;
  }
  
  static const bool forceProduction = false;
  
  static String get forcedBaseUrl {
    if (forceProduction) {
      return productionBaseUrl;
    }
    return baseUrl;
  }
}