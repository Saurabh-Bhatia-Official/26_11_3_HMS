import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'package:hospital_management/data/database/app_database.dart';
import 'package:hospital_management/domain/entities/patient.dart';
import 'package:hospital_management/domain/entities/patient_allergy.dart';
import 'package:hospital_management/domain/repositories/patient_repository.dart';

/// Drift-backed implementation of [PatientRepository].
class PatientRepositoryImpl implements PatientRepository {
  PatientRepositoryImpl(this._db);

  final AppDatabase _db;
  final _uuid = const Uuid();

  // ── Create / Update ───────────────────────────────────────────────────────

  @override
  Future<Patient> create(Patient patient) async {
    final now = DateTime.now().toIso8601String();
    final uuid = _uuid.v4();
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

    final id = await _db.patientsDao.insertPatient(companion);
    return patient.copyWith(id: id, uuid: uuid, uhid: uhid, createdAt: DateTime.now());
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

    await _db.patientsDao.updatePatient(companion);
    return patient;
  }

  @override
  Future<void> softDelete(int id) => _db.patientsDao.softDeletePatient(id);

  // ── Queries ───────────────────────────────────────────────────────────────

  @override
  Future<Patient?> findById(int id) async {
    final row = await _db.patientsDao.findPatientById(id);
    return row == null ? null : _mapRow(row);
  }

  @override
  Future<Patient?> findByUhid(String uhid) async {
    final row = await _db.patientsDao.findPatientByUhid(uhid);
    return row == null ? null : _mapRow(row);
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
    return rows.map(_mapRow).toList();
  }

  @override
  Future<List<Patient>> getAll({int limit = 50, int offset = 0}) async {
    final rows =
        await _db.patientsDao.getAllPatients(limit: limit, offset: offset);
    return rows.map(_mapRow).toList();
  }

  /// Generates the next UHID by atomically incrementing uhid_sequence in
  /// the settings table.  Format: "{prefix}-{6-digit padded sequence}".
  @override
  Future<String> generateUhid() async {
    return _db.transaction(() async {
      final prefixRow =
          await _db.settingsDao.getSetting('uhid_prefix');
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
    final rows =
        await _db.patientsDao.getAllergiesForPatient(patientId);
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

  Patient _mapRow(PatientRow row) {
    return Patient(
      id: row.id,
      uuid: row.uuid,
      uhid: row.uhid,
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
