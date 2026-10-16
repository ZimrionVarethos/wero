import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wero/widgets/contour_wave_background.dart';

void main() {
  testWidgets('ContourWaveBackground renders all variants without error', (
    tester,
  ) async {
    for (final variant in ContourVariant.values) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 800,
              child: ContourWaveBackground(variant: variant),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(ContourWaveBackground), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    }
  });
}
