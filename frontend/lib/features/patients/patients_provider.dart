import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hospital_management/core/auth/session_service.dart';
import 'package:hospital_management/data/database/app_database.dart';
import 'package:hospital_management/data/remote/backend_api_client.dart';
import 'package:hospital_management/data/remote/hms_sync_service.dart';
import 'package:hospital_management/data/repositories/patient_repository_impl.dart';
import 'package:hospital_management/domain/entities/patient.dart';
import 'package:hospital_management/domain/entities/patient_allergy.dart';
import 'package:hospital_management/domain/repositories/patient_repository.dart';
import 'package:hospital_management/core/auth/online_hospital_session.dart';
import 'package:hospital_management/data/remote/patient_api_client.dart';
import 'package:hospital_management/data/sync/patient_sync_coordinator.dart';

// ── Repository provider ────────────────────────────────────────────────────

/// Provides the singleton [PatientRepository] backed by [AppDatabase].
final patientRepositoryProvider = Provider<PatientRepository>((ref) {
  return PatientRepositoryImpl(AppDatabase.instance);
});

final patientSyncCoordinatorProvider = Provider<PatientSyncCoordinator>((ref) {
  return PatientSyncCoordinator(
    AppDatabase.instance,
    ref.read(patientApiClientProvider),
    ref.read(onlineHospitalSessionProvider.notifier),
  );
});

Future<void> _syncIfOnline(Ref ref) async {
  if (!ref.read(onlineHospitalSessionProvider).isAuthenticated) return;
  try {
    final result = await ref.read(patientSyncCoordinatorProvider).synchronize();
    if (result.blocked)
      throw PatientSyncBlockedException(
          result.error ?? 'Hospital authorization is required.');
  } catch (_) {
    rethrow;
  }
}

// ── Search / list providers ────────────────────────────────────────────────

/// Holds the current search query string for the patient list screen.
final patientSearchQueryProvider = StateProvider<String>((ref) => '');

/// Current page index (0-based) for patient list pagination.
final patientListPageProvider = StateProvider<int>((ref) => 0);

const _kPageSize = 20;

/// Provides the paginated, searched list of patients.
///
/// Automatically re-fetches when [patientSearchQueryProvider] or
/// [patientListPageProvider] changes.
final patientListProvider =
    FutureProvider.autoDispose<List<Patient>>((ref) async {
  final online = ref.watch(onlineHospitalSessionProvider).isAuthenticated;
  if (online) {
    try {
      await ref.read(patientSyncCoordinatorProvider).synchronize();
    } catch (_) {
      // A server outage does not block the local offline-first patient list.
    }
  }
  final query = ref.watch(patientSearchQueryProvider);
  final page = ref.watch(patientListPageProvider);
  final repo = ref.read(patientRepositoryProvider);

  if (query.isEmpty) {
    return repo.getAll(limit: _kPageSize, offset: page * _kPageSize);
  }
  return repo.search(query, limit: _kPageSize, offset: page * _kPageSize);
});

// ── Single patient providers ───────────────────────────────────────────────

/// Fetches a single patient by ID. Suitable for profile / edit screens.
final selectedPatientProvider =
    FutureProvider.family.autoDispose<Patient?, int>((ref, id) async {
  final repo = ref.read(patientRepositoryProvider);
  return repo.findById(id);
});

/// Fetches allergies for the given patient ID.
final patientAllergiesProvider = FutureProvider.family
    .autoDispose<List<PatientAllergy>, int>((ref, patientId) async {
  final repo = ref.read(patientRepositoryProvider);
  return repo.getAllergies(patientId);
});

// ── Mutation notifier ──────────────────────────────────────────────────────

/// Encapsulates create / update / soft-delete operations so the UI can
/// observe loading / error state without coupling to async directly.
class PatientMutationNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  PatientRepository get _repo => ref.read(patientRepositoryProvider);

  Future<Patient> createPatient(Patient patient) async {
    state = const AsyncLoading();
    try {
      final created = await _repo.create(patient);
      ref.invalidate(patientListProvider);
      await _syncIfOnline(ref);
      state = const AsyncData(null);
      return created;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<Patient> updatePatient(Patient patient) async {
    state = const AsyncLoading();
    try {
      final updated = await _repo.update(patient);
      ref.invalidate(patientListProvider);
      ref.invalidate(selectedPatientProvider(patient.id));
      await _syncIfOnline(ref);
      state = const AsyncData(null);
      return updated;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> deletePatient(int id) async {
    state = const AsyncLoading();
    try {
      await _repo.softDelete(id);
      ref.invalidate(patientListProvider);
      await _syncIfOnline(ref);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> setPatientStatus(int id, String status) async {
    state = const AsyncLoading();
    try {
      await _repo.changeStatus(id, status);
      ref.invalidate(patientListProvider);
      ref.invalidate(selectedPatientProvider(id));
      await _syncIfOnline(ref);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

final patientMutationProvider =
    AsyncNotifierProvider<PatientMutationNotifier, void>(
        PatientMutationNotifier.new);

// ── Allergy mutation notifier ──────────────────────────────────────────────

class AllergyMutationNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  PatientRepository get _repo => ref.read(patientRepositoryProvider);

  Future<void> addAllergy(PatientAllergy allergy) async {
    state = const AsyncLoading();
    try {
      await _repo.addAllergy(allergy);
      state = const AsyncData(null);
      ref.invalidate(patientAllergiesProvider(allergy.patientId));
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> deleteAllergy(int allergyId, int patientId) async {
    state = const AsyncLoading();
    try {
      await _repo.deleteAllergy(allergyId);
      state = const AsyncData(null);
      ref.invalidate(patientAllergiesProvider(patientId));
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

final allergyMutationProvider =
    AsyncNotifierProvider<AllergyMutationNotifier, void>(
        AllergyMutationNotifier.new);
