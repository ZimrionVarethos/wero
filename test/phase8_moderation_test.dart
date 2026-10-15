import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wero/models/community_post.dart';
import 'package:wero/models/community_report.dart';
import 'package:wero/models/moderation_action.dart';
import 'package:wero/screens/moderation/widgets/moderation_action_dialog.dart';
import 'package:wero/screens/moderation/widgets/moderation_history_tile.dart';
import 'package:wero/screens/moderation/widgets/reported_post_card.dart';

void main() {
  group('Phase 8 CommunityReport Model Tests', () {
    test('fromJson and toJson serializes correctly with joined post data', () {
      final json = {
        'id': 'rep-1',
        'post_id': 'post-1',
        'reporter_id': 'user-1',
        'reason_code': 'MISLEADING_DANGEROUS',
        'details': 'Informasi tidak akurat mengenai gempa',
        'status': 'PENDING',
        'created_at': '2026-10-15T09:00:00Z',
        'community_posts': {
          'title': 'Ramalan Gempa Besok',
          'body': 'Akan terjadi gempa besar besok pagi',
          'profiles': {'display_name': 'Warga A'},
        },
      };

      final report = CommunityReport.fromJson(json);
      expect(report.id, 'rep-1');
      expect(report.postId, 'post-1');
      expect(report.reasonCode, 'MISLEADING_DANGEROUS');
      expect(report.reasonLabel, 'Hoaks & Berbahaya');
      expect(report.details, 'Informasi tidak akurat mengenai gempa');
      expect(report.status, 'PENDING');
      expect(report.statusLabel, 'Menunggu Tinjauan');
      expect(report.postTitle, 'Ramalan Gempa Besok');
      expect(report.postAuthorName, 'Warga A');

      final serialized = report.toJson();
      expect(serialized['id'], 'rep-1');
      expect(serialized['reason_code'], 'MISLEADING_DANGEROUS');
      expect(serialized['status'], 'PENDING');
    });

    test('reasonLabel and statusLabel maps all codes appropriately', () {
      final r1 = CommunityReport(
        id: '1',
        postId: 'p1',
        reporterId: 'u1',
        reasonCode: 'SPAM',
        status: 'REVIEWED_ACTION',
        createdAt: DateTime.now(),
      );
      final r2 = CommunityReport(
        id: '2',
        postId: 'p2',
        reporterId: 'u2',
        reasonCode: 'HARASSMENT',
        status: 'DISMISSED',
        createdAt: DateTime.now(),
      );

      expect(r1.reasonLabel, 'Spam / Iklan Tak Relevan');
      expect(r1.statusLabel, 'Ditindaklanjuti');
      expect(r2.reasonLabel, 'Pelecehan / Ujaran Kebencian');
      expect(r2.statusLabel, 'Diabaikan / Valid');
    });
  });

  group('Phase 8 ModerationAction Model Tests', () {
    test('fromJson and toJson serializes decision history', () {
      final json = {
        'id': 'action-1',
        'post_id': 'post-1',
        'moderator_id': 'mod-1',
        'action': 'APPROVE_RESTORE',
        'reason': 'Informasi terverifikasi oleh posko BPBD',
        'created_at': '2026-10-15T09:30:00Z',
        'community_posts': {'title': 'Peringatan Banjir'},
        'profiles': {'display_name': 'Admin Mod'},
      };

      final action = ModerationAction.fromJson(json);
      expect(action.id, 'action-1');
      expect(action.action, 'APPROVE_RESTORE');
      expect(action.actionLabel, 'Pulihkan Postingan');
      expect(action.reason, 'Informasi terverifikasi oleh posko BPBD');
      expect(action.postTitle, 'Peringatan Banjir');
      expect(action.moderatorName, 'Admin Mod');

      final serialized = action.toJson();
      expect(serialized['id'], 'action-1');
      expect(serialized['action'], 'APPROVE_RESTORE');
    });
  });

  group('Phase 8 CommunityPost Status Helpers Tests', () {
    test('isPendingReview, isRemoved, isPublished helper getters work', () {
      final p1 = CommunityPost(
        id: 'p1',
        authorId: 'a1',
        authorName: 'User',
        body: 'Post content',
        categoryId: 'c1',
        scope: 'LOCAL',
        status: 'HIDDEN_PENDING_REVIEW',
        createdAt: DateTime.now(),
      );

      final p2 = CommunityPost(
        id: 'p2',
        authorId: 'a1',
        authorName: 'User',
        body: 'Post content',
        categoryId: 'c1',
        scope: 'NATIONAL',
        status: 'REMOVED',
        createdAt: DateTime.now(),
      );

      final p3 = CommunityPost(
        id: 'p3',
        authorId: 'a1',
        authorName: 'User',
        body: 'Post content',
        categoryId: 'c1',
        scope: 'LOCAL',
        status: 'PUBLISHED',
        createdAt: DateTime.now(),
      );

      expect(p1.isPendingReview, isTrue);
      expect(p1.isPublished, isFalse);
      expect(p2.isRemoved, isTrue);
      expect(p3.isPublished, isTrue);
    });
  });

  group('Phase 8 Moderation Widgets Tests', () {
    testWidgets(
      'ReportedPostCard renders report details and triggers actions',
      (tester) async {
        final report = CommunityReport(
          id: 'rep-test',
          postId: 'post-test',
          reporterId: 'u-reporter',
          reasonCode: 'MISLEADING_DANGEROUS',
          details: 'Klaim ramalan tanpa dasar ilmiah',
          status: 'PENDING',
          createdAt: DateTime.now(),
          postTitle: 'Ramalan Megathrust Besok',
          postBody: 'Akan terjadi gempa besar 9.0 SR',
          postAuthorName: 'Akun Pengguna',
        );

        var approved = false;
        var takedown = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ReportedPostCard(
                report: report,
                onApprove: () => approved = true,
                onTakedown: () => takedown = true,
              ),
            ),
          ),
        );

        expect(find.text('Hoaks & Berbahaya'), findsOneWidget);
        expect(find.text('Ramalan Megathrust Besok'), findsOneWidget);
        expect(
          find.textContaining('Klaim ramalan tanpa dasar'),
          findsOneWidget,
        );
        expect(find.text('Penulis: Akun Pengguna'), findsOneWidget);

        expect(find.text('Pulihkan'), findsOneWidget);
        expect(find.text('Takedown'), findsOneWidget);

        await tester.tap(find.text('Pulihkan'));
        await tester.pump();
        expect(approved, isTrue);

        await tester.tap(find.text('Takedown'));
        await tester.pump();
        expect(takedown, isTrue);
      },
    );

    testWidgets('ModerationHistoryTile renders audit trail entry', (
      tester,
    ) async {
      final action = ModerationAction(
        id: 'act-test',
        postId: 'post-test',
        moderatorId: 'mod-1',
        action: 'APPROVE_RESTORE',
        reason: 'Postingan valid dan penting untuk warga',
        createdAt: DateTime.now(),
        postTitle: 'Kondisi Sungai Citarum Meluap',
        moderatorName: 'Relawan Bandung',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ModerationHistoryTile(action: action)),
        ),
      );

      expect(find.text('Pulihkan Postingan'), findsOneWidget);
      expect(
        find.text('Target: Kondisi Sungai Citarum Meluap'),
        findsOneWidget,
      );
      expect(
        find.text('Catatan: "Postingan valid dan penting untuk warga"'),
        findsOneWidget,
      );
      expect(find.text('Oleh: Relawan Bandung'), findsOneWidget);
    });

    testWidgets('ModerationActionDialog validates non-empty reason input', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ModerationActionDialog(
              isApprove: true,
              postTitle: 'Judul Target',
            ),
          ),
        ),
      );

      expect(find.text('Pulihkan Postingan'), findsOneWidget);
      expect(find.text('Target: "Judul Target"'), findsOneWidget);

      // Button is initially disabled
      final buttonFinder = find.widgetWithText(ElevatedButton, 'Pulihkan');
      expect(tester.widget<ElevatedButton>(buttonFinder).enabled, isFalse);

      // Enter reason text
      await tester.enterText(
        find.byType(TextField),
        'Informasi telah dikonfirmasi BPBD',
      );
      await tester.pump();

      // Button should now be enabled
      expect(tester.widget<ElevatedButton>(buttonFinder).enabled, isTrue);
    });
  });
}
