// lib/data/database/tables/beds_tables.dart
// ignore_for_file: lines_longer_than_80_chars

import 'package:drift/drift.dart';

// ---------------------------------------------------------------------------
// Wards
// ---------------------------------------------------------------------------
class Wards extends Table {
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
// Rooms
// ---------------------------------------------------------------------------
class Rooms extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().unique()();
  IntColumn get wardId => integer().references(Wards, #id)();
  TextColumn get roomNo => text()();
  IntColumn get floor => integer().withDefault(const Constant(0))();
  BoolColumn get isActive =>
      boolean().withDefault(const Constant(true))();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();
  BoolColumn get isDeleted =>
      boolean().withDefault(const Constant(false))();

  @override
  List<Set<Column>> get uniqueKeys => [
        {wardId, roomNo},
      ];
}

// ---------------------------------------------------------------------------
// Beds
// ---------------------------------------------------------------------------
/// bed_type: general | semi_private | private | icu | hdu
/// status:   available | occupied | reserved | cleaning | maintenance
class Beds extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().unique()();
  IntColumn get roomId => integer().references(Rooms, #id)();
  TextColumn get bedNo => text()();
  TextColumn get bedType =>
      text().withDefault(const Constant('general'))();
  /// Daily bed tariff in paise
  IntColumn get dailyTariffPaise =>
      integer().withDefault(const Constant(0))();
  TextColumn get status =>
      text().withDefault(const Constant('available'))();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();
  BoolColumn get isDeleted =>
      boolean().withDefault(const Constant(false))();

  @override
  List<Set<Column>> get uniqueKeys => [
        {roomId, bedNo},
      ];
}
