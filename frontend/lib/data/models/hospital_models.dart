import 'dart:convert';

/// Typed representation of a hospital branch / entity managed in CareSync.
class HospitalModel {
  final int id;
  final String uuid;
  final String name;
  final String code;
  final String type;
  final String address;
  final String phone;
  final String email;
  final String taxId;
  final String status;
  final String createdAt;

  const HospitalModel({
    this.id = 0,
    required this.uuid,
    required this.name,
    required this.code,
    required this.type,
    this.address = '',
    this.phone = '',
    this.email = '',
    this.taxId = '',
    this.status = 'Active',
    this.createdAt = '',
  });

  HospitalModel copyWith({
    int? id,
    String? uuid,
    String? name,
    String? code,
    String? type,
    String? address,
    String? phone,
    String? email,
    String? taxId,
    String? status,
    String? createdAt,
  }) {
    return HospitalModel(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      name: name ?? this.name,
      code: code ?? this.code,
      type: type ?? this.type,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      taxId: taxId ?? this.taxId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory HospitalModel.fromMap(Map<String, dynamic> map) {
    return HospitalModel(
      id: map['id'] as int? ?? 0,
      uuid: map['uuid'] as String? ?? '',
      name: map['name'] as String? ?? '',
      code: map['code'] as String? ?? '',
      type: map['type'] as String? ?? 'Multispeciality Hospital',
      address: map['address'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      email: map['email'] as String? ?? '',
      taxId: map['tax_id'] as String? ?? '',
      status: map['status'] as String? ?? 'Active',
      createdAt: map['created_at'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'uuid': uuid,
      'name': name,
      'code': code,
      'type': type,
      'address': address,
      'phone': phone,
      'email': email,
      'tax_id': taxId,
      'status': status,
      'created_at': createdAt,
    };
  }

  String toJson() => jsonEncode(toMap());

  factory HospitalModel.fromJson(String source) =>
      HospitalModel.fromMap(jsonDecode(source) as Map<String, dynamic>);
}

