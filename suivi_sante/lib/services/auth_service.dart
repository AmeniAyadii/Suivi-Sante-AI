import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:suivi_sante_pro/config/api_config.dart';
import 'package:suivi_sante_pro/models/user.dart';

class AuthService {
  // ✅ URL ngrok pour que ça fonctionne depuis le téléphone
  //static const String baseUrl = String.fromEnvironment(
    //'API_URL', 
    //defaultValue: 'https://unlivable-omnivore-thrive.ngrok-free.dev/api',
  //);
  static const String baseUrl = ApiConfig.baseUrl;

  // ❌ SUPPRIMÉ : get userData => null;

  Map<String, dynamic>? _userData;
  Map<String, dynamic>? get userData => _userData;

  // ✅ Getter centralisé : en-têtes communs à TOUTES les requêtes
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'ngrok-skip-browser-warning': 'true',
  };

  Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    try {
      final url = Uri.parse('$baseUrl/register');
      print('📤 Register URL: $url');

      print('📤 Headers réels : $_headers');
      
      final response = await http.post(
        url,
        headers: _headers,
        body: json.encode(userData),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Connexion au serveur impossible (timeout)');
        },
      );

      print('📥 Response Status: ${response.statusCode}');
      print('📥 Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        return {
          'error': 'Erreur du serveur: ${response.statusCode}',
          'success': false
        };
      }
    } catch (e) {
      print('❌ Erreur: $e');
      return {
        'error': 'Erreur de connexion: $e',
        'success': false
      };
    }
  }

  // ✅ Méthode login CORRIGÉE avec nettoyage de la réponse
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final url = Uri.parse('$baseUrl/login');
      print('📤 Login URL: $url');
      
      final response = await http.post(
        url,
        headers: _headers,
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      print('📥 Response Status: ${response.statusCode}');
      print('📥 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          await _saveToken(data['token']);
          await _saveUserData(data['user']);
          return data;
        } else {
          return {'error': data['error'] ?? 'Echec de connexion', 'success': false};
        }
      } else {
        // Gérer les erreurs JSON renvoyées par le serveur
        try {
          final data = json.decode(response.body);
          return {
            'error': data['error'] ?? data['message'] ?? 'Erreur ${response.statusCode}',
            'success': false
          };
        } catch (_) {
          return {'error': 'Erreur du serveur: ${response.statusCode}', 'success': false};
        }
      }
    } catch (e) {
      print('❌ Erreur: $e');
      return {'error': 'Erreur de connexion: $e', 'success': false};
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('token');
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  Future<void> _saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user', json.encode(userData));
  }

  Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user');
    if (userJson != null) {
      return json.decode(userJson);
    }
    return null;
  }

  // ==================== MÉTHODE DE RÉINITIALISATION DE MOT DE PASSE ====================
  
  /// Envoie un email de réinitialisation de mot de passe
  /// [email] : L'email de l'utilisateur
  /// Retourne un Map avec 'success' (bool) et 'error' (String optionnel)
  Future<Map<String, dynamic>> sendPasswordResetLink(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/password/email'),
        headers: _headers,
        body: jsonEncode({
          'email': email,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Email de réinitialisation envoyé',
        };
      } else {
        return {
          'success': false,
          'error': data['message'] ?? 'Erreur lors de l\'envoi',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Erreur de connexion: $e',
      };
    }
  }

  /// Récupérer le rôle de l'utilisateur stocké
  Future<String?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user');
    if (userJson != null) {
      final data = json.decode(userJson);
      return data['role']?.toString() ?? 'patient';
    }
    return null;
  }

  /// Récupérer l'utilisateur complet depuis le stockage
  Future<User?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user');
    if (userJson != null) {
      try {
        return User.fromJson(json.decode(userJson));
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  Future<bool> updateCredentials({
    required String email,
    String? currentPassword,
    String? newPassword,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.put(
        Uri.parse('$baseUrl/profile/credentials'),
        headers: {
          ..._headers,
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'email': email,
          if (newPassword != null && newPassword.isNotEmpty) ...{
            'current_password': currentPassword,
            'new_password': newPassword,
            'new_password_confirmation': newPassword,
          }
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        // Mettre à jour l'utilisateur local avec les nouvelles infos
        _userData = data['user']; 
        
        // ✅ Sauvegarder dans le stockage local pour que ça persiste
        await _saveUserData(data['user']);
        
        return true;
      } else if (response.statusCode == 422) {
        throw Exception(data['errors'].values.first[0]); // Récupère la 1ère erreur
      } else {
        throw Exception(data['message'] ?? 'Erreur lors de la mise à jour');
      }
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }
}