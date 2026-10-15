import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Domain model representing a user report against a community post.
class CommunityReport {
  const CommunityReport({
    required this.id,
    required this.postId,
    required this.reporterId,
    required this.reasonCode,
    this.details,
    this.status = 'PENDING',
    required this.createdAt,
    this.reviewedAt,
    this.reviewerId,
    this.resolution,
    this.postTitle,
    this.postBody,
    this.postAuthorName,
  });

  final String id;
  final String postId;
  final String reporterId;
  final String reasonCode;
  final String? details;
  final String status; // 'PENDING' | 'REVIEWED_ACTION' | 'DISMISSED'
  final DateTime createdAt;
  final DateTime? reviewedAt;
  final String? reviewerId;
  final String? resolution;

  // Optional joined post metadata for moderation display
  final String? postTitle;
  final String? postBody;
  final String? postAuthorName;

  factory CommunityReport.fromJson(Map<String, dynamic> json) {
    String? pTitle;
    String? pBody;
    String? pAuthor;

    if (json['community_posts'] is Map<String, dynamic>) {
      final postMap = json['community_posts'] as Map<String, dynamic>;
      pTitle = postMap['title'] as String?;
      pBody = postMap['body'] as String?;
      if (postMap['profiles'] is Map<String, dynamic>) {
        pAuthor = postMap['profiles']['display_name'] as String?;
      }
    }

    return CommunityReport(
      id: json['id'] as String,
      postId: json['post_id'] as String,
      reporterId: json['reporter_id'] as String,
      reasonCode: json['reason_code'] as String? ?? 'OTHER',
      details: json['details'] as String?,
      status: json['status'] as String? ?? 'PENDING',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      reviewedAt: json['reviewed_at'] != null
          ? DateTime.parse(json['reviewed_at'] as String)
          : null,
      reviewerId: json['reviewer_id'] as String?,
      resolution: json['resolution'] as String?,
      postTitle: pTitle ?? json['post_title'] as String?,
      postBody: pBody ?? json['post_body'] as String?,
      postAuthorName: pAuthor ?? json['post_author_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'post_id': postId,
      'reporter_id': reporterId,
      'reason_code': reasonCode,
      'details': details,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      if (reviewedAt != null) 'reviewed_at': reviewedAt!.toIso8601String(),
      if (reviewerId != null) 'reviewer_id': reviewerId,
      if (resolution != null) 'resolution': resolution,
    };
  }

  String get reasonLabel {
    return switch (reasonCode) {
      'MISLEADING_DANGEROUS' => 'Hoaks & Berbahaya',
      'SPAM' => 'Spam / Iklan Tak Relevan',
      'HARASSMENT' => 'Pelecehan / Ujaran Kebencian',
      'PRIVACY' => 'Pelanggaran Privasi',
      'IRRELEVANT' => 'Tidak Relevan',
      _ => 'Lainnya',
    };
  }

  String get statusLabel {
    return switch (status) {
      'PENDING' => 'Menunggu Tinjauan',
      'REVIEWED_ACTION' => 'Ditindaklanjuti',
      'DISMISSED' => 'Diabaikan / Valid',
      _ => status,
    };
  }

  Color get statusColor {
    return switch (status) {
      'PENDING' => AppColors.accentOrange,
      'REVIEWED_ACTION' => AppColors.chartRed,
      'DISMISSED' => AppColors.chartGreen,
      _ => AppColors.textSecondary,
    };
  }
}
