import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/config/app_config.dart';
import 'services/fcm_notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Safely initialize Supabase if credentials are provided.
  if (AppConfig.isSupabaseConfigured) {
    try {
      await Supabase.initialize(
        url: AppConfig.supabaseUrl,
        publishableKey: AppConfig.supabaseAnonKey,
      );
    } catch (_) {
      // In offline/prototype development, allow app to continue gracefully.
    }
  }

  // Fetch dynamic public config (e.g. Mapbox token) from web backend
  unawaited(AppConfig.loadDynamicConfig());

  // Initialize Firebase Cloud Messaging for background push notifications
  unawaited(FcmNotificationService.instance.initialize());

  runApp(const ProviderScope(child: WeroApp()));
}
