import 'dart:convert';

/// Laboratory Order model for investigations, tests and pathology reports.
class LabOrderModel {
  final int id;
  final String orderNo;
  final String patientName;
  final String uhid;
  final String testName;
  final String doctorName;
  final String sampleType;
  final String priority;
  final String status;
  final String orderedAt;
  final List<Map<String, dynamic>> parameters;
  final int patientId;
  final int testId;
  final String sampleCollectedAt;
  final String resultDate;
  final String technicianNotes;
  final String createdAt;
  final String updatedAt;

  const LabOrderModel({
    required this.id,
    required this.orderNo,
    required this.patientName,
    required this.uhid,
    required this.testName,
    required this.doctorName,
    required this.sampleType,
    required this.priority,
    required this.status,
    required this.orderedAt,
    required this.parameters,
    this.patientId = 0,
    this.testId = 0,
    this.sampleCollectedAt = '',
    this.resultDate = '',
    this.technicianNotes = '',
    this.createdAt = '',
    this.updatedAt = '',
  });

  bool get isPendingCollection =>
      status.toLowerCase() == 'pending collection' ||
      status.toLowerCase() == 'pending';
  bool get isCollected => status.toLowerCase() == 'collected';
  bool get isProcessing => status.toLowerCase() == 'processing';
  bool get isResulted => status.toLowerCase() == 'resulted';
  bool get isVerified => status.toLowerCase() == 'verified';

