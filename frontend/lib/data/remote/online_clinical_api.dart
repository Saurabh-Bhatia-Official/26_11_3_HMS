import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hospital_management/core/auth/online_hospital_session.dart';
import 'package:http/http.dart' as http;

class OnlineApiException implements Exception {
  const OnlineApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

/// Small REST transport shared by online-only clinical clients.
/// A 401 is retried once after rotating the existing secure refresh token.
class OnlineClinicalApi {
  OnlineClinicalApi({
    http.Client? client,
    Uri? baseUri,
    required Future<String?> Function() accessToken,
    required Future<String?> Function() refreshAccessToken,
  })  : _client = client ?? http.Client(),
        _baseUri = baseUri ??
            Uri.parse(const String.fromEnvironment(
              'CARESYNC_API_BASE_URL',
              defaultValue: 'http://localhost:8080',
            )),
        _accessToken = accessToken,
        _refreshAccessToken = refreshAccessToken;

  final http.Client _client;
  final Uri _baseUri;
  final Future<String?> Function() _accessToken;
  final Future<String?> Function() _refreshAccessToken;
  Future<String?>? _refreshInFlight;

  void close() => _client.close();

  Future<dynamic> request(
    String method,
    String path, {
    Map<String, String>? query,
    Object? body,
    Set<int> expected = const {200},
  }) async {
    final uri = _baseUri.resolve(path).replace(queryParameters: query);
    var token = await _accessToken();
    if (token == null || token.isEmpty) {
      throw const OnlineApiException(
          'Sign in to your Hospital account to continue.',
          statusCode: 401);
    }
    var response = await _send(method, uri, token, body);
    if (response.statusCode == 401) {
      token = await _refreshOnce();
      if (token == null || token.isEmpty) {
        throw const OnlineApiException(
            'Your online session has expired. Sign in again.',
            statusCode: 401);
      }
      response = await _send(method, uri, token, body);
    }
    if (!expected.contains(response.statusCode)) _throwResponse(response);
    if (response.statusCode == 204 || response.body.isEmpty) return null;
    try {
      return jsonDecode(response.body);
    } on FormatException {
      throw OnlineApiException('The server returned an invalid response.',
          statusCode: response.statusCode);
    }
  }

  Future<String?> _refreshOnce() {
    final existing = _refreshInFlight;
    if (existing != null) return existing;
    final future = _refreshAccessToken();
    _refreshInFlight = future;
    return future.whenComplete(() {
      if (identical(_refreshInFlight, future)) _refreshInFlight = null;
    });
  }

  Future<http.Response> _send(
      String method, Uri uri, String token, Object? body) {
    final headers = <String, String>{
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      if (body != null) 'Content-Type': 'application/json',
    };
    final encoded = body == null ? null : jsonEncode(body);
    final future = switch (method) {
      'GET' => _client.get(uri, headers: headers),
      'POST' => _client.post(uri, headers: headers, body: encoded),
      'PUT' => _client.put(uri, headers: headers, body: encoded),
      'PATCH' => _client.patch(uri, headers: headers, body: encoded),
      'DELETE' => _client.delete(uri, headers: headers),
      _ =>
        throw ArgumentError.value(method, 'method', 'Unsupported HTTP method'),
    };
    return future.timeout(const Duration(seconds: 20));
  }

