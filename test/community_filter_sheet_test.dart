import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wero/screens/community/community_feed_screen.dart';
import 'package:wero/screens/community/widgets/community_filter_sheet.dart';
import 'package:wero/widgets/app_header.dart';

void main() {
  testWidgets('CommunityFeedScreen renders AppHeader with 4 action icons', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: CommunityFeedScreen())),
    );
    await tester.pump();

    // Verify AppHeader is rendered
    expect(find.byType(AppHeader), findsOneWidget);

    // Verify filter action button exists
    expect(find.byIcon(Icons.tune_rounded), findsOneWidget);

    // Verify 3 default icons exist
    expect(find.byIcon(Icons.history_rounded), findsOneWidget);
    expect(find.byIcon(Icons.map_outlined), findsOneWidget);
    expect(find.byIcon(Icons.notifications_rounded), findsOneWidget);

    // Total 4 action icons on header
    expect(find.byType(IconButton), findsAtLeastNWidgets(4));
  });

  testWidgets('Tapping filter button opens CommunityFilterSheet', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: CommunityFeedScreen())),
    );
    await tester.pump();

    // Tap filter button
    await tester.tap(find.byIcon(Icons.tune_rounded));
    await tester.pumpAndSettle();

    // Verify bottom sheet is displayed
    expect(find.byType(CommunityFilterSheet), findsOneWidget);
    expect(find.text('Filter Berita Komunitas'), findsOneWidget);
    expect(find.text('Cakupan Berita'), findsOneWidget);
    expect(find.text('Lokal'), findsOneWidget);
    expect(find.text('Nasional'), findsOneWidget);
    expect(find.text('Terapkan Filter'), findsOneWidget);
  });
}
