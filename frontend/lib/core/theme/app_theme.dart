import 'package:flutter/material.dart';

/// Central Material 3 theme definitions for the HMS application.
/// Provides both a light and dark theme sharing the same colour scheme seed.
class AppTheme {
  AppTheme._();

  // ── Brand colours ──────────────────────────────────────────────────────────
  static const Color _seedColor = Color(0xFF1565C0); // Deep blue
  static const Color _errorColor = Color(0xFFB00020);
  static const Color _warningColor = Color(0xFFE65100);
  static const Color _successColor = Color(0xFF2E7D32);

  // ── Light theme ────────────────────────────────────────────────────────────
  static ThemeData get lightTheme {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _seedColor,
        brightness: Brightness.light,
        error: _errorColor,
      ),
    );
    return base.copyWith(
      textTheme: _textTheme(base.textTheme, Brightness.light),
      appBarTheme: _appBarTheme(base),
      cardTheme: _cardTheme(),
      inputDecorationTheme: _inputDecorationTheme(base),
      elevatedButtonTheme: _elevatedButtonTheme(base),
      outlinedButtonTheme: _outlinedButtonTheme(base),
      textButtonTheme: _textButtonTheme(base),
      chipTheme: _chipTheme(base),
      dividerTheme: const DividerThemeData(space: 1, thickness: 1),
      extensions: [
        AppColours(
          warning: _warningColor,
          success: _successColor,
          criticalBg: const Color(0xFFFFEBEE),
          criticalFg: _errorColor,
        ),
      ],
    );
  }

  // ── Dark theme ─────────────────────────────────────────────────────────────
  static ThemeData get darkTheme {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _seedColor,
        brightness: Brightness.dark,
        error: const Color(0xFFCF6679),
      ),
    );
    return base.copyWith(
      textTheme: _textTheme(base.textTheme, Brightness.dark),
      appBarTheme: _appBarTheme(base),
      cardTheme: _cardTheme(),
      inputDecorationTheme: _inputDecorationTheme(base),
      elevatedButtonTheme: _elevatedButtonTheme(base),
      outlinedButtonTheme: _outlinedButtonTheme(base),
      textButtonTheme: _textButtonTheme(base),
      chipTheme: _chipTheme(base),
      dividerTheme: const DividerThemeData(space: 1, thickness: 1),
      extensions: [
        AppColours(
          warning: const Color(0xFFFFB74D),
          success: const Color(0xFF81C784),
          criticalBg: const Color(0xFF4E0000),
          criticalFg: const Color(0xFFCF6679),
        ),
      ],
    );
  }

  // ── Private helpers ────────────────────────────────────────────────────────
  static TextTheme _textTheme(TextTheme base, Brightness brightness) {
    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(fontFamily: 'NotoSans'),
      displayMedium: base.displayMedium?.copyWith(fontFamily: 'NotoSans'),
      displaySmall: base.displaySmall?.copyWith(fontFamily: 'NotoSans'),
      headlineLarge: base.headlineLarge?.copyWith(fontFamily: 'NotoSans', fontWeight: FontWeight.w700),
      headlineMedium: base.headlineMedium?.copyWith(fontFamily: 'NotoSans', fontWeight: FontWeight.w600),
      headlineSmall: base.headlineSmall?.copyWith(fontFamily: 'NotoSans', fontWeight: FontWeight.w600),
      titleLarge: base.titleLarge?.copyWith(fontFamily: 'NotoSans', fontWeight: FontWeight.w600),
      titleMedium: base.titleMedium?.copyWith(fontFamily: 'NotoSans', fontWeight: FontWeight.w500),
      titleSmall: base.titleSmall?.copyWith(fontFamily: 'NotoSans'),
      bodyLarge: base.bodyLarge?.copyWith(fontFamily: 'NotoSans'),
      bodyMedium: base.bodyMedium?.copyWith(fontFamily: 'NotoSans'),
      bodySmall: base.bodySmall?.copyWith(fontFamily: 'NotoSans'),
      labelLarge: base.labelLarge?.copyWith(fontFamily: 'NotoSans', fontWeight: FontWeight.w600),
      labelMedium: base.labelMedium?.copyWith(fontFamily: 'NotoSans'),
      labelSmall: base.labelSmall?.copyWith(fontFamily: 'NotoSans'),
    );
  }

  static AppBarTheme _appBarTheme(ThemeData base) => AppBarTheme(
    elevation: 0,
    centerTitle: false,
    scrolledUnderElevation: 2,
    backgroundColor: base.colorScheme.surface,
    foregroundColor: base.colorScheme.onSurface,
  );

  static CardThemeData _cardTheme() => const CardThemeData(
    elevation: 1,
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
    ),
  );

  static InputDecorationTheme _inputDecorationTheme(ThemeData base) =>
      InputDecorationTheme(
        filled: true,
        fillColor: base.colorScheme.surfaceContainerHighest.withOpacity(0.4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: base.colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: base.colorScheme.outline.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: base.colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: base.colorScheme.error),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        isDense: true,
      );

  static ElevatedButtonThemeData _elevatedButtonTheme(ThemeData base) =>
      ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 1,
        ),
      );

  static OutlinedButtonThemeData _outlinedButtonTheme(ThemeData base) =>
      OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );

  static TextButtonThemeData _textButtonTheme(ThemeData base) =>
      TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );

  static ChipThemeData _chipTheme(ThemeData base) => ChipThemeData(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    side: BorderSide.none,
  );
}

// ── Custom theme extension ───────────────────────────────────────────────────

class AppColours extends ThemeExtension<AppColours> {
  final Color warning;
  final Color success;
  final Color criticalBg;
  final Color criticalFg;

  const AppColours({
    required this.warning,
    required this.success,
    required this.criticalBg,
    required this.criticalFg,
  });

  @override
  AppColours copyWith({
    Color? warning,
    Color? success,
    Color? criticalBg,
    Color? criticalFg,
  }) {
    return AppColours(
      warning: warning ?? this.warning,
      success: success ?? this.success,
      criticalBg: criticalBg ?? this.criticalBg,
      criticalFg: criticalFg ?? this.criticalFg,
    );
  }

  @override
  AppColours lerp(AppColours? other, double t) {
    if (other is! AppColours) return this;
    return AppColours(
      warning: Color.lerp(warning, other.warning, t)!,
      success: Color.lerp(success, other.success, t)!,
      criticalBg: Color.lerp(criticalBg, other.criticalBg, t)!,
      criticalFg: Color.lerp(criticalFg, other.criticalFg, t)!,
    );
  }
}

extension AppColoursX on BuildContext {
  AppColours get appColours =>
      Theme.of(this).extension<AppColours>() ??
      const AppColours(
        warning: Color(0xFFE65100),
        success: Color(0xFF2E7D32),
        criticalBg: Color(0xFFFFEBEE),
        criticalFg: Color(0xFFB00020),
      );
}

