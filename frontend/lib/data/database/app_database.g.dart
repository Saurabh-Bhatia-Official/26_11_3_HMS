// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $PatientsTable extends Patients
    with TableInfo<$PatientsTable, PatientRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PatientsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  @override
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
      'uuid', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 36, maxTextLength: 36),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _uhidMeta = const VerificationMeta('uhid');
  @override
  late final GeneratedColumn<String> uhid = GeneratedColumn<String>(
      'uhid', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 30),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 200),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _genderMeta = const VerificationMeta('gender');
  @override
  late final GeneratedColumn<String> gender = GeneratedColumn<String>(
      'gender', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _dobMeta = const VerificationMeta('dob');
  @override
  late final GeneratedColumn<String> dob = GeneratedColumn<String>(
      'dob', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _ageYearsMeta =
      const VerificationMeta('ageYears');
  @override
  late final GeneratedColumn<int> ageYears = GeneratedColumn<int>(
      'age_years', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
      'phone', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _altPhoneMeta =
      const VerificationMeta('altPhone');
  @override
  late final GeneratedColumn<String> altPhone = GeneratedColumn<String>(
      'alt_phone', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
      'email', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _addressMeta =
      const VerificationMeta('address');
  @override
  late final GeneratedColumn<String> address = GeneratedColumn<String>(
      'address', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _cityMeta = const VerificationMeta('city');
  @override
  late final GeneratedColumn<String> city = GeneratedColumn<String>(
      'city', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  @override
  late final GeneratedColumn<String> state = GeneratedColumn<String>(
      'state', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _pincodeMeta =
      const VerificationMeta('pincode');
  @override
  late final GeneratedColumn<String> pincode = GeneratedColumn<String>(
      'pincode', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _bloodGroupMeta =
      const VerificationMeta('bloodGroup');
  @override
  late final GeneratedColumn<String> bloodGroup = GeneratedColumn<String>(
      'blood_group', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _emergencyContactNameMeta =
      const VerificationMeta('emergencyContactName');
  @override
  late final GeneratedColumn<String> emergencyContactName =
      GeneratedColumn<String>('emergency_contact_name', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _emergencyContactPhoneMeta =
      const VerificationMeta('emergencyContactPhone');
  @override
  late final GeneratedColumn<String> emergencyContactPhone =
      GeneratedColumn<String>('emergency_contact_phone', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _idTypeMeta = const VerificationMeta('idType');
  @override
  late final GeneratedColumn<String> idType = GeneratedColumn<String>(
      'id_type', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _idNumberMeta =
      const VerificationMeta('idNumber');
  @override
  late final GeneratedColumn<String> idNumber = GeneratedColumn<String>(
      'id_number', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _photoPathMeta =
      const VerificationMeta('photoPath');
  @override
  late final GeneratedColumn<String> photoPath = GeneratedColumn<String>(
      'photo_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isVipMeta = const VerificationMeta('isVip');
  @override
  late final GeneratedColumn<bool> isVip = GeneratedColumn<bool>(
      'is_vip', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_vip" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
      'created_at', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdByMeta =
      const VerificationMeta('createdBy');
  @override
  late final GeneratedColumn<int> createdBy = GeneratedColumn<int>(
      'created_by', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _updatedByMeta =
      const VerificationMeta('updatedBy');
  @override
  late final GeneratedColumn<int> updatedBy = GeneratedColumn<int>(
      'updated_by', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _isDeletedMeta =
      const VerificationMeta('isDeleted');
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
      'is_deleted', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_deleted" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        uuid,
        uhid,
        name,
        gender,
        dob,
        ageYears,
        phone,
        altPhone,
        email,
        address,
        city,
        state,
        pincode,
        bloodGroup,
        emergencyContactName,
        emergencyContactPhone,
        idType,
        idNumber,
        photoPath,
        isVip,
        notes,
        createdAt,
        updatedAt,
        createdBy,
        updatedBy,
        isDeleted
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'patients';
  @override
  VerificationContext validateIntegrity(Insertable<PatientRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('uuid')) {
      context.handle(
          _uuidMeta, uuid.isAcceptableOrUnknown(data['uuid']!, _uuidMeta));
    } else if (isInserting) {
      context.missing(_uuidMeta);
    }
    if (data.containsKey('uhid')) {
      context.handle(
          _uhidMeta, uhid.isAcceptableOrUnknown(data['uhid']!, _uhidMeta));
    } else if (isInserting) {
      context.missing(_uhidMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('gender')) {
      context.handle(_genderMeta,
          gender.isAcceptableOrUnknown(data['gender']!, _genderMeta));
    }
    if (data.containsKey('dob')) {
      context.handle(
          _dobMeta, dob.isAcceptableOrUnknown(data['dob']!, _dobMeta));
    }
    if (data.containsKey('age_years')) {
      context.handle(_ageYearsMeta,
          ageYears.isAcceptableOrUnknown(data['age_years']!, _ageYearsMeta));
    }
    if (data.containsKey('phone')) {
      context.handle(
          _phoneMeta, phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta));
    }
    if (data.containsKey('alt_phone')) {
      context.handle(_altPhoneMeta,
          altPhone.isAcceptableOrUnknown(data['alt_phone']!, _altPhoneMeta));
    }
    if (data.containsKey('email')) {
      context.handle(
          _emailMeta, email.isAcceptableOrUnknown(data['email']!, _emailMeta));
    }
    if (data.containsKey('address')) {
      context.handle(_addressMeta,
          address.isAcceptableOrUnknown(data['address']!, _addressMeta));
    }
    if (data.containsKey('city')) {
      context.handle(
          _cityMeta, city.isAcceptableOrUnknown(data['city']!, _cityMeta));
    }
    if (data.containsKey('state')) {
      context.handle(
          _stateMeta, state.isAcceptableOrUnknown(data['state']!, _stateMeta));
    }
    if (data.containsKey('pincode')) {
      context.handle(_pincodeMeta,
          pincode.isAcceptableOrUnknown(data['pincode']!, _pincodeMeta));
    }
    if (data.containsKey('blood_group')) {
      context.handle(
          _bloodGroupMeta,
          bloodGroup.isAcceptableOrUnknown(
              data['blood_group']!, _bloodGroupMeta));
    }
    if (data.containsKey('emergency_contact_name')) {
      context.handle(
          _emergencyContactNameMeta,
          emergencyContactName.isAcceptableOrUnknown(
              data['emergency_contact_name']!, _emergencyContactNameMeta));
    }
    if (data.containsKey('emergency_contact_phone')) {
      context.handle(
          _emergencyContactPhoneMeta,
          emergencyContactPhone.isAcceptableOrUnknown(
              data['emergency_contact_phone']!, _emergencyContactPhoneMeta));
    }
    if (data.containsKey('id_type')) {
      context.handle(_idTypeMeta,
          idType.isAcceptableOrUnknown(data['id_type']!, _idTypeMeta));
    }
    if (data.containsKey('id_number')) {
      context.handle(_idNumberMeta,
          idNumber.isAcceptableOrUnknown(data['id_number']!, _idNumberMeta));
    }
    if (data.containsKey('photo_path')) {
      context.handle(_photoPathMeta,
          photoPath.isAcceptableOrUnknown(data['photo_path']!, _photoPathMeta));
    }
    if (data.containsKey('is_vip')) {
      context.handle(
          _isVipMeta, isVip.isAcceptableOrUnknown(data['is_vip']!, _isVipMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('created_by')) {
      context.handle(_createdByMeta,
          createdBy.isAcceptableOrUnknown(data['created_by']!, _createdByMeta));
    }
    if (data.containsKey('updated_by')) {
      context.handle(_updatedByMeta,
          updatedBy.isAcceptableOrUnknown(data['updated_by']!, _updatedByMeta));
    }
    if (data.containsKey('is_deleted')) {
      context.handle(_isDeletedMeta,
          isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PatientRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PatientRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      uuid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}uuid'])!,
      uhid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}uhid'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      gender: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}gender']),
      dob: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}dob']),
      ageYears: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}age_years']),
      phone: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}phone']),
      altPhone: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}alt_phone']),
      email: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}email']),
      address: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}address']),
      city: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}city']),
      state: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}state']),
      pincode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}pincode']),
      bloodGroup: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}blood_group']),
      emergencyContactName: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}emergency_contact_name']),
      emergencyContactPhone: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}emergency_contact_phone']),
      idType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id_type']),
      idNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id_number']),
      photoPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}photo_path']),
      isVip: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_vip'])!,
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}updated_at'])!,
      createdBy: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_by']),
      updatedBy: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}updated_by']),
      isDeleted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_deleted'])!,
    );
  }

  @override
  $PatientsTable createAlias(String alias) {
    return $PatientsTable(attachedDatabase, alias);
  }
}

