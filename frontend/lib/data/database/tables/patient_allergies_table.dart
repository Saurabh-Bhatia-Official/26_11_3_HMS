import 'package:drift/drift.dart';
import 'patients_table.dart';

/// Drift table for patient allergies.
@DataClassName('PatientAllergyRow')
class PatientAllergies extends Table {
  @override
  String get tableName => 'patient_allergies';

  IntColumn get id => integer().autoIncrement()();

  /// FK → patients.id
  IntColumn get patientId =>
      integer().references(Patients, #id)();

  TextColumn get allergen => text().withLength(min: 1, max: 200)();
  TextColumn get reaction => text().nullable()();

  /// "mild" | "moderate" | "severe"
  TextColumn get severity =>
      text().withDefault(const Constant('mild'))();

  /// ISO-8601 timestamp
  TextColumn get createdAt => text()();
}
