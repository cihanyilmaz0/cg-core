import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saas_isletme/core/widgets/app_button.dart';

void main() {
  testWidgets('AppButton renders text and responds to tap', (WidgetTester tester) async {
    bool tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppButton(
            text: 'Giriş Yap',
            onPressed: () {
              tapped = true;
            },
          ),
        ),
      ),
    );

    expect(find.text('Giriş Yap'), findsOneWidget);
    await tester.tap(find.byType(AppButton));
    await tester.pump();

    expect(tapped, isTrue);
  });
}
