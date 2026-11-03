import 'dart:convert';
import 'package:hospital_management/domain/entities/patient.dart';

/// Data-layer Patient model mirroring SQLite patients table.
class PatientModel {
  final int id;
  final String uuid;
  final String uhid;
  final String name;
  final String gender;
  final String dob;
  final int ageYears;
  final String phone;
  final String altPhone;
  final String email;
  final String address;
  final String city;
  final String state;
  final String pincode;
  final String bloodGroup;
  final String emergencyContactName;
  final String emergencyContactPhone;
  final String idType;
  final String idNumber;
  final String photoPath;
  final bool isVip;
  final String notes;
  final String createdAt;
  final bool isDeleted;

  const PatientModel({
    required this.id,
    required this.uuid,
    required this.uhid,
    required this.name,
    this.gender = '',
    this.dob = '',
    this.ageYears = 0,
    this.phone = '',
    this.altPhone = '',
    this.email = '',
    this.address = '',
    this.city = '',
    this.state = '',
    this.pincode = '',
    this.bloodGroup = '',
    this.emergencyContactName = '',
    this.emergencyContactPhone = '',
    this.idType = '',
    this.idNumber = '',
    this.photoPath = '',
    this.isVip = false,
    this.notes = '',
    this.createdAt = '',
    this.isDeleted = false,
  });

  factory PatientModel.fromMap(Map<String, dynamic> map) {
    return PatientModel(
      id: map['id'] as int? ?? 0,
      uuid: map['uuid'] as String? ?? '',
      uhid: map['uhid'] as String? ?? '',
      name: map['name'] as String? ?? '',
      gender: map['gender'] as String? ?? '',
      dob: map['dob'] as String? ?? '',
      ageYears: map['age_years'] as int? ?? 0,
      phone: map['phone'] as String? ?? '',
      altPhone: map['alt_phone'] as String? ?? '',
      email: map['email'] as String? ?? '',
      address: map['address'] as String? ?? '',
      city: map['city'] as String? ?? '',
      state: map['state'] as String? ?? '',
      pincode: map['pincode'] as String? ?? '',
      bloodGroup: map['blood_group'] as String? ?? '',
      emergencyContactName: map['emergency_contact_name'] as String? ?? '',
      emergencyContactPhone: map['emergency_contact_phone'] as String? ?? '',
      idType: map['id_type'] as String? ?? '',
      idNumber: map['id_number'] as String? ?? '',
      photoPath: map['photo_path'] as String? ?? '',
      isVip: (map['is_vip'] is int)
          ? (map['is_vip'] as int) == 1
          : (map['is_vip'] as bool? ?? false),
      notes: map['notes'] as String? ?? '',
      createdAt: map['created_at'] as String? ?? '',
      isDeleted: (map['is_deleted'] is int)
          ? (map['is_deleted'] as int) == 1
          : (map['is_deleted'] as bool? ?? false),
    );
  }

  Map<String, dynamic> toMap() => {
        if (id > 0) 'id': id,
        'uuid': uuid,
        'uhid': uhid,
        'name': name,
        'gender': gender,
        'dob': dob,
        'age_years': ageYears,
        'phone': phone,
        'alt_phone': altPhone,
        'email': email,
        'address': address,
        'city': city,
        'state': state,
        'pincode': pincode,
        'blood_group': bloodGroup,
        'emergency_contact_name': emergencyContactName,
        'emergency_contact_phone': emergencyContactPhone,
        'id_type': idType,
        'id_number': idNumber,
        'photo_path': photoPath,
        'is_vip': isVip ? 1 : 0,
        'notes': notes,
        'created_at': createdAt,
        'is_deleted': isDeleted ? 1 : 0,
      };

  String toJson() => jsonEncode(toMap());

  factory PatientModel.fromJson(String source) =>
      PatientModel.fromMap(jsonDecode(source) as Map<String, dynamic>);

  Patient toDomain() {
    DateTime? parsedDob;
    if (dob.isNotEmpty) {
      try {
        parsedDob = DateTime.parse(dob);
      } catch (_) {}
    }

    DateTime parsedCreated = DateTime.now();
    if (createdAt.isNotEmpty) {
      try {
        parsedCreated = DateTime.parse(createdAt);
      } catch (_) {}
    }

    return Patient(
      id: id,
      uuid: uuid,
      uhid: uhid,
      name: name,
      gender: gender.isEmpty ? null : gender,
      dob: parsedDob,
      ageYears: ageYears > 0 ? ageYears : null,
      phone: phone.isEmpty ? null : phone,
      altPhone: altPhone.isEmpty ? null : altPhone,
      email: email.isEmpty ? null : email,
      address: address.isEmpty ? null : address,
      city: city.isEmpty ? null : city,
      state: state.isEmpty ? null : state,
      pincode: pincode.isEmpty ? null : pincode,
      bloodGroup: bloodGroup.isEmpty ? null : bloodGroup,
      emergencyContactName:
          emergencyContactName.isEmpty ? null : emergencyContactName,
      emergencyContactPhone:
          emergencyContactPhone.isEmpty ? null : emergencyContactPhone,
      idType: idType.isEmpty ? null : idType,
      idNumber: idNumber.isEmpty ? null : idNumber,
      photoPath: photoPath.isEmpty ? null : photoPath,
      isVip: isVip,
      notes: notes.isEmpty ? null : notes,
      createdAt: parsedCreated,
      isDeleted: isDeleted,
    );
  }

