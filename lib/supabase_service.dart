import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_config.dart';
import 'supabase_models.dart';

class JeevanArogyaRepository {
  JeevanArogyaRepository({SupabaseClient? client})
    : _client = client ?? SupabaseConfig.client;

  static const _rapidoBaseUrl = String.fromEnvironment(
    'RAPIDO_API_BASE_URL',
    defaultValue: 'https://rapido-backend-api.onrender.com',
  );

  final SupabaseClient? _client;

  bool get isConnected => _client != null;

  User? get currentUser => _client?.auth.currentUser;

  Stream<AuthState> get authStateChanges {
    final client = _client;
    if (client == null) {
      return const Stream.empty();
    }
    return client.auth.onAuthStateChange;
  }

  Future<String> sendEmailOtp({
    required String email,
    required String fullName,
  }) async {
    final normalizedEmail = normalizeEmail(email);
    await _sendViaEmailOtpService(normalizedEmail, fullName.trim());
    return normalizedEmail;
  }

  Future<bool> verifyEmailOtp({
    required String email,
    required String token,
  }) async {
    await _verifyViaEmailOtpService(normalizeEmail(email), token);
    return false;
  }

  Future<void> signOut() async {
    final client = _client;
    if (client == null) {
      return;
    }
    await client.auth.signOut();
  }

