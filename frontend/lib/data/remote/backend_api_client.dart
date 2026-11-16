import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

const caresyncApiBaseUrl = String.fromEnvironment('CARESYNC_API_BASE_URL');

class BackendApiException implements Exception {
  const BackendApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class BackendConnectionException implements Exception {
  const BackendConnectionException();

  @override
  String toString() =>
      'Backend is unavailable. Changes remain saved on this device.';
}

class BackendApiClient {
  BackendApiClient({
    String baseUrl = caresyncApiBaseUrl,
    http.Client? client,
    FlutterSecureStorage? storage,
  })  : _baseUri = _parseBaseUrl(baseUrl),
        _client = client ?? http.Client(),
        _storage = storage ?? const FlutterSecureStorage();

  static const _accessTokenKey = 'caresync_access_token';
  static const _refreshTokenKey = 'caresync_refresh_token';

  final Uri? _baseUri;
  final http.Client _client;
  final FlutterSecureStorage _storage;

  bool get isConfigured => _baseUri != null;

  Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await _send(
      'POST',
      '/api/auth/login',
      body: {'username': username, 'password': password},
      authenticated: false,
    );
    final token = _asObject(response);
    final accessToken = token['accessToken'];
    final refreshToken = token['refreshToken'];
    if (accessToken is! String || refreshToken is! String) {
      throw const BackendApiException(
          'Backend returned an invalid sign-in response.');
    }
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
    return _asObject(token['user']);
  }

  Future<void> logout() async {
    final refreshToken = await _storage.read(key: _refreshTokenKey);
    try {
      if (refreshToken != null && isConfigured) {
        await _send('POST', '/api/auth/logout',
            body: {'refreshToken': refreshToken}, authenticated: false);
      }
    } on BackendConnectionException {
      await clearCredentials();
    } on BackendApiException {
      await clearCredentials();
    } finally {
      await clearCredentials();
    }
  }

  Future<void> clearCredentials() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }

  Future<dynamic> get(String path, {Map<String, String>? query}) =>
      _send('GET', path, query: query);

  Future<dynamic> post(String path, {Object? body, String? idempotencyKey}) =>
      _send('POST', path, body: body, idempotencyKey: idempotencyKey);

  Future<dynamic> put(String path, {Object? body}) =>
      _send('PUT', path, body: body);

  Future<dynamic> delete(String path) => _send('DELETE', path);

  Future<dynamic> _send(
    String method,
    String path, {
    Object? body,
    Map<String, String>? query,
    bool authenticated = true,
    String? idempotencyKey,
    bool retryUnauthorized = true,
  }) async {
    final baseUri = _baseUri;
    if (baseUri == null) {
      throw const BackendApiException(
          'Backend URL is not configured. Set CARESYNC_API_BASE_URL when building the app.');
    }

    final accessToken =
        authenticated ? await _storage.read(key: _accessTokenKey) : null;
    final uri = baseUri.resolve(path).replace(queryParameters: query);
    final headers = <String, String>{'Accept': 'application/json'};
    if (body != null) headers['Content-Type'] = 'application/json';
    if (accessToken != null && authenticated) {
      headers['Authorization'] = 'Bearer $accessToken';
    }
    if (idempotencyKey != null) headers['Idempotency-Key'] = idempotencyKey;

    http.Response response;
    try {
      response = await _client
          .send(http.Request(method, uri)
            ..headers.addAll(headers)
            ..body = body == null ? '' : jsonEncode(body))
          .then(http.Response.fromStream)
          .timeout(const Duration(seconds: 15));
    } on TimeoutException {
      throw const BackendConnectionException();
    } on http.ClientException {
      throw const BackendConnectionException();
    }

    if (response.statusCode == 401 &&
        authenticated &&
        retryUnauthorized &&
        await _refreshAccessToken()) {
      return _send(method, path,
          body: body,
          query: query,
          authenticated: authenticated,
          idempotencyKey: idempotencyKey,
          retryUnauthorized: false);
    }
    if (response.statusCode == 401 && authenticated) {
      await clearCredentials();
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      String message = 'Backend request failed (${response.statusCode}).';
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic> && decoded['error'] is String) {
          message = decoded['error'] as String;
        }
      } on FormatException {
        // Keep the generic HTTP error if the response is not JSON.
      }
      throw BackendApiException(message, statusCode: response.statusCode);
    }
    if (response.statusCode == 204 || response.body.isEmpty) return null;
    try {
      return jsonDecode(response.body);
    } on FormatException {
      throw const BackendApiException('Backend returned an invalid response.');
    }
  }

  Future<bool> _refreshAccessToken() async {
    final refreshToken = await _storage.read(key: _refreshTokenKey);
    if (refreshToken == null || _baseUri == null) return false;
    try {
      final response = await _send('POST', '/api/auth/refresh',
          body: {'refreshToken': refreshToken},
          authenticated: false,
          retryUnauthorized: false);
      final tokens = _asObject(response);
      final accessToken = tokens['accessToken'];
      final newRefreshToken = tokens['refreshToken'];
      if (accessToken is! String || newRefreshToken is! String) {
        await clearCredentials();
        return false;
      }
      await _storage.write(key: _accessTokenKey, value: accessToken);
      await _storage.write(key: _refreshTokenKey, value: newRefreshToken);
      return true;
    } on BackendApiException {
      await clearCredentials();
      return false;
    }
  }

  static Uri? _parseBaseUrl(String value) {
    if (value.trim().isEmpty) return null;
    final uri = Uri.tryParse(value.trim());
    if (uri == null ||
        !uri.hasScheme ||
        uri.host.isEmpty ||
        (uri.scheme != 'http' && uri.scheme != 'https') ||
        uri.path.isNotEmpty && uri.path != '/') {
      throw ArgumentError.value(
          value, 'baseUrl', 'Must be an HTTP(S) origin without a path.');
    }
    return uri.replace(path: '/');
  }

  static Map<String, dynamic> _asObject(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    throw const BackendApiException('Backend returned an invalid response.');
  }
}

final backendApiClientProvider = Provider<BackendApiClient>((ref) {
  final client = BackendApiClient();
  ref.onDispose(client._client.close);
  return client;
});
