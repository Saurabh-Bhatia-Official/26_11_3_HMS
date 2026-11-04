import 'dart:convert';

/// System Configuration Setting key-value model
class SettingModel {
  final int id;
  final String key;
  final String value;
  final String updatedAt;

  const SettingModel({
    required this.id,
    required this.key,
    required this.value,
    this.updatedAt = '',
  });

  factory SettingModel.fromMap(Map<String, dynamic> map) {
    return SettingModel(
      id: map['id'] as int? ?? 0,
      key: map['key'] as String? ?? '',
      value: map['value'] as String? ?? '',
      updatedAt: map['updated_at'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        if (id > 0) 'id': id,
        'key': key,
        'value': value,
        'updated_at': updatedAt,
      };

  String toJson() => jsonEncode(toMap());

  factory SettingModel.fromJson(String source) =>
      SettingModel.fromMap(jsonDecode(source) as Map<String, dynamic>);
}

/// Hospital Organization Profile model
class HospitalProfileModel {
  final String hospitalName;
  final String tagline;
  final String address;
  final String phone;
  final String email;
  final String taxId;
  final String currencySymbol;
  final String logoPath;
  final String uhidPrefix;

  const HospitalProfileModel({
    this.hospitalName = 'CareSync',
    this.tagline = 'Connecting Care. Simplifying Healthcare.',
    this.address = '',
    this.phone = '',
    this.email = '',
    this.taxId = '',
    this.currencySymbol = '₹',
    this.logoPath = 'assets/images/caresync_logo.png',
    this.uhidPrefix = 'UHID',
  });

  factory HospitalProfileModel.fromMap(Map<String, dynamic> map) {
    return HospitalProfileModel(
      hospitalName: map['hospital_name'] as String? ?? 'CareSync',
      tagline: map['tagline'] as String? ?? 'Connecting Care. Simplifying Healthcare.',
      address: map['address'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      email: map['email'] as String? ?? '',
      taxId: map['tax_id'] as String? ?? '',
      currencySymbol: map['currency_symbol'] as String? ?? '₹',
      logoPath: map['logo_path'] as String? ?? '',
      uhidPrefix: map['uhid_prefix'] as String? ?? 'UHID',
    );
  }

  Map<String, dynamic> toMap() => {
        'hospital_name': hospitalName,
        'tagline': tagline,
        'address': address,
        'phone': phone,
        'email': email,
        'tax_id': taxId,
        'currency_symbol': currencySymbol,
        'logo_path': logoPath,
        'uhid_prefix': uhidPrefix,
      };

  String toJson() => jsonEncode(toMap());

  factory HospitalProfileModel.fromJson(String source) =>
      HospitalProfileModel.fromMap(jsonDecode(source) as Map<String, dynamic>);
}

