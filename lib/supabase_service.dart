import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_config.dart';
import 'supabase_models.dart';

class JeevanArogyaRepository {
  JeevanArogyaRepository({SupabaseClient? client})
    : _client = client ?? SupabaseConfig.client;

  final SupabaseClient? _client;
  OtpProvider _lastOtpProvider = OtpProvider.supabaseEmail;

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

    try {
      await _sendViaEmailOtpService(normalizedEmail);
      _lastOtpProvider = OtpProvider.githubEmailOtpService;
      return normalizedEmail;
    } on OtpApiUnavailable {
      final client = _requireClient();
      await client.auth.signInWithOtp(
        email: normalizedEmail,
        data: {'full_name': fullName.trim(), 'email': normalizedEmail},
      );
      _lastOtpProvider = OtpProvider.supabaseEmail;
    }

    return normalizedEmail;
  }

  Future<bool> verifyEmailOtp({
    required String email,
    required String token,
  }) async {
    if (_lastOtpProvider == OtpProvider.githubEmailOtpService) {
      await _verifyViaEmailOtpService(normalizeEmail(email), token);
      return false;
    }

    final client = _requireClient();
    await client.auth.verifyOTP(
      email: normalizeEmail(email),
      token: token.replaceAll(' ', ''),
      type: OtpType.email,
    );
    return true;
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

  Future<void> _sendViaEmailOtpService(String email) async {
    final response = await http
        .post(
          _apiUri('send_email_otp'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email}),
        )
        .timeout(const Duration(seconds: 12));
    final data = _decodeResponse(response);
    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        data['ok'] != true) {
      throw OtpFailure(
        _cleanOtpMessage(
          data['error']?.toString() ?? 'Email OTP send failed.',
        ),
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

enum OtpProvider { supabaseEmail, githubEmailOtpService }

class OtpApiUnavailable implements Exception {}

class OtpFailure implements Exception {
  const OtpFailure(this.message);

  final String message;

  @override
  String toString() => message;
}
