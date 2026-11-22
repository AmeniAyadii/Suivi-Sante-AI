import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:suivi_sante_pro/config/app_config.dart';
import '../models/symptome.dart';

class SymptomAnalysisService {
  // ⚠️ SUPPRIMÉ : static const String baseUrl = AppConfig.baseUrl;
  // → utiliser AppConfig.api() directement

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<Map<String, dynamic>> analyzeSymptoms(List<Symptome> symptomes) async {
    try {
      final token = await _getToken();
      final url = Uri.parse(AppConfig.api('/symptomes/analyze')); // ✅

      print('📤 POST $url');

      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              if (token != null) 'Authorization': 'Bearer $token',
            },
            body: json.encode({
              'symptomes': symptomes.map((s) => s.toJson()).toList(),
            }),
          )
          .timeout(const Duration(seconds: 30));

      print('📥 Status: ${response.statusCode}');
      print('📥 Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final result = data['data'] ?? {};

          if (result['summary'] != null) {
            result['summary'] = _formatSummary(result['summary']);
          }
          if (result['recommendations'] != null) {
            result['recommendations'] = _formatRecommendations(
              result['recommendations'],
            );
          }
          return result;
        }
        return data;
      } else {
        throw Exception('Erreur ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ Erreur analyzeSymptoms: $e');
      rethrow;
    }
  }

  String _formatSummary(String summary) {
    String cleaned = summary
        .replaceAll('**', '')
        .replaceAll('\\n', '\n')
        .replaceAll('\n\n', '\n')
        .trim();

    if (!cleaned.contains('\n')) {
      final lines = cleaned.split('. ');
      if (lines.length > 1) {
        return lines.map((l) => '• $l').join('\n');
      }
      return '• $cleaned';
    }
    return cleaned;
  }

  String _formatRecommendations(String recommendations) {
    String cleaned = recommendations
        .replaceAll('**', '')
        .replaceAll('\\n', '\n')
        .replaceAll('\n\n', '\n')
        .trim();

    if (!cleaned.contains('\n')) {
      final lines = cleaned.split('. ');
      if (lines.length > 1) {
        return lines.map((l) => '• $l').join('\n');
      }
      return '• $cleaned';
    }
    return cleaned;
  }
}