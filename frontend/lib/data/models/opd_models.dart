import 'dart:convert';

/// OPD Visit record model including patient vitals, diagnosis and clinical notes.
class OpdVisitModel {
  final int id;
  final String tokenNo;
  final String patientName;
  final String uhid;
  final String doctorName;
  final String department;
  final String ageGender;
  final String status;
  final String complaint;
  final String history;
  final String examination;
  final String diagnosis;
  final String advice;
  final String bpSys;
  final String bpDia;
  final String pulse;
  final String temp;
  final String spo2;
  final String weight;
  final String height;
  final List<Map<String, String>> medications;
  final int patientId;
  final int doctorId;
  final String visitDate;
  final String icdCode;
  final String followUpDate;
  final String createdAt;
  final String updatedAt;

  const OpdVisitModel({
    required this.id,
    required this.tokenNo,
    required this.patientName,
    required this.uhid,
    required this.doctorName,
    required this.department,
    required this.ageGender,
    required this.status,
    required this.complaint,
    required this.history,
    required this.examination,
    required this.diagnosis,
    required this.advice,
    required this.bpSys,
    required this.bpDia,
    required this.pulse,
    required this.temp,
    required this.spo2,
    required this.weight,
    required this.height,
    required this.medications,
    this.patientId = 0,
    this.doctorId = 0,
    this.visitDate = '',
    this.icdCode = '',
    this.followUpDate = '',
    this.createdAt = '',
    this.updatedAt = '',
  });

  String get vitalsSummary =>
      'BP $bpSys/$bpDia, Pulse $pulse, Temp $temp°F, SpO2 $spo2%';

  double? get bmi {
    final w = double.tryParse(weight);
    final h = double.tryParse(height);
    if (w != null && h != null && h > 0) {
      final hm = h / 100.0;
      return w / (hm * hm);
    }
    return null;
  }

  bool get isWaitingForVitals => status == 'Waiting for Vitals';
  bool get isInConsultation => status == 'In Consultation';
  bool get isCompleted => status == 'Completed';

