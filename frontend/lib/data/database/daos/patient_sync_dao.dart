import 'package:drift/drift.dart';
import 'package:hospital_management/data/database/app_database.dart';

class PatientSyncDao extends DatabaseAccessor<AppDatabase> {
  PatientSyncDao(super.db);

  Future<bool> hasDuplicateLocalUuid(String uuid) async {
    final rows = await customSelect(
      'SELECT COUNT(*) AS row_count FROM patients WHERE uuid = ?',
      variables: [Variable<String>(uuid)],
    ).get();
    return rows.single.read<int>('row_count') > 1;
  }

  Future<void> enqueue({
    required String operationId,
    required String patientUuid,
    required String operation,
    required String payload,
    int? baseVersion,
    required String createdAt,
  }) async {
    await customStatement(
      'INSERT INTO patient_sync_outbox '
      '(operation_id, patient_uuid, operation, payload, base_version, created_at, attempt_count, state) '
      'VALUES (?, ?, ?, ?, ?, ?, 0, \'PENDING\')',
      [operationId, patientUuid, operation, payload, baseVersion, createdAt],
    );
    await customStatement(
      'INSERT INTO patient_sync_states (patient_uuid, sync_state, updated_at) VALUES (?, \'PENDING\', ?) '
      'ON CONFLICT(patient_uuid) DO UPDATE SET sync_state = \'PENDING\', last_error_code = NULL, updated_at = excluded.updated_at',
      [patientUuid, createdAt],
    );
  }

  Future<List<PatientSyncOutboxEntry>> pending() async {
    final rows = await customSelect(
      "SELECT * FROM patient_sync_outbox WHERE state = 'PENDING' ORDER BY created_at, operation_id",
    ).get();
    return rows
        .map((row) => PatientSyncOutboxEntry(
              operationId: row.read<String>('operation_id'),
              patientUuid: row.read<String>('patient_uuid'),
              operation: row.read<String>('operation'),
              payload: row.read<String>('payload'),
              baseVersion: row.read<int?>('base_version'),
            ))
        .toList();
  }

  Future<void> requeueAuthorizationBlocked() => customStatement(
        "UPDATE patient_sync_outbox SET state = 'PENDING', last_error_code = NULL WHERE state = 'BLOCKED_AUTH'",
      );

  Future<int?> serverVersion(String uuid) async {
    final row = await customSelect(
      'SELECT server_version FROM patient_sync_states WHERE patient_uuid = ?',
      variables: [Variable<String>(uuid)],
    ).getSingleOrNull();
    return row?.read<int?>('server_version');
  }

  Future<String?> canonicalUhid(String uuid) async {
    final row = await customSelect(
      'SELECT canonical_uhid FROM patient_sync_states WHERE patient_uuid = ?',
      variables: [Variable<String>(uuid)],
    ).getSingleOrNull();
    return row?.read<String?>('canonical_uhid');
  }

  Future<String?> syncState(String uuid) async {
    final row = await customSelect(
      'SELECT sync_state FROM patient_sync_states WHERE patient_uuid = ?',
      variables: [Variable<String>(uuid)],
    ).getSingleOrNull();
    return row?.read<String?>('sync_state');
  }

  Future<void> acknowledge({
    required String operationId,
    required String patientUuid,
    required int serverPatientId,
    required String canonicalUhid,
    required int serverVersion,
    required String serverStatus,
    required String updatedAt,
  }) async {
    await transaction(() async {
      await customStatement(
        'DELETE FROM patient_sync_outbox WHERE operation_id = ?',
        [operationId],
      );
      await customStatement(
        'INSERT INTO patient_sync_states '
        '(patient_uuid, server_patient_id, canonical_uhid, server_version, server_status, sync_state, last_error_code, updated_at) '
        'VALUES (?, ?, ?, ?, ?, \'SYNCED\', NULL, ?) '
        'ON CONFLICT(patient_uuid) DO UPDATE SET '
        'server_patient_id = excluded.server_patient_id, '
        'canonical_uhid = excluded.canonical_uhid, '
        'server_version = excluded.server_version, '
        'server_status = excluded.server_status, sync_state = \'SYNCED\', '
        'last_error_code = NULL, updated_at = excluded.updated_at',
        [
          patientUuid,
          serverPatientId,
          canonicalUhid,
          serverVersion,
          serverStatus,
          updatedAt
        ],
      );
    });
  }

  Future<void> markFailure({
    required PatientSyncOutboxEntry entry,
    required String state,
    required String errorCode,
    required String updatedAt,
  }) async {
    await transaction(() async {
      await customStatement(
        'UPDATE patient_sync_outbox SET state = ?, last_error_code = ?, attempt_count = attempt_count + 1 WHERE operation_id = ?',
        [state, errorCode, entry.operationId],
      );
      await customStatement(
        'INSERT INTO patient_sync_states '
        '(patient_uuid, sync_state, last_error_code, updated_at) VALUES (?, ?, ?, ?) '
        'ON CONFLICT(patient_uuid) DO UPDATE SET sync_state = excluded.sync_state, '
        'last_error_code = excluded.last_error_code, updated_at = excluded.updated_at',
        [entry.patientUuid, state, errorCode, updatedAt],
      );
    });
  }

  Future<int> countOutbox() async {
    final row = await customSelect(
      'SELECT COUNT(*) AS row_count FROM patient_sync_outbox',
    ).getSingle();
    return row.read<int>('row_count');
  }

