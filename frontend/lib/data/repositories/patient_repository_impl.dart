import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:hospital_management/data/database/app_database.dart';
import 'package:hospital_management/domain/entities/patient.dart';
import 'package:hospital_management/domain/entities/patient_allergy.dart';
import 'package:hospital_management/domain/repositories/patient_repository.dart';
import 'package:uuid/uuid.dart';

/// Drift-backed implementation of [PatientRepository].
class PatientRepositoryImpl implements PatientRepository {
  PatientRepositoryImpl(this._db);

  final AppDatabase _db;
  final _uuid = const Uuid();

  // ── Create / Update ───────────────────────────────────────────────────────

  @override
  Future<Patient> create(Patient patient) async {
    final now = DateTime.now().toIso8601String();
    final uuid = _isUuid(patient.uuid) ? patient.uuid : _uuid.v4();
    final uhid = await generateUhid();

    final companion = PatientsCompanion(
      uuid: Value(uuid),
      uhid: Value(uhid),
      name: Value(patient.name),
      gender: Value(patient.gender),
      dob: Value(patient.dob?.toIso8601String()),
      ageYears: Value(patient.ageYears),
      phone: Value(patient.phone),
      altPhone: Value(patient.altPhone),
      email: Value(patient.email),
      address: Value(patient.address),
      city: Value(patient.city),
      state: Value(patient.state),
      pincode: Value(patient.pincode),
      bloodGroup: Value(patient.bloodGroup),
      emergencyContactName: Value(patient.emergencyContactName),
      emergencyContactPhone: Value(patient.emergencyContactPhone),
      idType: Value(patient.idType),
      idNumber: Value(patient.idNumber),
      photoPath: Value(patient.photoPath),
      isVip: Value(patient.isVip),
      notes: Value(patient.notes),
      createdAt: Value(now),
      updatedAt: Value(now),
      isDeleted: const Value(false),
    );

    late final int id;
    await _db.transaction(() async {
      id = await _db.patientsDao.insertPatient(companion);
      await _enqueue(uuid, 'CREATE', _patientPayload(patient, uuid), now);
    });
    return patient.copyWith(
        id: id, uuid: uuid, uhid: uhid, createdAt: DateTime.now());
  }

  @override
  Future<Patient> update(Patient patient) async {
    final now = DateTime.now().toIso8601String();

    final companion = PatientsCompanion(
      id: Value(patient.id),
      uuid: Value(patient.uuid),
      uhid: Value(patient.uhid),
      name: Value(patient.name),
      gender: Value(patient.gender),
      dob: Value(patient.dob?.toIso8601String()),
      ageYears: Value(patient.ageYears),
      phone: Value(patient.phone),
      altPhone: Value(patient.altPhone),
      email: Value(patient.email),
      address: Value(patient.address),
      city: Value(patient.city),
      state: Value(patient.state),
      pincode: Value(patient.pincode),
      bloodGroup: Value(patient.bloodGroup),
      emergencyContactName: Value(patient.emergencyContactName),
      emergencyContactPhone: Value(patient.emergencyContactPhone),
      idType: Value(patient.idType),
      idNumber: Value(patient.idNumber),
      photoPath: Value(patient.photoPath),
      isVip: Value(patient.isVip),
      notes: Value(patient.notes),
      createdAt: Value(patient.createdAt.toIso8601String()),
      updatedAt: Value(now),
      isDeleted: Value(patient.isDeleted),
    );

    await _db.transaction(() async {
      final found = await _db.patientsDao.updatePatient(companion);
      if (!found) throw StateError('Patient record no longer exists.');
      final version = await _db.patientSyncDao.serverVersion(patient.uuid);
      await _enqueue(
          patient.uuid, 'UPDATE', _patientPayload(patient, patient.uuid), now,
          baseVersion: version);
    });
    return patient;
  }

  @override
  Future<void> softDelete(int id) async {
    final row = await _db.patientsDao.findPatientById(id);
    if (row == null) return;
    final now = DateTime.now().toIso8601String();
    await _db.transaction(() async {
      await _db.patientsDao.softDeletePatient(id);
      await _enqueue(row.uuid, 'ARCHIVE', const {}, now,
          baseVersion: await _db.patientSyncDao.serverVersion(row.uuid));
    });
  }

  @override
  Future<void> changeStatus(int id, String status) async {
    if (status != 'ACTIVE' && status != 'INACTIVE') {
      throw ArgumentError.value(
          status, 'status', 'Expected ACTIVE or INACTIVE');
    }
    final row = await _db.patientsDao.findPatientById(id);
    if (row == null) throw StateError('Patient record no longer exists.');
    final now = DateTime.now().toIso8601String();
    await _db.transaction(() async {
      final version = await _db.patientSyncDao.serverVersion(row.uuid);
      await _enqueue(row.uuid, 'STATUS', {'status': status}, now,
          baseVersion: version);
      await _db.customStatement(
        'INSERT INTO patient_sync_states (patient_uuid, sync_state, updated_at) VALUES (?, \'PENDING\', ?) '
        'ON CONFLICT(patient_uuid) DO UPDATE SET sync_state = \'PENDING\', updated_at = excluded.updated_at',
        [row.uuid, now],
      );
    });
  }

