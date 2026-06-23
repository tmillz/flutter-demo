import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_demo/presentation/widgets/app_brand_title.dart';
import 'package:flutter_demo/presentation/widgets/footer_widget.dart';

void main() {
  testWidgets('AppBrandTitle renders title and subtitle', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppBrandTitle(title: 'Tmillz', subtitle: 'ideas in motion'),
        ),
      ),
    );

    expect(find.text('Tmillz'), findsOneWidget);
    expect(find.text('ideas in motion'), findsOneWidget);
  });

  testWidgets('FooterWidget shows policy links', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: FooterWidget())),
    );

    expect(find.text('Privacy Policy'), findsOneWidget);
    expect(find.text('Terms of Service'), findsOneWidget);
  });
}
