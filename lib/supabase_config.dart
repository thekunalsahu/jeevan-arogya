import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  const SupabaseConfig._();

  static bool _ready = false;
  static bool _envLoaded = false;
  static const _definedUrl = String.fromEnvironment('SUPABASE_URL');
  static const _definedAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const _definedRedirectUrl = String.fromEnvironment(
    'SUPABASE_REDIRECT_URL',
  );
  static const _fallbackUrl = 'https://swyerkuqipjjehjidxul.supabase.co';
  static const _fallbackAnonKey =
      'sb_publishable_FlQeYF2lAx55scQjv4gcqw_CJGn7hOu';

  static bool get isReady => _ready;

  static String get url {
    if (_definedUrl.isNotEmpty) {
      return _definedUrl;
    }
    final envUrl = _envValue('SUPABASE_URL');
    return envUrl.isNotEmpty ? envUrl : _fallbackUrl;
  }

  static String get anonKey {
    if (_definedAnonKey.isNotEmpty) {
      return _definedAnonKey;
    }
    final envAnonKey = _envValue('SUPABASE_ANON_KEY');
    return envAnonKey.isNotEmpty ? envAnonKey : _fallbackAnonKey;
  }

  static String get redirectUrl => _definedRedirectUrl.isNotEmpty
      ? _definedRedirectUrl
      : _envValue(
          'SUPABASE_REDIRECT_URL',
          fallback: 'io.supabase.jeevanarogya://login-callback/',
        );

  static String get oauthRedirectUrl {
    if (kIsWeb) {
      return Uri.base.origin;
    }
    return redirectUrl;
  }

  static Future<void> initialize() async {
    if (kIsWeb) {
      _envLoaded = false;
    } else {
      try {
        await dotenv.load(fileName: '.env');
        _envLoaded = true;
      } catch (_) {
        _envLoaded = false;
        debugPrint('No .env asset found. Checking dart-define values.');
      }
    }

    final hasCredentials = url.startsWith('https://') && anonKey.length > 40;
    if (!hasCredentials) {
      debugPrint(
        'Supabase credentials missing. OTP and live data are disabled.',
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

  static String _envValue(String key, {String fallback = ''}) {
    if (!_envLoaded) {
      return fallback;
    }
    return dotenv.maybeGet(key) ?? fallback;
  }
}
