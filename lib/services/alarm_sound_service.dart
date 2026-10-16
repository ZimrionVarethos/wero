import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

/// Singleton service managing emergency alert audio sirens and haptic vibrations.
class AlarmSoundService {
  factory AlarmSoundService() => _instance;

  AlarmSoundService._internal() : _player = AudioPlayer();

  static final AlarmSoundService _instance = AlarmSoundService._internal();

  static const MethodChannel _vibrationChannel = MethodChannel(
    'com.siagaku.wero/vibration',
  );

  final AudioPlayer _player;
  Timer? _hapticTimer;
  bool _isPlaying = false;
  int _playSessionId = 0;

  bool get isPlaying => _isPlaying;

  static const String emergencySirenUrl =
      'https://assets.mixkit.co/active_storage/sfx/2869/2869-preview.mp3';

  /// Starts the emergency alarm sound and rhythmic vibration.
  Future<void> startEmergencyAlarm({String? audioUrl}) async {
    if (_isPlaying) return;
    _isPlaying = true;
    final session = ++_playSessionId;

    // Trigger powerful Android hardware vibrator
    try {
      unawaited(_vibrationChannel.invokeMethod('vibrateEmergency'));
    } catch (_) {}

    // Start rhythmic haptic vibration fallback
    _triggerHaptic();
    _hapticTimer?.cancel();
    _hapticTimer = Timer.periodic(const Duration(milliseconds: 600), (_) {
      if (_isPlaying && _playSessionId == session) {
        _triggerHaptic();
      }
    });

    try {
      await _player.setReleaseMode(ReleaseMode.loop);
      // Abort if user already requested stop while preparing
      if (!_isPlaying || _playSessionId != session) {
        await _player.setReleaseMode(ReleaseMode.release);
        await _player.pause();
        await _player.stop();
        return;
      }

      await _player.play(UrlSource(audioUrl ?? emergencySirenUrl), volume: 1.0);

      // Verify user hasn't cancelled while the network audio was streaming/buffering
      if (!_isPlaying || _playSessionId != session) {
        await _player.setReleaseMode(ReleaseMode.release);
        await _player.pause();
        await _player.stop();
      }
    } catch (_) {
      // Audio playback errors should not prevent visual alert or vibration
    }
  }

  void _triggerHaptic() {
    try {
      HapticFeedback.heavyImpact();
    } catch (_) {}
  }

  /// Stops the emergency alarm sound and stops vibration immediately.
  Future<void> stopEmergencyAlarm() async {
    _isPlaying = false;
    _playSessionId++; // Invalidate any in-flight startEmergencyAlarm invocation
    _hapticTimer?.cancel();
    _hapticTimer = null;
    try {
      unawaited(_vibrationChannel.invokeMethod('stopVibration'));
    } catch (_) {}
    try {
      await _player.setReleaseMode(ReleaseMode.release);
      await _player.pause();
      await _player.stop();
    } catch (_) {}
  }

  /// Dispose player resources.
  Future<void> dispose() async {
    await stopEmergencyAlarm();
    await _player.dispose();
  }
}
