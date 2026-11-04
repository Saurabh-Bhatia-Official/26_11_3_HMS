import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hospital_management/data/database/app_database.dart';

// ---------------------------------------------------------------------------
// Domain model
// ---------------------------------------------------------------------------

/// Lightweight in-memory representation of the logged-in user.
class SessionUser {
  const SessionUser({
    required this.id,
    required this.uuid,
    required this.username,
    required this.fullName,
    required this.role,
    required this.email,
    this.avatarPath,
    this.hospitalId,
    this.hospitalName,
  });

  final int id;
  final String uuid;
  final String username;
  final String fullName;
  final String role;
  final String email;
  final String? avatarPath;
  final int? hospitalId;
  final String? hospitalName;

  SessionUser copyWith({
    int? id,
    String? uuid,
    String? username,
    String? fullName,
    String? role,
    String? email,
    String? avatarPath,
    int? hospitalId,
    String? hospitalName,
  }) {
    return SessionUser(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      email: email ?? this.email,
      avatarPath: avatarPath ?? this.avatarPath,
      hospitalId: hospitalId ?? this.hospitalId,
      hospitalName: hospitalName ?? this.hospitalName,
    );
  }

  @override
  String toString() => 'SessionUser($username, role=$role, hospital=$hospitalName)';
}

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class SessionState {
  const SessionState({
    this.user,
    this.isAuthenticated = false,
    this.isLocked = false,
    this.errorMessage,
    this.isLoading = false,
  });

  final SessionUser? user;
  final bool isAuthenticated;
  final bool isLocked;
  final String? errorMessage;
  final bool isLoading;

  SessionState copyWith({
    SessionUser? user,
    bool? isAuthenticated,
    bool? isLocked,
    String? errorMessage,
    bool clearError = false,
    bool? isLoading,
  }) {
    return SessionState(
      user: user ?? this.user,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLocked: isLocked ?? this.isLocked,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isLoading: isLoading ?? this.isLoading,
    );
  }

  static const SessionState initial = SessionState();
}

// ---------------------------------------------------------------------------
// Password hashing helpers
// ---------------------------------------------------------------------------

/// Generates a cryptographically random hex salt of [length] bytes.
String _generateSalt({int length = 16}) {
  final rng = Random.secure();
  final bytes = List<int>.generate(length, (_) => rng.nextInt(256));
  return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}

/// Hashes [password] with [salt] using SHA-256.
///
/// Storage format: `"<salt>:<sha256(salt + password)>"`
String hashPassword(String password, String salt) {
  final input = utf8.encode(salt + password);
  final digest = sha256.convert(input);
  return '$salt:${digest.toString()}';
}

/// Creates a new salted hash for [password] (use when creating/resetting).
String createPasswordHash(String password) {
  final salt = _generateSalt();
  return hashPassword(password, salt);
}

