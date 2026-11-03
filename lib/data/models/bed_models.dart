import 'dart:convert';

/// Bed record model representing hospital beds and occupancy status.
class BedModel {
  final int id;
  final String bedNo;
  final String ward;
  final String type;
  final int tariffPaise;
  final String status;
  final String? patientName;
  final String? uhid;
  final int roomId;
  final int wardId;
  final String roomNo;
  final int floor;
  final String createdAt;
  final String updatedAt;

  const BedModel({
    required this.id,
    required this.bedNo,
    required this.ward,
    required this.type,
    required this.tariffPaise,
    required this.status,
    this.patientName,
    this.uhid,
    this.roomId = 0,
    this.wardId = 0,
    this.roomNo = '',
    this.floor = 0,
    this.createdAt = '',
    this.updatedAt = '',
  });

  String get tariffFormatted =>
      tariffPaise > 0 ? '₹${(tariffPaise / 100).toStringAsFixed(0)}/day' : 'Free';

  bool get isAvailable => status.toLowerCase() == 'available';
  bool get isOccupied => status.toLowerCase() == 'occupied';
  bool get isCleaning => status.toLowerCase() == 'cleaning';
  bool get isMaintenance => status.toLowerCase() == 'maintenance';

  factory BedModel.fromMap(Map<String, dynamic> map) {
    return BedModel(
      id: map['id'] as int? ?? 0,
      bedNo: map['bed_no'] as String? ?? '',
      ward: map['ward'] as String? ?? '',
      type: (map['bed_type'] ?? map['type']) as String? ?? 'general',
      tariffPaise: (map['tariff_paise'] ?? map['daily_tariff_paise']) as int? ?? 0,
      status: map['status'] as String? ?? 'available',
      patientName: map['patient_name'] as String?,
      uhid: map['uhid'] as String?,
      roomId: map['room_id'] as int? ?? 0,
      wardId: map['ward_id'] as int? ?? 0,
      roomNo: map['room_no'] as String? ?? '',
      floor: map['floor'] as int? ?? 0,
      createdAt: map['created_at'] as String? ?? '',
      updatedAt: map['updated_at'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        if (id > 0) 'id': id,
        'bed_no': bedNo,
        'ward': ward,
        'bed_type': type,
        'tariff_paise': tariffPaise,
        'status': status,
        'patient_name': patientName,
        'uhid': uhid,
        'room_id': roomId,
        'ward_id': wardId,
        'room_no': roomNo,
        'floor': floor,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  String toJson() => jsonEncode(toMap());

  factory BedModel.fromJson(String source) =>
      BedModel.fromMap(jsonDecode(source) as Map<String, dynamic>);

  BedModel copyWith({
    int? id,
    String? bedNo,
    String? ward,
    String? type,
    int? tariffPaise,
    String? status,
    String? patientName,
    String? uhid,
    int? roomId,
    int? wardId,
    String? roomNo,
    int? floor,
    String? createdAt,
    String? updatedAt,
    bool clearPatient = false,
  }) {
    return BedModel(
      id: id ?? this.id,
      bedNo: bedNo ?? this.bedNo,
      ward: ward ?? this.ward,
      type: type ?? this.type,
      tariffPaise: tariffPaise ?? this.tariffPaise,
      status: status ?? this.status,
      patientName: clearPatient ? null : (patientName ?? this.patientName),
      uhid: clearPatient ? null : (uhid ?? this.uhid),
      roomId: roomId ?? this.roomId,
      wardId: wardId ?? this.wardId,
      roomNo: roomNo ?? this.roomNo,
      floor: floor ?? this.floor,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BedModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          bedNo == other.bedNo &&
          ward == other.ward;

  @override
  int get hashCode => id.hashCode ^ bedNo.hashCode ^ ward.hashCode;

  @override
  String toString() => 'BedModel(bedNo: $bedNo, ward: $ward, status: $status)';
}

/// Hospital Ward model
class WardModel {
  final int id;
  final String uuid;
  final String name;
  final String description;
  final bool isActive;
  final int totalBeds;
  final int occupiedBeds;
  final String createdAt;
  final String updatedAt;

  const WardModel({
    required this.id,
    required this.uuid,
    required this.name,
    this.description = '',
    this.isActive = true,
    this.totalBeds = 0,
    this.occupiedBeds = 0,
    this.createdAt = '',
    this.updatedAt = '',
  });

  int get availableBeds => (totalBeds - occupiedBeds).clamp(0, totalBeds);
  double get occupancyRate =>
      totalBeds > 0 ? (occupiedBeds / totalBeds) * 100 : 0.0;

  factory WardModel.fromMap(Map<String, dynamic> map) {
    return WardModel(
      id: map['id'] as int? ?? 0,
      uuid: map['uuid'] as String? ?? '',
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      isActive: (map['is_active'] is int)
          ? (map['is_active'] as int) == 1
          : (map['is_active'] as bool? ?? true),
      totalBeds: map['total_beds'] as int? ?? 0,
      occupiedBeds: map['occupied_beds'] as int? ?? 0,
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
        'total_beds': totalBeds,
        'occupied_beds': occupiedBeds,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  String toJson() => jsonEncode(toMap());

  factory WardModel.fromJson(String source) =>
      WardModel.fromMap(jsonDecode(source) as Map<String, dynamic>);

  WardModel copyWith({
    int? id,
    String? uuid,
    String? name,
    String? description,
    bool? isActive,
    int? totalBeds,
    int? occupiedBeds,
    String? createdAt,
    String? updatedAt,
  }) {
    return WardModel(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      name: name ?? this.name,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      totalBeds: totalBeds ?? this.totalBeds,
      occupiedBeds: occupiedBeds ?? this.occupiedBeds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WardModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name;

  @override
  int get hashCode => id.hashCode ^ name.hashCode;

  @override
  String toString() => 'WardModel(name: $name, beds: $occupiedBeds/$totalBeds)';
}

/// Room within a ward
class RoomModel {
  final int id;
  final String uuid;
  final int wardId;
  final String wardName;
  final String roomNo;
  final int floor;
  final bool isActive;
  final String createdAt;
  final String updatedAt;

  const RoomModel({
    required this.id,
    required this.uuid,
    required this.wardId,
    this.wardName = '',
    required this.roomNo,
    this.floor = 0,
    this.isActive = true,
    this.createdAt = '',
    this.updatedAt = '',
  });

  factory RoomModel.fromMap(Map<String, dynamic> map) {
    return RoomModel(
      id: map['id'] as int? ?? 0,
      uuid: map['uuid'] as String? ?? '',
      wardId: map['ward_id'] as int? ?? 0,
      wardName: map['ward_name'] as String? ?? '',
      roomNo: map['room_no'] as String? ?? '',
      floor: map['floor'] as int? ?? 0,
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
        'ward_id': wardId,
        'ward_name': wardName,
        'room_no': roomNo,
        'floor': floor,
        'is_active': isActive ? 1 : 0,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  String toJson() => jsonEncode(toMap());

  factory RoomModel.fromJson(String source) =>
      RoomModel.fromMap(jsonDecode(source) as Map<String, dynamic>);

  RoomModel copyWith({
    int? id,
    String? uuid,
    int? wardId,
    String? wardName,
    String? roomNo,
    int? floor,
    bool? isActive,
    String? createdAt,
    String? updatedAt,
  }) {
    return RoomModel(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      wardId: wardId ?? this.wardId,
      wardName: wardName ?? this.wardName,
      roomNo: roomNo ?? this.roomNo,
      floor: floor ?? this.floor,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RoomModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          roomNo == other.roomNo;

  @override
  int get hashCode => id.hashCode ^ roomNo.hashCode;

  @override
  String toString() => 'RoomModel(roomNo: $roomNo, ward: $wardName)';
}

/// Bed transfer event audit model
class BedTransferModel {
  final int id;
  final String uuid;
  final int admissionId;
  final String fromBedNo;
  final String toBedNo;
  final String transferredAt;
  final String reason;
  final String transferredBy;

  const BedTransferModel({
    required this.id,
    required this.uuid,
    required this.admissionId,
    required this.fromBedNo,
    required this.toBedNo,
    required this.transferredAt,
    this.reason = '',
    this.transferredBy = '',
  });

  factory BedTransferModel.fromMap(Map<String, dynamic> map) {
    return BedTransferModel(
      id: map['id'] as int? ?? 0,
      uuid: map['uuid'] as String? ?? '',
      admissionId: map['admission_id'] as int? ?? 0,
      fromBedNo: map['from_bed_no'] as String? ?? '',
      toBedNo: map['to_bed_no'] as String? ?? '',
      transferredAt: map['transferred_at'] as String? ?? '',
      reason: map['reason'] as String? ?? '',
      transferredBy: map['transferred_by'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        if (id > 0) 'id': id,
        'uuid': uuid,
        'admission_id': admissionId,
        'from_bed_no': fromBedNo,
        'to_bed_no': toBedNo,
        'transferred_at': transferredAt,
        'reason': reason,
        'transferred_by': transferredBy,
      };

  String toJson() => jsonEncode(toMap());

  factory BedTransferModel.fromJson(String source) =>
      BedTransferModel.fromMap(jsonDecode(source) as Map<String, dynamic>);

  BedTransferModel copyWith({
    int? id,
    String? uuid,
    int? admissionId,
    String? fromBedNo,
    String? toBedNo,
    String? transferredAt,
    String? reason,
    String? transferredBy,
  }) {
    return BedTransferModel(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      admissionId: admissionId ?? this.admissionId,
      fromBedNo: fromBedNo ?? this.fromBedNo,
      toBedNo: toBedNo ?? this.toBedNo,
      transferredAt: transferredAt ?? this.transferredAt,
      reason: reason ?? this.reason,
      transferredBy: transferredBy ?? this.transferredBy,
    );
  }

  @override
  String toString() => 'BedTransfer($fromBedNo -> $toBedNo at $transferredAt)';
}