  factory PatientModel.fromDomain(Patient p) {
    return PatientModel(
      id: p.id,
      uuid: p.uuid,
      uhid: p.uhid,
      name: p.name,
      gender: p.gender ?? '',
      dob: p.dob?.toIso8601String().split('T').first ?? '',
      ageYears: p.ageYears ?? p.age,
      phone: p.phone ?? '',
      altPhone: p.altPhone ?? '',
      email: p.email ?? '',
      address: p.address ?? '',
      city: p.city ?? '',
      state: p.state ?? '',
      pincode: p.pincode ?? '',
      bloodGroup: p.bloodGroup ?? '',
      emergencyContactName: p.emergencyContactName ?? '',
      emergencyContactPhone: p.emergencyContactPhone ?? '',
      idType: p.idType ?? '',
      idNumber: p.idNumber ?? '',
      photoPath: p.photoPath ?? '',
      isVip: p.isVip,
      notes: p.notes ?? '',
      createdAt: p.createdAt.toIso8601String(),
      isDeleted: p.isDeleted,
    );
  }
}

/// Attached medical documents / scan files for patient records (PAT-09)
class PatientDocumentModel {
  final int id;
  final String uuid;
  final int patientId;
  final String uhid;
  final String title;
  final String docType; // lab_report, imaging, referral, id_proof, prescription, other
  final String fileUri;
  final int fileSizeBytes;
  final String mimeType;
  final String uploadedAt;

  const PatientDocumentModel({
    required this.id,
    required this.uuid,
    required this.patientId,
    required this.uhid,
    required this.title,
    required this.docType,
    required this.fileUri,
    this.fileSizeBytes = 0,
    this.mimeType = 'application/pdf',
    required this.uploadedAt,
  });

  factory PatientDocumentModel.fromMap(Map<String, dynamic> map) {
    return PatientDocumentModel(
      id: map['id'] as int? ?? 0,
      uuid: map['uuid'] as String? ?? '',
      patientId: map['patient_id'] as int? ?? 0,
      uhid: map['uhid'] as String? ?? '',
      title: map['title'] as String? ?? '',
      docType: map['doc_type'] as String? ?? 'other',
      fileUri: map['file_uri'] as String? ?? '',
      fileSizeBytes: map['file_size_bytes'] as int? ?? 0,
      mimeType: map['mime_type'] as String? ?? 'application/pdf',
      uploadedAt: map['uploaded_at'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        if (id > 0) 'id': id,
        'uuid': uuid,
        'patient_id': patientId,
        'uhid': uhid,
        'title': title,
        'doc_type': docType,
        'file_uri': fileUri,
        'file_size_bytes': fileSizeBytes,
        'mime_type': mimeType,
        'uploaded_at': uploadedAt,
      };

  String toJson() => jsonEncode(toMap());

  factory PatientDocumentModel.fromJson(String source) =>
      PatientDocumentModel.fromMap(jsonDecode(source) as Map<String, dynamic>);
}

/// Patient comprehensive timeline history event (PAT-05)
class PatientTimelineEventModel {
  final String eventType; // opd_visit | ipd_admission | lab_test | invoice | prescription
  final String title;
  final String date;
  final String summary;
  final String doctorOrDepartment;
  final String status;
  final String? refId;

  const PatientTimelineEventModel({
    required this.eventType,
    required this.title,
    required this.date,
    required this.summary,
    required this.doctorOrDepartment,
    required this.status,
    this.refId,
  });

  factory PatientTimelineEventModel.fromMap(Map<String, dynamic> map) {
    return PatientTimelineEventModel(
      eventType: map['event_type'] as String? ?? 'opd_visit',
      title: map['title'] as String? ?? '',
      date: map['date'] as String? ?? '',
      summary: map['summary'] as String? ?? '',
      doctorOrDepartment: map['doctor_or_dept'] as String? ?? '',
      status: map['status'] as String? ?? '',
      refId: map['ref_id'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'event_type': eventType,
        'title': title,
        'date': date,
        'summary': summary,
        'doctor_or_dept': doctorOrDepartment,
        'status': status,
        'ref_id': refId,
      };

  String toJson() => jsonEncode(toMap());

  factory PatientTimelineEventModel.fromJson(String source) =>
      PatientTimelineEventModel.fromMap(jsonDecode(source) as Map<String, dynamic>);
}

