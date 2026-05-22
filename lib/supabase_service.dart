import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_config.dart';
import 'supabase_models.dart';

class JeevanArogyaRepository {
  JeevanArogyaRepository({SupabaseClient? client})
    : _client = client ?? SupabaseConfig.client;

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

  Future<bool> signInWithGoogle() async {
    final client = _requireClient();
    return client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: SupabaseConfig.oauthRedirectUrl,
    );
  }

  Future<void> sendPhoneOtp(String phone) async {
    final client = _requireClient();
    await client.auth.signInWithOtp(phone: _normalizePhone(phone));
  }

  Future<void> verifyPhoneOtp({
    required String phone,
    required String token,
  }) async {
    final client = _requireClient();
    await client.auth.verifyOTP(
      phone: _normalizePhone(phone),
      token: token.replaceAll(' ', ''),
      type: OtpType.sms,
    );
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
    required String email,
  }) async {
    final client = _requireClient();
    final userId = _requireUserId();
    await client.from('profiles').upsert({
      'id': userId,
      'full_name': fullName,
      'phone': phone,
      'email': email,
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

  String _normalizePhone(String phone) {
    final compact = phone.replaceAll(RegExp(r'\s+'), '');
    if (compact.startsWith('+')) {
      return compact;
    }
    return '+91$compact';
  }
}
