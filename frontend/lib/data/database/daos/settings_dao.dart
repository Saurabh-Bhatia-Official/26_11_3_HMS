import 'package:drift/drift.dart';
import 'package:hospital_management/data/database/tables/settings_table.dart';
import 'package:hospital_management/data/database/app_database.dart';

part 'settings_dao.g.dart';

@DriftAccessor(tables: [Settings])
class SettingsDao extends DatabaseAccessor<AppDatabase>
    with _$SettingsDaoMixin {
  SettingsDao(super.db);

  Future<SettingRow?> getSetting(String key) =>
      (select(settings)..where((t) => t.key.equals(key))).getSingleOrNull();

  Future<void> upsertSetting(String key, String value) async {
    final now = DateTime.now().toIso8601String();
    final existing = await (select(settings)..where((t) => t.key.equals(key))).getSingleOrNull();
    if (existing != null) {
      await (update(settings)..where((t) => t.key.equals(key))).write(
        SettingsCompanion(
          value: Value(value),
          updatedAt: Value(now),
        ),
      );
    } else {
      await into(settings).insert(
        SettingsCompanion(
          key: Value(key),
          value: Value(value),
          updatedAt: Value(now),
        ),
      );
    }
  }
}