  factory OpdVisitModel.fromMap(Map<String, dynamic> map) {
    List<Map<String, String>> parsedMeds = [];
    final medsJson = map['medications_json'] as String?;
    if (medsJson != null && medsJson.isNotEmpty) {
      try {
        final list = jsonDecode(medsJson) as List<dynamic>;
        parsedMeds = list
            .map((e) => Map<String, String>.from(e as Map<dynamic, dynamic>))
            .toList();
      } catch (_) {}
    }

    return OpdVisitModel(
      id: map['id'] as int? ?? 0,
      tokenNo: map['token_no'] as String? ?? '01',
      patientName: map['patient_name'] as String? ?? '',
      uhid: map['uhid'] as String? ?? '',
      doctorName: map['doctor_name'] as String? ?? '',
      department: map['department'] as String? ?? '',
      ageGender: map['age_gender'] as String? ?? '',
      status: map['status'] as String? ?? 'Waiting for Vitals',
      complaint: map['complaint'] as String? ?? '',
      history: map['history'] as String? ?? '',
      examination: map['examination'] as String? ?? '',
      diagnosis: map['diagnosis'] as String? ?? '',
      advice: map['advice'] as String? ?? '',
      bpSys: map['bp_sys'] as String? ?? '120',
      bpDia: map['bp_dia'] as String? ?? '80',
      pulse: map['pulse'] as String? ?? '72',
      temp: map['temp'] as String? ?? '98.6',
      spo2: map['spo2'] as String? ?? '99',
      weight: map['weight'] as String? ?? '70',
      height: map['height'] as String? ?? '170',
      medications: parsedMeds,
      patientId: map['patient_id'] as int? ?? 0,
      doctorId: map['doctor_id'] as int? ?? 0,
      visitDate: map['visit_date'] as String? ?? '',
      icdCode: map['icd_code'] as String? ?? '',
      followUpDate: map['follow_up_date'] as String? ?? '',
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
        'age_gender': ageGender,
        'status': status,
        'complaint': complaint,
        'history': history,
        'examination': examination,
        'diagnosis': diagnosis,
        'advice': advice,
        'bp_sys': bpSys,
        'bp_dia': bpDia,
        'pulse': pulse,
        'temp': temp,
        'spo2': spo2,
        'weight': weight,
        'height': height,
        'medications_json': jsonEncode(medications),
        'patient_id': patientId,
        'doctor_id': doctorId,
        'visit_date': visitDate,
        'icd_code': icdCode,
        'follow_up_date': followUpDate,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  String toJson() => jsonEncode(toMap());

  factory OpdVisitModel.fromJson(String source) =>
      OpdVisitModel.fromMap(jsonDecode(source) as Map<String, dynamic>);

  OpdVisitModel copyWith({
    int? id,
    String? tokenNo,
    String? patientName,
    String? uhid,
    String? doctorName,
    String? department,
    String? ageGender,
    String? status,
    String? complaint,
    String? history,
    String? examination,
    String? diagnosis,
    String? advice,
    String? bpSys,
    String? bpDia,
    String? pulse,
    String? temp,
    String? spo2,
    String? weight,
    String? height,
    List<Map<String, String>>? medications,
    int? patientId,
    int? doctorId,
    String? visitDate,
    String? icdCode,
    String? followUpDate,
    String? createdAt,
    String? updatedAt,
  }) {
    return OpdVisitModel(
      id: id ?? this.id,
      tokenNo: tokenNo ?? this.tokenNo,
      patientName: patientName ?? this.patientName,
      uhid: uhid ?? this.uhid,
      doctorName: doctorName ?? this.doctorName,
      department: department ?? this.department,
      ageGender: ageGender ?? this.ageGender,
      status: status ?? this.status,
      complaint: complaint ?? this.complaint,
      history: history ?? this.history,
      examination: examination ?? this.examination,
      diagnosis: diagnosis ?? this.diagnosis,
      advice: advice ?? this.advice,
      bpSys: bpSys ?? this.bpSys,
      bpDia: bpDia ?? this.bpDia,
      pulse: pulse ?? this.pulse,
      temp: temp ?? this.temp,
      spo2: spo2 ?? this.spo2,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      medications: medications ?? this.medications,
      patientId: patientId ?? this.patientId,
      doctorId: doctorId ?? this.doctorId,
      visitDate: visitDate ?? this.visitDate,
      icdCode: icdCode ?? this.icdCode,
      followUpDate: followUpDate ?? this.followUpDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OpdVisitModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          uhid == other.uhid &&
          tokenNo == other.tokenNo;

  @override
  int get hashCode => id.hashCode ^ uhid.hashCode ^ tokenNo.hashCode;

  @override
  String toString() =>
      'OpdVisitModel(token: #$tokenNo, patient: $patientName, status: $status)';
}

/// Clinical Vitals record model
class VitalsModel {
  final int id;
  final String uuid;
  final int visitId;
  final int? bpSystolic;
  final int? bpDiastolic;
  final int? pulse;
  final double? temperatureC;
  final int? spo2;
  final double? weightKg;
  final double? heightCm;
  final double? bmi;
  final String recordedAt;
  final String recordedBy;
  final String notes;

  const VitalsModel({
    required this.id,
    required this.uuid,
    required this.visitId,
    this.bpSystolic,
    this.bpDiastolic,
    this.pulse,
    this.temperatureC,
    this.spo2,
    this.weightKg,
    this.heightCm,
    this.bmi,
    required this.recordedAt,
    this.recordedBy = '',
    this.notes = '',
  });

  String get bpDisplay => (bpSystolic != null && bpDiastolic != null)
      ? '$bpSystolic/$bpDiastolic mmHg'
      : '-';

  String get pulseDisplay => pulse != null ? '$pulse bpm' : '-';
  String get tempDisplay => temperatureC != null ? '${temperatureC!.toStringAsFixed(1)} °C' : '-';
  String get spo2Display => spo2 != null ? '$spo2%' : '-';
  String get bmiDisplay => bmi != null ? bmi!.toStringAsFixed(1) : '-';

  factory VitalsModel.fromMap(Map<String, dynamic> map) {
    return VitalsModel(
      id: map['id'] as int? ?? 0,
      uuid: map['uuid'] as String? ?? '',
      visitId: map['visit_id'] as int? ?? 0,
      bpSystolic: map['bp_systolic'] as int?,
      bpDiastolic: map['bp_diastolic'] as int?,
      pulse: map['pulse'] as int?,
      temperatureC: (map['temperature_c'] as num?)?.toDouble(),
      spo2: map['spo2'] as int?,
      weightKg: (map['weight_kg'] as num?)?.toDouble(),
      heightCm: (map['height_cm'] as num?)?.toDouble(),
      bmi: (map['bmi'] as num?)?.toDouble(),
      recordedAt: map['recorded_at'] as String? ?? '',
      recordedBy: map['recorded_by'] as String? ?? '',
      notes: map['notes'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        if (id > 0) 'id': id,
        'uuid': uuid,
        'visit_id': visitId,
        'bp_systolic': bpSystolic,
        'bp_diastolic': bpDiastolic,
        'pulse': pulse,
        'temperature_c': temperatureC,
        'spo2': spo2,
        'weight_kg': weightKg,
        'height_cm': heightCm,
        'bmi': bmi,
        'recorded_at': recordedAt,
        'recorded_by': recordedBy,
        'notes': notes,
      };

  String toJson() => jsonEncode(toMap());

  factory VitalsModel.fromJson(String source) =>
      VitalsModel.fromMap(jsonDecode(source) as Map<String, dynamic>);
}

/// Clinical Consultation model
class ConsultationModel {
  final int id;
  final String uuid;
  final int visitId;
  final String chiefComplaint;
  final String history;
  final String examination;
  final String diagnosisText;
  final String? icdCode;
  final String? icdDescription;
  final String advice;
  final String? followUpDate;
  final int version;
  final String createdAt;
  final String updatedAt;

  const ConsultationModel({
    required this.id,
    required this.uuid,
    required this.visitId,
    this.chiefComplaint = '',
    this.history = '',
    this.examination = '',
    this.diagnosisText = '',
    this.icdCode,
    this.icdDescription,
    this.advice = '',
    this.followUpDate,
    this.version = 1,
    this.createdAt = '',
    this.updatedAt = '',
  });

  factory ConsultationModel.fromMap(Map<String, dynamic> map) {
    return ConsultationModel(
      id: map['id'] as int? ?? 0,
      uuid: map['uuid'] as String? ?? '',
      visitId: map['visit_id'] as int? ?? 0,
      chiefComplaint: map['chief_complaint'] as String? ?? '',
      history: map['history'] as String? ?? '',
      examination: map['examination'] as String? ?? '',
      diagnosisText: map['diagnosis_text'] as String? ?? '',
      icdCode: map['icd_code'] as String?,
      icdDescription: map['icd_description'] as String?,
      advice: map['advice'] as String? ?? '',
      followUpDate: map['follow_up_date'] as String?,
      version: map['version'] as int? ?? 1,
      createdAt: map['created_at'] as String? ?? '',
      updatedAt: map['updated_at'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        if (id > 0) 'id': id,
        'uuid': uuid,
        'visit_id': visitId,
        'chief_complaint': chiefComplaint,
        'history': history,
        'examination': examination,
        'diagnosis_text': diagnosisText,
        'icd_code': icdCode,
        'icd_description': icdDescription,
        'advice': advice,
        'follow_up_date': followUpDate,
        'version': version,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  String toJson() => jsonEncode(toMap());

  factory ConsultationModel.fromJson(String source) =>
      ConsultationModel.fromMap(jsonDecode(source) as Map<String, dynamic>);
}

