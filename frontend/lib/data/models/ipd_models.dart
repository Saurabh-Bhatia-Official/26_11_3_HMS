import 'dart:convert';

/// Inpatient Admission model representing admitted patients, bed occupancy and care summary.
class IpdAdmissionModel {
  final int id;
  final String patientName;
  final String uhid;
  final String ward;
  final String bedNo;
  final String doctorName;
  final String admitDate;
  final int days;
  final String diagnosis;
  final String status;
  final int depositPaise;
  final List<Map<String, dynamic>> notes;
  final List<Map<String, dynamic>> medications;
  final int patientId;
  final int bedId;
  final int admittingDoctorId;
  final String dischargeDate;
  final String dischargeSummary;
  final String createdAt;
  final String updatedAt;

  const IpdAdmissionModel({
    required this.id,
    required this.patientName,
    required this.uhid,
    required this.ward,
    required this.bedNo,
    required this.doctorName,
    required this.admitDate,
    required this.days,
    required this.diagnosis,
    required this.status,
    required this.depositPaise,
    required this.notes,
    required this.medications,
    this.patientId = 0,
    this.bedId = 0,
    this.admittingDoctorId = 0,
    this.dischargeDate = '',
    this.dischargeSummary = '',
    this.createdAt = '',
    this.updatedAt = '',
  });

  String get depositFormatted => '₹${(depositPaise / 100).toStringAsFixed(0)}';

  bool get isAdmitted => status.toLowerCase() == 'admitted';
  bool get isDischarged => status.toLowerCase() == 'discharged';
  bool get isTransferred => status.toLowerCase() == 'transferred';

