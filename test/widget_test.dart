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
      expect(
        isLikelyFemaleDoctorName('Dr. Manish Jain', speciality: 'Gynecologist'),
        isFalse,
      );
      expect(
        isLikelyFemaleDoctorName('Dr. Pooja Jain', speciality: 'Gynecologist'),
        isTrue,
      );
      expect(
        isLikelyFemaleDoctorName('Dr. K K Shah', speciality: 'Gynecologist'),
        isFalse,
      );
      expect(isLikelyFemaleDoctorName('Dr. Rohit Verma'), isFalse);
      expect(isLikelyFemaleDoctorName('Dr. Ravi Gupta'), isFalse);
    },
  );

  test('gynecologist specialty filter handles common spelling variants', () {
    const doctor = Doctor(
      name: 'Dr. Pooja Jain',
      specialty: 'Gynaecology and Obstetrics',
      experience: '10 years',
      degree: 'MBBS, MS',
      fee: 'Call',
      rating: '4.8',
      reviews: '120',
      nextSlot: 'Today',
      color: Colors.white,
    );

    expect(doctorMatchesSpecialty(doctor, 'Gynecologist'), isTrue);
  });

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
