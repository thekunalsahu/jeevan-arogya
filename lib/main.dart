import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter_map/flutter_map.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import 'supabase_config.dart';
import 'supabase_models.dart';
import 'supabase_service.dart';

final appLocation = AppLocationController();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.initialize();
  runApp(const JeevanArogyaApp());
}

class JeevanArogyaApp extends StatelessWidget {
  const JeevanArogyaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Jeevan Arogya',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColors.bg,
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.navy,
          brightness: Brightness.light,
          primary: AppColors.navy,
          surface: Colors.white,
        ),
      ),
      builder: (context, child) => ColoredBox(
        color: const Color(0xFFEFF4FA),
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth >= 800) {
              return child ?? const SizedBox.shrink();
            }
            final width = constraints.maxWidth < 430
                ? constraints.maxWidth
                : 430.0;
            return Center(
              child: SizedBox(
                width: width,
                height: constraints.maxHeight,
                child: child ?? const SizedBox.shrink(),
              ),
            );
          },
        ),
      ),
      home: const AuthGate(),
    );
  }
}

class AppColors {
  static const bg = Color(0xFFF7FAFE);
  static const navy = Color(0xFF062A55);
  static const navy2 = Color(0xFF0A3A72);
  static const red = Color(0xFFF22635);
  static const red2 = Color(0xFFFF5B62);
  static const green = Color(0xFF079C66);
  static const blue = Color(0xFF2474D8);
  static const gold = Color(0xFFF7A700);
  static const text = Color(0xFF111827);
  static const muted = Color(0xFF748092);
  static const line = Color(0xFFE8EDF4);
  static const soft = Color(0xFFF0F4F9);
}

const doctors = [
  Doctor(
    name: 'Dr. Ananya Sharma',
    specialty: 'Cardiologist',
    experience: '10+ Years Exp.',
    degree: 'MBBS, MD',
    fee: 'Rs. 800',
    rating: '4.8',
    reviews: '128',
    nextSlot: 'Today, 11:30 AM',
    color: Color(0xFFE9F0F8),
  ),
  Doctor(
    name: 'Dr. Rohit Verma',
    specialty: 'Orthopedic',
    experience: '8+ Years Exp.',
    degree: 'MBBS, MS',
    fee: 'Rs. 600',
    rating: '4.6',
    reviews: '96',
    nextSlot: 'Today, 02:00 PM',
    color: Color(0xFFE7F4FF),
  ),
  Doctor(
    name: 'Dr. Neha Patel',
    specialty: 'Pediatrician',
    experience: '7+ Years Exp.',
    degree: 'MBBS, DCH',
    fee: 'Rs. 500',
    rating: '4.7',
    reviews: '74',
    nextSlot: 'Tomorrow, 10:00 AM',
    color: Color(0xFFFFEFF2),
  ),
  Doctor(
    name: 'Dr. Karan Mehta',
    specialty: 'Dermatologist',
    experience: '9+ Years Exp.',
    degree: 'MBBS, DDV',
    fee: 'Rs. 700',
    rating: '4.5',
    reviews: '68',
    nextSlot: 'Today, 04:30 PM',
    color: Color(0xFFFFF1DF),
  ),
];

const hospitals = [
  Hospital(
    'Apollo Hospitals',
    '2.4 km away',
    '24x7 Open',
    latitude: 22.7533,
    longitude: 75.8922,
    phone: '+917314738888',
  ),
  Hospital(
    'Choithram Hospital',
    '3.1 km away',
    '24x7 Open',
    latitude: 22.6893,
    longitude: 75.8425,
    phone: '+917312365001',
  ),
  Hospital(
    'Bombay Hospital',
    '4.2 km away',
    '24x7 Open',
    latitude: 22.7564,
    longitude: 75.9049,
    phone: '+917314777700',
  ),
  Hospital(
    'Shalby Hospital',
    '4.8 km away',
    '24x7 Open',
    latitude: 22.7679,
    longitude: 75.8817,
    phone: '+917314711111',
  ),
];

const kendras = [
  Place(
    'Jan Aushadhi Kendra',
    '1.2 km away',
    'Malviya Nagar',
    latitude: 22.7448,
    longitude: 75.8928,
    phone: '+917310001201',
  ),
  Place(
    'Jan Aushadhi Kendra',
    '2.7 km away',
    'Vijay Nagar',
    latitude: 22.7539,
    longitude: 75.8953,
    phone: '+917310001202',
  ),
  Place(
    'Jan Aushadhi Kendra',
    '3.4 km away',
    'Bhawarkuan',
    latitude: 22.6928,
    longitude: 75.8670,
    phone: '+917310001203',
  ),
  Place(
    'Jan Aushadhi Kendra',
    '4.1 km away',
    'Palasia',
    latitude: 22.7244,
    longitude: 75.8839,
    phone: '+917310001204',
  ),
];

class Doctor {
  const Doctor({
    this.id = '',
    required this.name,
    required this.specialty,
    required this.experience,
    required this.degree,
    required this.fee,
    required this.rating,
    required this.reviews,
    required this.nextSlot,
    required this.color,
  });

  final String id;
  final String name;
  final String specialty;
  final String experience;
  final String degree;
  final String fee;
  final String rating;
  final String reviews;
  final String nextSlot;
  final Color color;
}

Doctor doctorFromDb(DbDoctor doctor) {
  return Doctor(
    id: doctor.id,
    name: doctor.name,
    specialty: doctor.specialty,
    experience: '${doctor.experienceYears}+ Years Exp.',
    degree: doctor.degree,
    fee: 'Rs. ${doctor.fee}',
    rating: doctor.rating.toStringAsFixed(1),
    reviews: doctor.reviews.toString(),
    nextSlot: doctor.nextSlot,
    color: doctor.isOnline ? const Color(0xFFE7F4FF) : const Color(0xFFFFF1DF),
  );
}

class Hospital {
  const Hospital(
    this.name,
    this.distance,
    this.status, {
    required this.latitude,
    required this.longitude,
    required this.phone,
  });

  final String name;
  final String distance;
  final String status;
  final double latitude;
  final double longitude;
  final String phone;

  LatLng get latLng => LatLng(latitude, longitude);

  String distanceFrom(LatLng userLocation) =>
      formatDistanceKm(distanceKm(userLocation, latLng));
}

class Place {
  const Place(
    this.name,
    this.distance,
    this.area, {
    required this.latitude,
    required this.longitude,
    required this.phone,
  });

  final String name;
  final String distance;
  final String area;
  final double latitude;
  final double longitude;
  final String phone;

  LatLng get latLng => LatLng(latitude, longitude);

  String distanceFrom(LatLng userLocation) =>
      formatDistanceKm(distanceKm(userLocation, latLng));
}

class AppLocationController extends ChangeNotifier {
  LatLng _current = const LatLng(22.7196, 75.8577);
  String _label = 'Indore, Madhya Pradesh';
  String? _message;
  bool _loading = false;
  bool _resolved = false;

  LatLng get current => _current;
  String get label => _label;
  String? get message => _message;
  bool get loading => _loading;
  bool get resolved => _resolved;

  Future<void> requestCurrentLocation() async {
    _loading = true;
    _message = null;
    notifyListeners();

    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        _message = 'Location service off hai. Device/browser location on karo.';
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _message =
            'Location permission deny hai. Browser permission allow karo.';
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );
      _current = LatLng(position.latitude, position.longitude);
      _resolved = true;
      _label =
          '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
      _message = 'Live location updated';
    } catch (error) {
      _message = 'Location unavailable: $error';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}

double distanceKm(LatLng a, LatLng b) {
  const earthKm = 6371.0;
  final dLat = _degToRad(b.latitude - a.latitude);
  final dLng = _degToRad(b.longitude - a.longitude);
  final lat1 = _degToRad(a.latitude);
  final lat2 = _degToRad(b.latitude);
  final h =
      math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(lat1) * math.cos(lat2) * math.sin(dLng / 2) * math.sin(dLng / 2);
  return earthKm * 2 * math.atan2(math.sqrt(h), math.sqrt(1 - h));
}

double _degToRad(double degree) => degree * math.pi / 180;

String formatDistanceKm(double km) {
  if (km < 1) {
    return '${(km * 1000).round()} m away';
  }
  return '${km.toStringAsFixed(1)} km away';
}

