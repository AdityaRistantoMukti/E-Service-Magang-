import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification_model.dart';

class NotificationService {
  static const String _key = 'notifications';

  // Add a new notification
  static Future<void> addNotification(NotificationModel notification) async {
    final prefs = await SharedPreferences.getInstance();
    final notifications = await getNotifications();
    notifications.add(notification);
    // Sort by timestamp descending (newest first)
    notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final encoded = jsonEncode(notifications.map((n) => n.toMap()).toList());
    await prefs.setString(_key, encoded);
  }

  // Get all notifications
  static Future<List<NotificationModel>> getNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_key);
    if (data == null) return [];
    final decoded = jsonDecode(data) as List;
    return decoded.map((map) => NotificationModel.fromMap(map)).toList();
  }

  // Remove a notification by index
  static Future<void> removeNotification(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final notifications = await getNotifications();
    if (index >= 0 && index < notifications.length) {
      notifications.removeAt(index);
      final encoded = jsonEncode(notifications.map((n) => n.toMap()).toList());
      await prefs.setString(_key, encoded);
    }
  }

  // Clear all notifications
  static Future<void> clearNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
