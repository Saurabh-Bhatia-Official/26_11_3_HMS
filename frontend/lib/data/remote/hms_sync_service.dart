import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hospital_management/data/database/app_database.dart';
import 'package:hospital_management/data/remote/backend_api_client.dart';

class HmsSyncService {
  const HmsSyncService(this._database, this._api);

  static bool _isSyncing = false;

  final AppDatabase _database;
  final BackendApiClient _api;

  Future<List<String>> syncPending() async {
    if (!_api.isConfigured || _isSyncing) return const [];
    _isSyncing = true;
    try {
      final operations = await _database.hmsDao.getPendingSyncOperations();
      final errors = <String>[];
      for (final operation in operations) {
        final operationId = operation['operation_id'] as String;
        try {
          final method = operation['method'] as String;
          final path = operation['path'] as String;
          final payload =
              jsonDecode(operation['payload_json'] as String) as Object?;
          if (method != 'POST') {
            throw const BackendApiException(
                'This queued operation type is not supported yet.');
          }
          await _api.post(path, body: payload, idempotencyKey: operationId);
          await _database.hmsDao.markSyncOperationComplete(operationId);
        } on BackendConnectionException {
          errors.add('Saved locally; waiting for a backend connection.');
          break;
        } on BackendApiException catch (error) {
          await _database.hmsDao
              .markSyncOperationFailed(operationId, error.message);
          errors.add(error.message);
        } on FormatException catch (error) {
          await _database.hmsDao
              .markSyncOperationFailed(operationId, error.message);
          errors.add('Invalid queued request: ${error.message}');
        }
      }
      return errors;
    } finally {
      _isSyncing = false;
    }
  }
}

final hmsSyncServiceProvider = Provider<HmsSyncService>((ref) {
  return HmsSyncService(
    ref.watch(appDatabaseProvider),
    ref.watch(backendApiClientProvider),
  );
});