  Future<List<DbDoctor>> fetchDoctors({String? specialty}) async {
    final client = _requireClient();
    dynamic query = client.from('doctors').select();
    if (specialty != null && specialty != 'All') {
      query = query.eq('specialty', specialty);
    }
    final rows = await query.order('rating', ascending: false);
    return (rows as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(DbDoctor.fromMap)
        .toList();
  }

  Stream<List<DbDoctor>> watchDoctors() {
    final client = _client;
    if (client == null) {
      return const Stream.empty();
    }
    return client
        .from('doctors')
        .stream(primaryKey: ['id'])
        .order('rating', ascending: false)
        .map((rows) => rows.map(DbDoctor.fromMap).toList());
  }

  Future<List<DbHospital>> fetchHospitals() async {
    final client = _requireClient();
    final rows = await client
        .from('hospitals')
        .select()
        .order('distance_km', ascending: true);
    return (rows as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(DbHospital.fromMap)
        .toList();
  }

  Future<List<DbEmergencyContact>> fetchEmergencyContacts() async {
    final client = _requireClient();
    final userId = _requireUserId();
    final rows = await client
        .from('emergency_contacts')
        .select()
        .eq('user_id', userId)
        .order('is_primary', ascending: false);
    return (rows as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(DbEmergencyContact.fromMap)
        .toList();
  }

  Future<DbAppointment> bookAppointment({
    required String doctorId,
    required DateTime slotTime,
    String reason = 'General consultation',
  }) async {
    final client = _requireClient();
    final userId = _requireUserId();
    final rows = await client
        .from('appointments')
        .insert({
          'user_id': userId,
          'doctor_id': doctorId,
          'slot_time': slotTime.toIso8601String(),
          'reason': reason,
          'status': 'confirmed',
        })
        .select('id, slot_time, status, doctors(name, specialty)')
        .single();
    final doctor = rows['doctors'] as Map<String, dynamic>? ?? {};
    return DbAppointment.fromMap({
      'id': rows['id'],
      'slot_time': rows['slot_time'],
      'status': rows['status'],
      'doctor_name': doctor['name'],
      'specialty': doctor['specialty'],
    });
  }

  Future<DbSosAlert> createSosAlert({
    required double latitude,
    required double longitude,
    String note = 'Emergency SOS triggered from Jeevan Arogya app',
  }) async {
    final client = _requireClient();
    final userId = _requireUserId();
    final row = await client
        .from('sos_alerts')
        .insert({
          'user_id': userId,
          'latitude': latitude,
          'longitude': longitude,
          'note': note,
          'status': 'sent',
        })
        .select()
        .single();
    return DbSosAlert.fromMap(row);
  }

  Future<DbCabRequest> requestEmergencyCab({
    required String pickup,
    required String dropLocation,
    required double pickupLatitude,
    required double pickupLongitude,
  }) async {
    final client = _requireClient();
    final userId = _requireUserId();
    final row = await client
        .from('cab_requests')
        .insert({
          'user_id': userId,
          'pickup': pickup,
          'drop_location': dropLocation,
          'pickup_latitude': pickupLatitude,
          'pickup_longitude': pickupLongitude,
          'status': 'requested',
          'eta_minutes': 5,
        })
        .select()
        .single();
    return DbCabRequest.fromMap(row);
  }

  Future<RapidoRideResult> requestRapidoRide({
    required String fullName,
    required String email,
    required String pickup,
    required String dropLocation,
    required double pickupLatitude,
    required double pickupLongitude,
    required String rideType,
    required String paymentMethod,
  }) async {
    final normalizedEmail = normalizeEmail(email);
    final token = await _rapidoTokenFor(
      fullName: fullName,
      email: normalizedEmail,
    );
    final scheduleTime = DateTime.now()
        .toUtc()
        .add(const Duration(minutes: 8))
        .toIso8601String();
    final response = await http
        .post(
          _rapidoUri('/api/rides'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'pickup': _limitText(pickup, fallback: 'Current GPS pickup'),
            'drop': _limitText(dropLocation, fallback: 'Nearest hospital'),
            'scheduleTime': scheduleTime,
            'purpose': 'Emergency hospital ride',
            'specialRequirements':
                'Jeevan Arogya emergency request | Ride: $rideType | Payment: $paymentMethod | GPS: ${pickupLatitude.toStringAsFixed(6)}, ${pickupLongitude.toStringAsFixed(6)}',
          }),
        )
        .timeout(const Duration(seconds: 18));
    final data = _decodeJsonResponse(response);
    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        data['success'] != true) {
      throw RapidoApiFailure(
        data['message']?.toString() ?? 'Ride booking failed.',
      );
    }
    final ride = data['data'] is Map ? (data['data'] as Map)['ride'] : null;
    if (ride is! Map) {
      throw const RapidoApiFailure('Ride server response was incomplete.');
    }
    final rideMap = ride.cast<String, dynamic>();
    return RapidoRideResult(
      id: rideMap['_id']?.toString() ?? '',
      status: rideMap['status']?.toString() ?? 'pending',
      estimatedFare: (rideMap['estimatedFare'] as num?)?.toInt(),
    );
  }

  Future<void> upsertProfile({
    required String fullName,
    required String phone,
  }) async {
    final client = _requireClient();
    final userId = _requireUserId();
    await client.from('profiles').upsert({
      'id': userId,
      'full_name': fullName,
      'phone': phone,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  SupabaseClient _requireClient() {
    final client = _client;
    if (client == null) {
      throw StateError('Supabase is not configured. Add .env credentials.');
    }
    return client;
  }

  String _requireUserId() {
    final id = _client?.auth.currentUser?.id;
    if (id == null) {
      throw StateError('User must be signed in to perform this action.');
    }
    return id;
  }

  String normalizeEmail(String email) {
    final normalized = email.trim().toLowerCase();
    if (!normalized.contains('@')) {
      throw const OtpFailure('Please enter a valid email address.');
    }
    return normalized;
  }

  Uri _apiUri(String path) {
    final origin = Uri.base.origin;
    if (!origin.startsWith('http')) {
      throw const OtpFailure(
        'Email OTP API is available only on web deployment.',
      );
    }
    return Uri.parse('$origin/api/$path');
  }

  Uri _rapidoUri(String path) => Uri.parse('$_rapidoBaseUrl$path');

  Future<String> _rapidoTokenFor({
    required String fullName,
    required String email,
  }) async {
    final password = _rapidoPassword(email);
    try {
      return await _loginRapido(email: email, password: password);
    } on RapidoApiFailure {
      await _registerRapido(
        fullName: fullName,
        email: email,
        password: password,
      );
      return _loginRapido(email: email, password: password);
    }
  }

  Future<void> _registerRapido({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final names = _rapidoNames(fullName);
    final hash = _stableHash(email);
    final response = await http
        .post(
          _rapidoUri('/api/auth/register'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'firstName': names.$1,
            'lastName': names.$2,
            'email': email,
            'password': password,
            'phone': '+91${9000000000 + (hash % 999999999)}',
            'employeeId': 'JA${hash.toRadixString(36).toUpperCase()}',
            'department': 'Operations',
            'role': 'user',
          }),
        )
        .timeout(const Duration(seconds: 18));
    final data = _decodeJsonResponse(response);
    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        data['success'] != true) {
      final message = data['message']?.toString() ?? 'Ride user setup failed.';
      if (!message.toLowerCase().contains('already exists')) {
        throw RapidoApiFailure(message);
      }
    }
  }

  Future<String> _loginRapido({
    required String email,
    required String password,
  }) async {
    final response = await http
        .post(
          _rapidoUri('/api/auth/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email, 'password': password}),
        )
        .timeout(const Duration(seconds: 18));
    final data = _decodeJsonResponse(response);
    final token = data['data'] is Map ? (data['data'] as Map)['token'] : null;
    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        data['success'] != true ||
        token == null) {
      throw RapidoApiFailure(
        data['message']?.toString() ?? 'Ride backend login failed.',
      );
    }
    return token.toString();
  }

  Future<void> _sendViaEmailOtpService(String email, String fullName) async {
    final response = await http
        .post(
          _apiUri('send_email_otp'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email, 'full_name': fullName}),
        )
        .timeout(const Duration(seconds: 12));
    final data = _decodeResponse(response);
    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        data['ok'] != true) {
      throw OtpFailure(
        _cleanOtpMessage(data['error']?.toString() ?? 'Email OTP send failed.'),
      );
    }
  }

  Future<void> _verifyViaEmailOtpService(String email, String token) async {
    final response = await http
        .post(
          _apiUri('verify_email_otp'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email, 'code': token.replaceAll(' ', '')}),
        )
        .timeout(const Duration(seconds: 12));
    final data = _decodeResponse(response);
    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        data['ok'] != true) {
      throw OtpFailure(
        _cleanOtpMessage(
          data['error']?.toString() ?? 'Invalid or expired OTP.',
        ),
      );
    }
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
    final contentType = response.headers['content-type'] ?? '';
    final body = response.body.trimLeft();
    if (!contentType.contains('application/json') ||
        body.startsWith('<!DOCTYPE') ||
        body.startsWith('<html')) {
      throw OtpApiUnavailable();
    }

    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } on FormatException {
      throw OtpApiUnavailable();
    }
    return {'ok': false, 'error': 'Unexpected OTP server response.'};
  }

  Map<String, dynamic> _decodeJsonResponse(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } on FormatException {
      throw const RapidoApiFailure('Ride server returned invalid response.');
    }
    return {'success': false, 'message': 'Unexpected ride server response.'};
  }

  (String, String) _rapidoNames(String fullName) {
    final cleaned = fullName
        .replaceAll(RegExp(r'[^a-zA-Z\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final parts = cleaned.isEmpty ? <String>[] : cleaned.split(' ');
    final first = parts.isEmpty ? 'Jeevan' : parts.first;
    final last = parts.length > 1 ? parts.skip(1).join(' ') : 'User';
    return (
      first.length < 2 ? 'Jeevan' : first,
      last.length < 2 ? 'User' : last,
    );
  }

  String _rapidoPassword(String email) {
    return 'JeevanArogya${_stableHash(email).toRadixString(36)}Aa1!';
  }

  int _stableHash(String value) {
    var hash = 0x811c9dc5;
    for (final code in value.codeUnits) {
      hash ^= code;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return hash;
  }

  String _limitText(String value, {required String fallback}) {
    final text = value.trim().isEmpty ? fallback : value.trim();
    if (text.length <= 200) {
      return text.length < 5 ? fallback : text;
    }
    return text.substring(0, 200);
  }

  String _cleanOtpMessage(String message) {
    var cleaned = message.trim();
    for (final prefix in [
      'Bad state:',
      'Exception:',
      'StateError:',
      'TwilioApiError:',
      'EmailOtpServiceError:',
    ]) {
      if (cleaned.toLowerCase().startsWith(prefix.toLowerCase())) {
        cleaned = cleaned.substring(prefix.length).trim();
      }
    }
    if (cleaned.toLowerCase() == 'invalid parameters') {
      return 'Invalid email OTP parameters. Check EMAIL_OTP_SERVICE_URL and request payload.';
    }
    return cleaned;
  }
}

class RapidoRideResult {
  const RapidoRideResult({
    required this.id,
    required this.status,
    required this.estimatedFare,
  });

  final String id;
  final String status;
  final int? estimatedFare;
}

class OtpApiUnavailable implements Exception {}

class RapidoApiFailure implements Exception {
  const RapidoApiFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

class OtpFailure implements Exception {
  const OtpFailure(this.message);

  final String message;

  @override
  String toString() => message;
}