  factory LabOrderModel.fromMap(Map<String, dynamic> map) {
    List<Map<String, dynamic>> parsedParams = [];
    final paramsJson = map['params_json'] as String?;
    if (paramsJson != null && paramsJson.isNotEmpty) {
      try {
        final list = jsonDecode(paramsJson) as List<dynamic>;
        parsedParams = list
            .map((e) => Map<String, dynamic>.from(e as Map<dynamic, dynamic>))
            .toList();
      } catch (_) {}
    }

    return LabOrderModel(
      id: map['id'] as int? ?? 0,
      orderNo: map['order_no'] as String? ?? '',
      patientName: map['patient_name'] as String? ?? '',
      uhid: map['uhid'] as String? ?? '',
      testName: map['test_name'] as String? ?? '',
      doctorName: map['doctor_name'] as String? ?? '',
      sampleType: map['sample_type'] as String? ?? 'Blood',
      priority: map['priority'] as String? ?? 'Routine',
      status: map['status'] as String? ?? 'Pending Collection',
      orderedAt: map['ordered_at'] as String? ?? '',
      parameters: parsedParams,
      patientId: map['patient_id'] as int? ?? 0,
      testId: map['test_id'] as int? ?? 0,
      sampleCollectedAt: map['sample_collected_at'] as String? ?? '',
      resultDate: map['result_date'] as String? ?? '',
      technicianNotes: map['technician_notes'] as String? ?? '',
      createdAt: map['created_at'] as String? ?? '',
      updatedAt: map['updated_at'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        if (id > 0) 'id': id,
        'order_no': orderNo,
        'patient_name': patientName,
        'uhid': uhid,
        'test_name': testName,
        'doctor_name': doctorName,
        'sample_type': sampleType,
        'priority': priority,
        'status': status,
        'ordered_at': orderedAt,
        'params_json': jsonEncode(parameters),
        'patient_id': patientId,
        'test_id': testId,
        'sample_collected_at': sampleCollectedAt,
        'result_date': resultDate,
        'technician_notes': technicianNotes,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  String toJson() => jsonEncode(toMap());

  factory LabOrderModel.fromJson(String source) =>
      LabOrderModel.fromMap(jsonDecode(source) as Map<String, dynamic>);

  LabOrderModel copyWith({
    int? id,
    String? orderNo,
    String? patientName,
    String? uhid,
    String? testName,
    String? doctorName,
    String? sampleType,
    String? priority,
    String? status,
    String? orderedAt,
    List<Map<String, dynamic>>? parameters,
    int? patientId,
    int? testId,
    String? sampleCollectedAt,
    String? resultDate,
    String? technicianNotes,
    String? createdAt,
    String? updatedAt,
  }) {
    return LabOrderModel(
      id: id ?? this.id,
      orderNo: orderNo ?? this.orderNo,
      patientName: patientName ?? this.patientName,
      uhid: uhid ?? this.uhid,
      testName: testName ?? this.testName,
      doctorName: doctorName ?? this.doctorName,
      sampleType: sampleType ?? this.sampleType,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      orderedAt: orderedAt ?? this.orderedAt,
      parameters: parameters ?? this.parameters,
      patientId: patientId ?? this.patientId,
      testId: testId ?? this.testId,
      sampleCollectedAt: sampleCollectedAt ?? this.sampleCollectedAt,
      resultDate: resultDate ?? this.resultDate,
      technicianNotes: technicianNotes ?? this.technicianNotes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LabOrderModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          orderNo == other.orderNo;

  @override
  int get hashCode => id.hashCode ^ orderNo.hashCode;

  @override
  String toString() =>
      'LabOrderModel(orderNo: $orderNo, test: $testName, patient: $patientName [$status])';
}

/// Master Lab Test catalogue item
class LabTestModel {
  final int id;
  final String uuid;
  final String name;
  final String category;
  final String sampleType;
  final int pricePaise;
  final int turnaroundHours;
  final bool isOutsourced;
  final String createdAt;
  final String updatedAt;

  const LabTestModel({
    required this.id,
    required this.uuid,
    required this.name,
    this.category = 'General',
    this.sampleType = 'Blood',
    this.pricePaise = 0,
    this.turnaroundHours = 24,
    this.isOutsourced = false,
    this.createdAt = '',
    this.updatedAt = '',
  });

  String get priceFormatted =>
      pricePaise > 0 ? '₹${(pricePaise / 100).toStringAsFixed(2)}' : 'Free';

  factory LabTestModel.fromMap(Map<String, dynamic> map) {
    return LabTestModel(
      id: map['id'] as int? ?? 0,
      uuid: map['uuid'] as String? ?? '',
      name: map['name'] as String? ?? '',
      category: map['category'] as String? ?? 'General',
      sampleType: map['sample_type'] as String? ?? 'Blood',
      pricePaise: map['price_paise'] as int? ?? 0,
      turnaroundHours: map['turnaround_hours'] as int? ?? 24,
      isOutsourced: (map['is_outsourced'] is int)
          ? (map['is_outsourced'] as int) == 1
          : (map['is_outsourced'] as bool? ?? false),
      createdAt: map['created_at'] as String? ?? '',
      updatedAt: map['updated_at'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        if (id > 0) 'id': id,
        'uuid': uuid,
        'name': name,
        'category': category,
        'sample_type': sampleType,
        'price_paise': pricePaise,
        'turnaround_hours': turnaroundHours,
        'is_outsourced': isOutsourced ? 1 : 0,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  String toJson() => jsonEncode(toMap());

  factory LabTestModel.fromJson(String source) =>
      LabTestModel.fromMap(jsonDecode(source) as Map<String, dynamic>);
}

/// Parameter within a Lab Test (e.g. Hemoglobin, RBC)
class LabTestParameterModel {
  final int id;
  final String uuid;
  final int testId;
  final String parameterName;
  final String unit;
  final double? rangeLow;
  final double? rangeHigh;
  final String? referenceText;

  const LabTestParameterModel({
    required this.id,
    required this.uuid,
    required this.testId,
    required this.parameterName,
    this.unit = '',
    this.rangeLow,
    this.rangeHigh,
    this.referenceText,
  });

  String get referenceRangeDisplay {
    if (referenceText != null && referenceText!.isNotEmpty) return referenceText!;
    if (rangeLow != null && rangeHigh != null) return '$rangeLow - $rangeHigh $unit';
    if (rangeLow != null) return '> $rangeLow $unit';
    if (rangeHigh != null) return '< $rangeHigh $unit';
    return '-';
  }

  factory LabTestParameterModel.fromMap(Map<String, dynamic> map) {
    return LabTestParameterModel(
      id: map['id'] as int? ?? 0,
      uuid: map['uuid'] as String? ?? '',
      testId: map['test_id'] as int? ?? 0,
      parameterName: map['parameter_name'] as String? ?? '',
      unit: map['unit'] as String? ?? '',
      rangeLow: (map['range_low'] as num?)?.toDouble(),
      rangeHigh: (map['range_high'] as num?)?.toDouble(),
      referenceText: map['reference_text'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        if (id > 0) 'id': id,
        'uuid': uuid,
        'test_id': testId,
        'parameter_name': parameterName,
        'unit': unit,
        'range_low': rangeLow,
        'range_high': rangeHigh,
        'reference_text': referenceText,
      };

  String toJson() => jsonEncode(toMap());

  factory LabTestParameterModel.fromJson(String source) =>
      LabTestParameterModel.fromMap(jsonDecode(source) as Map<String, dynamic>);
}

/// Package of multiple lab tests (e.g. Executive Health Check)
class LabPackageModel {
  final int id;
  final String uuid;
  final String name;
  final String description;
  final int pricePaise;
  final List<int> testIds;

  const LabPackageModel({
    required this.id,
    required this.uuid,
    required this.name,
    this.description = '',
    this.pricePaise = 0,
    this.testIds = const [],
  });

  String get priceFormatted =>
      pricePaise > 0 ? '₹${(pricePaise / 100).toStringAsFixed(2)}' : 'Free';

  factory LabPackageModel.fromMap(Map<String, dynamic> map) {
    List<int> tests = [];
    final testsJson = map['test_ids_json'] as String?;
    if (testsJson != null && testsJson.isNotEmpty) {
      try {
        final list = jsonDecode(testsJson) as List<dynamic>;
        tests = list.map((e) => e as int).toList();
      } catch (_) {}
    }

    return LabPackageModel(
      id: map['id'] as int? ?? 0,
      uuid: map['uuid'] as String? ?? '',
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      pricePaise: map['price_paise'] as int? ?? 0,
      testIds: tests,
    );
  }

  Map<String, dynamic> toMap() => {
        if (id > 0) 'id': id,
        'uuid': uuid,
        'name': name,
        'description': description,
        'price_paise': pricePaise,
        'test_ids_json': jsonEncode(testIds),
      };

  String toJson() => jsonEncode(toMap());

  factory LabPackageModel.fromJson(String source) =>
      LabPackageModel.fromMap(jsonDecode(source) as Map<String, dynamic>);
}

/// Specific test result value for a single parameter
class LabParameterResultModel {
  final String parameterName;
  final String value;
  final String unit;
  final String referenceRange;
  final bool isAbnormal;
  final String flag; // Normal, High, Low, Critical

  const LabParameterResultModel({
    required this.parameterName,
    required this.value,
    this.unit = '',
    this.referenceRange = '',
    this.isAbnormal = false,
    this.flag = 'Normal',
  });

  factory LabParameterResultModel.fromMap(Map<String, dynamic> map) {
    return LabParameterResultModel(
      parameterName: map['name'] ?? map['parameter_name'] ?? '',
      value: map['value']?.toString() ?? '',
      unit: map['unit']?.toString() ?? '',
      referenceRange: map['ref'] ?? map['reference_range'] ?? '',
      isAbnormal: map['is_abnormal'] as bool? ?? false,
      flag: map['flag'] as String? ?? 'Normal',
    );
  }

  Map<String, dynamic> toMap() => {
        'name': parameterName,
        'value': value,
        'unit': unit,
        'ref': referenceRange,
        'is_abnormal': isAbnormal,
        'flag': flag,
      };

  String toJson() => jsonEncode(toMap());

  factory LabParameterResultModel.fromJson(String source) =>
      LabParameterResultModel.fromMap(jsonDecode(source) as Map<String, dynamic>);
}

