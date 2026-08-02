import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tmillz/presentation/widgets/app_brand_title.dart';
import 'package:tmillz/presentation/widgets/footer_widget.dart';

void main() {
  testWidgets('AppBrandTitle renders title', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: AppBrandTitle(title: 'Brand')),
      ),
    );

    expect(find.text('Brand'), findsOneWidget);
  });

  testWidgets('FooterWidget shows policy links', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: FooterWidget())),
    );

    expect(find.text('Privacy Policy'), findsOneWidget);
    expect(find.text('Terms of Service'), findsOneWidget);
  });
}
