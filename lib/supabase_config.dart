import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  const SupabaseConfig._();

  static bool _ready = false;

  static bool get isReady => _ready;

  static String get url => dotenv.maybeGet('SUPABASE_URL') ?? '';

  static String get anonKey => dotenv.maybeGet('SUPABASE_ANON_KEY') ?? '';

  static String get redirectUrl =>
      dotenv.maybeGet('SUPABASE_REDIRECT_URL') ??
      'io.supabase.jeevanarogya://login-callback/';

  static String get oauthRedirectUrl {
    if (kIsWeb) {
      return Uri.base.origin;
    }
    return redirectUrl;
  }

  static Future<void> initialize() async {
    await dotenv.load(fileName: '.env');

    final hasCredentials = url.startsWith('https://') && anonKey.length > 40;
    if (!hasCredentials) {
      debugPrint(
        'Supabase credentials missing. Running Jeevan Arogya in demo mode.',
      );
      _ready = false;
      return;
    }

    await Supabase.initialize(url: url, anonKey: anonKey);
    _ready = true;
  }

  static SupabaseClient? get client {
    if (!_ready) {
      return null;
    }
    return Supabase.instance.client;
  }
}
