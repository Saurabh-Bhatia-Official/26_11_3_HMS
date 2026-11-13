import 'package:drift/drift.dart';

/// Settings / configuration key-value store.
@DataClassName('SettingRow')
class Settings extends Table {
  @override
  String get tableName => 'settings';

  IntColumn get id => integer().autoIncrement()();

  /// Unique setting key, e.g. "uhid_prefix", "uhid_sequence"
  TextColumn get key => text().withLength(min: 1, max: 100).unique()();

  TextColumn get value => text()();

  TextColumn get updatedAt => text()();
}
