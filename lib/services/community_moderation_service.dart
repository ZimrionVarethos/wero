import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/errors/app_exceptions.dart';
import '../models/community_report.dart';
import '../models/moderation_action.dart';

/// Service managing community reports, moderation actions, and trust verification.
class CommunityModerationService {
  const CommunityModerationService(this._client);

  final SupabaseClient? _client;

  /// Check whether the specified user has moderator or admin privileges.
  Future<bool> checkIsModerator(String? userId) async {
    final client = _client;
    if (client == null || userId == null || userId.isEmpty) return false;
    try {
      final res = await client
          .from('user_roles')
          .select('role')
          .eq('user_id', userId);

      final roles = (res as List)
          .map((r) => r['role']?.toString().toUpperCase())
          .toSet();

      return roles.contains('COMMUNITY_MODERATOR') ||
          roles.contains('SUPER_ADMIN') ||
          roles.contains('GOVERNMENT_ADMIN');
    } catch (_) {
      return false;
    }
  }

  /// Fetch list of community reports pending moderation review.
  Future<List<CommunityReport>> fetchPendingReports() async {
    final client = _client;
    if (client == null) return _samplePendingReports;

    try {
      final res = await client
          .from('community_reports')
          .select(
            'id, post_id, reporter_id, reason_code, details, status, '
            'created_at, reviewed_at, reviewer_id, resolution, '
            'community_posts(title, body, profiles(display_name))',
          )
          .eq('status', 'PENDING')
          .order('created_at', ascending: false);

      final reports = (res as List)
          .map((r) => CommunityReport.fromJson(r as Map<String, dynamic>))
          .toList();

      return reports.isNotEmpty ? reports : _samplePendingReports;
    } catch (_) {
      return _samplePendingReports;
    }
  }

  /// Fetch audit log of recent community moderation actions.
  Future<List<ModerationAction>> fetchModerationHistory() async {
    final client = _client;
    if (client == null) return _sampleActions;

    try {
      final res = await client
          .from('community_moderation_actions')
          .select(
            'id, post_id, moderator_id, action, reason, created_at, '
            'community_posts(title), profiles(display_name)',
          )
          .order('created_at', ascending: false)
          .limit(30);

      final actions = (res as List)
          .map((a) => ModerationAction.fromJson(a as Map<String, dynamic>))
          .toList();

      return actions.isNotEmpty ? actions : _sampleActions;
    } catch (_) {
      return _sampleActions;
    }
  }

  /// Restore reported post back to PUBLISHED and dismiss the report.
  Future<void> approveAndRestorePost({
    required String postId,
    required String reportId,
    required String reason,
  }) async {
    final client = _client;
    final user = client?.auth.currentUser;
    if (client == null || user == null) {
      throw const AppAuthException('Anda harus masuk sebagai moderator.');
    }

    try {
      final now = DateTime.now().toIso8601String();

      // 1. Restore post
      await client
          .from('community_posts')
          .update({'status': 'PUBLISHED'})
          .eq('id', postId);

      // 2. Dismiss report
      await client
          .from('community_reports')
          .update({
            'status': 'DISMISSED',
            'resolution': reason.trim(),
            'reviewed_at': now,
            'reviewer_id': user.id,
          })
          .eq('id', reportId);

      // 3. Log moderation action
      await client.from('community_moderation_actions').insert({
        'post_id': postId,
        'moderator_id': user.id,
        'action': 'APPROVE_RESTORE',
        'reason': reason.trim(),
        'created_at': now,
      });
    } catch (e) {
      throw ServerException('Gagal memulihkan postingan: $e', e);
    }
  }

  /// Takedown reported post to REMOVED and mark report as reviewed.
  Future<void> takedownPost({
    required String postId,
    required String reportId,
    required String reason,
  }) async {
    final client = _client;
    final user = client?.auth.currentUser;
    if (client == null || user == null) {
      throw const AppAuthException('Anda harus masuk sebagai moderator.');
    }

    try {
      final now = DateTime.now().toIso8601String();

      // 1. Remove post
      await client
          .from('community_posts')
          .update({'status': 'REMOVED'})
          .eq('id', postId);

      // 2. Resolve report
      await client
          .from('community_reports')
          .update({
            'status': 'REVIEWED_ACTION',
            'resolution': reason.trim(),
            'reviewed_at': now,
            'reviewer_id': user.id,
          })
          .eq('id', reportId);

      // 3. Log moderation action
      await client.from('community_moderation_actions').insert({
        'post_id': postId,
        'moderator_id': user.id,
        'action': 'REMOVE_TAKEDOWN',
        'reason': reason.trim(),
        'created_at': now,
      });
    } catch (e) {
      throw ServerException('Gagal menghapus postingan: $e', e);
    }
  }

  // Fallback offline sample data
  static final _samplePendingReports = [
    CommunityReport(
      id: 'b1a2b3c4-0001-4000-8000-000000000001',
      postId: 'a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d',
      reporterId: 'demo-user-id',
      reasonCode: 'MISLEADING_DANGEROUS',
      details: 'Informasi berpotensi menimbulkan kepanikan masal tanpa konfirmasi BMKG.',
      status: 'PENDING',
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      postTitle: '[Diduga Hoaks] Ramalan Gempa Megathrust Besok Pagi',
      postBody: 'Waspada semuanya, beredar kabar berantai di grup WA bahwa besok pagi pukul 08:00 akan terjadi gempa 9.0 SR di pesisir selatan, segera tinggalkan rumah!',
      postAuthorName: 'Warga Siaga',
    ),
  ];

  static final _sampleActions = [
    ModerationAction(
      id: 'action-sample-1',
      postId: 'post-sample-prev',
      moderatorId: 'mod-1',
      action: 'APPROVE_RESTORE',
      reason: 'Konten terkonfirmasi merupakan laporan situasi riil lapangan dan bukan hoaks.',
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      postTitle: 'Laporan genangan air 30cm di Jl. Magelang KM 4',
      moderatorName: 'Moderator Jogja',
    ),
  ];
}