  Never _throwResponse(http.Response response) {
    String? message;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map) {
        message = (decoded['error'] ?? decoded['message'] ?? decoded['detail'])
            ?.toString();
      }
    } catch (_) {
      // Do not expose an unstructured server response.
    }
    message ??= switch (response.statusCode) {
      400 => 'Check the entered information and try again.',
      401 => 'Your online session has expired. Sign in again.',
      403 => 'Your Hospital role does not allow this operation.',
      404 => 'The requested record was not found in this Hospital.',
      409 =>
        'This request conflicts with current Hospital data. Refresh and try again.',
      _ => 'The online service could not complete this request.',
    };
    throw OnlineApiException(message, statusCode: response.statusCode);
  }

  Future<Map<String, dynamic>> _object(String method, String path,
      {Map<String, String>? query,
      Object? body,
      Set<int> expected = const {200}}) async {
    final value = await request(method, path,
        query: query, body: body, expected: expected);
    if (value is Map<String, dynamic>) return value;
    throw const OnlineApiException('The server returned an invalid record.');
  }

  Future<List<Map<String, dynamic>>> _list(String method, String path,
      {Map<String, String>? query,
      Object? body,
      Set<int> expected = const {200}}) async {
    final value = await request(method, path,
        query: query, body: body, expected: expected);
    if (value is List) return value.cast<Map<String, dynamic>>();
    if (value is Map<String, dynamic> && value['items'] is List) {
      return (value['items'] as List).cast<Map<String, dynamic>>();
    }
    throw const OnlineApiException('The server returned an invalid list.');
  }

  Future<List<Map<String, dynamic>>> departments(
          {int page = 0, int size = 100, bool? active}) =>
      _list('GET', '/api/v1/departments', query: {
        'page': '$page',
        'size': '$size',
        if (active != null) 'active': '$active',
      });

  Future<Map<String, dynamic>> department(String id) =>
      _object('GET', '/api/v1/departments/$id');
  Future<Map<String, dynamic>> createDepartment(Map<String, dynamic> body) =>
      _object('POST', '/api/v1/departments', body: body, expected: const {201});
  Future<Map<String, dynamic>> updateDepartment(
          String id, Map<String, dynamic> body) =>
      _object('PUT', '/api/v1/departments/$id', body: body);
  Future<Map<String, dynamic>> setDepartmentActive(String id, bool active) =>
      _object('PATCH', '/api/v1/departments/$id/status',
          body: {'active': active});

  Future<List<Map<String, dynamic>>> doctors(
          {int page = 0, int size = 100, bool? active}) =>
      _list('GET', '/api/v1/doctors', query: {
        'page': '$page',
        'size': '$size',
        if (active != null) 'active': '$active',
      });
  Future<Map<String, dynamic>> doctor(String id) =>
      _object('GET', '/api/v1/doctors/$id');
  Future<Map<String, dynamic>> createDoctor(Map<String, dynamic> body) =>
      _object('POST', '/api/v1/doctors', body: body, expected: const {201});
  Future<Map<String, dynamic>> updateDoctor(
          String id, Map<String, dynamic> body) =>
      _object('PATCH', '/api/v1/doctors/$id', body: body);
  Future<Map<String, dynamic>> setDoctorActive(String id, bool active) =>
      _object('PATCH', '/api/v1/doctors/$id/status', body: {'active': active});
  Future<List<Map<String, dynamic>>> schedules(String doctorId) =>
      _list('GET', '/api/v1/doctors/$doctorId/schedules');
  Future<Map<String, dynamic>> createSchedule(
          String doctorId, Map<String, dynamic> body) =>
      _object('POST', '/api/v1/doctors/$doctorId/schedules',
          body: body, expected: const {201});
  Future<Map<String, dynamic>> updateSchedule(
          String doctorId, String scheduleId, Map<String, dynamic> body) =>
      _object('PATCH', '/api/v1/doctors/$doctorId/schedules/$scheduleId',
          body: body);
  Future<List<Map<String, dynamic>>> exceptions(String doctorId) =>
      _list('GET', '/api/v1/doctors/$doctorId/schedule-exceptions');
  Future<Map<String, dynamic>> createException(
          String doctorId, Map<String, dynamic> body) =>
      _object('POST', '/api/v1/doctors/$doctorId/schedule-exceptions',
          body: body, expected: const {201});
  Future<Map<String, dynamic>> updateException(
          String doctorId, String exceptionId, Map<String, dynamic> body) =>
      _object(
          'PATCH', '/api/v1/doctors/$doctorId/schedule-exceptions/$exceptionId',
          body: body);
  Future<List<Map<String, dynamic>>> availability(
          String doctorId, DateTime date) =>
      _list('GET', '/api/v1/doctors/$doctorId/availability', query: {
        'date':
            '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
      });

  Future<List<Map<String, dynamic>>> patients({int page = 0, int size = 100}) =>
      _list('GET', '/api/v1/patients',
          query: {'page': '$page', 'size': '$size'});
  Future<List<Map<String, dynamic>>> appointments({
    int page = 0,
    int size = 100,
    String? doctorUuid,
    String? patientUuid,
    String? status,
    DateTime? from,
    DateTime? until,
  }) =>
      _list('GET', '/api/v1/appointments', query: {
        'page': '$page',
        'size': '$size',
        if (doctorUuid != null) 'doctorUuid': doctorUuid,
        if (patientUuid != null) 'patientUuid': patientUuid,
        if (status != null) 'status': status,
        if (from != null) 'from': from.toIso8601String(),
        if (until != null) 'until': until.toIso8601String(),
      });
  Future<Map<String, dynamic>> appointment(String id) =>
      _object('GET', '/api/v1/appointments/$id');
  Future<List<Map<String, dynamic>>> appointmentEvents(String id) =>
      _list('GET', '/api/v1/appointments/$id/events');
  Future<Map<String, dynamic>> createAppointment(Map<String, dynamic> body) =>
      _object('POST', '/api/v1/appointments',
          body: body, expected: const {201});
  Future<Map<String, dynamic>> reschedule(String id, String startsAt) =>
      _object('POST', '/api/v1/appointments/$id/reschedule',
          body: {'startsAt': startsAt});
  Future<Map<String, dynamic>> changeAppointmentStatus(
          String id, String status) =>
      _object('PATCH', '/api/v1/appointments/$id/status',
          body: {'status': status});
  Future<Map<String, dynamic>> cancelAppointment(String id) =>
      _object('POST', '/api/v1/appointments/$id/cancel');
}

final onlineClinicalApiProvider = Provider<OnlineClinicalApi>((ref) {
  final session = ref.read(onlineHospitalSessionProvider.notifier);
  final api = OnlineClinicalApi(
    accessToken: session.accessTokenForApi,
    refreshAccessToken: session.refreshAccessTokenForApi,
  );
  ref.onDispose(api.close);
  return api;
});
