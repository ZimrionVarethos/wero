import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/ai_assistant_providers.dart';
import '../../routing/app_router.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_bottom_navigation.dart';
import 'widgets/chat_bubble.dart';
import 'widgets/chat_input_bar.dart';
import 'widgets/gemini_avatar.dart';
import 'widgets/suggested_prompts.dart';

/// Screen for conversational disaster assistance and offline survival advice.
class AssistantScreen extends ConsumerStatefulWidget {
  const AssistantScreen({super.key});

  @override
  ConsumerState<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends ConsumerState<AssistantScreen> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onBottomNavTap(int index) {
    if (index == 0) context.go(AppRoutes.activity);
    if (index == 1) return; // already here
    if (index == 2) context.go(AppRoutes.community);
    if (index == 3) context.go(AppRoutes.statistics);
    if (index == 4) context.go(AppRoutes.profile);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage([String? text]) {
    final query = text ?? _inputController.text;
    if (query.trim().isEmpty) return;
    _inputController.clear();
    ref.read(aiChatProvider.notifier).sendMessage(query);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiChatProvider);

    ref.listen(aiChatProvider, (previous, next) => _scrollToBottom());

    return Scaffold(
      backgroundColor: AppColors.canvasBlue,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            _buildDisclaimer(),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                itemCount: state.messages.length + (state.isGenerating ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == state.messages.length) {
                    return _buildTypingIndicator();
                  }
                  return ChatBubble(message: state.messages[index]);
                },
              ),
            ),
            SuggestedPrompts(
              disabled: state.isGenerating,
              onSelectPrompt: _sendMessage,
            ),
            ChatInputBar(
              controller: _inputController,
              isGenerating: state.isGenerating,
              onSend: _sendMessage,
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: 1,
        onTap: _onBottomNavTap,
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.pagePadding,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const GeminiAvatar(size: 34, iconSize: 19),
              const SizedBox(width: AppSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Asisten Siaga AI', style: AppTextStyles.screenTitle),
                  const SizedBox(height: 2),
                  Text(
                    'Panduan Bencana BNPB / BMKG',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.chartBlue,
                    ),
                  ),
                ],
              ),
            ],
          ),
          IconButton(
            icon: const Icon(
              Icons.restart_alt_rounded,
              color: AppColors.textSecondary,
            ),
            tooltip: 'Mulai Ulang Percakapan',
            onPressed: () => ref.read(aiChatProvider.notifier).clearChat(),
          ),
        ],
      ),
    );
  }

  Widget _buildDisclaimer() {
    return Container(
      width: double.infinity,
      color: AppColors.softBlue,
      padding: const EdgeInsets.symmetric(
        vertical: 6,
        horizontal: AppSpacing.pagePadding,
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.pagePadding,
        bottom: AppSpacing.md,
      ),
      child: Row(
        children: [
          const GeminiAvatar(size: 26, iconSize: 14),
          const SizedBox(width: AppSpacing.xs),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.chartBlue,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'Siaga AI sedang merumuskan langkah...',
                  style: AppTextStyles.caption.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
