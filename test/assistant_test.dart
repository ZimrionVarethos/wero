import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wero/core/providers/ai_assistant_providers.dart';
import 'package:wero/models/chat_message.dart';
import 'package:wero/screens/assistant/assistant_screen.dart';
import 'package:wero/screens/assistant/widgets/chat_bubble.dart';
import 'package:wero/services/ai_assistant_service.dart';

void main() {
  group('AI Assistant Service Tests', () {
    final service = AiAssistantService();

    test(
      'Answers earthquake query with Drop Cover Hold On and guide action',
      () async {
        final res = await service.generateResponse(
          'Apa yang harus dilakukan saat gempa bumi?',
          forceOffline: true,
        );
        expect(res.role, equals(ChatRole.assistant));
        expect(res.text, contains('Drop, Cover, Hold On'));
        expect(res.isOfflineFallback, isTrue);
        expect(
          res.suggestedActions.any((a) => a.label.contains('Gempa')),
          isTrue,
        );
      },
    );

    test(
      'Answers flood query with electricity warning and evacuation map action',
      () async {
        final res = await service.generateResponse(
          'Ada banjir di dekat rumah',
          forceOffline: true,
        );
        expect(res.role, equals(ChatRole.assistant));
        expect(res.text, contains('Matikan Listrik'));
        expect(
          res.suggestedActions.any((a) => a.route == '/evacuation'),
          isTrue,
        );
      },
    );

    test('Answers emergency numbers query with 112 and Basarnas', () async {
      final res = await service.generateResponse(
        'Berapa nomor darurat penting?',
        forceOffline: true,
      );
      expect(res.role, equals(ChatRole.assistant));
      expect(res.text, contains('112'));
      expect(res.text, contains('115'));
      expect(res.suggestedActions.any((a) => a.phoneNumber == '112'), isTrue);
    });

    test('Gemini API call returns structured response when online', () async {
      final res = await service.generateResponse(
        'Halo Siaga AI, sebutkan tips gempa singkat',
      );
      expect(res.role, equals(ChatRole.assistant));
      expect(res.text.isNotEmpty, isTrue);
    });
  });

  group('AI Assistant Provider State Tests', () {
    test('Initial state contains greeting message', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(aiChatProvider);
      expect(state.messages.length, equals(1));
      expect(state.messages.first.role, equals(ChatRole.assistant));
      expect(state.messages.first.text, contains('Asisten Siaga AI'));
    });

    test('sendMessage appends user and assistant messages', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container
          .read(aiChatProvider.notifier)
          .sendMessage('Info kebakaran');
      final state = container.read(aiChatProvider);

      expect(state.messages.length, equals(3));
      expect(state.messages[1].role, equals(ChatRole.user));
      expect(state.messages[1].text, equals('Info kebakaran'));
      expect(state.messages[2].role, equals(ChatRole.assistant));
      expect(state.messages[2].text, contains('Kebakaran'));
    });

    test('clearChat resets message history to single greeting', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(aiChatProvider.notifier).sendMessage('Tes');
      expect(container.read(aiChatProvider).messages.length, equals(3));

      container.read(aiChatProvider.notifier).clearChat();
      expect(container.read(aiChatProvider).messages.length, equals(1));
    });
  });

  group('Assistant Widgets Tests', () {
    testWidgets('ChatBubble displays user and assistant content correctly', (
      tester,
    ) async {
      final userMsg = ChatMessage(
        id: '1',
        role: ChatRole.user,
        text: 'Halo Siaga AI',
        timestamp: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ChatBubble(message: userMsg)),
        ),
      );

      expect(find.text('Halo Siaga AI'), findsOneWidget);
    });

    testWidgets(
      'ChatBubble renders assistant message with markdown and gemini avatar',
      (tester) async {
        final aiMsg = ChatMessage(
          id: '2',
          role: ChatRole.assistant,
          text: '**Langkah 1**: Lindungi kepala dan leher.',
          timestamp: DateTime.now(),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: ChatBubble(message: aiMsg)),
          ),
        );

        expect(
          find.textContaining('Lindungi kepala dan leher'),
          findsOneWidget,
        );
      },
    );

    testWidgets('AssistantScreen renders title, disclaimer and quick prompts', (
      tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: AssistantScreen())),
      );

      expect(find.text('Asisten Siaga AI'), findsOneWidget);
      expect(
        find.textContaining('Panduan Bencana BNPB / BMKG'),
        findsOneWidget,
      );
      expect(find.text('Apa yang harus dilakukan saat gempa?'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });
  });
}
