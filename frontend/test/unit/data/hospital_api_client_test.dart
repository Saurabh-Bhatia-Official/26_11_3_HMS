import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hospital_management/data/remote/hospital_api_client.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('registration sends public API request and returns pending registration', () async {
    final client = MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.url.path, '/api/v1/hospital-registrations');
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      expect(body['adminPassword'], 'HospitalPassphrase9!');
      expect(body.containsKey('hospitalId'), isFalse);
      return http.Response(
        jsonEncode({'registrationId': 'reg-1', 'status': 'PENDING', 'submittedAt': '2026-11-16T00:00:00Z'}),
        202,
      );
    });
    final api = HospitalApiClient(client: client, baseUri: Uri.parse('https://api.test'));

    final result = await api.registerHospital(
      name: 'North Clinic',
      code: 'NC-1',
      type: 'Clinic',
      address: 'Street 1',
      email: 'admin@example.test',
      adminUsername: 'north-admin',
      adminPassword: 'HospitalPassphrase9!',
      adminFullName: 'North Admin',
    );

    expect(result['status'], 'PENDING');
  });

  test('approved hospitals are parsed separately from local integer IDs', () async {
    final client = MockClient((request) async => http.Response(
          jsonEncode([
            {
              'hospitalId': '123456789012',
              'name': 'North Clinic',
              'type': 'Clinic',
            },
          ]),
          200,
        ));
    final api = HospitalApiClient(client: client, baseUri: Uri.parse('https://api.test'));

    final hospitals = await api.listHospitals();

    expect(hospitals.single.hospitalId, '123456789012');
  });

  test('invalid Hospital ID is rejected before the network call', () async {
    final client = MockClient((_) async => throw StateError('unexpected network call'));
    final api = HospitalApiClient(client: client, baseUri: Uri.parse('https://api.test'));

    await expectLater(api.lookupHospital('1234'), throwsA(isA<HospitalApiException>()));
  });
}
