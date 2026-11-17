import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hospital_management/data/remote/hospital_api_client.dart';
import 'package:hospital_management/data/remote/patient_api_client.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('PatientApiClient', () {
    test('posts the client UUID and only approved demographics', () async {
      late http.Request captured;
      final client = PatientApiClient(
        baseUri: Uri.parse('https://api.example.test'),
        client: MockClient((request) async {
          captured = request;
          return http.Response(
            jsonEncode({
              'id': 42,
              'uuid': 'd9428888-122b-4f79-b4c8-639e5d8110a1',
              'uhid': 'HOSP-000042',
              'version': 0,
              'status': 'ACTIVE',
            }),
            201,
          );
        }),
      );

      final result = await client.create('secure-access-token', {
        'uuid': 'd9428888-122b-4f79-b4c8-639e5d8110a1',
        'name': 'Sample Patient',
      });

      expect(captured.url.path, '/api/v1/patients');
      expect(captured.headers['Authorization'], 'Bearer secure-access-token');
      expect(jsonDecode(captured.body), {
        'uuid': 'd9428888-122b-4f79-b4c8-639e5d8110a1',
        'name': 'Sample Patient',
      });
      expect(result.uhid, 'HOSP-000042');
      expect(result.version, 0);
    });

    test('preserves authorization status for blocked outbox handling', () async {
      final client = PatientApiClient(
        baseUri: Uri.parse('https://api.example.test'),
        client: MockClient((_) async => http.Response(
              jsonEncode({'message': 'Active Hospital membership required'}),
              403,
            )),
      );

      await expectLater(
        client.create('token', {'uuid': 'd9428888-122b-4f79-b4c8-639e5d8110a1'}),
        throwsA(isA<HospitalApiException>().having((e) => e.statusCode, 'statusCode', 403)),
      );
    });
  });
}
