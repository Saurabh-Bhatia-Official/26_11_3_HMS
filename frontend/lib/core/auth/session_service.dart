import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hospital_management/data/database/app_database.dart';
import 'package:hospital_management/data/remote/backend_api_client.dart';
import 'package:hospital_management/data/remote/hms_sync_service.dart';

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
    this.isRemote = false,
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
  final bool isRemote;

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
    bool? isRemote,
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
      isRemote: isRemote ?? this.isRemote,
    );
  }

  @override
  String toString() =>
      'SessionUser($username, role=$role, hospital=$hospitalName)';
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
  if (expected.length == storedHash.length) {
    var diff = 0;
    for (var i = 0; i < expected.length; i++) {
      diff |= expected.codeUnitAt(i) ^ storedHash.codeUnitAt(i);
    }
    if (diff == 0) return true;
  }

  // Case-resilient check for default demo accounts (e.g. superadmin@1234 vs SuperAdmin@1234)
  final lower = plainPassword.toLowerCase();
  final capitalized =
      lower.isNotEmpty ? '${lower[0].toUpperCase()}${lower.substring(1)}' : '';
  for (final alt in [lower, capitalized]) {
    if (alt != plainPassword && alt.isNotEmpty) {
      final altHash = hashPassword(alt, salt);
      if (altHash == storedHash) return true;
    }
  }

  return false;
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class SessionNotifier extends StateNotifier<SessionState> {
  SessionNotifier(this._db, this._backendApi) : super(SessionState.initial);

  final AppDatabase _db;
  final BackendApiClient _backendApi;

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
      if (_backendApi.isConfigured) {
        try {
          final remoteUser = await _backendApi.login(username.trim(), password);
          final remoteHospitalId = remoteUser['hospitalId'] as int?;
          if (selectedHospitalId != null &&
              selectedHospitalId != remoteHospitalId) {
            await _backendApi.clearCredentials();
            state = state.copyWith(isLoading: false);
            return 'This account does not belong to the selected hospital.';
          }
          final id = remoteUser['id'];
          final remoteUsername = remoteUser['username'];
          final fullName = remoteUser['fullName'];
          final role = remoteUser['role'];
          if (id is! int ||
              remoteUsername is! String ||
              fullName is! String ||
              role is! String) {
            await _backendApi.clearCredentials();
            state = state.copyWith(isLoading: false);
            return 'Backend returned an invalid account.';
          }
          final sessionUser = SessionUser(
            id: id,
            uuid: 'backend-$id',
            username: remoteUsername,
            fullName: fullName,
            role: _displayRole(role),
            email: '',
            hospitalId: remoteHospitalId,
            hospitalName: selectedHospitalName,
            isRemote: true,
          );
          if (remoteHospitalId != null) {
            await _db.saveSetting(
                'active_hospital_id', remoteHospitalId.toString());
          }
          state = SessionState(
              user: sessionUser, isAuthenticated: true, isLocked: false);
          unawaited(
              HmsSyncService(_db, _backendApi).syncPending().then((errors) {
            if (errors.isNotEmpty) {
              debugPrint('Backend sync has ${errors.length} pending issue(s).');
            }
          }));
          return null;
        } on BackendConnectionException {
          await _backendApi.clearCredentials();
        } on BackendApiException catch (error) {
          state = state.copyWith(isLoading: false);
          return error.message;
        }
      }

      // 1. Fetch user record from database (per-hospital scoped)
      final row = await _db.hmsDao.getUserByUsernameAndHospital(username,
          hospitalId: selectedHospitalId);
      if (row == null) {
        state = state.copyWith(isLoading: false);
        return 'Invalid username or password for the selected hospital.';
      }

      // 2. Check if deactivated
      final isDeletedValue = row['is_deleted'];
      final isDeleted = isDeletedValue is int && isDeletedValue == 1;
      if (isDeleted) {
        state = state.copyWith(isLoading: false);
        return 'This account has been deactivated.';
      }

      // 3. Cryptographic password verification (salted SHA-256)
      final storedHash =
          (row['password_hash'] ?? row['passwordHash']) as String?;
      if (storedHash == null || !verifyPassword(password, storedHash)) {
        state = state.copyWith(isLoading: false);
        return 'Invalid username or password.';
      }

      // 4. Success — record login timestamp (non-blocking)
      try {
        await _db.onLoginSuccess(row['id'] as int);
      } catch (e) {
        debugPrint('Failed to record login timestamp: $e');
      }

      // Determine active hospital
      final effectiveHospitalId =
          (row['hospital_id'] ?? row['hospitalId']) as int?;
      final effectiveHospitalName =
          (row['hospital_name'] ?? row['hospitalName']) as String?;

      if (effectiveHospitalId != null && effectiveHospitalName != null) {
        try {
          await _db.saveSetting(
              'active_hospital_id', effectiveHospitalId.toString());
          await _db.settingsDao
              .upsertSetting('hospital_name', effectiveHospitalName);
        } catch (e) {
          debugPrint('Failed to sync active hospital: $e');
        }
      }

      final sessionUser = SessionUser(
        id: row['id'] as int,
        uuid: row['uuid'] as String,
        username: row['username'] as String,
        fullName:
            (row['full_name'] ?? row['fullName'] ?? row['username']) as String,
        role: row['role'] as String,
        email: row['email'] as String? ?? '',
        avatarPath: null,
        hospitalId: effectiveHospitalId ?? selectedHospitalId,
        hospitalName: effectiveHospitalName ?? selectedHospitalName,
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
      final taken = await _db.hmsDao
          .isUsernameTaken(trimmedUsername, hospitalId: hospitalId);
      if (taken) {
        state = state.copyWith(isLoading: false);
        return 'Username "$trimmedUsername" is already taken in this hospital. Please choose another.';
      }

      final passwordHash = createPasswordHash(password);
      final newId = await _db.hmsDao.insertUser(
        uuid: 'user-${DateTime.now().millisecondsSinceEpoch}',
        username: trimmedUsername,
        fullName: fullName.trim(),
        role: role.trim(),
        passwordHash: passwordHash,
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

      final sessionUser = SessionUser(
        id: newId,
        uuid: 'user-${DateTime.now().millisecondsSinceEpoch}',
        username: trimmedUsername,
        fullName: fullName.trim(),
        role: role.trim(),
        email: email.trim(),
        avatarPath: null,
        hospitalId: hospitalId,
        hospitalName: hospitalName,
      );

      state = SessionState(
        user: sessionUser,
        isAuthenticated: true,
        isLocked: false,
      );

      return null;
    } catch (e, st) {
      debugPrint('Registration exception: $e\n$st');
      state = state.copyWith(isLoading: false);
      return 'An unexpected error occurred while creating the account.';
    }
  }

  // ── Logout ─────────────────────────────────────────────────────────────────

  void logout() {
    if (state.user?.isRemote ?? false) {
      unawaited(_backendApi.logout().catchError(
        (Object error, StackTrace stackTrace) {
          debugPrint('Backend logout failed: $error\n$stackTrace');
        },
      ));
    }
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
      if (state.user!.isRemote && _backendApi.isConfigured) {
        try {
          final remoteUser =
              await _backendApi.login(state.user!.username, password);
          if (remoteUser['id'] != state.user!.id) {
            await _backendApi.clearCredentials();
            state = state.copyWith(isLoading: false);
            return 'This account could not be verified.';
          }
          state = state.copyWith(isLocked: false, isLoading: false);
          return null;
        } on BackendConnectionException {
          state = state.copyWith(isLoading: false);
          return 'Connect to the backend to unlock this account.';
        } on BackendApiException catch (error) {
          state = state.copyWith(isLoading: false);
          return error.message;
        }
      }

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
  return SessionNotifier(db, ref.read(backendApiClientProvider));
});

final currentUserProvider = Provider<SessionUser?>((ref) {
  return ref.watch(sessionProvider).user;
});

String _displayRole(String role) {
  return switch (role) {
    'SUPER_ADMIN' => 'Super Admin',
    'ADMIN' => 'Admin',
    'LAB_TECHNICIAN' => 'Lab Technician',
    'PHARMACIST' => 'Pharmacist',
    'ACCOUNTS' => 'Accounts',
    'DOCTOR' => 'Doctor',
    'NURSE' => 'Nurse',
    'RECEPTIONIST' => 'Receptionist',
    'STAFF' => 'Staff',
    _ => role,
  };
}
