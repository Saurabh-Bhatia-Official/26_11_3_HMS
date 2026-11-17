import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hospital_management/data/remote/hospital_api_client.dart';
import 'package:http/http.dart' as http;

class PatientServerRecord {
  const PatientServerRecord(this.json);
  final Map<String, dynamic> json;

  String get uuid => json['uuid'] as String;
  int get id => (json['id'] as num).toInt();
  String get uhid => json['uhid'] as String;
  int get version => (json['version'] as num).toInt();
  String get status => json['status'] as String? ?? 'ACTIVE';
}

class PatientApiClient {
  PatientApiClient({http.Client? client, Uri? baseUri})
      : _client = client ?? http.Client(),
        _baseUri = baseUri ?? Uri.parse(const String.fromEnvironment(
          'CARESYNC_API_BASE_URL',
          defaultValue: 'http://localhost:8080',
        ));

  final http.Client _client;
  final Uri _baseUri;

  Uri _uri(String path) => _baseUri.resolve(path);

  Future<PatientServerRecord> create(String token, Map<String, dynamic> body) async {
    final response = await _client
        .post(_uri('/api/v1/patients'), headers: _headers(token), body: jsonEncode(body))
        .timeout(const Duration(seconds: 20));
    return PatientServerRecord(_decode(response, {201}));
  }

  Future<PatientServerRecord> update(
      String token, String uuid, Map<String, dynamic> body) async {
    final response = await _client
        .put(_uri('/api/v1/patients/$uuid'), headers: _headers(token), body: jsonEncode(body))
        .timeout(const Duration(seconds: 20));
    return PatientServerRecord(_decode(response, {200}));
  }

  Future<PatientServerRecord> changeStatus(
      String token, String uuid, String status, int version) async {
    final response = await _client
        .patch(_uri('/api/v1/patients/$uuid/status'),
            headers: _headers(token), body: jsonEncode({'status': status, 'version': version}))
        .timeout(const Duration(seconds: 20));
    return PatientServerRecord(_decode(response, {200}));
  }

  Future<void> archive(String token, String uuid) async {
    final response = await _client
        .delete(_uri('/api/v1/patients/$uuid'), headers: _headers(token))
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != 204) _decode(response, {204});
  }

  Future<Map<String, dynamic>> list(
      String token, {required int page, int size = 100}) async {
    final uri = _uri('/api/v1/patients').replace(queryParameters: {
      'page': '$page',
      'size': '$size',
    });
    final response = await _client
        .get(uri, headers: _headers(token))
        .timeout(const Duration(seconds: 20));
    return _decode(response, {200});
  }

  Map<String, String> _headers(String token) => {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  Map<String, dynamic> _decode(http.Response response, Set<int> expected) {
    dynamic decoded;
    if (response.body.isNotEmpty) {
      try {
        decoded = jsonDecode(response.body);
      } catch (_) {
        throw HospitalApiException('The Patient server returned an invalid response.',
            statusCode: response.statusCode);
      }
    }
    if (!expected.contains(response.statusCode)) {
      final message = decoded is Map<String, dynamic>
          ? (decoded['message'] ?? decoded['detail'])?.toString()
          : null;
      throw HospitalApiException(
        message ?? _safeStatusMessage(response.statusCode),
        statusCode: response.statusCode,
      );
    }
    if (decoded is Map<String, dynamic>) return decoded;
    if (response.statusCode == 204) return const {};
    throw HospitalApiException('The Patient server returned an invalid response.',
        statusCode: response.statusCode);
  }

  String _safeStatusMessage(int status) => switch (status) {
        401 => 'Your server session has expired.',
        403 => 'Active Hospital membership is required for Patient synchronization.',
        404 => 'The requested Patient record was not found.',
        409 => 'The Patient record conflicts with a newer server version.',
        _ => 'Patient synchronization is temporarily unavailable.',
      };
}

final patientApiClientProvider = Provider<PatientApiClient>((ref) => PatientApiClient());
