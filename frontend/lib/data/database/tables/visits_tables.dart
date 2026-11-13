// lib/data/database/tables/visits_tables.dart
// ignore_for_file: lines_longer_than_80_chars

import 'package:drift/drift.dart';

import 'appointments_tables.dart';
import 'patients_tables.dart';
import 'staff_tables.dart';

// ---------------------------------------------------------------------------
// Visits
// ---------------------------------------------------------------------------
/// visit_type: opd | ipd | emergency | followup
/// status:     open | closed
class Visits extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().unique()();
  IntColumn get patientId => integer().references(Patients, #id)();
  IntColumn get doctorId => integer().references(Doctors, #id)();
  IntColumn get departmentId => integer().references(Departments, #id)();
  IntColumn get appointmentId =>
      integer().nullable().references(Appointments, #id)();
  TextColumn get visitType => text()();
  TextColumn get visitDate => text()();
  TextColumn get status =>
      text().withDefault(const Constant('open'))();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();
  IntColumn get createdBy => integer().nullable()();
  IntColumn get updatedBy => integer().nullable()();
  BoolColumn get isDeleted =>
      boolean().withDefault(const Constant(false))();
}

// ---------------------------------------------------------------------------
// Vitals
// ---------------------------------------------------------------------------
class Vitals extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().unique()();
  IntColumn get visitId => integer().references(Visits, #id)();
  IntColumn get bpSystolic => integer().nullable()();
  IntColumn get bpDiastolic => integer().nullable()();
  IntColumn get pulse => integer().nullable()();
  RealColumn get temperatureC => real().nullable()();
  IntColumn get spo2 => integer().nullable()();
  RealColumn get weightKg => real().nullable()();
  RealColumn get heightCm => real().nullable()();
  /// Computed (weight_kg / (height_m)^2) and stored for reporting
  RealColumn get bmi => real().nullable()();
  /// FK → users.id
  IntColumn get recordedBy => integer().nullable()();
  TextColumn get recordedAt => text()();
  TextColumn get notes => text().nullable()();
  BoolColumn get isDeleted =>
      boolean().withDefault(const Constant(false))();
}

// ---------------------------------------------------------------------------
// Consultations
// ---------------------------------------------------------------------------
class Consultations extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().unique()();
  IntColumn get visitId => integer().unique().references(Visits, #id)();
  TextColumn get chiefComplaint => text().withDefault(const Constant(''))();
  TextColumn get history => text().withDefault(const Constant(''))();
  TextColumn get examination => text().withDefault(const Constant(''))();
  TextColumn get diagnosisText => text().withDefault(const Constant(''))();
  TextColumn get icdCode => text().nullable()();
  TextColumn get icdDescription => text().nullable()();
  TextColumn get advice => text().withDefault(const Constant(''))();
  TextColumn get followUpDate => text().nullable()();
  IntColumn get version => integer().withDefault(const Constant(1))();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();
  IntColumn get createdBy => integer().nullable()();
  IntColumn get updatedBy => integer().nullable()();
  BoolColumn get isDeleted =>
      boolean().withDefault(const Constant(false))();
}
