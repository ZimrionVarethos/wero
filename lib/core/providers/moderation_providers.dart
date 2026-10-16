import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/community_report.dart';
import '../../models/moderation_action.dart';
import '../../services/community_moderation_service.dart';
import 'supabase_providers.dart';

/// Provider for CommunityModerationService instance.
final moderationServiceProvider = Provider<CommunityModerationService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return CommunityModerationService(client);
});

/// Provider checking whether current logged in user has moderator rights.
final isModeratorProvider = FutureProvider<bool>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return false;
  return ref.watch(moderationServiceProvider).checkIsModerator(user.id);
});

/// Provider for fetching pending community reports queue.
final pendingReportsProvider =
    FutureProvider.autoDispose<List<CommunityReport>>((ref) async {
      return ref.watch(moderationServiceProvider).fetchPendingReports();
    });

/// Provider for fetching audit history of moderation actions.
final moderationHistoryProvider =
    FutureProvider.autoDispose<List<ModerationAction>>((ref) async {
      return ref.watch(moderationServiceProvider).fetchModerationHistory();
    });
