import 'dart:convert';

/// Staff & Doctor record model representing hospital employees.
class StaffModel {
  final int id;
  final String uuid;
  final String name;
  final String role;
  final String regNo;
  final String department;
  final String phone;
  final String email;
  final int feePaise;
  final String status;
  final String gender;
  final String dob;
  final String address;
  final String qualification;
  final String photoPath;
  final String createdAt;
  final String updatedAt;

  const StaffModel({
    required this.id,
    required this.uuid,
    required this.name,
    required this.role,
    required this.regNo,
    required this.department,
    required this.phone,
    required this.email,
    required this.feePaise,
    required this.status,
    this.gender = '',
    this.dob = '',
    this.address = '',
    this.qualification = '',
    this.photoPath = '',
    this.createdAt = '',
    this.updatedAt = '',
  });

  String get feeFormatted =>
      feePaise > 0 ? '₹${(feePaise / 100).toStringAsFixed(2)}' : '-';

  bool get isActive => status.toLowerCase() == 'active';

  factory StaffModel.fromMap(Map<String, dynamic> map) {
    return StaffModel(
      id: map['id'] as int? ?? 0,
      uuid: map['uuid'] as String? ?? '',
      name: map['name'] as String? ?? '',
      role: map['role'] as String? ?? '',
      regNo: map['reg_no'] as String? ?? '',
      department: map['department'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      email: map['email'] as String? ?? '',
      feePaise: map['consultation_fee'] as int? ?? 0,
      status: map['status'] as String? ?? 'Active',
      gender: map['gender'] as String? ?? '',
      dob: map['dob'] as String? ?? '',
      address: map['address'] as String? ?? '',
      qualification: map['qualification'] as String? ?? '',
      photoPath: map['photo_path'] as String? ?? '',
      createdAt: map['created_at'] as String? ?? '',
      updatedAt: map['updated_at'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        if (id > 0) 'id': id,
        'uuid': uuid,
        'name': name,
        'role': role,
        'reg_no': regNo,
        'department': department,
        'phone': phone,
        'email': email,
        'consultation_fee': feePaise,
        'status': status,
        'gender': gender,
        'dob': dob,
        'address': address,
        'qualification': qualification,
        'photo_path': photoPath,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  String toJson() => jsonEncode(toMap());

  factory StaffModel.fromJson(String source) =>
      StaffModel.fromMap(jsonDecode(source) as Map<String, dynamic>);

  StaffModel copyWith({
    int? id,
    String? uuid,
    String? name,
    String? role,
    String? regNo,
    String? department,
    String? phone,
    String? email,
    int? feePaise,
    String? status,
    String? gender,
    String? dob,
    String? address,
    String? qualification,
    String? photoPath,
    String? createdAt,
    String? updatedAt,
  }) {
    return StaffModel(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      name: name ?? this.name,
      role: role ?? this.role,
      regNo: regNo ?? this.regNo,
      department: department ?? this.department,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      feePaise: feePaise ?? this.feePaise,
      status: status ?? this.status,
      gender: gender ?? this.gender,
      dob: dob ?? this.dob,
      address: address ?? this.address,
      qualification: qualification ?? this.qualification,
      photoPath: photoPath ?? this.photoPath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StaffModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          uuid == other.uuid &&
          name == other.name &&
          role == other.role &&
          regNo == other.regNo &&
          department == other.department;

  @override
  int get hashCode =>
      id.hashCode ^
      uuid.hashCode ^
      name.hashCode ^
      role.hashCode ^
      regNo.hashCode ^
      department.hashCode;

  @override
  String toString() => 'StaffModel(id: $id, name: $name, role: $role, dept: $department)';
}

/// Clinical Department model
class DepartmentModel {
  final int id;
  final String uuid;
  final String name;
  final String description;
  final bool isActive;
  final String createdAt;
  final String updatedAt;

  const DepartmentModel({
    required this.id,
    required this.uuid,
    required this.name,
    this.description = '',
    this.isActive = true,
    this.createdAt = '',
    this.updatedAt = '',
  });

  factory DepartmentModel.fromMap(Map<String, dynamic> map) {
    return DepartmentModel(
      id: map['id'] as int? ?? 0,
      uuid: map['uuid'] as String? ?? '',
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      isActive: (map['is_active'] is int)
          ? (map['is_active'] as int) == 1
          : (map['is_active'] as bool? ?? true),
      createdAt: map['created_at'] as String? ?? '',
      updatedAt: map['updated_at'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        if (id > 0) 'id': id,
        'uuid': uuid,
        'name': name,
        'description': description,
        'is_active': isActive ? 1 : 0,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  String toJson() => jsonEncode(toMap());

  factory DepartmentModel.fromJson(String source) =>
      DepartmentModel.fromMap(jsonDecode(source) as Map<String, dynamic>);

  DepartmentModel copyWith({
    int? id,
    String? uuid,
    String? name,
    String? description,
    bool? isActive,
    String? createdAt,
    String? updatedAt,
  }) {
    return DepartmentModel(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      name: name ?? this.name,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DepartmentModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name;

  @override
  int get hashCode => id.hashCode ^ name.hashCode;

  @override
  String toString() => 'DepartmentModel(id: $id, name: $name)';
}

/// Doctor profile model with consultation fee and slot configuration
class DoctorModel {
  final int id;
  final String uuid;
  final int staffId;
  final String doctorName;
  final String specialisation;
  final String department;
  final int consultationFeePaise;
  final int followupFeePaise;
  final int followupDays;
  final int maxSlotsPerDay;
  final String createdAt;
  final String updatedAt;

  const DoctorModel({
    required this.id,
    required this.uuid,
    required this.staffId,
    required this.doctorName,
    required this.specialisation,
    this.department = '',
    this.consultationFeePaise = 0,
    this.followupFeePaise = 0,
    this.followupDays = 7,
    this.maxSlotsPerDay = 30,
    this.createdAt = '',
    this.updatedAt = '',
  });

  String get consultationFeeFormatted =>
      '₹${(consultationFeePaise / 100).toStringAsFixed(2)}';
  String get followupFeeFormatted =>
      '₹${(followupFeePaise / 100).toStringAsFixed(2)}';

  factory DoctorModel.fromMap(Map<String, dynamic> map) {
    return DoctorModel(
      id: map['id'] as int? ?? 0,
      uuid: map['uuid'] as String? ?? '',
      staffId: map['staff_id'] as int? ?? 0,
      doctorName: map['doctor_name'] as String? ?? '',
      specialisation: map['specialisation'] as String? ?? '',
      department: map['department'] as String? ?? '',
      consultationFeePaise: map['consultation_fee'] as int? ?? 0,
      followupFeePaise: map['followup_fee'] as int? ?? 0,
      followupDays: map['followup_days'] as int? ?? 7,
      maxSlotsPerDay: map['max_slots_per_day'] as int? ?? 30,
      createdAt: map['created_at'] as String? ?? '',
      updatedAt: map['updated_at'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        if (id > 0) 'id': id,
        'uuid': uuid,
        'staff_id': staffId,
        'doctor_name': doctorName,
        'specialisation': specialisation,
        'department': department,
        'consultation_fee': consultationFeePaise,
        'followup_fee': followupFeePaise,
        'followup_days': followupDays,
        'max_slots_per_day': maxSlotsPerDay,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  String toJson() => jsonEncode(toMap());

  factory DoctorModel.fromJson(String source) =>
      DoctorModel.fromMap(jsonDecode(source) as Map<String, dynamic>);

  DoctorModel copyWith({
    int? id,
    String? uuid,
    int? staffId,
    String? doctorName,
    String? specialisation,
    String? department,
    int? consultationFeePaise,
    int? followupFeePaise,
    int? followupDays,
    int? maxSlotsPerDay,
    String? createdAt,
    String? updatedAt,
  }) {
    return DoctorModel(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      staffId: staffId ?? this.staffId,
      doctorName: doctorName ?? this.doctorName,
      specialisation: specialisation ?? this.specialisation,
      department: department ?? this.department,
      consultationFeePaise: consultationFeePaise ?? this.consultationFeePaise,
      followupFeePaise: followupFeePaise ?? this.followupFeePaise,
      followupDays: followupDays ?? this.followupDays,
      maxSlotsPerDay: maxSlotsPerDay ?? this.maxSlotsPerDay,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DoctorModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          staffId == other.staffId &&
          doctorName == other.doctorName;

  @override
  int get hashCode => id.hashCode ^ staffId.hashCode ^ doctorName.hashCode;

  @override
  String toString() => 'DoctorModel(id: $id, name: $doctorName, spec: $specialisation)';
}

/// Doctor schedule representation per weekday
class DoctorScheduleModel {
  final int id;
  final String uuid;
  final int doctorId;
  final int weekday; // 0 = Mon, 6 = Sun
  final String startTime;
  final String endTime;
  final int slotMinutes;
  final bool isActive;
  final String createdAt;
  final String updatedAt;

  const DoctorScheduleModel({
    required this.id,
    required this.uuid,
    required this.doctorId,
    required this.weekday,
    required this.startTime,
    required this.endTime,
    this.slotMinutes = 15,
    this.isActive = true,
    this.createdAt = '',
    this.updatedAt = '',
  });

  String get weekdayName {
    const names = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    if (weekday >= 0 && weekday < names.length) return names[weekday];
    return 'Day $weekday';
  }

  factory DoctorScheduleModel.fromMap(Map<String, dynamic> map) {
    return DoctorScheduleModel(
      id: map['id'] as int? ?? 0,
      uuid: map['uuid'] as String? ?? '',
      doctorId: map['doctor_id'] as int? ?? 0,
      weekday: map['weekday'] as int? ?? 0,
      startTime: map['start_time'] as String? ?? '09:00',
      endTime: map['end_time'] as String? ?? '17:00',
      slotMinutes: map['slot_minutes'] as int? ?? 15,
      isActive: (map['is_active'] is int)
          ? (map['is_active'] as int) == 1
          : (map['is_active'] as bool? ?? true),
      createdAt: map['created_at'] as String? ?? '',
      updatedAt: map['updated_at'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        if (id > 0) 'id': id,
        'uuid': uuid,
        'doctor_id': doctorId,
        'weekday': weekday,
        'start_time': startTime,
        'end_time': endTime,
        'slot_minutes': slotMinutes,
        'is_active': isActive ? 1 : 0,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  String toJson() => jsonEncode(toMap());

  factory DoctorScheduleModel.fromJson(String source) =>
      DoctorScheduleModel.fromMap(jsonDecode(source) as Map<String, dynamic>);

  DoctorScheduleModel copyWith({
    int? id,
    String? uuid,
    int? doctorId,
    int? weekday,
    String? startTime,
    String? endTime,
    int? slotMinutes,
    bool? isActive,
    String? createdAt,
    String? updatedAt,
  }) {
    return DoctorScheduleModel(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      doctorId: doctorId ?? this.doctorId,
      weekday: weekday ?? this.weekday,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      slotMinutes: slotMinutes ?? this.slotMinutes,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DoctorScheduleModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          doctorId == other.doctorId &&
          weekday == other.weekday;

  @override
  int get hashCode => id.hashCode ^ doctorId.hashCode ^ weekday.hashCode;

  @override
  String toString() => 'DoctorScheduleModel($weekdayName: $startTime - $endTime)';
}