/// Verifies [plainPassword] against a stored [storedHash] of the form
/// `"<salt>:<sha256>"`.
bool verifyPassword(String plainPassword, String storedHash) {
  final parts = storedHash.split(':');
  if (parts.length != 2) return false;
  final salt = parts[0];
  final expected = hashPassword(plainPassword, salt);
  // Constant-time comparison to avoid timing attacks.
  if (expected.length != storedHash.length) return false;
  var diff = 0;
  for (var i = 0; i < expected.length; i++) {
    diff |= expected.codeUnitAt(i) ^ storedHash.codeUnitAt(i);
  }
  return diff == 0;
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class SessionNotifier extends StateNotifier<SessionState> {
  SessionNotifier(this._db) : super(SessionState.initial);

  final AppDatabase _db;

  // ── Login ──────────────────────────────────────────────────────────────────

  /// Attempts to authenticate [username] with [password].
  ///
  /// Returns `null` on success, or a clear error string on failure.
  /// Account locking and attempt counters are disabled per system policy.
  Future<String?> login(
    String username,
    String password, {
    int? selectedHospitalId,
    String? selectedHospitalName,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      // 1. Fetch user record from database
      final row = await _db.getUserByUsername(username);
      if (row == null) {
        state = state.copyWith(isLoading: false);
        return 'Invalid username or password.';
      }

      // 2. Check if deactivated
      if (row.isDeleted) {
        state = state.copyWith(isLoading: false);
        return 'This account has been deactivated.';
      }

      // 3. Cryptographic password verification (salted SHA-256)
      final valid = verifyPassword(password, row.passwordHash);
      if (!valid) {
        state = state.copyWith(isLoading: false);
        return 'Invalid username or password.';
      }

      // 4. Success — record login timestamp (non-blocking)
      try {
        await _db.onLoginSuccess(row.id);
      } catch (e) {
        debugPrint('Failed to record login timestamp: $e');
      }

      // Determine active hospital
      final effectiveHospitalId = selectedHospitalId ?? row.hospitalId;
      final effectiveHospitalName = selectedHospitalName ?? row.hospitalName;

      if (effectiveHospitalId != null && effectiveHospitalName != null) {
        try {
          await _db.saveSetting('active_hospital_id', effectiveHospitalId.toString());
          await _db.settingsDao.upsertSetting('hospital_name', effectiveHospitalName);
        } catch (e) {
          debugPrint('Failed to sync active hospital: $e');
        }
      }

      final sessionUser = SessionUser(
        id: row.id,
        uuid: row.uuid,
        username: row.username,
        fullName: row.fullName,
        role: row.role,
        email: row.email,
        avatarPath: row.avatarPath,
        hospitalId: effectiveHospitalId,
        hospitalName: effectiveHospitalName,
      );

      state = SessionState(
        user: sessionUser,
        isAuthenticated: true,
        isLocked: false,
      );
      return null;
    } catch (e, st) {
      debugPrint('Login exception: $e\n$st');
      state = state.copyWith(isLoading: false);
      return 'An unexpected error occurred. Please try again.';
    }
  }

  // ── Register ───────────────────────────────────────────────────────────────

  /// Creates a new user account with specified hospital and role, and authenticates.
  Future<String?> registerUser({
    required String fullName,
    required String username,
    required String email,
    required String password,
    required String role,
    int? hospitalId,
    String? hospitalName,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final trimmedUsername = username.trim();
      final taken = await _db.isUsernameTaken(trimmedUsername);
      if (taken) {
        state = state.copyWith(isLoading: false);
        return 'Username "$trimmedUsername" is already taken. Please choose another.';
      }

      final passwordHash = createPasswordHash(password);
      await _db.createRegularUser(
        username: trimmedUsername,
        passwordHash: passwordHash,
        fullName: fullName.trim(),
        role: role.trim(),
        email: email.trim(),
        hospitalId: hospitalId,
        hospitalName: hospitalName,
      );

      // Synchronize active hospital if provided
      if (hospitalId != null && hospitalName != null) {
        try {
          await _db.saveSetting('active_hospital_id', hospitalId.toString());
          await _db.settingsDao.upsertSetting('hospital_name', hospitalName);
        } catch (e) {
          debugPrint('Failed to sync active hospital on register: $e');
        }
      }

      // Fetch newly created record
      final row = await _db.getUserByUsername(trimmedUsername);
      if (row != null) {
        final sessionUser = SessionUser(
          id: row.id,
          uuid: row.uuid,
          username: row.username,
          fullName: row.fullName,
          role: row.role,
          email: row.email,
          avatarPath: row.avatarPath,
          hospitalId: hospitalId ?? row.hospitalId,
          hospitalName: hospitalName ?? row.hospitalName,
        );

        state = SessionState(
          user: sessionUser,
          isAuthenticated: true,
          isLocked: false,
        );
      } else {
        state = state.copyWith(isLoading: false);
      }

      return null;
    } catch (e, st) {
      debugPrint('Registration exception: $e\n$st');
      state = state.copyWith(isLoading: false);
      return 'An unexpected error occurred while creating the account.';
    }
  }

  // ── Logout ─────────────────────────────────────────────────────────────────

  void logout() {
    state = SessionState.initial;
  }

  // ── Lock / Unlock ──────────────────────────────────────────────────────────

  /// Locks the session without clearing the user (auto-lock).
  void lock() {
    if (!state.isAuthenticated) return;
    state = state.copyWith(isLocked: true);
  }

  /// Unlocks using the current user's password.
  Future<String?> unlock(String password) async {
    if (state.user == null) return 'No active session.';

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final row = await _db.getUserByUsername(state.user!.username);
      if (row == null) {
        logout();
        return 'Session expired. Please log in again.';
      }

      final valid = verifyPassword(password, row.passwordHash);
      if (!valid) {
        state = state.copyWith(isLoading: false);
        return 'Incorrect password.';
      }

      state = state.copyWith(isLocked: false, isLoading: false);
      return null;
    } catch (_) {
      state = state.copyWith(isLoading: false);
      return 'An unexpected error occurred.';
    }
  }
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final sessionProvider =
    StateNotifierProvider<SessionNotifier, SessionState>((ref) {
  final db = ref.read(appDatabaseProvider);
  return SessionNotifier(db);
});

final currentUserProvider = Provider<SessionUser?>((ref) {
  return ref.watch(sessionProvider).user;
});
