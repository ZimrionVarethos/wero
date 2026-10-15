import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/chat_message.dart';
import '../../services/ai_assistant_service.dart';
import 'supabase_providers.dart';

/// Provider for the AI Assistant Service.
final aiAssistantServiceProvider = Provider<AiAssistantService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return AiAssistantService(client);
});

/// State for the disaster assistant conversation.
class AiChatState {
  const AiChatState({
    required this.messages,
    this.isGenerating = false,
    this.isOfflineMode = true,
  });

  final List<ChatMessage> messages;
  final bool isGenerating;
  final bool isOfflineMode;

  AiChatState copyWith({
    List<ChatMessage>? messages,
    bool? isGenerating,
    bool? isOfflineMode,
  }) {
    return AiChatState(
      messages: messages ?? this.messages,
      isGenerating: isGenerating ?? this.isGenerating,
      isOfflineMode: isOfflineMode ?? this.isOfflineMode,
    );
  }
}

/// Notifier managing AI chat interaction, loading state, and message stream.
class AiChatNotifier extends Notifier<AiChatState> {
  @override
  AiChatState build() {
    return AiChatState(messages: [_initialGreetingMessage()]);
  }

  AiAssistantService get _service => ref.read(aiAssistantServiceProvider);

  static ChatMessage _initialGreetingMessage() {
    return ChatMessage(
      id: 'init_welcome',
      role: ChatRole.assistant,
      text:
          'Halo! Saya **Asisten Siaga AI**.\n\n'
          'Saya siap memberikan instruksi darurat cepat sesuai protokol resmi BNPB & BMKG, baik saat Anda terhubung internet maupun **dalam mode offline** saat sinyal darurat terputus.\n\n'
          'Ada yang bisa saya bantu untuk keselamatan Anda saat ini?',
      timestamp: DateTime.now(),
      isOfflineFallback: true,
      suggestedActions: const [
        ChatAction(label: 'Gempa Bumi', route: '/guides'),
        ChatAction(label: 'Nomor Darurat', phoneNumber: '112'),
        ChatAction(label: 'Peta Evakuasi', route: '/evacuation'),
      ],
    );
  }

  /// Sends a message and generates an assistant response.
  Future<void> sendMessage(String text) async {
    final query = text.trim();
    if (query.isEmpty || state.isGenerating) return;

    final userMsg = ChatMessage(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      role: ChatRole.user,
      text: query,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isGenerating: true,
    );

    try {
      final response = await _service.generateResponse(
        query,
        previousMessages: state.messages,
      );

      state = state.copyWith(
        messages: [...state.messages, response],
        isGenerating: false,
      );
    } catch (_) {
      final errorMsg = ChatMessage(
        id: 'err_${DateTime.now().millisecondsSinceEpoch}',
        role: ChatRole.assistant,
        text: 'Mohon maaf, terjadi kendala saat memproses jawaban. Silakan buka menu Panduan Bencana secara langsung.',
        timestamp: DateTime.now(),
        isOfflineFallback: true,
        suggestedActions: const [
          ChatAction(label: 'Buka Panduan Darurat', route: '/guides'),
        ],
      );

      state = state.copyWith(
        messages: [...state.messages, errorMsg],
        isGenerating: false,
      );
    }
  }

  /// Clears the conversation and resets to the welcome message.
  void clearChat() {
    state = AiChatState(messages: [_initialGreetingMessage()]);
  }
}

/// Provider exposing the AI assistant chat notifier and state.
final aiChatProvider = NotifierProvider<AiChatNotifier, AiChatState>(
  AiChatNotifier.new,
);
