import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'alarm_sound_service.dart';

/// Top-level background message handler executed by the OS when app is closed.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
    // Background message received while app is terminated
  } catch (_) {}
}

/// Service managing Firebase Cloud Messaging (FCM) registration, topics, and background alerts.
class FcmNotificationService {
  FcmNotificationService._();
  static final FcmNotificationService instance = FcmNotificationService._();

  static const String _prefKeyFcmToken = 'wero_fcm_device_token';
  static const String _prefKeyLastTopic = 'wero_last_region_topic';

  String? _cachedToken;
  String? get fcmToken => _cachedToken;

  /// Initialize Firebase app and request push notification permissions.
  Future<void> initialize() async {
    try {
      if (kIsWeb) {
        // Web FCM requires specific vapidKey configuration; skip safely if omitted
        return;
      }

      await Firebase.initializeApp();

      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      final messaging = FirebaseMessaging.instance;

      // Enable foreground heads-up notifications presentation
      try {
        await messaging.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
      } catch (_) {}

      // Request notification permissions (crucial for Android 13+ and iOS)
      try {
        await messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
          provisional: false,
        );
      } catch (_) {}

      // Listen to registration events (modern replacement in firebase_messaging v17)
      messaging.onRegistered.listen((token) async {
        _cachedToken = token;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_prefKeyFcmToken, token);
        if (kDebugMode) {
          // ignore: avoid_print
          print('[FCM] Device token registered: $token');
        }
      });

      // Register the app instance with Firebase Cloud Messaging
      try {
        await messaging.register();
      } catch (_) {}

      // Subscribe to national broadcasts by default
      try {
        await messaging.subscribeToTopic('nasional');
      } catch (_) {}

      // Listen to foreground FCM messages and trigger alarm siren + vibration
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        try {
          AlarmSoundService().startEmergencyAlarm();
        } catch (_) {}
      });
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('FCM initialization notice: $e');
      }
    }
  }

  /// Subscribe user device to a specific normalized regional topic (e.g. 'region_medan').
  Future<void> syncRegionTopic(String? regionName) async {
    if (kIsWeb || regionName == null || regionName.trim().isEmpty) return;

    try {
      final messaging = FirebaseMessaging.instance;
      final prefs = await SharedPreferences.getInstance();
      final lastTopic = prefs.getString(_prefKeyLastTopic);

      // Clean and normalize topic name (FCM topics only accept [a-zA-Z0-9-_.~%]+)
      final cleanName = regionName
          .trim()
          .toLowerCase()
          .replaceAll('kota', '')
          .replaceAll('kabupaten', '')
          .replaceAll('kab.', '')
          .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')
          .replaceAll(RegExp(r'_+'), '_')
          .trim();

      if (cleanName.isEmpty) return;
      final newTopic = 'region_$cleanName';

      // Unsubscribe from old topic if changed
      if (lastTopic != null && lastTopic != newTopic) {
        await messaging.unsubscribeFromTopic(lastTopic);
      }

      // Subscribe to new topic
      await messaging.subscribeToTopic(newTopic);
      await prefs.setString(_prefKeyLastTopic, newTopic);
    } catch (_) {}
  }
}
