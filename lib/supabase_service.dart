import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_config.dart';
import 'supabase_models.dart';

class JeevanArogyaRepository {
  JeevanArogyaRepository({SupabaseClient? client})
    : _client = client ?? SupabaseConfig.client;

  final SupabaseClient? _client;
  OtpProvider _lastOtpProvider = OtpProvider.supabase;

  bool get isConnected => _client != null;

  User? get currentUser => _client?.auth.currentUser;

  Stream<AuthState> get authStateChanges {
    final client = _client;
    if (client == null) {
      return const Stream.empty();
    }
    return client.auth.onAuthStateChange;
  }

  Future<String> sendPhoneOtp({
    required String phone,
    required String fullName,
  }) async {
    final normalizedPhone = normalizePhone(phone);

    try {
      await _sendViaTwilioVerify(normalizedPhone);
      _lastOtpProvider = OtpProvider.twilioVerify;
      return normalizedPhone;
    } catch (_) {
      final client = _requireClient();
      await client.auth.signInWithOtp(
        phone: normalizedPhone,
        data: {'full_name': fullName.trim(), 'phone': normalizedPhone},
      );
      _lastOtpProvider = OtpProvider.supabase;
    }

    return normalizedPhone;
  }

  Future<bool> verifyPhoneOtp({
    required String phone,
    required String token,
  }) async {
    if (_lastOtpProvider == OtpProvider.twilioVerify) {
      await _verifyViaTwilioVerify(normalizePhone(phone), token);
      return false;
    }

    final client = _requireClient();
    await client.auth.verifyOTP(
      phone: normalizePhone(phone),
      token: token.replaceAll(' ', ''),
      type: OtpType.sms,
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
      'phone': normalizePhone(phone),
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

  String normalizePhone(String phone) {
    final trimmed = phone.trim();
    final digits = trimmed.replaceAll(RegExp(r'\D'), '');
    if (trimmed.startsWith('+')) {
      return '+$digits';
    }
    if (digits.startsWith('91') && digits.length == 12) {
      return '+$digits';
    }
    return '+91$digits';
  }

  Uri _apiUri(String path) {
    final origin = Uri.base.origin;
    if (!origin.startsWith('http')) {
      throw StateError('Twilio API is available only on web deployment.');
    }
    return Uri.parse('$origin/api/$path');
  }

  Future<void> _sendViaTwilioVerify(String phone) async {
    final response = await http
        .post(
          _apiUri('send_otp'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'phone': phone}),
        )
        .timeout(const Duration(seconds: 12));
    final data = _decodeResponse(response.body);
    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        data['ok'] != true) {
      throw StateError(data['error']?.toString() ?? 'Twilio OTP send failed.');
    }
  }

  Future<void> _verifyViaTwilioVerify(String phone, String token) async {
    final response = await http
        .post(
          _apiUri('verify_otp'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'phone': phone, 'code': token.replaceAll(' ', '')}),
        )
        .timeout(const Duration(seconds: 12));
    final data = _decodeResponse(response.body);
    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        data['ok'] != true) {
      throw StateError(data['error']?.toString() ?? 'Invalid or expired OTP.');
    }
  }

  Map<String, dynamic> _decodeResponse(String body) {
    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    return {'ok': false, 'error': 'Unexpected OTP server response.'};
  }
}

enum OtpProvider { supabase, twilioVerify }
