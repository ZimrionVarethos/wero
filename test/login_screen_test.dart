import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wero/screens/auth/login_screen.dart';
import 'package:wero/screens/auth/widgets/login_form_card.dart';
import 'package:wero/widgets/app_logo.dart';

void main() {
  testWidgets(
    'LoginScreen renders brand logo, ornament background, and form card',
    (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: LoginScreen())),
      );
      await tester.pump();

      // Verify ornament image asset is loaded as background
      final imageFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                'assets/images/ornamen.png',
      );
      expect(imageFinder, findsOneWidget);

      // Verify brand logo widget is displayed above form
      expect(find.byType(AppLogo), findsOneWidget);

      // Verify authentication form card is displayed
      expect(find.byType(LoginFormCard), findsOneWidget);
      expect(find.text('Masuk ke Siagaku'), findsOneWidget);
      expect(find.text('Masuk Cepat (Akun Demo)'), findsOneWidget);
    },
  );

  testWidgets('LoginFormCard toggles between sign in and sign up states', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: Scaffold(body: LoginFormCard())),
      ),
    );
    await tester.pump();

    expect(find.text('Masuk ke Siagaku'), findsOneWidget);
    expect(find.text('Belum punya akun? Daftar sekarang'), findsOneWidget);

    // Tap toggle button to switch to Sign Up
    await tester.tap(find.text('Belum punya akun? Daftar sekarang'));
    await tester.pump();

    expect(find.text('Daftar Akun Baru'), findsOneWidget);
    expect(find.text('Nama Lengkap'), findsOneWidget);
    expect(find.text('Daftar Sekarang'), findsOneWidget);
    expect(find.text('Sudah punya akun? Masuk'), findsOneWidget);
  });
}
