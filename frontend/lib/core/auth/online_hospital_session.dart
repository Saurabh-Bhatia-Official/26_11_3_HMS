import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hospital_management/data/remote/hospital_api_client.dart';

class OnlineHospitalUser {
  const OnlineHospitalUser({
    required this.id,
    required this.username,
    required this.fullName,
    required this.role,
    required this.hospitalId,
  });

  final int id;
  final String username;
  final String fullName;
  final String role;
  final String hospitalId;

  factory OnlineHospitalUser.fromJson(Map<String, dynamic> json) {
    final id = int.tryParse(json['id'].toString());
    final hospitalId = json['hospitalId']?.toString();
    if (id == null || hospitalId == null || !RegExp(r'^\d{12}$').hasMatch(hospitalId)) {
      throw const HospitalApiException('The server returned an invalid Hospital account.');
    }
    final role = json['role'] as String?;
    if (role == null || role == 'SUPER_ADMIN') {
      throw const HospitalApiException('A Hospital account is required.');
    }
    return OnlineHospitalUser(
      id: id,
      username: json['username'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      role: role,
      hospitalId: hospitalId,
    );
  }
}

class OnlineHospitalProfile {
  const OnlineHospitalProfile({
    required this.hospitalId,
    required this.name,
    required this.code,
    required this.type,
    this.address,
    this.email,
    this.phone,
  });

  final String hospitalId;
  final String name;
  final String code;
  final String type;
  final String? address;
  final String? email;
  final String? phone;

  factory OnlineHospitalProfile.fromJson(Map<String, dynamic> json) {
    final id = json['hospitalId']?.toString();
    if (id == null || !RegExp(r'^\d{12}$').hasMatch(id)) {
      throw const HospitalApiException('The server returned an invalid Hospital profile.');
    }
    return OnlineHospitalProfile(
      hospitalId: id,
      name: json['name'] as String? ?? '',
      code: json['code'] as String? ?? '',
      type: json['type'] as String? ?? '',
      address: json['address'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
    );
  }
}

abstract interface class OnlineTokenStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

class SecureOnlineTokenStore implements OnlineTokenStore {
  SecureOnlineTokenStore(this._storage);

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) => _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

class OnlineHospitalSessionState {
  const OnlineHospitalSessionState({
    this.isRestoring = true,
    this.isLoading = false,
    this.user,
    this.hospital,
    this.error,
  });

  const OnlineHospitalSessionState.signedOutWithError(String message)
      : this(isRestoring: false, error: message);

  final bool isRestoring;
  final bool isLoading;
  final OnlineHospitalUser? user;
  final OnlineHospitalProfile? hospital;
  final String? error;

  bool get isAuthenticated => user != null && hospital != null;

  static const signedOut = OnlineHospitalSessionState(isRestoring: false);
}

class OnlineHospitalSessionNotifier extends StateNotifier<OnlineHospitalSessionState> {
  OnlineHospitalSessionNotifier(this._api, this._tokens, {bool autoRestore = true})
      : super(const OnlineHospitalSessionState()) {
    if (autoRestore) unawaited(restore());
  }

  static const _accessTokenKey = 'caresync.online.access_token';
  static const _refreshTokenKey = 'caresync.online.refresh_token';

  final HospitalApiClient _api;
  final OnlineTokenStore _tokens;

  Future<void> restore() async {
    state = const OnlineHospitalSessionState(isRestoring: true);
    try {
      final access = await _tokens.read(_accessTokenKey);
      final refresh = await _tokens.read(_refreshTokenKey);
      if (access == null || refresh == null || access.isEmpty || refresh.isEmpty) {
        await _clearTokens();
        state = OnlineHospitalSessionState.signedOut;
        return;
      }
      await _loadSession(access, refresh);
    } catch (_) {
      state = OnlineHospitalSessionState.signedOutWithError(
          'Secure session storage is unavailable. Please try again.');
    }
  }

