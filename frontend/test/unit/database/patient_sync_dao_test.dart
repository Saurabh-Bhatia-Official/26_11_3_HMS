import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hospital_management/data/database/app_database.dart';

void main() {
  late AppDatabase database;

  setUp(() async {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    await database.customSelect('SELECT 1').get();
  });

  tearDown(() async => database.close());

  test('retains an authorization-blocked operation for later retry', () async {
    const uuid = 'd9428888-122b-4f79-b4c8-639e5d8110a1';
    const operationId = 'a9428888-122b-4f79-b4c8-639e5d8110a2';
    await database.patientSyncDao.enqueue(
      operationId: operationId,
      patientUuid: uuid,
      operation: 'CREATE',
      payload: '{"uuid":"$uuid","name":"Sample Patient"}',
      createdAt: DateTime.utc(2026).toIso8601String(),
    );

    final entry = (await database.patientSyncDao.pending()).single;
    await database.patientSyncDao.markFailure(
      entry: entry,
      state: 'BLOCKED_AUTH',
      errorCode: 'MEMBERSHIP_OR_SESSION_REQUIRED',
      updatedAt: DateTime.utc(2026).toIso8601String(),
    );

    expect(await database.patientSyncDao.countOutbox(), 1);
    expect(await database.patientSyncDao.pending(), isEmpty);

    await database.patientSyncDao.requeueAuthorizationBlocked();
    expect((await database.patientSyncDao.pending()).single.operationId, operationId);
  });
}
