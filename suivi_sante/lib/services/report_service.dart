// lib/services/report_service.dart
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/report.dart';
import 'logger_service.dart';

class ReportService {
  // ✅ URL NGROK
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://192.168.1.5:8001/api/',
  );

  Future<String?> _getToken() async {
    LoggerService.debug('Récupération du token d\'authentification...');
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token != null) {
        LoggerService.debug(
          'Token récupéré avec succès (${token.substring(0, min(10, token.length))}...)',
        );
      } else {
        LoggerService.warning('Aucun token trouvé dans SharedPreferences');
      }

      return token;
    } catch (e, stackTrace) {
      LoggerService.error(
        'Erreur lors de la récupération du token',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  Future<Map<String, dynamic>> generateReport({
    required String dateStart,
    required String dateEnd,
    required String type,
  }) async {
    LoggerService.info('🚀 Génération d\'un rapport $type');
    LoggerService.debug('Période: $dateStart → $dateEnd');

    final stopwatch = Stopwatch()..start();

    try {
      final token = await _getToken();
      final url = Uri.parse('$baseUrl/reports/generate');

      final requestBody = {
        'date_start': dateStart,
        'date_end': dateEnd,
        'type': type,
      };

      LoggerService.api('POST', url.toString(), request: requestBody);

      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'ngrok-skip-browser-warning': 'true', // ✅ AJOUT
              if (token != null) 'Authorization': 'Bearer $token',
            },
            body: json.encode(requestBody),
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              LoggerService.error('Timeout lors de la génération du rapport');
              throw Exception('Connexion au serveur impossible (timeout)');
            },
          );

      stopwatch.stop();
      LoggerService.performance(
        'Génération du rapport $type',
        stopwatch.elapsed,
      );

      LoggerService.debug('Status code: ${response.statusCode}');
      LoggerService.debug(
        'Response body: ${response.body.substring(0, min(500, response.body.length))}...',
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        LoggerService.api(
          'POST',
          url.toString(),
          response: data,
          statusCode: response.statusCode,
        );

        if (data['success'] == true) {
          LoggerService.success('✅ Rapport généré avec succès');
          LoggerService.debug('Données reçues: ${data['data']?.keys ?? 'N/A'}');
          return data['data'];
        } else {
          LoggerService.warning('Échec de la génération: ${data['message']}');
          throw Exception(data['message'] ?? 'Erreur de génération');
        }
      } else {
        LoggerService.error(
          'Erreur serveur ${response.statusCode}',
          error: response.body,
        );
        throw Exception('Erreur ${response.statusCode}: ${response.body}');
      }
    } catch (e, stackTrace) {
      stopwatch.stop();
      LoggerService.error(
        'Erreur lors de la génération du rapport',
        error: e,
        stackTrace: stackTrace,
      );
      throw Exception('Erreur: $e');
    }
  }

  Future<List<Report>> getReports() async {
    LoggerService.info('📥 Récupération de la liste des rapports');
    final stopwatch = Stopwatch()..start();

    try {
      final token = await _getToken();
      final url = Uri.parse('$baseUrl/reports');

      LoggerService.api('GET', url.toString());

      final response = await http
          .get(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'ngrok-skip-browser-warning': 'true', // ✅ AJOUT
              if (token != null) 'Authorization': 'Bearer $token',
            },
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              LoggerService.error(
                'Timeout lors de la récupération des rapports',
              );
              throw Exception('Connexion au serveur impossible (timeout)');
            },
          );

      stopwatch.stop();
      LoggerService.performance('Récupération des rapports', stopwatch.elapsed);

      LoggerService.debug('Status code: ${response.statusCode}');
      LoggerService.debug(
        'Response body: ${response.body.substring(0, min(500, response.body.length))}...',
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        LoggerService.api(
          'GET',
          url.toString(),
          response: data,
          statusCode: response.statusCode,
        );

        if (data['success'] == true) {
          final reports = (data['data'] as List)
              .map((item) => Report.fromJson(item))
              .toList();

          LoggerService.success('✅ ${reports.length} rapports récupérés');

          if (reports.isNotEmpty) {
            LoggerService.debug(
              'IDs des rapports: ${reports.map((r) => '${r.id}(${r.status})').join(', ')}',
            );
          }

          return reports;
        } else {
          LoggerService.warning(
            'Réponse API: success=false, message: ${data['message']}',
          );
          return [];
        }
      } else {
        LoggerService.error(
          'Erreur ${response.statusCode} lors de la récupération',
          error: response.body,
        );
        throw Exception('Erreur ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      stopwatch.stop();
      LoggerService.error(
        'Erreur lors de la récupération des rapports',
        error: e,
        stackTrace: stackTrace,
      );
      throw Exception('Erreur: $e');
    }
  }

  Future<void> deleteReport(int id) async {
    LoggerService.info('🗑️ Suppression du rapport #$id');
    final stopwatch = Stopwatch()..start();

    try {
      final token = await _getToken();
      final url = Uri.parse('$baseUrl/reports/$id');

      LoggerService.api('DELETE', url.toString());

      final response = await http
          .delete(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'ngrok-skip-browser-warning': 'true', // ✅ AJOUT
              if (token != null) 'Authorization': 'Bearer $token',
            },
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              LoggerService.error(
                'Timeout lors de la suppression du rapport #$id',
              );
              throw Exception('Connexion au serveur impossible (timeout)');
            },
          );

      stopwatch.stop();
      LoggerService.performance(
        'Suppression du rapport #$id',
        stopwatch.elapsed,
      );

      LoggerService.debug('Status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        LoggerService.success('✅ Rapport #$id supprimé avec succès');
      } else {
        LoggerService.error(
          'Erreur ${response.statusCode} lors de la suppression',
          error: response.body,
        );
        throw Exception('Erreur ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      stopwatch.stop();
      LoggerService.error(
        'Erreur lors de la suppression du rapport #$id',
        error: e,
        stackTrace: stackTrace,
      );
      throw Exception('Erreur: $e');
    }
  }
}