import 'package:flutter/foundation.dart';

import '../models/app_notification.dart';
import '../services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationService _notificationService = NotificationService();

  List<AppNotification> _notifications = const <AppNotification>[];
  bool _isLoading = false;
  bool _initialized = false;

  List<AppNotification> get notifications => _notifications;
  bool get isLoading => _isLoading;
  bool get initialized => _initialized;
  int get unreadCount => _notifications.where((item) => !item.isRead).length;

  Future<void> initialize() async {
    if (_initialized) return;
    _isLoading = true;
    notifyListeners();

    try {
      _notifications = await _notificationService.loadNotifications();
      _initialized = true;
      _notifications = await _notificationService.syncNotifications();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> sync() async {
    _isLoading = true;
    notifyListeners();

    try {
      _notifications = await _notificationService.syncNotifications();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAllRead() async {
    await _notificationService.markAllRead();
    _notifications = _notifications
        .map((item) => item.copyWith(isRead: true))
        .toList();
    notifyListeners();
  }

  Future<void> markRead(String id) async {
    await _notificationService.markRead(id);
    _notifications = _notifications
        .map((item) => item.id == id ? item.copyWith(isRead: true) : item)
        .toList();
    notifyListeners();
  }
}
