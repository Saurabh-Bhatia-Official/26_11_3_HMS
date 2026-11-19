import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hospital_management/data/remote/online_clinical_api.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('OnlineClinicalApi', () {
    test('loads paginated Departments with bearer authentication', () async {
      late http.Request captured;
      final api = OnlineClinicalApi(
        baseUri: Uri.parse('https://care.test/'),
        accessToken: () async => 'access-token',
        refreshAccessToken: () async => null,
        client: MockClient((request) async {
          captured = request;
          return http.Response(
              jsonEncode({
                'items': [
                  {'id': 'department-uuid', 'name': 'Cardiology'}
                ],
                'page': 0,
                'size': 100,
                'totalElements': 1,
                'totalPages': 1,
              }),
              200);
        }),
      );

      final departments = await api.departments(active: true);

      expect(captured.method, 'GET');
      expect(captured.url.path, '/api/v1/departments');
      expect(captured.url.queryParameters,
          {'page': '0', 'size': '100', 'active': 'true'});
      expect(captured.headers['authorization'], 'Bearer access-token');
      expect(departments.single['id'], 'department-uuid');
      api.close();
    });

    test('uses the server availability slot and posts an appointment',
        () async {
      late http.Request captured;
      final api = OnlineClinicalApi(
        accessToken: () async => 'token',
        refreshAccessToken: () async => null,
        client: MockClient((request) async {
          captured = request;
          return http.Response(
              jsonEncode({'appointmentUuid': 'appointment-uuid'}), 201);
        }),
      );

      final result = await api.createAppointment({
        'patientUuid': 'patient-uuid',
        'doctorUuid': 'doctor-uuid',
        'startsAt': '2026-11-20T09:00:00+05:30',
        'appointmentType': 'CONSULTATION',
      });

      expect(captured.method, 'POST');
      expect(captured.url.path, '/api/v1/appointments');
      expect(
          jsonDecode(captured.body)['startsAt'], '2026-11-20T09:00:00+05:30');
      expect(result['appointmentUuid'], 'appointment-uuid');
      api.close();
    });

    test('rotates once and retries a protected request after 401', () async {
      var requests = 0;
      var refreshes = 0;
      final api = OnlineClinicalApi(
        accessToken: () async => 'expired-token',
        refreshAccessToken: () async {
          refreshes++;
          return 'rotated-token';
        },
        client: MockClient((request) async {
          requests++;
          if (request.headers['authorization'] == 'Bearer expired-token') {
            return http.Response('{"error":"expired"}', 401);
          }
          return http.Response('[]', 200);
        }),
      );

      expect(await api.appointmentEvents('appointment-uuid'), isEmpty);
      expect(requests, 2);
      expect(refreshes, 1);
      api.close();
    });

    test('coalesces simultaneous 401 refreshes to one token rotation', () async {
      var refreshes = 0;
      final api = OnlineClinicalApi(
        accessToken: () async => 'expired-token',
        refreshAccessToken: () async {
          refreshes++;
          await Future<void>.delayed(const Duration(milliseconds: 20));
          return 'rotated-token';
        },
        client: MockClient((request) async {
          if (request.headers['authorization'] == 'Bearer expired-token') {
            return http.Response('{"error":"expired"}', 401);
          }
          return http.Response('[]', 200);
        }),
      );

      await Future.wait([
        api.appointmentEvents('appointment-a'),
        api.appointmentEvents('appointment-b'),
      ]);
      expect(refreshes, 1);
      api.close();
    });

    test('surfaces safe server error messages and status codes', () async {
      final api = OnlineClinicalApi(
        accessToken: () async => 'token',
        refreshAccessToken: () async => null,
        client: MockClient((_) async =>
            http.Response('{"error":"Slot is no longer available"}', 409)),
      );

      await expectLater(
        api.createAppointment({'startsAt': 'slot'}),
        throwsA(isA<OnlineApiException>()
            .having((e) => e.statusCode, 'statusCode', 409)
            .having(
                (e) => e.message, 'message', 'Slot is no longer available')),
      );
      api.close();
    });

    test('does not send requests when there is no authenticated session',
        () async {
      var sends = 0;
      final api = OnlineClinicalApi(
        accessToken: () async => null,
        refreshAccessToken: () async => null,
        client: MockClient((_) async {
          sends++;
          return http.Response('[]', 200);
        }),
      );

      await expectLater(api.departments(), throwsA(isA<OnlineApiException>()));
      expect(sends, 0);
      api.close();
    });
  });
}
