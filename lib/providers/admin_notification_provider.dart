import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';

class AdminNotification {
  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  bool isRead;

  AdminNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    this.isRead = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'body': body,
    'timestamp': timestamp.toIso8601String(),
    'isRead': isRead,
  };

  factory AdminNotification.fromJson(Map<String, dynamic> json) =>
      AdminNotification(
        id: json['id'] as String,
        title: json['title'] as String,
        body: json['body'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        isRead: json['isRead'] as bool? ?? false,
      );
}

class AdminNotificationProvider extends ChangeNotifier {
  static const _key = 'admin_notifications';

  List<AdminNotification> _notifications = [];

  List<AdminNotification> get notifications =>
      List.unmodifiable(_notifications);

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  bool get hasUnread => unreadCount > 0;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      final list = jsonDecode(raw) as List<dynamic>;
      _notifications =
          list
              .map((e) => AdminNotification.fromJson(e as Map<String, dynamic>))
              .toList()
            ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    }
    notifyListeners();
  }

  Future<void> addNotification({
    required String title,
    required String body,
  }) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final notif = AdminNotification(
      id: id,
      title: title,
      body: body,
      timestamp: DateTime.now(),
      isRead: false,
    );
    _notifications.insert(0, notif);
    await _save();
    notifyListeners();
    // Also push to system notification bar
    await NotificationService().showAdminNotification(
      title: title,
      body: body,
      id: id,
    );
  }

  Future<void> markAllRead() async {
    for (final n in _notifications) {
      n.isRead = true;
    }
    await _save();
    notifyListeners();
  }

  Future<void> markRead(String id) async {
    final n = _notifications.firstWhere((n) => n.id == id);
    n.isRead = true;
    await _save();
    notifyListeners();
  }

  Future<void> deleteNotification(String id) async {
    _notifications.removeWhere((n) => n.id == id);
    await _save();
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(_notifications.map((n) => n.toJson()).toList()),
    );
  }
}
