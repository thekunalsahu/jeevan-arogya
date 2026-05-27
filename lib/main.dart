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
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'supabase_config.dart';
import 'supabase_models.dart';
import 'supabase_service.dart';

final appLocation = AppLocationController();
final appData = AppDataController();
final liveHealthData = LiveHealthDataController();
final appTheme = AppThemeController();
final appLanguage = AppLanguageController();

class AppTextEntry {
  const AppTextEntry({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.attachmentName = '',
    this.attachmentType = '',
    this.attachmentData = '',
    this.attachmentMime = '',
    this.attachmentSize = 0,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String attachmentName;
  final String attachmentType;
  final String attachmentData;
  final String attachmentMime;
  final int attachmentSize;

  Map<String, dynamic> toJson() => {
    'title': title,
    'subtitle': subtitle,
    'icon': icon.codePoint,
    'color': color.toARGB32(),
    'attachmentName': attachmentName,
    'attachmentType': attachmentType,
    'attachmentData': attachmentData,
    'attachmentMime': attachmentMime,
    'attachmentSize': attachmentSize,
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
      attachmentData: map['attachmentData']?.toString() ?? '',
      attachmentMime: map['attachmentMime']?.toString() ?? '',
      attachmentSize: (map['attachmentSize'] as num?)?.toInt() ?? 0,
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

  void removeEntry(List<AppTextEntry> target, AppTextEntry entry) {
    target.remove(entry);
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

  void clearActivityData() {
    threads.clear();
    appointments.clear();
    cabRequests.clear();
    notifications.clear();
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

enum AppVisualTheme { light, dark, black }

class AppThemeController extends ChangeNotifier {
  static const _storageKey = 'jeevan_arogya_visual_theme_v1';

  AppVisualTheme _mode = AppVisualTheme.light;

  AppVisualTheme get mode => _mode;
  bool get isDark => _mode != AppVisualTheme.light;
  Brightness get brightness => isDark ? Brightness.dark : Brightness.light;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    _mode = AppVisualTheme.values.firstWhere(
      (theme) => theme.name == raw,
      orElse: () => AppVisualTheme.light,
    );
  }

  Future<void> setMode(AppVisualTheme mode) async {
    if (_mode == mode) {
      return;
    }
    _mode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, mode.name);
  }
}

extension AppVisualThemeLabel on AppVisualTheme {
  String get label => switch (this) {
    AppVisualTheme.light => 'Light',
    AppVisualTheme.dark => 'Dark',
    AppVisualTheme.black => '100% Black',
  };

  IconData get icon => switch (this) {
    AppVisualTheme.light => Icons.light_mode_rounded,
    AppVisualTheme.dark => Icons.dark_mode_rounded,
    AppVisualTheme.black => Icons.contrast_rounded,
  };
}

class AppThemePalette {
  const AppThemePalette({
    required this.pageTop,
    required this.pageBottom,
    required this.shell,
    required this.card,
    required this.soft,
    required this.text,
    required this.muted,
    required this.line,
    required this.shadow,
  });

  final Color pageTop;
  final Color pageBottom;
  final Color shell;
  final Color card;
  final Color soft;
  final Color text;
  final Color muted;
  final Color line;
  final Color shadow;

  static AppThemePalette get current => const AppThemePalette(
    pageTop: Colors.white,
    pageBottom: AppColors.bg,
    shell: Color(0xFFEFF4FA),
    card: Colors.white,
    soft: AppColors.soft,
    text: AppColors.text,
    muted: AppColors.muted,
    line: AppColors.line,
    shadow: Colors.black,
  );
}

enum AppLanguage { english, hindi }

class AppLanguageController extends ChangeNotifier {
  static const _storageKey = 'jeevan_arogya_language_v1';

  AppLanguage _mode = AppLanguage.english;

  AppLanguage get mode => _mode;
  bool get isHindi => _mode == AppLanguage.hindi;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    _mode = AppLanguage.values.firstWhere(
      (language) => language.name == raw,
      orElse: () => AppLanguage.english,
    );
  }

  Future<void> setMode(AppLanguage mode) async {
    if (_mode == mode) {
      return;
    }
    _mode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, mode.name);
  }
}

extension AppLanguageLabel on AppLanguage {
  String get label => switch (this) {
    AppLanguage.english => 'English',
    AppLanguage.hindi => 'हिन्दी',
  };

  String get shortLabel => switch (this) {
    AppLanguage.english => 'EN',
    AppLanguage.hindi => 'HI',
  };
}

String tr(String key) {
  return _enText[key] ?? key;
}

String trHello(String firstName) {
  return 'Hello, $firstName';
}

String tt(String text) {
  return text;
}

const _enText = {
  'helpToday': 'How can we help\nyou today?',
  'searchHome': 'Search doctors, hospitals, services...',
  'findDoctors': 'Find Doctors',
  'bookAppointments': 'Book appointments',
  'nearbyHospitals': 'Nearby Hospitals',
  'findHospitalsNear': 'Find hospitals near you',
  'emergencyCab': 'Emergency Cab',
  'bookCabEmergency': 'Book a cab in emergency',
  'healthSchemes': 'Health Schemes',
  'ayushmanMore': 'Ayushman Bharat & more',
  'medicalStores': 'Medical Stores',
  'janPharmacies': 'Jan Aushadhi & pharmacies',
  'healthRecords': 'Health Records',
  'medicalInfo': 'Your medical info',
  'aiAssistant': 'ArogyaX',
  'aiSubtitle': 'AI health guide',
  'viewAll': 'View all',
  'enableGpsCare': 'Enable GPS for nearby care',
  'gpsCareSubtitle':
      'Nearby hospitals and emergency distances appear only after GPS permission.',
  'fetchHospitals': 'Fetching hospitals',
  'fetchHospitalsSub': 'Checking hospitals near your GPS.',
  'noHospitals': 'No nearby hospitals found',
  'noHospitalsSub': 'Refresh GPS or try again.',
  'language': 'Language',
  'arogyaxTitle': 'ArogyaX Assistant',
  'askArogyaX': 'Ask about symptoms, specialist, hospital, medicine...',
  'send': 'Send',
  'uploadReport': 'Upload Report',
  'uploadImage': 'Upload Image',
  'clearUpload': 'Clear upload',
  'assistantIntro':
      'Tell me your health concern. I can read uploaded report images/text and use your nearby doctors, hospitals and medical stores.',
};

const hiText = {
  'helpToday': 'आज आपकी कैसे\nमदद करें?',
  'searchHome': 'डॉक्टर, अस्पताल, सेवाएं खोजें...',
  'findDoctors': 'डॉक्टर खोजें',
  'bookAppointments': 'अपॉइंटमेंट बुक करें',
  'nearbyHospitals': 'नजदीकी अस्पताल',
  'findHospitalsNear': 'पास के अस्पताल देखें',
  'emergencyCab': 'इमरजेंसी कैब',
  'bookCabEmergency': 'आपातकाल में कैब बुक करें',
  'healthSchemes': 'स्वास्थ्य योजनाएं',
  'ayushmanMore': 'आयुष्मान भारत और अन्य',
  'medicalStores': 'मेडिकल स्टोर',
  'janPharmacies': 'जन औषधि और फार्मेसी',
  'healthRecords': 'हेल्थ रिकॉर्ड',
  'medicalInfo': 'आपकी मेडिकल जानकारी',
  'aiAssistant': 'आरोग्यX',
  'aiSubtitle': 'AI स्वास्थ्य गाइड',
  'viewAll': 'सभी देखें',
  'enableGpsCare': 'नजदीकी देखभाल के लिए GPS चालू करें',
  'gpsCareSubtitle': 'GPS अनुमति के बाद ही नजदीकी अस्पताल और दूरी दिखाई जाएगी।',
  'fetchHospitals': 'अस्पताल खोजे जा रहे हैं',
  'fetchHospitalsSub': 'OpenStreetMap से नजदीकी अस्पताल लोड हो रहे हैं।',
  'noHospitals': 'नजदीकी अस्पताल नहीं मिले',
  'noHospitalsSub': 'GPS फिर से रिफ्रेश करें या दोबारा कोशिश करें।',
  'language': 'भाषा',
  'arogyaxTitle': 'आरोग्यX असिस्टेंट',
  'askArogyaX': 'लक्षण, विशेषज्ञ, अस्पताल, दवाई पूछें...',
  'send': 'भेजें',
  'uploadReport': 'रिपोर्ट अपलोड',
  'uploadImage': 'इमेज अपलोड',
  'clearUpload': 'अपलोड हटाएं',
  'assistantIntro':
      'अपनी स्वास्थ्य समस्या बताएं। मैं रिपोर्ट इमेज/टेक्स्ट पढ़कर पास के डॉक्टर, अस्पताल और मेडिकल स्टोर के हिसाब से मदद करूंगा।',
};

const exactHiText = {
  'Home': 'होम',
  'Appointments': 'अपॉइंटमेंट',
  'Messages': 'मैसेज',
  'Profile': 'प्रोफाइल',
  'SOS': 'SOS',
  'Find Doctors': 'डॉक्टर खोजें',
  'Search specialists and book appointment slots':
      'विशेषज्ञ खोजें और अपॉइंटमेंट बुक करें',
  'Emergency Cab': 'इमरजेंसी कैब',
  'Request a GPS-based ride to nearest hospital':
      'नजदीकी अस्पताल तक GPS आधारित राइड',
  'Nearby Hospitals': 'नजदीकी अस्पताल',
  'Open live GPS map, call and directions': 'GPS मैप, कॉल और दिशा देखें',
  'Emergency SOS': 'इमरजेंसी SOS',
  'Trigger emergency alert and call your priority contact':
      'इमरजेंसी अलर्ट और प्राथमिक संपर्क को कॉल',
  'Medical Stores': 'मेडिकल स्टोर',
  'Find affordable medicine stores near you': 'पास के दवा स्टोर खोजें',
  'Health Schemes': 'स्वास्थ्य योजनाएं',
  'PM-JAY, CGHS, ESIC, ABHA and government portals':
      'PM-JAY, CGHS, ESIC, ABHA और सरकारी पोर्टल',
  'Health Records': 'हेल्थ रिकॉर्ड',
  'Prescriptions': 'प्रिस्क्रिप्शन',
  'Allergies & Conditions': 'एलर्जी और बीमारियां',
  'Vital Health Info': 'जरूरी स्वास्थ्य जानकारी',
  'My Health': 'मेरा स्वास्थ्य',
  'My Account': 'मेरा अकाउंट',
  'Emergency Contacts': 'इमरजेंसी संपर्क',
  'Address Book': 'एड्रेस बुक',
  'Notification Settings': 'नोटिफिकेशन सेटिंग्स',
  'Help & Support': 'मदद और सपोर्ट',
  'About Us': 'हमारे बारे में',
  'Clear Saved Data': 'सेव डेटा मिटाएं',
  'Logout': 'लॉगआउट',
  'Edit Profile': 'प्रोफाइल एडिट करें',
  'Save Profile': 'प्रोफाइल सेव करें',
  'New Message': 'नया मैसेज',
  'Send Message': 'मैसेज भेजें',
  'Search': 'खोजें',
  'No exact result found': 'सटीक परिणाम नहीं मिला',
  'You can still open these live services and continue from there.':
      'आप इन सेवाओं को खोलकर आगे बढ़ सकते हैं।',
  'Doctors near your area': 'आपके पास डॉक्टर',
  'Use GPS to personalize doctor availability':
      'डॉक्टर उपलब्धता के लिए GPS इस्तेमाल करें',
  'Detecting GPS...': 'GPS खोजा जा रहा है...',
  'Enable GPS Location': 'GPS लोकेशन चालू करें',
  'GPS...': 'GPS...',
  'GPS': 'GPS',
  'Filter Doctors': 'डॉक्टर फिल्टर करें',
  'All': 'सभी',
  'Doctor': 'डॉक्टर',
  'Cardiologist': 'हृदय रोग विशेषज्ञ',
  'Orthopedic': 'हड्डी रोग विशेषज्ञ',
  'General Physician': 'जनरल फिजिशियन',
  'ENT': 'ENT',
  'Neurologist': 'न्यूरोलॉजिस्ट',
  'Dentist': 'डेंटिस्ट',
  'Pediatrician': 'बाल रोग विशेषज्ञ',
  'Gynecologist': 'स्त्री रोग विशेषज्ञ',
  'Dermatologist': 'त्वचा रोग विशेषज्ञ',
  'Fetching doctors': 'डॉक्टर खोजे जा रहे हैं',
  'OpenStreetMap se live nearby doctor listings aa rahi hain.':
      'OpenStreetMap से पास के डॉक्टर लोड हो रहे हैं।',
  'No verified live doctors found': 'पास में डॉक्टर नहीं मिले',
  'Try All filter or refresh GPS.': 'सभी फिल्टर चुनें या GPS रिफ्रेश करें।',
  'Live OpenStreetMap doctor data': 'OpenStreetMap डॉक्टर डेटा',
  'About Doctor': 'डॉक्टर के बारे में',
  'Read more': 'और पढ़ें',
  'Next Available Slots': 'अगले उपलब्ध स्लॉट',
  'Reason for visit': 'विजिट का कारण',
  'Book Appointment': 'अपॉइंटमेंट बुक करें',
  'Consultation Fee': 'कंसल्टेशन फीस',
  'Available Today': 'आज उपलब्ध',
  'Location': 'लोकेशन',
  'Contact for details': 'जानकारी के लिए संपर्क करें',
  'Call': 'कॉल',
  'Call to confirm': 'कन्फर्म करने के लिए कॉल करें',
  'Medical Store': 'मेडिकल स्टोर',
  'Jan Aushadhi': 'जन औषधि',
  'Filter Medical Stores': 'मेडिकल स्टोर फिल्टर करें',
  'All medical stores': 'सभी मेडिकल स्टोर',
  'Jan Aushadhi only': 'केवल जन औषधि',
  'No medical store live result found': 'मेडिकल स्टोर नहीं मिला',
  'OpenStreetMap me nearby medical store listing nahi mili.':
      'OpenStreetMap में पास की मेडिकल स्टोर लिस्टिंग नहीं मिली।',
  'Add Health Record': 'हेल्थ रिकॉर्ड जोड़ें',
  'Report name': 'रिपोर्ट का नाम',
  'Notes, file link, doctor, date': 'नोट्स, फाइल, डॉक्टर, तारीख',
  'Save Record': 'रिकॉर्ड सेव करें',
  'Upload File': 'फाइल अपलोड',
  'Upload Image': 'इमेज अपलोड',
  'Save': 'सेव',
  'Title': 'शीर्षक',
  'Details': 'जानकारी',
  'No uploaded health records yet.': 'अभी कोई हेल्थ रिकॉर्ड अपलोड नहीं है।',
  'ArogyaX thinking': 'ArogyaX सोच रहा है',
  'Report, location and nearby care context is being checked.':
      'रिपोर्ट, लोकेशन और पास की स्वास्थ्य जानकारी देखी जा रही है।',
  'Change theme': 'थीम बदलें',
  'Light': 'लाइट',
  'Dark': 'डार्क',
  '100% Black': '100% ब्लैक',
  'Notifications': 'नोटिफिकेशन',
  'No notifications yet': 'अभी कोई नोटिफिकेशन नहीं',
  'New appointment, SOS and cab updates will appear here after activity.':
      'अपॉइंटमेंट, SOS और कैब अपडेट गतिविधि के बाद यहां दिखेंगे।',
  'Enable GPS to find doctors': 'डॉक्टर खोजने के लिए GPS चालू करें',
  'Doctor availability and nearby appointment details unlock after live GPS permission.':
      'लाइव GPS अनुमति के बाद डॉक्टर उपलब्धता और पास के स्लॉट दिखेंगे।',
  'Enable GPS for Medical Stores': 'मेडिकल स्टोर खोजने के लिए GPS चालू करें',
  'Nearest store list, distance and map are hidden until live GPS permission is allowed.':
      'लाइव GPS अनुमति मिलने तक नजदीकी स्टोर, दूरी और मैप छिपे रहेंगे।',
  'Fetching Medical Stores': 'मेडिकल स्टोर खोजे जा रहे हैं',
  'OpenStreetMap se live pharmacy data load ho raha hai.':
      'OpenStreetMap से पास की फार्मेसी जानकारी लोड हो रही है।',
  'No appointments yet': 'अभी कोई अपॉइंटमेंट नहीं',
  'Book a doctor appointment and it will appear here permanently.':
      'डॉक्टर अपॉइंटमेंट बुक करें, वह यहां स्थायी रूप से दिखेगा।',
  'No messages yet': 'अभी कोई मैसेज नहीं',
  'Start a message or book appointments to create live threads.':
      'मैसेज शुरू करें या अपॉइंटमेंट बुक करें, थ्रेड यहां दिखेंगे।',
  'Start Message': 'मैसेज शुरू करें',
  'New': 'नया',
  'Confirm Emergency Ride': 'इमरजेंसी राइड कन्फर्म करें',
  'Pickup Location': 'पिकअप लोकेशन',
  'Drop Location': 'ड्रॉप लोकेशन',
  'Ride Type': 'राइड प्रकार',
  'Payment Method': 'पेमेंट तरीका',
  'Select ride type': 'राइड प्रकार चुनें',
  'Select payment': 'पेमेंट चुनें',
  'Hatchback': 'हैचबैक',
  'Sedan': 'सेडान',
  'SUV': 'SUV',
  'Ambulance': 'एम्बुलेंस',
  'Cash': 'कैश',
  'Online': 'ऑनलाइन',
  'Request Emergency Cab': 'इमरजेंसी कैब रिक्वेस्ट करें',
  'Requesting cab...': 'कैब रिक्वेस्ट हो रही है...',
  'Drivers will be notified about the emergency':
      'ड्राइवरों को इमरजेंसी के बारे में सूचित किया जाएगा',
  'Cab booking saved': 'कैब बुकिंग सेव हुई',
  'Cab booking requested': 'कैब बुकिंग रिक्वेस्ट हुई',
  'Live emergency route': 'लाइव इमरजेंसी रूट',
  'Hospitals near you': 'आपके पास अस्पताल',
  'Medical stores near you': 'आपके पास मेडिकल स्टोर',
  'Directions': 'दिशा',
  'Call Now': 'अभी कॉल करें',
  'Finding nearby hospitals': 'पास के अस्पताल खोजे जा रहे हैं',
  'Fetching live OpenStreetMap results around your GPS.':
      'आपके GPS के आसपास OpenStreetMap परिणाम लोड हो रहे हैं।',
  'No live hospital found nearby': 'पास में लाइव अस्पताल नहीं मिला',
  'Tap GPS again or call emergency services.':
      'GPS फिर दबाएं या इमरजेंसी सेवा को कॉल करें।',
  'Enable GPS for emergency cab': 'इमरजेंसी कैब के लिए GPS चालू करें',
  'Enable GPS for nearby hospitals': 'पास के अस्पतालों के लिए GPS चालू करें',
  'No verified live hospitals found': 'पास में सत्यापित अस्पताल नहीं मिले',
  'Refresh GPS and try again.': 'GPS रिफ्रेश करें और फिर कोशिश करें।',
  'Ayushman Bharat': 'आयुष्मान भारत',
  'Check Eligibility': 'पात्रता जांचें',
  'Eligibility': 'पात्रता',
  'Documents': 'दस्तावेज',
  'Ayushman Bharat PM-JAY': 'आयुष्मान भारत PM-JAY',
  'Cashless hospital care up to Rs. 5,00,000':
      '₹5,00,000 तक कैशलेस अस्पताल इलाज',
  'Jan Aushadhi Yojana': 'जन औषधि योजना',
  'Affordable generic medicines': 'सस्ती जेनेरिक दवाइयां',
  'Central Government Health Scheme': 'केंद्रीय सरकारी स्वास्थ्य योजना',
  'Employees State Insurance Scheme': 'कर्मचारी राज्य बीमा योजना',
  'ABHA Health ID': 'ABHA हेल्थ ID',
  'Digital health account': 'डिजिटल हेल्थ अकाउंट',
  'Vaccination certificates and services': 'टीकाकरण प्रमाणपत्र और सेवाएं',
  'Open File': 'फाइल खोलें',
  'Attachment preview unavailable': 'अटैचमेंट प्रीव्यू उपलब्ध नहीं',
  'File saved in app data': 'फाइल ऐप डेटा में सेव है',
  'Clear saved data?': 'सेव डेटा मिटाएं?',
  'Cancel': 'रद्द करें',
  'Clear Data': 'डेटा मिटाएं',
  'Delete entry?': 'एंट्री मिटाएं?',
  'Delete': 'मिटाएं',
  'Saving...': 'सेव हो रहा है...',
  'Other Government Schemes': 'अन्य सरकारी योजनाएं',
  'Messages, cab requests, doctor appointments and activity notifications saved on this device will be deleted.':
      'इस डिवाइस पर सेव मैसेज, कैब रिक्वेस्ट, डॉक्टर अपॉइंटमेंट और गतिविधि नोटिफिकेशन मिटा दिए जाएंगे।',
  'Saved app activity cleared.': 'सेव ऐप गतिविधि मिटा दी गई।',
  'This saved item and its uploaded attachment will be removed from this device.':
      'यह सेव आइटम और उसका अपलोडेड अटैचमेंट इस डिवाइस से हट जाएगा।',
  'Deleted.': 'मिटा दिया गया।',
  'Add Contact': 'संपर्क जोड़ें',
  'Name': 'नाम',
  'Phone number': 'फोन नंबर',
  'Relation': 'रिश्ता',
  'Name and phone are required.': 'नाम और फोन नंबर जरूरी हैं।',
  'Full name': 'पूरा नाम',
  'Email address': 'ईमेल पता',
  'Contact number': 'संपर्क नंबर',
  'Enter a valid name and email.': 'सही नाम और ईमेल दर्ज करें।',
  'Doctor, hospital, or contact name': 'डॉक्टर, अस्पताल या संपर्क का नाम',
  'Message': 'मैसेज',
  'Name and message are required.': 'नाम और मैसेज जरूरी हैं।',
  'Type a message...': 'मैसेज लिखें...',
  'Custom message': 'कस्टम मैसेज',
  'Address or landmark': 'पता या लैंडमार्क',
  'Using your live location': 'आपकी लाइव लोकेशन इस्तेमाल हो रही है',
  'Location based care': 'लोकेशन आधारित देखभाल',
  'Live hospital data will appear after fetch':
      'फेच होने के बाद लाइव अस्पताल डेटा दिखेगा',
  'Enable GPS to fetch nearby care': 'पास की देखभाल खोजने के लिए GPS चालू करें',
  'Locating': 'लोकेशन खोज रहे हैं',
  'Use GPS': 'GPS इस्तेमाल करें',
  'Finding live doctors': 'लाइव डॉक्टर खोजे जा रहे हैं',
  'Nearby doctor listings are loading.':
      'पास के डॉक्टरों की सूची लोड हो रही है।',
  'Next doctor available': 'अगला डॉक्टर उपलब्ध',
  'Jeevan Arogya connects patients to nearby care.':
      'जीवन आरोग्य मरीजों को पास की स्वास्थ्य सेवा से जोड़ता है।',
  'Maps use OpenStreetMap tiles.':
      'मैप में OpenStreetMap टाइल्स इस्तेमाल होती हैं।',
  'Supabase powers auth and live database features.':
      'Auth और लाइव डेटाबेस फीचर Supabase से चलते हैं।',
};

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
    final palette = AppThemePalette.current;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Jeevan Arogya',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: palette.pageBottom,
        fontFamily: 'Roboto',
        textTheme: ThemeData(
          brightness: Brightness.light,
          fontFamily: 'Roboto',
        ).textTheme.apply(bodyColor: palette.text, displayColor: palette.text),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: palette.soft,
          hintStyle: TextStyle(color: palette.muted),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.navy,
          brightness: Brightness.light,
          primary: AppColors.navy,
          surface: palette.card,
        ),
      ),
      builder: (context, child) => ColoredBox(
        color: palette.shell,
        child: DefaultTextStyle.merge(
          style: TextStyle(color: palette.text),
          child: IconTheme.merge(
            data: IconThemeData(color: palette.text),
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
    this.phone = '',
    this.address = '',
    this.about = '',
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
  final String phone;
  final String address;
  final String about;

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
    message = 'Fetching live OpenStreetMap health data around your GPS...';
    notifyListeners();

    try {
      final query = _overpassQuery(center);
      final decoded = await _fetchLivePlaces(center, query);
      _applyElements(decoded['elements'], center);
      loaded = true;
      _lastCenter = center;
      message =
          'Live data: ${hospitals.length} hospitals, ${doctors.length} doctors, ${kendras.length} medical stores.';
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

  Future<Map<String, dynamic>> _fetchLivePlaces(
    LatLng center,
    String query,
  ) async {
    final errors = <String>[];
    final proxy = _healthPlacesProxyUri(center);
    if (proxy != null) {
      try {
        final response = await http
            .get(proxy, headers: {'Accept': 'application/json'})
            .timeout(const Duration(seconds: 42));
        if (response.statusCode >= 200 && response.statusCode < 300) {
          return _decodeHealthJson(response.body, 'health proxy');
        }
        errors.add(
          'health proxy ${response.statusCode}: ${_shortBody(response.body)}',
        );
      } catch (error) {
        errors.add('health proxy: $error');
      }
    }

    const endpoints = [
      'https://overpass-api.de/api/interpreter',
      'https://overpass.kumi.systems/api/interpreter',
    ];
    for (final endpoint in endpoints) {
      try {
        final response = await http
            .post(
              Uri.parse(endpoint),
              headers: {
                'Accept': 'application/json',
                'Content-Type': 'text/plain; charset=utf-8',
              },
              body: query,
            )
            .timeout(const Duration(seconds: 35));
        if (response.statusCode >= 200 && response.statusCode < 300) {
          return _decodeHealthJson(response.body, endpoint);
        }
        errors.add(
          '$endpoint ${response.statusCode}: ${_shortBody(response.body)}',
        );
      } catch (error) {
        errors.add('$endpoint: $error');
      }
    }

    throw StateError(errors.join(' | '));
  }

  Uri? _healthPlacesProxyUri(LatLng center) {
    final base = Uri.base;
    if (base.scheme != 'http' && base.scheme != 'https') {
      return null;
    }
    return Uri(
      scheme: base.scheme,
      host: base.host,
      port: base.hasPort ? base.port : null,
      path: '/api/health_places',
      queryParameters: {
        'lat': center.latitude.toStringAsFixed(6),
        'lng': center.longitude.toStringAsFixed(6),
      },
    );
  }

  Map<String, dynamic> _decodeHealthJson(String body, String source) {
    final trimmed = body.trimLeft();
    if (trimmed.startsWith('<')) {
      throw FormatException('$source returned app HTML instead of JSON');
    }
    final decoded = jsonDecode(body);
    if (decoded is! Map) {
      throw FormatException('$source returned invalid JSON');
    }
    final map = decoded.cast<String, dynamic>();
    if (map['elements'] is! List) {
      throw FormatException('$source response missing places');
    }
    return map;
  }

  String _shortBody(String body) {
    final cleaned = body.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (cleaned.length <= 160) {
      return cleaned;
    }
    return '${cleaned.substring(0, 160)}...';
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
      final address = _addressFromTags(tags);
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
          final about = _doctorAboutFromTags(
            name: name,
            speciality: speciality,
            address: address,
            phone: phone,
            tags: tags,
          );
          doctors.add(
            Doctor(
              name: name,
              specialty: speciality,
              experience: 'Verified on OpenStreetMap',
              degree: phone.isEmpty ? 'Contact for details' : phone,
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
              phone: phone,
              address: address,
              about: about,
            ),
          );
        }
      }

      if (isPharmacy) {
        final key = _placeKey(name, point);
        if (seenKendras.add(key)) {
          final area = _cleanName(tags['addr:suburb'] ?? tags['addr:city']);
          final storeType = isJanAushadhi ? 'Jan Aushadhi' : 'Medical Store';
          kendras.add(
            Place(
              name,
              formatDistanceKm(distanceKm(center, point)),
              area.isEmpty ? storeType : '$storeType - $area',
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

  String _addressFromTags(Map<String, dynamic> tags) {
    final direct = _cleanName(
      tags['addr:full'] ?? tags['addr:street'] ?? tags['addr:place'],
    );
    final suburb = _cleanName(
      tags['addr:suburb'] ?? tags['addr:neighbourhood'],
    );
    final city = _cleanName(tags['addr:city']);
    final parts = [
      direct,
      suburb,
      city,
    ].where((part) => part.isNotEmpty).toSet().toList();
    return parts.join(', ');
  }

  String _doctorAboutFromTags({
    required String name,
    required String speciality,
    required String address,
    required String phone,
    required Map<String, dynamic> tags,
  }) {
    final description = _cleanName(
      tags['description'] ?? tags['operator'] ?? tags['healthcare:speciality'],
    );
    if (description.isNotEmpty &&
        description.toLowerCase() != name.toLowerCase()) {
      return description;
    }
    final location = address.isEmpty ? 'your selected GPS area' : address;
    final contact = phone.isEmpty
        ? 'Call before visiting to confirm timings and availability.'
        : 'Contact: $phone.';
    return '$name is listed as a $speciality provider near $location. $contact';
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
        label: Text(tt(label)),
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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!appLocation.resolved && !appLocation.loading) {
        unawaited(appLocation.requestCurrentLocation());
      }
    });
  }

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
    final palette = AppThemePalette.current;
    return Container(
      width: 236,
      decoration: BoxDecoration(
        color: palette.card,
        border: Border(right: BorderSide(color: palette.line)),
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
                backgroundColor: palette.card,
                indicatorColor: AppColors.navy,
                selectedIconTheme: const IconThemeData(color: Colors.white),
                selectedLabelTextStyle: const TextStyle(
                  color: AppColors.navy,
                  fontWeight: FontWeight.w900,
                ),
                unselectedLabelTextStyle: TextStyle(
                  color: palette.muted,
                  fontWeight: FontWeight.w700,
                ),
                destinations: [
                  NavigationRailDestination(
                    icon: const Icon(Icons.home_outlined),
                    selectedIcon: const Icon(Icons.home_rounded),
                    label: Text(tt('Home')),
                  ),
                  NavigationRailDestination(
                    icon: const Icon(Icons.calendar_today_outlined),
                    selectedIcon: const Icon(Icons.calendar_month_rounded),
                    label: Text(tt('Appointments')),
                  ),
                  NavigationRailDestination(
                    icon: const Icon(Icons.sos_rounded),
                    selectedIcon: const Icon(Icons.sos_rounded),
                    label: Text(tt('SOS')),
                  ),
                  NavigationRailDestination(
                    icon: const Icon(Icons.chat_bubble_outline_rounded),
                    selectedIcon: const Icon(Icons.chat_bubble_rounded),
                    label: Text(tt('Messages')),
                  ),
                  NavigationRailDestination(
                    icon: const Icon(Icons.person_outline_rounded),
                    selectedIcon: const Icon(Icons.person_rounded),
                    label: Text(tt('Profile')),
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
            trHello(profile.firstName),
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            tr('helpToday'),
            style: TextStyle(
              color: AppThemePalette.current.text,
              fontSize: 27,
              height: 1.08,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 22),
          SearchBox(
            hint: tr('searchHome'),
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
                title: tr('findDoctors'),
                subtitle: tr('bookAppointments'),
                color: AppColors.blue,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FindDoctorsScreen()),
                ),
              ),
              ServiceItem(
                icon: Icons.local_hospital_rounded,
                title: tr('nearbyHospitals'),
                subtitle: tr('findHospitalsNear'),
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
                title: tr('emergencyCab'),
                subtitle: tr('bookCabEmergency'),
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
                title: tr('healthSchemes'),
                subtitle: tr('ayushmanMore'),
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
                title: tr('medicalStores'),
                subtitle: tr('janPharmacies'),
                color: const Color(0xFF80A7D9),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const JanAushadhiScreen()),
                ),
              ),
              ServiceItem(
                icon: Icons.description_rounded,
                title: tr('healthRecords'),
                subtitle: tr('medicalInfo'),
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
            title: tr('nearbyHospitals'),
            action: tr('viewAll'),
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
                return LocationRequiredPanel(
                  title: tr('enableGpsCare'),
                  subtitle: tr('gpsCareSubtitle'),
                  icon: Icons.local_hospital_rounded,
                );
              }
              final nearby = liveHealthData.nearbyHospitals(
                appLocation.current,
              );
              if (liveHealthData.loading && nearby.isEmpty) {
                return LiveHealthLoadingCard(
                  title: tr('fetchHospitals'),
                  subtitle: tr('fetchHospitalsSub'),
                );
              }
              if (nearby.isEmpty) {
                return EmptyStateCard(
                  icon: Icons.local_hospital_outlined,
                  title: tr('noHospitals'),
                  subtitle: tr('noHospitalsSub'),
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
          const SizedBox(height: 18),
          const ArogyaXHomeCard(),
        ],
      ),
    );
  }
}

class ArogyaXHomeCard extends StatelessWidget {
  const ArogyaXHomeCard({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = AppThemePalette.current;
    return AppCard(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ArogyaXScreen()),
      ),
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          const ArogyaXLogoMark(size: 58),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr('aiAssistant'),
                  style: TextStyle(
                    color: palette.text,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tr('assistantIntro'),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: palette.muted,
                    fontSize: 12,
                    height: 1.3,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: palette.muted),
        ],
      ),
    );
  }
}

