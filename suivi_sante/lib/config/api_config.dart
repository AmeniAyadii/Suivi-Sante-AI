
class ApiConfig {
  // Backend Laravel local : téléphone Xiaomi Redmi
  static const String devUrl = 'http://192.168.1.5:8001/api';

  // Backend Laravel en production : Render
  static const String prodUrl = 'https://laravel-suivi.onrender.com/api';

  // URL utilisée par défaut : développement local
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: devUrl,
  );
}
