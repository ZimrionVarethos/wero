import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/disaster_event.dart';
import '../../models/user_profile.dart';
import '../../services/fcm_notification_service.dart';
import '../../services/notification_dismiss_service.dart';
import 'auth_providers.dart';
import 'bmkg_providers.dart';
import 'operations_providers.dart';
import 'supabase_providers.dart';

/// Notifier managing active live emergency broadcasts received from Web Admin Portal and FCM.
class ActiveBroadcastNotifier extends Notifier<DisasterEvent?> {
  final _dismissService = const NotificationDismissService();
  final Set<String> _dismissedIds = {};
  final Set<String> _handledAlertIds = {};
  RealtimeChannel? _realtimeChannel;
  Timer? _pollingTimer;
  StreamSubscription<RemoteMessage>? _fcmSubscription;

  @override
  DisasterEvent? build() {
    ref.onDispose(() {
      _realtimeChannel?.unsubscribe();
      _pollingTimer?.cancel();
      _fcmSubscription?.cancel();
    });

    _listenToFcmPush();
    _initRealtimeSubscription();
    _startPeriodicPolling();
    unawaited(_loadPersistedIds());
    return null;
  }

  Future<void> _loadPersistedIds() async {
    final dismissed = await _dismissService.getDismissedIds();
    final handled = await _dismissService.getHandledAlertIds();
    _dismissedIds.addAll(dismissed);
    _handledAlertIds.addAll(handled);
    await _checkRecentBroadcasts();
  }

  void _listenToFcmPush() {
    _fcmSubscription?.cancel();
    _fcmSubscription = FcmNotificationService.instance.onMessageStream.listen((
      msg,
    ) {
      _onFcmMessageReceived(msg);
    });
  }

  Future<void> _onFcmMessageReceived(RemoteMessage msg) async {
    final data = msg.data;
    final eventId = data['event_id'] as String?;
    final sev = (data['severity'] as String? ?? 'AWAS').toUpperCase();

    if (eventId != null && eventId.isNotEmpty) {
      if (_dismissedIds.contains(eventId)) return;
      final alreadyAlerted = _handledAlertIds.contains(eventId);
      _handledAlertIds.add(eventId);
      unawaited(_dismissService.markAlertHandled(eventId));

      if (!alreadyAlerted &&
          (sev == 'AWAS' || sev == 'SIAGA' || sev == 'CRITICAL')) {
        ref.read(alarmSoundServiceProvider).startEmergencyAlarm();
      }
    } else {
      ref.read(alarmSoundServiceProvider).startEmergencyAlarm();
    }

    // Invalidate disaster events so the log sheet updates in realtime without waiting
    ref.invalidate(disasterEventsProvider);
    await _checkRecentBroadcasts();
  }

  void _initRealtimeSubscription() {
    final client = ref.read(supabaseClientProvider);
    if (client == null) return;

    try {
      _realtimeChannel = client.channel('public:disaster_events')
        ..onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'disaster_events',
          callback: (payload) {
            final record = payload.newRecord;
            if (record['is_published'] == true) {
              _onNewBroadcastReceived(DisasterEvent.fromJson(record));
            }
          },
        )
        ..subscribe();
    } catch (_) {
      // Realtime subscription fallback handled by polling
    }
  }

  void _startPeriodicPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _checkRecentBroadcasts();
    });
    // Check once at startup
    _checkRecentBroadcasts();
  }

  Future<void> _checkRecentBroadcasts() async {
    final client = ref.read(supabaseClientProvider);
    if (client == null) return;

    try {
      final res = await client
          .from('disaster_events')
          .select()
          .eq('is_published', true)
          .order('occurred_at', ascending: false)
          .limit(1);

      if (res.isNotEmpty) {
        final latest = DisasterEvent.fromJson(res.first);
        if (_dismissedIds.contains(latest.id)) {
          if (state?.id == latest.id) {
            state = null;
          }
          return;
        }

        // Only trigger if occurred within last 15 minutes
        if (latest.occurredAt != null) {
          final diff = DateTime.now().difference(latest.occurredAt!).inMinutes;
          if (diff <= 15) {
            await _onNewBroadcastReceived(latest);
          }
        }
      }
    } catch (_) {}
  }

  Future<void> _onNewBroadcastReceived(DisasterEvent event) async {
    if (_dismissedIds.contains(event.id)) return;
    if (state?.id == event.id) return;

    // Filter by regional target
    UserProfile? profile = ref.read(userProfileProvider).asData?.value;
    if (profile == null) {
      try {
        profile = await ref.read(userProfileProvider.future);
      } catch (_) {}
    }

    if (!event.isTargetedFor(profile)) {
      return;
    }

    state = event;
    // Invalidate disaster events so the notification log sheet displays the event in realtime
    ref.invalidate(disasterEventsProvider);

    final alreadyAlerted = _handledAlertIds.contains(event.id);
    _handledAlertIds.add(event.id);
    unawaited(_dismissService.markAlertHandled(event.id));

    final sev = event.severity.toUpperCase();
    if (!alreadyAlerted &&
        (sev == 'AWAS' || sev == 'SIAGA' || sev == 'CRITICAL')) {
      ref.read(alarmSoundServiceProvider).startEmergencyAlarm();
    }
  }

  /// Dismiss the active alert and stop the audio siren.
  void dismiss() {
    if (state != null) {
      final id = state!.id;
      _dismissedIds.add(id);
      unawaited(_dismissService.dismiss(id));
    }
    state = null;
    ref.read(alarmSoundServiceProvider).stopEmergencyAlarm();
  }

  /// Dismiss a specific event ID (e.g. from swipe to delete in log sheet).
  void dismissById(String id) {
    _dismissedIds.add(id);
    unawaited(_dismissService.dismiss(id));
    if (state?.id == id) {
      state = null;
      ref.read(alarmSoundServiceProvider).stopEmergencyAlarm();
    }
  }
}

/// Provider exposing the current active disaster broadcast from Web Admin.
final activeBroadcastAlertProvider =
    NotifierProvider<ActiveBroadcastNotifier, DisasterEvent?>(
      ActiveBroadcastNotifier.new,
    );
