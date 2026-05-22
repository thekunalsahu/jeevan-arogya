class DbDoctor {
  const DbDoctor({
    required this.id,
    required this.name,
    required this.specialty,
    required this.experienceYears,
    required this.degree,
    required this.fee,
    required this.rating,
    required this.reviews,
    required this.nextSlot,
    required this.hospital,
    required this.area,
    required this.isOnline,
  });

  final String id;
  final String name;
  final String specialty;
  final int experienceYears;
  final String degree;
  final int fee;
  final double rating;
  final int reviews;
  final String nextSlot;
  final String hospital;
  final String area;
  final bool isOnline;

  factory DbDoctor.fromMap(Map<String, dynamic> map) {
    return DbDoctor(
      id: map['id'].toString(),
      name: map['name'] as String? ?? '',
      specialty: map['specialty'] as String? ?? '',
      experienceYears: (map['experience_years'] as num?)?.toInt() ?? 0,
      degree: map['degree'] as String? ?? '',
      fee: (map['fee'] as num?)?.toInt() ?? 0,
      rating: (map['rating'] as num?)?.toDouble() ?? 0,
      reviews: (map['reviews'] as num?)?.toInt() ?? 0,
      nextSlot: map['next_slot'] as String? ?? '',
      hospital: map['hospital'] as String? ?? '',
      area: map['area'] as String? ?? '',
      isOnline: map['is_online'] as bool? ?? false,
    );
  }
}

class DbAppointment {
  const DbAppointment({
    required this.id,
    required this.doctorName,
    required this.specialty,
    required this.slotTime,
    required this.status,
  });

  final String id;
  final String doctorName;
  final String specialty;
  final DateTime slotTime;
  final String status;

  factory DbAppointment.fromMap(Map<String, dynamic> map) {
    return DbAppointment(
      id: map['id'].toString(),
      doctorName: map['doctor_name'] as String? ?? '',
      specialty: map['specialty'] as String? ?? '',
      slotTime:
          DateTime.tryParse(map['slot_time'] as String? ?? '') ??
          DateTime.now(),
      status: map['status'] as String? ?? 'pending',
    );
  }
}

class DbHospital {
  const DbHospital({
    required this.id,
    required this.name,
    required this.area,
    required this.distanceKm,
    required this.isOpen,
    required this.hasAyushman,
    required this.phone,
  });

  final String id;
  final String name;
  final String area;
  final double distanceKm;
  final bool isOpen;
  final bool hasAyushman;
  final String phone;

  factory DbHospital.fromMap(Map<String, dynamic> map) {
    return DbHospital(
      id: map['id'].toString(),
      name: map['name'] as String? ?? '',
      area: map['area'] as String? ?? '',
      distanceKm: (map['distance_km'] as num?)?.toDouble() ?? 0,
      isOpen: map['is_open'] as bool? ?? false,
      hasAyushman: map['has_ayushman'] as bool? ?? false,
      phone: map['phone'] as String? ?? '',
    );
  }
}

class DbEmergencyContact {
  const DbEmergencyContact({
    required this.id,
    required this.name,
    required this.phone,
    required this.relation,
    required this.isPrimary,
  });

  final String id;
  final String name;
  final String phone;
  final String relation;
  final bool isPrimary;

  factory DbEmergencyContact.fromMap(Map<String, dynamic> map) {
    return DbEmergencyContact(
      id: map['id'].toString(),
      name: map['name'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      relation: map['relation'] as String? ?? '',
      isPrimary: map['is_primary'] as bool? ?? false,
    );
  }
}

class DbSosAlert {
  const DbSosAlert({
    required this.id,
    required this.status,
    required this.latitude,
    required this.longitude,
    required this.createdAt,
  });

  final String id;
  final String status;
  final double latitude;
  final double longitude;
  final DateTime createdAt;

  factory DbSosAlert.fromMap(Map<String, dynamic> map) {
    return DbSosAlert(
      id: map['id'].toString(),
      status: map['status'] as String? ?? 'sent',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0,
      createdAt:
          DateTime.tryParse(map['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

class DbCabRequest {
  const DbCabRequest({
    required this.id,
    required this.pickup,
    required this.dropLocation,
    required this.status,
    required this.driverName,
    required this.etaMinutes,
  });

  final String id;
  final String pickup;
  final String dropLocation;
  final String status;
  final String driverName;
  final int etaMinutes;

  factory DbCabRequest.fromMap(Map<String, dynamic> map) {
    return DbCabRequest(
      id: map['id'].toString(),
      pickup: map['pickup'] as String? ?? '',
      dropLocation: map['drop_location'] as String? ?? '',
      status: map['status'] as String? ?? 'requested',
      driverName: map['driver_name'] as String? ?? '',
      etaMinutes: (map['eta_minutes'] as num?)?.toInt() ?? 0,
    );
  }
}
