import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show User;
import 'package:url_launcher/url_launcher.dart';

import 'supabase_config.dart';
import 'supabase_models.dart';
import 'supabase_service.dart';

final appLocation = AppLocationController();
final appData = AppDataController();
final liveHealthData = LiveHealthDataController();

class AppTextEntry {
  const AppTextEntry({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.attachmentName = '',
    this.attachmentType = '',
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String attachmentName;
  final String attachmentType;

  Map<String, dynamic> toJson() => {
    'title': title,
    'subtitle': subtitle,
    'icon': icon.codePoint,
    'color': color.toARGB32(),
    'attachmentName': attachmentName,
    'attachmentType': attachmentType,
  };

  factory AppTextEntry.fromJson(Map<String, dynamic> map) {
    return AppTextEntry(
      title: map['title']?.toString() ?? '',
      subtitle: map['subtitle']?.toString() ?? '',
      icon: materialIconFromCode(
        (map['icon'] as num?)?.toInt(),
        Icons.description_rounded,
      ),
      color: Color(
        (map['color'] as num?)?.toInt() ?? AppColors.blue.toARGB32(),
      ),
      attachmentName: map['attachmentName']?.toString() ?? '',
      attachmentType: map['attachmentType']?.toString() ?? '',
    );
  }
}

class EmergencyContactEntry {
  const EmergencyContactEntry({
    required this.name,
    required this.phone,
    required this.relation,
  });

  final String name;
  final String phone;
  final String relation;

  Map<String, dynamic> toJson() => {
    'name': name,
    'phone': phone,
    'relation': relation,
  };

  factory EmergencyContactEntry.fromJson(Map<String, dynamic> map) {
    return EmergencyContactEntry(
      name: map['name']?.toString() ?? '',
      phone: map['phone']?.toString() ?? '',
      relation: map['relation']?.toString() ?? '',
    );
  }
}

class ChatMessageEntry {
  const ChatMessageEntry({
    required this.sender,
    required this.body,
    required this.time,
    this.fromUser = false,
  });

  final String sender;
  final String body;
  final String time;
  final bool fromUser;

  Map<String, dynamic> toJson() => {
    'sender': sender,
    'body': body,
    'time': time,
    'fromUser': fromUser,
  };

  factory ChatMessageEntry.fromJson(Map<String, dynamic> map) {
    return ChatMessageEntry(
      sender: map['sender']?.toString() ?? '',
      body: map['body']?.toString() ?? '',
      time: map['time']?.toString() ?? '',
      fromUser: map['fromUser'] == true,
    );
  }
}

class MessageThreadEntry {
  const MessageThreadEntry({
    required this.name,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.messages,
  });

  final String name;
  final String subtitle;
  final IconData icon;
  final Color color;
  final List<ChatMessageEntry> messages;

  Map<String, dynamic> toJson() => {
    'name': name,
    'subtitle': subtitle,
    'icon': icon.codePoint,
    'color': color.toARGB32(),
    'messages': messages.map((message) => message.toJson()).toList(),
  };

  factory MessageThreadEntry.fromJson(Map<String, dynamic> map) {
    final rawMessages = map['messages'];
    return MessageThreadEntry(
      name: map['name']?.toString() ?? '',
      subtitle: map['subtitle']?.toString() ?? '',
      icon: materialIconFromCode(
        (map['icon'] as num?)?.toInt(),
        Icons.chat_bubble_outline_rounded,
      ),
      color: Color(
        (map['color'] as num?)?.toInt() ?? AppColors.navy.toARGB32(),
      ),
      messages: rawMessages is List
          ? rawMessages
                .whereType<Map>()
                .map(
                  (item) =>
                      ChatMessageEntry.fromJson(item.cast<String, dynamic>()),
                )
                .toList()
          : <ChatMessageEntry>[],
    );
  }
}

class UserAppointmentEntry {
  const UserAppointmentEntry({
    required this.doctorName,
    required this.specialty,
    required this.dateLabel,
    required this.timeLabel,
    required this.reason,
  });

  final String doctorName;
  final String specialty;
  final String dateLabel;
  final String timeLabel;
  final String reason;

  Map<String, dynamic> toJson() => {
    'doctorName': doctorName,
    'specialty': specialty,
    'dateLabel': dateLabel,
    'timeLabel': timeLabel,
    'reason': reason,
  };

  factory UserAppointmentEntry.fromJson(Map<String, dynamic> map) {
    return UserAppointmentEntry(
      doctorName: map['doctorName']?.toString() ?? '',
      specialty: map['specialty']?.toString() ?? '',
      dateLabel: map['dateLabel']?.toString() ?? '',
      timeLabel: map['timeLabel']?.toString() ?? '',
      reason: map['reason']?.toString() ?? '',
    );
  }
}

class EmergencyCabRequestEntry {
  const EmergencyCabRequestEntry({
    required this.pickup,
    required this.dropLocation,
    required this.hospitalName,
    required this.hospitalPhone,
    required this.status,
    required this.etaMinutes,
    required this.driverName,
    required this.createdAtLabel,
    required this.rideType,
    required this.paymentMethod,
    this.backendRideId = '',
    this.fareLabel = '',
  });

  final String pickup;
  final String dropLocation;
  final String hospitalName;
  final String hospitalPhone;
  final String status;
  final int etaMinutes;
  final String driverName;
  final String createdAtLabel;
  final String rideType;
  final String paymentMethod;
  final String backendRideId;
  final String fareLabel;

  Map<String, dynamic> toJson() => {
    'pickup': pickup,
    'dropLocation': dropLocation,
    'hospitalName': hospitalName,
    'hospitalPhone': hospitalPhone,
    'status': status,
    'etaMinutes': etaMinutes,
    'driverName': driverName,
    'createdAtLabel': createdAtLabel,
    'rideType': rideType,
    'paymentMethod': paymentMethod,
    'backendRideId': backendRideId,
    'fareLabel': fareLabel,
  };

  factory EmergencyCabRequestEntry.fromJson(Map<String, dynamic> map) {
    return EmergencyCabRequestEntry(
      pickup: map['pickup']?.toString() ?? '',
      dropLocation: map['dropLocation']?.toString() ?? '',
      hospitalName: map['hospitalName']?.toString() ?? '',
      hospitalPhone: map['hospitalPhone']?.toString() ?? '',
      status: map['status']?.toString() ?? 'Requested',
      etaMinutes: (map['etaMinutes'] as num?)?.toInt() ?? 5,
      driverName: map['driverName']?.toString() ?? 'Emergency cab partner',
      createdAtLabel: map['createdAtLabel']?.toString() ?? '',
      rideType: map['rideType']?.toString() ?? 'Hatchback',
      paymentMethod: map['paymentMethod']?.toString() ?? 'Cash',
      backendRideId: map['backendRideId']?.toString() ?? '',
      fareLabel: map['fareLabel']?.toString() ?? '',
    );
  }
}

IconData materialIconFromCode(int? code, IconData fallback) {
  if (code == Icons.science_rounded.codePoint) return Icons.science_rounded;
  if (code == Icons.medication_rounded.codePoint) {
    return Icons.medication_rounded;
  }
  if (code == Icons.warning_amber_rounded.codePoint) {
    return Icons.warning_amber_rounded;
  }
  if (code == Icons.monitor_heart_rounded.codePoint) {
    return Icons.monitor_heart_rounded;
  }
  if (code == Icons.home_work_rounded.codePoint) {
    return Icons.home_work_rounded;
  }
  if (code == Icons.notifications_active_rounded.codePoint) {
    return Icons.notifications_active_rounded;
  }
  if (code == Icons.chat_bubble_outline_rounded.codePoint) {
    return Icons.chat_bubble_outline_rounded;
  }
  if (code == Icons.calendar_month_rounded.codePoint) {
    return Icons.calendar_month_rounded;
  }
  if (code == Icons.folder_copy_rounded.codePoint) {
    return Icons.folder_copy_rounded;
  }
  if (code == Icons.description_rounded.codePoint) {
    return Icons.description_rounded;
  }
  if (code == Icons.location_on_rounded.codePoint) {
    return Icons.location_on_rounded;
  }
  if (code == Icons.settings_rounded.codePoint) {
    return Icons.settings_rounded;
  }
  return fallback;
}

class AppDataController extends ChangeNotifier {
  static const _storageKey = 'jeevan_arogya_app_data_v3';

  final healthRecords = <AppTextEntry>[];
  final prescriptions = <AppTextEntry>[];
  final allergies = <AppTextEntry>[];
  final vitals = <AppTextEntry>[];
  final addresses = <AppTextEntry>[];
  final notifications = <AppTextEntry>[];
  final emergencyContacts = <EmergencyContactEntry>[];
  final threads = <MessageThreadEntry>[];
  final appointments = <UserAppointmentEntry>[];
  final cabRequests = <EmergencyCabRequestEntry>[];
  String profileName = '';
  String profileEmail = '';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      return;
    }
    try {
      final data = jsonDecode(raw);
      if (data is! Map<String, dynamic>) {
        return;
      }
      _loadEntries(healthRecords, data['healthRecords']);
      _loadEntries(prescriptions, data['prescriptions']);
      _loadEntries(allergies, data['allergies']);
      _loadEntries(vitals, data['vitals']);
      _loadEntries(addresses, data['addresses']);
      _loadEntries(notifications, data['notifications']);
      emergencyContacts
        ..clear()
        ..addAll(
          _decodeList(
            data['emergencyContacts'],
          ).map(EmergencyContactEntry.fromJson),
        );
      threads
        ..clear()
        ..addAll(_decodeList(data['threads']).map(MessageThreadEntry.fromJson));
      appointments
        ..clear()
        ..addAll(
          _decodeList(data['appointments']).map(UserAppointmentEntry.fromJson),
        );
      cabRequests
        ..clear()
        ..addAll(
          _decodeList(
            data['cabRequests'],
          ).map(EmergencyCabRequestEntry.fromJson),
        );
      profileName = data['profileName']?.toString() ?? '';
      profileEmail = data['profileEmail']?.toString() ?? '';
    } catch (_) {
      return;
    }
  }

  List<Map<String, dynamic>> _decodeList(Object? value) {
    if (value is! List) {
      return const [];
    }
    return value
        .whereType<Map>()
        .map((item) => item.cast<String, dynamic>())
        .toList();
  }

