// lib/data/database/tables/audit_tables.dart
// ignore_for_file: lines_longer_than_80_chars

import 'package:drift/drift.dart';

// ---------------------------------------------------------------------------
// AuditLogs
// ---------------------------------------------------------------------------
/// action: create | update | delete | view | login | logout |
///         print | export | backup | restore
class AuditLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  /// FK → users.id (nullable for system actions)
  IntColumn get userId => integer().nullable()();
  TextColumn get action => text()();
  TextColumn get entity => text()();
  IntColumn get entityId => integer().nullable()();
  /// JSON-encoded previous state
  TextColumn get oldValue => text().nullable()();
  /// JSON-encoded new state
  TextColumn get newValue => text().nullable()();
  TextColumn get ipAddress => text().nullable()();
  TextColumn get deviceInfo => text().nullable()();
  TextColumn get createdAt => text()();
  /// Previous log row hash (for tamper-evidence chain)
  TextColumn get prevHash => text().nullable()();
  /// SHA-256 of (prevHash + action + entity + entityId + createdAt + userId)
  TextColumn get hash => text().nullable()();
}

// ---------------------------------------------------------------------------
// Settings
// ---------------------------------------------------------------------------
/// Key-value application settings. The primary key is the key column itself.
class Settings extends Table {
  /// Primary key (text)
  TextColumn get key => text()();
  TextColumn get value => text()();
  TextColumn get updatedAt => text()();
  IntColumn get updatedBy => integer().nullable()();

  @override
  Set<Column> get primaryKey => {key};
}

// ---------------------------------------------------------------------------
// Notifications
// ---------------------------------------------------------------------------
class Notifications extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().unique()();
  TextColumn get type => text()();
  TextColumn get message => text()();
  TextColumn get entity => text().nullable()();
  IntColumn get entityId => integer().nullable()();
  BoolColumn get isRead =>
      boolean().withDefault(const Constant(false))();
  TextColumn get createdAt => text()();
  BoolColumn get isDeleted =>
      boolean().withDefault(const Constant(false))();
}
