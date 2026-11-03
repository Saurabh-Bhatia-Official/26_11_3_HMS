import 'dart:convert';

/// Single medicine item within a prescription.
class PrescriptionItemModel {
  final int id;
  final String uuid;
  final int prescriptionId;
  final int medicineId;
  final String medicineName;
  final String dose;
  final String frequency; // e.g. "1-0-1", "TDS", "SOS"
  final String duration;  // e.g. "5 days"
  final String route;     // e.g. "Oral", "IV", "Topical"
  final String instructions; // e.g. "After meals"
  final int qtyPrescribed;

  const PrescriptionItemModel({
    required this.id,
    required this.uuid,
    required this.prescriptionId,
    required this.medicineId,
    required this.medicineName,
    this.dose = '',
    this.frequency = '',
    this.duration = '',
    this.route = 'Oral',
    this.instructions = '',
    this.qtyPrescribed = 0,
  });

  String get summary =>
      '$medicineName ($dose) — $frequency for $duration [$instructions]';

  factory PrescriptionItemModel.fromMap(Map<String, dynamic> map) {
    return PrescriptionItemModel(
      id: map['id'] as int? ?? 0,
      uuid: map['uuid'] as String? ?? '',
      prescriptionId: map['prescription_id'] as int? ?? 0,
      medicineId: map['medicine_id'] as int? ?? 0,
      medicineName: (map['medicine_name'] ?? map['name']) as String? ?? '',
      dose: (map['dose'] ?? map['dosage']) as String? ?? '',
      frequency: map['frequency'] as String? ?? '',
      duration: map['duration'] as String? ?? '',
      route: map['route'] as String? ?? 'Oral',
      instructions: map['instructions'] as String? ?? '',
      qtyPrescribed: (map['qty_prescribed'] ?? map['qty']) as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
        if (id > 0) 'id': id,
        'uuid': uuid,
        'prescription_id': prescriptionId,
        'medicine_id': medicineId,
        'medicine_name': medicineName,
        'dose': dose,
        'frequency': frequency,
        'duration': duration,
        'route': route,
        'instructions': instructions,
        'qty_prescribed': qtyPrescribed,
      };

  String toJson() => jsonEncode(toMap());

  factory PrescriptionItemModel.fromJson(String source) =>
      PrescriptionItemModel.fromMap(jsonDecode(source) as Map<String, dynamic>);
}

/// Clinical Prescription document model
class PrescriptionModel {
  final int id;
  final String uuid;
  final int visitId;
  final int doctorId;
  final String doctorName;
  final String patientName;
  final String uhid;
  final String prescribedAt;
  final String notes;
  final String status; // active, dispensed, cancelled
  final List<PrescriptionItemModel> items;

  const PrescriptionModel({
    required this.id,
    required this.uuid,
    required this.visitId,
    required this.doctorId,
    this.doctorName = '',
    required this.patientName,
    required this.uhid,
    required this.prescribedAt,
    this.notes = '',
    this.status = 'active',
    this.items = const [],
  });

  bool get isActive => status.toLowerCase() == 'active';
  bool get isDispensed => status.toLowerCase() == 'dispensed';

  factory PrescriptionModel.fromMap(Map<String, dynamic> map) {
    List<PrescriptionItemModel> parsedItems = [];
    final raw = map['items'];
    if (raw is List) {
      parsedItems = raw.map((e) => PrescriptionItemModel.fromMap(e as Map<String, dynamic>)).toList();
    } else if (map['items_json'] is String) {
      try {
        final list = jsonDecode(map['items_json'] as String) as List<dynamic>;
        parsedItems = list.map((e) => PrescriptionItemModel.fromMap(e as Map<String, dynamic>)).toList();
      } catch (_) {}
    }

    return PrescriptionModel(
      id: map['id'] as int? ?? 0,
      uuid: map['uuid'] as String? ?? '',
      visitId: map['visit_id'] as int? ?? 0,
      doctorId: map['doctor_id'] as int? ?? 0,
      doctorName: map['doctor_name'] as String? ?? '',
      patientName: map['patient_name'] as String? ?? '',
      uhid: map['uhid'] as String? ?? '',
      prescribedAt: map['prescribed_at'] as String? ?? '',
      notes: map['notes'] as String? ?? '',
      status: map['status'] as String? ?? 'active',
      items: parsedItems,
    );
  }

  Map<String, dynamic> toMap() => {
        if (id > 0) 'id': id,
        'uuid': uuid,
        'visit_id': visitId,
        'doctor_id': doctorId,
        'doctor_name': doctorName,
        'patient_name': patientName,
        'uhid': uhid,
        'prescribed_at': prescribedAt,
        'notes': notes,
        'status': status,
        'items': items.map((e) => e.toMap()).toList(),
      };

  String toJson() => jsonEncode(toMap());

  factory PrescriptionModel.fromJson(String source) =>
      PrescriptionModel.fromMap(jsonDecode(source) as Map<String, dynamic>);
}

/// Doctor quick prescription template model (e.g. "Fever & Cold standard Rx")
class PrescriptionTemplateModel {
  final int id;
  final String uuid;
  final int doctorId;
  final String name;
  final List<Map<String, String>> items;

  const PrescriptionTemplateModel({
    required this.id,
    required this.uuid,
    required this.doctorId,
    required this.name,
    this.items = const [],
  });

  factory PrescriptionTemplateModel.fromMap(Map<String, dynamic> map) {
    List<Map<String, String>> parsed = [];
    if (map['items_json'] is String) {
      try {
        final list = jsonDecode(map['items_json'] as String) as List<dynamic>;
        parsed = list.map((e) => Map<String, String>.from(e as Map)).toList();
      } catch (_) {}
    }
    return PrescriptionTemplateModel(
      id: map['id'] as int? ?? 0,
      uuid: map['uuid'] as String? ?? '',
      doctorId: map['doctor_id'] as int? ?? 0,
      name: map['name'] as String? ?? '',
      items: parsed,
    );
  }

  Map<String, dynamic> toMap() => {
        if (id > 0) 'id': id,
        'uuid': uuid,
        'doctor_id': doctorId,
        'name': name,
        'items_json': jsonEncode(items),
      };

  String toJson() => jsonEncode(toMap());

  factory PrescriptionTemplateModel.fromJson(String source) =>
      PrescriptionTemplateModel.fromMap(jsonDecode(source) as Map<String, dynamic>);
}

