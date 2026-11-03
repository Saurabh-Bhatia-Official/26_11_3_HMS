// lib/core/providers/hospital_name_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hospital_management/data/database/app_database.dart';

/// Provides all hospital identity details from the `settings` table.
final hospitalInfoProvider = FutureProvider<Map<String, String>>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  final dao = db.settingsDao;
  final name = (await dao.getSetting('hospital_name'))?.value ?? 'Hospital';
  final address = (await dao.getSetting('address'))?.value ?? '';
  final phone = (await dao.getSetting('phone'))?.value ?? '';
  final regNo = (await dao.getSetting('reg_no'))?.value ?? '';
  final gstNo = (await dao.getSetting('gst_no'))?.value ?? '';
  final email = (await dao.getSetting('email'))?.value ?? '';
  return {
    'name': name,
    'address': address,
    'phone': phone,
    'regNo': regNo,
    'gstNo': gstNo,
    'email': email,
  };
});

/// Provides the hospital name read from the `settings` table.
///
/// Falls back to `'City Hospital'` if the setting has not been seeded yet.
final hospitalNameProvider = FutureProvider<String>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  final dao = db.settingsDao;
  final row = await dao.getSetting('hospital_name');
  return row?.value ?? 'City Hospital';
});

/// Mutable notifier so the Settings screen can update the name immediately.
final hospitalNameNotifierProvider =
    StateNotifierProvider<HospitalNameNotifier, String>((ref) {
  return HospitalNameNotifier(ref);
});

class HospitalNameNotifier extends StateNotifier<String> {
  HospitalNameNotifier(this._ref) : super('City Hospital') {
    _load();
  }

  final Ref _ref;

  Future<void> _load() async {
    final db = _ref.read(appDatabaseProvider);
    final row = await db.settingsDao.getSetting('hospital_name');
    if (mounted) state = row?.value ?? 'City Hospital';
  }

  Future<void> update(String name) async {
    state = name;
    final db = _ref.read(appDatabaseProvider);
    await db.settingsDao.upsertSetting('hospital_name', name);
  }
}
