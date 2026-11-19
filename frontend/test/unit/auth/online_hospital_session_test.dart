import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hospital_management/core/auth/online_hospital_session.dart';
import 'package:hospital_management/data/remote/hospital_api_client.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _hospitalId = '123456789012';

void main() {
  test('does not publish restored session state after notifier disposal',
      () async {
    final accessRead = Completer<String?>();
    final refreshRead = Completer<String?>();
    final tokenStore =
        _DelayedTokenStore(accessRead.future, refreshRead.future);
    final api = HospitalApiClient(
      client: MockClient((_) async => http.Response('', 500)),
      baseUri: Uri.parse('https://api.test'),
    );
    final notifier =
        OnlineHospitalSessionNotifier(api, tokenStore, autoRestore: false);

    final restore = notifier.restore();
    notifier.dispose();
    accessRead.complete('access-one');
    refreshRead.complete('refresh-one');

    await expectLater(restore, completes);
    api.close();
  });

  test(
      'stores only tokens securely and restores the verified Hospital after restart',
      () async {
    final tokenStore = _MemoryTokenStore();
    final api = HospitalApiClient(
      client: MockClient((request) async => _sessionResponse(request)),
      baseUri: Uri.parse('https://api.test'),
    );
    final firstRun =
        OnlineHospitalSessionNotifier(api, tokenStore, autoRestore: false);

    expect(
        await firstRun.login(
          hospitalId: _hospitalId,
          username: 'hospital-admin',
          password: 'NeverStoreThisPassword9!',
        ),
        isNull);
    expect(firstRun.state.isAuthenticated, isTrue);
    expect(tokenStore.values.values, contains('access-one'));
    expect(tokenStore.values.values, contains('refresh-one'));
    expect(
        tokenStore.values.values, isNot(contains('NeverStoreThisPassword9!')));
    firstRun.dispose();

    final afterRestart =
        OnlineHospitalSessionNotifier(api, tokenStore, autoRestore: false);
    await afterRestart.restore();
    expect(afterRestart.state.isAuthenticated, isTrue);
    expect(afterRestart.state.hospital?.hospitalId, _hospitalId);
    afterRestart.dispose();
    api.close();
  });

  test('rotates an expired access session and persists both replacement tokens',
      () async {
    final tokenStore = _MemoryTokenStore();
    final api = HospitalApiClient(
      client: MockClient((request) async {
        if (request.url.path == '/api/auth/hospital-login')
          return _tokenResponse('access-old', 'refresh-old');
        if (request.url.path == '/api/auth/me' &&
            request.headers['Authorization'] == 'Bearer access-old') {
          return http.Response('{"error":"Unauthorized"}', 401);
        }
        if (request.url.path == '/api/auth/refresh') {
          expect(
              (jsonDecode(request.body)
                  as Map<String, dynamic>)['refreshToken'],
              'refresh-old');
          return _tokenResponse('access-new', 'refresh-new');
        }
        return _sessionResponse(request, accessToken: 'access-new');
      }),
      baseUri: Uri.parse('https://api.test'),
    );
    final notifier =
        OnlineHospitalSessionNotifier(api, tokenStore, autoRestore: false);

    expect(
        await notifier.login(
          hospitalId: _hospitalId,
          username: 'hospital-admin',
          password: 'NeverStoreThisPassword9!',
        ),
        isNull);
    expect(tokenStore.values.values, contains('access-new'));
    expect(tokenStore.values.values, contains('refresh-new'));
    notifier.dispose();
    api.close();
  });

  test('clears a revoked token family on restore and revokes on logout',
      () async {
    final tokenStore = _MemoryTokenStore()
      ..values['caresync.online.access_token'] = 'revoked-access'
      ..values['caresync.online.refresh_token'] = 'revoked-refresh';
    final api = HospitalApiClient(
      client: MockClient((request) async {
        if (request.url.path == '/api/auth/me')
          return http.Response('{"error":"Unauthorized"}', 401);
        if (request.url.path == '/api/auth/refresh' ||
            request.url.path == '/api/auth/logout') {
          return http.Response(
              '{"error":"Invalid or expired refresh token"}', 401);
        }
        return http.Response('', 500);
      }),
      baseUri: Uri.parse('https://api.test'),
    );
    final notifier =
        OnlineHospitalSessionNotifier(api, tokenStore, autoRestore: false);

    await notifier.restore();
    expect(notifier.state.isAuthenticated, isFalse);
    expect(tokenStore.values, isEmpty);

    tokenStore.values['caresync.online.refresh_token'] = 'logout-refresh';
    await notifier.logout();
    expect(tokenStore.values, isEmpty);
    notifier.dispose();
    api.close();
  });
}

http.Response _sessionResponse(http.Request request,
    {String accessToken = 'access-one'}) {
  if (request.url.path == '/api/auth/me') {
    return http.Response(
        jsonEncode({
          'id': 5,
          'username': 'hospital-admin',
          'fullName': 'Hospital Admin',
          'role': 'HOSPITAL_SUPER_ADMIN',
          'hospitalId': _hospitalId,
        }),
        200);
  }
  if (request.url.path == '/api/v1/hospitals/me') {
    return http.Response(
        jsonEncode({
          'hospitalId': _hospitalId,
          'name': 'North Clinic',
          'code': 'NC-1',
          'type': 'Clinic',
        }),
        200);
  }
  if (request.url.path == '/api/auth/hospital-login')
    return _tokenResponse(accessToken, 'refresh-one');
  if (request.url.path == '/api/auth/logout') return http.Response('', 204);
  return http.Response('{"error":"unexpected request"}', 404);
}

http.Response _tokenResponse(String accessToken, String refreshToken) =>
    http.Response(
        jsonEncode({
          'accessToken': accessToken,
          'refreshToken': refreshToken,
          'tokenType': 'Bearer',
          'expiresIn': 900,
          'user': {
            'id': 5,
            'username': 'hospital-admin',
            'fullName': 'Hospital Admin',
            'role': 'HOSPITAL_SUPER_ADMIN',
            'hospitalId': _hospitalId,
          },
        }),
        200);

class _MemoryTokenStore implements OnlineTokenStore {
  final Map<String, String> values = {};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    values.remove(key);
  }
}

class _DelayedTokenStore implements OnlineTokenStore {
  _DelayedTokenStore(this.accessRead, this.refreshRead);

  final Future<String?> accessRead;
  final Future<String?> refreshRead;

  @override
  Future<String?> read(String key) =>
      key.endsWith('access_token') ? accessRead : refreshRead;

  @override
  Future<void> write(String key, String value) async {}

  @override
  Future<void> delete(String key) async {}
}
