import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hospital_management/data/database/app_database.dart';
import 'package:hospital_management/data/remote/backend_api_client.dart';

class SyncStatusInfo {
  const SyncStatusInfo({
    required this.isSyncing,
    required this.isConfigured,
    required this.pendingCount,
    required this.failedCount,
    this.lastSyncedAt,
    this.lastError,
  });

  final bool isSyncing;
  final bool isConfigured;
  final int pendingCount;
  final int failedCount;
  final String? lastSyncedAt;
  final String? lastError;

  bool get hasIssues =>
      failedCount > 0 || (lastError != null && lastError!.isNotEmpty);
  bool get isClean => pendingCount == 0 && failedCount == 0;
}

class HmsSyncService {
  HmsSyncService(this._database, this._api);

  static bool _isSyncing = false;

  final AppDatabase _database;
  final BackendApiClient _api;

  bool get isSyncing => _isSyncing;

  Future<SyncStatusInfo> getStatus() async {
    final pending = await _database.hmsDao.getPendingSyncCount();
    final failed = await _database.hmsDao.getFailedSyncCount();
    final lastSync = await _database.getSetting('last_synced_at');
    final lastErr = await _database.getSetting('last_sync_error');

    return SyncStatusInfo(
      isSyncing: _isSyncing,
      isConfigured: _api.isConfigured,
      pendingCount: pending,
      failedCount: failed,
      lastSyncedAt: lastSync,
      lastError: lastErr,
    );
  }

  Future<List<String>> syncPending() async {
    if (!_api.isConfigured || _isSyncing) return const [];
    _isSyncing = true;
    try {
      final operations = await _database.hmsDao.getPendingSyncOperations();
      final errors = <String>[];
      for (final operation in operations) {
        final operationId = operation['operation_id'] as String;
        try {
          final method = (operation['method'] as String).toUpperCase();
          final path = operation['path'] as String;
          final payload =
              jsonDecode(operation['payload_json'] as String) as Object?;

          if (method == 'POST') {
            await _api.post(path, body: payload, idempotencyKey: operationId);
          } else if (method == 'PUT') {
            await _api.put(path, body: payload);
          } else if (method == 'DELETE') {
            await _api.delete(path);
          } else {
            throw BackendApiException('Unsupported sync method: $method');
          }
          await _api.post(path, body: payload, idempotencyKey: operationId);
          await _database.hmsDao.markSyncOperationComplete(operationId);
        } on BackendConnectionException {
          errors.add('Saved locally; waiting for online connection.');
          await _database.saveSetting(
              'last_sync_error', 'Connection unavailable');
          break;
        } on BackendApiException catch (error) {
          // If conflict/already exists (e.g. 409), treat as completed to avoid blocking the queue
          if (error.statusCode == 409 ||
              error.message.toLowerCase().contains('already exists')) {
            await _database.hmsDao.markSyncOperationComplete(operationId);
          } else {
            await _database.hmsDao
                .markSyncOperationFailed(operationId, error.message);
            errors.add(error.message);
            await _database.saveSetting('last_sync_error', error.message);
          }
        } on FormatException catch (error) {
          await _database.hmsDao
              .markSyncOperationFailed(operationId, error.message);
          errors.add('Invalid queued request: ${error.message}');
          await _database.saveSetting('last_sync_error', error.message);
        } catch (e) {
          await _database.hmsDao
              .markSyncOperationFailed(operationId, e.toString());
          errors.add(e.toString());
          await _database.saveSetting('last_sync_error', e.toString());
        }
      }

      if (errors.isEmpty) {
        final nowIso = DateTime.now().toLocal().toIso8601String();
        await _database.saveSetting('last_synced_at', nowIso);
        await _database.saveSetting('last_sync_error', '');
      }
      return errors;
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> retryFailedOperations() async {
    await _database.hmsDao.retryAllFailedSyncOperations();
    await syncPending();
  }

  Future<List<String>> syncAll() async {
    final errors = await syncPending();
    if (errors.isEmpty && _api.isConfigured) {
      try {
        await pullLatestChanges();
      } catch (e) {
        debugPrint('Pull sync notice: $e');
      }
    }
    return errors;
  }

  Future<void> pullLatestChanges() async {
    if (!_api.isConfigured) return;
    try {
      // 1. Pull latest bed states
      final bedsRes = await _api.get('/api/admissions/beds');
      if (bedsRes is List) {
        for (final item in bedsRes) {
          if (item is Map) {
            final bedNo = item['bedNumber']?.toString();
            final status = item['status']?.toString();
            if (bedNo != null && status != null) {
              await _database.customStatement('''
                UPDATE beds SET status = '${status.trim().toLowerCase() == "occupied" ? "Occupied" : (status.trim().toLowerCase() == "cleaning" ? "Cleaning" : "Available")}'
                WHERE bed_no = '${bedNo.replaceAll("'", "''")}'
              ''');
            }
          }
        }
      }
    } on BackendConnectionException {
      // Offline, ignore
    } catch (e) {
      debugPrint('Background pull notice: $e');
    }
  }

  Timer? _autoSyncTimer;

  void startAutoSync({Duration interval = const Duration(seconds: 15)}) {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = Timer.periodic(interval, (_) async {
      if (_api.isConfigured && !_isSyncing) {
        try {
          final pending = await _database.hmsDao.getPendingSyncCount();
          if (pending > 0) {
            await syncAll();
          } else {
            await pullLatestChanges();
          }
        } catch (_) {}
      }
    });
  }

  void stopAutoSync() {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = null;
  }
}

class SyncStatusNotifier extends StateNotifier<AsyncValue<SyncStatusInfo>> {
  SyncStatusNotifier(this._syncService) : super(const AsyncLoading()) {
    refresh();
    _syncService.startAutoSync();
  }

  @override
  void dispose() {
    _syncService.stopAutoSync();
    super.dispose();
  }

  final HmsSyncService _syncService;

  Future<void> refresh() async {
    try {
      final status = await _syncService.getStatus();
      state = AsyncData(status);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<List<String>> triggerSync() async {
    final current = state.value;
    if (current != null) {
      state = AsyncData(SyncStatusInfo(
        isSyncing: true,
        isConfigured: current.isConfigured,
        pendingCount: current.pendingCount,
        failedCount: current.failedCount,
        lastSyncedAt: current.lastSyncedAt,
        lastError: current.lastError,
      ));
    }
    final errors = await _syncService.syncAll();
    await refresh();
    return errors;
  }

  Future<void> retryFailed() async {
    await _syncService.retryFailedOperations();
    await refresh();
  }
}

final hmsSyncServiceProvider = Provider<HmsSyncService>((ref) {
  return HmsSyncService(
    ref.watch(appDatabaseProvider),
    ref.watch(backendApiClientProvider),
  );
});

final syncStatusNotifierProvider =
    StateNotifierProvider<SyncStatusNotifier, AsyncValue<SyncStatusInfo>>(
        (ref) {
  return SyncStatusNotifier(ref.watch(hmsSyncServiceProvider));
});
