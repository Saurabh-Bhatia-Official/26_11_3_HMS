// lib/data/database/tables/lab_tables.dart
// ignore_for_file: lines_longer_than_80_chars

import 'package:drift/drift.dart';

import 'patients_tables.dart';
import 'staff_tables.dart';
import 'visits_tables.dart';

// ---------------------------------------------------------------------------
// LabTests
// ---------------------------------------------------------------------------
class LabTests extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().unique()();
  TextColumn get name => text()();
  TextColumn get category => text().withDefault(const Constant(''))();
  TextColumn get sampleType => text().withDefault(const Constant(''))();
  IntColumn get pricePaise => integer().withDefault(const Constant(0))();
  IntColumn get turnaroundHours =>
      integer().withDefault(const Constant(24))();
  BoolColumn get isOutsourced =>
      boolean().withDefault(const Constant(false))();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();
  BoolColumn get isDeleted =>
      boolean().withDefault(const Constant(false))();
}

// ---------------------------------------------------------------------------
// LabTestParameters
// ---------------------------------------------------------------------------
class LabTestParameters extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().unique()();
  IntColumn get testId => integer().references(LabTests, #id)();
  TextColumn get parameterName => text()();
  TextColumn get unit => text().withDefault(const Constant(''))();
  RealColumn get rangeLow => real().nullable()();
  RealColumn get rangeHigh => real().nullable()();
  /// Free-text reference range (e.g. "Negative")
  TextColumn get referenceText => text().nullable()();
  TextColumn get createdAt => text()();
  BoolColumn get isDeleted =>
      boolean().withDefault(const Constant(false))();
}

// ---------------------------------------------------------------------------
// LabPackages
// ---------------------------------------------------------------------------
class LabPackages extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().unique()();
  TextColumn get name => text()();
  TextColumn get description =>
      text().withDefault(const Constant(''))();
  IntColumn get pricePaise => integer().withDefault(const Constant(0))();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();
  BoolColumn get isDeleted =>
      boolean().withDefault(const Constant(false))();
}

// ---------------------------------------------------------------------------
// LabPackageTests
// ---------------------------------------------------------------------------
class LabPackageTests extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get packageId => integer().references(LabPackages, #id)();
  IntColumn get testId => integer().references(LabTests, #id)();
  BoolColumn get isDeleted =>
      boolean().withDefault(const Constant(false))();

  @override
  List<Set<Column>> get uniqueKeys => [
        {packageId, testId},
      ];
}

// ---------------------------------------------------------------------------
// LabOrders
// ---------------------------------------------------------------------------
/// status:   pending | collected | processing | resulted | verified | delivered
/// priority: routine | urgent | stat
class LabOrders extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().unique()();
  IntColumn get patientId => integer().references(Patients, #id)();
  IntColumn get visitId => integer().references(Visits, #id)();
  IntColumn get orderedBy => integer().references(Doctors, #id)();
  TextColumn get orderedAt => text()();
  TextColumn get sampleCollectedAt => text().nullable()();
  TextColumn get status =>
      text().withDefault(const Constant('pending'))();
  TextColumn get priority =>
      text().withDefault(const Constant('routine'))();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();
  BoolColumn get isDeleted =>
      boolean().withDefault(const Constant(false))();
}

// ---------------------------------------------------------------------------
// LabOrderItems
// ---------------------------------------------------------------------------
class LabOrderItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().unique()();
  IntColumn get orderId => integer().references(LabOrders, #id)();
  IntColumn get testId => integer().references(LabTests, #id)();
  TextColumn get status =>
      text().withDefault(const Constant('pending'))();
  TextColumn get remarks => text().nullable()();
  BoolColumn get isOutsourced =>
      boolean().withDefault(const Constant(false))();
  TextColumn get createdAt => text()();
  BoolColumn get isDeleted =>
      boolean().withDefault(const Constant(false))();
}

// ---------------------------------------------------------------------------
// LabResults
// ---------------------------------------------------------------------------
/// abnormal_flag: low | high | critical_low | critical_high
class LabResults extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().unique()();
  IntColumn get orderItemId =>
      integer().unique().references(LabOrderItems, #id)();
  TextColumn get resultValue => text()();
  TextColumn get abnormalFlag => text().nullable()();
  TextColumn get remarks => text().nullable()();
  /// FK → users.id
  IntColumn get enteredBy => integer()();
  TextColumn get enteredAt => text()();
  IntColumn get verifiedBy => integer().nullable()();
  TextColumn get verifiedAt => text().nullable()();
  BoolColumn get isDeleted =>
      boolean().withDefault(const Constant(false))();
}
