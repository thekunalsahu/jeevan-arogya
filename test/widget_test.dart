import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gravitymeet/main.dart';

void main() {
  test(
    'doctor gender image detection handles common names and specialties',
    () {
      expect(isLikelyFemaleDoctorName('Dr. Nidhi Jain'), isTrue);
      expect(isLikelyFemaleDoctorName('Dr. Seema Sharma'), isTrue);
      expect(
        isLikelyFemaleDoctorName('City Care', speciality: 'Gynaecologist'),
        isTrue,
      );
      expect(isLikelyFemaleDoctorName('Dr. Rohit Verma'), isFalse);
      expect(isLikelyFemaleDoctorName('Dr. Ravi Gupta'), isFalse);
    },
  );

  testWidgets('Jeevan Arogya landing shows OTP login fields', (tester) async {
    await tester.pumpWidget(const JeevanArogyaApp());

    expect(
      find.text('Healthcare help,\nright when life\nneeds speed.'),
      findsOneWidget,
    );

    await tester.drag(find.byType(Scrollable).first, const Offset(0, -700));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Email OTP Login'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.text('Explore demo without login'), findsNothing);
    expect(find.text('Continue with Gmail'), findsNothing);
  });
}
