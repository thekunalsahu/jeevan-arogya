import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gravitymeet/main.dart';

void main() {
  testWidgets('Jeevan Arogya landing opens the live home screen', (
    tester,
  ) async {
    await tester.pumpWidget(const JeevanArogyaApp());

    expect(
      find.text('Healthcare help,\nright when life\nneeds speed.'),
      findsOneWidget,
    );

    await tester.drag(find.byType(Scrollable).first, const Offset(0, -700));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Mobile OTP Login'), findsOneWidget);

    await tester.ensureVisible(find.text('Explore demo without login'));
    await tester.tap(find.text('Explore demo without login'));
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.text('How can we help\nyou today?'), findsOneWidget);
    expect(find.text('Tap SOS for\nimmediate help'), findsOneWidget);
  });
}
