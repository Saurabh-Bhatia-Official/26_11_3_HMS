// lib/data/database/tables/ipd_tables.dart
// ignore_for_file: lines_longer_than_80_chars

import 'package:drift/drift.dart';

import 'beds_tables.dart';
import 'patients_tables.dart';
import 'pharmacy_tables.dart';
import 'staff_tables.dart';
import 'visits_tables.dart';

// ---------------------------------------------------------------------------
// Admissions
// ---------------------------------------------------------------------------
/// status: admitted | discharged | transferred
class Admissions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().unique()();
  IntColumn get patientId => integer().references(Patients, #id)();
  IntColumn get visitId => integer().unique().references(Visits, #id)();
  IntColumn get bedId => integer().references(Beds, #id)();
  IntColumn get admittingDoctorId =>
      integer().references(Doctors, #id)();
  TextColumn get reasonForAdmission => text()();
  TextColumn get admitAt => text()();
  TextColumn get dischargeAt => text().nullable()();
  TextColumn get status =>
      text().withDefault(const Constant('admitted'))();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();
  IntColumn get createdBy => integer().nullable()();
  IntColumn get updatedBy => integer().nullable()();
  BoolColumn get isDeleted =>
      boolean().withDefault(const Constant(false))();
}

// ---------------------------------------------------------------------------
// BedTransfers
// ---------------------------------------------------------------------------
class BedTransfers extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().unique()();
  IntColumn get admissionId => integer().references(Admissions, #id)();
  IntColumn get fromBedId => integer().references(Beds, #id)();
  IntColumn get toBedId => integer().references(Beds, #id)();
  TextColumn get transferredAt => text()();
  TextColumn get reason => text().withDefault(const Constant(''))();
  /// FK → users.id
  IntColumn get transferredBy => integer().nullable()();
  BoolColumn get isDeleted =>
      boolean().withDefault(const Constant(false))();
}

// ---------------------------------------------------------------------------
// NursingNotes
// ---------------------------------------------------------------------------
class NursingNotes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().unique()();
  IntColumn get admissionId => integer().references(Admissions, #id)();
  TextColumn get note => text()();
  /// FK → users.id
  IntColumn get authorId => integer()();
  TextColumn get createdAt => text()();
  BoolColumn get isDeleted =>
      boolean().withDefault(const Constant(false))();
}

// ---------------------------------------------------------------------------
// RoundNotes
// ---------------------------------------------------------------------------
class RoundNotes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().unique()();
  IntColumn get admissionId => integer().references(Admissions, #id)();
  IntColumn get doctorId => integer().references(Doctors, #id)();
  TextColumn get note => text()();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();
  IntColumn get createdBy => integer().nullable()();
  BoolColumn get isDeleted =>
      boolean().withDefault(const Constant(false))();
}

// ---------------------------------------------------------------------------
// MedicationAdministration
// ---------------------------------------------------------------------------
/// status: pending | given | skipped | held
class MedicationAdministration extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().unique()();
  IntColumn get admissionId => integer().references(Admissions, #id)();
  IntColumn get medicineId => integer().references(Medicines, #id)();
  /// FK → prescription_items.id (nullable when ordered directly)
  IntColumn get prescriptionItemId => integer().nullable()();
  TextColumn get dose => text()();
  TextColumn get route => text()();
  TextColumn get scheduledAt => text()();
  TextColumn get givenAt => text().nullable()();
  /// FK → users.id
  IntColumn get givenBy => integer().nullable()();
  TextColumn get status =>
      text().withDefault(const Constant('pending'))();
  TextColumn get remarks => text().nullable()();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();
  BoolColumn get isDeleted =>
      boolean().withDefault(const Constant(false))();
}

// ---------------------------------------------------------------------------
// DischargeSummaries
// ---------------------------------------------------------------------------
class DischargeSummaries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().unique()();
  IntColumn get admissionId =>
      integer().unique().references(Admissions, #id)();
  TextColumn get finalDiagnosis =>
      text().withDefault(const Constant(''))();
  TextColumn get courseInHospital =>
      text().withDefault(const Constant(''))();
  TextColumn get conditionAtDischarge =>
      text().withDefault(const Constant(''))();
  TextColumn get dischargeMeds =>
      text().withDefault(const Constant(''))();
  TextColumn get followUpAdvice =>
      text().withDefault(const Constant(''))();
  TextColumn get followUpDate => text().nullable()();
  TextColumn get surgeonNotes => text().nullable()();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();
  IntColumn get createdBy => integer().nullable()();
  IntColumn get updatedBy => integer().nullable()();
  BoolColumn get isDeleted =>
      boolean().withDefault(const Constant(false))();
}

// ---------------------------------------------------------------------------
// Deposits
// ---------------------------------------------------------------------------
/// Advance deposits against an IPD admission
class Deposits extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().unique()();
  IntColumn get admissionId => integer().references(Admissions, #id)();
  IntColumn get amountPaise => integer()();
  TextColumn get paymentMode => text()();
  TextColumn get reference => text().nullable()();
  /// FK → users.id
  IntColumn get receivedBy => integer()();
  TextColumn get receivedAt => text()();
  BoolColumn get isRefunded =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get isDeleted =>
      boolean().withDefault(const Constant(false))();
}
