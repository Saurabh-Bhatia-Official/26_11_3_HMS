// lib/data/database/tables/users_tables.dart
// ignore_for_file: lines_longer_than_80_chars

import 'package:drift/drift.dart';

// ---------------------------------------------------------------------------
// Roles
// ---------------------------------------------------------------------------
class Roles extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().unique()();
  TextColumn get name => text().unique()();
  TextColumn get description => text().withDefault(const Constant(''))();
  BoolColumn get isSystem =>
      boolean().withDefault(const Constant(false))();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();
}

// ---------------------------------------------------------------------------
// Permissions
// ---------------------------------------------------------------------------
class Permissions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().unique()();
  /// e.g. patients, billing, pharmacy …
  TextColumn get module => text()();
  /// view | create | edit | delete | print | export
  TextColumn get action => text()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {module, action},
      ];
}

// ---------------------------------------------------------------------------
// RolePermissions
// ---------------------------------------------------------------------------
class RolePermissions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get roleId => integer().references(Roles, #id)();
  IntColumn get permissionId => integer().references(Permissions, #id)();
  BoolColumn get isAllowed =>
      boolean().withDefault(const Constant(true))();

  @override
  List<Set<Column>> get uniqueKeys => [
        {roleId, permissionId},
      ];
}

// ---------------------------------------------------------------------------
// Users
// ---------------------------------------------------------------------------
/// Staff FK is declared as a plain integer (nullable) to avoid a circular
/// dependency between users_tables.dart and staff_tables.dart.
/// The referential integrity is enforced via PRAGMA foreign_keys = ON and
/// the FK is documented in the column name.
class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().unique()();
  TextColumn get username => text().unique()();
  TextColumn get passwordHash => text()();
  IntColumn get roleId => integer().references(Roles, #id)();
  /// FK → staff.id (nullable; plain int to avoid circular import)
  IntColumn get staffId => integer().nullable()();
  BoolColumn get isActive =>
      boolean().withDefault(const Constant(true))();
  TextColumn get lastLogin => text().nullable()();
  IntColumn get failedAttempts =>
      integer().withDefault(const Constant(0))();
  TextColumn get lockedUntil => text().nullable()();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();
  BoolColumn get isDeleted =>
      boolean().withDefault(const Constant(false))();
}