  factory IpdAdmissionModel.fromMap(Map<String, dynamic> map) {
    List<Map<String, dynamic>> parsedNotes = [];
    final notesJson = map['notes_json'] as String?;
    if (notesJson != null && notesJson.isNotEmpty) {
      try {
        final list = jsonDecode(notesJson) as List<dynamic>;
        parsedNotes = list
            .map((e) => Map<String, dynamic>.from(e as Map<dynamic, dynamic>))
            .toList();
      } catch (_) {}
    }

    List<Map<String, dynamic>> parsedMeds = [];
    final medsJson = map['medications_json'] as String?;
    if (medsJson != null && medsJson.isNotEmpty) {
      try {
        final list = jsonDecode(medsJson) as List<dynamic>;
        parsedMeds = list
            .map((e) => Map<String, dynamic>.from(e as Map<dynamic, dynamic>))
            .toList();
      } catch (_) {}
    }

    return IpdAdmissionModel(
      id: map['id'] as int? ?? 0,
      patientName: map['patient_name'] as String? ?? '',
      uhid: map['uhid'] as String? ?? '',
      ward: map['ward'] as String? ?? '',
      bedNo: map['bed_no'] as String? ?? '',
      doctorName: map['doctor_name'] as String? ?? '',
      admitDate: map['admit_date'] as String? ?? '',
      days: map['days'] as int? ?? 1,
      diagnosis: map['diagnosis'] as String? ?? '',
      status: map['status'] as String? ?? 'Admitted',
      depositPaise: map['deposit_paise'] as int? ?? 0,
      notes: parsedNotes,
      medications: parsedMeds,
      patientId: map['patient_id'] as int? ?? 0,
      bedId: map['bed_id'] as int? ?? 0,
      admittingDoctorId: map['admitting_doctor_id'] as int? ?? 0,
      dischargeDate: map['discharge_date'] as String? ?? '',
      dischargeSummary: map['discharge_summary'] as String? ?? '',
      createdAt: map['created_at'] as String? ?? '',
      updatedAt: map['updated_at'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        if (id > 0) 'id': id,
        'patient_name': patientName,
        'uhid': uhid,
        'ward': ward,
        'bed_no': bedNo,
        'doctor_name': doctorName,
        'admit_date': admitDate,
        'days': days,
        'diagnosis': diagnosis,
        'status': status,
        'deposit_paise': depositPaise,
        'notes_json': jsonEncode(notes),
        'medications_json': jsonEncode(medications),
        'patient_id': patientId,
        'bed_id': bedId,
        'admitting_doctor_id': admittingDoctorId,
        'discharge_date': dischargeDate,
        'discharge_summary': dischargeSummary,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  String toJson() => jsonEncode(toMap());

  factory IpdAdmissionModel.fromJson(String source) =>
      IpdAdmissionModel.fromMap(jsonDecode(source) as Map<String, dynamic>);

  IpdAdmissionModel copyWith({
    int? id,
    String? patientName,
    String? uhid,
    String? ward,
    String? bedNo,
    String? doctorName,
    String? admitDate,
    int? days,
    String? diagnosis,
    String? status,
    int? depositPaise,
    List<Map<String, dynamic>>? notes,
    List<Map<String, dynamic>>? medications,
    int? patientId,
    int? bedId,
    int? admittingDoctorId,
    String? dischargeDate,
    String? dischargeSummary,
    String? createdAt,
    String? updatedAt,
  }) {
    return IpdAdmissionModel(
      id: id ?? this.id,
      patientName: patientName ?? this.patientName,
      uhid: uhid ?? this.uhid,
      ward: ward ?? this.ward,
      bedNo: bedNo ?? this.bedNo,
      doctorName: doctorName ?? this.doctorName,
      admitDate: admitDate ?? this.admitDate,
      days: days ?? this.days,
      diagnosis: diagnosis ?? this.diagnosis,
      status: status ?? this.status,
      depositPaise: depositPaise ?? this.depositPaise,
      notes: notes ?? this.notes,
      medications: medications ?? this.medications,
      patientId: patientId ?? this.patientId,
      bedId: bedId ?? this.bedId,
      admittingDoctorId: admittingDoctorId ?? this.admittingDoctorId,
      dischargeDate: dischargeDate ?? this.dischargeDate,
      dischargeSummary: dischargeSummary ?? this.dischargeSummary,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IpdAdmissionModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          uhid == other.uhid &&
          bedNo == other.bedNo;

  @override
  int get hashCode => id.hashCode ^ uhid.hashCode ^ bedNo.hashCode;

  @override
  String toString() =>
      'IpdAdmissionModel($patientName, Bed $bedNo, Ward $ward [$status])';
}

/// Nursing clinical care note model
class NursingNoteModel {
  final int id;
  final String uuid;
  final int admissionId;
  final String note;
  final String authorName;
  final String authorRole;
  final String createdAt;

  const NursingNoteModel({
    required this.id,
    required this.uuid,
    required this.admissionId,
    required this.note,
    this.authorName = '',
    this.authorRole = 'Nurse',
    required this.createdAt,
  });

  factory NursingNoteModel.fromMap(Map<String, dynamic> map) {
    return NursingNoteModel(
      id: map['id'] as int? ?? 0,
      uuid: map['uuid'] as String? ?? '',
      admissionId: map['admission_id'] as int? ?? 0,
      note: map['note'] as String? ?? '',
      authorName: map['author_name'] as String? ?? '',
      authorRole: map['author_role'] as String? ?? 'Nurse',
      createdAt: map['created_at'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        if (id > 0) 'id': id,
        'uuid': uuid,
        'admission_id': admissionId,
        'note': note,
        'author_name': authorName,
        'author_role': authorRole,
        'created_at': createdAt,
      };

  String toJson() => jsonEncode(toMap());

  factory NursingNoteModel.fromJson(String source) =>
      NursingNoteModel.fromMap(jsonDecode(source) as Map<String, dynamic>);
}

/// Doctor daily round note model
class DoctorRoundNoteModel {
  final int id;
  final String uuid;
  final int admissionId;
  final int doctorId;
  final String doctorName;
  final String note;
  final String createdAt;

  const DoctorRoundNoteModel({
    required this.id,
    required this.uuid,
    required this.admissionId,
    required this.doctorId,
    required this.doctorName,
    required this.note,
    required this.createdAt,
  });

  factory DoctorRoundNoteModel.fromMap(Map<String, dynamic> map) {
    return DoctorRoundNoteModel(
      id: map['id'] as int? ?? 0,
      uuid: map['uuid'] as String? ?? '',
      admissionId: map['admission_id'] as int? ?? 0,
      doctorId: map['doctor_id'] as int? ?? 0,
      doctorName: map['doctor_name'] as String? ?? '',
      note: map['note'] as String? ?? '',
      createdAt: map['created_at'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        if (id > 0) 'id': id,
        'uuid': uuid,
        'admission_id': admissionId,
        'doctor_id': doctorId,
        'doctor_name': doctorName,
        'note': note,
        'created_at': createdAt,
      };

  String toJson() => jsonEncode(toMap());

  factory DoctorRoundNoteModel.fromJson(String source) =>
      DoctorRoundNoteModel.fromMap(jsonDecode(source) as Map<String, dynamic>);
}

/// Inpatient Medication Administration Record (eMAR)
class MedicationAdministrationModel {
  final int id;
  final String uuid;
  final int admissionId;
  final String medicineName;
  final String dose;
  final String route;
  final String scheduledTime;
  final String? givenTime;
  final String status; // pending, given, skipped, held
  final String administeredBy;

  const MedicationAdministrationModel({
    required this.id,
    required this.uuid,
    required this.admissionId,
    required this.medicineName,
    required this.dose,
    required this.route,
    required this.scheduledTime,
    this.givenTime,
    this.status = 'pending',
    this.administeredBy = '',
  });

  bool get isGiven => status.toLowerCase() == 'given';
  bool get isPending => status.toLowerCase() == 'pending';

  factory MedicationAdministrationModel.fromMap(Map<String, dynamic> map) {
    return MedicationAdministrationModel(
      id: map['id'] as int? ?? 0,
      uuid: map['uuid'] as String? ?? '',
      admissionId: map['admission_id'] as int? ?? 0,
      medicineName: map['medicine_name'] as String? ?? '',
      dose: map['dose'] as String? ?? '',
      route: map['route'] as String? ?? '',
      scheduledTime: map['scheduled_time'] as String? ?? '',
      givenTime: map['given_time'] as String?,
      status: map['status'] as String? ?? 'pending',
      administeredBy: map['administered_by'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        if (id > 0) 'id': id,
        'uuid': uuid,
        'admission_id': admissionId,
        'medicine_name': medicineName,
        'dose': dose,
        'route': route,
        'scheduled_time': scheduledTime,
        'given_time': givenTime,
        'status': status,
        'administered_by': administeredBy,
      };

  String toJson() => jsonEncode(toMap());

  factory MedicationAdministrationModel.fromJson(String source) =>
      MedicationAdministrationModel.fromMap(jsonDecode(source) as Map<String, dynamic>);
}

/// Discharge summary card & documentation model
class DischargeSummaryModel {
  final int id;
  final int admissionId;
  final String patientName;
  final String uhid;
  final String admitDate;
  final String dischargeDate;
  final String admittingDiagnosis;
  final String finalDiagnosis;
  final String clinicalCourse;
  final String dischargeAdvice;
  final String followUpInstructions;
  final String consultantDoctor;

  const DischargeSummaryModel({
    required this.id,
    required this.admissionId,
    required this.patientName,
    required this.uhid,
    required this.admitDate,
    required this.dischargeDate,
    required this.admittingDiagnosis,
    required this.finalDiagnosis,
    this.clinicalCourse = '',
    this.dischargeAdvice = '',
    this.followUpInstructions = '',
    required this.consultantDoctor,
  });

  factory DischargeSummaryModel.fromMap(Map<String, dynamic> map) {
    return DischargeSummaryModel(
      id: map['id'] as int? ?? 0,
      admissionId: map['admission_id'] as int? ?? 0,
      patientName: map['patient_name'] as String? ?? '',
      uhid: map['uhid'] as String? ?? '',
      admitDate: map['admit_date'] as String? ?? '',
      dischargeDate: map['discharge_date'] as String? ?? '',
      admittingDiagnosis: map['admitting_diagnosis'] as String? ?? '',
      finalDiagnosis: map['final_diagnosis'] as String? ?? '',
      clinicalCourse: map['clinical_course'] as String? ?? '',
      dischargeAdvice: map['discharge_advice'] as String? ?? '',
      followUpInstructions: map['follow_up_instructions'] as String? ?? '',
      consultantDoctor: map['consultant_doctor'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        if (id > 0) 'id': id,
        'admission_id': admissionId,
        'patient_name': patientName,
        'uhid': uhid,
        'admit_date': admitDate,
        'discharge_date': dischargeDate,
        'admitting_diagnosis': admittingDiagnosis,
        'final_diagnosis': finalDiagnosis,
        'clinical_course': clinicalCourse,
        'discharge_advice': dischargeAdvice,
        'follow_up_instructions': followUpInstructions,
        'consultant_doctor': consultantDoctor,
      };

  String toJson() => jsonEncode(toMap());

  factory DischargeSummaryModel.fromJson(String source) =>
      DischargeSummaryModel.fromMap(jsonDecode(source) as Map<String, dynamic>);
}

