import 'dart:convert';

/// Appointment record model for outpatient consultations and token queue.
class AppointmentModel {
  final int id;
  final String tokenNo;
  final String patientName;
  final String uhid;
  final String doctorName;
  final String department;
  final String date;
  final String timeSlot;
  final String status;
  final String visitType;
  final String notes;
  final int patientId;
  final int doctorId;
  final int departmentId;
  final String createdAt;
  final String updatedAt;

  const AppointmentModel({
    required this.id,
    required this.tokenNo,
    required this.patientName,
    required this.uhid,
    required this.doctorName,
    required this.department,
    required this.date,
    required this.timeSlot,
    required this.status,
    required this.visitType,
    required this.notes,
    this.patientId = 0,
    this.doctorId = 0,
    this.departmentId = 0,
    this.createdAt = '',
    this.updatedAt = '',
  });

  bool get isScheduled => status.toLowerCase() == 'scheduled';
  bool get isInProgress => status.toLowerCase() == 'in_progress';
  bool get isCompleted => status.toLowerCase() == 'completed';
  bool get isCancelled => status.toLowerCase() == 'cancelled';
  bool get isNoShow => status.toLowerCase() == 'no_show';

  factory AppointmentModel.fromMap(Map<String, dynamic> map) {
    return AppointmentModel(
      id: map['id'] as int? ?? 0,
      tokenNo: map['token_no'] as String? ?? '01',
      patientName: map['patient_name'] as String? ?? '',
      uhid: map['uhid'] as String? ?? '',
      doctorName: map['doctor_name'] as String? ?? '',
      department: map['department'] as String? ?? '',
      date: (map['date'] ?? map['scheduled_date']) as String? ?? '',
      timeSlot: (map['time_slot'] ?? map['scheduled_time']) as String? ?? '',
      status: map['status'] as String? ?? 'Scheduled',
      visitType: map['visit_type'] as String? ?? 'Scheduled',
      notes: map['notes'] as String? ?? '',
      patientId: map['patient_id'] as int? ?? 0,
      doctorId: map['doctor_id'] as int? ?? 0,
      departmentId: map['department_id'] as int? ?? 0,
      createdAt: map['created_at'] as String? ?? '',
      updatedAt: map['updated_at'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        if (id > 0) 'id': id,
        'token_no': tokenNo,
        'patient_name': patientName,
        'uhid': uhid,
        'doctor_name': doctorName,
        'department': department,
        'date': date,
        'time_slot': timeSlot,
        'status': status,
        'visit_type': visitType,
        'notes': notes,
        'patient_id': patientId,
        'doctor_id': doctorId,
        'department_id': departmentId,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  String toJson() => jsonEncode(toMap());

  factory AppointmentModel.fromJson(String source) =>
      AppointmentModel.fromMap(jsonDecode(source) as Map<String, dynamic>);

  AppointmentModel copyWith({
    int? id,
    String? tokenNo,
    String? patientName,
    String? uhid,
    String? doctorName,
    String? department,
    String? date,
    String? timeSlot,
    String? status,
    String? visitType,
    String? notes,
    int? patientId,
    int? doctorId,
    int? departmentId,
    String? createdAt,
    String? updatedAt,
  }) {
    return AppointmentModel(
      id: id ?? this.id,
      tokenNo: tokenNo ?? this.tokenNo,
      patientName: patientName ?? this.patientName,
      uhid: uhid ?? this.uhid,
      doctorName: doctorName ?? this.doctorName,
      department: department ?? this.department,
      date: date ?? this.date,
      timeSlot: timeSlot ?? this.timeSlot,
      status: status ?? this.status,
      visitType: visitType ?? this.visitType,
      notes: notes ?? this.notes,
      patientId: patientId ?? this.patientId,
      doctorId: doctorId ?? this.doctorId,
      departmentId: departmentId ?? this.departmentId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppointmentModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          tokenNo == other.tokenNo &&
          uhid == other.uhid &&
          date == other.date &&
          timeSlot == other.timeSlot;

  @override
  int get hashCode =>
      id.hashCode ^
      tokenNo.hashCode ^
      uhid.hashCode ^
      date.hashCode ^
      timeSlot.hashCode;

  @override
  String toString() =>
      'AppointmentModel(#$tokenNo $patientName with $doctorName at $timeSlot [$status])';
}

/// Available appointment time slot
class AppointmentSlotModel {
  final String slotTime;
  final bool isAvailable;
  final int? appointmentId;
  final String? patientName;

  const AppointmentSlotModel({
    required this.slotTime,
    required this.isAvailable,
    this.appointmentId,
    this.patientName,
  });

  factory AppointmentSlotModel.fromMap(Map<String, dynamic> map) {
    return AppointmentSlotModel(
      slotTime: map['slot_time'] as String? ?? '',
      isAvailable: map['is_available'] as bool? ?? true,
      appointmentId: map['appointment_id'] as int?,
      patientName: map['patient_name'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'slot_time': slotTime,
        'is_available': isAvailable,
        'appointment_id': appointmentId,
        'patient_name': patientName,
      };

  String toJson() => jsonEncode(toMap());

  factory AppointmentSlotModel.fromJson(String source) =>
      AppointmentSlotModel.fromMap(jsonDecode(source) as Map<String, dynamic>);
}

/// Live OPD walk-in token model
class QueueTokenModel {
  final String tokenNo;
  final String patientName;
  final String uhid;
  final String doctorName;
  final String department;
  final String status;
  final String issueTime;
  final int waitMinutesEstimated;

  const QueueTokenModel({
    required this.tokenNo,
    required this.patientName,
    required this.uhid,
    required this.doctorName,
    required this.department,
    required this.status,
    required this.issueTime,
    this.waitMinutesEstimated = 15,
  });

  factory QueueTokenModel.fromMap(Map<String, dynamic> map) {
    return QueueTokenModel(
      tokenNo: map['token_no'] as String? ?? '01',
      patientName: map['patient_name'] as String? ?? '',
      uhid: map['uhid'] as String? ?? '',
      doctorName: map['doctor_name'] as String? ?? '',
      department: map['department'] as String? ?? '',
      status: map['status'] as String? ?? 'Waiting',
      issueTime: map['issue_time'] as String? ?? '',
      waitMinutesEstimated: map['wait_minutes'] as int? ?? 15,
    );
  }

  Map<String, dynamic> toMap() => {
        'token_no': tokenNo,
        'patient_name': patientName,
        'uhid': uhid,
        'doctor_name': doctorName,
        'department': department,
        'status': status,
        'issue_time': issueTime,
        'wait_minutes': waitMinutesEstimated,
      };

  String toJson() => jsonEncode(toMap());

  factory QueueTokenModel.fromJson(String source) =>
      QueueTokenModel.fromMap(jsonDecode(source) as Map<String, dynamic>);
}

