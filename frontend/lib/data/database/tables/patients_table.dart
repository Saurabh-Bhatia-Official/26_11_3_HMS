import 'package:drift/drift.dart';

/// Drift table definition for the `patients` table.
@DataClassName('PatientRow')
class Patients extends Table {
  @override
  String get tableName => 'patients';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().withLength(min: 36, max: 36)();
  TextColumn get uhid => text().withLength(min: 1, max: 30)();

  TextColumn get name => text().withLength(min: 1, max: 200)();

  /// "Male" | "Female" | "Other"
  TextColumn get gender => text().nullable()();

  /// ISO-8601 date string, e.g. "1990-05-15"
  TextColumn get dob => text().nullable()();

  IntColumn get ageYears => integer().nullable()();

  TextColumn get phone => text().nullable()();
  TextColumn get altPhone => text().nullable()();
  TextColumn get email => text().nullable()();
  TextColumn get address => text().nullable()();
  TextColumn get city => text().nullable()();
  TextColumn get state => text().nullable()();
  TextColumn get pincode => text().nullable()();

  /// "A+" | "A-" | "B+" | "B-" | "O+" | "O-" | "AB+" | "AB-"
  TextColumn get bloodGroup => text().nullable()();

  TextColumn get emergencyContactName => text().nullable()();
  TextColumn get emergencyContactPhone => text().nullable()();

  /// "Aadhaar" | "PAN" | "Passport" | "DL" | "Other"
  TextColumn get idType => text().nullable()();
  TextColumn get idNumber => text().nullable()();

  /// Absolute on-device path to the patient photo file.
  TextColumn get photoPath => text().nullable()();

  BoolColumn get isVip =>
      boolean().withDefault(const Constant(false))();

  TextColumn get notes => text().nullable()();

  /// ISO-8601 timestamp
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();

  /// FK → users.id (nullable until auth is wired)
  IntColumn get createdBy => integer().nullable()();
  IntColumn get updatedBy => integer().nullable()();

  BoolColumn get isDeleted =>
      boolean().withDefault(const Constant(false))();

  @override
  List<Index> get indexes => [
        Index('idx_patients_uhid', 'uhid'),
        Index('idx_patients_phone', 'phone'),
        Index('idx_patients_name', 'name'),
      ];
}
