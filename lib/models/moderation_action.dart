import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Domain model representing an audit log entry for a community moderation decision.
class ModerationAction {
  const ModerationAction({
    required this.id,
    required this.postId,
    required this.moderatorId,
    required this.action,
    required this.reason,
    required this.createdAt,
    this.postTitle,
    this.moderatorName,
  });

  final String id;
  final String postId;
  final String moderatorId;
  final String
  action; // 'APPROVE_RESTORE' | 'REMOVE_TAKEDOWN' | 'DISMISS_REPORTS'
  final String reason;
  final DateTime createdAt;
  final String? postTitle;
  final String? moderatorName;

  factory ModerationAction.fromJson(Map<String, dynamic> json) {
    String? pTitle;
    String? modName;

    if (json['community_posts'] is Map<String, dynamic>) {
      pTitle = json['community_posts']['title'] as String?;
    }
    if (json['profiles'] is Map<String, dynamic>) {
      modName = json['profiles']['display_name'] as String?;
    }

    return ModerationAction(
      id: json['id'] as String,
      postId: json['post_id'] as String,
      moderatorId: json['moderator_id'] as String,
      action: json['action'] as String? ?? 'APPROVE_RESTORE',
      reason: json['reason'] as String? ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      postTitle: pTitle ?? json['post_title'] as String?,
      moderatorName: modName ?? json['moderator_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'post_id': postId,
      'moderator_id': moderatorId,
      'action': action,
      'reason': reason,
      'created_at': createdAt.toIso8601String(),
    };
  }

  String get actionLabel {
    return switch (action) {
      'APPROVE_RESTORE' => 'Pulihkan Postingan',
      'REMOVE_TAKEDOWN' => 'Hapus / Takedown',
      'DISMISS_REPORTS' => 'Abaikan Laporan',
      _ => action,
    };
  }

  Color get actionColor {
    return switch (action) {
      'APPROVE_RESTORE' => AppColors.chartGreen,
      'REMOVE_TAKEDOWN' => AppColors.chartRed,
      'DISMISS_REPORTS' => AppColors.chartBlue,
      _ => AppColors.textSecondary,
    };
  }

  IconData get actionIcon {
    return switch (action) {
      'APPROVE_RESTORE' => Icons.check_circle_outline_rounded,
      'REMOVE_TAKEDOWN' => Icons.block_rounded,
      'DISMISS_REPORTS' => Icons.done_all_rounded,
      _ => Icons.shield_outlined,
    };
  }
}