class ArogyaXMessage {
  const ArogyaXMessage({required this.text, required this.fromUser});

  final String text;
  final bool fromUser;
}

class ArogyaXScreen extends StatefulWidget {
  const ArogyaXScreen({super.key});

  @override
  State<ArogyaXScreen> createState() => _ArogyaXScreenState();
}

class _ArogyaXScreenState extends State<ArogyaXScreen> {
  final _controller = TextEditingController();
  final _messages = <ArogyaXMessage>[
    const ArogyaXMessage(
      text:
          'Hi, I am ArogyaX. Ask about symptoms, reports, nearby doctors, hospitals or medicines. Upload a report when you want me to read it.',
      fromUser: false,
    ),
  ];
  var _busy = false;
  String _uploadName = '';
  String _uploadMime = '';
  String _uploadData = '';
  String _uploadText = '';
  Uint8List _uploadBytes = Uint8List(0);
  int _uploadSize = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppThemePalette.current;
    return Scaffold(
      body: AppPage(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
              child: TopBar(title: tr('arogyaxTitle')),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 18),
                children: [
                  AppCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const ArogyaXLogoMark(size: 62),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'ArogyaX Health Assistant',
                                    style: TextStyle(
                                      color: palette.text,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Reports, symptoms and nearby care guidance in one chat.',
                                    style: TextStyle(
                                      color: palette.muted,
                                      fontSize: 12,
                                      height: 1.3,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _ArogyaXStatusChip(
                              icon: appLocation.resolved
                                  ? Icons.gps_fixed_rounded
                                  : Icons.gps_not_fixed_rounded,
                              label: appLocation.resolved
                                  ? 'GPS ready'
                                  : 'GPS will auto-request',
                              color: appLocation.resolved
                                  ? AppColors.green
                                  : AppColors.gold,
                            ),
                            _ArogyaXStatusChip(
                              icon: Icons.upload_file_rounded,
                              label: _uploadName.isEmpty
                                  ? 'Report optional'
                                  : 'Report attached',
                              color: _uploadName.isEmpty
                                  ? AppColors.blue
                                  : AppColors.green,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  for (final message in _messages) _ArogyaXBubble(message),
                  if (_busy)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: LiveHealthLoadingCard(
                        title: 'ArogyaX thinking',
                        subtitle:
                            'Report, location and nearby care context is being checked.',
                      ),
                    ),
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: palette.line),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: .06),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_uploadName.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
                          decoration: BoxDecoration(
                            color: AppColors.blue.withValues(alpha: .08),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: AppColors.blue.withValues(alpha: .18),
                            ),
                          ),
                          child: Row(
                            children: [
                              _UploadPreviewThumb(
                                name: _uploadName,
                                mime: _uploadMime,
                                bytes: _uploadBytes,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '$_uploadName (${formatBytes(_uploadSize)})',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              IconButton(
                                tooltip: 'View upload',
                                onPressed: _showUploadPreview,
                                icon: const Icon(
                                  Icons.visibility_rounded,
                                  color: AppColors.blue,
                                ),
                              ),
                              IconButton(
                                tooltip: 'Delete upload',
                                onPressed: _clearUpload,
                                icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  color: AppColors.red,
                                ),
                              ),
                            ],
                          ),
                        ),
                      Row(
                        children: [
                          _ComposerIconButton(
                            tooltip: tr('uploadReport'),
                            icon: Icons.upload_file_rounded,
                            onTap: _busy ? null : () => _pickUpload(false),
                          ),
                          _ComposerIconButton(
                            tooltip: tr('uploadImage'),
                            icon: Icons.image_rounded,
                            onTap: _busy ? null : () => _pickUpload(true),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              minLines: 1,
                              maxLines: 2,
                              textInputAction: TextInputAction.send,
                              onSubmitted: (_) => _busy ? null : _send(),
                              style: TextStyle(
                                color: palette.text,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                              decoration: InputDecoration(
                                hintText: tr('askArogyaX'),
                                filled: true,
                                isDense: true,
                                fillColor: Colors.transparent,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 10,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(999),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          _ComposerSendButton(
                            busy: _busy,
                            onTap: _busy ? null : _send,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickUpload(bool imageOnly) async {
    final result = await FilePicker.pickFiles(
      type: imageOnly ? FileType.image : FileType.any,
      allowMultiple: false,
      withData: true,
    );
    if (result == null || result.files.isEmpty) {
      return;
    }
    final file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not read selected file.')),
      );
      return;
    }
    final mime = inferMimeType(file.name, imageOnly: imageOnly);
    setState(() {
      _uploadName = file.name;
      _uploadMime = mime;
      _uploadSize = bytes.length;
      _uploadBytes = Uint8List.fromList(bytes);
      _uploadText = _isTextMime(mime, file.name)
          ? utf8.decode(bytes, allowMalformed: true)
          : '';
      _uploadData = mime.startsWith('image/') ? base64Encode(bytes) : '';
    });
  }

  bool _isTextMime(String mime, String name) {
    final lower = name.toLowerCase();
    return mime.startsWith('text/') ||
        lower.endsWith('.txt') ||
        lower.endsWith('.csv') ||
        lower.endsWith('.json') ||
        lower.endsWith('.md');
  }

  void _clearUpload() {
    setState(_clearUploadState);
  }

  void _showUploadPreview() {
    if (_uploadName.isEmpty) return;
    final palette = AppThemePalette.current;
    final isImage = _uploadMime.startsWith('image/') && _uploadBytes.isNotEmpty;
    final isText = _uploadText.trim().isNotEmpty;
    showDialog<void>(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720, maxHeight: 720),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _UploadPreviewThumb(
                        name: _uploadName,
                        mime: _uploadMime,
                        bytes: _uploadBytes,
                        size: 44,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _uploadName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: palette.text,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${formatBytes(_uploadSize)}  -  ${_uploadMime.isEmpty ? 'file' : _uploadMime}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: palette.muted,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Delete upload',
                        onPressed: () {
                          Navigator.pop(context);
                          _clearUpload();
                        },
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          color: AppColors.red,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Close',
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.close_rounded, color: palette.text),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Flexible(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: double.infinity,
                        color: palette.soft,
                        child: isImage
                            ? InteractiveViewer(
                                minScale: .7,
                                maxScale: 4,
                                child: Image.memory(
                                  _uploadBytes,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const _UnsupportedUploadPreview(),
                                ),
                              )
                            : isText
                            ? SingleChildScrollView(
                                padding: const EdgeInsets.all(14),
                                child: SelectableText(
                                  _uploadText,
                                  style: TextStyle(
                                    color: palette.text,
                                    height: 1.45,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              )
                            : const _UnsupportedUploadPreview(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty && _uploadName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ask a question or upload a report.')),
      );
      return;
    }
    if (!appLocation.resolved && !appLocation.loading) {
      unawaited(appLocation.requestCurrentLocation());
    }
    setState(() {
      _messages.add(
        ArogyaXMessage(
          text: text.isEmpty ? 'Uploaded $_uploadName' : text,
          fromUser: true,
        ),
      );
      _busy = true;
      _controller.clear();
    });
    try {
      final response = await http
          .post(
            _arogyaxUri(),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(_payload(text)),
          )
          .timeout(const Duration(seconds: 70));
      final data = jsonDecode(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw StateError(data['error']?.toString() ?? 'ArogyaX request failed');
      }
      setState(() {
        _messages.add(
          ArogyaXMessage(
            text: data['answer']?.toString() ?? 'No answer received.',
            fromUser: false,
          ),
        );
        _clearUploadState();
      });
    } catch (error) {
      setState(() {
        _messages.add(
          ArogyaXMessage(
            text:
                'ArogyaX setup issue: $error\n\nVercel env me GROQ_API_KEY add karke redeploy karo.',
            fromUser: false,
          ),
        );
      });
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  void _clearUploadState() {
    _uploadName = '';
    _uploadMime = '';
    _uploadData = '';
    _uploadText = '';
    _uploadBytes = Uint8List(0);
    _uploadSize = 0;
  }

  Uri _arogyaxUri() {
    final base = Uri.base;
    return Uri(
      scheme: base.scheme,
      host: base.host,
      port: base.hasPort ? base.port : null,
      path: '/api/arogyax',
    );
  }

  Map<String, dynamic> _payload(String question) {
    final center = appLocation.current;
    final hospitals = liveHealthData.nearbyHospitals(center).take(6).map((h) {
      return {
        'name': h.name,
        'distance': h.distanceFrom(center),
        'status': h.status,
        'phone': h.phone,
      };
    }).toList();
    final doctors = liveHealthData.nearbyDoctors(center).take(8).map((d) {
      return {
        'name': d.name,
        'specialty': d.specialty,
        'distance': d.latLng == null
            ? ''
            : formatDistanceKm(distanceKm(center, d.latLng!)),
        'phone': d.phone,
        'address': d.address,
      };
    }).toList();
    final stores = liveHealthData.nearbyKendras(center).take(6).map((s) {
      return {
        'name': s.name,
        'distance': s.distanceFrom(center),
        'area': s.area,
        'phone': s.phone,
      };
    }).toList();
    final records = appData.healthRecords.take(8).map((record) {
      return {
        'title': record.title,
        'notes': record.subtitle,
        'attachment': record.attachmentName,
        'mime': record.attachmentMime,
      };
    }).toList();
    return {
      'message': question,
      'language': 'english',
      'location': {
        'resolved': appLocation.resolved,
        'label': appLocation.label,
        'lat': center.latitude,
        'lng': center.longitude,
      },
      'nearbyHospitals': hospitals,
      'nearbyDoctors': doctors,
      'medicalStores': stores,
      'healthRecords': records,
      'upload': {
        'name': _uploadName,
        'mime': _uploadMime,
        'size': _uploadSize,
        'text': _uploadText.length > 12000
            ? _uploadText.substring(0, 12000)
            : _uploadText,
        'imageBase64': _uploadData,
      },
    };
  }
}

class _ArogyaXBubble extends StatelessWidget {
  const _ArogyaXBubble(this.message);

  final ArogyaXMessage message;

  @override
  Widget build(BuildContext context) {
    final palette = AppThemePalette.current;
    return Align(
      alignment: message.fromUser
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 720),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: message.fromUser ? AppColors.blue : palette.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: message.fromUser ? AppColors.blue : palette.line,
          ),
        ),
        child: SelectableText(
          message.text,
          style: TextStyle(
            color: message.fromUser ? Colors.white : palette.text,
            height: 1.4,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _ComposerIconButton extends StatelessWidget {
  const _ComposerIconButton({
    required this.tooltip,
    required this.icon,
    required this.onTap,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.blue.withValues(alpha: .08),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.blue, size: 20),
        ),
      ),
    );
  }
}

class _ComposerSendButton extends StatelessWidget {
  const _ComposerSendButton({required this.busy, required this.onTap});

  final bool busy;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.navy, AppColors.blue],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.blue.withValues(alpha: .24),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: busy
            ? const SizedBox(
                width: 17,
                height: 17,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.arrow_upward_rounded, color: Colors.white),
      ),
    );
  }
}

class _UploadPreviewThumb extends StatelessWidget {
  const _UploadPreviewThumb({
    required this.name,
    required this.mime,
    required this.bytes,
    this.size = 34,
  });

  final String name;
  final String mime;
  final Uint8List bytes;
  final double size;

  @override
  Widget build(BuildContext context) {
    final isImage = mime.startsWith('image/') && bytes.isNotEmpty;
    if (isImage) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(size * .28),
        child: Image.memory(
          bytes,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _fileIcon(),
        ),
      );
    }
    return _fileIcon();
  }

  Widget _fileIcon() {
    final lower = name.toLowerCase();
    final icon = lower.endsWith('.pdf')
        ? Icons.picture_as_pdf_rounded
        : lower.endsWith('.csv') || lower.endsWith('.xlsx')
        ? Icons.table_chart_rounded
        : lower.endsWith('.txt') ||
              lower.endsWith('.md') ||
              lower.endsWith('.json')
        ? Icons.article_rounded
        : Icons.insert_drive_file_rounded;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.blue.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(size * .28),
      ),
      child: Icon(icon, color: AppColors.blue, size: size * .58),
    );
  }
}