  void _loadEntries(List<AppTextEntry> target, Object? value) {
    target
      ..clear()
      ..addAll(_decodeList(value).map(AppTextEntry.fromJson));
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode({
        'healthRecords': healthRecords.map((entry) => entry.toJson()).toList(),
        'prescriptions': prescriptions.map((entry) => entry.toJson()).toList(),
        'allergies': allergies.map((entry) => entry.toJson()).toList(),
        'vitals': vitals.map((entry) => entry.toJson()).toList(),
        'addresses': addresses.map((entry) => entry.toJson()).toList(),
        'notifications': notifications.map((entry) => entry.toJson()).toList(),
        'emergencyContacts': emergencyContacts
            .map((contact) => contact.toJson())
            .toList(),
        'threads': threads.map((thread) => thread.toJson()).toList(),
        'appointments': appointments
            .map((appointment) => appointment.toJson())
            .toList(),
        'cabRequests': cabRequests.map((request) => request.toJson()).toList(),
        'profileName': profileName,
        'profileEmail': profileEmail,
      }),
    );
  }

  void _changed() {
    unawaited(_save());
    notifyListeners();
  }

  void addEntry(List<AppTextEntry> target, AppTextEntry entry) {
    target.insert(0, entry);
    _changed();
  }

  void addEmergencyContact(EmergencyContactEntry contact) {
    emergencyContacts.insert(0, contact);
    _changed();
  }

  void addAppointment(UserAppointmentEntry appointment) {
    appointments.insert(0, appointment);
    _ensureThread(
      name: 'Appointments',
      subtitle: 'Doctor bookings',
      icon: Icons.calendar_month_rounded,
      color: AppColors.blue,
    ).messages.add(
      ChatMessageEntry(
        sender: 'Jeevan Arogya',
        body:
            '${appointment.doctorName} appointment booked for ${appointment.dateLabel}, ${appointment.timeLabel}.',
        time: 'Now',
      ),
    );
    _changed();
  }

  void addCabRequest(EmergencyCabRequestEntry request) {
    cabRequests.insert(0, request);
    _ensureThread(
      name: 'Emergency Cab',
      subtitle: 'Cab requests and hospital rides',
      icon: Icons.local_taxi_rounded,
      color: const Color(0xFFFF9800),
    ).messages.add(
      ChatMessageEntry(
        sender: 'Jeevan Arogya',
        body:
            '${request.status}: ${request.driverName} to ${request.dropLocation}. ETA ${request.etaMinutes} min.',
        time: 'Now',
      ),
    );
    _changed();
  }

  void saveProfile(String name, String email) {
    profileName = name;
    profileEmail = email;
    _changed();
  }

  void clearLoginSession() {
    profileName = '';
    profileEmail = '';
    _changed();
  }

  void createThread({
    required String name,
    required String subtitle,
    required String body,
  }) {
    threads.insert(
      0,
      MessageThreadEntry(
        name: name,
        subtitle: subtitle,
        icon: Icons.chat_bubble_outline_rounded,
        color: AppColors.navy,
        messages: [
          ChatMessageEntry(
            sender: 'You',
            body: body,
            time: 'Now',
            fromUser: true,
          ),
        ],
      ),
    );
    _changed();
  }

  void addMessage(int threadIndex, String body) {
    if (threadIndex < 0 || threadIndex >= threads.length) {
      return;
    }
    threads[threadIndex].messages.add(
      ChatMessageEntry(sender: 'You', body: body, time: 'Now', fromUser: true),
    );
    _changed();
  }

  MessageThreadEntry _ensureThread({
    required String name,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    final index = threads.indexWhere((thread) => thread.name == name);
    if (index != -1) {
      return threads[index];
    }
    final thread = MessageThreadEntry(
      name: name,
      subtitle: subtitle,
      icon: icon,
      color: color,
      messages: [],
    );
    threads.insert(0, thread);
    return thread;
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.initialize();
  await appData.load();
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
  Doctor(
    name: 'Dr. Ritu Sengar',
    specialty: 'Gynecologist',
    experience: '12+ Years Exp.',
    degree: 'MBBS, MS',
    fee: 'Rs. 750',
    rating: '4.7',
    reviews: '112',
    nextSlot: 'Tomorrow, 09:30 AM',
    color: Color(0xFFFFEFF8),
  ),
  Doctor(
    name: 'Dr. Sameer Khan',
    specialty: 'Dentist',
    experience: '11+ Years Exp.',
    degree: 'BDS, MDS',
    fee: 'Rs. 450',
    rating: '4.6',
    reviews: '89',
    nextSlot: 'Today, 05:00 PM',
    color: Color(0xFFEAFBF3),
  ),
  Doctor(
    name: 'Dr. Meera Joshi',
    specialty: 'General Physician',
    experience: '14+ Years Exp.',
    degree: 'MBBS, MD Medicine',
    fee: 'Rs. 550',
    rating: '4.8',
    reviews: '176',
    nextSlot: 'Today, 12:30 PM',
    color: Color(0xFFE9F0F8),
  ),
  Doctor(
    name: 'Dr. Vivek Tiwari',
    specialty: 'ENT',
    experience: '9+ Years Exp.',
    degree: 'MBBS, MS ENT',
    fee: 'Rs. 600',
    rating: '4.5',
    reviews: '72',
    nextSlot: 'Tomorrow, 03:30 PM',
    color: Color(0xFFE7F4FF),
  ),
  Doctor(
    name: 'Dr. Priyanka Rao',
    specialty: 'Neurologist',
    experience: '13+ Years Exp.',
    degree: 'MBBS, DM Neurology',
    fee: 'Rs. 1000',
    rating: '4.9',
    reviews: '141',
    nextSlot: 'Sat, 11:00 AM',
    color: Color(0xFFF4F0FF),
  ),
  Doctor(
    name: 'Dr. Amit Chouhan',
    specialty: 'Cardiologist',
    experience: '16+ Years Exp.',
    degree: 'MBBS, DM Cardiology',
    fee: 'Rs. 1200',
    rating: '4.9',
    reviews: '204',
    nextSlot: 'Today, 06:30 PM',
    color: Color(0xFFEAFBF3),
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
    this.latitude,
    this.longitude,
    this.source = '',
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
  final double? latitude;
  final double? longitude;
  final String source;

  LatLng? get latLng {
    final lat = latitude;
    final lng = longitude;
    if (lat == null || lng == null) {
      return null;
    }
    return LatLng(lat, lng);
  }
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

class LiveHealthDataController extends ChangeNotifier {
  final hospitals = <Hospital>[];
  final doctors = <Doctor>[];
  final kendras = <Place>[];
  bool loading = false;
  bool loaded = false;
  String? message;
  LatLng? _lastCenter;

  Future<void> loadFor(LatLng center) async {
    final last = _lastCenter;
    if (loading || (last != null && distanceKm(last, center) < 3 && loaded)) {
      return;
    }
    loading = true;
    message = 'Fetching live OpenStreetMap health data...';
    notifyListeners();

    try {
      final query = _overpassQuery(center);
      final response = await http
          .post(
            Uri.parse('https://overpass-api.de/api/interpreter'),
            headers: {
              'Content-Type': 'text/plain; charset=utf-8',
              'User-Agent': 'JeevanArogya/1.0',
            },
            body: query,
          )
          .timeout(const Duration(seconds: 35));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw StateError('OpenStreetMap server ${response.statusCode}');
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Invalid OpenStreetMap response');
      }
      _applyElements(decoded['elements'], center);
      loaded = true;
      _lastCenter = center;
      message =
          'Live data: ${hospitals.length} hospitals, ${doctors.length} doctors, ${kendras.length} Jan Aushadhi/pharmacies.';
    } catch (error) {
      loaded = true;
      message = 'Live data unavailable: $error';
      hospitals.clear();
      doctors.clear();
      kendras.clear();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  List<Hospital> nearbyHospitals(LatLng center) {
    return [...hospitals]..sort(
      (a, b) =>
          distanceKm(center, a.latLng).compareTo(distanceKm(center, b.latLng)),
    );
  }

  List<Doctor> nearbyDoctors(LatLng center) {
    return [...doctors]..sort((a, b) {
      final aPoint = a.latLng;
      final bPoint = b.latLng;
      if (aPoint == null || bPoint == null) {
        return a.name.compareTo(b.name);
      }
      return distanceKm(center, aPoint).compareTo(distanceKm(center, bPoint));
    });
  }

  List<Place> nearbyKendras(LatLng center) {
    return [...kendras]..sort(
      (a, b) =>
          distanceKm(center, a.latLng).compareTo(distanceKm(center, b.latLng)),
    );
  }

  String _overpassQuery(LatLng center) {
    final lat = center.latitude.toStringAsFixed(6);
    final lng = center.longitude.toStringAsFixed(6);
    return '''
[out:json][timeout:30];
(
  node["amenity"~"hospital|doctors|pharmacy"](around:25000,$lat,$lng);
  way["amenity"~"hospital|doctors|pharmacy"](around:25000,$lat,$lng);
  relation["amenity"~"hospital|doctors|pharmacy"](around:25000,$lat,$lng);
  node["healthcare"~"hospital|doctor|pharmacy"](around:25000,$lat,$lng);
  way["healthcare"~"hospital|doctor|pharmacy"](around:25000,$lat,$lng);
  relation["healthcare"~"hospital|doctor|pharmacy"](around:25000,$lat,$lng);
);
out center 1500;
''';
  }

  void _applyElements(Object? rawElements, LatLng center) {
    hospitals.clear();
    doctors.clear();
    kendras.clear();
    final seenHospitals = <String>{};
    final seenDoctors = <String>{};
    final seenKendras = <String>{};

    if (rawElements is! List) {
      return;
    }

    for (final raw in rawElements.whereType<Map>()) {
      final item = raw.cast<String, dynamic>();
      final tags = item['tags'] is Map
          ? (item['tags'] as Map).cast<String, dynamic>()
          : <String, dynamic>{};
      final point = _elementPoint(item);
      if (point == null) {
        continue;
      }
      final name = _cleanName(
        tags['name'] ??
            tags['operator'] ??
            tags['brand'] ??
            tags['official_name'],
      );
      if (name.isEmpty) {
        continue;
      }
      final amenity = tags['amenity']?.toString().toLowerCase() ?? '';
      final healthcare = tags['healthcare']?.toString().toLowerCase() ?? '';
      final lowerName = name.toLowerCase();
      final phone = _cleanName(
        tags['phone'] ?? tags['contact:phone'] ?? tags['mobile'],
      );
      final openingHours = _cleanName(tags['opening_hours']);

      final isHospital = amenity == 'hospital' || healthcare == 'hospital';
      final isDoctor = amenity == 'doctors' || healthcare == 'doctor';
      final isPharmacy = amenity == 'pharmacy' || healthcare == 'pharmacy';
      final isJanAushadhi =
          lowerName.contains('jan aushadhi') ||
          lowerName.contains('janaushadhi') ||
          lowerName.contains('jan aushadi') ||
          lowerName.contains('generic medicine');

      if (isHospital) {
        final key = _placeKey(name, point);
        if (seenHospitals.add(key)) {
          hospitals.add(
            Hospital(
              name,
              formatDistanceKm(distanceKm(center, point)),
              openingHours.contains('24/7') ? '24x7 Open' : 'OpenStreetMap',
              latitude: point.latitude,
              longitude: point.longitude,
              phone: phone.isEmpty ? '+91108' : phone,
            ),
          );
        }
      }

      if (isDoctor) {
        final key = _placeKey(name, point);
        if (seenDoctors.add(key)) {
          final speciality = _specialityFromTags(tags, amenity, healthcare);
          doctors.add(
            Doctor(
              name: name,
              specialty: speciality,
              experience: 'Verified on OpenStreetMap',
              degree: phone.isEmpty ? 'Call doctor for details' : phone,
              fee: 'Call',
              rating: 'Live',
              reviews: 'OSM',
              nextSlot: 'Call to confirm',
              color: isLikelyFemaleDoctorName(name)
                  ? const Color(0xFFFFEFF8)
                  : const Color(0xFFE7F4FF),
              latitude: point.latitude,
              longitude: point.longitude,
              source: 'OpenStreetMap',
            ),
          );
        }
      }

      if (isPharmacy && isJanAushadhi) {
        final key = _placeKey(name, point);
        if (seenKendras.add(key)) {
          kendras.add(
            Place(
              name,
              formatDistanceKm(distanceKm(center, point)),
              _cleanName(tags['addr:suburb'] ?? tags['addr:city']).isEmpty
                  ? 'OpenStreetMap'
                  : _cleanName(tags['addr:suburb'] ?? tags['addr:city']),
              latitude: point.latitude,
              longitude: point.longitude,
              phone: phone.isEmpty ? '+91108' : phone,
            ),
          );
        }
      }
    }
  }

  LatLng? _elementPoint(Map<String, dynamic> item) {
    final lat =
        (item['lat'] as num?)?.toDouble() ??
        (item['center'] is Map
            ? ((item['center'] as Map)['lat'] as num?)?.toDouble()
            : null);
    final lng =
        (item['lon'] as num?)?.toDouble() ??
        (item['center'] is Map
            ? ((item['center'] as Map)['lon'] as num?)?.toDouble()
            : null);
    if (lat == null || lng == null) {
      return null;
    }
    return LatLng(lat, lng);
  }

  String _cleanName(Object? value) {
    return value?.toString().replaceAll(RegExp(r'\s+'), ' ').trim() ?? '';
  }

  String _placeKey(String name, LatLng point) {
    return '${name.toLowerCase()}-${point.latitude.toStringAsFixed(4)}-${point.longitude.toStringAsFixed(4)}';
  }

  String _specialityFromTags(
    Map<String, dynamic> tags,
    String amenity,
    String healthcare,
  ) {
    final raw = _cleanName(
      tags['healthcare:speciality'] ??
          tags['speciality'] ??
          tags['healthcare:specialty'],
    );
    if (raw.isEmpty) {
      return 'Doctor';
    }
    return raw
        .split(';')
        .map((part) => part.replaceAll('_', ' ').trim())
        .where((part) => part.isNotEmpty)
        .map((part) => part.substring(0, 1).toUpperCase() + part.substring(1))
        .join(', ');
  }
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
      unawaited(liveHealthData.loadFor(_current));
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

bool isLikelyFemaleDoctorName(String name) {
  final lower = name.toLowerCase();
  const femaleMarkers = [
    'ananya',
    'neha',
    'ritu',
    'meera',
    'priyanka',
    'priya',
    'pooja',
    'shreya',
    'swati',
    'sonal',
    'sonia',
    'mrs',
    'ms.',
    'dr. mrs',
  ];
  return femaleMarkers.any(lower.contains);
}

String friendlyAuthError(Object error) {
  var text = error.toString().replaceFirst('AuthException(message: ', '');
  for (final prefix in ['Bad state:', 'Exception:', 'StateError:']) {
    if (text.toLowerCase().startsWith(prefix.toLowerCase())) {
      text = text.substring(prefix.length).trim();
    }
  }
  if (text.toLowerCase().contains('otp') ||
      text.toLowerCase().contains('email')) {
    return '$text Check EMAIL_OTP_SERVICE_URL and your deployed email OTP service.';
  }
  if (text.toLowerCase().contains('invalid parameters')) {
    return 'Invalid email OTP parameters. Check service URL and email input.';
  }
  return text;
}

class AppUserProfile {
  const AppUserProfile({required this.name, required this.phone});

  final String name;
  final String phone;

  String get firstName {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return 'User';
    }
    return trimmed.split(RegExp(r'\s+')).first;
  }

  String get initial {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return 'U';
    }
    return trimmed.substring(0, 1).toUpperCase();
  }

  static AppUserProfile fromUser(User? user) {
    final metadata = user?.userMetadata ?? {};
    final name = (metadata['full_name'] ?? metadata['name'] ?? '')
        .toString()
        .trim();
    final phone = (user?.email ?? metadata['email'] ?? metadata['phone'] ?? '')
        .toString()
        .trim();
    return AppUserProfile(
      name: name.isEmpty ? 'User' : name,
      phone: phone.isEmpty ? 'Email verified' : phone,
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final JeevanArogyaRepository _repository = JeevanArogyaRepository();
  StreamSubscription? _authSubscription;
  late bool _loggedIn =
      _repository.currentUser != null || appData.profileEmail.isNotEmpty;
  late AppUserProfile _profile = _repository.currentUser != null
      ? AppUserProfile.fromUser(_repository.currentUser)
      : AppUserProfile(
          name: appData.profileName.isEmpty ? 'User' : appData.profileName,
          phone: appData.profileEmail,
        );

  @override
  void initState() {
    super.initState();
    _authSubscription = _repository.authStateChanges.listen((state) {
      if (!mounted) {
        return;
      }
      setState(() {
        if (state.session?.user != null) {
          _profile = AppUserProfile.fromUser(state.session!.user);
          appData.saveProfile(_profile.name, _profile.phone);
          _loggedIn = true;
        } else {
          _loggedIn = appData.profileEmail.isNotEmpty;
        }
      });
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  void _enterApp(AppUserProfile profile) {
    appData.saveProfile(profile.name, profile.phone);
    setState(() {
      _profile = profile;
      _loggedIn = true;
    });
  }

  Future<void> _logout() async {
    await _repository.signOut();
    appData.clearLoginSession();
    if (!mounted) {
      return;
    }
    setState(() => _loggedIn = false);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 520),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: _loggedIn
          ? AppShell(
              key: const ValueKey('app-shell'),
              profile: _profile,
              onLogout: _logout,
            )
          : LandingScreen(
              key: const ValueKey('landing-screen'),
              repository: _repository,
              onLogin: _enterApp,
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
  final ValueChanged<AppUserProfile> onLogin;

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final TextEditingController _nameController = TextEditingController();
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
    _nameController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final name = _nameController.text.trim();
    final email = _phoneController.text.trim();
    if (name.length < 2) {
      setState(() {
        _authMessage = 'Please enter your name.';
      });
      return;
    }
    if (!email.contains('@') || !email.contains('.')) {
      setState(() {
        _authMessage = 'Please enter a valid email address.';
      });
      return;
    }

    setState(() {
      _authBusy = true;
      _authMessage = null;
    });

    try {
      if (widget.repository.isConnected) {
        final normalizedEmail = await widget.repository.sendEmailOtp(
          email: email,
          fullName: name,
        );
        setState(() {
          _otpSent = true;
          _authMessage = 'OTP sent to $normalizedEmail. Enter the code.';
          _otp = '';
          _otpController.clear();
        });
      } else {
        setState(() {
          _otpSent = false;
          _otp = '';
          _otpController.clear();
          _authMessage =
              'OTP service is not configured on this build. Add Supabase keys.';
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
            _authMessage = 'Please enter the email OTP.';
          });
          return;
        }

        final hasSupabaseSession = await widget.repository.verifyEmailOtp(
          email: _phoneController.text,
          token: token,
        );
        final profile = AppUserProfile(
          name: _nameController.text.trim(),
          phone: widget.repository.normalizeEmail(_phoneController.text),
        );
        if (hasSupabaseSession) {
          try {
            await widget.repository.upsertProfile(
              fullName: profile.name,
              phone: profile.phone,
            );
          } catch (_) {
            // Auth succeeded; profile sync can be retried after database setup.
          }
        }
        widget.onLogin(profile);
      } else {
        setState(() {
          _authMessage =
              'OTP service is not configured on this build. Add Supabase keys.';
        });
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
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final loginPanel = LoginPanel(
                    nameController: _nameController,
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
                  );
                  if (constraints.maxWidth >= 900) {
                    return Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const LandingTopBar(),
                          const SizedBox(height: 22),
                          Expanded(
                            child: Row(
                              children: [
                                const Expanded(
                                  flex: 6,
                                  child: LandingHero(expanded: true),
                                ),
                                const SizedBox(width: 28),
                                Expanded(
                                  flex: 5,
                                  child: Center(
                                    child: ConstrainedBox(
                                      constraints: const BoxConstraints(
                                        maxWidth: 460,
                                      ),
                                      child: loginPanel,
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
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
                    children: [
                      const LandingTopBar(),
                      const SizedBox(height: 26),
                      const LandingHero(),
                      const SizedBox(height: 24),
                      loginPanel,
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
  const LandingHero({super.key, this.expanded = false});

  final bool expanded;

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
              const LiveNetworkTextBadge(),
              const Spacer(),
              const Icon(Icons.auto_awesome_rounded, color: AppColors.gold),
            ],
          ),
          SizedBox(height: expanded ? 42 : 22),
          Text(
            'Healthcare help,\nright when life\nneeds speed.',
            style: TextStyle(
              color: AppColors.text,
              fontSize: expanded ? 54 : 34,
              height: 1.02,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Find doctors, book appointments, trigger SOS alerts, request emergency cabs, and locate affordable medicines from one smart app.',
            style: TextStyle(
              color: AppColors.muted,
              fontSize: expanded ? 17 : 14,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class LiveNetworkTextBadge extends StatefulWidget {
  const LiveNetworkTextBadge({super.key});

  @override
  State<LiveNetworkTextBadge> createState() => _LiveNetworkTextBadgeState();
}

class _LiveNetworkTextBadgeState extends State<LiveNetworkTextBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    )..repeat();
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
        final glow = .5 + math.sin(_controller.value * math.pi * 2) * .5;
        return CustomPaint(
          painter: _LiveNetworkBadgePainter(progress: _controller.value),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF8EF),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: AppColors.green.withValues(alpha: .18 + glow * .18),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.green.withValues(alpha: .09 + glow * .11),
                  blurRadius: 16 + glow * 10,
                  spreadRadius: glow * 1.2,
                ),
              ],
            ),
            child: const Text(
              'Live emergency network',
              style: TextStyle(
                color: AppColors.green,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _LiveNetworkBadgePainter extends CustomPainter {
  const _LiveNetworkBadgePainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    for (final offset in const [0.0, .34, .68]) {
      final p = (progress + offset) % 1;
      final alpha = (1 - p) * .16;
      final inflated = 2 + p * 16;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = AppColors.green.withValues(alpha: alpha);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          rect.inflate(inflated),
          Radius.circular(22 + inflated),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LiveNetworkBadgePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class LiveSignalIcon extends StatefulWidget {
  const LiveSignalIcon({super.key});

  @override
  State<LiveSignalIcon> createState() => _LiveSignalIconState();
}

class _LiveSignalIconState extends State<LiveSignalIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
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
      width: 22,
      height: 22,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Stack(
            alignment: Alignment.center,
            children: [
              for (final offset in [0.0, .34, .68])
                _SignalRing(progress: (_controller.value + offset) % 1),
              const Icon(
                Icons.sensors_rounded,
                color: AppColors.green,
                size: 15,
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.green,
                  shape: BoxShape.circle,
                ),
                child: SizedBox(width: 4, height: 4),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SignalRing extends StatelessWidget {
  const _SignalRing({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final size = 7 + progress * 18;
    final opacity = (1 - progress).clamp(0.0, 1.0) * .55;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.green.withValues(alpha: opacity),
          width: 1.5,
        ),
      ),
    );
  }
}

class LoginPanel extends StatelessWidget {
  const LoginPanel({
    super.key,
    required this.nameController,
    required this.phoneController,
    required this.otpController,
    required this.otpSent,
    required this.otp,
    required this.busy,
    required this.connected,
    required this.animation,
    required this.onSendOtp,
    required this.onLogin,
    this.message,
  });

  final TextEditingController nameController;
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
                    'Login securely with email OTP',
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
                    controller: nameController,
                    textCapitalization: TextCapitalization.words,
                    keyboardType: TextInputType.name,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(
                        Icons.person_rounded,
                        color: AppColors.green,
                      ),
                      hintText: 'Your full name',
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
                          color: AppColors.green,
                          width: 1.4,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(
                        Icons.alternate_email_rounded,
                        color: AppColors.blue,
                      ),
                      hintText: 'Email address',
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
                Icon(
                  Icons.alternate_email_rounded,
                  size: 17,
                  color: Colors.white,
                ),
                SizedBox(width: 7),
                Flexible(
                  child: Text(
                    'Email OTP Login',
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
              connected ? 'Supabase connected' : 'OTP service not configured',
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
  const AppShell({super.key, required this.profile, required this.onLogout});

  final AppUserProfile profile;
  final Future<void> Function() onLogout;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  var _index = 0;
  late AppUserProfile _profile = widget.profile;

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(profile: _profile, onLogout: widget.onLogout),
      const AppointmentsScreen(),
      const SizedBox.shrink(),
      const MessagesScreen(),
      ProfileScreen(
        profile: _profile,
        onLogout: widget.onLogout,
        onProfileChanged: (profile) => setState(() => _profile = profile),
      ),
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
  const HomeScreen({super.key, required this.profile, required this.onLogout});

  final AppUserProfile profile;
  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    return AppPage(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 112),
        children: [
          HomeHeader(profile: profile, onLogout: onLogout),
          const SizedBox(height: 30),
          Text(
            'Hello, ${profile.firstName}',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
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
          SearchBox(
            hint: 'Search doctors, hospitals, services...',
            onSubmitted: (query) {
              final trimmed = query.trim();
              if (trimmed.isEmpty) {
                return;
              }
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SearchResultsScreen(query: trimmed),
                ),
              );
            },
          ),
          AnimatedBuilder(
            animation: appLocation,
            builder: (context, _) {
              if (!appLocation.resolved) {
                return const SizedBox.shrink();
              }
              return const Padding(
                padding: EdgeInsets.only(top: 12),
                child: DoctorAvailabilityTicker(),
              );
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
                  MaterialPageRoute(
                    builder: (_) => EmergencyCabScreen(profile: profile),
                  ),
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
                    builder: (_) => HealthRecordsScreen(profile: profile),
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
            animation: Listenable.merge([appLocation, liveHealthData]),
            builder: (context, _) {
              if (!appLocation.resolved) {
                return const LocationRequiredPanel(
                  title: 'Enable GPS for nearby care',
                  subtitle:
                      'Nearby hospitals and emergency distances appear only after live GPS permission.',
                  icon: Icons.local_hospital_rounded,
                );
              }
              final nearby = liveHealthData.nearbyHospitals(
                appLocation.current,
              );
              if (liveHealthData.loading && nearby.isEmpty) {
                return const LiveHealthLoadingCard(
                  title: 'Fetching real hospitals',
                  subtitle:
                      'OpenStreetMap se live nearby hospitals load ho rahe hain.',
                );
              }
              if (nearby.isEmpty) {
                return const EmptyStateCard(
                  icon: Icons.local_hospital_outlined,
                  title: 'No verified live hospitals found',
                  subtitle:
                      'Refresh GPS or try again. Fake hospital entries are hidden.',
                );
              }
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
      animation: Listenable.merge([appLocation, liveHealthData]),
      builder: (context, _) {
        final nearestHospital = liveHealthData.nearbyHospitals(
          appLocation.current,
        );
        final hospital = nearestHospital.isEmpty ? null : nearestHospital.first;
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
                      hospital == null
                          ? (appLocation.resolved
                                ? 'Live hospital data will appear after fetch'
                                : 'Enable GPS to fetch real nearby care')
                          : '${hospital.name} - ${hospital.distanceFrom(appLocation.current)}',
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

class SearchShortcut {
  const SearchShortcut({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.builder,
    required this.terms,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final WidgetBuilder builder;
  final List<String> terms;
}

class SearchResultsScreen extends StatelessWidget {
  const SearchResultsScreen({super.key, required this.query});

  final String query;

  List<SearchShortcut> _allShortcuts() {
    return [
      SearchShortcut(
        title: 'Find Doctors',
        subtitle: 'Search specialists and book appointment slots',
        icon: Icons.medical_services_rounded,
        color: AppColors.blue,
        builder: (_) => const FindDoctorsScreen(),
        terms: const [
          'doctor',
          'doctors',
          'specialist',
          'cardiologist',
          'dentist',
          'pediatrician',
          'appointment',
        ],
      ),
      SearchShortcut(
        title: 'Emergency Cab',
        subtitle: 'Request a GPS-based ride to nearest hospital',
        icon: Icons.local_taxi_rounded,
        color: const Color(0xFFFF9800),
        builder: (_) => const EmergencyCabScreen(),
        terms: const [
          'cab',
          'taxi',
          'ride',
          'driver',
          'emergency cab',
          'ambulance',
        ],
      ),
      SearchShortcut(
        title: 'Nearby Hospitals',
        subtitle: 'Open live GPS map, call and directions',
        icon: Icons.local_hospital_rounded,
        color: AppColors.red,
        builder: (_) => const NearbyHospitalsScreen(),
        terms: const ['hospital', 'hospitals', 'nearby', '24x7'],
      ),
      SearchShortcut(
        title: 'Emergency SOS',
        subtitle: 'Trigger emergency alert and call your priority contact',
        icon: Icons.sos_rounded,
        color: AppColors.red,
        builder: (_) => const EmergencySosScreen(),
        terms: const ['sos', 'emergency', 'help', 'urgent', 'alert'],
      ),
      SearchShortcut(
        title: 'Jan Aushadhi Kendras',
        subtitle: 'Find affordable medicine stores near you',
        icon: Icons.medication_liquid_rounded,
        color: AppColors.green,
        builder: (_) => const JanAushadhiScreen(),
        terms: const [
          'jan aushadhi',
          'medicine',
          'pharmacy',
          'kendra',
          'generic',
        ],
      ),
      SearchShortcut(
        title: 'Health Schemes',
        subtitle: 'PM-JAY, CGHS, ESIC, ABHA and government portals',
        icon: Icons.health_and_safety_rounded,
        color: AppColors.green,
        builder: (_) => const HealthSchemesScreen(),
        terms: const [
          'scheme',
          'schemes',
          'ayushman',
          'pmjay',
          'cghs',
          'esic',
          'abha',
          'cowin',
        ],
      ),
    ];
  }

  bool _matchesShortcut(SearchShortcut shortcut, String q) {
    if (q.isEmpty) {
      return false;
    }
    final words = q.split(RegExp(r'\s+')).where((word) => word.length > 1);
    return shortcut.terms.any(
      (term) =>
          term.contains(q) ||
          q.contains(term) ||
          words.any((word) => term.contains(word) || word.contains(term)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final q = query.trim().toLowerCase();
    final doctorResults = liveHealthData.doctors
        .where(
          (doctor) =>
              doctor.name.toLowerCase().contains(q) ||
              doctor.specialty.toLowerCase().contains(q),
        )
        .toList();
    final hospitalResults = liveHealthData.hospitals
        .where(
          (hospital) =>
              hospital.name.toLowerCase().contains(q) ||
              hospital.status.toLowerCase().contains(q),
        )
        .toList();
    final kendraResults = liveHealthData.kendras
        .where(
          (place) =>
              place.name.toLowerCase().contains(q) ||
              place.area.toLowerCase().contains(q),
        )
        .toList();
    final allShortcuts = _allShortcuts();
    final shortcutResults = allShortcuts
        .where((shortcut) => _matchesShortcut(shortcut, q))
        .toList();
    final showSuggestions =
        doctorResults.isEmpty &&
        hospitalResults.isEmpty &&
        kendraResults.isEmpty &&
        shortcutResults.isEmpty;

    return Scaffold(
      body: AppPage(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
          children: [
            TopBar(title: 'Search: $query'),
            const SizedBox(height: 18),
            if (showSuggestions)
              const EmptyStateCard(
                icon: Icons.search_off_rounded,
                title: 'No exact result found',
                subtitle:
                    'You can still open these live services and continue from there.',
              ),
            if (showSuggestions) const SizedBox(height: 12),
            if (showSuggestions)
              for (final shortcut in allShortcuts)
                SearchShortcutCard(shortcut: shortcut),
            for (final shortcut in shortcutResults)
              SearchShortcutCard(shortcut: shortcut),
            for (final doctor in doctorResults)
              DoctorCard(
                doctor: doctor,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DoctorDetailScreen(doctor: doctor),
                  ),
                ),
              ),
            for (final hospital in hospitalResults)
              HospitalMiniCard(hospital: hospital, compact: true),
            for (final place in kendraResults) KendraCard(place: place),
          ],
        ),
      ),
    );
  }
}

class SearchShortcutCard extends StatelessWidget {
  const SearchShortcutCard({super.key, required this.shortcut});

  final SearchShortcut shortcut;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      onTap: () =>
          Navigator.push(context, MaterialPageRoute(builder: shortcut.builder)),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: shortcut.color.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(shortcut.icon, color: shortcut.color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  shortcut.title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  shortcut.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    height: 1.25,
                  ),
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

class LiveHealthLoadingCard extends StatelessWidget {
  const LiveHealthLoadingCard({
    super.key,
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(22),
      child: Row(
        children: [
          const SizedBox(
            width: 34,
            height: 34,
            child: CircularProgressIndicator(strokeWidth: 3),
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
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    height: 1.35,
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

class EmptyStateCard extends StatelessWidget {
  const EmptyStateCard({
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
    return AppCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.soft,
            child: Icon(icon, color: AppColors.navy),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.muted, height: 1.35),
          ),
        ],
      ),
    );
  }
}

class FindDoctorsScreen extends StatefulWidget {
  const FindDoctorsScreen({super.key});

  @override
  State<FindDoctorsScreen> createState() => _FindDoctorsScreenState();
}

class _FindDoctorsScreenState extends State<FindDoctorsScreen> {
  var _query = '';
  var _specialty = 'All';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppPage(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 112),
          children: [
            TopBar(
              title: 'Find Doctors',
              trailingIcon: Icons.tune_rounded,
              trailingOnTap: _showFilterSheet,
            ),
            const SizedBox(height: 24),
            SearchBox(
              hint: 'Search by name, specialization...',
              onChanged: (value) => setState(() => _query = value),
            ),
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
                    CategoryChips(
                      selectedLabel: _specialty,
                      onSelected: (value) => setState(() => _specialty = value),
                      labels: const [
                        'All',
                        'Doctor',
                        'Cardiologist',
                        'Orthopedic',
                        'General Physician',
                        'ENT',
                        'Neurologist',
                        'Dentist',
                        'Pediatrician',
                        'Gynecologist',
                        'Dermatologist',
                      ],
                    ),
                    const SizedBox(height: 16),
                    DoctorDirectoryList(
                      repository: JeevanArogyaRepository(),
                      query: _query,
                      specialty: _specialty,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Filter Doctors',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final label in [
                    'All',
                    'Doctor',
                    'Cardiologist',
                    'Orthopedic',
                    'General Physician',
                    'ENT',
                    'Neurologist',
                    'Pediatrician',
                    'Dermatologist',
                    'Dentist',
                    'Gynecologist',
                  ])
                    ChoiceChip(
                      label: Text(label),
                      selected: _specialty == label,
                      onSelected: (_) {
                        setState(() => _specialty = label);
                        Navigator.pop(context);
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DoctorDirectoryList extends StatelessWidget {
  const DoctorDirectoryList({
    super.key,
    required this.repository,
    required this.query,
    required this.specialty,
  });

  final JeevanArogyaRepository repository;
  final String query;
  final String specialty;

  List<Doctor> _filter(List<Doctor> source) {
    final q = query.trim().toLowerCase();
    return source
        .where(
          (doctor) =>
              specialty == 'All' ||
              doctor.specialty.toLowerCase() == specialty.toLowerCase(),
        )
        .where(
          (doctor) =>
              q.isEmpty ||
              doctor.name.toLowerCase().contains(q) ||
              doctor.specialty.toLowerCase().contains(q) ||
              doctor.degree.toLowerCase().contains(q),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: liveHealthData,
      builder: (context, _) {
        if (liveHealthData.loading && liveHealthData.doctors.isEmpty) {
          return const LiveHealthLoadingCard(
            title: 'Fetching real doctors',
            subtitle:
                'OpenStreetMap se live nearby doctor listings aa rahi hain.',
          );
        }
        final filteredDoctors = _filter(
          liveHealthData.nearbyDoctors(appLocation.current),
        );

        return Column(
          children: [
            const LiveDatabaseNotice(label: 'Live OpenStreetMap doctor data'),
            if (filteredDoctors.isEmpty)
              const EmptyStateCard(
                icon: Icons.person_search_rounded,
                title: 'No verified live doctors found',
                subtitle:
                    'Try All filter or refresh GPS. Fake doctor entries are hidden.',
              ),
            for (final doctor in filteredDoctors)
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
            AppointmentBookingPanel(doctor: doctor),
          ],
        ),
      ),
    );
  }
}

class AppointmentBookingPanel extends StatefulWidget {
  const AppointmentBookingPanel({super.key, required this.doctor});

  final Doctor doctor;

  @override
  State<AppointmentBookingPanel> createState() =>
      _AppointmentBookingPanelState();
}

class _AppointmentBookingPanelState extends State<AppointmentBookingPanel> {
  var _dateIndex = 0;
  var _timeIndex = 1;
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Next Available Slots',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 12),
        DateSlots(
          selectedIndex: _dateIndex,
          onSelected: (index) => setState(() => _dateIndex = index),
        ),
        const SizedBox(height: 12),
        TimeSlots(
          selectedIndex: _timeIndex,
          onSelected: (index) => setState(() => _timeIndex = index),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _reasonController,
          decoration: InputDecoration(
            hintText: 'Reason for visit',
            filled: true,
            fillColor: AppColors.soft,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 22),
        PrimaryButton(label: 'Book Appointment', onTap: _bookAppointment),
      ],
    );
  }

  Future<void> _bookAppointment() async {
    final date = appointmentDateOptions()[_dateIndex];
    final time = appointmentTimes[_timeIndex];
    final reason = _reasonController.text.trim().isEmpty
        ? 'General consultation'
        : _reasonController.text.trim();

    appData.addAppointment(
      UserAppointmentEntry(
        doctorName: widget.doctor.name,
        specialty: widget.doctor.specialty,
        dateLabel: '${date.$1}, ${date.$2}',
        timeLabel: time,
        reason: reason,
      ),
    );

    final repository = JeevanArogyaRepository();
    if (repository.isConnected && widget.doctor.id.isNotEmpty) {
      try {
        await repository.bookAppointment(
          doctorId: widget.doctor.id,
          slotTime: DateTime.now().add(Duration(days: _dateIndex, hours: 10)),
          reason: reason,
        );
      } catch (_) {
        // Local appointment is already saved; Supabase sync can retry later.
      }
    }

    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Appointment booked for ${widget.doctor.name} on ${date.$1} at $time.',
        ),
      ),
    );
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
  const EmergencyCabScreen({super.key, this.profile});

  final AppUserProfile? profile;

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
                animation: Listenable.merge([appLocation, liveHealthData]),
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
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final mapHeight = constraints.maxWidth >= 900
                          ? 430.0
                          : 360.0;
                      return ListView(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                        children: [
                          SizedBox(
                            height: mapHeight,
                            child: const MapPanel(mode: MapMode.route),
                          ),
                          const SizedBox(height: 14),
                          EmergencyRideCard(profile: profile),
                        ],
                      );
                    },
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
                trailingOnTap: () => showFilterInfo(
                  context,
                  'Hospitals are sorted by live GPS distance. Tap GPS to refresh nearest 24x7 care.',
                ),
                onBack: () => Navigator.pop(context),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: AnimatedBuilder(
                animation: Listenable.merge([appLocation, liveHealthData]),
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
                  final nearby = liveHealthData.nearbyHospitals(
                    appLocation.current,
                  );
                  if (liveHealthData.loading && nearby.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.fromLTRB(20, 0, 20, 26),
                      child: LiveHealthLoadingCard(
                        title: 'Fetching real hospitals',
                        subtitle:
                            'OpenStreetMap se user GPS ke aas-paas hospitals aa rahe hain.',
                      ),
                    );
                  }
                  if (nearby.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.fromLTRB(20, 0, 20, 26),
                      child: EmptyStateCard(
                        icon: Icons.local_hospital_outlined,
                        title: 'No verified live hospitals found',
                        subtitle:
                            'Refresh GPS and try again. Fake static entries are hidden.',
                      ),
                    );
                  }
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

class HealthSchemeInfo {
  const HealthSchemeInfo({
    required this.title,
    required this.subtitle,
    required this.department,
    required this.benefit,
    required this.eligibility,
    required this.documents,
    required this.actionLabel,
    required this.url,
    required this.icon,
    required this.color,
  });

  final String title;
  final String subtitle;
  final String department;
  final String benefit;
  final String eligibility;
  final List<String> documents;
  final String actionLabel;
  final String url;
  final IconData icon;
  final Color color;
}

const healthSchemeInfos = [
  HealthSchemeInfo(
    title: 'Ayushman Bharat PM-JAY',
    subtitle: 'Cashless hospital care up to Rs. 5,00,000',
    department: 'National Health Authority',
    benefit:
        'Cashless secondary and tertiary hospital treatment for eligible families.',
    eligibility:
        'Check eligibility through beneficiary portal using Aadhaar, mobile, PM-JAY ID, or family details.',
    documents: [
      'Aadhaar card',
      'Ration card or family ID',
      'Mobile number',
      'Hospital referral if required',
    ],
    actionLabel: 'Check Eligibility',
    url: 'https://beneficiary.nha.gov.in/',
    icon: Icons.health_and_safety_rounded,
    color: AppColors.green,
  ),
  HealthSchemeInfo(
    title: 'Jan Aushadhi Yojana',
    subtitle: 'Affordable generic medicines',
    department: 'Department of Pharmaceuticals',
    benefit:
        'Find low-cost quality generic medicines through Pradhan Mantri Bhartiya Janaushadhi Kendras.',
    eligibility:
        'Available to all citizens. Call nearest kendra to confirm medicine stock.',
    documents: [
      'Prescription if medicine requires it',
      'Medicine name or salt name',
    ],
    actionLabel: 'Open Portal',
    url: 'https://janaushadhi.gov.in/',
    icon: Icons.medication_liquid_rounded,
    color: Color(0xFFBFE9FF),
  ),
  HealthSchemeInfo(
    title: 'CGHS',
    subtitle: 'Central Government Health Scheme',
    department: 'Ministry of Health and Family Welfare',
    benefit:
        'OPD, medicines, diagnostics and empanelled hospital care for eligible central government beneficiaries.',
    eligibility:
        'Central government employees, pensioners and other notified beneficiary groups.',
    documents: [
      'CGHS card',
      'Government ID',
      'Referral or prescription when needed',
    ],
    actionLabel: 'CGHS Website',
    url: 'https://cghs.gov.in/',
    icon: Icons.local_hospital_rounded,
    color: Color(0xFFFFC9D0),
  ),
  HealthSchemeInfo(
    title: 'ESIC',
    subtitle: 'Employees State Insurance Scheme',
    department: 'Employees State Insurance Corporation',
    benefit:
        'Medical, sickness, maternity, disability and dependent benefits for covered workers.',
    eligibility:
        'Employees and families covered under ESIC contribution rules.',
    documents: [
      'ESIC insurance number',
      'Aadhaar or identity proof',
      'Employer details',
    ],
    actionLabel: 'ESIC Portal',
    url: 'https://www.esic.gov.in/',
    icon: Icons.verified_user_rounded,
    color: Color(0xFFFFD99C),
  ),
  HealthSchemeInfo(
    title: 'ABHA Health ID',
    subtitle: 'Digital health account',
    department: 'Ayushman Bharat Digital Mission',
    benefit:
        'Create a digital health ID to link and access health records securely.',
    eligibility:
        'Available to Indian residents with mobile/Aadhaar based verification.',
    documents: ['Mobile number', 'Aadhaar or driving licence if used'],
    actionLabel: 'Create ABHA',
    url: 'https://abha.abdm.gov.in/',
    icon: Icons.badge_rounded,
    color: Color(0xFFE6C8FF),
  ),
  HealthSchemeInfo(
    title: 'CoWIN',
    subtitle: 'Vaccination certificates and services',
    department: 'Ministry of Health and Family Welfare',
    benefit:
        'Access vaccination certificates and vaccination service information.',
    eligibility: 'Available to citizens with registered mobile number.',
    documents: ['Registered mobile number', 'Beneficiary reference details'],
    actionLabel: 'Open CoWIN',
    url: 'https://www.cowin.gov.in/',
    icon: Icons.vaccines_rounded,
    color: Color(0xFFD9F99D),
  ),
];

class HealthSchemesScreen extends StatelessWidget {
  const HealthSchemesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppPage(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          children: [
            const TopBar(title: 'Health Schemes'),
            const SizedBox(height: 18),
            AyushmanCard(scheme: healthSchemeInfos.first),
            const SizedBox(height: 22),
            const Text(
              'Other Government Schemes',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            for (final scheme in healthSchemeInfos.skip(1))
              SchemeTile(scheme: scheme),
          ],
        ),
      ),
    );
  }
}

class HealthRecordsScreen extends StatelessWidget {
  const HealthRecordsScreen({super.key, required this.profile});

  final AppUserProfile profile;

  @override
  Widget build(BuildContext context) {
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'No uploaded health records yet.',
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
            EditableEntryPanel(
              title: 'Add Health Record',
              titleHint: 'Report name',
              subtitleHint: 'Notes, file link, doctor, date',
              buttonLabel: 'Save Record',
              icon: Icons.folder_copy_rounded,
              color: AppColors.blue,
              onSave: (title, subtitle, attachmentName, attachmentType) {
                appData.addEntry(
                  appData.healthRecords,
                  AppTextEntry(
                    title: title,
                    subtitle: subtitle,
                    icon: Icons.folder_copy_rounded,
                    color: AppColors.blue,
                    attachmentName: attachmentName,
                    attachmentType: attachmentType,
                  ),
                );
              },
            ),
            const SizedBox(height: 18),
            AnimatedBuilder(
              animation: appData,
              builder: (context, _) {
                return Column(
                  children: [
                    for (final record in appData.healthRecords)
                      InfoEntryCard(entry: record),
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
                trailingOnTap: () => showFilterInfo(
                  context,
                  'Jan Aushadhi stores are sorted by live GPS distance. Call a store to confirm stock.',
                ),
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
                  final nearby = liveHealthData.nearbyKendras(
                    appLocation.current,
                  );
                  if (liveHealthData.loading && nearby.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.fromLTRB(20, 0, 20, 26),
                      child: LiveHealthLoadingCard(
                        title: 'Fetching Jan Aushadhi stores',
                        subtitle:
                            'OpenStreetMap se live pharmacy data load ho raha hai.',
                      ),
                    );
                  }
                  if (nearby.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.fromLTRB(20, 0, 20, 26),
                      child: EmptyStateCard(
                        icon: Icons.medication_liquid_rounded,
                        title: 'No Jan Aushadhi live result found',
                        subtitle:
                            'OpenStreetMap me nearby verified Jan Aushadhi listing nahi mili.',
                      ),
                    );
                  }
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
          AnimatedBuilder(
            animation: appData,
            builder: (context, _) {
              if (appData.appointments.isEmpty) {
                return const EmptyStateCard(
                  icon: Icons.calendar_month_rounded,
                  title: 'No appointments yet',
                  subtitle:
                      'Book a doctor appointment and it will appear here permanently.',
                );
              }
              return Column(
                children: [
                  for (final appointment in appData.appointments)
                    AppointmentCard(appointment: appointment),
                ],
              );
            },
          ),
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
        children: [
          const TopBar(title: 'Messages', showBack: false),
          const SizedBox(height: 20),
          AnimatedBuilder(
            animation: appData,
            builder: (context, _) {
              if (appData.threads.isEmpty) {
                return Column(
                  children: [
                    const EmptyStateCard(
                      icon: Icons.chat_bubble_outline_rounded,
                      title: 'No messages yet',
                      subtitle:
                          'Start a message or book appointments to create live threads.',
                    ),
                    const SizedBox(height: 12),
                    PrimaryButton(
                      label: 'Start Message',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NewMessageScreen(),
                        ),
                      ),
                    ),
                  ],
                );
              }
              return Column(
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NewMessageScreen(),
                        ),
                      ),
                      icon: const Icon(Icons.add_comment_rounded),
                      label: const Text('New'),
                    ),
                  ),
                  for (var i = 0; i < appData.threads.length; i++)
                    MessageTile(
                      name: appData.threads[i].name,
                      text: appData.threads[i].messages.isEmpty
                          ? appData.threads[i].subtitle
                          : appData.threads[i].messages.last.body,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatThreadScreen(threadIndex: i),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    super.key,
    required this.profile,
    required this.onLogout,
    required this.onProfileChanged,
  });

  final AppUserProfile profile;
  final Future<void> Function() onLogout;
  final ValueChanged<AppUserProfile> onProfileChanged;

  @override
  Widget build(BuildContext context) {
    return AppPage(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 112),
        children: [
          TopBar(
            title: 'Profile',
            showBack: false,
            trailingIcon: Icons.settings_outlined,
            trailingOnTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => EditableInfoScreen(
                  title: 'Notification Settings',
                  entries: appData.notifications,
                  defaultIcon: Icons.settings_rounded,
                  color: AppColors.navy,
                  allowAttachments: false,
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          ProfileHeaderCard(
            profile: profile,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => EditProfileScreen(
                  profile: profile,
                  onSaved: onProfileChanged,
                ),
              ),
            ),
          ),
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
              MaterialPageRoute(
                builder: (_) => HealthRecordsScreen(profile: profile),
              ),
            ),
          ),
          ProfileMenuItem(
            icon: Icons.medical_information_outlined,
            title: 'Prescriptions',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => EditableInfoScreen(
                  title: 'Prescriptions',
                  entries: appData.prescriptions,
                  defaultIcon: Icons.medication_rounded,
                  color: AppColors.green,
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
                builder: (_) => EditableInfoScreen(
                  title: 'Allergies & Conditions',
                  entries: appData.allergies,
                  defaultIcon: Icons.warning_amber_rounded,
                  color: AppColors.red,
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
                builder: (_) => EditableInfoScreen(
                  title: 'Vital Health Info',
                  entries: appData.vitals,
                  defaultIcon: Icons.monitor_heart_rounded,
                  color: AppColors.red,
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
                builder: (_) => const EmergencyContactsScreen(),
              ),
            ),
          ),
          ProfileMenuItem(
            icon: Icons.location_on_outlined,
            title: 'Address Book',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => EditableInfoScreen(
                  title: 'Address Book',
                  entries: appData.addresses,
                  defaultIcon: Icons.location_on_rounded,
                  color: AppColors.blue,
                  onBeforeAdd: () async {
                    await appLocation.requestCurrentLocation();
                  },
                  seedSubtitle: appLocation.resolved
                      ? appLocation.label
                      : 'Address or landmark',
                  allowAttachments: false,
                ),
              ),
            ),
          ),
          ProfileMenuItem(
            icon: Icons.notifications_none_rounded,
            title: 'Notification Settings',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => EditableInfoScreen(
                  title: 'Notification Settings',
                  entries: appData.notifications,
                  defaultIcon: Icons.notifications_active_rounded,
                  color: AppColors.green,
                  allowAttachments: false,
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
            onTap: onLogout,
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

class EditableInfoScreen extends StatelessWidget {
  const EditableInfoScreen({
    super.key,
    required this.title,
    required this.entries,
    required this.defaultIcon,
    required this.color,
    this.onBeforeAdd,
    this.seedSubtitle,
    this.allowAttachments = true,
  });

  final String title;
  final List<AppTextEntry> entries;
  final IconData defaultIcon;
  final Color color;
  final Future<void> Function()? onBeforeAdd;
  final String? seedSubtitle;
  final bool allowAttachments;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppPage(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
          children: [
            TopBar(title: title),
            const SizedBox(height: 18),
            EditableEntryPanel(
              title: 'Add $title',
              titleHint: 'Title',
              subtitleHint: seedSubtitle ?? 'Details',
              buttonLabel: 'Save',
              icon: defaultIcon,
              color: color,
              allowAttachments: allowAttachments,
              onBeforeSave: onBeforeAdd,
              onSave: (entryTitle, subtitle, attachmentName, attachmentType) {
                appData.addEntry(
                  entries,
                  AppTextEntry(
                    title: entryTitle,
                    subtitle: subtitle,
                    icon: defaultIcon,
                    color: color,
                    attachmentName: attachmentName,
                    attachmentType: attachmentType,
                  ),
                );
              },
            ),
            const SizedBox(height: 18),
            AnimatedBuilder(
              animation: appData,
              builder: (context, _) {
                return Column(
                  children: [
                    for (final entry in entries) InfoEntryCard(entry: entry),
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

class EditableEntryPanel extends StatefulWidget {
  const EditableEntryPanel({
    super.key,
    required this.title,
    required this.titleHint,
    required this.subtitleHint,
    required this.buttonLabel,
    required this.icon,
    required this.color,
    required this.onSave,
    this.allowAttachments = true,
    this.onBeforeSave,
  });

  final String title;
  final String titleHint;
  final String subtitleHint;
  final String buttonLabel;
  final IconData icon;
  final Color color;
  final bool allowAttachments;
  final void Function(
    String title,
    String subtitle,
    String attachmentName,
    String attachmentType,
  )
  onSave;
  final Future<void> Function()? onBeforeSave;

  @override
  State<EditableEntryPanel> createState() => _EditableEntryPanelState();
}

class _EditableEntryPanelState extends State<EditableEntryPanel> {
  final _titleController = TextEditingController();
  final _subtitleController = TextEditingController();
  var _busy = false;
  String _attachmentName = '';
  String _attachmentType = '';

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: widget.color.withValues(alpha: .12),
                child: Icon(widget.icon, color: widget.color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              hintText: widget.titleHint,
              filled: true,
              fillColor: AppColors.soft,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _subtitleController,
            minLines: 2,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: widget.subtitleHint,
              filled: true,
              fillColor: AppColors.soft,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          if (widget.allowAttachments) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: _busy ? null : () => _pickAttachment(false),
                  icon: const Icon(Icons.upload_file_rounded),
                  label: const Text('Upload File'),
                ),
                OutlinedButton.icon(
                  onPressed: _busy ? null : () => _pickAttachment(true),
                  icon: const Icon(Icons.image_rounded),
                  label: const Text('Upload Image'),
                ),
              ],
            ),
          ],
          if (widget.allowAttachments && _attachmentName.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Attached: $_attachmentName',
              style: const TextStyle(
                color: AppColors.green,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
          const SizedBox(height: 12),
          PrimaryButton(
            label: _busy ? 'Saving...' : widget.buttonLabel,
            onTap: _busy ? null : _save,
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    final subtitle = _subtitleController.text.trim();
    if (title.isEmpty || subtitle.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please fill both fields.')));
      return;
    }
    setState(() => _busy = true);
    try {
      await widget.onBeforeSave?.call();
      widget.onSave(title, subtitle, _attachmentName, _attachmentType);
      _titleController.clear();
      _subtitleController.clear();
      _attachmentName = '';
      _attachmentType = '';
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Saved.')));
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _pickAttachment(bool imageOnly) async {
    final result = await FilePicker.pickFiles(
      type: imageOnly ? FileType.image : FileType.any,
      allowMultiple: false,
      withData: false,
    );
    if (result == null || result.files.isEmpty) {
      return;
    }
    final file = result.files.first;
    setState(() {
      _attachmentName = file.name;
      _attachmentType = imageOnly ? 'image' : 'file';
    });
  }
}

class InfoEntryCard extends StatelessWidget {
  const InfoEntryCard({super.key, required this.entry});

  final AppTextEntry entry;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: entry.color.withValues(alpha: .12),
            child: Icon(entry.icon, color: entry.color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  entry.subtitle,
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
                if (entry.attachmentName.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        entry.attachmentType == 'image'
                            ? Icons.image_rounded
                            : Icons.attach_file_rounded,
                        color: AppColors.green,
                        size: 15,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          entry.attachmentName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.green,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class EmergencyContactsScreen extends StatefulWidget {
  const EmergencyContactsScreen({super.key});

  @override
  State<EmergencyContactsScreen> createState() =>
      _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _relationController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _relationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppPage(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
          children: [
            const TopBar(title: 'Emergency Contacts'),
            const SizedBox(height: 18),
            AppCard(
              child: Column(
                children: [
                  _contactField(_nameController, 'Name', Icons.person_rounded),
                  const SizedBox(height: 10),
                  _contactField(
                    _phoneController,
                    'Phone number',
                    Icons.phone_rounded,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 10),
                  _contactField(
                    _relationController,
                    'Relation',
                    Icons.family_restroom_rounded,
                  ),
                  const SizedBox(height: 12),
                  PrimaryButton(label: 'Add Contact', onTap: _addContact),
                ],
              ),
            ),
            const SizedBox(height: 18),
            AnimatedBuilder(
              animation: appData,
              builder: (context, _) {
                return Column(
                  children: [
                    for (final contact in appData.emergencyContacts)
                      AppCard(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            const CircleAvatar(
                              backgroundColor: AppColors.soft,
                              child: Icon(
                                Icons.contact_phone_rounded,
                                color: AppColors.navy,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    contact.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${contact.relation} - ${contact.phone}',
                                    style: const TextStyle(
                                      color: AppColors.muted,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            CircleIcon(
                              icon: Icons.call_rounded,
                              onTap: () => callPhone(context, contact.phone),
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _contactField(
    TextEditingController controller,
    String hint,
    IconData icon, {
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: AppColors.navy),
        hintText: hint,
        filled: true,
        fillColor: AppColors.soft,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  void _addContact() {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final relation = _relationController.text.trim();
    if (name.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name and phone are required.')),
      );
      return;
    }
    appData.addEmergencyContact(
      EmergencyContactEntry(
        name: name,
        phone: phone,
        relation: relation.isEmpty ? 'Emergency contact' : relation,
      ),
    );
    _nameController.clear();
    _phoneController.clear();
    _relationController.clear();
  }
}

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({
    super.key,
    required this.profile,
    required this.onSaved,
  });

  final AppUserProfile profile;
  final ValueChanged<AppUserProfile> onSaved;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  final _contactController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.name);
    _emailController = TextEditingController(text: widget.profile.phone);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppPage(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
          children: [
            const TopBar(title: 'Edit Profile'),
            const SizedBox(height: 18),
            AppCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 42,
                    backgroundColor: const Color(0xFF91B7F2),
                    child: Text(
                      widget.profile.initial,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _field(_nameController, 'Full name', Icons.person_rounded),
                  const SizedBox(height: 12),
                  _field(
                    _emailController,
                    'Email address',
                    Icons.alternate_email_rounded,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 12),
                  _field(
                    _contactController,
                    'Contact number',
                    Icons.phone_rounded,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  PrimaryButton(label: 'Save Profile', onTap: _save),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String hint,
    IconData icon, {
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: AppColors.navy),
        hintText: hint,
        filled: true,
        fillColor: AppColors.soft,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  void _save() {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final contact = _contactController.text.trim();
    if (name.length < 2 || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid name and email.')),
      );
      return;
    }
    appData.saveProfile(name, email);
    widget.onSaved(AppUserProfile(name: name, phone: email));
    if (contact.isNotEmpty) {
      appData.addEmergencyContact(
        EmergencyContactEntry(
          name: name,
          phone: contact,
          relation: 'Personal contact',
        ),
      );
    }
    Navigator.pop(context);
  }
}

class NewMessageScreen extends StatefulWidget {
  const NewMessageScreen({super.key});

  @override
  State<NewMessageScreen> createState() => _NewMessageScreenState();
}

class _NewMessageScreenState extends State<NewMessageScreen> {
  final _nameController = TextEditingController();
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppPage(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
          children: [
            const TopBar(title: 'New Message'),
            const SizedBox(height: 18),
            AppCard(
              child: Column(
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      hintText: 'Doctor, hospital, or contact name',
                      filled: true,
                      fillColor: AppColors.soft,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _messageController,
                    minLines: 3,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: 'Message',
                      filled: true,
                      fillColor: AppColors.soft,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  PrimaryButton(label: 'Send Message', onTap: _send),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _send() {
    final name = _nameController.text.trim();
    final body = _messageController.text.trim();
    if (name.isEmpty || body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name and message are required.')),
      );
      return;
    }
    appData.createThread(name: name, subtitle: 'Custom message', body: body);
    Navigator.pop(context);
  }
}

class ChatThreadScreen extends StatefulWidget {
  const ChatThreadScreen({super.key, required this.threadIndex});

  final int threadIndex;

  @override
  State<ChatThreadScreen> createState() => _ChatThreadScreenState();
}

class _ChatThreadScreenState extends State<ChatThreadScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final thread = appData.threads[widget.threadIndex];
    return Scaffold(
      body: AppPage(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
              child: TopBar(title: thread.name),
            ),
            Expanded(
              child: AnimatedBuilder(
                animation: appData,
                builder: (context, _) {
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                    children: [
                      for (final message in thread.messages)
                        Align(
                          alignment: message.fromUser
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 520),
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(13),
                            decoration: BoxDecoration(
                              color: message.fromUser
                                  ? AppColors.navy
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.line),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  message.body,
                                  style: TextStyle(
                                    color: message.fromUser
                                        ? Colors.white
                                        : AppColors.text,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  message.time,
                                  style: TextStyle(
                                    color: message.fromUser
                                        ? Colors.white70
                                        : AppColors.muted,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(999),
                          borderSide: const BorderSide(color: AppColors.line),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  CircleIcon(icon: Icons.send_rounded, onTap: _send),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      return;
    }
    appData.addMessage(widget.threadIndex, text);
    _controller.clear();
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
            constraints: const BoxConstraints(maxWidth: 1440),
            child: child,
          ),
        ),
      ),
    );
  }
}

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key, required this.profile, required this.onLogout});

  final AppUserProfile profile;
  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 44),
        const Spacer(),
        const LogoMark(width: 136, height: 52),
        const Spacer(),
        CircleIcon(
          icon: Icons.notifications_none_rounded,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NotificationCenterScreen()),
          ),
        ),
      ],
    );
  }
}

class NotificationCenterScreen extends StatelessWidget {
  const NotificationCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppPage(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
          children: const [
            TopBar(title: 'Notifications'),
            SizedBox(height: 18),
            EmptyStateCard(
              icon: Icons.notifications_none_rounded,
              title: 'No notifications yet',
              subtitle:
                  'New appointment, SOS and cab updates will appear here after real activity.',
            ),
          ],
        ),
      ),
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
    this.trailingOnTap,
    this.onBack,
    this.showBack = true,
  });

  final String title;
  final IconData? trailingIcon;
  final VoidCallback? trailingOnTap;
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
          CircleIcon(icon: trailingIcon!, onTap: trailingOnTap ?? () {})
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

class SearchBox extends StatefulWidget {
  const SearchBox({
    super.key,
    required this.hint,
    this.onChanged,
    this.onSubmitted,
  });

  final String hint;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  State<SearchBox> createState() => _SearchBoxState();
}

class _SearchBoxState extends State<SearchBox> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _runSearch() {
    final value = _controller.text.trim();
    widget.onChanged?.call(value);
    widget.onSubmitted?.call(value);
  }

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
            child: TextField(
              controller: _controller,
              onChanged: widget.onChanged,
              onSubmitted: (value) {
                widget.onChanged?.call(value.trim());
                widget.onSubmitted?.call(value.trim());
              },
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: widget.hint,
                border: InputBorder.none,
                isDense: true,
                hintStyle: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Search',
            onPressed: widget.onChanged == null && widget.onSubmitted == null
                ? null
                : _runSearch,
            icon: const Icon(Icons.search_rounded),
            color: AppColors.text,
          ),
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
        setState(() => _index++);
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
    final visibleDoctors = liveHealthData.nearbyDoctors(appLocation.current);
    if (liveHealthData.loading && visibleDoctors.isEmpty) {
      return const LiveHealthLoadingCard(
        title: 'Finding live doctors',
        subtitle: 'Real nearby doctor listings are loading.',
      );
    }
    if (visibleDoctors.isEmpty) {
      return const SizedBox.shrink();
    }
    final doctor = visibleDoctors[_index % visibleDoctors.length];
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 420),
      child: AppCard(
        key: ValueKey(doctor.name),
        padding: const EdgeInsets.all(14),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => DoctorDetailScreen(doctor: doctor)),
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900
            ? 4
            : constraints.maxWidth >= 620
            ? 3
            : 2;
        return GridView.builder(
          itemCount: items.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: constraints.maxWidth >= 620 ? 1.65 : 1.35,
          ),
          itemBuilder: (context, index) => ServiceCard(item: items[index]),
        );
      },
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
  const CategoryChips({
    super.key,
    required this.labels,
    this.selectedLabel = 'All',
    this.onSelected,
  });

  final List<String> labels;
  final String selectedLabel;
  final ValueChanged<String>? onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => onSelected?.call(labels[i]),
              child: Container(
                margin: const EdgeInsets.only(right: 9),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color: labels[i] == selectedLabel
                      ? AppColors.navy
                      : AppColors.soft,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  labels[i],
                  style: TextStyle(
                    color: labels[i] == selectedLabel
                        ? Colors.white
                        : AppColors.text,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
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

class DoctorAvatar extends StatefulWidget {
  const DoctorAvatar({super.key, required this.doctor, this.radius = 34});

  final Doctor doctor;
  final double radius;

  @override
  State<DoctorAvatar> createState() => _DoctorAvatarState();
}

class _DoctorAvatarState extends State<DoctorAvatar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final female = isLikelyFemaleDoctorName(widget.doctor.name);
    return SizedBox(
      width: widget.radius * 2,
      height: widget.radius * 2,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            painter: DoctorCartoonPainter(
              progress: _controller.value,
              female: female,
              background: widget.doctor.color,
            ),
          );
        },
      ),
    );
  }
}

class DoctorCartoonPainter extends CustomPainter {
  const DoctorCartoonPainter({
    required this.progress,
    required this.female,
    required this.background,
  });

  final double progress;
  final bool female;
  final Color background;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    final bob = math.sin(progress * math.pi * 2) * r * .035;
    final bg = Paint()..color = background;
    canvas.drawCircle(c, r, bg);
    canvas.drawCircle(
      c,
      r * (.82 + progress * .04),
      Paint()
        ..color = Colors.white.withValues(alpha: .24)
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * .06,
    );

    final skin = Paint()..color = const Color(0xFFFFD2B7);
    final hair = Paint()
      ..color = female ? const Color(0xFF2E1D16) : const Color(0xFF1F2937);
    final coat = Paint()..color = Colors.white;
    final navy = Paint()..color = AppColors.navy;
    final blue = Paint()..color = AppColors.blue;
    final red = Paint()..color = AppColors.red;

    final headCenter = Offset(c.dx, c.dy - r * .16 + bob);
    if (female) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(c.dx, c.dy - r * .04 + bob),
          width: r * 1.04,
          height: r * 1.26,
        ),
        hair,
      );
    } else {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(c.dx, c.dy - r * .31 + bob),
          width: r * .9,
          height: r * .45,
        ),
        hair,
      );
    }
    canvas.drawCircle(headCenter, r * .36, skin);
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(c.dx, c.dy - r * .30 + bob),
        width: r * .78,
        height: r * .45,
      ),
      math.pi,
      math.pi,
      true,
      hair,
    );

    final eyeY = headCenter.dy - r * .03;
    for (final dx in [-r * .12, r * .12]) {
      canvas.drawCircle(Offset(c.dx + dx, eyeY), r * .027, navy);
    }
    final smile = ui.Path()
      ..moveTo(c.dx - r * .12, headCenter.dy + r * .13)
      ..quadraticBezierTo(
        c.dx,
        headCenter.dy + r * (.21 + progress * .02),
        c.dx + r * .12,
        headCenter.dy + r * .13,
      );
    canvas.drawPath(
      smile,
      Paint()
        ..color = AppColors.red.withValues(alpha: .72)
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * .035
        ..strokeCap = StrokeCap.round,
    );

    final bodyTop = c.dy + r * .22 + bob;
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(c.dx - r * .48, bodyTop, r * .96, r * .72),
      Radius.circular(r * .18),
    );
    canvas.drawRRect(body, coat);
    canvas.drawLine(
      Offset(c.dx, bodyTop + r * .04),
      Offset(c.dx, bodyTop + r * .66),
      Paint()
        ..color = AppColors.line
        ..strokeWidth = r * .025,
    );
    canvas.drawCircle(Offset(c.dx - r * .20, bodyTop + r * .26), r * .04, red);
    canvas.drawLine(
      Offset(c.dx + r * .16, bodyTop + r * .16),
      Offset(c.dx + r * .28, bodyTop + r * .36),
      Paint()
        ..color = AppColors.blue
        ..strokeWidth = r * .035
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(
      Offset(c.dx + r * .30, bodyTop + r * .40),
      r * .055,
      blue,
    );
  }

  @override
  bool shouldRepaint(covariant DoctorCartoonPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.female != female ||
        oldDelegate.background != background;
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

const appointmentTimes = [
  '10:00 AM',
  '11:30 AM',
  '03:00 PM',
  '04:30 PM',
  '05:30 PM',
  '06:00 PM',
];

List<(String, String)> appointmentDateOptions() {
  const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final now = DateTime.now();
  return List.generate(4, (index) {
    final day = now.add(Duration(days: index));
    return (
      index == 0 ? 'Today' : weekdays[day.weekday - 1],
      '${day.day} ${months[day.month - 1]}',
    );
  });
}

class DateSlots extends StatelessWidget {
  const DateSlots({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final dates = appointmentDateOptions();
    return Row(
      children: [
        for (var i = 0; i < dates.length; i++)
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(11),
              onTap: () => onSelected(i),
              child: Container(
                margin: EdgeInsets.only(right: i == dates.length - 1 ? 0 : 8),
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: i == selectedIndex ? AppColors.navy : AppColors.soft,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Column(
                  children: [
                    Text(
                      dates[i].$1,
                      style: TextStyle(
                        color: i == selectedIndex
                            ? Colors.white
                            : AppColors.text,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      dates[i].$2,
                      style: TextStyle(
                        color: i == selectedIndex
                            ? Colors.white70
                            : AppColors.muted,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class TimeSlots extends StatelessWidget {
  const TimeSlots({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: appointmentTimes.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 2.3,
      ),
      itemBuilder: (context, index) {
        final selected = index == selectedIndex;
        return InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => onSelected(index),
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? AppColors.navy : AppColors.soft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              appointmentTimes[index],
              style: TextStyle(
                color: selected ? Colors.white : AppColors.text,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
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
            'Opening emergency call. Supabase alert save is offline.',
          ),
        ),
      );
      await callPhone(context, _primaryEmergencyPhone());
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
        const SnackBar(
          content: Text('SOS alert saved. Opening emergency call.'),
        ),
      );
      await callPhone(context, _primaryEmergencyPhone());
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('SOS failed: $error')));
      await callPhone(context, _primaryEmergencyPhone());
    }
  }

  String _primaryEmergencyPhone() {
    if (appData.emergencyContacts.isNotEmpty) {
      return appData.emergencyContacts.first.phone;
    }
    return '108';
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
      animation: Listenable.merge([appLocation, liveHealthData]),
      builder: (context, _) {
        final user = appLocation.current;
        final liveHospitals = liveHealthData.nearbyHospitals(user);
        final liveKendras = liveHealthData.nearbyKendras(user);
        final destination = switch (mode) {
          MapMode.route || MapMode.hospitals =>
            liveHospitals.isEmpty ? null : liveHospitals.first.latLng,
          MapMode.kendras =>
            liveKendras.isEmpty ? null : liveKendras.first.latLng,
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
            for (final hospital in liveHospitals)
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
            for (final kendra in liveKendras)
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
                  initialCenter: mode == MapMode.route && destination != null
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
                  if (mode == MapMode.route && destination != null)
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

class EmergencyRideCard extends StatefulWidget {
  const EmergencyRideCard({super.key, this.profile});

  final AppUserProfile? profile;

  @override
  State<EmergencyRideCard> createState() => _EmergencyRideCardState();
}

class _EmergencyRideCardState extends State<EmergencyRideCard> {
  static const _rideTypes = ['Hatchback', 'Sedan', 'SUV', 'Ambulance'];
  static const _paymentMethods = ['Cash', 'Online'];

  var _rideType = 'Hatchback';
  var _paymentMethod = 'Cash';
  var _requesting = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([appLocation, liveHealthData]),
      builder: (context, _) {
        final nearest = liveHealthData.nearbyHospitals(appLocation.current);
        if (liveHealthData.loading && nearest.isEmpty) {
          return const LiveHealthLoadingCard(
            title: 'Finding nearby hospitals',
            subtitle: 'Fetching live OpenStreetMap results around your GPS.',
          );
        }
        if (nearest.isEmpty) {
          return const EmptyStateCard(
            icon: Icons.local_hospital_outlined,
            title: 'No live hospital found nearby',
            subtitle:
                'Tap GPS again or call emergency services. The app will not show fake hospital drops.',
          );
        }
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
              Row(
                children: [
                  Expanded(
                    child: RideInfo(
                      icon: Icons.local_taxi_rounded,
                      title: 'Ride Type',
                      value: _rideType,
                      onTap: () => _showPicker(
                        title: 'Select ride type',
                        values: _rideTypes,
                        currentValue: _rideType,
                        onSelected: (value) => setState(() {
                          _rideType = value;
                        }),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: RideInfo(
                      icon: Icons.payments_outlined,
                      title: 'Payment Method',
                      value: _paymentMethod,
                      onTap: () => _showPicker(
                        title: 'Select payment',
                        values: _paymentMethods,
                        currentValue: _paymentMethod,
                        onSelected: (value) => setState(() {
                          _paymentMethod = value;
                        }),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              PrimaryButton(
                label: _requesting
                    ? 'Requesting cab...'
                    : 'Request Emergency Cab',
                onTap: _requesting ? null : () => _requestCab(context),
              ),
              const SizedBox(height: 12),
              const Center(
                child: Text(
                  'Drivers will be notified about the emergency',
                  style: TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ),
              AnimatedBuilder(
                animation: appData,
                builder: (context, _) {
                  if (appData.cabRequests.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: CabRequestStatusCard(
                      request: appData.cabRequests.first,
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _requestCab(BuildContext context) async {
    setState(() => _requesting = true);
    if (!appLocation.resolved && !appLocation.loading) {
      await appLocation.requestCurrentLocation();
    }
    if (!context.mounted) {
      if (mounted) {
        setState(() => _requesting = false);
      }
      return;
    }
    final nearest = liveHealthData.nearbyHospitals(appLocation.current);
    if (nearest.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No live nearby hospital found. Refresh GPS and try again.',
          ),
        ),
      );
      if (mounted) {
        setState(() => _requesting = false);
      }
      return;
    }
    final hospital = nearest.first;
    final now = DateTime.now();
    final eta = 4 + (now.second % 5);
    final drivers = [
      'Amit Verma',
      'Rahul Yadav',
      'Imran Khan',
      'Deepak Patel',
      'Sandeep Sharma',
    ];
    final profile =
        widget.profile ??
        AppUserProfile(
          name: appData.profileName.isEmpty ? 'User' : appData.profileName,
          phone: appData.profileEmail,
        );
    RapidoRideResult? liveRide;
    String? liveError;
    try {
      liveRide = await JeevanArogyaRepository().requestRapidoRide(
        fullName: profile.name,
        email: profile.phone,
        pickup: appLocation.label,
        dropLocation: '${hospital.name}, Indore',
        pickupLatitude: appLocation.current.latitude,
        pickupLongitude: appLocation.current.longitude,
        rideType: _rideType,
        paymentMethod: _paymentMethod,
      );
    } catch (error) {
      liveError = friendlyAuthError(error);
    }
    final request = EmergencyCabRequestEntry(
      pickup: appLocation.label,
      dropLocation: '${hospital.name}, Indore',
      hospitalName: hospital.name,
      hospitalPhone: hospital.phone,
      status: liveRide == null ? 'Cab booking saved' : 'Cab booking requested',
      etaMinutes: eta,
      driverName: drivers[now.second % drivers.length],
      createdAtLabel: formatShortDateTime(now),
      rideType: _rideType,
      paymentMethod: _paymentMethod,
      backendRideId: liveRide?.id ?? '',
      fareLabel: liveRide?.estimatedFare == null
          ? ''
          : 'Rs. ${liveRide!.estimatedFare}',
    );
    appData.addCabRequest(request);
    if (!context.mounted) {
      if (mounted) {
        setState(() => _requesting = false);
      }
      return;
    }
    setState(() => _requesting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          liveRide == null
              ? 'Cab saved locally. Backend sync failed: ${liveError ?? 'try again'}'
              : 'Ride saved to backend. ETA $eta min. Fare ${request.fareLabel}.',
        ),
        action: SnackBarAction(
          label: 'Call',
          onPressed: () => callPhone(context, hospital.phone),
        ),
      ),
    );
  }

  Future<void> _showPicker({
    required String title,
    required List<String> values,
    required String currentValue,
    required ValueChanged<String> onSelected,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                for (final value in values)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: value == currentValue
                          ? AppColors.navy
                          : AppColors.soft,
                      child: Icon(
                        value == currentValue
                            ? Icons.check_rounded
                            : Icons.circle_outlined,
                        color: value == currentValue
                            ? Colors.white
                            : AppColors.muted,
                      ),
                    ),
                    title: Text(
                      value,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    onTap: () {
                      onSelected(value);
                      Navigator.pop(context);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class CabRequestStatusCard extends StatelessWidget {
  const CabRequestStatusCard({super.key, required this.request});

  final EmergencyCabRequestEntry request;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.soft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 18,
                backgroundColor: Color(0xFFFFE7C2),
                child: Icon(
                  Icons.local_taxi_rounded,
                  color: Color(0xFFFF9800),
                  size: 19,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${request.status} - ETA ${request.etaMinutes} min',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${request.driverName} - ${request.createdAtLabel}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: () => callPhone(context, request.hospitalPhone),
                icon: const Icon(Icons.call_rounded, size: 17),
                label: const Text('Call'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _CabMetaChip(
                icon: Icons.local_taxi_rounded,
                label: request.rideType,
              ),
              _CabMetaChip(
                icon: Icons.payments_outlined,
                label: request.paymentMethod,
              ),
              if (request.fareLabel.isNotEmpty)
                _CabMetaChip(
                  icon: Icons.currency_rupee_rounded,
                  label: request.fareLabel,
                ),
              if (request.backendRideId.isNotEmpty)
                _CabMetaChip(
                  icon: Icons.cloud_done_rounded,
                  label:
                      'Ride ${request.backendRideId.substring(0, math.min(6, request.backendRideId.length))}',
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            request.dropLocation,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Pickup: ${request.pickup}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _CabMetaChip extends StatelessWidget {
  const _CabMetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.navy),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

String formatShortDateTime(DateTime value) {
  final hour12 = value.hour % 12 == 0 ? 12 : value.hour % 12;
  final minute = value.minute.toString().padLeft(2, '0');
  final suffix = value.hour >= 12 ? 'PM' : 'AM';
  return '${value.day}/${value.month} $hour12:$minute $suffix';
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
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
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
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.soft,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.line),
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
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 10,
                    ),
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

Future<void> openExternalUrl(BuildContext context, String url) async {
  final uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
    return;
  }
  if (!context.mounted) {
    return;
  }
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text('Open this link: $url')));
}

void showFilterInfo(BuildContext context, String message) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Active Filter',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              style: const TextStyle(color: AppColors.muted, height: 1.4),
            ),
            const SizedBox(height: 14),
            PrimaryButton(
              label: appLocation.loading ? 'Locating...' : 'Refresh GPS',
              onTap: appLocation.loading
                  ? null
                  : () async {
                      await appLocation.requestCurrentLocation();
                      if (context.mounted) Navigator.pop(context);
                    },
            ),
          ],
        ),
      ),
    ),
  );
}

class AyushmanCard extends StatelessWidget {
  const AyushmanCard({super.key, required this.scheme});

  final HealthSchemeInfo scheme;

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
                Text(
                  scheme.subtitle,
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  scheme.benefit,
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
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SchemeDetailScreen(scheme: scheme),
                      ),
                    ),
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
  const SchemeTile({super.key, required this.scheme});

  final HealthSchemeInfo scheme;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => SchemeDetailScreen(scheme: scheme)),
      ),
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: scheme.color,
            child: Icon(scheme.icon, color: AppColors.navy, size: 21),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  scheme.title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  scheme.subtitle,
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

class SchemeDetailScreen extends StatelessWidget {
  const SchemeDetailScreen({super.key, required this.scheme});

  final HealthSchemeInfo scheme;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppPage(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
          children: [
            TopBar(title: scheme.title),
            const SizedBox(height: 18),
            AppCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: scheme.color,
                    child: Icon(scheme.icon, color: AppColors.navy),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    scheme.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    scheme.department,
                    style: const TextStyle(
                      color: AppColors.navy,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    scheme.benefit,
                    style: const TextStyle(
                      color: AppColors.muted,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Eligibility',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    scheme.eligibility,
                    style: const TextStyle(
                      color: AppColors.muted,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Documents',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  for (final document in scheme.documents)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 7),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.green,
                            size: 17,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              document,
                              style: const TextStyle(
                                color: AppColors.text,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              label: scheme.actionLabel,
              onTap: () => openExternalUrl(context, scheme.url),
            ),
          ],
        ),
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
  const AppointmentCard({super.key, required this.appointment});

  final UserAppointmentEntry appointment;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 32,
            backgroundColor: AppColors.soft,
            child: Icon(Icons.event_available_rounded, color: AppColors.navy),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appointment.doctorName,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  appointment.specialty,
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Text(
                  '${appointment.dateLabel} - ${appointment.timeLabel}',
                  style: const TextStyle(
                    color: AppColors.green,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
                if (appointment.reason.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    appointment.reason,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
                ],
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
  const MessageTile({
    super.key,
    required this.name,
    required this.text,
    this.onTap,
  });

  final String name;
  final String text;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
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
  const ProfileHeaderCard({super.key, required this.profile, this.onTap});

  final AppUserProfile profile;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 33,
            backgroundColor: const Color(0xFF91B7F2),
            child: Text(
              profile.initial,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  profile.phone,
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
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
        onPressed: onTap,
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
