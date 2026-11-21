import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

class HospitalApiException implements Exception {
  const HospitalApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class HospitalApiRecord {

  factory HospitalApiRecord.fromJson(Map<String, dynamic> json) {
    return HospitalApiRecord(
      hospitalId: json['hospitalId'].toString(),
      name: json['name'] as String,
      type: json['type'] as String,
    );
  }
  const HospitalApiRecord({
    required this.hospitalId,
    required this.name,
    required this.type,
  });

  final String hospitalId;
  final String name;
  final String type;
}

class HospitalApiClient {
  HospitalApiClient({http.Client? client, Uri? baseUri})
      : _client = client ?? http.Client(),
        _baseUri = baseUri ?? Uri.parse(const String.fromEnvironment(
          'CARESYNC_API_BASE_URL',
          defaultValue: 'http://localhost:8080',
        ));

  final http.Client _client;
  final Uri _baseUri;

  Uri _uri(String path) => _baseUri.resolve(path);

  Future<Map<String, dynamic>> registerHospital({
    required String name,
    required String code,
    required String type,
    required String address,
    required String email,
    required String adminUsername,
    required String adminPassword,
    required String adminFullName,
  }) async {
    final response = await _client
        .post(
          _uri('/api/v1/hospital-registrations'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({
            'name': name,
            'code': code,
            'type': type,
            'address': address,
            'email': email,
            'adminUsername': adminUsername,
            'adminPassword': adminPassword,
            'adminFullName': adminFullName,
          }),
        )
        .timeout(const Duration(seconds: 20));
    return _decodeObject(response, expectedStatus: 202);
  }

  Future<List<HospitalApiRecord>> listHospitals() async {
    final response = await _client
        .get(_uri('/api/v1/hospitals'))
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) _throwApiError(response);
    final decoded = jsonDecode(response.body);
    if (decoded is! List) throw const HospitalApiException('The server returned an invalid response.');
    return decoded
        .map((row) => HospitalApiRecord.fromJson(row as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<HospitalApiRecord> lookupHospital(String hospitalId) async {
    if (!RegExp(r'^\d{12}$').hasMatch(hospitalId)) {
      throw const HospitalApiException('Enter a valid 12-digit Hospital ID.');
    }
    final response = await _client
        .get(_uri('/api/v1/hospitals/lookup/$hospitalId'))
        .timeout(const Duration(seconds: 20));
    return HospitalApiRecord.fromJson(_decodeObject(response, expectedStatus: 200));
  }

  Future<Map<String, dynamic>> hospitalLogin({
    required String hospitalId,
    required String username,
    required String password,
  }) async {
    final response = await _client
        .post(
          _uri('/api/auth/hospital-login'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({'hospitalId': hospitalId, 'username': username, 'password': password}),
        )
        .timeout(const Duration(seconds: 20));
    return _decodeObject(response, expectedStatus: 200);
  }

  Future<Map<String, dynamic>> currentUser(String accessToken) async {
    final response = await _client.get(_uri('/api/auth/me'),
        headers: {'Authorization': 'Bearer $accessToken'}).timeout(const Duration(seconds: 20));
    return _decodeObject(response, expectedStatus: 200);
  }

  Future<Map<String, dynamic>> currentHospital(String accessToken) async {
    final response = await _client.get(_uri('/api/v1/hospitals/me'),
        headers: {'Authorization': 'Bearer $accessToken'}).timeout(const Duration(seconds: 20));
    return _decodeObject(response, expectedStatus: 200);
  }

  Future<Map<String, dynamic>> refreshSession(String refreshToken) async {
    final response = await _client.post(_uri('/api/auth/refresh'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken})).timeout(const Duration(seconds: 20));
    return _decodeObject(response, expectedStatus: 200);
  }

  Future<void> logout(String refreshToken) async {
    final response = await _client.post(_uri('/api/auth/logout'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken})).timeout(const Duration(seconds: 20));
    if (response.statusCode != 204) _throwApiError(response);
  }

  Future<Map<String, dynamic>> centralAdminLogin({
    required String username,
    required String password,
  }) async {
    final response = await _client
        .post(
          _uri('/api/auth/login'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({'username': username, 'password': password}),
        )
        .timeout(const Duration(seconds: 20));
    return _decodeObject(response, expectedStatus: 200);
  }

  Future<List<Map<String, dynamic>>> pendingRegistrations(String accessToken) async {
    final response = await _client.get(
      _uri('/api/v1/platform/hospital-registrations'),
      headers: {'Authorization': 'Bearer $accessToken'},
    ).timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) _throwApiError(response);
    final decoded = jsonDecode(response.body);
    if (decoded is! List) throw const HospitalApiException('The server returned an invalid response.');
    return decoded.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> approveRegistration(String registrationId, String accessToken) async {
    final response = await _client.post(
      _uri('/api/v1/platform/hospital-registrations/$registrationId/approve'),
      headers: {'Authorization': 'Bearer $accessToken'},
    ).timeout(const Duration(seconds: 20));
    return _decodeObject(response, expectedStatus: 200);
  }

  Future<void> rejectRegistration(String registrationId, String accessToken) async {
    final response = await _client.post(
      _uri('/api/v1/platform/hospital-registrations/$registrationId/reject'),
      headers: {'Authorization': 'Bearer $accessToken'},
    ).timeout(const Duration(seconds: 20));
    if (response.statusCode != 204) _throwApiError(response);
  }

  Map<String, dynamic> _decodeObject(http.Response response, {required int expectedStatus}) {
    if (response.statusCode != expectedStatus) _throwApiError(response);
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const HospitalApiException('The server returned an invalid response.');
    }
    return decoded;
  }

  Never _throwApiError(http.Response response) {
    var message = 'The request could not be completed.';
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded['error'] is String) message = decoded['error'] as String;
    } catch (_) {
      // Keep the UI error generic when a response is not valid JSON.
    }
    throw HospitalApiException(message, statusCode: response.statusCode);
  }

  void close() => _client.close();
}

final hospitalApiClientProvider = Provider<HospitalApiClient>((ref) {
  final client = HospitalApiClient();
  ref.onDispose(client.close);
  return client;
});
