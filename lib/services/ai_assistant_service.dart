import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/app_config.dart';
import '../data/ai_offline_engine.dart';
import '../data/emergency_guides_data.dart';
import '../models/chat_message.dart';
import '../models/emergency_guide.dart';

/// Service powering the AI Disaster Assistant with Gemini API & offline fallback.
class AiAssistantService {
  AiAssistantService([this._client, http.Client? httpClient])
    : _httpClient = httpClient ?? http.Client();

  // ignore: unused_field
  final SupabaseClient? _client;
  final http.Client _httpClient;

  /// Generates a response using Gemini API with offline survival fallback.
  Future<ChatMessage> generateResponse(
    String userQuery, {
    List<ChatMessage> previousMessages = const [],
    bool forceOffline = false,
  }) async {
    final query = userQuery.trim().toLowerCase();
    final messageId = 'msg_${DateTime.now().millisecondsSinceEpoch}';

    if (!forceOffline && AppConfig.isGeminiConfigured) {
      try {
        final geminiMsg = await _callGeminiApi(
          messageId,
          userQuery,
          previousMessages: previousMessages,
        );
        if (geminiMsg != null) return geminiMsg;
      } catch (_) {
        // Fall back gracefully to offline disaster engine
      }
    }

    return _generateOfflineFallback(query, messageId);
  }

  Future<ChatMessage?> _callGeminiApi(
    String messageId,
    String query, {
    required List<ChatMessage> previousMessages,
  }) async {
    final url = Uri.parse('${AppConfig.webBackendUrl}/api/assistant/chat');

    final recent = previousMessages.length > 6
        ? previousMessages.sublist(previousMessages.length - 6)
        : previousMessages;

    final historyList = recent
        .map((m) => {'role': m.isUser ? 'user' : 'assistant', 'text': m.text})
        .toList();

    final body = jsonEncode({
      'message': query,
      'previousMessages': historyList,
    });

    final res = await _httpClient
        .post(url, headers: {'Content-Type': 'application/json'}, body: body)
        .timeout(const Duration(seconds: 12));

    if (res.statusCode == 200) {
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      if (json['success'] == true) {
        final text = json['text'] as String?;
        if (text != null && text.trim().isNotEmpty) {
          final serverActions = json['suggestedActions'] as List<dynamic>?;
          final actions = <ChatAction>[];

          if (serverActions != null) {
            for (final a in serverActions) {
              if (a is Map<String, dynamic>) {
                final route = a['route'] as String?;
                EmergencyGuide? guide;
                if (route == '/guides/detail') {
                  final label = (a['label'] as String? ?? '').toLowerCase();
                  if (label.contains('gempa')) {
                    guide = _findGuide('guide-gempa');
                  } else if (label.contains('banjir')) {
                    guide = _findGuide('guide-banjir');
                  }
                }
                actions.add(
                  ChatAction(
                    label: a['label'] as String? ?? '',
                    route: route,
                    routeExtra: guide,
                    phoneNumber: a['phoneNumber'] as String?,
                    iconName: a['iconName'] as String?,
                  ),
                );
              }
            }
          }

          return ChatMessage(
            id: messageId,
            role: ChatRole.assistant,
            text: text.trim(),
            timestamp: DateTime.now(),
            isOfflineFallback: false,
            suggestedActions: actions.isNotEmpty
                ? actions
                : _resolveActionChips(query, text),
          );
        }
      }
    }
    return null;
  }

  List<ChatAction> _resolveActionChips(String query, String text) {
    final lower = '$query $text'.toLowerCase();
    final actions = <ChatAction>[];

    if (lower.contains('gempa')) {
      final g = _findGuide('guide-gempa');
      if (g != null) {
        actions.add(
          ChatAction(
            label: 'Panduan Gempa',
            route: '/guides/detail',
            routeExtra: g,
            iconName: 'menu_book',
          ),
        );
      }
    }
    if (lower.contains('banjir')) {
      final g = _findGuide('guide-banjir');
      if (g != null) {
        actions.add(
          ChatAction(
            label: 'Panduan Banjir',
            route: '/guides/detail',
            routeExtra: g,
            iconName: 'menu_book',
          ),
        );
      }
    }
    if (lower.contains('112')) {
      actions.add(
        const ChatAction(
          label: 'Panggil 112',
          phoneNumber: '112',
          iconName: 'phone',
        ),
      );
    }
    if (lower.contains('115') || lower.contains('basarnas')) {
      actions.add(
        const ChatAction(
          label: 'Panggil 115',
          phoneNumber: '115',
          iconName: 'phone',
        ),
      );
    }
    if (lower.contains('evakuasi') || lower.contains('titik kumpul')) {
      actions.add(
        const ChatAction(
          label: 'Peta Evakuasi',
          route: '/evacuation',
          iconName: 'map',
        ),
      );
    }
    return actions.take(3).toList();
  }

  EmergencyGuide? _findGuide(String id) {
    try {
      return defaultEmergencyGuides.firstWhere((g) => g.id == id);
    } catch (_) {
      return null;
    }
  }

  ChatMessage _generateOfflineFallback(String query, String messageId) {
    return AiOfflineEngine.match(query, messageId);
  }
}
