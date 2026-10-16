import 'package:shared_preferences/shared_preferences.dart';

/// Manages locally dismissed/deleted notifications for the current user.
class NotificationDismissService {
  const NotificationDismissService();

  static const String _key = 'wero_dismissed_notification_ids_v1';

  /// Get the set of notification IDs that the user has dismissed/deleted.
  Future<Set<String>> getDismissedIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_key);
      return list != null ? list.toSet() : <String>{};
    } catch (_) {
      return <String>{};
    }
  }

  /// Mark a single notification ID as dismissed.
  Future<void> dismiss(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final current = (prefs.getStringList(_key) ?? []).toSet();
      current.add(id);
      await prefs.setStringList(_key, current.toList());
    } catch (_) {}
  }

  /// Mark multiple notification IDs as dismissed (e.g. "Hapus Semua").
  Future<void> dismissAll(Iterable<String> ids) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final current = (prefs.getStringList(_key) ?? []).toSet();
      current.addAll(ids);
      await prefs.setStringList(_key, current.toList());
    } catch (_) {}
  }

  /// Restore a previously dismissed notification (e.g. Undo action).
  Future<void> restore(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final current = (prefs.getStringList(_key) ?? []).toSet();
      if (current.remove(id)) {
        await prefs.setStringList(_key, current.toList());
      }
    } catch (_) {}
  }

  static const String _keyHandledAlerts = 'wero_handled_alarm_event_ids_v1';

  /// Get event IDs that have already sounded their emergency alarm.
  Future<Set<String>> getHandledAlertIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_keyHandledAlerts);
      return list != null ? list.toSet() : <String>{};
    } catch (_) {
      return <String>{};
    }
  }

  /// Mark an event ID as having already triggered its alarm.
  Future<void> markAlertHandled(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final current = (prefs.getStringList(_keyHandledAlerts) ?? []).toSet();
      current.add(id);
      // Keep only last 50 IDs to prevent unbounded storage
      final list = current.length > 50
          ? current.toList().sublist(current.length - 50)
          : current.toList();
      await prefs.setStringList(_keyHandledAlerts, list);
    } catch (_) {}
  }
}