  Future<void> _enqueue(String uuid, String operation,
          Map<String, dynamic> payload, String createdAt,
          {int? baseVersion}) =>
      _db.patientSyncDao.enqueue(
        operationId: _uuid.v4(),
        patientUuid: uuid,
        operation: operation,
        payload: jsonEncode(payload),
        baseVersion: baseVersion,
        createdAt: createdAt,
      );

  Map<String, dynamic> _patientPayload(Patient patient, String uuid) => {
        'uuid': uuid,
        'name': patient.name,
        'gender': patient.gender,
        'dateOfBirth': patient.dob?.toIso8601String().split('T').first,
        'ageYears': patient.ageYears,
        'phone': patient.phone,
        'alternatePhone': patient.altPhone,
        'email': patient.email,
        'address': patient.address,
        'city': patient.city,
        'state': patient.state,
        'pincode': patient.pincode,
        'bloodGroup': patient.bloodGroup,
        'emergencyContactName': patient.emergencyContactName,
        'emergencyContactPhone': patient.emergencyContactPhone,
      };

  bool _isUuid(String value) => RegExp(
        r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-8][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
      ).hasMatch(value);

  // ── Queries ───────────────────────────────────────────────────────────────

  @override
  Future<Patient?> findById(int id) async {
    final row = await _db.patientsDao.findPatientById(id);
    return row == null ? null : await _mapRow(row);
  }

  @override
  Future<Patient?> findByUhid(String uhid) async {
    final row = await _db.patientsDao.findPatientByUhid(uhid);
    return row == null ? null : await _mapRow(row);
  }

  @override
  Future<List<Patient>> search(
    String query, {
    int limit = 20,
    int offset = 0,
  }) async {
    final rows = await _db.patientsDao.searchPatients(
      query,
      limit: limit,
      offset: offset,
    );
    return Future.wait(rows.map(_mapRow));
  }

  @override
  Future<List<Patient>> getAll({int limit = 50, int offset = 0}) async {
    final rows =
        await _db.patientsDao.getAllPatients(limit: limit, offset: offset);
    return Future.wait(rows.map(_mapRow));
  }

  /// Generates the next UHID by atomically incrementing uhid_sequence in
  /// the settings table.  Format: "{prefix}-{6-digit padded sequence}".
  @override
  Future<String> generateUhid() async {
    return _db.transaction(() async {
      final prefixRow = await _db.settingsDao.getSetting('uhid_prefix');
      final seqRow = await _db.settingsDao.getSetting('uhid_sequence');

      final prefix = prefixRow?.value ?? 'UHID';
      final currentSeq = int.tryParse(seqRow?.value ?? '0') ?? 0;
      final nextSeq = currentSeq + 1;

      await _db.settingsDao.upsertSetting(
        'uhid_sequence',
        nextSeq.toString(),
      );

      return '$prefix-${nextSeq.toString().padLeft(6, '0')}';
    });
  }

  // ── Allergies ─────────────────────────────────────────────────────────────

  @override
  Future<List<PatientAllergy>> getAllergies(int patientId) async {
    final rows = await _db.patientsDao.getAllergiesForPatient(patientId);
    return rows.map(_mapAllergyRow).toList();
  }

  @override
  Future<void> addAllergy(PatientAllergy allergy) async {
    final companion = PatientAllergiesCompanion(
      patientId: Value(allergy.patientId),
      allergen: Value(allergy.allergen),
      reaction: Value(allergy.reaction),
      severity: Value(allergy.severity.name),
      createdAt: Value(allergy.createdAt.toIso8601String()),
    );
    await _db.patientsDao.insertAllergy(companion);
  }

  @override
  Future<void> deleteAllergy(int allergyId) =>
      _db.patientsDao.deleteAllergy(allergyId);

  // ── Mapping helpers ───────────────────────────────────────────────────────

  Future<Patient> _mapRow(PatientRow row) async {
    return Patient(
      id: row.id,
      uuid: row.uuid,
      uhid: row.uhid,
      serverUhid: await _db.patientSyncDao.canonicalUhid(row.uuid),
      syncState: await _db.patientSyncDao.syncState(row.uuid),
      name: row.name,
      gender: row.gender,
      dob: row.dob != null ? DateTime.tryParse(row.dob!) : null,
      ageYears: row.ageYears,
      phone: row.phone,
      altPhone: row.altPhone,
      email: row.email,
      address: row.address,
      city: row.city,
      state: row.state,
      pincode: row.pincode,
      bloodGroup: row.bloodGroup,
      emergencyContactName: row.emergencyContactName,
      emergencyContactPhone: row.emergencyContactPhone,
      idType: row.idType,
      idNumber: row.idNumber,
      photoPath: row.photoPath,
      isVip: row.isVip,
      notes: row.notes,
      createdAt: DateTime.parse(row.createdAt),
      isDeleted: row.isDeleted,
    );
  }

  PatientAllergy _mapAllergyRow(PatientAllergyRow row) {
    return PatientAllergy(
      id: row.id,
      patientId: row.patientId,
      allergen: row.allergen,
      reaction: row.reaction,
      severity: AllergySeverity.fromString(row.severity),
      createdAt: DateTime.parse(row.createdAt),
    );
  }
}
