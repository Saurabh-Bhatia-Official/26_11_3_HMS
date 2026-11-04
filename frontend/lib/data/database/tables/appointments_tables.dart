// lib/data/database/tables/appointments_tables.dart
// ignore_for_file: lines_longer_than_80_chars

import 'package:drift/drift.dart';

import 'patients_tables.dart';
import 'staff_tables.dart';

// ---------------------------------------------------------------------------
// Appointments
// ---------------------------------------------------------------------------
/// status: scheduled | arrived | in_progress | completed | no_show | cancelled
/// visit_type: appointment | walk_in
class Appointments extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().unique()();
  IntColumn get patientId => integer().references(Patients, #id)();
  IntColumn get doctorId => integer().references(Doctors, #id)();
  IntColumn get departmentId => integer().references(Departments, #id)();
  /// YYYY-MM-DD
  TextColumn get scheduledDate => text()();
  /// HH:mm
  TextColumn get scheduledTime => text()();
  IntColumn get tokenNo => integer().nullable()();
  TextColumn get status =>
      text().withDefault(const Constant('scheduled'))();
  TextColumn get visitType =>
      text().withDefault(const Constant('appointment'))();
  TextColumn get notes => text().nullable()();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();
  IntColumn get createdBy => integer().nullable()();
  IntColumn get updatedBy => integer().nullable()();
  BoolColumn get isDeleted =>
      boolean().withDefault(const Constant(false))();
}
