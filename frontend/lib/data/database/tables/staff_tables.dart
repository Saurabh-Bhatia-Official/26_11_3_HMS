// lib/data/database/tables/staff_tables.dart
// ignore_for_file: lines_longer_than_80_chars

import 'package:drift/drift.dart';

// ---------------------------------------------------------------------------
// Departments
// ---------------------------------------------------------------------------
class Departments extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().unique()();
  TextColumn get name => text().unique()();
  TextColumn get description => text().withDefault(const Constant(''))();
  BoolColumn get isActive =>
      boolean().withDefault(const Constant(true))();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();
  BoolColumn get isDeleted =>
      boolean().withDefault(const Constant(false))();
}

// ---------------------------------------------------------------------------
// Staff
// ---------------------------------------------------------------------------
/// role values: doctor | nurse | lab | pharmacy | reception | admin | accounts
class Staff extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().unique()();
  TextColumn get name => text()();
  /// M | F | Other
  TextColumn get gender => text()();
  TextColumn get dob => text().nullable()();
  TextColumn get phone => text()();
  TextColumn get email => text().nullable()();
  TextColumn get address => text().withDefault(const Constant(''))();
  TextColumn get role => text()();
  IntColumn get departmentId =>
      integer().nullable().references(Departments, #id)();
  TextColumn get qualification =>
      text().withDefault(const Constant(''))();
  TextColumn get regNo => text().nullable()();
  TextColumn get photoPath => text().nullable()();
  BoolColumn get isActive =>
      boolean().withDefault(const Constant(true))();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();
  /// FK → users.id (plain int to avoid circular import)
  IntColumn get createdBy => integer().nullable()();
  IntColumn get updatedBy => integer().nullable()();
  BoolColumn get isDeleted =>
      boolean().withDefault(const Constant(false))();
}

// ---------------------------------------------------------------------------
// Doctors
// ---------------------------------------------------------------------------
class Doctors extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().unique()();
  IntColumn get staffId => integer().unique().references(Staff, #id)();
  TextColumn get specialisation =>
      text().withDefault(const Constant(''))();
  /// Consultation fee in paise (₹ × 100)
  IntColumn get consultationFee => integer().withDefault(const Constant(0))();
  IntColumn get followupFee => integer().withDefault(const Constant(0))();
  IntColumn get followupDays => integer().withDefault(const Constant(7))();
  IntColumn get maxSlotsPerDay =>
      integer().withDefault(const Constant(30))();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();
  BoolColumn get isDeleted =>
      boolean().withDefault(const Constant(false))();
}

// ---------------------------------------------------------------------------
// DoctorSchedules
// ---------------------------------------------------------------------------
/// weekday: 0 = Monday … 6 = Sunday
class DoctorSchedules extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().unique()();
  IntColumn get doctorId => integer().references(Doctors, #id)();
  IntColumn get weekday => integer()();
  TextColumn get startTime => text()();
  TextColumn get endTime => text()();
  IntColumn get slotMinutes =>
      integer().withDefault(const Constant(15))();
  BoolColumn get isActive =>
      boolean().withDefault(const Constant(true))();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();
  BoolColumn get isDeleted =>
      boolean().withDefault(const Constant(false))();
}
