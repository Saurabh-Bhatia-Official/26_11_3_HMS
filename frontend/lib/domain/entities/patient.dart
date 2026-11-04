import 'package:equatable/equatable.dart';

/// Core domain entity representing a hospital patient.
/// All IDs are SQLite rowids (int); money is never stored here.
class Patient extends Equatable {
  const Patient({
    required this.id,
    required this.uuid,
    required this.uhid,
    required this.name,
    this.gender,
    this.dob,
    this.ageYears,
    this.phone,
    this.altPhone,
    this.email,
    this.address,
    this.city,
    this.state,
    this.pincode,
    this.bloodGroup,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.idType,
    this.idNumber,
    this.photoPath,
    this.isVip = false,
    this.notes,
    required this.createdAt,
    this.isDeleted = false,
  });

  final int id;
  final String uuid;

  /// Unique Hospital ID, e.g. "UHID-000042"
  final String uhid;
  final String name;

  /// "Male" | "Female" | "Other"
  final String? gender;

  /// Date of birth – preferred over [ageYears] when available.
  final DateTime? dob;

  /// Fallback age in years when exact DOB is unknown.
  final int? ageYears;

  final String? phone;
  final String? altPhone;
  final String? email;
  final String? address;
  final String? city;
  final String? state;
  final String? pincode;

  /// "A+" | "A-" | "B+" | "B-" | "O+" | "O-" | "AB+" | "AB-"
  final String? bloodGroup;

  final String? emergencyContactName;
  final String? emergencyContactPhone;

  /// "Aadhaar" | "PAN" | "Passport" | "DL" | "Other"
  final String? idType;
  final String? idNumber;

  /// Absolute path to the patient photo on-device.
  final String? photoPath;
  final bool isVip;
  final String? notes;
  final DateTime createdAt;
  final bool isDeleted;

  // ── Computed ─────────────────────────────────────────────────────────────

  /// Returns best-effort age in years.
  int get age {
    if (dob != null) {
      final now = DateTime.now();
      int years = now.year - dob!.year;
      final hadBirthday = (now.month > dob!.month) ||
          (now.month == dob!.month && now.day >= dob!.day);
      if (!hadBirthday) years--;
      return years < 0 ? 0 : years;
    }
    return ageYears ?? 0;
  }

  /// Compact display: "28 M" / "45 F"
  String get ageSexDisplay {
    final a = age;
    final g = gender != null ? gender![0].toUpperCase() : '?';
    return '$a $g';
  }

  // ── CopyWith ──────────────────────────────────────────────────────────────

  Patient copyWith({
    int? id,
    String? uuid,
    String? uhid,
    String? name,
    String? gender,
    DateTime? dob,
    int? ageYears,
    String? phone,
    String? altPhone,
    String? email,
    String? address,
    String? city,
    String? state,
    String? pincode,
    String? bloodGroup,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? idType,
    String? idNumber,
    String? photoPath,
    bool? isVip,
    String? notes,
    DateTime? createdAt,
    bool? isDeleted,
    // Sentinel to explicitly null optional fields
    bool clearDob = false,
    bool clearAgeYears = false,
    bool clearGender = false,
    bool clearPhotoPath = false,
  }) {
    return Patient(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      uhid: uhid ?? this.uhid,
      name: name ?? this.name,
      gender: clearGender ? null : (gender ?? this.gender),
      dob: clearDob ? null : (dob ?? this.dob),
      ageYears: clearAgeYears ? null : (ageYears ?? this.ageYears),
      phone: phone ?? this.phone,
      altPhone: altPhone ?? this.altPhone,
      email: email ?? this.email,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone:
          emergencyContactPhone ?? this.emergencyContactPhone,
      idType: idType ?? this.idType,
      idNumber: idNumber ?? this.idNumber,
      photoPath: clearPhotoPath ? null : (photoPath ?? this.photoPath),
      isVip: isVip ?? this.isVip,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  @override
  List<Object?> get props => [
        id,
        uuid,
        uhid,
        name,
        gender,
        dob,
        ageYears,
        phone,
        altPhone,
        email,
        address,
        city,
        state,
        pincode,
        bloodGroup,
        emergencyContactName,
        emergencyContactPhone,
        idType,
        idNumber,
        photoPath,
        isVip,
        notes,
        createdAt,
        isDeleted,
      ];
}