  Future<String?> login({
    required String hospitalId,
    required String username,
    required String password,
  }) async {
    state = const OnlineHospitalSessionState(isRestoring: false, isLoading: true);
    try {
      final response = await _api.hospitalLogin(
        hospitalId: hospitalId,
        username: username,
        password: password,
      );
      final access = response['accessToken'] as String?;
      final refresh = response['refreshToken'] as String?;
      final userJson = response['user'];
      if (access == null || refresh == null || userJson is! Map<String, dynamic>) {
        throw const HospitalApiException('The server returned an invalid login response.');
      }
      final user = OnlineHospitalUser.fromJson(userJson);
      if (user.hospitalId != hospitalId) {
        throw const HospitalApiException('The account does not belong to the selected Hospital.');
      }
      await _writeTokens(access, refresh);
      await _loadSession(access, refresh);
      if (!state.isAuthenticated) throw const HospitalApiException('Hospital access is unavailable.');
      return null;
    } on HospitalApiException catch (error) {
      await _clearTokens();
      state = OnlineHospitalSessionState.signedOutWithError(error.message);
      return error.message;
    } catch (_) {
      await _clearTokens();
      state = OnlineHospitalSessionState.signedOutWithError('Cannot establish a secure server session.');
      return state.error;
    }
  }

  Future<void> refresh() async {
    final access = await _tokens.read(_accessTokenKey);
    final refreshToken = await _tokens.read(_refreshTokenKey);
    if (access == null || refreshToken == null) {
      await _expireSession();
      return;
    }
    state = OnlineHospitalSessionState(isLoading: true, user: state.user, hospital: state.hospital);
    await _loadSession(access, refreshToken);
  }

  Future<bool> logout() async {
    var serverRevoked = false;
    try {
      final refresh = await _tokens.read(_refreshTokenKey);
      if (refresh != null && refresh.isNotEmpty) {
        await _api.logout(refresh);
        serverRevoked = true;
      } else {
        serverRevoked = true;
      }
    } catch (_) {
      serverRevoked = false;
    } finally {
      await _clearTokens();
      state = OnlineHospitalSessionState.signedOut;
    }
    return serverRevoked;
  }

  Future<void> _loadSession(String access, String refresh) async {
    try {
      var currentAccess = access;
      Map<String, dynamic> userJson;
      Map<String, dynamic> hospitalJson;
      try {
        userJson = await _api.currentUser(currentAccess);
        hospitalJson = await _api.currentHospital(currentAccess);
      } on HospitalApiException catch (error) {
        if (error.statusCode != 401) rethrow;
        final pair = await _api.refreshSession(refresh);
        final refreshedAccess = pair['accessToken'] as String?;
        final refreshedToken = pair['refreshToken'] as String?;
        if (refreshedAccess == null || refreshedToken == null) rethrow;
        currentAccess = refreshedAccess;
        await _writeTokens(refreshedAccess, refreshedToken);
        userJson = await _api.currentUser(currentAccess);
        hospitalJson = await _api.currentHospital(currentAccess);
      }
      final user = OnlineHospitalUser.fromJson(userJson);
      final hospital = OnlineHospitalProfile.fromJson(hospitalJson);
      if (user.hospitalId != hospital.hospitalId) {
        throw const HospitalApiException('The server returned mismatched Hospital context.');
      }
      state = OnlineHospitalSessionState(isRestoring: false, user: user, hospital: hospital);
    } on HospitalApiException catch (error) {
      final invalidSession = error.statusCode == 401 || error.statusCode == 403;
      if (invalidSession) await _clearTokens();
      state = OnlineHospitalSessionState.signedOutWithError(invalidSession
          ? 'Your server session has expired.'
          : 'The Hospital server is temporarily unavailable. Retry to restore your session.');
    } catch (_) {
      state = OnlineHospitalSessionState.signedOutWithError(
          'The Hospital server is temporarily unavailable. Retry to restore your session.');
    }
  }

  Future<void> _writeTokens(String access, String refresh) async {
    await _tokens.write(_accessTokenKey, access);
    await _tokens.write(_refreshTokenKey, refresh);
  }

  Future<void> _clearTokens() async {
    try {
      await _tokens.delete(_accessTokenKey);
    } catch (_) {}
    try {
      await _tokens.delete(_refreshTokenKey);
    } catch (_) {}
  }

  Future<void> _expireSession() async {
    await _clearTokens();
    state = OnlineHospitalSessionState.signedOutWithError('Your server session has expired. Please sign in again.');
  }
}

final onlineHospitalSessionProvider =
    StateNotifierProvider<OnlineHospitalSessionNotifier, OnlineHospitalSessionState>((ref) {
  return OnlineHospitalSessionNotifier(
    ref.read(hospitalApiClientProvider),
    SecureOnlineTokenStore(const FlutterSecureStorage()),
  );
});
