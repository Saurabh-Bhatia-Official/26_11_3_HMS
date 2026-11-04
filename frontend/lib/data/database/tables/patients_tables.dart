// lib/data/database/tables/patients_tables.dart
// ignore_for_file: lines_longer_than_80_chars

import 'package:drift/drift.dart';

// ---------------------------------------------------------------------------
// Patients
// ---------------------------------------------------------------------------
/// gender: M | F | Other
/// id_type: aadhaar | pan | passport | voter | driving_licence | other
class Patients extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().unique()();
  TextColumn get uhid => text().unique()();
  TextColumn get name => text()();
  TextColumn get gender => text()();
  TextColumn get dob => text().nullable()();
  /// Used when dob is not known
  IntColumn get ageYears => integer().nullable()();
  TextColumn get phone => text()();
  TextColumn get altPhone => text().nullable()();
  TextColumn get email => text().nullable()();
  TextColumn get address => text().withDefault(const Constant(''))();
  TextColumn get city => text().withDefault(const Constant(''))();
  TextColumn get state => text().withDefault(const Constant(''))();
  TextColumn get pincode => text().withDefault(const Constant(''))();
  TextColumn get bloodGroup => text().nullable()();
  TextColumn get emergencyContactName => text().nullable()();
  TextColumn get emergencyContactPhone => text().nullable()();
  TextColumn get idType => text().nullable()();
  TextColumn get idNumber => text().nullable()();
  TextColumn get photoPath => text().nullable()();
  BoolColumn get isVip =>
      boolean().withDefault(const Constant(false))();
  TextColumn get notes => text().nullable()();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();
  /// FK → users.id (plain int to avoid circular import)
  IntColumn get createdBy => integer().nullable()();
  IntColumn get updatedBy => integer().nullable()();
  BoolColumn get isDeleted =>
      boolean().withDefault(const Constant(false))();
}

// ---------------------------------------------------------------------------
// PatientAllergies
// ---------------------------------------------------------------------------
/// severity: mild | moderate | severe
class PatientAllergies extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().unique()();
  IntColumn get patientId => integer().references(Patients, #id)();
  TextColumn get allergen => text()();
  TextColumn get reaction => text().withDefault(const Constant(''))();
  TextColumn get severity => text()();
  TextColumn get createdAt => text()();
  IntColumn get createdBy => integer().nullable()();
  BoolColumn get isDeleted =>
      boolean().withDefault(const Constant(false))();
}

// ---------------------------------------------------------------------------
// PatientDocuments
// ---------------------------------------------------------------------------
/// file_type: pdf | image
class PatientDocuments extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().unique()();
  IntColumn get patientId => integer().references(Patients, #id)();
  TextColumn get filePath => text()();
  /// pdf | image
  TextColumn get fileType => text()();
  TextColumn get description =>
      text().withDefault(const Constant(''))();
  /// FK → users.id
  IntColumn get uploadedBy => integer().nullable()();
  TextColumn get createdAt => text()();
  BoolColumn get isDeleted =>
      boolean().withDefault(const Constant(false))();
}
