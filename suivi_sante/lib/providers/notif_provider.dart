// lib/providers/notification_provider.dart
import 'package:flutter/material.dart';
// ✅ Importer avec un alias
import '../models/notification_model.dart' as app;
import '../services/notification_service.dart';

class NotifProvider extends ChangeNotifier {
  final NotificationService _service = NotificationService();
  
  List<app.NotificationModel> _notifications = [];
  bool _isLoading = false;
  String? _error;
  int _unreadCount = 0;

  List<app.NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get unreadCount => _unreadCount;
  int get nonLues => _unreadCount;

  NotifProvider() {
    loadNotifications();
  }

  Future<void> loadNotifications() async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _service.getNotifications();
      if (result.containsKey('data')) {
        _notifications = (result['data'] as List)
            .map((json) => app.NotificationModel.fromJson(json))
            .toList();
        _unreadCount = result['non_lues'] ?? 0;
        _error = null;
      }
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> markAsRead(int id) async {
    try {
      await _service.markAsRead(id);
      
      final index = _notifications.indexWhere((n) => n.id == id);
      if (index != -1) {
        _notifications[index] = app.NotificationModel(
          ..._notifications[index].toJson(),
          lu: true,
        );
        _unreadCount = _notifications.where((n) => !n.lu).length;
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _service.markAllAsRead();
      
      _notifications = _notifications.map((n) {
        return app.NotificationModel(
          ...n.toJson(),
          lu: true,
        );
      }).toList();
      _unreadCount = 0;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteNotification(int id) async {
    try {
      await _service.deleteNotification(id);
      _notifications.removeWhere((n) => n.id == id);
      _unreadCount = _notifications.where((n) => !n.lu).length;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> sendTestNotification() async {
    try {
      await _service.sendTestNotification();
      await loadNotifications();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}