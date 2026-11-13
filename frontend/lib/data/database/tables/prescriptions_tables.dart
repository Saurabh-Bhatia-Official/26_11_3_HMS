// lib/data/database/tables/prescriptions_tables.dart
// ignore_for_file: lines_longer_than_80_chars

import 'package:drift/drift.dart';

import 'pharmacy_tables.dart';
import 'staff_tables.dart';
import 'visits_tables.dart';

// ---------------------------------------------------------------------------
// Prescriptions
// ---------------------------------------------------------------------------
/// status: active | dispensed | cancelled
class Prescriptions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().unique()();
  IntColumn get visitId => integer().references(Visits, #id)();
  IntColumn get doctorId => integer().references(Doctors, #id)();
  TextColumn get prescribedAt => text()();
  TextColumn get notes => text().nullable()();
  TextColumn get status =>
      text().withDefault(const Constant('active'))();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();
  BoolColumn get isDeleted =>
      boolean().withDefault(const Constant(false))();
}

// ---------------------------------------------------------------------------
// PrescriptionItems
// ---------------------------------------------------------------------------
class PrescriptionItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().unique()();
  IntColumn get prescriptionId =>
      integer().references(Prescriptions, #id)();
  IntColumn get medicineId => integer().references(Medicines, #id)();
  TextColumn get dose => text().withDefault(const Constant(''))();
  TextColumn get frequency => text().withDefault(const Constant(''))();
  TextColumn get duration => text().withDefault(const Constant(''))();
  TextColumn get route => text().withDefault(const Constant(''))();
  TextColumn get instructions =>
      text().withDefault(const Constant(''))();
  IntColumn get qtyPrescribed =>
      integer().withDefault(const Constant(0))();
  BoolColumn get isDeleted =>
      boolean().withDefault(const Constant(false))();
}

// ---------------------------------------------------------------------------
// PrescriptionTemplates
// ---------------------------------------------------------------------------
class PrescriptionTemplates extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().unique()();
  IntColumn get doctorId => integer().references(Doctors, #id)();
  TextColumn get name => text()();
  /// Serialised JSON array of prescription line items
  TextColumn get itemsJson => text()();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();
  BoolColumn get isDeleted =>
      boolean().withDefault(const Constant(false))();
}
