import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gravitymeet/main.dart';

void main() {
  testWidgets('Jeevan Arogya landing shows OTP login fields', (tester) async {
    await tester.pumpWidget(const JeevanArogyaApp());

    expect(
      find.text('Healthcare help,\nright when life\nneeds speed.'),
      findsOneWidget,
    );

    await tester.drag(find.byType(Scrollable).first, const Offset(0, -700));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Mobile OTP Login'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.text('Explore demo without login'), findsNothing);
    expect(find.text('Continue with Gmail'), findsNothing);
  });
}
