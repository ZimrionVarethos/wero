import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wero/app.dart';

void main() {
  testWidgets(
    'Wero app renders login screen for unauthenticated users on first launch',
    (tester) async {
      await tester.pumpWidget(const ProviderScope(child: WeroApp()));
      await tester.pumpAndSettle();

      // Unauthenticated users are strictly guarded and redirected to LoginScreen
      expect(find.text('Masuk ke Wero'), findsOneWidget);
    },
  );
}
