import 'package:drift/drift.dart';
import 'package:hospital_management/data/database/app_database.dart';
import 'package:hospital_management/data/database/tables/patients_table.dart';
import 'package:hospital_management/data/database/tables/patient_allergies_table.dart';

part 'patients_dao.g.dart';

@DriftAccessor(tables: [Patients, PatientAllergies])
class PatientsDao extends DatabaseAccessor<AppDatabase>
    with _$PatientsDaoMixin {
  PatientsDao(super.db);

  // ── Patients ──────────────────────────────────────────────────────────────

  Future<int> insertPatient(PatientsCompanion companion) =>
      into(patients).insert(companion);

  Future<bool> updatePatient(PatientsCompanion companion) =>
      update(patients).replace(companion);

  Future<void> softDeletePatient(int id) => (update(patients)
        ..where((t) => t.id.equals(id)))
      .write(PatientsCompanion(
        isDeleted: const Value(true),
        updatedAt: Value(DateTime.now().toIso8601String()),
      ));

  Future<PatientRow?> findPatientById(int id) =>
      (select(patients)
            ..where((t) => t.id.equals(id) & t.isDeleted.equals(false)))
          .getSingleOrNull();

  Future<PatientRow?> findPatientByUhid(String uhid) =>
      (select(patients)
            ..where((t) => t.uhid.equals(uhid) & t.isDeleted.equals(false)))
          .getSingleOrNull();

  Future<List<PatientRow>> searchPatients(
    String query, {
    int limit = 20,
    int offset = 0,
  }) {
    final q = '%$query%';
    return (select(patients)
          ..where(
            (t) =>
                t.isDeleted.equals(false) &
                (t.name.like(q) |
                    t.uhid.like(q) |
                    t.phone.like(q)),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.name)])
          ..limit(limit, offset: offset))
        .get();
  }

  Future<List<PatientRow>> getAllPatients({
    int limit = 50,
    int offset = 0,
  }) =>
      (select(patients)
            ..where((t) => t.isDeleted.equals(false))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
            ..limit(limit, offset: offset))
          .get();

  Future<PatientRow?> findPatientByPhone(String phone) =>
      (select(patients)
            ..where((t) => t.phone.equals(phone) & t.isDeleted.equals(false)))
          .getSingleOrNull();

  // ── Allergies ─────────────────────────────────────────────────────────────

  Future<List<PatientAllergyRow>> getAllergiesForPatient(int patientId) =>
      (select(patientAllergies)
            ..where((t) => t.patientId.equals(patientId))
            ..orderBy([(t) => OrderingTerm.asc(t.allergen)]))
          .get();

  Future<int> insertAllergy(PatientAllergiesCompanion companion) =>
      into(patientAllergies).insert(companion);

  Future<void> deleteAllergy(int allergyId) =>
      (delete(patientAllergies)..where((t) => t.id.equals(allergyId))).go();
}
