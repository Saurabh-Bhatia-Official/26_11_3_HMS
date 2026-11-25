import 'dart:convert';

import 'package:hospital_management/core/auth/online_hospital_session.dart';
import 'package:hospital_management/data/database/app_database.dart';
import 'package:hospital_management/data/database/daos/patient_sync_dao.dart';
import 'package:hospital_management/data/remote/hospital_api_client.dart';
import 'package:hospital_management/data/remote/patient_api_client.dart';

class PatientSyncResult {
  const PatientSyncResult(
      {this.acknowledged = 0, this.blocked = false, this.error});
  final int acknowledged;
  final bool blocked;
  final String? error;
}

class PatientSyncBlockedException implements Exception {
  const PatientSyncBlockedException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Drains the durable local outbox only when an authenticated online session exists.
/// The local patient row is retained until an individual server acknowledgement.
class PatientSyncCoordinator {
  PatientSyncCoordinator(this._db, this._api, this._session);

  final AppDatabase _db;
  final PatientApiClient _api;
  final OnlineHospitalSessionNotifier _session;
  bool _running = false;

  PatientSyncDao get _sync => _db.patientSyncDao;

  Future<PatientSyncResult> synchronize() async {
    if (_running || !_session.state.isAuthenticated)
      return const PatientSyncResult();
    _running = true;
    var acknowledged = 0;
    try {
      await _sync.requeueAuthorizationBlocked();
      for (final entry in await _sync.pending()) {
        if (await _sync.hasDuplicateLocalUuid(entry.patientUuid)) {
          await _sync.markFailure(
            entry: entry,
            state: 'CONFLICT',
            errorCode: 'DUPLICATE_LOCAL_UUID',
            updatedAt: DateTime.now().toIso8601String(),
          );
          continue;
        }
        try {
          if (await _send(entry)) acknowledged++;
        } on HospitalApiException catch (error) {
          final blocked = error.statusCode == 401 || error.statusCode == 403;
          final conflict = error.statusCode == 409;
          await _sync.markFailure(
            entry: entry,
            state:
                blocked ? 'BLOCKED_AUTH' : (conflict ? 'CONFLICT' : 'PENDING'),
            errorCode: blocked
                ? 'MEMBERSHIP_OR_SESSION_REQUIRED'
                : (conflict ? 'SERVER_VERSION_CONFLICT' : 'SERVER_UNAVAILABLE'),
            updatedAt: DateTime.now().toIso8601String(),
          );
          if (blocked)
            return PatientSyncResult(
              acknowledged: acknowledged,
              blocked: true,
              error:
                  'Saved on this device. Sync requires an active Hospital membership.',
            );
        } catch (_) {
          await _sync.markFailure(
            entry: entry,
            state: 'PENDING',
            errorCode: 'NETWORK_UNAVAILABLE',
            updatedAt: DateTime.now().toIso8601String(),
          );
          return PatientSyncResult(
            acknowledged: acknowledged,
            error:
                'Patient data remains saved on this device and will retry when online.',
          );
        }
      }
      await _pullServerPatients();
      return PatientSyncResult(acknowledged: acknowledged);
    } finally {
      _running = false;
    }
  }

  Future<bool> _send(PatientSyncOutboxEntry entry) async {
    final body = jsonDecode(entry.payload) as Map<String, dynamic>;
    switch (entry.operation) {
      case 'CREATE':
        final result = await _withToken((token) => _api.create(token, body));
        await _ack(entry, result);
        return true;
      case 'UPDATE':
        final version =
            await _sync.serverVersion(entry.patientUuid) ?? entry.baseVersion;
        if (version == null) {
          await _sync.markFailure(
            entry: entry,
            state: 'CONFLICT',
            errorCode: 'SERVER_BASE_MISSING',
            updatedAt: DateTime.now().toIso8601String(),
          );
          return false;
        }
        final result = await _withToken((token) => _api
            .update(token, entry.patientUuid, {...body, 'version': version}));
        await _ack(entry, result);
        return true;
      case 'STATUS':
        final version =
            await _sync.serverVersion(entry.patientUuid) ?? entry.baseVersion;
        if (version == null) {
          await _sync.markFailure(
            entry: entry,
            state: 'CONFLICT',
            errorCode: 'SERVER_BASE_MISSING',
            updatedAt: DateTime.now().toIso8601String(),
          );
          return false;
        }
        final result = await _withToken((token) => _api.changeStatus(
              token,
              entry.patientUuid,
              body['status'] as String,
              version,
            ));
        await _ack(entry, result);
        return true;
      case 'ARCHIVE':
        await _withToken((token) => _api.archive(token, entry.patientUuid));
        await _sync.acknowledgeArchive(entry.operationId, entry.patientUuid);
        return true;
      default:
        await _sync.markFailure(
          entry: entry,
          state: 'CONFLICT',
          errorCode: 'UNSUPPORTED_OPERATION',
          updatedAt: DateTime.now().toIso8601String(),
        );
        return false;
    }
  }

  Future<T> _withToken<T>(Future<T> Function(String token) request) async {
    var token = await _session.accessTokenForApi();
    if (token == null)
      throw const HospitalApiException('Active Hospital session required.',
          statusCode: 401);
    try {
      return await request(token);
    } on HospitalApiException catch (error) {
      if (error.statusCode != 401) rethrow;
      token = await _session.refreshAccessTokenForApi();
      if (token == null) rethrow;
      return request(token);
    }
  }

  Future<void> _ack(
          PatientSyncOutboxEntry entry, PatientServerRecord response) =>
      _sync.acknowledge(
        operationId: entry.operationId,
        patientUuid: entry.patientUuid,
        serverPatientId: response.id,
        canonicalUhid: response.uhid,
        serverVersion: response.version,
        serverStatus: response.status,
        updatedAt: DateTime.now().toIso8601String(),
      );

  Future<void> _pullServerPatients() async {
    var page = 0;
    var totalPages = 1;
    while (page < totalPages) {
      final result = await _withToken((token) => _api.list(token, page: page));
      final rows = result['items'];
      if (rows is! List) throw const FormatException('Invalid Patient page');
      for (final row in rows) {
        if (row is Map<String, dynamic>) await _sync.applyRemoteSnapshot(row);
      }
      totalPages = (result['totalPages'] as num?)?.toInt() ?? 1;
      page++;
    }
  }
}
