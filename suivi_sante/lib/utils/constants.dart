// lib/utils/constants.dart

import 'package:suivi_sante_pro/config/api_config.dart';

class ApiConstants {
  // URL de base de votre API
  //static const String baseUrl = 'http://192.168.1.215:8000';
  // ✅ Utilise l'URL ngrok
  //static const String baseUrl = 'https://unlivable-omnivore-thrive.ngrok-free.dev';
  static const String baseUrl = ApiConfig.baseUrl;
  
  // Endpoints
  static const String loginEndpoint = '/api/login';
  static const String registerEndpoint = '/api/register';
  static const String dashboardEndpoint = '/api/dashboard';
  static const String constantesEndpoint = '/api/constantes';
  static const String alertesEndpoint = '/api/alertes';
  static const String seuilsEndpoint = '/api/seuils';
  static const String correlationEndpoint = '/api/correlation-symptomes';
  static const String exportEndpoint = '/api/export-constantes';
  static const String goalsEndpoint = '/api/goals';
  static const String challengesEndpoint = '/api/challenges';
  static const String achievementsEndpoint = '/api/achievements';
  
  // Headers
  static const String contentType = 'application/json';
  static const String accept = 'application/json';

  
  // ✅ AJOUTE CETTE LIGNE :
  static const String ngrokSkip = 'true';
  
  // Timeouts
  static const int connectionTimeout = 30;
  static const int receiveTimeout = 30;
}