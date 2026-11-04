import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hospital_management/data/database/app_database.dart';

/// Persisted theme-mode preference stored in the settings table.
final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier(ref);
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier(this._ref) : super(ThemeMode.light) {
    _load();
  }

  final Ref _ref;

  Future<void> _load() async {
    final db = _ref.read(appDatabaseProvider);
    final value = await db.getSetting('theme_mode');
    if (value == 'dark') {
      state = ThemeMode.dark;
    } else if (value == 'system') {
      state = ThemeMode.system;
    } else {
      state = ThemeMode.light;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final db = _ref.read(appDatabaseProvider);
    final key = mode == ThemeMode.dark
        ? 'dark'
        : mode == ThemeMode.system
            ? 'system'
            : 'light';
    await db.saveSetting('theme_mode', key);
  }
}

