import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wero/models/community_category.dart';
import 'package:wero/models/community_post.dart';
import 'package:wero/screens/activity/widgets/local_community_section.dart';
import 'package:wero/screens/community/widgets/category_filter_bar.dart';
import 'package:wero/screens/community/widgets/post_card.dart';
import 'package:wero/screens/community/widgets/scope_selector.dart';

void main() {
  group('Community Widgets Tests', () {
    testWidgets('ScopeSelector switches between Local and National', (
      tester,
    ) async {
      String current = 'LOCAL';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return ScopeSelector(
                  currentScope: current,
                  onScopeChanged: (val) => setState(() => current = val),
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Lokal'), findsOneWidget);
      expect(find.text('Nasional'), findsOneWidget);

      await tester.tap(find.text('Nasional'));
      await tester.pumpAndSettle();
      expect(current, 'NATIONAL');

      await tester.tap(find.text('Lokal'));
      await tester.pumpAndSettle();
      expect(current, 'LOCAL');
    });

    testWidgets('CategoryFilterBar renders chips and responds to clicks', (
      tester,
    ) async {
      String? selected;
      final categories = [
        const CommunityCategory(id: 'c1', slug: 'edu', name: 'Edukasi'),
        const CommunityCategory(id: 'c2', slug: 'tips', name: 'Tips Siaga'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return CategoryFilterBar(
                  categories: categories,
                  selectedCategoryId: selected,
                  onSelectCategory: (id) => setState(() => selected = id),
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Semua'), findsOneWidget);
      expect(find.text('Edukasi'), findsOneWidget);
      expect(find.text('Tips Siaga'), findsOneWidget);

      await tester.tap(find.text('Edukasi'));
      await tester.pumpAndSettle();
      expect(selected, 'c1');
    });

    testWidgets(
      'PostCard renders post details and Tersimpan badge when cached',
      (tester) async {
        bool tapped = false;
        final post = CommunityPost(
          id: 'p-1',
          authorId: 'u-1',
          authorName: 'Siti Rahma',
          title: 'Jalur Evakuasi Banjir',
          body: 'Berikut rute aman menuju titik kumpul dataran tinggi.',
          categoryId: 'c-1',
          categoryName: 'Informasi Wilayah',
          scope: 'LOCAL',
          regionName: 'Kab. Bandung',
          status: 'PUBLISHED',
          createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
          isCached: true,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PostCard(post: post, onTap: () => tapped = true),
            ),
          ),
        );

        expect(find.text('Siti Rahma'), findsNothing);
        expect(find.text('Tersimpan'), findsOneWidget);
        expect(find.text('Informasi Wilayah'), findsOneWidget);

        await tester.tap(find.text('Informasi Wilayah'));
        expect(tapped, isTrue);
      },
    );

    testWidgets(
      'LocalCommunitySection renders city title, postcards, and view all button',
      (tester) async {
        final posts = List.generate(
          3,
          (i) => CommunityPost(
            id: 'p-$i',
            authorId: 'u-1',
            authorName: 'Relawan Jogja',
            body: 'Warta posko siaga ke-$i',
            categoryId: 'c-1',
            categoryName: 'Informasi Wilayah',
            scope: 'LOCAL',
            regionName: 'Kota Yogyakarta',
            status: 'PUBLISHED',
            createdAt: DateTime.now().subtract(Duration(minutes: 10 * (i + 1))),
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: LocalCommunitySection(
                  cityName: 'Kota Yogyakarta',
                  postsAsync: AsyncValue.data(posts),
                ),
              ),
            ),
          ),
        );

        expect(
          find.text('Liat Keadaan Kota Yogyakarta Komunitas'),
          findsOneWidget,
        );
        expect(find.byType(PostCard), findsNWidgets(3));
        expect(find.text('Lihat Semua'), findsOneWidget);
      },
    );
  });
}