class _UnsupportedUploadPreview extends StatelessWidget {
  const _UnsupportedUploadPreview();

  @override
  Widget build(BuildContext context) {
    final palette = AppThemePalette.current;
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.insert_drive_file_rounded,
            color: AppColors.blue.withValues(alpha: .75),
            size: 46,
          ),
          const SizedBox(height: 10),
          Text(
            'Preview is available for images and text files.',
            textAlign: TextAlign.center,
            style: TextStyle(color: palette.text, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            'The selected file is attached for ArogyaX context.',
            textAlign: TextAlign.center,
            style: TextStyle(color: palette.muted, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _ArogyaXStatusChip extends StatelessWidget {
  const _ArogyaXStatusChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: .22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
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
        final palette = AppThemePalette.current;
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
                      tt(
                        appLocation.resolved
                            ? 'Using your live location'
                            : 'Location based care',
                      ),
                      style: TextStyle(
                        color: palette.text,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      hospital == null
                          ? tt(
                              appLocation.resolved
                                  ? 'Live hospital data will appear after fetch'
                                  : 'Enable GPS to fetch nearby care',
                            )
                          : '${hospital.name} - ${hospital.distanceFrom(appLocation.current)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: palette.muted,
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
                label: Text(
                  appLocation.loading ? tt('Locating') : tt('Use GPS'),
                ),
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
    final palette = AppThemePalette.current;
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
                          tt(title),
                          style: TextStyle(
                            color: palette.text,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          tt(subtitle),
                          style: TextStyle(
                            color: palette.muted,
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
                    ? tt('Detecting GPS...')
                    : tt('Enable GPS Location'),
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
        final palette = AppThemePalette.current;
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
                    Text(
                      tt('Doctors near your area'),
                      style: TextStyle(
                        color: palette.text,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      appLocation.resolved
                          ? 'Using ${appLocation.label}'
                          : tt('Use GPS to personalize doctor availability'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: palette.muted,
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
                label: Text(appLocation.loading ? tt('GPS...') : tt('GPS')),
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
        title: 'Medical Stores',
        subtitle: 'Find affordable medicine stores near you',
        icon: Icons.medication_liquid_rounded,
        color: AppColors.green,
        builder: (_) => const JanAushadhiScreen(),
        terms: const [
          'jan aushadhi',
          'medicine',
          'pharmacy',
          'medical',
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
    final palette = AppThemePalette.current;
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
                  tt(shortcut.title),
                  style: TextStyle(
                    color: palette.text,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tt(shortcut.subtitle),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: palette.muted,
                    fontSize: 12,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: palette.muted),
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
    final palette = AppThemePalette.current;
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
                  tt(title),
                  style: TextStyle(
                    color: palette.text,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  tt(subtitle),
                  style: TextStyle(
                    color: palette.muted,
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
    final palette = AppThemePalette.current;
    return AppCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: palette.soft,
            child: Icon(icon, color: AppColors.navy),
          ),
          const SizedBox(height: 14),
          Text(
            tt(title),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: palette.text,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            tt(subtitle),
            textAlign: TextAlign.center,
            style: TextStyle(color: palette.muted, height: 1.35),
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
      backgroundColor: AppThemePalette.current.card,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tt('Filter Doctors'),
                style: TextStyle(
                  color: AppThemePalette.current.text,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
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
                      label: Text(tt(label)),
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
        .where((doctor) => doctorMatchesSpecialty(doctor, specialty))
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
            title: 'Fetching doctors',
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
                subtitle: 'Try All filter or refresh GPS.',
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

bool doctorMatchesSpecialty(Doctor doctor, String selected) {
  if (selected == 'All') {
    return true;
  }
  final specialty = doctor.specialty.toLowerCase();
  final target = selected.toLowerCase();
  if (specialty.contains(target)) {
    return true;
  }
  final aliases = <String, List<String>>{
    'doctor': ['doctor', 'physician', 'general'],
    'cardiologist': ['cardio', 'heart'],
    'orthopedic': ['ortho', 'bone', 'orthopaedic'],
    'general physician': ['general', 'physician', 'medicine'],
    'ent': ['ent', 'ear', 'nose', 'throat'],
    'neurologist': ['neuro', 'brain'],
    'pediatrician': ['paediatric', 'pediatric', 'child'],
    'gynecologist': ['gyn', 'obstetric', 'women'],
    'dermatologist': ['derma', 'skin'],
    'dentist': ['dental', 'dentist'],
  };
  return (aliases[target] ?? const []).any(specialty.contains);
}

class DemoModeNotice extends StatelessWidget {
  const DemoModeNotice({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final palette = AppThemePalette.current;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        tt(text),
        style: TextStyle(
          color: palette.text,
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
    final palette = AppThemePalette.current;
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
                  onPressed: () => shareDoctorDetails(context, doctor),
                  icon: Icon(Icons.share_outlined, color: palette.text),
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
                    style: TextStyle(
                      color: palette.text,
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
                    style: TextStyle(color: palette.muted, fontSize: 12),
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
                Expanded(
                  child: StatCard(
                    title: doctor.address.isEmpty
                        ? 'Nearby care'
                        : doctor.address,
                    subtitle: 'Location',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              tt('About Doctor'),
              style: TextStyle(
                color: palette.text,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              doctor.about.isEmpty ? doctorFallbackAbout(doctor) : doctor.about,
              style: TextStyle(color: palette.muted, height: 1.45),
            ),
            TextButton(
              onPressed: () => showDoctorInfoSheet(context, doctor),
              style: TextButton.styleFrom(
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.zero,
              ),
              child: Text(tt('Read more')),
            ),
            const SizedBox(height: 14),
            AppointmentBookingPanel(doctor: doctor),
          ],
        ),
      ),
    );
  }
}

String doctorFallbackAbout(Doctor doctor) {
  final source = doctor.source.isEmpty ? 'the care directory' : doctor.source;
  final contact = doctor.phone.isEmpty
      ? 'Please call before visiting to confirm availability.'
      : 'Contact number: ${doctor.phone}.';
  return '${doctor.name} is listed as a ${doctor.specialty} provider from $source. ${doctor.experience}. $contact';
}

Future<void> shareDoctorDetails(BuildContext context, Doctor doctor) async {
  final location = doctor.address.isEmpty ? appLocation.label : doctor.address;
  final phone = doctor.phone.isEmpty ? doctor.degree : doctor.phone;
  final lines = [
    doctor.name,
    doctor.specialty,
    'Location: $location',
    if (phone.isNotEmpty) 'Contact: $phone',
    'Next slot: ${doctor.nextSlot}',
    'Shared from Jeevan Arogya',
  ];
  await Clipboard.setData(ClipboardData(text: lines.join('\n')));
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Doctor details copied for sharing.')),
    );
  }
}

void showDoctorInfoSheet(BuildContext context, Doctor doctor) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            doctor.name,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            doctor.about.isEmpty ? doctorFallbackAbout(doctor) : doctor.about,
          ),
          const SizedBox(height: 12),
          InfoLine(
            icon: Icons.medical_services_rounded,
            text: doctor.specialty,
          ),
          if (doctor.address.isNotEmpty)
            InfoLine(icon: Icons.location_on_rounded, text: doctor.address),
          if (doctor.phone.isNotEmpty)
            InfoLine(icon: Icons.call_rounded, text: doctor.phone),
        ],
      ),
    ),
  );
}

class InfoLine extends StatelessWidget {
  const InfoLine({super.key, required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.blue),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
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
    final palette = AppThemePalette.current;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tt('Next Available Slots'),
          style: TextStyle(
            color: palette.text,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
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
            hintText: tt('Reason for visit'),
            filled: true,
            fillColor: palette.soft,
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
                              'Pickup, route and nearest hospital drop are shown after GPS is available.',
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
                        title: 'Fetching hospitals',
                        subtitle: 'Checking hospitals near your GPS.',
                      ),
                    );
                  }
                  if (nearby.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.fromLTRB(20, 0, 20, 26),
                      child: EmptyStateCard(
                        icon: Icons.local_hospital_outlined,
                        title: 'No verified live hospitals found',
                        subtitle: 'Refresh GPS and try again.',
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
    final palette = AppThemePalette.current;
    return Scaffold(
      body: AppPage(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          children: [
            const TopBar(title: 'Health Schemes'),
            const SizedBox(height: 18),
            AyushmanCard(scheme: healthSchemeInfos.first),
            const SizedBox(height: 22),
            Text(
              tt('Other Government Schemes'),
              style: TextStyle(
                color: palette.text,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
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
    final palette = AppThemePalette.current;
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
                          style: TextStyle(
                            color: palette.text,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          tt('No uploaded health records yet.'),
                          style: TextStyle(color: palette.muted, fontSize: 12),
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
              onSave:
                  (
                    title,
                    subtitle,
                    attachmentName,
                    attachmentType,
                    attachmentData,
                    attachmentMime,
                    attachmentSize,
                  ) {
                    appData.addEntry(
                      appData.healthRecords,
                      AppTextEntry(
                        title: title,
                        subtitle: subtitle,
                        icon: Icons.folder_copy_rounded,
                        color: AppColors.blue,
                        attachmentName: attachmentName,
                        attachmentType: attachmentType,
                        attachmentData: attachmentData,
                        attachmentMime: attachmentMime,
                        attachmentSize: attachmentSize,
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
                      InfoEntryCard(
                        entry: record,
                        onDelete: () =>
                            appData.removeEntry(appData.healthRecords, record),
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
}

enum MedicalStoreFilter { all, janAushadhi }

class JanAushadhiScreen extends StatefulWidget {
  const JanAushadhiScreen({super.key});

  @override
  State<JanAushadhiScreen> createState() => _JanAushadhiScreenState();
}

class _JanAushadhiScreenState extends State<JanAushadhiScreen> {
  var _filter = MedicalStoreFilter.all;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppPage(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              child: TopBar(
                title: 'Medical Stores',
                trailingIcon: Icons.tune_rounded,
                trailingOnTap: _showFilterSheet,
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
                        title: 'Enable GPS for Medical Stores',
                        subtitle:
                            'Nearest store list, distance and map are hidden until live GPS permission is allowed.',
                        icon: Icons.medication_liquid_rounded,
                      ),
                    );
                  }
                  final nearby = _filteredStores(
                    liveHealthData.nearbyKendras(appLocation.current),
                  );
                  if (liveHealthData.loading && nearby.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.fromLTRB(20, 0, 20, 26),
                      child: LiveHealthLoadingCard(
                        title: 'Fetching Medical Stores',
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
                        title: 'No medical store live result found',
                        subtitle:
                            'OpenStreetMap me nearby medical store listing nahi mili.',
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

  List<Place> _filteredStores(List<Place> stores) {
    if (_filter == MedicalStoreFilter.all) {
      return stores;
    }
    return stores.where(isJanAushadhiPlace).toList();
  }

  void _showFilterSheet() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppThemePalette.current.card,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tt('Filter Medical Stores'),
                style: TextStyle(
                  color: AppThemePalette.current.text,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              ChoiceChip(
                label: Text(tt('All medical stores')),
                selected: _filter == MedicalStoreFilter.all,
                onSelected: (_) {
                  setState(() => _filter = MedicalStoreFilter.all);
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 8),
              ChoiceChip(
                label: Text(tt('Jan Aushadhi only')),
                selected: _filter == MedicalStoreFilter.janAushadhi,
                onSelected: (_) {
                  setState(() => _filter = MedicalStoreFilter.janAushadhi);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

bool isJanAushadhiPlace(Place place) {
  final text = '${place.name} ${place.area}'.toLowerCase();
  return text.contains('jan aushadhi') ||
      text.contains('janaushadhi') ||
      text.contains('jan aushadi');
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
                      label: Text(tt('New')),
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
    final palette = AppThemePalette.current;
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
          Text(
            tt('My Health'),
            style: TextStyle(
              color: palette.text,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
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
          Text(
            tt('My Account'),
            style: TextStyle(
              color: palette.text,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
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
            icon: Icons.cleaning_services_rounded,
            title: 'Clear Saved Data',
            danger: true,
            onTap: () => showClearSavedDataDialog(context),
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

Future<void> showClearSavedDataDialog(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) {
      final palette = AppThemePalette.current;
      return AlertDialog(
        backgroundColor: palette.card,
        title: Text(
          tt('Clear saved data?'),
          style: TextStyle(color: palette.text),
        ),
        content: Text(
          tt(
            'Messages, cab requests, doctor appointments and activity notifications saved on this device will be deleted.',
          ),
          style: TextStyle(color: palette.muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(tt('Cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.red),
            onPressed: () => Navigator.pop(context, true),
            child: Text(tt('Clear Data')),
          ),
        ],
      );
    },
  );
  if (confirmed == true) {
    appData.clearActivityData();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tt('Saved app activity cleared.'))),
      );
    }
  }
}

class SimpleInfoScreen extends StatelessWidget {
  const SimpleInfoScreen({super.key, required this.title, required this.lines});

  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    final palette = AppThemePalette.current;
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
                        tt(line),
                        style: TextStyle(
                          color: palette.text,
                          fontWeight: FontWeight.w800,
                        ),
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
    final addTitle = 'Add $title';
    return Scaffold(
      body: AppPage(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
          children: [
            TopBar(title: title),
            const SizedBox(height: 18),
            EditableEntryPanel(
              title: addTitle,
              titleHint: 'Title',
              subtitleHint: seedSubtitle ?? 'Details',
              buttonLabel: 'Save',
              icon: defaultIcon,
              color: color,
              allowAttachments: allowAttachments,
              onBeforeSave: onBeforeAdd,
              onSave:
                  (
                    entryTitle,
                    subtitle,
                    attachmentName,
                    attachmentType,
                    attachmentData,
                    attachmentMime,
                    attachmentSize,
                  ) {
                    appData.addEntry(
                      entries,
                      AppTextEntry(
                        title: entryTitle,
                        subtitle: subtitle,
                        icon: defaultIcon,
                        color: color,
                        attachmentName: attachmentName,
                        attachmentType: attachmentType,
                        attachmentData: attachmentData,
                        attachmentMime: attachmentMime,
                        attachmentSize: attachmentSize,
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
                    for (final entry in entries)
                      InfoEntryCard(
                        entry: entry,
                        onDelete: () => appData.removeEntry(entries, entry),
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
    String attachmentData,
    String attachmentMime,
    int attachmentSize,
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
  String _attachmentData = '';
  String _attachmentMime = '';
  int _attachmentSize = 0;

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppThemePalette.current;
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
                  tt(widget.title),
                  style: TextStyle(
                    color: palette.text,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              hintText: tt(widget.titleHint),
              filled: true,
              fillColor: palette.soft,
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
              hintText: tt(widget.subtitleHint),
              filled: true,
              fillColor: palette.soft,
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
                  label: Text(tt('Upload File')),
                ),
                OutlinedButton.icon(
                  onPressed: _busy ? null : () => _pickAttachment(true),
                  icon: const Icon(Icons.image_rounded),
                  label: Text(tt('Upload Image')),
                ),
              ],
            ),
          ],
          if (widget.allowAttachments && _attachmentName.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.green.withValues(alpha: .09),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.green.withValues(alpha: .22),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _attachmentType == 'image'
                        ? Icons.image_rounded
                        : Icons.attach_file_rounded,
                    color: AppColors.green,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Attached: $_attachmentName (${formatBytes(_attachmentSize)})',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.green,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Remove attachment',
                    onPressed: _clearAttachment,
                    icon: const Icon(Icons.close_rounded),
                    color: AppColors.green,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
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
      widget.onSave(
        title,
        subtitle,
        _attachmentName,
        _attachmentType,
        _attachmentData,
        _attachmentMime,
        _attachmentSize,
      );
      _titleController.clear();
      _subtitleController.clear();
      _clearAttachment(setStateNow: false);
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
      withData: true,
    );
    if (result == null || result.files.isEmpty) {
      return;
    }
    final file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not read selected file.')),
      );
      return;
    }
    setState(() {
      _attachmentName = file.name;
      _attachmentType = imageOnly ? 'image' : 'file';
      _attachmentData = base64Encode(bytes);
      _attachmentMime = inferMimeType(file.name, imageOnly: imageOnly);
      _attachmentSize = bytes.length;
    });
  }

  void _clearAttachment({bool setStateNow = true}) {
    void clear() {
      _attachmentName = '';
      _attachmentType = '';
      _attachmentData = '';
      _attachmentMime = '';
      _attachmentSize = 0;
    }

    if (setStateNow) {
      setState(clear);
    } else {
      clear();
    }
  }
}

class InfoEntryCard extends StatelessWidget {
  const InfoEntryCard({super.key, required this.entry, this.onDelete});

  final AppTextEntry entry;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final palette = AppThemePalette.current;
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
                  style: TextStyle(
                    color: palette.text,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  entry.subtitle,
                  style: TextStyle(color: palette.muted, fontSize: 12),
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
          const SizedBox(width: 8),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (entry.attachmentName.isNotEmpty)
                CircleIcon(
                  icon: Icons.visibility_rounded,
                  onTap: () => showAttachmentPreview(context, entry),
                ),
              if (onDelete != null) ...[
                if (entry.attachmentName.isNotEmpty) const SizedBox(height: 8),
                CircleIcon(
                  icon: Icons.delete_outline_rounded,
                  onTap: () => confirmDeleteEntry(context, onDelete!),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

Future<void> confirmDeleteEntry(
  BuildContext context,
  VoidCallback onDelete,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) {
      final palette = AppThemePalette.current;
      return AlertDialog(
        backgroundColor: palette.card,
        title: Text(tt('Delete entry?'), style: TextStyle(color: palette.text)),
        content: Text(
          tt(
            'This saved item and its uploaded attachment will be removed from this device.',
          ),
          style: TextStyle(color: palette.muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(tt('Cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.red),
            onPressed: () => Navigator.pop(context, true),
            child: Text(tt('Delete')),
          ),
        ],
      );
    },
  );
  if (confirmed == true) {
    onDelete();
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(tt('Deleted.'))));
    }
  }
}

void showAttachmentPreview(BuildContext context, AppTextEntry entry) {
  final bytes = decodeAttachment(entry);
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      final palette = AppThemePalette.current;
      final canShowText = isTextAttachment(entry);
      return DraggableScrollableSheet(
        initialChildSize: .72,
        minChildSize: .42,
        maxChildSize: .92,
        builder: (context, controller) {
          return Container(
            decoration: BoxDecoration(
              color: palette.card,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              border: Border.all(color: palette.line),
            ),
            child: ListView(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: palette.line,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.green.withValues(alpha: .14),
                      child: Icon(
                        entry.attachmentType == 'image'
                            ? Icons.image_rounded
                            : Icons.attach_file_rounded,
                        color: AppColors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.attachmentName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: palette.text,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${entry.attachmentMime.isEmpty ? 'Saved file' : entry.attachmentMime} - ${formatBytes(entry.attachmentSize)}',
                            style: TextStyle(
                              color: palette.muted,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close_rounded, color: palette.text),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (bytes == null)
                  EmptyStateCard(
                    icon: Icons.error_outline_rounded,
                    title: 'Attachment preview unavailable',
                    subtitle:
                        'This older saved item only has the file name. Upload it again to store a previewable copy.',
                  )
                else if (entry.attachmentType == 'image')
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.memory(bytes, fit: BoxFit.contain),
                  )
                else if (canShowText)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: palette.soft,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: palette.line),
                    ),
                    child: SelectableText(
                      utf8.decode(bytes, allowMalformed: true),
                      style: TextStyle(color: palette.text, height: 1.35),
                    ),
                  )
                else
                  AppCard(
                    child: Column(
                      children: [
                        Icon(
                          Icons.insert_drive_file_rounded,
                          size: 54,
                          color: AppColors.blue.withValues(alpha: .9),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'File saved in app data',
                          style: TextStyle(
                            color: palette.text,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Use Open File to preview it in a supported browser/app.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: palette.muted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                if (bytes != null) ...[
                  const SizedBox(height: 16),
                  PrimaryButton(
                    label: 'Open File',
                    onTap: () =>
                        openAttachmentExternally(context, entry, bytes),
                  ),
                ],
              ],
            ),
          );
        },
      );
    },
  );
}

Uint8List? decodeAttachment(AppTextEntry entry) {
  if (entry.attachmentData.isEmpty) {
    return null;
  }
  try {
    return base64Decode(entry.attachmentData);
  } catch (_) {
    return null;
  }
}

bool isTextAttachment(AppTextEntry entry) {
  final name = entry.attachmentName.toLowerCase();
  final mime = entry.attachmentMime.toLowerCase();
  return mime.startsWith('text/') ||
      name.endsWith('.txt') ||
      name.endsWith('.csv') ||
      name.endsWith('.json') ||
      name.endsWith('.md');
}

Future<void> openAttachmentExternally(
  BuildContext context,
  AppTextEntry entry,
  Uint8List bytes,
) async {
  final uri = Uri.dataFromBytes(
    bytes,
    mimeType: entry.attachmentMime.isEmpty
        ? 'application/octet-stream'
        : entry.attachmentMime,
  );
  var opened = false;
  try {
    opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    opened = false;
  }
  if (!opened && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No external app could open this file.')),
    );
  }
}

String inferMimeType(String fileName, {required bool imageOnly}) {
  final lower = fileName.toLowerCase();
  if (lower.endsWith('.png')) return 'image/png';
  if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
  if (lower.endsWith('.webp')) return 'image/webp';
  if (lower.endsWith('.gif')) return 'image/gif';
  if (lower.endsWith('.pdf')) return 'application/pdf';
  if (lower.endsWith('.txt')) return 'text/plain';
  if (lower.endsWith('.csv')) return 'text/csv';
  if (lower.endsWith('.json')) return 'application/json';
  if (lower.endsWith('.doc')) return 'application/msword';
  if (lower.endsWith('.docx')) {
    return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
  }
  return imageOnly ? 'image/*' : 'application/octet-stream';
}

String formatBytes(int bytes) {
  if (bytes <= 0) {
    return '0 KB';
  }
  const units = ['B', 'KB', 'MB', 'GB'];
  var size = bytes.toDouble();
  var unit = 0;
  while (size >= 1024 && unit < units.length - 1) {
    size /= 1024;
    unit++;
  }
  final digits = size >= 10 || unit == 0 ? 0 : 1;
  return '${size.toStringAsFixed(digits)} ${units[unit]}';
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
    final palette = AppThemePalette.current;
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
                            CircleAvatar(
                              backgroundColor: palette.soft,
                              child: const Icon(
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
                                    style: TextStyle(
                                      color: palette.text,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${contact.relation} - ${contact.phone}',
                                    style: TextStyle(
                                      color: palette.muted,
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
    final palette = AppThemePalette.current;
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(color: palette.text),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: AppColors.navy),
        hintText: tt(hint),
        filled: true,
        fillColor: palette.soft,
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
        SnackBar(content: Text(tt('Name and phone are required.'))),
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
    final palette = AppThemePalette.current;
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(color: palette.text),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: AppColors.navy),
        hintText: tt(hint),
        filled: true,
        fillColor: palette.soft,
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
        SnackBar(content: Text(tt('Enter a valid name and email.'))),
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
    final palette = AppThemePalette.current;
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
                    style: TextStyle(color: palette.text),
                    decoration: InputDecoration(
                      hintText: tt('Doctor, hospital, or contact name'),
                      filled: true,
                      fillColor: palette.soft,
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
                    style: TextStyle(color: palette.text),
                    decoration: InputDecoration(
                      hintText: tt('Message'),
                      filled: true,
                      fillColor: palette.soft,
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
        SnackBar(content: Text(tt('Name and message are required.'))),
      );
      return;
    }
    appData.createThread(
      name: name,
      subtitle: tt('Custom message'),
      body: body,
    );
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
    final palette = AppThemePalette.current;
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
                                  : palette.card,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: palette.line),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  message.body,
                                  style: TextStyle(
                                    color: message.fromUser
                                        ? Colors.white
                                        : palette.text,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  message.time,
                                  style: TextStyle(
                                    color: message.fromUser
                                        ? Colors.white70
                                        : palette.muted,
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
                      style: TextStyle(color: palette.text),
                      decoration: InputDecoration(
                        hintText: tt('Type a message...'),
                        filled: true,
                        fillColor: palette.card,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(999),
                          borderSide: BorderSide(color: palette.line),
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
    final palette = AppThemePalette.current;
    return SafeArea(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [palette.pageTop, palette.pageBottom],
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
    return const Center(child: LogoMark(width: 152, height: 58));
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
                  'New appointment, SOS and cab updates will appear here after activity.',
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

class ArogyaXLogoMark extends StatelessWidget {
  const ArogyaXLogoMark({super.key, this.size = 56});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * .02),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size * .28),
        boxShadow: [
          BoxShadow(
            color: AppColors.green.withValues(alpha: .14),
            blurRadius: size * .22,
            offset: Offset(0, size * .08),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * .22),
        child: Image.asset(
          'assets/branding/arogyax_logo.png',
          fit: BoxFit.contain,
          semanticLabel: 'ArogyaX',
        ),
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
    final palette = AppThemePalette.current;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: palette.card,
          shape: BoxShape.circle,
          border: Border.all(color: palette.line),
        ),
        child: Icon(icon, color: palette.text, size: 21),
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
            title.startsWith('Search: ')
                ? '${tt('Search')}: ${title.substring(8)}'
                : tt(title),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppThemePalette.current.text,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
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
      child: SizedBox(
        width: 40,
        height: 40,
        child: Icon(
          Icons.arrow_back_rounded,
          color: AppThemePalette.current.text,
        ),
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
    final palette = AppThemePalette.current;
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: palette.soft,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.line),
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
              style: TextStyle(color: palette.text),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: tt(widget.hint),
                border: InputBorder.none,
                isDense: true,
                hintStyle: TextStyle(color: palette.muted, fontSize: 13),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Search',
            onPressed: widget.onChanged == null && widget.onSubmitted == null
                ? null
                : _runSearch,
            icon: const Icon(Icons.search_rounded),
            color: palette.text,
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
    final palette = AppThemePalette.current;
    final visibleDoctors = liveHealthData.nearbyDoctors(appLocation.current);
    if (liveHealthData.loading && visibleDoctors.isEmpty) {
      return const LiveHealthLoadingCard(
        title: 'Finding live doctors',
        subtitle: 'Nearby doctor listings are loading.',
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
                  Text(
                    tt('Next doctor available'),
                    style: TextStyle(
                      color: palette.muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    doctor.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: palette.text,
                      fontWeight: FontWeight.w900,
                    ),
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
    final palette = AppThemePalette.current;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: item.onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: palette.soft,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: palette.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(item.icon, color: item.color, size: 28),
            const Spacer(),
            Text(
              tt(item.title),
              maxLines: 2,
              style: TextStyle(
                color: palette.text,
                fontWeight: FontWeight.w900,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              tt(item.subtitle),
              maxLines: 2,
              style: TextStyle(color: palette.muted, fontSize: 11),
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
    final palette = AppThemePalette.current;
    return Row(
      children: [
        Expanded(
          child: Text(
            tt(title),
            style: TextStyle(
              color: palette.text,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        if (action != null)
          TextButton(
            onPressed: onTap,
            child: Text(tt(action!), style: const TextStyle(fontSize: 12)),
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
    final palette = AppThemePalette.current;
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
                      : palette.soft,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: labels[i] == selectedLabel
                        ? AppColors.navy
                        : palette.line,
                  ),
                ),
                child: Text(
                  tt(labels[i]),
                  style: TextStyle(
                    color: labels[i] == selectedLabel
                        ? Colors.white
                        : palette.text,
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
    final palette = AppThemePalette.current;
    return AppCard(
      onTap: onTap,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 68,
            child: Column(
              children: [
                DoctorAvatar(doctor: doctor, radius: 31),
                const SizedBox(height: 8),
                Text(
                  doctor.fee,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 88),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          doctor.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.favorite_border_rounded,
                        color: AppColors.muted,
                        size: 20,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    doctor.specialty,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: palette.text,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${doctor.experience}  -  ${doctor.degree}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: palette.muted, fontSize: 11),
                  ),
                  const SizedBox(height: 8),
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
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                color: AppColors.green,
                                fontSize: 10.5,
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
    final female = isLikelyFemaleDoctorName(doctor.name);
    final asset = female
        ? 'assets/branding/doctor_female.jpeg'
        : 'assets/branding/doctor_male.jpeg';
    final size = radius * 2;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(
          color: Colors.white,
          width: math.max(2, radius * .05),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: .10),
            blurRadius: radius * .28,
            offset: Offset(0, radius * .08),
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          asset,
          fit: BoxFit.cover,
          semanticLabel: female ? 'Female doctor' : 'Male doctor',
        ),
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
            style: TextStyle(
              color: AppThemePalette.current.text,
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
    final palette = AppThemePalette.current;
    return Container(
      constraints: const BoxConstraints(minHeight: 72),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: palette.soft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.line),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            tt(title),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: palette.text,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            tt(subtitle),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: palette.muted, fontSize: 10),
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
    final palette = AppThemePalette.current;
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
                  color: i == selectedIndex ? AppColors.navy : palette.soft,
                  border: Border.all(
                    color: i == selectedIndex ? AppColors.navy : palette.line,
                  ),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Column(
                  children: [
                    Text(
                      dates[i].$1,
                      style: TextStyle(
                        color: i == selectedIndex ? Colors.white : palette.text,
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
                            : palette.muted,
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
    final palette = AppThemePalette.current;
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
              color: selected ? AppColors.navy : palette.soft,
              border: Border.all(
                color: selected ? AppColors.navy : palette.line,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              appointmentTimes[index],
              style: TextStyle(
                color: selected ? Colors.white : palette.text,
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
    final palette = AppThemePalette.current;
    final title = switch (mode) {
      MapMode.route => 'Live emergency route',
      MapMode.hospitals => 'Hospitals near you',
      MapMode.kendras => 'Medical stores near you',
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.card.withValues(alpha: .94),
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
                tt(title),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: palette.text,
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
              label: Text(tt('GPS')),
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
    final palette = AppThemePalette.current;
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
            color: palette.card,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: palette.line),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: palette.text,
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
        final palette = AppThemePalette.current;
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
            subtitle: 'Tap GPS again or call emergency services.',
          );
        }
        final hospital = nearest.first;
        return AppCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tt('Confirm Emergency Ride'),
                style: TextStyle(
                  color: palette.text,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
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
              Center(
                child: Text(
                  tt('Drivers will be notified about the emergency'),
                  style: TextStyle(color: palette.muted, fontSize: 12),
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
      backgroundColor: AppThemePalette.current.card,
      builder: (context) {
        final palette = AppThemePalette.current;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tt(title),
                  style: TextStyle(
                    color: palette.text,
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
                          : palette.soft,
                      child: Icon(
                        value == currentValue
                            ? Icons.check_rounded
                            : Icons.circle_outlined,
                        color: value == currentValue
                            ? Colors.white
                            : palette.muted,
                      ),
                    ),
                    title: Text(
                      tt(value),
                      style: TextStyle(
                        color: palette.text,
                        fontWeight: FontWeight.w900,
                      ),
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
    final palette = AppThemePalette.current;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.soft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.line),
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
                      style: TextStyle(
                        color: palette.text,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${request.driverName} - ${request.createdAtLabel}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: palette.muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: () => callPhone(context, request.hospitalPhone),
                icon: const Icon(Icons.call_rounded, size: 17),
                label: Text(tt('Call')),
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
            style: TextStyle(
              color: palette.text,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Pickup: ${request.pickup}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: palette.muted, fontSize: 12),
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
    final palette = AppThemePalette.current;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: palette.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.navy),
          const SizedBox(width: 5),
          Text(
            tt(label),
            style: TextStyle(
              color: palette.text,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
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
    final palette = AppThemePalette.current;
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
                  tt(title),
                  style: TextStyle(color: palette.muted, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: palette.text,
                    fontWeight: FontWeight.w800,
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
    final palette = AppThemePalette.current;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: palette.soft,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: palette.line),
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
                    tt(title),
                    style: TextStyle(color: palette.muted, fontSize: 10),
                  ),
                  Text(
                    tt(value),
                    style: TextStyle(
                      color: palette.text,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: palette.muted, size: 18),
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
        final palette = AppThemePalette.current;
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
                  color: palette.soft,
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
                      style: TextStyle(
                        color: palette.text,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: distance,
                            style: TextStyle(color: palette.muted),
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
    final palette = AppThemePalette.current;
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
                    style: TextStyle(
                      color: palette.text,
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: palette.muted,
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
                          label: Text(tt('Directions')),
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
    final palette = AppThemePalette.current;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.soft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.line),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tt('Ayushman Bharat'),
                  style: TextStyle(
                    color: palette.text,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  scheme.subtitle,
                  style: TextStyle(
                    color: palette.text,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  scheme.benefit,
                  style: TextStyle(
                    color: palette.muted,
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
                    child: Text(
                      tt('Check Eligibility'),
                      style: const TextStyle(
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
    final palette = AppThemePalette.current;
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
                  tt(scheme.title),
                  style: TextStyle(
                    color: palette.text,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tt(scheme.subtitle),
                  style: TextStyle(color: palette.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: palette.muted),
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
    final palette = AppThemePalette.current;
    return Scaffold(
      body: AppPage(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
          children: [
            TopBar(title: tt(scheme.title)),
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
                    tt(scheme.title),
                    style: TextStyle(
                      color: palette.text,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    tt(scheme.department),
                    style: const TextStyle(
                      color: AppColors.navy,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    tt(scheme.benefit),
                    style: TextStyle(color: palette.muted, height: 1.45),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    tt('Eligibility'),
                    style: TextStyle(
                      color: palette.text,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    tt(scheme.eligibility),
                    style: TextStyle(color: palette.muted, height: 1.45),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    tt('Documents'),
                    style: TextStyle(
                      color: palette.text,
                      fontWeight: FontWeight.w900,
                    ),
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
                              tt(document),
                              style: TextStyle(
                                color: palette.text,
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
        final palette = AppThemePalette.current;
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
                  color: AppColors.green.withValues(alpha: .12),
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
                      style: TextStyle(color: palette.muted, fontSize: 12),
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
    final palette = AppThemePalette.current;
    return AppCard(
      margin: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: palette.soft,
            child: const Icon(
              Icons.event_available_rounded,
              color: AppColors.navy,
            ),
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
                  style: TextStyle(color: palette.muted, fontSize: 12),
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
                    style: TextStyle(color: palette.muted, fontSize: 12),
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
    final palette = AppThemePalette.current;
    return AppCard(
      onTap: onTap,
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: palette.soft,
            child: const Icon(
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
                  style: TextStyle(color: palette.muted, fontSize: 12),
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
    final palette = AppThemePalette.current;
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
                  style: TextStyle(color: palette.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: palette.text),
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
    final palette = AppThemePalette.current;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
        decoration: BoxDecoration(
          color: palette.card,
          border: Border(bottom: BorderSide(color: palette.line)),
        ),
        child: Row(
          children: [
            Icon(icon, color: danger ? AppColors.red : palette.text, size: 20),
            const SizedBox(width: 13),
            Expanded(
              child: Text(
                tt(title),
                style: TextStyle(
                  color: danger ? AppColors.red : palette.text,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: palette.muted),
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
    final palette = AppThemePalette.current;
    return Container(
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: palette.line)),
        boxShadow: [
          BoxShadow(
            color: palette.shadow.withValues(alpha: .08),
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
    final palette = AppThemePalette.current;
    final color = selected ? AppColors.blue : palette.muted;
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
              tt(label),
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
        child: Text(
          tt(label),
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
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
    final palette = AppThemePalette.current;
    final card = Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.line),
        boxShadow: [
          BoxShadow(
            color: palette.shadow.withValues(alpha: .05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );

    final result = onTap == null
        ? card
        : InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: card,
          );
    return result;
  }
}