String friendlyAuthError(Object error) {
  final text = error.toString().replaceFirst('AuthException(message: ', '');
  if (text.toLowerCase().contains('sms') ||
      text.toLowerCase().contains('twilio')) {
    return '$text Check Supabase Auth > Phone provider/Twilio settings.';
  }
  return text;
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final JeevanArogyaRepository _repository = JeevanArogyaRepository();
  StreamSubscription? _authSubscription;
  late bool _loggedIn = _repository.currentUser != null;

  @override
  void initState() {
    super.initState();
    _authSubscription = _repository.authStateChanges.listen((state) {
      if (!mounted) {
        return;
      }
      setState(() => _loggedIn = state.session != null);
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  void _enterDemo() {
    setState(() => _loggedIn = true);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 520),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: _loggedIn
          ? const AppShell(key: ValueKey('app-shell'))
          : LandingScreen(
              key: const ValueKey('landing-screen'),
              repository: _repository,
              onLogin: _enterDemo,
            ),
    );
  }
}

class LandingScreen extends StatefulWidget {
  const LandingScreen({
    super.key,
    required this.repository,
    required this.onLogin,
  });

  final JeevanArogyaRepository repository;
  final VoidCallback onLogin;

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  var _otpSent = false;
  var _otp = '4  8  2  1';
  var _authBusy = false;
  String? _authMessage;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty || phone.replaceAll(RegExp(r'\D'), '').length < 10) {
      setState(() {
        _authMessage = 'Please enter a valid mobile number.';
      });
      return;
    }

    setState(() {
      _authBusy = true;
      _authMessage = null;
    });

    try {
      if (widget.repository.isConnected) {
        final normalizedPhone = await widget.repository.sendPhoneOtp(phone);
        setState(() {
          _otpSent = true;
          _authMessage = 'OTP sent to $normalizedPhone. Enter the SMS code.';
          _otp = '';
          _otpController.clear();
        });
      } else {
        setState(() {
          _otpSent = true;
          _otp = '4  8  2  1';
          _otpController.text = '4821';
          _authMessage = 'Demo mode: add Supabase keys in .env for real OTP.';
        });
      }
    } catch (error) {
      setState(() {
        _authMessage = 'OTP send failed: ${friendlyAuthError(error)}';
      });
    } finally {
      if (mounted) {
        setState(() => _authBusy = false);
      }
    }
  }

  Future<void> _verifyOtpOrEnter() async {
    setState(() {
      _authBusy = true;
      _authMessage = null;
    });

    try {
      if (widget.repository.isConnected && _otpSent) {
        final token = _otpController.text.replaceAll(RegExp(r'\s+'), '');
        if (token.length < 4) {
          setState(() {
            _authMessage = 'Please enter the SMS OTP.';
          });
          return;
        }

        await widget.repository.verifyPhoneOtp(
          phone: _phoneController.text,
          token: token,
        );
        try {
          await widget.repository.upsertProfile(
            fullName: 'Priya Sharma',
            phone: _phoneController.text,
            email: 'priya.sharma@email.com',
          );
        } catch (_) {
          // Auth succeeded; profile sync can be retried after database setup.
        }
        widget.onLogin();
      } else {
        final token = _otpController.text.replaceAll(RegExp(r'\s+'), '');
        if (!_otpSent || token == '4821') {
          widget.onLogin();
        } else {
          setState(() {
            _authMessage = 'Use demo OTP 4821 in demo mode.';
          });
        }
      }
    } catch (error) {
      setState(() {
        _authMessage = 'OTP verify failed: ${friendlyAuthError(error)}';
      });
    } finally {
      if (mounted) {
        setState(() => _authBusy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppPage(
        child: Stack(
          children: [
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return CustomPaint(
                  painter: LandingBackdropPainter(_controller.value),
                  child: const SizedBox.expand(),
                );
              },
            ),
            SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
                children: [
                  const LandingTopBar(),
                  const SizedBox(height: 26),
                  const LandingHero(),
                  const SizedBox(height: 24),
                  LoginPanel(
                    phoneController: _phoneController,
                    otpController: _otpController,
                    otpSent: _otpSent,
                    otp: _otp,
                    busy: _authBusy,
                    message: _authMessage,
                    connected: widget.repository.isConnected,
                    animation: _controller,
                    onSendOtp: _sendOtp,
                    onLogin: _verifyOtpOrEnter,
                    onDemoLogin: widget.onLogin,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LandingBackdropPainter extends CustomPainter {
  const LandingBackdropPainter(this.t);

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final topPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFE4F0FF), Color(0xFFFFEEF1), Color(0xFFEAFBF3)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, topPaint);

    void bubble(Offset center, double radius, Color color) {
      final paint = Paint()
        ..color = color
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 32);
      canvas.drawCircle(center, radius, paint);
    }

    bubble(
      Offset(size.width * (.18 + t * .08), size.height * .14),
      72,
      AppColors.blue.withValues(alpha: .20),
    );
    bubble(
      Offset(size.width * (.86 - t * .05), size.height * .20),
      88,
      AppColors.red.withValues(alpha: .16),
    );
    bubble(
      Offset(size.width * (.72 + t * .04), size.height * .62),
      120,
      AppColors.green.withValues(alpha: .14),
    );
  }

  @override
  bool shouldRepaint(covariant LandingBackdropPainter oldDelegate) {
    return oldDelegate.t != t;
  }
}

class LandingTopBar extends StatelessWidget {
  const LandingTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(children: [const LogoMark(width: 148, height: 56)]);
  }
}

class LandingHero extends StatelessWidget {
  const LandingHero({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Color(0xFFF4FAFF)],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: .10),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF8EF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.sensors_rounded,
                      color: AppColors.green,
                      size: 16,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Live emergency network',
                      style: TextStyle(
                        color: AppColors.green,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              const Icon(Icons.auto_awesome_rounded, color: AppColors.gold),
            ],
          ),
          const SizedBox(height: 22),
          const Text(
            'Healthcare help,\nright when life\nneeds speed.',
            style: TextStyle(
              color: AppColors.text,
              fontSize: 34,
              height: 1.02,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Find doctors, book appointments, trigger SOS alerts, request emergency cabs, and locate affordable medicines from one smart app.',
            style: TextStyle(
              color: AppColors.muted,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class LoginPanel extends StatelessWidget {
  const LoginPanel({
    super.key,
    required this.phoneController,
    required this.otpController,
    required this.otpSent,
    required this.otp,
    required this.busy,
    required this.connected,
    required this.animation,
    required this.onSendOtp,
    required this.onLogin,
    required this.onDemoLogin,
    this.message,
  });

  final TextEditingController phoneController;
  final TextEditingController otpController;
  final bool otpSent;
  final String otp;
  final bool busy;
  final bool connected;
  final Animation<double> animation;
  final String? message;
  final VoidCallback onSendOtp;
  final VoidCallback onLogin;
  final VoidCallback onDemoLogin;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: .98),
            const Color(0xFFF8FBFF),
            const Color(0xFFFFF5F5),
          ],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: .86)),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: .10),
            blurRadius: 32,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(27),
        child: Stack(
          children: [
            Positioned.fill(
              child: AnimatedBuilder(
                animation: animation,
                builder: (context, _) {
                  return CustomPaint(
                    painter: LoginHealthWavePainter(animation.value),
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .78),
                borderRadius: BorderRadius.circular(27),
                border: Border.all(
                  color: AppColors.line.withValues(alpha: .70),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(child: LogoMark(width: 190, height: 72)),
                  const SizedBox(height: 8),
                  const Text(
                    'Welcome back',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    'Login securely with mobile OTP',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  AnimatedBuilder(
                    animation: animation,
                    builder: (context, _) {
                      return OtpOnlyAuthPill(progress: animation.value);
                    },
                  ),
                  const SizedBox(height: 14),
                  SupabaseStatusPill(connected: connected),
                  const SizedBox(height: 16),
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(
                        Icons.phone_iphone_rounded,
                        color: AppColors.blue,
                      ),
                      prefixText: '+91  ',
                      hintText: '98765 43210',
                      hintStyle: const TextStyle(
                        color: AppColors.muted,
                        fontWeight: FontWeight.w700,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF3F7FB),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 17,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(999),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(999),
                        borderSide: BorderSide(color: AppColors.line),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(999),
                        borderSide: const BorderSide(
                          color: AppColors.blue,
                          width: 1.4,
                        ),
                      ),
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 260),
                    child: otpSent
                        ? Padding(
                            key: const ValueKey('otp-visible'),
                            padding: const EdgeInsets.only(top: 12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: connected
                                      ? TextField(
                                          controller: otpController,
                                          keyboardType: TextInputType.number,
                                          decoration: InputDecoration(
                                            hintText: 'Enter OTP',
                                            filled: true,
                                            fillColor: const Color(0xFFEAF8EF),
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  horizontal: 18,
                                                  vertical: 17,
                                                ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                              borderSide: BorderSide.none,
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                              borderSide: BorderSide(
                                                color: AppColors.green
                                                    .withValues(alpha: .22),
                                              ),
                                            ),
                                          ),
                                        )
                                      : Container(
                                          height: 54,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFEAF8EF),
                                            borderRadius: BorderRadius.circular(
                                              999,
                                            ),
                                            border: Border.all(
                                              color: AppColors.green.withValues(
                                                alpha: .24,
                                              ),
                                            ),
                                          ),
                                          child: Text(
                                            otp,
                                            style: const TextStyle(
                                              color: AppColors.green,
                                              fontSize: 20,
                                              letterSpacing: 3,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ),
                                ),
                                const SizedBox(width: 10),
                                SizedBox(
                                  height: 54,
                                  child: FilledButton(
                                    onPressed: busy ? null : onLogin,
                                    style: FilledButton.styleFrom(
                                      backgroundColor: AppColors.green,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 18,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      connected ? 'Verify' : 'Open',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : const SizedBox.shrink(key: ValueKey('otp-hidden')),
                  ),
                  if (message != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      message!,
                      style: TextStyle(
                        color: connected ? AppColors.green : AppColors.muted,
                        fontSize: 12,
                        height: 1.3,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  PillActionButton(
                    label: busy
                        ? 'Please wait...'
                        : (otpSent ? 'Enter App' : 'Send OTP'),
                    icon: otpSent ? Icons.login_rounded : Icons.sms_rounded,
                    onTap: busy ? null : (otpSent ? onLogin : onSendOtp),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: TextButton(
                      onPressed: busy ? null : onDemoLogin,
                      child: const Text('Explore demo without login'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OtpOnlyAuthPill extends StatelessWidget {
  const OtpOnlyAuthPill({super.key, required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4F8),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: FractionalTranslation(
              translation: Offset(-1.25 + progress * 2.5, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: 110,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.white.withValues(alpha: .46),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.navy,
              borderRadius: BorderRadius.circular(999),
              boxShadow: [
                BoxShadow(
                  color: AppColors.navy.withValues(alpha: .18),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.phone_iphone_rounded, size: 17, color: Colors.white),
                SizedBox(width: 7),
                Flexible(
                  child: Text(
                    'Mobile OTP Login',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class LoginHealthWavePainter extends CustomPainter {
  const LoginHealthWavePainter(this.t);

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final softWash = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFFFFF), Color(0xFFF1FAFF), Color(0xFFFFF2F5)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, softWash);

    for (var i = 0; i < 3; i++) {
      final phase = (t + i * .22) % 1;
      final y = size.height * (.18 + i * .23);
      final path = ui.Path()..moveTo(-40, y);
      for (double x = -40; x <= size.width + 40; x += 18) {
        final wave = math.sin(
          (x / size.width * math.pi * 2.2) + phase * math.pi * 2,
        );
        path.lineTo(x, y + wave * (10 + i * 2));
      }
      final paint = Paint()
        ..color = [
          AppColors.blue,
          AppColors.green,
          AppColors.red,
        ][i].withValues(alpha: .055)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawPath(path, paint);
    }

    final glow = Paint()
      ..color = AppColors.green.withValues(alpha: .07)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28);
    canvas.drawCircle(
      Offset(size.width * (.18 + t * .10), size.height * .24),
      54,
      glow,
    );
  }

  @override
  bool shouldRepaint(covariant LoginHealthWavePainter oldDelegate) {
    return oldDelegate.t != t;
  }
}

class PillActionButton extends StatelessWidget {
  const PillActionButton({
    super.key,
    required this.label,
    required this.icon,
    this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 20),
        label: Text(label),
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.navy,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.navy.withValues(alpha: .42),
          disabledForegroundColor: Colors.white.withValues(alpha: .82),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

class SupabaseStatusPill extends StatelessWidget {
  const SupabaseStatusPill({super.key, required this.connected});

  final bool connected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: connected
            ? AppColors.green.withValues(alpha: .10)
            : AppColors.gold.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            connected ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
            color: connected ? AppColors.green : AppColors.gold,
            size: 17,
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              connected
                  ? 'Supabase connected'
                  : 'Demo mode until keys are added',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: connected ? AppColors.green : AppColors.text,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LandingFeatureRail extends StatelessWidget {
  const LandingFeatureRail({super.key});

  @override
  Widget build(BuildContext context) {
    const features = [
      LandingFeature(
        icon: Icons.emergency_share_rounded,
        title: 'SOS live location',
        subtitle: 'Alerts contacts, hospitals and authorities',
        color: AppColors.red,
      ),
      LandingFeature(
        icon: Icons.local_taxi_rounded,
        title: 'Emergency cab mode',
        subtitle: 'Drivers see the ride as priority emergency',
        color: Color(0xFFFF9800),
      ),
      LandingFeature(
        icon: Icons.savings_rounded,
        title: 'Schemes & medicines',
        subtitle: 'Ayushman Bharat and Jan Aushadhi support',
        color: AppColors.green,
      ),
    ];

    return Column(
      children: [
        for (final feature in features)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .90),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: feature.color.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(feature.icon, color: feature.color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        feature.title,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        feature.subtitle,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class LandingFeature {
  const LandingFeature({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  var _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const HomeScreen(),
      const AppointmentsScreen(),
      const SizedBox.shrink(),
      const MessagesScreen(),
      const ProfileScreen(),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        return Scaffold(
          body: Row(
            children: [
              if (wide)
                DesktopRail(selectedIndex: _index, onChanged: _handleTabChange),
              Expanded(
                child: IndexedStack(
                  index: _index == 2 ? 0 : _index,
                  children: pages,
                ),
              ),
            ],
          ),
          bottomNavigationBar: wide
              ? null
              : JeevanNavBar(
                  selectedIndex: _index,
                  onChanged: _handleTabChange,
                ),
        );
      },
    );
  }

  void _handleTabChange(int value) {
    if (value == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const EmergencySosScreen()),
      );
      return;
    }
    setState(() => _index = value);
  }
}

class DesktopRail extends StatelessWidget {
  const DesktopRail({
    super.key,
    required this.selectedIndex,
    required this.onChanged,
  });

  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 236,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: AppColors.line)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(18, 20, 18, 26),
              child: LogoMark(width: 184, height: 70),
            ),
            Expanded(
              child: NavigationRail(
                extended: true,
                selectedIndex: selectedIndex,
                onDestinationSelected: onChanged,
                backgroundColor: Colors.white,
                indicatorColor: AppColors.navy,
                selectedIconTheme: const IconThemeData(color: Colors.white),
                selectedLabelTextStyle: const TextStyle(
                  color: AppColors.navy,
                  fontWeight: FontWeight.w900,
                ),
                unselectedLabelTextStyle: const TextStyle(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w700,
                ),
                destinations: const [
                  NavigationRailDestination(
                    icon: Icon(Icons.home_outlined),
                    selectedIcon: Icon(Icons.home_rounded),
                    label: Text('Home'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.calendar_today_outlined),
                    selectedIcon: Icon(Icons.calendar_month_rounded),
                    label: Text('Appointments'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.sos_rounded),
                    selectedIcon: Icon(Icons.sos_rounded),
                    label: Text('SOS'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.chat_bubble_outline_rounded),
                    selectedIcon: Icon(Icons.chat_bubble_rounded),
                    label: Text('Messages'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.person_outline_rounded),
                    selectedIcon: Icon(Icons.person_rounded),
                    label: Text('Profile'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppPage(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 112),
        children: [
          const HomeHeader(),
          const SizedBox(height: 30),
          const Text(
            'Hello, Priya',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text(
            'How can we help\nyou today?',
            style: TextStyle(
              color: AppColors.text,
              fontSize: 27,
              height: 1.08,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 22),
          const SearchBox(hint: 'Search doctors, hospitals, services...'),
          AnimatedBuilder(
            animation: appLocation,
            builder: (context, _) {
              if (!appLocation.resolved) {
                return const SizedBox.shrink();
              }
              return const DoctorAvailabilityTicker();
            },
          ),
          const SizedBox(height: 18),
          const EmergencyBanner(),
          const SizedBox(height: 18),
          ServiceGrid(
            items: [
              ServiceItem(
                icon: Icons.medical_services_rounded,
                title: 'Find Doctors',
                subtitle: 'Book appointments',
                color: AppColors.blue,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FindDoctorsScreen()),
                ),
              ),
              ServiceItem(
                icon: Icons.local_hospital_rounded,
                title: 'Nearby Hospitals',
                subtitle: 'Find hospitals near you',
                color: AppColors.blue,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const NearbyHospitalsScreen(),
                  ),
                ),
              ),
              ServiceItem(
                icon: Icons.local_taxi_rounded,
                title: 'Emergency Cab',
                subtitle: 'Book a cab in emergency',
                color: const Color(0xFFFF9800),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EmergencyCabScreen()),
                ),
              ),
              ServiceItem(
                icon: Icons.health_and_safety_rounded,
                title: 'Health Schemes',
                subtitle: 'Ayushman Bharat & more',
                color: AppColors.green,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const HealthSchemesScreen(),
                  ),
                ),
              ),
              ServiceItem(
                icon: Icons.medication_liquid_rounded,
                title: 'Jan Aushadhi Kendras',
                subtitle: 'Find nearest stores',
                color: const Color(0xFF80A7D9),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const JanAushadhiScreen()),
                ),
              ),
              ServiceItem(
                icon: Icons.description_rounded,
                title: 'Health Records',
                subtitle: 'Your medical info',
                color: const Color(0xFF7D75FF),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const HealthRecordsScreen(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          SectionHeader(
            title: 'Nearby Hospitals',
            action: 'View all',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NearbyHospitalsScreen()),
            ),
          ),
          const SizedBox(height: 10),
          AnimatedBuilder(
            animation: appLocation,
            builder: (context, _) {
              if (!appLocation.resolved) {
                return const LocationRequiredPanel(
                  title: 'Enable GPS for nearby care',
                  subtitle:
                      'Nearby hospitals and emergency distances appear only after live GPS permission.',
                  icon: Icons.local_hospital_rounded,
                );
              }
              final nearby = [...hospitals]
                ..sort(
                  (a, b) => distanceKm(
                    appLocation.current,
                    a.latLng,
                  ).compareTo(distanceKm(appLocation.current, b.latLng)),
                );
              return Column(
                children: [
                  for (final hospital in nearby.take(2))
                    HospitalMiniCard(hospital: hospital, compact: true),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class LocationInsightCard extends StatelessWidget {
  const LocationInsightCard({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appLocation,
      builder: (context, _) {
        final nearestHospital = [...hospitals]
          ..sort(
            (a, b) => distanceKm(
              appLocation.current,
              a.latLng,
            ).compareTo(distanceKm(appLocation.current, b.latLng)),
          );
        final hospital = nearestHospital.first;
        return AppCard(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.blue.withValues(alpha: .11),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.my_location_rounded,
                  color: AppColors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appLocation.resolved
                          ? 'Using your live location'
                          : 'Location based care',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${hospital.name} - ${hospital.distanceFrom(appLocation.current)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (appLocation.message != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        appLocation.message!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.green,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: appLocation.loading
                    ? null
                    : appLocation.requestCurrentLocation,
                icon: appLocation.loading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.gps_fixed_rounded, size: 17),
                label: Text(appLocation.loading ? 'Locating' : 'Use GPS'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class LocationRequiredPanel extends StatelessWidget {
  const LocationRequiredPanel({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appLocation,
      builder: (context, _) {
        return AppCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.blue.withValues(alpha: .11),
                      borderRadius: BorderRadius.circular(17),
                    ),
                    child: Icon(icon, color: AppColors.blue),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            color: AppColors.muted,
                            height: 1.35,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (appLocation.message != null) ...[
                const SizedBox(height: 12),
                Text(
                  appLocation.message!,
                  style: const TextStyle(
                    color: AppColors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              PillActionButton(
                label: appLocation.loading
                    ? 'Detecting GPS...'
                    : 'Enable GPS Location',
                icon: Icons.gps_fixed_rounded,
                onTap: appLocation.loading
                    ? null
                    : appLocation.requestCurrentLocation,
              ),
            ],
          ),
        );
      },
    );
  }
}

class DoctorLocationPrompt extends StatelessWidget {
  const DoctorLocationPrompt({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appLocation,
      builder: (context, _) {
        return AppCard(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.green.withValues(alpha: .11),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.medical_information_rounded,
                  color: AppColors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Doctors near your area',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      appLocation.resolved
                          ? 'Using ${appLocation.label}'
                          : 'Use GPS to personalize doctor availability',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: appLocation.loading
                    ? null
                    : appLocation.requestCurrentLocation,
                icon: appLocation.loading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.gps_fixed_rounded, size: 17),
                label: Text(appLocation.loading ? 'GPS...' : 'GPS'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class FindDoctorsScreen extends StatelessWidget {
  const FindDoctorsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppPage(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 112),
          children: [
            const TopBar(
              title: 'Find Doctors',
              trailingIcon: Icons.tune_rounded,
            ),
            const SizedBox(height: 24),
            const SearchBox(hint: 'Search by name, specialization...'),
            const SizedBox(height: 12),
            AnimatedBuilder(
              animation: appLocation,
              builder: (context, _) {
                if (!appLocation.resolved) {
                  return const LocationRequiredPanel(
                    title: 'Enable GPS to find doctors',
                    subtitle:
                        'Doctor availability and nearby appointment details unlock after live GPS permission.',
                    icon: Icons.medical_information_rounded,
                  );
                }
                return Column(
                  children: [
                    const CategoryChips(
                      labels: [
                        'All',
                        'Cardiologist',
                        'Dentist',
                        'Pediatrician',
                        'Gynecologist',
                      ],
                    ),
                    const SizedBox(height: 16),
                    DoctorDirectoryList(repository: JeevanArogyaRepository()),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class DoctorDirectoryList extends StatelessWidget {
  const DoctorDirectoryList({super.key, required this.repository});

  final JeevanArogyaRepository repository;

  @override
  Widget build(BuildContext context) {
    if (!repository.isConnected) {
      return Column(
        children: [
          const DemoModeNotice(
            text: 'Doctors are demo data. Add Supabase keys for live database.',
          ),
          for (final doctor in doctors)
            DoctorCard(
              doctor: doctor,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DoctorDetailScreen(doctor: doctor),
                ),
              ),
            ),
        ],
      );
    }

    return StreamBuilder<List<DbDoctor>>(
      stream: repository.watchDoctors(),
      builder: (context, snapshot) {
        final liveDoctors = snapshot.data?.map(doctorFromDb).toList();
        final visibleDoctors = liveDoctors == null || liveDoctors.isEmpty
            ? doctors
            : liveDoctors;

        return Column(
          children: [
            LiveDatabaseNotice(
              label: snapshot.hasData
                  ? 'Live doctors synced from Supabase'
                  : 'Connecting to Supabase doctors...',
            ),
            for (final doctor in visibleDoctors)
              DoctorCard(
                doctor: doctor,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DoctorDetailScreen(doctor: doctor),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class DemoModeNotice extends StatelessWidget {
  const DemoModeNotice({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.text,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class LiveDatabaseNotice extends StatelessWidget {
  const LiveDatabaseNotice({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.green.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const LiveDot(color: AppColors.green),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.green,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DoctorDetailScreen extends StatelessWidget {
  const DoctorDetailScreen({super.key, required this.doctor});

  final Doctor doctor;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppPage(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 112),
          children: [
            Row(
              children: [
                BackCircle(onTap: () => Navigator.pop(context)),
                const Spacer(),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.share_outlined, color: AppColors.navy),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Center(child: DoctorAvatar(doctor: doctor, radius: 64)),
            const SizedBox(height: 18),
            Center(
              child: Column(
                children: [
                  Text(
                    doctor.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    doctor.specialty,
                    style: const TextStyle(
                      color: AppColors.navy,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${doctor.experience}  -  ${doctor.degree} (${doctor.specialty})',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  RatingLine(rating: doctor.rating, reviews: doctor.reviews),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    title: doctor.fee,
                    subtitle: 'Consultation Fee',
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: StatCard(
                    title: '10:00 AM - 6:00 PM',
                    subtitle: 'Available Today',
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: StatCard(
                    title: 'Apollo Hospital',
                    subtitle: 'Malviya Nagar, Indore',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'About Doctor',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            const Text(
              'Dr. Ananya Sharma is a consultant cardiologist with over 10 years of experience in managing heart diseases and performing advanced cardiac procedures.',
              style: TextStyle(color: AppColors.muted, height: 1.45),
            ),
            TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.zero,
              ),
              child: const Text('Read more'),
            ),
            const SizedBox(height: 14),
            const Text(
              'Next Available Slots',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            const DateSlots(),
            const SizedBox(height: 12),
            const TimeSlots(),
            const SizedBox(height: 22),
            PrimaryButton(
              label: 'Book Appointment',
              onTap: () => _bookAppointment(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _bookAppointment(BuildContext context) async {
    final repository = JeevanArogyaRepository();
    if (!repository.isConnected || doctor.id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Demo booking shown. Add Supabase keys for real save.'),
        ),
      );
      return;
    }

    try {
      await repository.bookAppointment(
        doctorId: doctor.id,
        slotTime: DateTime.now().add(const Duration(days: 1, hours: 2)),
      );
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Appointment saved in Supabase.')),
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Booking failed: $error')));
    }
  }
}

class EmergencySosScreen extends StatelessWidget {
  const EmergencySosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.red,
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFF3B44), Color(0xFFD71927)],
            ),
          ),
          child: Stack(
            children: [
              ListView(
                padding: const EdgeInsets.fromLTRB(22, 26, 22, 110),
                children: const [
                  SizedBox(height: 34),
                  Text(
                    'Emergency SOS',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'We will alert your contacts and\nnearby authorities',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, height: 1.35),
                  ),
                  SizedBox(height: 60),
                  SosPulseButton(),
                  SizedBox(height: 34),
                  LocationSharingPill(),
                  SizedBox(height: 24),
                  AlertPanel(),
                ],
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 88,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    children: [
                      Transform.translate(
                        offset: const Offset(0, -20),
                        child: FloatingActionButton.small(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.text,
                          onPressed: () => Navigator.pop(context),
                          child: const Icon(Icons.close_rounded),
                        ),
                      ),
                      const Text(
                        'Slide up to cancel SOS',
                        style: TextStyle(color: AppColors.muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EmergencyCabScreen extends StatelessWidget {
  const EmergencyCabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppPage(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              child: TopBar(
                title: 'Emergency Cab',
                onBack: () => Navigator.pop(context),
              ),
            ),
            Expanded(
              child: AnimatedBuilder(
                animation: appLocation,
                builder: (context, _) {
                  if (!appLocation.resolved) {
                    return const Padding(
                      padding: EdgeInsets.fromLTRB(20, 20, 20, 28),
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: LocationRequiredPanel(
                          title: 'Enable GPS for emergency cab',
                          subtitle:
                              'Pickup, route and nearest hospital drop are shown only after real live GPS is available.',
                          icon: Icons.local_taxi_rounded,
                        ),
                      ),
                    );
                  }
                  return const Stack(
                    children: [
                      Positioned.fill(child: MapPanel(mode: MapMode.route)),
                      Positioned(
                        left: 20,
                        right: 20,
                        bottom: 0,
                        child: EmergencyRideCard(),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NearbyHospitalsScreen extends StatelessWidget {
  const NearbyHospitalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppPage(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              child: TopBar(
                title: 'Nearby Hospitals',
                trailingIcon: Icons.tune_rounded,
                onBack: () => Navigator.pop(context),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: AnimatedBuilder(
                animation: appLocation,
                builder: (context, _) {
                  if (!appLocation.resolved) {
                    return const Padding(
                      padding: EdgeInsets.fromLTRB(20, 0, 20, 26),
                      child: LocationRequiredPanel(
                        title: 'Enable GPS for nearby hospitals',
                        subtitle:
                            'Hospitals, distance, map and call details unlock after live GPS permission.',
                        icon: Icons.local_hospital_rounded,
                      ),
                    );
                  }
                  final nearby = [...hospitals]
                    ..sort(
                      (a, b) => distanceKm(
                        appLocation.current,
                        a.latLng,
                      ).compareTo(distanceKm(appLocation.current, b.latLng)),
                    );
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 26),
                    children: [
                      const SizedBox(
                        height: 265,
                        child: MapPanel(mode: MapMode.hospitals),
                      ),
                      const SizedBox(height: 12),
                      for (final hospital in nearby)
                        HospitalMiniCard(hospital: hospital, compact: false),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HealthSchemesScreen extends StatelessWidget {
  const HealthSchemesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppPage(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          children: const [
            TopBar(title: 'Health Schemes'),
            SizedBox(height: 18),
            AyushmanCard(),
            SizedBox(height: 22),
            Text(
              'Other Government Schemes',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            ),
            SizedBox(height: 12),
            SchemeTile(
              icon: Icons.local_hospital_rounded,
              title: 'State Health Scheme',
              subtitle: 'Scheme by your state government',
              color: Color(0xFFBFE9FF),
            ),
            SchemeTile(
              icon: Icons.health_and_safety_rounded,
              title: 'CGHS',
              subtitle: 'Central Government Health Scheme',
              color: Color(0xFFFFC9D0),
            ),
            SchemeTile(
              icon: Icons.verified_user_rounded,
              title: 'ESIC',
              subtitle: 'Employees State Insurance Scheme',
              color: Color(0xFFFFD99C),
            ),
            SchemeTile(
              icon: Icons.dashboard_customize_rounded,
              title: 'Others',
              subtitle: 'More government schemes',
              color: Color(0xFFE6C8FF),
            ),
          ],
        ),
      ),
    );
  }
}

class HealthRecordsScreen extends StatelessWidget {
  const HealthRecordsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const records = [
      ('Blood Report', 'CBC and lipid profile - uploaded today'),
      ('Prescription', 'Dr. Ananya Sharma - Atorvastatin 10mg'),
      ('Allergy', 'Penicillin sensitivity marked as important'),
      ('Vaccination', 'Tetanus booster due in 2027'),
    ];

    return Scaffold(
      body: AppPage(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
          children: [
            const TopBar(title: 'Health Records'),
            const SizedBox(height: 18),
            AppCard(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.blue.withValues(alpha: .11),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.folder_copy_rounded,
                      color: AppColors.blue,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Priya Sharma',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '4 verified records stored locally for demo.',
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            for (final record in records)
              AppCard(
                margin: const EdgeInsets.only(bottom: 12),
                onTap: () => ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('${record.$1} opened'))),
                child: Row(
                  children: [
                    const Icon(
                      Icons.description_rounded,
                      color: AppColors.navy,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            record.$1,
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            record.$2,
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class JanAushadhiScreen extends StatelessWidget {
  const JanAushadhiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppPage(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              child: TopBar(
                title: 'Jan Aushadhi Kendras',
                trailingIcon: Icons.tune_rounded,
                onBack: () => Navigator.pop(context),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: AnimatedBuilder(
                animation: appLocation,
                builder: (context, _) {
                  if (!appLocation.resolved) {
                    return const Padding(
                      padding: EdgeInsets.fromLTRB(20, 0, 20, 26),
                      child: LocationRequiredPanel(
                        title: 'Enable GPS for Jan Aushadhi',
                        subtitle:
                            'Nearest store list, distance and map are hidden until live GPS permission is allowed.',
                        icon: Icons.medication_liquid_rounded,
                      ),
                    );
                  }
                  final nearby = [...kendras]
                    ..sort(
                      (a, b) => distanceKm(
                        appLocation.current,
                        a.latLng,
                      ).compareTo(distanceKm(appLocation.current, b.latLng)),
                    );
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 26),
                    children: [
                      const SizedBox(
                        height: 265,
                        child: MapPanel(mode: MapMode.kendras),
                      ),
                      const SizedBox(height: 12),
                      for (final kendra in nearby) KendraCard(place: kendra),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AppointmentsScreen extends StatelessWidget {
  const AppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppPage(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 112),
        children: [
          const TopBar(title: 'Appointments', showBack: false),
          const SizedBox(height: 20),
          AppointmentCard(doctor: doctors.first, time: 'Today, 11:30 AM'),
          AppointmentCard(doctor: doctors[2], time: 'Tomorrow, 10:00 AM'),
        ],
      ),
    );
  }
}

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppPage(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 112),
        children: const [
          TopBar(title: 'Messages', showBack: false),
          SizedBox(height: 20),
          MessageTile(
            name: 'Apollo Hospitals',
            text: 'Your appointment is confirmed.',
          ),
          MessageTile(
            name: 'Emergency Contacts',
            text: '3 contacts are ready for SOS alerts.',
          ),
          MessageTile(
            name: 'Health Schemes',
            text: 'Ayushman eligibility check is pending.',
          ),
        ],
      ),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppPage(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 112),
        children: [
          const TopBar(
            title: 'Profile',
            showBack: false,
            trailingIcon: Icons.settings_outlined,
          ),
          const SizedBox(height: 18),
          const ProfileHeaderCard(),
          const SizedBox(height: 24),
          const Text(
            'My Health',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          ProfileMenuItem(
            icon: Icons.description_outlined,
            title: 'Health Records',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HealthRecordsScreen()),
            ),
          ),
          ProfileMenuItem(
            icon: Icons.medical_information_outlined,
            title: 'Prescriptions',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const SimpleInfoScreen(
                  title: 'Prescriptions',
                  lines: [
                    'Atorvastatin 10mg - once daily',
                    'Vitamin D3 - weekly',
                    'ORS sachets - as needed',
                  ],
                ),
              ),
            ),
          ),
          ProfileMenuItem(
            icon: Icons.sick_outlined,
            title: 'Allergies & Conditions',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const SimpleInfoScreen(
                  title: 'Allergies & Conditions',
                  lines: [
                    'Penicillin allergy',
                    'Mild seasonal asthma',
                    'No active critical conditions',
                  ],
                ),
              ),
            ),
          ),
          ProfileMenuItem(
            icon: Icons.shield_outlined,
            title: 'Vital Health Info',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const SimpleInfoScreen(
                  title: 'Vital Health Info',
                  lines: ['Blood group: B+', 'Pulse: 76 bpm', 'SpO2: 98%'],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'My Account',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          ProfileMenuItem(
            icon: Icons.groups_2_outlined,
            title: 'Emergency Contacts',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const SimpleInfoScreen(
                  title: 'Emergency Contacts',
                  lines: [
                    'Rohit Sharma - Father - +91 98765 00001',
                    'Neha Sharma - Sister - +91 98765 00002',
                    'Local ambulance - 108',
                  ],
                ),
              ),
            ),
          ),
          ProfileMenuItem(
            icon: Icons.location_on_outlined,
            title: 'Address Book',
            onTap: appLocation.requestCurrentLocation,
          ),
          ProfileMenuItem(
            icon: Icons.notifications_none_rounded,
            title: 'Notification Settings',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const SimpleInfoScreen(
                  title: 'Notification Settings',
                  lines: [
                    'SOS alerts enabled',
                    'Appointment reminders enabled',
                    'Medicine refill reminders enabled',
                  ],
                ),
              ),
            ),
          ),
          ProfileMenuItem(
            icon: Icons.help_outline_rounded,
            title: 'Help & Support',
            onTap: () => callPhone(context, '+91108'),
          ),
          ProfileMenuItem(
            icon: Icons.info_outline_rounded,
            title: 'About Us',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const SimpleInfoScreen(
                  title: 'About Us',
                  lines: [
                    'Jeevan Arogya connects patients to nearby care.',
                    'Maps use OpenStreetMap tiles.',
                    'Supabase powers auth and live database features.',
                  ],
                ),
              ),
            ),
          ),
          ProfileMenuItem(
            icon: Icons.logout_rounded,
            title: 'Logout',
            danger: true,
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Logged out in demo mode.')),
            ),
          ),
        ],
      ),
    );
  }
}

class SimpleInfoScreen extends StatelessWidget {
  const SimpleInfoScreen({super.key, required this.title, required this.lines});

  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppPage(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
          children: [
            TopBar(title: title),
            const SizedBox(height: 18),
            for (final line in lines)
              AppCard(
                margin: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.green,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        line,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class AppPage extends StatelessWidget {
  const AppPage({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, AppColors.bg],
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1180),
            child: child,
          ),
        ),
      ),
    );
  }
}

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleIcon(
          icon: Icons.menu_rounded,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProfileScreen()),
          ),
        ),
        const Spacer(),
        const LogoMark(width: 136, height: 52),
        const Spacer(),
        CircleIcon(
          icon: Icons.notifications_none_rounded,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const SimpleInfoScreen(
                title: 'Notifications',
                lines: [
                  'Appointment reminder: Today 11:30 AM',
                  'Nearest hospital list updated',
                  'Medicine refill reminder is active',
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class LogoMark extends StatelessWidget {
  const LogoMark({super.key, this.width = 144, this.height = 54});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Image.asset(
        'assets/branding/jeevan_arogya_logo.png',
        fit: BoxFit.contain,
        semanticLabel: 'Jeevan Arogya',
      ),
    );
  }
}

class CircleIcon extends StatelessWidget {
  const CircleIcon({super.key, required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.text, size: 21),
      ),
    );
  }
}

class TopBar extends StatelessWidget {
  const TopBar({
    super.key,
    required this.title,
    this.trailingIcon,
    this.onBack,
    this.showBack = true,
  });

  final String title;
  final IconData? trailingIcon;
  final VoidCallback? onBack;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (showBack)
          BackCircle(onTap: onBack ?? () => Navigator.pop(context))
        else
          const SizedBox(width: 40),
        Expanded(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
        ),
        if (trailingIcon != null)
          CircleIcon(icon: trailingIcon!, onTap: () {})
        else
          const SizedBox(width: 40),
      ],
    );
  }
}

class BackCircle extends StatelessWidget {
  const BackCircle({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: const SizedBox(
        width: 40,
        height: 40,
        child: Icon(Icons.arrow_back_rounded, color: AppColors.text),
      ),
    );
  }
}

class SearchBox extends StatelessWidget {
  const SearchBox({super.key, required this.hint});

  final String hint;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.soft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              hint,
              style: const TextStyle(color: AppColors.muted, fontSize: 13),
            ),
          ),
          const Icon(Icons.search_rounded, color: AppColors.text),
        ],
      ),
    );
  }
}

class DoctorAvailabilityTicker extends StatefulWidget {
  const DoctorAvailabilityTicker({super.key});

  @override
  State<DoctorAvailabilityTicker> createState() =>
      _DoctorAvailabilityTickerState();
}

class _DoctorAvailabilityTickerState extends State<DoctorAvailabilityTicker> {
  late Timer _timer;
  var _index = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) {
        setState(() => _index = (_index + 1) % doctors.length);
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final doctor = doctors[_index];
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 420),
      child: Container(
        key: ValueKey(doctor.name),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(
          children: [
            DoctorAvatar(doctor: doctor, radius: 27),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Next doctor available',
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    doctor.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${doctor.specialty} - ${doctor.nextSlot}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                color: AppColors.navy,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LiveDot extends StatefulWidget {
  const LiveDot({super.key, required this.color});

  final Color color;

  @override
  State<LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<LiveDot> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final spread = 2 + _controller.value * 5;
        return Container(
          width: 11,
          height: 11,
          decoration: BoxDecoration(
            color: widget.color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: .25),
                blurRadius: 10,
                spreadRadius: spread,
              ),
            ],
          ),
        );
      },
    );
  }
}

class EmergencyBanner extends StatelessWidget {
  const EmergencyBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const EmergencySosScreen()),
      ),
      child: Container(
        height: 184,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [AppColors.red2, AppColors.red],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.red.withValues(alpha: .22),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'In an Emergency?',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Tap SOS for\nimmediate help',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 21,
                      height: 1.05,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 9),
                  Text(
                    'Alert contacts, nearby hospitals\n& authorities',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const HomeSosPulseButton(),
          ],
        ),
      ),
    );
  }
}

class HomeSosPulseButton extends StatefulWidget {
  const HomeSosPulseButton({super.key});

  @override
  State<HomeSosPulseButton> createState() => _HomeSosPulseButtonState();
}

class _HomeSosPulseButtonState extends State<HomeSosPulseButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 112,
      height: 112,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              _PulseRing(progress: _controller.value),
              _PulseRing(progress: (_controller.value + .52) % 1),
              Container(
                width: 82,
                height: 82,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: .38),
                      blurRadius: 22,
                      spreadRadius: 8,
                    ),
                    BoxShadow(
                      color: AppColors.red.withValues(alpha: .18),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'SOS',
                    style: TextStyle(
                      color: AppColors.red,
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PulseRing extends StatelessWidget {
  const _PulseRing({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final size = 76 + (progress * 36);
    final opacity = (1 - progress).clamp(0.0, 1.0) * .42;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: opacity * .24),
        border: Border.all(
          color: Colors.white.withValues(alpha: opacity),
          width: 2.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: opacity * .78),
            blurRadius: 26,
            spreadRadius: 6,
          ),
        ],
      ),
    );
  }
}

class ServiceGrid extends StatelessWidget {
  const ServiceGrid({super.key, required this.items});

  final List<ServiceItem> items;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      itemCount: items.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.35,
      ),
      itemBuilder: (context, index) => ServiceCard(item: items[index]),
    );
  }
}

class ServiceItem {
  const ServiceItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
}

class ServiceCard extends StatelessWidget {
  const ServiceCard({super.key, required this.item});

  final ServiceItem item;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: item.onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.soft,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(item.icon, color: item.color, size: 28),
            const Spacer(),
            Text(
              item.title,
              maxLines: 2,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              item.subtitle,
              maxLines: 2,
              style: const TextStyle(color: AppColors.muted, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.action,
    this.onTap,
  });

  final String title;
  final String? action;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
        ),
        if (action != null)
          TextButton(
            onPressed: onTap,
            child: Text(action!, style: const TextStyle(fontSize: 12)),
          ),
      ],
    );
  }
}

class CategoryChips extends StatelessWidget {
  const CategoryChips({super.key, required this.labels});

  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Container(
              margin: const EdgeInsets.only(right: 9),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
              decoration: BoxDecoration(
                color: i == 0 ? AppColors.navy : AppColors.soft,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                labels[i],
                style: TextStyle(
                  color: i == 0 ? Colors.white : AppColors.text,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class DoctorCard extends StatelessWidget {
  const DoctorCard({super.key, required this.doctor, required this.onTap});

  final Doctor doctor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      margin: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              DoctorAvatar(doctor: doctor, radius: 35),
              const SizedBox(height: 10),
              Text(
                doctor.fee,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        doctor.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.favorite_border_rounded,
                      color: AppColors.muted,
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  doctor.specialty,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  '${doctor.experience}  -  ${doctor.degree}',
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
                const SizedBox(height: 11),
                Row(
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: RatingLine(
                          rating: doctor.rating,
                          reviews: doctor.reviews,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'Next available',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.green,
                              fontSize: 10,
                            ),
                          ),
                          Text(
                            doctor.nextSlot,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.green,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DoctorAvatar extends StatelessWidget {
  const DoctorAvatar({super.key, required this.doctor, this.radius = 34});

  final Doctor doctor;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(color: doctor.color, shape: BoxShape.circle),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.person_rounded,
            size: radius * 1.35,
            color: AppColors.navy.withValues(alpha: .58),
          ),
          Positioned(
            right: radius * .34,
            bottom: radius * .15,
            child: Icon(
              Icons.medical_services_rounded,
              size: radius * .34,
              color: AppColors.blue,
            ),
          ),
        ],
      ),
    );
  }
}

class RatingLine extends StatelessWidget {
  const RatingLine({super.key, required this.rating, required this.reviews});

  final String rating;
  final String reviews;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.star_rounded, color: AppColors.gold, size: 17),
        const SizedBox(width: 3),
        Flexible(
          child: Text(
            '$rating ($reviews)',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class StatCard extends StatelessWidget {
  const StatCard({super.key, required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 72),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.soft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.muted, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class DateSlots extends StatelessWidget {
  const DateSlots({super.key});

  @override
  Widget build(BuildContext context) {
    const dates = [
      ('Today', '16 May'),
      ('Sat', '17 May'),
      ('Sun', '18 May'),
      ('Mon', '19 May'),
    ];
    return Row(
      children: [
        for (var i = 0; i < dates.length; i++)
          Expanded(
            child: Container(
              margin: EdgeInsets.only(right: i == dates.length - 1 ? 0 : 8),
              padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: BoxDecoration(
                color: i == 0 ? AppColors.navy : AppColors.soft,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Column(
                children: [
                  Text(
                    dates[i].$1,
                    style: TextStyle(
                      color: i == 0 ? Colors.white : AppColors.text,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    dates[i].$2,
                    style: TextStyle(
                      color: i == 0 ? Colors.white70 : AppColors.muted,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class TimeSlots extends StatelessWidget {
  const TimeSlots({super.key});

  @override
  Widget build(BuildContext context) {
    const times = [
      '10:00 AM',
      '11:30 AM',
      '03:00 PM',
      '04:30 PM',
      '05:30 PM',
      '06:00 PM',
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: times.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 2.3,
      ),
      itemBuilder: (context, index) {
        final selected = index == 1;
        return Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.navy : AppColors.soft,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            times[index],
            style: TextStyle(
              color: selected ? Colors.white : AppColors.text,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        );
      },
    );
  }
}

class SosPulseButton extends StatelessWidget {
  const SosPulseButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: () => _saveSos(context),
        child: Container(
          width: 190,
          height: 190,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: .12),
          ),
          child: Center(
            child: Container(
              width: 148,
              height: 148,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: .16),
              ),
              child: Center(
                child: Container(
                  width: 112,
                  height: 112,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  child: const Center(
                    child: Text(
                      'TAP TO\nSOS',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.red,
                        fontSize: 22,
                        height: 1.1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveSos(BuildContext context) async {
    if (!appLocation.resolved && !appLocation.loading) {
      await appLocation.requestCurrentLocation();
    }
    if (!context.mounted) {
      return;
    }
    final repository = JeevanArogyaRepository();
    if (!repository.isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Demo SOS active. Add Supabase keys for real alert save.',
          ),
        ),
      );
      return;
    }

    try {
      await repository.createSosAlert(
        latitude: appLocation.current.latitude,
        longitude: appLocation.current.longitude,
      );
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('SOS alert saved in Supabase.')),
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('SOS failed: $error')));
    }
  }
}

class LocationSharingPill extends StatelessWidget {
  const LocationSharingPill({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appLocation,
      builder: (context, _) {
        return Center(
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: appLocation.loading
                ? null
                : appLocation.requestCurrentLocation,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .18),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.location_on_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    appLocation.resolved
                        ? 'Live: ${appLocation.label}'
                        : 'Tap to share live location',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    appLocation.loading
                        ? Icons.sync_rounded
                        : Icons.sensors_rounded,
                    color: Colors.white,
                    size: 17,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class AlertPanel extends StatelessWidget {
  const AlertPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: .25)),
        color: Colors.white.withValues(alpha: .08),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This will alert',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
          ),
          SizedBox(height: 16),
          AlertRow(
            icon: Icons.groups_2_rounded,
            title: 'Emergency Contacts',
            subtitle: '3 contacts',
          ),
          AlertRow(
            icon: Icons.local_hospital_rounded,
            title: 'Nearby Hospitals',
            subtitle: 'Within 5 km radius',
          ),
          AlertRow(
            icon: Icons.account_balance_rounded,
            title: 'Local Authorities',
            subtitle: 'Police & Ambulance',
          ),
        ],
      ),
    );
  }
}

class AlertRow extends StatelessWidget {
  const AlertRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

enum MapMode { route, hospitals, kendras }

class MapPanel extends StatelessWidget {
  const MapPanel({super.key, required this.mode});

  final MapMode mode;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appLocation,
      builder: (context, _) {
        final user = appLocation.current;
        final destination = switch (mode) {
          MapMode.route => hospitals.first.latLng,
          MapMode.hospitals => hospitals.first.latLng,
          MapMode.kendras => kendras.first.latLng,
        };
        final markers = <Marker>[
          Marker(
            point: user,
            width: 54,
            height: 54,
            child: const MapBubble(
              color: AppColors.blue,
              icon: Icons.my_location_rounded,
              label: 'You',
            ),
          ),
          if (mode == MapMode.hospitals || mode == MapMode.route)
            for (final hospital in hospitals)
              Marker(
                point: hospital.latLng,
                width: 60,
                height: 60,
                child: MapBubble(
                  color: AppColors.red,
                  icon: Icons.local_hospital_rounded,
                  label: hospital.distanceFrom(user),
                ),
              ),
          if (mode == MapMode.kendras)
            for (final kendra in kendras)
              Marker(
                point: kendra.latLng,
                width: 60,
                height: 60,
                child: MapBubble(
                  color: AppColors.green,
                  icon: Icons.medication_liquid_rounded,
                  label: kendra.distanceFrom(user),
                ),
              ),
        ];

        return ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            children: [
              FlutterMap(
                key: ValueKey(
                  '${mode.name}-${user.latitude.toStringAsFixed(4)}-${user.longitude.toStringAsFixed(4)}',
                ),
                options: MapOptions(
                  initialCenter: mode == MapMode.route
                      ? LatLng(
                          (user.latitude + destination.latitude) / 2,
                          (user.longitude + destination.longitude) / 2,
                        )
                      : user,
                  initialZoom: mode == MapMode.route ? 13.0 : 13.5,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.gravitymeet.gravitymeet',
                  ),
                  if (mode == MapMode.route)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: [user, destination],
                          color: AppColors.navy,
                          strokeWidth: 5,
                        ),
                      ],
                    ),
                  MarkerLayer(markers: markers),
                ],
              ),
              Positioned(
                left: 12,
                right: 12,
                top: 12,
                child: MapLocationToolbar(mode: mode),
              ),
            ],
          ),
        );
      },
    );
  }
}

class MapLocationToolbar extends StatelessWidget {
  const MapLocationToolbar({super.key, required this.mode});

  final MapMode mode;

  @override
  Widget build(BuildContext context) {
    final title = switch (mode) {
      MapMode.route => 'Live emergency route',
      MapMode.hospitals => 'Hospitals near you',
      MapMode.kendras => 'Jan Aushadhi near you',
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .92),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            const Icon(Icons.map_rounded, color: AppColors.blue, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: appLocation.loading
                  ? null
                  : appLocation.requestCurrentLocation,
              icon: const Icon(Icons.gps_fixed_rounded, size: 16),
              label: const Text('GPS'),
            ),
          ],
        ),
      ),
    );
  }
}

class MapBubble extends StatelessWidget {
  const MapBubble({
    super.key,
    required this.color,
    required this.icon,
    required this.label,
  });

  final Color color;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: .35),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 17),
        ),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 9,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class EmergencyRideCard extends StatelessWidget {
  const EmergencyRideCard({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appLocation,
      builder: (context, _) {
        final nearest = [...hospitals]
          ..sort(
            (a, b) => distanceKm(
              appLocation.current,
              a.latLng,
            ).compareTo(distanceKm(appLocation.current, b.latLng)),
          );
        final hospital = nearest.first;
        return AppCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Confirm Emergency Ride',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 18),
              RouteRow(
                color: AppColors.blue,
                title: 'Pickup Location',
                subtitle: appLocation.resolved
                    ? appLocation.label
                    : 'Use GPS for current location',
              ),
              RouteRow(
                color: AppColors.red,
                title: 'Drop Location',
                subtitle:
                    '${hospital.name} (${hospital.distanceFrom(appLocation.current)})',
              ),
              const SizedBox(height: 8),
              const Row(
                children: [
                  Expanded(
                    child: RideInfo(
                      icon: Icons.local_taxi_rounded,
                      title: 'Ride Type',
                      value: 'Hatchback',
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: RideInfo(
                      icon: Icons.payments_outlined,
                      title: 'Payment Method',
                      value: 'Cash',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              PrimaryButton(
                label: 'Request Emergency Cab',
                onTap: () => _requestCab(context),
              ),
              const SizedBox(height: 12),
              const Center(
                child: Text(
                  'Drivers will be notified about the emergency',
                  style: TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _requestCab(BuildContext context) async {
    if (!appLocation.resolved && !appLocation.loading) {
      await appLocation.requestCurrentLocation();
    }
    if (!context.mounted) {
      return;
    }
    final nearest = [...hospitals]
      ..sort(
        (a, b) => distanceKm(
          appLocation.current,
          a.latLng,
        ).compareTo(distanceKm(appLocation.current, b.latLng)),
      );
    final hospital = nearest.first;
    final repository = JeevanArogyaRepository();
    if (!repository.isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Demo cab request shown. Add Supabase keys for real save.',
          ),
        ),
      );
      return;
    }

    try {
      await repository.requestEmergencyCab(
        pickup: appLocation.label,
        dropLocation: '${hospital.name}, Indore',
        pickupLatitude: appLocation.current.latitude,
        pickupLongitude: appLocation.current.longitude,
      );
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Emergency cab request saved.')),
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Cab request failed: $error')));
    }
  }
}

class RouteRow extends StatelessWidget {
  const RouteRow({
    super.key,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  final Color color;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        children: [
          CircleAvatar(radius: 5, backgroundColor: color),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: AppColors.muted, fontSize: 11),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class RideInfo extends StatelessWidget {
  const RideInfo({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.soft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.navy, size: 20),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: AppColors.muted, fontSize: 10),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.muted,
            size: 18,
          ),
        ],
      ),
    );
  }
}

class HospitalMiniCard extends StatelessWidget {
  const HospitalMiniCard({
    super.key,
    required this.hospital,
    required this.compact,
  });

  final Hospital hospital;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appLocation,
      builder: (context, _) {
        final distance = hospital.distanceFrom(appLocation.current);
        return AppCard(
          padding: const EdgeInsets.all(14),
          margin: const EdgeInsets.only(bottom: 12),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PlaceDetailScreen(
                title: hospital.name,
                subtitle: '$distance - ${hospital.status}',
                icon: Icons.local_hospital_rounded,
                color: AppColors.red,
                phone: hospital.phone,
                location: hospital.latLng,
              ),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.soft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.local_hospital_outlined,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hospital.name,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 4),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: distance,
                            style: const TextStyle(color: AppColors.muted),
                          ),
                          const TextSpan(text: '  -  '),
                          TextSpan(
                            text: hospital.status,
                            style: const TextStyle(
                              color: AppColors.green,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
              CircleIcon(
                icon: Icons.call_outlined,
                onTap: () => callPhone(context, hospital.phone),
              ),
            ],
          ),
        );
      },
    );
  }
}

class PlaceDetailScreen extends StatelessWidget {
  const PlaceDetailScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.phone,
    required this.location,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String phone;
  final LatLng location;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppPage(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
          children: [
            TopBar(title: title),
            const SizedBox(height: 22),
            AppCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: color.withValues(alpha: .12),
                    child: Icon(icon, color: color),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: PrimaryButton(
                          label: 'Call Now',
                          onTap: () => callPhone(context, phone),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => openDirections(context, location),
                          icon: const Icon(Icons.directions_rounded),
                          label: const Text('Directions'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const SizedBox(
              height: 320,
              child: MapPanel(mode: MapMode.hospitals),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> callPhone(BuildContext context, String phone) async {
  final uri = Uri(scheme: 'tel', path: phone);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri);
    return;
  }
  if (!context.mounted) {
    return;
  }
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text('Call: $phone')));
}

Future<void> openDirections(BuildContext context, LatLng location) async {
  final uri = Uri.parse(
    'https://www.google.com/maps/dir/?api=1&destination=${location.latitude},${location.longitude}',
  );
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
    return;
  }
  if (!context.mounted) {
    return;
  }
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        'Map: ${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}',
      ),
    ),
  );
}

class AyushmanCard extends StatelessWidget {
  const AyushmanCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.soft,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ayushman Bharat',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Pradhan Mantri Jan Arogya Yojana',
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Get cashless treatment up to Rs. 5,00,000 per family per year.',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 38,
                  child: FilledButton(
                    onPressed: () {},
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.navy,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Check Eligibility',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            children: [
              Container(
                width: 66,
                height: 66,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: AppColors.green, width: 2),
                ),
                child: const Icon(
                  Icons.spa_rounded,
                  color: AppColors.green,
                  size: 34,
                ),
              ),
              const SizedBox(height: 14),
              Transform.rotate(
                angle: -.1,
                child: Container(
                  width: 78,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.green, width: 2),
                  ),
                  child: const Icon(
                    Icons.credit_card_rounded,
                    color: AppColors.green,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class SchemeTile extends StatelessWidget {
  const SchemeTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: color,
            child: Icon(icon, color: AppColors.navy, size: 21),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
        ],
      ),
    );
  }
}

class KendraCard extends StatelessWidget {
  const KendraCard({super.key, required this.place});

  final Place place;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appLocation,
      builder: (context, _) {
        final distance = place.distanceFrom(appLocation.current);
        return AppCard(
          padding: const EdgeInsets.all(14),
          margin: const EdgeInsets.only(bottom: 12),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PlaceDetailScreen(
                title: place.name,
                subtitle: '$distance - ${place.area}',
                icon: Icons.medication_liquid_rounded,
                color: AppColors.green,
                phone: place.phone,
                location: place.latLng,
              ),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF8EF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.medication_liquid_rounded,
                  color: AppColors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place.name,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$distance  -  ${place.area}',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              CircleIcon(
                icon: Icons.call_outlined,
                onTap: () => callPhone(context, place.phone),
              ),
            ],
          ),
        );
      },
    );
  }
}

class AppointmentCard extends StatelessWidget {
  const AppointmentCard({super.key, required this.doctor, required this.time});

  final Doctor doctor;
  final String time;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          DoctorAvatar(doctor: doctor, radius: 32),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doctor.name,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  doctor.specialty,
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Text(
                  time,
                  style: const TextStyle(
                    color: AppColors.green,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.videocam_outlined, color: AppColors.navy),
        ],
      ),
    );
  }
}

class MessageTile extends StatelessWidget {
  const MessageTile({super.key, required this.name, required this.text});

  final String name;
  final String text;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: AppColors.soft,
            child: Icon(
              Icons.chat_bubble_outline_rounded,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(
                  text,
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileHeaderCard extends StatelessWidget {
  const ProfileHeaderCard({super.key});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 33,
            backgroundColor: Color(0xFF91B7F2),
            child: Text(
              'P',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Priya Sharma',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                ),
                SizedBox(height: 4),
                Text(
                  '+91 98765 43210',
                  style: TextStyle(color: AppColors.muted, fontSize: 12),
                ),
                Text(
                  'priya.sharma@email.com',
                  style: TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.text),
        ],
      ),
    );
  }
}

class ProfileMenuItem extends StatelessWidget {
  const ProfileMenuItem({
    super.key,
    required this.icon,
    required this.title,
    this.danger = false,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final bool danger;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: AppColors.line)),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: danger ? AppColors.red : AppColors.text,
              size: 20,
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: danger ? AppColors.red : AppColors.text,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
          ],
        ),
      ),
    );
  }
}

class JeevanNavBar extends StatelessWidget {
  const JeevanNavBar({
    super.key,
    required this.selectedIndex,
    required this.onChanged,
  });

  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .08),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 74,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              NavItem(
                icon: Icons.home_rounded,
                label: 'Home',
                selected: selectedIndex == 0,
                onTap: () => onChanged(0),
              ),
              NavItem(
                icon: Icons.calendar_month_outlined,
                label: 'Appointments',
                selected: selectedIndex == 1,
                onTap: () => onChanged(1),
              ),
              Transform.translate(
                offset: const Offset(0, -18),
                child: InkWell(
                  borderRadius: BorderRadius.circular(34),
                  onTap: () => onChanged(2),
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [AppColors.red2, AppColors.red],
                      ),
                      border: Border.all(color: Colors.white, width: 6),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.red.withValues(alpha: .25),
                          blurRadius: 18,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        'SOS',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              NavItem(
                icon: Icons.chat_bubble_outline_rounded,
                label: 'Messages',
                selected: selectedIndex == 3,
                onTap: () => onChanged(3),
              ),
              NavItem(
                icon: Icons.person_outline_rounded,
                label: 'Profile',
                selected: selectedIndex == 4,
                onTap: () => onChanged(4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NavItem extends StatelessWidget {
  const NavItem({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.navy : AppColors.muted;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: SizedBox(
        width: 68,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({super.key, required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: FilledButton(
        onPressed: onTap ?? () {},
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.navy,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w900)),
      ),
    );
  }
}

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.margin,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );

    if (onTap == null) {
      return card;
    }

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: card,
    );
  }
}
