// lib/core/providers/hospital_name_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hospital_management/data/database/app_database.dart';
import 'package:hospital_management/data/models/hms_models.dart';

/// Provides all hospital identity details from the `settings` table.
final hospitalInfoProvider = FutureProvider<Map<String, String>>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  final dao = db.settingsDao;
  final name = (await dao.getSetting('hospital_name'))?.value ?? 'CareSync';
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
/// Falls back to `'CareSync'` if the setting has not been seeded yet.
final hospitalNameProvider = FutureProvider<String>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  final dao = db.settingsDao;
  final row = await dao.getSetting('hospital_name');
  return row?.value ?? 'CareSync';
});

/// Mutable notifier so the Settings screen can update the name immediately.
final hospitalNameNotifierProvider =
    StateNotifierProvider<HospitalNameNotifier, String>((ref) {
  return HospitalNameNotifier(ref);
});

class HospitalNameNotifier extends StateNotifier<String> {
  HospitalNameNotifier(this._ref) : super('CareSync') {
    _load();
  }

  final Ref _ref;

  Future<void> _load() async {
    final db = _ref.read(appDatabaseProvider);
    final row = await db.settingsDao.getSetting('hospital_name');
    if (mounted) state = row?.value ?? 'CareSync';
  }

  Future<void> update(String name) async {
    state = name;
    final db = _ref.read(appDatabaseProvider);
    await db.settingsDao.upsertSetting('hospital_name', name);
  }
}

/// Provides all registered hospitals in CareSync (for Super Admin multi-hospital management).
final allHospitalsProvider = FutureProvider<List<HospitalModel>>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  return db.hmsDao.getAllHospitals();
});

/// Active hospital state for multi-hospital switching.
final activeHospitalProvider =
    StateNotifierProvider<ActiveHospitalNotifier, HospitalModel?>((ref) {
  return ActiveHospitalNotifier(ref);
});

class ActiveHospitalNotifier extends StateNotifier<HospitalModel?> {
  ActiveHospitalNotifier(this._ref) : super(null) {
    _load();
  }

  final Ref _ref;

  Future<void> _load() async {
    final db = _ref.read(appDatabaseProvider);
    final hospitals = await db.hmsDao.getAllHospitals();
    if (hospitals.isNotEmpty && mounted) {
      final activeIdStr = await db.getSetting('active_hospital_id');
      final activeId = int.tryParse(activeIdStr ?? '1') ?? 1;
      final selected = hospitals.firstWhere(
        (h) => h.id == activeId,
        orElse: () => hospitals.first,
      );
      state = selected;
    }
  }

  Future<void> switchHospital(HospitalModel hospital) async {
    state = hospital;
    final db = _ref.read(appDatabaseProvider);
    await db.saveSetting('active_hospital_id', hospital.id.toString());
    await db.settingsDao.upsertSetting('hospital_name', hospital.name);
    _ref.read(hospitalNameNotifierProvider.notifier).update(hospital.name);
    _ref.invalidate(hospitalNameProvider);
    _ref.invalidate(hospitalInfoProvider);
  }
}
