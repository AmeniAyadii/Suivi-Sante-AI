import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:suivi_sante_pro/config/api_config.dart';

class ApiService {
  //static const String baseUrl = String.fromEnvironment(
    //'API_URL',
    //defaultValue: 'https://unlivable-omnivore-thrive.ngrok-free.dev/api', 
  //);
  static const String baseUrl = ApiConfig.baseUrl;

  // ✅ Cette méthode ajoute TOUJOURS le slash
  String _buildUrl(String endpoint) {
    final cleanEndpoint = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    return '$baseUrl$cleanEndpoint';
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Map<String, String> _headers(String? token) => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'ngrok-skip-browser-warning': 'true',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Future<http.Response> get(String endpoint) async {
    final token = await _getToken();
    final url = _buildUrl(endpoint); // ✅
    
    print('📤 GET Request: $url');
    
    return await http.get(
      Uri.parse(url),
      headers: _headers(token),
    ).timeout(
      const Duration(seconds: 30),
      onTimeout: () {
        throw Exception('Connexion au serveur impossible (timeout)');
      },
    );
  }

  Future<http.Response> post(String endpoint, Map<String, dynamic> data) async {
    final token = await _getToken();
    final url = _buildUrl(endpoint); // ✅ Correction ici
    
    print('📤 POST Request: $url');
    print('📦 Data: $data');
    
    return await http.post(
      Uri.parse(url),
      headers: _headers(token),
      body: json.encode(data),
    ).timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        throw Exception('Connexion au serveur impossible (timeout)');
      },
    );
  }

  Future<http.Response> put(String endpoint, Map<String, dynamic> data) async {
    final token = await _getToken();
    final url = _buildUrl(endpoint); // ✅
    
    return await http.put(
      Uri.parse(url),
      headers: _headers(token),
      body: json.encode(data),
    ).timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        throw Exception('Connexion au serveur impossible (timeout)');
      },
    );
  }

  Future<http.Response> delete(String endpoint) async {
    final token = await _getToken();
    final url = _buildUrl(endpoint); // ✅
    
    return await http.delete(
      Uri.parse(url),
      headers: _headers(token),
    ).timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        throw Exception('Connexion au serveur impossible (timeout)');
      },
    );
  }

  Future<dynamic> postWithCleanResponse(String endpoint, dynamic data) async {
    try {
      final token = await _getToken();
      final url = _buildUrl(endpoint); // ✅
      
      final response = await http.post(
        Uri.parse(url),
        headers: _headers(token),
        body: jsonEncode(data),
      );
      
      String responseBody = response.body;
      responseBody = responseBody.replaceAll(RegExp(r'<[^>]*>'), '');
      responseBody = responseBody.trim();
      
      if (responseBody.startsWith('{') || responseBody.startsWith('[')) {
        return jsonDecode(responseBody);
      }
      
      throw Exception('Réponse invalide: $responseBody');
      
    } catch (e) {
      throw Exception('Erreur API: $e');
    }
  }
}