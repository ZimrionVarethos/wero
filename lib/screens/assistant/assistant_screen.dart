import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/ai_assistant_providers.dart';
import '../../routing/app_router.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_bottom_navigation.dart';
import '../../widgets/app_header.dart';
import '../../widgets/contour_wave_background.dart';
import 'widgets/chat_bubble.dart';
import 'widgets/chat_input_bar.dart';
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
    if (index == 3) context.go(AppRoutes.profile);
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
      backgroundColor: AppColors.backgroundCream,
      appBar: AppHeader(
        showBackButton: false,
        prefixActions: [
          IconButton(
            icon: const Icon(Icons.restart_alt_rounded, size: 22),
            color: AppColors.primaryNavy,
            tooltip: 'Mulai Ulang Percakapan',
            onPressed: () => ref.read(aiChatProvider.notifier).clearChat(),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(
            child: IgnorePointer(
              child: ContourWaveBackground(variant: ContourVariant.assistant),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildDisclaimer(),
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.sm,
                    ),
                    itemCount:
                        state.messages.length + (state.isGenerating ? 1 : 0),
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
        ],
      ),
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: 1,
        onTap: _onBottomNavTap,
      ),
    );
  }

  Widget _buildDisclaimer() {
    return Container(
      width: double.infinity,
      color: AppColors.softBlue.withValues(alpha: 0.3),
      padding: const EdgeInsets.symmetric(
        vertical: 4,
        horizontal: AppSpacing.pagePadding,
      ),
      child: const Row(
        children: [
          Icon(
            Icons.offline_bolt_outlined,
            size: 14,
            color: AppColors.chartBlue,
          ),
          SizedBox(width: 6),
          Text(
            'Panduan Siaga Darurat Offline BNPB & BMKG',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.pagePadding,
        bottom: AppSpacing.md,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(
            color: AppColors.borderNeutral.withValues(alpha: 0.8),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryNavy.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.asset(
                'assets/images/icon.png',
                width: 20,
                height: 20,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primaryNavy,
              ),
            ),
            const SizedBox(width: AppSpacing.xs + 2),
            Text(
              'Siaga AI sedang merumuskan langkah...',
              style: AppTextStyles.caption.copyWith(
                fontStyle: FontStyle.italic,
                color: AppColors.mutedText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
