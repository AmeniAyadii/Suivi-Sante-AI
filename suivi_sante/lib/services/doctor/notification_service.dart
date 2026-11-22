
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:suivi_sante_pro/models/app_notification.dart';

class NotificationService {
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://192.168.1.5:8001/api',
  );

  // Construction des URL sans double slash
  Uri _url(String path, [Map<String, String>? params]) {
    final base = baseUrl.replaceAll(RegExp(r'/+$'), '');
    final normalizedPath = path.replaceAll(RegExp(r'^/+'), '');

    return Uri.parse('$base/$normalizedPath')
        .replace(queryParameters: params);
  }

  Future<String?> _token() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<Map<String, String>> _headers() async {
    final token = await _token();

    if (token == null || token.isEmpty) {
      throw Exception('Token absent. Veuillez vous reconnecter.');
    }

    return {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
  }

  /// GET /api/notifications
  Future<Map<String, dynamic>> getNotifications({
    bool? lu,
    String? type,
    int perPage = 20,
  }) async {
    final params = <String, String>{
      'per_page': perPage.toString(),
    };

    if (lu != null) params['lu'] = lu ? '1' : '0';
    if (type != null) params['type'] = type;

    final uri = _url('notifications', params);

    print('🔔 URL notifications : $uri');

    final res = await http.get(uri, headers: await _headers());

    print('📥 Status : ${res.statusCode}');
    print('📥 Réponse : ${res.body}');

    if (res.statusCode != 200) {
      throw Exception('Erreur ${res.statusCode}: ${res.body}');
    }

    final json = jsonDecode(utf8.decode(res.bodyBytes))
        as Map<String, dynamic>;

    final list = (json['data'] as List<dynamic>? ?? [])
        .map((e) => AppNotification.fromJson(
              e as Map<String, dynamic>,
            ))
        .toList();

    return {
      'notifications': list,
      'non_lues': json['non_lues'] ?? 0,
      'meta': json['meta'] ?? {},
    };
  }

  /// GET /api/notifications/unread-count
  Future<int> getUnreadCount() async {
    final res = await http.get(
      _url('notifications/unread-count'),
      headers: await _headers(),
    );

    if (res.statusCode != 200) {
      throw Exception('Erreur unread-count : ${res.statusCode}');
    }

    final json = jsonDecode(utf8.decode(res.bodyBytes))
        as Map<String, dynamic>;

    return (json['count'] as num?)?.toInt() ?? 0;
  }

  /// PUT /api/notifications/{id}/read
  Future<bool> markAsRead(int id) async {
    final res = await http.put(
      _url('notifications/$id/read'),
      headers: await _headers(),
    );

    return res.statusCode == 200;
  }

  /// PUT /api/notifications/read-all
  Future<bool> markAllAsRead() async {
    final res = await http.put(
      _url('notifications/read-all'),
      headers: await _headers(),
    );

    return res.statusCode == 200;
  }

  /// DELETE /api/notifications/{id}
  Future<bool> deleteNotification(int id) async {
    final res = await http.delete(
      _url('notifications/$id'),
      headers: await _headers(),
    );

    return res.statusCode == 200;
  }

  /// DELETE /api/notifications
  Future<bool> clearRead() async {
    final res = await http.delete(
      _url('notifications'),
      headers: await _headers(),
    );

    return res.statusCode == 200;
  }
}