class PatientRow extends DataClass implements Insertable<PatientRow> {
  final int id;
  final String uuid;
  final String uhid;
  final String name;

  /// "Male" | "Female" | "Other"
  final String? gender;

  /// ISO-8601 date string, e.g. "1990-05-15"
  final String? dob;
  final int? ageYears;
  final String? phone;
  final String? altPhone;
  final String? email;
  final String? address;
  final String? city;
  final String? state;
  final String? pincode;

  /// "A+" | "A-" | "B+" | "B-" | "O+" | "O-" | "AB+" | "AB-"
  final String? bloodGroup;
  final String? emergencyContactName;
  final String? emergencyContactPhone;

  /// "Aadhaar" | "PAN" | "Passport" | "DL" | "Other"
  final String? idType;
  final String? idNumber;

  /// Absolute on-device path to the patient photo file.
  final String? photoPath;
  final bool isVip;
  final String? notes;

  /// ISO-8601 timestamp
  final String createdAt;
  final String updatedAt;

  /// FK → users.id (nullable until auth is wired)
  final int? createdBy;
  final int? updatedBy;
  final bool isDeleted;
  const PatientRow(
      {required this.id,
      required this.uuid,
      required this.uhid,
      required this.name,
      this.gender,
      this.dob,
      this.ageYears,
      this.phone,
      this.altPhone,
      this.email,
      this.address,
      this.city,
      this.state,
      this.pincode,
      this.bloodGroup,
      this.emergencyContactName,
      this.emergencyContactPhone,
      this.idType,
      this.idNumber,
      this.photoPath,
      required this.isVip,
      this.notes,
      required this.createdAt,
      required this.updatedAt,
      this.createdBy,
      this.updatedBy,
      required this.isDeleted});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['uuid'] = Variable<String>(uuid);
    map['uhid'] = Variable<String>(uhid);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || gender != null) {
      map['gender'] = Variable<String>(gender);
    }
    if (!nullToAbsent || dob != null) {
      map['dob'] = Variable<String>(dob);
    }
    if (!nullToAbsent || ageYears != null) {
      map['age_years'] = Variable<int>(ageYears);
    }
    if (!nullToAbsent || phone != null) {
      map['phone'] = Variable<String>(phone);
    }
    if (!nullToAbsent || altPhone != null) {
      map['alt_phone'] = Variable<String>(altPhone);
    }
    if (!nullToAbsent || email != null) {
      map['email'] = Variable<String>(email);
    }
    if (!nullToAbsent || address != null) {
      map['address'] = Variable<String>(address);
    }
    if (!nullToAbsent || city != null) {
      map['city'] = Variable<String>(city);
    }
    if (!nullToAbsent || state != null) {
      map['state'] = Variable<String>(state);
    }
    if (!nullToAbsent || pincode != null) {
      map['pincode'] = Variable<String>(pincode);
    }
    if (!nullToAbsent || bloodGroup != null) {
      map['blood_group'] = Variable<String>(bloodGroup);
    }
    if (!nullToAbsent || emergencyContactName != null) {
      map['emergency_contact_name'] = Variable<String>(emergencyContactName);
    }
    if (!nullToAbsent || emergencyContactPhone != null) {
      map['emergency_contact_phone'] = Variable<String>(emergencyContactPhone);
    }
    if (!nullToAbsent || idType != null) {
      map['id_type'] = Variable<String>(idType);
    }
    if (!nullToAbsent || idNumber != null) {
      map['id_number'] = Variable<String>(idNumber);
    }
    if (!nullToAbsent || photoPath != null) {
      map['photo_path'] = Variable<String>(photoPath);
    }
    map['is_vip'] = Variable<bool>(isVip);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['created_at'] = Variable<String>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    if (!nullToAbsent || createdBy != null) {
      map['created_by'] = Variable<int>(createdBy);
    }
    if (!nullToAbsent || updatedBy != null) {
      map['updated_by'] = Variable<int>(updatedBy);
    }
    map['is_deleted'] = Variable<bool>(isDeleted);
    return map;
  }

  PatientsCompanion toCompanion(bool nullToAbsent) {
    return PatientsCompanion(
      id: Value(id),
      uuid: Value(uuid),
      uhid: Value(uhid),
      name: Value(name),
      gender:
          gender == null && nullToAbsent ? const Value.absent() : Value(gender),
      dob: dob == null && nullToAbsent ? const Value.absent() : Value(dob),
      ageYears: ageYears == null && nullToAbsent
          ? const Value.absent()
          : Value(ageYears),
      phone:
          phone == null && nullToAbsent ? const Value.absent() : Value(phone),
      altPhone: altPhone == null && nullToAbsent
          ? const Value.absent()
          : Value(altPhone),
      email:
          email == null && nullToAbsent ? const Value.absent() : Value(email),
      address: address == null && nullToAbsent
          ? const Value.absent()
          : Value(address),
      city: city == null && nullToAbsent ? const Value.absent() : Value(city),
      state:
          state == null && nullToAbsent ? const Value.absent() : Value(state),
      pincode: pincode == null && nullToAbsent
          ? const Value.absent()
          : Value(pincode),
      bloodGroup: bloodGroup == null && nullToAbsent
          ? const Value.absent()
          : Value(bloodGroup),
      emergencyContactName: emergencyContactName == null && nullToAbsent
          ? const Value.absent()
          : Value(emergencyContactName),
      emergencyContactPhone: emergencyContactPhone == null && nullToAbsent
          ? const Value.absent()
          : Value(emergencyContactPhone),
      idType:
          idType == null && nullToAbsent ? const Value.absent() : Value(idType),
      idNumber: idNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(idNumber),
      photoPath: photoPath == null && nullToAbsent
          ? const Value.absent()
          : Value(photoPath),
      isVip: Value(isVip),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      createdBy: createdBy == null && nullToAbsent
          ? const Value.absent()
          : Value(createdBy),
      updatedBy: updatedBy == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedBy),
      isDeleted: Value(isDeleted),
    );
  }

  factory PatientRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PatientRow(
      id: serializer.fromJson<int>(json['id']),
      uuid: serializer.fromJson<String>(json['uuid']),
      uhid: serializer.fromJson<String>(json['uhid']),
      name: serializer.fromJson<String>(json['name']),
      gender: serializer.fromJson<String?>(json['gender']),
      dob: serializer.fromJson<String?>(json['dob']),
      ageYears: serializer.fromJson<int?>(json['ageYears']),
      phone: serializer.fromJson<String?>(json['phone']),
      altPhone: serializer.fromJson<String?>(json['altPhone']),
      email: serializer.fromJson<String?>(json['email']),
      address: serializer.fromJson<String?>(json['address']),
      city: serializer.fromJson<String?>(json['city']),
      state: serializer.fromJson<String?>(json['state']),
      pincode: serializer.fromJson<String?>(json['pincode']),
      bloodGroup: serializer.fromJson<String?>(json['bloodGroup']),
      emergencyContactName:
          serializer.fromJson<String?>(json['emergencyContactName']),
      emergencyContactPhone:
          serializer.fromJson<String?>(json['emergencyContactPhone']),
      idType: serializer.fromJson<String?>(json['idType']),
      idNumber: serializer.fromJson<String?>(json['idNumber']),
      photoPath: serializer.fromJson<String?>(json['photoPath']),
      isVip: serializer.fromJson<bool>(json['isVip']),
      notes: serializer.fromJson<String?>(json['notes']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
      createdBy: serializer.fromJson<int?>(json['createdBy']),
      updatedBy: serializer.fromJson<int?>(json['updatedBy']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'uuid': serializer.toJson<String>(uuid),
      'uhid': serializer.toJson<String>(uhid),
      'name': serializer.toJson<String>(name),
      'gender': serializer.toJson<String?>(gender),
      'dob': serializer.toJson<String?>(dob),
      'ageYears': serializer.toJson<int?>(ageYears),
      'phone': serializer.toJson<String?>(phone),
      'altPhone': serializer.toJson<String?>(altPhone),
      'email': serializer.toJson<String?>(email),
      'address': serializer.toJson<String?>(address),
      'city': serializer.toJson<String?>(city),
      'state': serializer.toJson<String?>(state),
      'pincode': serializer.toJson<String?>(pincode),
      'bloodGroup': serializer.toJson<String?>(bloodGroup),
      'emergencyContactName': serializer.toJson<String?>(emergencyContactName),
      'emergencyContactPhone':
          serializer.toJson<String?>(emergencyContactPhone),
      'idType': serializer.toJson<String?>(idType),
      'idNumber': serializer.toJson<String?>(idNumber),
      'photoPath': serializer.toJson<String?>(photoPath),
      'isVip': serializer.toJson<bool>(isVip),
      'notes': serializer.toJson<String?>(notes),
      'createdAt': serializer.toJson<String>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
      'createdBy': serializer.toJson<int?>(createdBy),
      'updatedBy': serializer.toJson<int?>(updatedBy),
      'isDeleted': serializer.toJson<bool>(isDeleted),
    };
  }

  PatientRow copyWith(
          {int? id,
          String? uuid,
          String? uhid,
          String? name,
          Value<String?> gender = const Value.absent(),
          Value<String?> dob = const Value.absent(),
          Value<int?> ageYears = const Value.absent(),
          Value<String?> phone = const Value.absent(),
          Value<String?> altPhone = const Value.absent(),
          Value<String?> email = const Value.absent(),
          Value<String?> address = const Value.absent(),
          Value<String?> city = const Value.absent(),
          Value<String?> state = const Value.absent(),
          Value<String?> pincode = const Value.absent(),
          Value<String?> bloodGroup = const Value.absent(),
          Value<String?> emergencyContactName = const Value.absent(),
          Value<String?> emergencyContactPhone = const Value.absent(),
          Value<String?> idType = const Value.absent(),
          Value<String?> idNumber = const Value.absent(),
          Value<String?> photoPath = const Value.absent(),
          bool? isVip,
          Value<String?> notes = const Value.absent(),
          String? createdAt,
          String? updatedAt,
          Value<int?> createdBy = const Value.absent(),
          Value<int?> updatedBy = const Value.absent(),
          bool? isDeleted}) =>
      PatientRow(
        id: id ?? this.id,
        uuid: uuid ?? this.uuid,
        uhid: uhid ?? this.uhid,
        name: name ?? this.name,
        gender: gender.present ? gender.value : this.gender,
        dob: dob.present ? dob.value : this.dob,
        ageYears: ageYears.present ? ageYears.value : this.ageYears,
        phone: phone.present ? phone.value : this.phone,
        altPhone: altPhone.present ? altPhone.value : this.altPhone,
        email: email.present ? email.value : this.email,
        address: address.present ? address.value : this.address,
        city: city.present ? city.value : this.city,
        state: state.present ? state.value : this.state,
        pincode: pincode.present ? pincode.value : this.pincode,
        bloodGroup: bloodGroup.present ? bloodGroup.value : this.bloodGroup,
        emergencyContactName: emergencyContactName.present
            ? emergencyContactName.value
            : this.emergencyContactName,
        emergencyContactPhone: emergencyContactPhone.present
            ? emergencyContactPhone.value
            : this.emergencyContactPhone,
        idType: idType.present ? idType.value : this.idType,
        idNumber: idNumber.present ? idNumber.value : this.idNumber,
        photoPath: photoPath.present ? photoPath.value : this.photoPath,
        isVip: isVip ?? this.isVip,
        notes: notes.present ? notes.value : this.notes,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        createdBy: createdBy.present ? createdBy.value : this.createdBy,
        updatedBy: updatedBy.present ? updatedBy.value : this.updatedBy,
        isDeleted: isDeleted ?? this.isDeleted,
      );
  PatientRow copyWithCompanion(PatientsCompanion data) {
    return PatientRow(
      id: data.id.present ? data.id.value : this.id,
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      uhid: data.uhid.present ? data.uhid.value : this.uhid,
      name: data.name.present ? data.name.value : this.name,
      gender: data.gender.present ? data.gender.value : this.gender,
      dob: data.dob.present ? data.dob.value : this.dob,
      ageYears: data.ageYears.present ? data.ageYears.value : this.ageYears,
      phone: data.phone.present ? data.phone.value : this.phone,
      altPhone: data.altPhone.present ? data.altPhone.value : this.altPhone,
      email: data.email.present ? data.email.value : this.email,
      address: data.address.present ? data.address.value : this.address,
      city: data.city.present ? data.city.value : this.city,
      state: data.state.present ? data.state.value : this.state,
      pincode: data.pincode.present ? data.pincode.value : this.pincode,
      bloodGroup:
          data.bloodGroup.present ? data.bloodGroup.value : this.bloodGroup,
      emergencyContactName: data.emergencyContactName.present
          ? data.emergencyContactName.value
          : this.emergencyContactName,
      emergencyContactPhone: data.emergencyContactPhone.present
          ? data.emergencyContactPhone.value
          : this.emergencyContactPhone,
      idType: data.idType.present ? data.idType.value : this.idType,
      idNumber: data.idNumber.present ? data.idNumber.value : this.idNumber,
      photoPath: data.photoPath.present ? data.photoPath.value : this.photoPath,
      isVip: data.isVip.present ? data.isVip.value : this.isVip,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      createdBy: data.createdBy.present ? data.createdBy.value : this.createdBy,
      updatedBy: data.updatedBy.present ? data.updatedBy.value : this.updatedBy,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PatientRow(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('uhid: $uhid, ')
          ..write('name: $name, ')
          ..write('gender: $gender, ')
          ..write('dob: $dob, ')
          ..write('ageYears: $ageYears, ')
          ..write('phone: $phone, ')
          ..write('altPhone: $altPhone, ')
          ..write('email: $email, ')
          ..write('address: $address, ')
          ..write('city: $city, ')
          ..write('state: $state, ')
          ..write('pincode: $pincode, ')
          ..write('bloodGroup: $bloodGroup, ')
          ..write('emergencyContactName: $emergencyContactName, ')
          ..write('emergencyContactPhone: $emergencyContactPhone, ')
          ..write('idType: $idType, ')
          ..write('idNumber: $idNumber, ')
          ..write('photoPath: $photoPath, ')
          ..write('isVip: $isVip, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('createdBy: $createdBy, ')
          ..write('updatedBy: $updatedBy, ')
          ..write('isDeleted: $isDeleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
        id,
        uuid,
        uhid,
        name,
        gender,
        dob,
        ageYears,
        phone,
        altPhone,
        email,
        address,
        city,
        state,
        pincode,
        bloodGroup,
        emergencyContactName,
        emergencyContactPhone,
        idType,
        idNumber,
        photoPath,
        isVip,
        notes,
        createdAt,
        updatedAt,
        createdBy,
        updatedBy,
        isDeleted
      ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PatientRow &&
          other.id == this.id &&
          other.uuid == this.uuid &&
          other.uhid == this.uhid &&
          other.name == this.name &&
          other.gender == this.gender &&
          other.dob == this.dob &&
          other.ageYears == this.ageYears &&
          other.phone == this.phone &&
          other.altPhone == this.altPhone &&
          other.email == this.email &&
          other.address == this.address &&
          other.city == this.city &&
          other.state == this.state &&
          other.pincode == this.pincode &&
          other.bloodGroup == this.bloodGroup &&
          other.emergencyContactName == this.emergencyContactName &&
          other.emergencyContactPhone == this.emergencyContactPhone &&
          other.idType == this.idType &&
          other.idNumber == this.idNumber &&
          other.photoPath == this.photoPath &&
          other.isVip == this.isVip &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.createdBy == this.createdBy &&
          other.updatedBy == this.updatedBy &&
          other.isDeleted == this.isDeleted);
}

class PatientsCompanion extends UpdateCompanion<PatientRow> {
  final Value<int> id;
  final Value<String> uuid;
  final Value<String> uhid;
  final Value<String> name;
  final Value<String?> gender;
  final Value<String?> dob;
  final Value<int?> ageYears;
  final Value<String?> phone;
  final Value<String?> altPhone;
  final Value<String?> email;
  final Value<String?> address;
  final Value<String?> city;
  final Value<String?> state;
  final Value<String?> pincode;
  final Value<String?> bloodGroup;
  final Value<String?> emergencyContactName;
  final Value<String?> emergencyContactPhone;
  final Value<String?> idType;
  final Value<String?> idNumber;
  final Value<String?> photoPath;
  final Value<bool> isVip;
  final Value<String?> notes;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  final Value<int?> createdBy;
  final Value<int?> updatedBy;
  final Value<bool> isDeleted;
  const PatientsCompanion({
    this.id = const Value.absent(),
    this.uuid = const Value.absent(),
    this.uhid = const Value.absent(),
    this.name = const Value.absent(),
    this.gender = const Value.absent(),
    this.dob = const Value.absent(),
    this.ageYears = const Value.absent(),
    this.phone = const Value.absent(),
    this.altPhone = const Value.absent(),
    this.email = const Value.absent(),
    this.address = const Value.absent(),
    this.city = const Value.absent(),
    this.state = const Value.absent(),
    this.pincode = const Value.absent(),
    this.bloodGroup = const Value.absent(),
    this.emergencyContactName = const Value.absent(),
    this.emergencyContactPhone = const Value.absent(),
    this.idType = const Value.absent(),
    this.idNumber = const Value.absent(),
    this.photoPath = const Value.absent(),
    this.isVip = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.createdBy = const Value.absent(),
    this.updatedBy = const Value.absent(),
    this.isDeleted = const Value.absent(),
  });
  PatientsCompanion.insert({
    this.id = const Value.absent(),
    required String uuid,
    required String uhid,
    required String name,
    this.gender = const Value.absent(),
    this.dob = const Value.absent(),
    this.ageYears = const Value.absent(),
    this.phone = const Value.absent(),
    this.altPhone = const Value.absent(),
    this.email = const Value.absent(),
    this.address = const Value.absent(),
    this.city = const Value.absent(),
    this.state = const Value.absent(),
    this.pincode = const Value.absent(),
    this.bloodGroup = const Value.absent(),
    this.emergencyContactName = const Value.absent(),
    this.emergencyContactPhone = const Value.absent(),
    this.idType = const Value.absent(),
    this.idNumber = const Value.absent(),
    this.photoPath = const Value.absent(),
    this.isVip = const Value.absent(),
    this.notes = const Value.absent(),
    required String createdAt,
    required String updatedAt,
    this.createdBy = const Value.absent(),
    this.updatedBy = const Value.absent(),
    this.isDeleted = const Value.absent(),
  })  : uuid = Value(uuid),
        uhid = Value(uhid),
        name = Value(name),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<PatientRow> custom({
    Expression<int>? id,
    Expression<String>? uuid,
    Expression<String>? uhid,
    Expression<String>? name,
    Expression<String>? gender,
    Expression<String>? dob,
    Expression<int>? ageYears,
    Expression<String>? phone,
    Expression<String>? altPhone,
    Expression<String>? email,
    Expression<String>? address,
    Expression<String>? city,
    Expression<String>? state,
    Expression<String>? pincode,
    Expression<String>? bloodGroup,
    Expression<String>? emergencyContactName,
    Expression<String>? emergencyContactPhone,
    Expression<String>? idType,
    Expression<String>? idNumber,
    Expression<String>? photoPath,
    Expression<bool>? isVip,
    Expression<String>? notes,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<int>? createdBy,
    Expression<int>? updatedBy,
    Expression<bool>? isDeleted,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (uuid != null) 'uuid': uuid,
      if (uhid != null) 'uhid': uhid,
      if (name != null) 'name': name,
      if (gender != null) 'gender': gender,
      if (dob != null) 'dob': dob,
      if (ageYears != null) 'age_years': ageYears,
      if (phone != null) 'phone': phone,
      if (altPhone != null) 'alt_phone': altPhone,
      if (email != null) 'email': email,
      if (address != null) 'address': address,
      if (city != null) 'city': city,
      if (state != null) 'state': state,
      if (pincode != null) 'pincode': pincode,
      if (bloodGroup != null) 'blood_group': bloodGroup,
      if (emergencyContactName != null)
        'emergency_contact_name': emergencyContactName,
      if (emergencyContactPhone != null)
        'emergency_contact_phone': emergencyContactPhone,
      if (idType != null) 'id_type': idType,
      if (idNumber != null) 'id_number': idNumber,
      if (photoPath != null) 'photo_path': photoPath,
      if (isVip != null) 'is_vip': isVip,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (createdBy != null) 'created_by': createdBy,
      if (updatedBy != null) 'updated_by': updatedBy,
      if (isDeleted != null) 'is_deleted': isDeleted,
    });
  }

  PatientsCompanion copyWith(
      {Value<int>? id,
      Value<String>? uuid,
      Value<String>? uhid,
      Value<String>? name,
      Value<String?>? gender,
      Value<String?>? dob,
      Value<int?>? ageYears,
      Value<String?>? phone,
      Value<String?>? altPhone,
      Value<String?>? email,
      Value<String?>? address,
      Value<String?>? city,
      Value<String?>? state,
      Value<String?>? pincode,
      Value<String?>? bloodGroup,
      Value<String?>? emergencyContactName,
      Value<String?>? emergencyContactPhone,
      Value<String?>? idType,
      Value<String?>? idNumber,
      Value<String?>? photoPath,
      Value<bool>? isVip,
      Value<String?>? notes,
      Value<String>? createdAt,
      Value<String>? updatedAt,
      Value<int?>? createdBy,
      Value<int?>? updatedBy,
      Value<bool>? isDeleted}) {
    return PatientsCompanion(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      uhid: uhid ?? this.uhid,
      name: name ?? this.name,
      gender: gender ?? this.gender,
      dob: dob ?? this.dob,
      ageYears: ageYears ?? this.ageYears,
      phone: phone ?? this.phone,
      altPhone: altPhone ?? this.altPhone,
      email: email ?? this.email,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone:
          emergencyContactPhone ?? this.emergencyContactPhone,
      idType: idType ?? this.idType,
      idNumber: idNumber ?? this.idNumber,
      photoPath: photoPath ?? this.photoPath,
      isVip: isVip ?? this.isVip,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
    }
    if (uhid.present) {
      map['uhid'] = Variable<String>(uhid.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (gender.present) {
      map['gender'] = Variable<String>(gender.value);
    }
    if (dob.present) {
      map['dob'] = Variable<String>(dob.value);
    }
    if (ageYears.present) {
      map['age_years'] = Variable<int>(ageYears.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (altPhone.present) {
      map['alt_phone'] = Variable<String>(altPhone.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (address.present) {
      map['address'] = Variable<String>(address.value);
    }
    if (city.present) {
      map['city'] = Variable<String>(city.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(state.value);
    }
    if (pincode.present) {
      map['pincode'] = Variable<String>(pincode.value);
    }
    if (bloodGroup.present) {
      map['blood_group'] = Variable<String>(bloodGroup.value);
    }
    if (emergencyContactName.present) {
      map['emergency_contact_name'] =
          Variable<String>(emergencyContactName.value);
    }
    if (emergencyContactPhone.present) {
      map['emergency_contact_phone'] =
          Variable<String>(emergencyContactPhone.value);
    }
    if (idType.present) {
      map['id_type'] = Variable<String>(idType.value);
    }
    if (idNumber.present) {
      map['id_number'] = Variable<String>(idNumber.value);
    }
    if (photoPath.present) {
      map['photo_path'] = Variable<String>(photoPath.value);
    }
    if (isVip.present) {
      map['is_vip'] = Variable<bool>(isVip.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (createdBy.present) {
      map['created_by'] = Variable<int>(createdBy.value);
    }
    if (updatedBy.present) {
      map['updated_by'] = Variable<int>(updatedBy.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PatientsCompanion(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('uhid: $uhid, ')
          ..write('name: $name, ')
          ..write('gender: $gender, ')
          ..write('dob: $dob, ')
          ..write('ageYears: $ageYears, ')
          ..write('phone: $phone, ')
          ..write('altPhone: $altPhone, ')
          ..write('email: $email, ')
          ..write('address: $address, ')
          ..write('city: $city, ')
          ..write('state: $state, ')
          ..write('pincode: $pincode, ')
          ..write('bloodGroup: $bloodGroup, ')
          ..write('emergencyContactName: $emergencyContactName, ')
          ..write('emergencyContactPhone: $emergencyContactPhone, ')
          ..write('idType: $idType, ')
          ..write('idNumber: $idNumber, ')
          ..write('photoPath: $photoPath, ')
          ..write('isVip: $isVip, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('createdBy: $createdBy, ')
          ..write('updatedBy: $updatedBy, ')
          ..write('isDeleted: $isDeleted')
          ..write(')'))
        .toString();
  }
}

class $PatientAllergiesTable extends PatientAllergies
    with TableInfo<$PatientAllergiesTable, PatientAllergyRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PatientAllergiesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _patientIdMeta =
      const VerificationMeta('patientId');
  @override
  late final GeneratedColumn<int> patientId = GeneratedColumn<int>(
      'patient_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _allergenMeta =
      const VerificationMeta('allergen');
  @override
  late final GeneratedColumn<String> allergen = GeneratedColumn<String>(
      'allergen', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 200),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _reactionMeta =
      const VerificationMeta('reaction');
  @override
  late final GeneratedColumn<String> reaction = GeneratedColumn<String>(
      'reaction', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _severityMeta =
      const VerificationMeta('severity');
  @override
  late final GeneratedColumn<String> severity = GeneratedColumn<String>(
      'severity', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('mild'));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
      'created_at', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, patientId, allergen, reaction, severity, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'patient_allergies';
  @override
  VerificationContext validateIntegrity(Insertable<PatientAllergyRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('patient_id')) {
      context.handle(_patientIdMeta,
          patientId.isAcceptableOrUnknown(data['patient_id']!, _patientIdMeta));
    } else if (isInserting) {
      context.missing(_patientIdMeta);
    }
    if (data.containsKey('allergen')) {
      context.handle(_allergenMeta,
          allergen.isAcceptableOrUnknown(data['allergen']!, _allergenMeta));
    } else if (isInserting) {
      context.missing(_allergenMeta);
    }
    if (data.containsKey('reaction')) {
      context.handle(_reactionMeta,
          reaction.isAcceptableOrUnknown(data['reaction']!, _reactionMeta));
    }
    if (data.containsKey('severity')) {
      context.handle(_severityMeta,
          severity.isAcceptableOrUnknown(data['severity']!, _severityMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PatientAllergyRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PatientAllergyRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      patientId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}patient_id'])!,
      allergen: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}allergen'])!,
      reaction: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}reaction']),
      severity: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}severity'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $PatientAllergiesTable createAlias(String alias) {
    return $PatientAllergiesTable(attachedDatabase, alias);
  }
}

class PatientAllergyRow extends DataClass
    implements Insertable<PatientAllergyRow> {
  final int id;

  /// FK → patients.id
  final int patientId;
  final String allergen;
  final String? reaction;

  /// "mild" | "moderate" | "severe"
  final String severity;

  /// ISO-8601 timestamp
  final String createdAt;
  const PatientAllergyRow(
      {required this.id,
      required this.patientId,
      required this.allergen,
      this.reaction,
      required this.severity,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['patient_id'] = Variable<int>(patientId);
    map['allergen'] = Variable<String>(allergen);
    if (!nullToAbsent || reaction != null) {
      map['reaction'] = Variable<String>(reaction);
    }
    map['severity'] = Variable<String>(severity);
    map['created_at'] = Variable<String>(createdAt);
    return map;
  }

  PatientAllergiesCompanion toCompanion(bool nullToAbsent) {
    return PatientAllergiesCompanion(
      id: Value(id),
      patientId: Value(patientId),
      allergen: Value(allergen),
      reaction: reaction == null && nullToAbsent
          ? const Value.absent()
          : Value(reaction),
      severity: Value(severity),
      createdAt: Value(createdAt),
    );
  }

  factory PatientAllergyRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PatientAllergyRow(
      id: serializer.fromJson<int>(json['id']),
      patientId: serializer.fromJson<int>(json['patientId']),
      allergen: serializer.fromJson<String>(json['allergen']),
      reaction: serializer.fromJson<String?>(json['reaction']),
      severity: serializer.fromJson<String>(json['severity']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'patientId': serializer.toJson<int>(patientId),
      'allergen': serializer.toJson<String>(allergen),
      'reaction': serializer.toJson<String?>(reaction),
      'severity': serializer.toJson<String>(severity),
      'createdAt': serializer.toJson<String>(createdAt),
    };
  }

  PatientAllergyRow copyWith(
          {int? id,
          int? patientId,
          String? allergen,
          Value<String?> reaction = const Value.absent(),
          String? severity,
          String? createdAt}) =>
      PatientAllergyRow(
        id: id ?? this.id,
        patientId: patientId ?? this.patientId,
        allergen: allergen ?? this.allergen,
        reaction: reaction.present ? reaction.value : this.reaction,
        severity: severity ?? this.severity,
        createdAt: createdAt ?? this.createdAt,
      );
  PatientAllergyRow copyWithCompanion(PatientAllergiesCompanion data) {
    return PatientAllergyRow(
      id: data.id.present ? data.id.value : this.id,
      patientId: data.patientId.present ? data.patientId.value : this.patientId,
      allergen: data.allergen.present ? data.allergen.value : this.allergen,
      reaction: data.reaction.present ? data.reaction.value : this.reaction,
      severity: data.severity.present ? data.severity.value : this.severity,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PatientAllergyRow(')
          ..write('id: $id, ')
          ..write('patientId: $patientId, ')
          ..write('allergen: $allergen, ')
          ..write('reaction: $reaction, ')
          ..write('severity: $severity, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, patientId, allergen, reaction, severity, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PatientAllergyRow &&
          other.id == this.id &&
          other.patientId == this.patientId &&
          other.allergen == this.allergen &&
          other.reaction == this.reaction &&
          other.severity == this.severity &&
          other.createdAt == this.createdAt);
}

class PatientAllergiesCompanion extends UpdateCompanion<PatientAllergyRow> {
  final Value<int> id;
  final Value<int> patientId;
  final Value<String> allergen;
  final Value<String?> reaction;
  final Value<String> severity;
  final Value<String> createdAt;
  const PatientAllergiesCompanion({
    this.id = const Value.absent(),
    this.patientId = const Value.absent(),
    this.allergen = const Value.absent(),
    this.reaction = const Value.absent(),
    this.severity = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  PatientAllergiesCompanion.insert({
    this.id = const Value.absent(),
    required int patientId,
    required String allergen,
    this.reaction = const Value.absent(),
    this.severity = const Value.absent(),
    required String createdAt,
  })  : patientId = Value(patientId),
        allergen = Value(allergen),
        createdAt = Value(createdAt);
  static Insertable<PatientAllergyRow> custom({
    Expression<int>? id,
    Expression<int>? patientId,
    Expression<String>? allergen,
    Expression<String>? reaction,
    Expression<String>? severity,
    Expression<String>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (patientId != null) 'patient_id': patientId,
      if (allergen != null) 'allergen': allergen,
      if (reaction != null) 'reaction': reaction,
      if (severity != null) 'severity': severity,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  PatientAllergiesCompanion copyWith(
      {Value<int>? id,
      Value<int>? patientId,
      Value<String>? allergen,
      Value<String?>? reaction,
      Value<String>? severity,
      Value<String>? createdAt}) {
    return PatientAllergiesCompanion(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      allergen: allergen ?? this.allergen,
      reaction: reaction ?? this.reaction,
      severity: severity ?? this.severity,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (patientId.present) {
      map['patient_id'] = Variable<int>(patientId.value);
    }
    if (allergen.present) {
      map['allergen'] = Variable<String>(allergen.value);
    }
    if (reaction.present) {
      map['reaction'] = Variable<String>(reaction.value);
    }
    if (severity.present) {
      map['severity'] = Variable<String>(severity.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PatientAllergiesCompanion(')
          ..write('id: $id, ')
          ..write('patientId: $patientId, ')
          ..write('allergen: $allergen, ')
          ..write('reaction: $reaction, ')
          ..write('severity: $severity, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $SettingsTable extends Settings
    with TableInfo<$SettingsTable, SettingRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
      'key', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 100),
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
      'value', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, key, value, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(Insertable<SettingRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('key')) {
      context.handle(
          _keyMeta, key.isAcceptableOrUnknown(data['key']!, _keyMeta));
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
          _valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SettingRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SettingRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      key: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}key'])!,
      value: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}value'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $SettingsTable createAlias(String alias) {
    return $SettingsTable(attachedDatabase, alias);
  }
}

class SettingRow extends DataClass implements Insertable<SettingRow> {
  final int id;

  /// Unique setting key, e.g. "uhid_prefix", "uhid_sequence"
  final String key;
  final String value;
  final String updatedAt;
  const SettingRow(
      {required this.id,
      required this.key,
      required this.value,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    map['updated_at'] = Variable<String>(updatedAt);
    return map;
  }

  SettingsCompanion toCompanion(bool nullToAbsent) {
    return SettingsCompanion(
      id: Value(id),
      key: Value(key),
      value: Value(value),
      updatedAt: Value(updatedAt),
    );
  }

  factory SettingRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SettingRow(
      id: serializer.fromJson<int>(json['id']),
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
      'updatedAt': serializer.toJson<String>(updatedAt),
    };
  }

  SettingRow copyWith(
          {int? id, String? key, String? value, String? updatedAt}) =>
      SettingRow(
        id: id ?? this.id,
        key: key ?? this.key,
        value: value ?? this.value,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  SettingRow copyWithCompanion(SettingsCompanion data) {
    return SettingRow(
      id: data.id.present ? data.id.value : this.id,
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SettingRow(')
          ..write('id: $id, ')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, key, value, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SettingRow &&
          other.id == this.id &&
          other.key == this.key &&
          other.value == this.value &&
          other.updatedAt == this.updatedAt);
}

class SettingsCompanion extends UpdateCompanion<SettingRow> {
  final Value<int> id;
  final Value<String> key;
  final Value<String> value;
  final Value<String> updatedAt;
  const SettingsCompanion({
    this.id = const Value.absent(),
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  SettingsCompanion.insert({
    this.id = const Value.absent(),
    required String key,
    required String value,
    required String updatedAt,
  })  : key = Value(key),
        value = Value(value),
        updatedAt = Value(updatedAt);
  static Insertable<SettingRow> custom({
    Expression<int>? id,
    Expression<String>? key,
    Expression<String>? value,
    Expression<String>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  SettingsCompanion copyWith(
      {Value<int>? id,
      Value<String>? key,
      Value<String>? value,
      Value<String>? updatedAt}) {
    return SettingsCompanion(
      id: id ?? this.id,
      key: key ?? this.key,
      value: value ?? this.value,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsCompanion(')
          ..write('id: $id, ')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $PatientsTable patients = $PatientsTable(this);
  late final $PatientAllergiesTable patientAllergies =
      $PatientAllergiesTable(this);
  late final $SettingsTable settings = $SettingsTable(this);
  late final PatientsDao patientsDao = PatientsDao(this as AppDatabase);
  late final SettingsDao settingsDao = SettingsDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [patients, patientAllergies, settings];
}

typedef $$PatientsTableCreateCompanionBuilder = PatientsCompanion Function({
  Value<int> id,
  required String uuid,
  required String uhid,
  required String name,
  Value<String?> gender,
  Value<String?> dob,
  Value<int?> ageYears,
  Value<String?> phone,
  Value<String?> altPhone,
  Value<String?> email,
  Value<String?> address,
  Value<String?> city,
  Value<String?> state,
  Value<String?> pincode,
  Value<String?> bloodGroup,
  Value<String?> emergencyContactName,
  Value<String?> emergencyContactPhone,
  Value<String?> idType,
  Value<String?> idNumber,
  Value<String?> photoPath,
  Value<bool> isVip,
  Value<String?> notes,
  required String createdAt,
  required String updatedAt,
  Value<int?> createdBy,
  Value<int?> updatedBy,
  Value<bool> isDeleted,
});
typedef $$PatientsTableUpdateCompanionBuilder = PatientsCompanion Function({
  Value<int> id,
  Value<String> uuid,
  Value<String> uhid,
  Value<String> name,
  Value<String?> gender,
  Value<String?> dob,
  Value<int?> ageYears,
  Value<String?> phone,
  Value<String?> altPhone,
  Value<String?> email,
  Value<String?> address,
  Value<String?> city,
  Value<String?> state,
  Value<String?> pincode,
  Value<String?> bloodGroup,
  Value<String?> emergencyContactName,
  Value<String?> emergencyContactPhone,
  Value<String?> idType,
  Value<String?> idNumber,
  Value<String?> photoPath,
  Value<bool> isVip,
  Value<String?> notes,
  Value<String> createdAt,
  Value<String> updatedAt,
  Value<int?> createdBy,
  Value<int?> updatedBy,
  Value<bool> isDeleted,
});

class $$PatientsTableFilterComposer
    extends Composer<_$AppDatabase, $PatientsTable> {
  $$PatientsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get uuid => $composableBuilder(
      column: $table.uuid, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get uhid => $composableBuilder(
      column: $table.uhid, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get gender => $composableBuilder(
      column: $table.gender, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get dob => $composableBuilder(
      column: $table.dob, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get ageYears => $composableBuilder(
      column: $table.ageYears, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get phone => $composableBuilder(
      column: $table.phone, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get altPhone => $composableBuilder(
      column: $table.altPhone, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get email => $composableBuilder(
      column: $table.email, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get address => $composableBuilder(
      column: $table.address, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get city => $composableBuilder(
      column: $table.city, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get state => $composableBuilder(
      column: $table.state, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get pincode => $composableBuilder(
      column: $table.pincode, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get bloodGroup => $composableBuilder(
      column: $table.bloodGroup, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get emergencyContactName => $composableBuilder(
      column: $table.emergencyContactName,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get emergencyContactPhone => $composableBuilder(
      column: $table.emergencyContactPhone,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get idType => $composableBuilder(
      column: $table.idType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get idNumber => $composableBuilder(
      column: $table.idNumber, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get photoPath => $composableBuilder(
      column: $table.photoPath, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isVip => $composableBuilder(
      column: $table.isVip, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdBy => $composableBuilder(
      column: $table.createdBy, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get updatedBy => $composableBuilder(
      column: $table.updatedBy, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isDeleted => $composableBuilder(
      column: $table.isDeleted, builder: (column) => ColumnFilters(column));
}

class $$PatientsTableOrderingComposer
    extends Composer<_$AppDatabase, $PatientsTable> {
  $$PatientsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get uuid => $composableBuilder(
      column: $table.uuid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get uhid => $composableBuilder(
      column: $table.uhid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get gender => $composableBuilder(
      column: $table.gender, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get dob => $composableBuilder(
      column: $table.dob, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get ageYears => $composableBuilder(
      column: $table.ageYears, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get phone => $composableBuilder(
      column: $table.phone, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get altPhone => $composableBuilder(
      column: $table.altPhone, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get email => $composableBuilder(
      column: $table.email, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get address => $composableBuilder(
      column: $table.address, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get city => $composableBuilder(
      column: $table.city, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get state => $composableBuilder(
      column: $table.state, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get pincode => $composableBuilder(
      column: $table.pincode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get bloodGroup => $composableBuilder(
      column: $table.bloodGroup, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get emergencyContactName => $composableBuilder(
      column: $table.emergencyContactName,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get emergencyContactPhone => $composableBuilder(
      column: $table.emergencyContactPhone,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get idType => $composableBuilder(
      column: $table.idType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get idNumber => $composableBuilder(
      column: $table.idNumber, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get photoPath => $composableBuilder(
      column: $table.photoPath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isVip => $composableBuilder(
      column: $table.isVip, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdBy => $composableBuilder(
      column: $table.createdBy, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedBy => $composableBuilder(
      column: $table.updatedBy, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
      column: $table.isDeleted, builder: (column) => ColumnOrderings(column));
}

class $$PatientsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PatientsTable> {
  $$PatientsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<String> get uhid =>
      $composableBuilder(column: $table.uhid, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get gender =>
      $composableBuilder(column: $table.gender, builder: (column) => column);

  GeneratedColumn<String> get dob =>
      $composableBuilder(column: $table.dob, builder: (column) => column);

  GeneratedColumn<int> get ageYears =>
      $composableBuilder(column: $table.ageYears, builder: (column) => column);

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumn<String> get altPhone =>
      $composableBuilder(column: $table.altPhone, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get address =>
      $composableBuilder(column: $table.address, builder: (column) => column);

  GeneratedColumn<String> get city =>
      $composableBuilder(column: $table.city, builder: (column) => column);

  GeneratedColumn<String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<String> get pincode =>
      $composableBuilder(column: $table.pincode, builder: (column) => column);

  GeneratedColumn<String> get bloodGroup => $composableBuilder(
      column: $table.bloodGroup, builder: (column) => column);

  GeneratedColumn<String> get emergencyContactName => $composableBuilder(
      column: $table.emergencyContactName, builder: (column) => column);

  GeneratedColumn<String> get emergencyContactPhone => $composableBuilder(
      column: $table.emergencyContactPhone, builder: (column) => column);

  GeneratedColumn<String> get idType =>
      $composableBuilder(column: $table.idType, builder: (column) => column);

  GeneratedColumn<String> get idNumber =>
      $composableBuilder(column: $table.idNumber, builder: (column) => column);

  GeneratedColumn<String> get photoPath =>
      $composableBuilder(column: $table.photoPath, builder: (column) => column);

  GeneratedColumn<bool> get isVip =>
      $composableBuilder(column: $table.isVip, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get createdBy =>
      $composableBuilder(column: $table.createdBy, builder: (column) => column);

  GeneratedColumn<int> get updatedBy =>
      $composableBuilder(column: $table.updatedBy, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);
}

class $$PatientsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PatientsTable,
    PatientRow,
    $$PatientsTableFilterComposer,
    $$PatientsTableOrderingComposer,
    $$PatientsTableAnnotationComposer,
    $$PatientsTableCreateCompanionBuilder,
    $$PatientsTableUpdateCompanionBuilder,
    (PatientRow, BaseReferences<_$AppDatabase, $PatientsTable, PatientRow>),
    PatientRow,
    PrefetchHooks Function()> {
  $$PatientsTableTableManager(_$AppDatabase db, $PatientsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PatientsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PatientsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PatientsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> uuid = const Value.absent(),
            Value<String> uhid = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String?> gender = const Value.absent(),
            Value<String?> dob = const Value.absent(),
            Value<int?> ageYears = const Value.absent(),
            Value<String?> phone = const Value.absent(),
            Value<String?> altPhone = const Value.absent(),
            Value<String?> email = const Value.absent(),
            Value<String?> address = const Value.absent(),
            Value<String?> city = const Value.absent(),
            Value<String?> state = const Value.absent(),
            Value<String?> pincode = const Value.absent(),
            Value<String?> bloodGroup = const Value.absent(),
            Value<String?> emergencyContactName = const Value.absent(),
            Value<String?> emergencyContactPhone = const Value.absent(),
            Value<String?> idType = const Value.absent(),
            Value<String?> idNumber = const Value.absent(),
            Value<String?> photoPath = const Value.absent(),
            Value<bool> isVip = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<String> createdAt = const Value.absent(),
            Value<String> updatedAt = const Value.absent(),
            Value<int?> createdBy = const Value.absent(),
            Value<int?> updatedBy = const Value.absent(),
            Value<bool> isDeleted = const Value.absent(),
          }) =>
              PatientsCompanion(
            id: id,
            uuid: uuid,
            uhid: uhid,
            name: name,
            gender: gender,
            dob: dob,
            ageYears: ageYears,
            phone: phone,
            altPhone: altPhone,
            email: email,
            address: address,
            city: city,
            state: state,
            pincode: pincode,
            bloodGroup: bloodGroup,
            emergencyContactName: emergencyContactName,
            emergencyContactPhone: emergencyContactPhone,
            idType: idType,
            idNumber: idNumber,
            photoPath: photoPath,
            isVip: isVip,
            notes: notes,
            createdAt: createdAt,
            updatedAt: updatedAt,
            createdBy: createdBy,
            updatedBy: updatedBy,
            isDeleted: isDeleted,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String uuid,
            required String uhid,
            required String name,
            Value<String?> gender = const Value.absent(),
            Value<String?> dob = const Value.absent(),
            Value<int?> ageYears = const Value.absent(),
            Value<String?> phone = const Value.absent(),
            Value<String?> altPhone = const Value.absent(),
            Value<String?> email = const Value.absent(),
            Value<String?> address = const Value.absent(),
            Value<String?> city = const Value.absent(),
            Value<String?> state = const Value.absent(),
            Value<String?> pincode = const Value.absent(),
            Value<String?> bloodGroup = const Value.absent(),
            Value<String?> emergencyContactName = const Value.absent(),
            Value<String?> emergencyContactPhone = const Value.absent(),
            Value<String?> idType = const Value.absent(),
            Value<String?> idNumber = const Value.absent(),
            Value<String?> photoPath = const Value.absent(),
            Value<bool> isVip = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            required String createdAt,
            required String updatedAt,
            Value<int?> createdBy = const Value.absent(),
            Value<int?> updatedBy = const Value.absent(),
            Value<bool> isDeleted = const Value.absent(),
          }) =>
              PatientsCompanion.insert(
            id: id,
            uuid: uuid,
            uhid: uhid,
            name: name,
            gender: gender,
            dob: dob,
            ageYears: ageYears,
            phone: phone,
            altPhone: altPhone,
            email: email,
            address: address,
            city: city,
            state: state,
            pincode: pincode,
            bloodGroup: bloodGroup,
            emergencyContactName: emergencyContactName,
            emergencyContactPhone: emergencyContactPhone,
            idType: idType,
            idNumber: idNumber,
            photoPath: photoPath,
            isVip: isVip,
            notes: notes,
            createdAt: createdAt,
            updatedAt: updatedAt,
            createdBy: createdBy,
            updatedBy: updatedBy,
            isDeleted: isDeleted,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$PatientsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $PatientsTable,
    PatientRow,
    $$PatientsTableFilterComposer,
    $$PatientsTableOrderingComposer,
    $$PatientsTableAnnotationComposer,
    $$PatientsTableCreateCompanionBuilder,
    $$PatientsTableUpdateCompanionBuilder,
    (PatientRow, BaseReferences<_$AppDatabase, $PatientsTable, PatientRow>),
    PatientRow,
    PrefetchHooks Function()>;
typedef $$PatientAllergiesTableCreateCompanionBuilder
    = PatientAllergiesCompanion Function({
  Value<int> id,
  required int patientId,
  required String allergen,
  Value<String?> reaction,
  Value<String> severity,
  required String createdAt,
});
typedef $$PatientAllergiesTableUpdateCompanionBuilder
    = PatientAllergiesCompanion Function({
  Value<int> id,
  Value<int> patientId,
  Value<String> allergen,
  Value<String?> reaction,
  Value<String> severity,
  Value<String> createdAt,
});

class $$PatientAllergiesTableFilterComposer
    extends Composer<_$AppDatabase, $PatientAllergiesTable> {
  $$PatientAllergiesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get patientId => $composableBuilder(
      column: $table.patientId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get allergen => $composableBuilder(
      column: $table.allergen, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get reaction => $composableBuilder(
      column: $table.reaction, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get severity => $composableBuilder(
      column: $table.severity, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$PatientAllergiesTableOrderingComposer
    extends Composer<_$AppDatabase, $PatientAllergiesTable> {
  $$PatientAllergiesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get patientId => $composableBuilder(
      column: $table.patientId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get allergen => $composableBuilder(
      column: $table.allergen, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get reaction => $composableBuilder(
      column: $table.reaction, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get severity => $composableBuilder(
      column: $table.severity, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$PatientAllergiesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PatientAllergiesTable> {
  $$PatientAllergiesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get patientId =>
      $composableBuilder(column: $table.patientId, builder: (column) => column);

  GeneratedColumn<String> get allergen =>
      $composableBuilder(column: $table.allergen, builder: (column) => column);

  GeneratedColumn<String> get reaction =>
      $composableBuilder(column: $table.reaction, builder: (column) => column);

  GeneratedColumn<String> get severity =>
      $composableBuilder(column: $table.severity, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$PatientAllergiesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PatientAllergiesTable,
    PatientAllergyRow,
    $$PatientAllergiesTableFilterComposer,
    $$PatientAllergiesTableOrderingComposer,
    $$PatientAllergiesTableAnnotationComposer,
    $$PatientAllergiesTableCreateCompanionBuilder,
    $$PatientAllergiesTableUpdateCompanionBuilder,
    (
      PatientAllergyRow,
      BaseReferences<_$AppDatabase, $PatientAllergiesTable, PatientAllergyRow>
    ),
    PatientAllergyRow,
    PrefetchHooks Function()> {
  $$PatientAllergiesTableTableManager(
      _$AppDatabase db, $PatientAllergiesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PatientAllergiesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PatientAllergiesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PatientAllergiesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> patientId = const Value.absent(),
            Value<String> allergen = const Value.absent(),
            Value<String?> reaction = const Value.absent(),
            Value<String> severity = const Value.absent(),
            Value<String> createdAt = const Value.absent(),
          }) =>
              PatientAllergiesCompanion(
            id: id,
            patientId: patientId,
            allergen: allergen,
            reaction: reaction,
            severity: severity,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int patientId,
            required String allergen,
            Value<String?> reaction = const Value.absent(),
            Value<String> severity = const Value.absent(),
            required String createdAt,
          }) =>
              PatientAllergiesCompanion.insert(
            id: id,
            patientId: patientId,
            allergen: allergen,
            reaction: reaction,
            severity: severity,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$PatientAllergiesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $PatientAllergiesTable,
    PatientAllergyRow,
    $$PatientAllergiesTableFilterComposer,
    $$PatientAllergiesTableOrderingComposer,
    $$PatientAllergiesTableAnnotationComposer,
    $$PatientAllergiesTableCreateCompanionBuilder,
    $$PatientAllergiesTableUpdateCompanionBuilder,
    (
      PatientAllergyRow,
      BaseReferences<_$AppDatabase, $PatientAllergiesTable, PatientAllergyRow>
    ),
    PatientAllergyRow,
    PrefetchHooks Function()>;
typedef $$SettingsTableCreateCompanionBuilder = SettingsCompanion Function({
  Value<int> id,
  required String key,
  required String value,
  required String updatedAt,
});
typedef $$SettingsTableUpdateCompanionBuilder = SettingsCompanion Function({
  Value<int> id,
  Value<String> key,
  Value<String> value,
  Value<String> updatedAt,
});

class $$SettingsTableFilterComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$SettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$SettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$SettingsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SettingsTable,
    SettingRow,
    $$SettingsTableFilterComposer,
    $$SettingsTableOrderingComposer,
    $$SettingsTableAnnotationComposer,
    $$SettingsTableCreateCompanionBuilder,
    $$SettingsTableUpdateCompanionBuilder,
    (SettingRow, BaseReferences<_$AppDatabase, $SettingsTable, SettingRow>),
    SettingRow,
    PrefetchHooks Function()> {
  $$SettingsTableTableManager(_$AppDatabase db, $SettingsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<String> updatedAt = const Value.absent(),
          }) =>
              SettingsCompanion(
            id: id,
            key: key,
            value: value,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String key,
            required String value,
            required String updatedAt,
          }) =>
              SettingsCompanion.insert(
            id: id,
            key: key,
            value: value,
            updatedAt: updatedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SettingsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SettingsTable,
    SettingRow,
    $$SettingsTableFilterComposer,
    $$SettingsTableOrderingComposer,
    $$SettingsTableAnnotationComposer,
    $$SettingsTableCreateCompanionBuilder,
    $$SettingsTableUpdateCompanionBuilder,
    (SettingRow, BaseReferences<_$AppDatabase, $SettingsTable, SettingRow>),
    SettingRow,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$PatientsTableTableManager get patients =>
      $$PatientsTableTableManager(_db, _db.patients);
  $$PatientAllergiesTableTableManager get patientAllergies =>
      $$PatientAllergiesTableTableManager(_db, _db.patientAllergies);
  $$SettingsTableTableManager get settings =>
      $$SettingsTableTableManager(_db, _db.settings);
}
