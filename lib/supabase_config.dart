import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  const SupabaseConfig._();

  static bool _ready = false;
  static const _definedUrl = String.fromEnvironment('SUPABASE_URL');
  static const _definedAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const _definedRedirectUrl = String.fromEnvironment(
    'SUPABASE_REDIRECT_URL',
  );

  static bool get isReady => _ready;

  static String get url => _definedUrl.isNotEmpty
      ? _definedUrl
      : dotenv.maybeGet('SUPABASE_URL') ?? '';

  static String get anonKey => _definedAnonKey.isNotEmpty
      ? _definedAnonKey
      : dotenv.maybeGet('SUPABASE_ANON_KEY') ?? '';

  static String get redirectUrl => _definedRedirectUrl.isNotEmpty
      ? _definedRedirectUrl
      : dotenv.maybeGet('SUPABASE_REDIRECT_URL') ??
            'io.supabase.jeevanarogya://login-callback/';

  static String get oauthRedirectUrl {
    if (kIsWeb) {
      return Uri.base.origin;
    }
    return redirectUrl;
  }

  static Future<void> initialize() async {
    try {
      await dotenv.load(fileName: '.env');
    } catch (_) {
      debugPrint('No .env asset found. Checking dart-define values.');
    }

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
