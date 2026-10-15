import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/disaster_event.dart';
import '../../models/user_profile.dart';
import 'auth_providers.dart';
import 'bmkg_providers.dart';
import 'supabase_providers.dart';

/// Notifier managing active live emergency broadcasts received from Web Admin Portal.
class ActiveBroadcastNotifier extends Notifier<DisasterEvent?> {
  final Set<String> _dismissedIds = {};
  RealtimeChannel? _realtimeChannel;
  Timer? _pollingTimer;

  @override
  DisasterEvent? build() {
    ref.onDispose(() {
      _realtimeChannel?.unsubscribe();
      _pollingTimer?.cancel();
    });

    _initRealtimeSubscription();
    _startPeriodicPolling();
    return null;
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
        // Only trigger if occurred within last 15 minutes and not dismissed
        if (latest.occurredAt != null) {
          final diff = DateTime.now().difference(latest.occurredAt!).inMinutes;
          if (diff <= 15 && !_dismissedIds.contains(latest.id)) {
            _onNewBroadcastReceived(latest);
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
    ref.read(alarmSoundServiceProvider).startEmergencyAlarm();
  }

  /// Dismiss the active alert and stop the audio siren.
  void dismiss() {
    if (state != null) {
      _dismissedIds.add(state!.id);
    }
    state = null;
    ref.read(alarmSoundServiceProvider).stopEmergencyAlarm();
  }
}

/// Provider exposing the current active disaster broadcast from Web Admin.
final activeBroadcastAlertProvider =
    NotifierProvider<ActiveBroadcastNotifier, DisasterEvent?>(
      ActiveBroadcastNotifier.new,
    );