  Future<void> acknowledgeArchive(
      String operationId, String patientUuid) async {
    await transaction(() async {
      await customStatement(
          'DELETE FROM patient_sync_outbox WHERE operation_id = ?',
          [operationId]);
      await customStatement(
        "UPDATE patient_sync_states SET sync_state = 'SYNCED', last_error_code = NULL, updated_at = ? WHERE patient_uuid = ?",
        [DateTime.now().toIso8601String(), patientUuid],
      );
    });
  }

  Future<void> applyRemoteSnapshot(Map<String, dynamic> patient) async {
    final uuid = patient['uuid'] as String;
    final existingRows = await customSelect(
      'SELECT id FROM patients WHERE uuid = ?',
      variables: [Variable<String>(uuid)],
    ).get();
    if (existingRows.length > 1) {
      await _upsertState(uuid, 'CONFLICT', 'DUPLICATE_LOCAL_UUID', patient);
      return;
    }
    final pendingRows = await customSelect(
      "SELECT COUNT(*) AS row_count FROM patient_sync_outbox WHERE patient_uuid = ? AND state <> 'ACKNOWLEDGED'",
      variables: [Variable<String>(uuid)],
    ).getSingle();
    if (pendingRows.read<int>('row_count') > 0) return;

    final now = DateTime.now().toIso8601String();
    final id = (patient['id'] as num).toInt();
    final canonicalUhid = patient['uhid'] as String;
    final localAlias = 'LOCAL-${uuid.replaceAll('-', '').substring(0, 20)}';
    final createdAt = (patient['createdAt'] as String?) ?? now;
    final updatedAt = (patient['updatedAt'] as String?) ?? now;
    await transaction(() async {
      if (existingRows.isEmpty) {
        await customStatement(
          'INSERT INTO patients '
          '(uuid, uhid, name, gender, dob, age_years, phone, alt_phone, email, address, city, state, pincode, '
          'blood_group, emergency_contact_name, emergency_contact_phone, is_vip, created_at, updated_at, is_deleted) '
          'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 0, ?, ?, 0)',
          [
            uuid,
            localAlias,
            patient['name'],
            patient['gender'],
            patient['dateOfBirth'],
            patient['ageYears'],
            patient['phone'],
            patient['alternatePhone'],
            patient['email'],
            patient['address'],
            patient['city'],
            patient['state'],
            patient['pincode'],
            patient['bloodGroup'],
            patient['emergencyContactName'],
            patient['emergencyContactPhone'],
            createdAt,
            updatedAt
          ],
        );
      } else {
        await customStatement(
          'UPDATE patients SET name = ?, gender = ?, dob = ?, age_years = ?, phone = ?, alt_phone = ?, email = ?, '
          'address = ?, city = ?, state = ?, pincode = ?, blood_group = ?, emergency_contact_name = ?, '
          'emergency_contact_phone = ?, updated_at = ? WHERE id = ?',
          [
            patient['name'],
            patient['gender'],
            patient['dateOfBirth'],
            patient['ageYears'],
            patient['phone'],
            patient['alternatePhone'],
            patient['email'],
            patient['address'],
            patient['city'],
            patient['state'],
            patient['pincode'],
            patient['bloodGroup'],
            patient['emergencyContactName'],
            patient['emergencyContactPhone'],
            updatedAt,
            existingRows.single.read<int>('id')
          ],
        );
      }
      await customStatement(
        'INSERT INTO patient_sync_states '
        '(patient_uuid, server_patient_id, canonical_uhid, server_version, server_status, sync_state, last_error_code, updated_at) '
        "VALUES (?, ?, ?, ?, ?, 'SYNCED', NULL, ?) ON CONFLICT(patient_uuid) DO UPDATE SET "
        'server_patient_id = excluded.server_patient_id, canonical_uhid = excluded.canonical_uhid, '
        'server_version = excluded.server_version, server_status = excluded.server_status, '
        "sync_state = 'SYNCED', last_error_code = NULL, updated_at = excluded.updated_at",
        [
          uuid,
          id,
          canonicalUhid,
          (patient['version'] as num).toInt(),
          patient['status'] ?? 'ACTIVE',
          now
        ],
      );
    });
  }

  Future<void> _upsertState(String uuid, String state, String error,
          Map<String, dynamic> patient) =>
      customStatement(
        'INSERT INTO patient_sync_states '
        '(patient_uuid, server_patient_id, canonical_uhid, server_version, server_status, sync_state, last_error_code, updated_at) '
        'VALUES (?, ?, ?, ?, ?, ?, ?, ?) ON CONFLICT(patient_uuid) DO UPDATE SET '
        'sync_state = excluded.sync_state, last_error_code = excluded.last_error_code, updated_at = excluded.updated_at',
        [
          uuid,
          patient['id'],
          patient['uhid'],
          patient['version'],
          patient['status'],
          state,
          error,
          DateTime.now().toIso8601String()
        ],
      );
}

class PatientSyncOutboxEntry {
  const PatientSyncOutboxEntry({
    required this.operationId,
    required this.patientUuid,
    required this.operation,
    required this.payload,
    required this.baseVersion,
  });

  final String operationId;
  final String patientUuid;
  final String operation;
  final String payload;
  final int? baseVersion;
}
