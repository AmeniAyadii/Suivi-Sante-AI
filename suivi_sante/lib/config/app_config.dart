// lib/config/app_config.dart
class AppConfig {
  // ============================================================
  // URL DE L'API LARAVEL
  // ============================================================
  
  // ✅ Option 1 : Utiliser NGROK (actuellement actif)
  //static const String baseUrl = 'https://unlivable-omnivore-thrive.ngrok-free.dev/api';
  static const String baseUrl = 'http://192.168.1.5:8001/api/';
  
  // Option 2 : Utiliser l'IP locale (si vous êtes sur le même Wi-Fi)
  // static const String baseUrl = 'http://192.168.1.215:8000/api';
  
  // Option 3 : Émulateur Android
  // static const String baseUrl = 'http://10.0.2.2:8000/api';

  // ============================================================
  // API PYTHON (Analyse de tension)
  // ============================================================
  // Note : Si vous devez aussi y accéder à distance, créez un 2ème tunnel ngrok sur le port 8001
  static const String pythonBaseUrl = 'http://192.168.1.215:8000/api/v1';

  // ============================================================
  // HEADERS
  // ============================================================
  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    // ⚠️ IMPORTANT : Cette ligne évite que ngrok bloque vos requêtes 
    // avec sa page d'avertissement (valable pour tous les services qui utilisent AppConfig.headers)
    'ngrok-skip-browser-warning': 'true',
  };

  static String api(String path) {
    final cleanBase = baseUrl.replaceAll(RegExp(r'/+$'), '');
    final cleanPath = path.replaceAll(RegExp(r'^/+'), '');
    return '$cleanBase/$cleanPath';
  }
}