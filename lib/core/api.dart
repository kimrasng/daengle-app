import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

typedef Json = Map<String, dynamic>;
Json object(dynamic value) =>
    value is Map ? Map<String, dynamic>.from(value) : {};
List<Json> records(dynamic value) =>
    value is List ? value.map(object).toList() : [];
List<Json> items(dynamic value) => records(object(value)['items']);
String label(dynamic value) => value?.toString() ?? '';
const uuid = Uuid();

abstract interface class TokenStore {
  Future<String?> read();
  Future<void> write(String value);
  Future<void> clear();
}

class SecureTokenStore implements TokenStore {
  final FlutterSecureStorage storage;
  SecureTokenStore([this.storage = const FlutterSecureStorage()]);
  @override
  Future<String?> read() => storage.read(key: 'daengle.session.v1');
  @override
  Future<void> write(String value) =>
      storage.write(key: 'daengle.session.v1', value: value);
  @override
  Future<void> clear() => storage.delete(key: 'daengle.session.v1');
}

class ApiFailure implements Exception {
  final String message, code;
  final int? status;
  const ApiFailure(this.message, {this.code = '', this.status});
  @override
  String toString() => message;
}

class Api extends ChangeNotifier {
  final Dio http;
  final TokenStore store;
  Json? session;
  Future<void>? _refreshing;
  Api({String? baseUrl, Dio? client, TokenStore? tokenStore})
    : http =
          client ??
          Dio(
            BaseOptions(
              baseUrl:
                  baseUrl ??
                  const String.fromEnvironment(
                    'API_BASE_URL',
                    defaultValue: 'http://localhost:4000/v1',
                  ),
              connectTimeout: const Duration(seconds: 12),
              receiveTimeout: const Duration(seconds: 20),
            ),
          ),
      store = tokenStore ?? SecureTokenStore();
  String? get accessToken => session?['accessToken'] as String?;
  String? get userId => session?['userId'] as String?;
  String get origin => http.options.baseUrl.replaceFirst(RegExp(r'/v1/?$'), '');
  Future<void> restore() async {
    final raw = await store.read();
    if (raw == null) return;
    try {
      session = object(jsonDecode(raw));
    } on FormatException {
      await forget();
      return;
    }
    if (session?['refreshToken'] == null) {
      await forget();
      return;
    }
    // Restore only refresh credentials. Access tokens stay in memory.
    await refresh();
  }

  Future<void> establish(Json value) async {
    session = value;
    await store.write(
      jsonEncode({
        'refreshToken': value['refreshToken'],
        'userId': value['userId'],
      }),
    );
    notifyListeners();
  }

  Future<void> forget() async {
    session = null;
    await store.clear();
    notifyListeners();
  }

  Future<void> refresh() async {
    if (_refreshing != null) return _refreshing;
    final future = _rotate();
    _refreshing = future;
    try {
      await future;
    } finally {
      _refreshing = null;
    }
  }

  Future<void> _rotate() async {
    final token = session?['refreshToken'];
    if (token == null) throw const ApiFailure('다시 로그인해주세요.', status: 401);
    try {
      final response = await http.post(
        '/auth/refresh',
        data: {'refreshToken': token},
      );
      await establish(object(response.data));
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) await forget();
      throw failure(e);
    }
  }

  Future<dynamic> call(
    String path, {
    String method = 'GET',
    Json? data,
    Json? query,
    String? idempotencyKey,
    bool authenticated = true,
    ResponseType? responseType,
  }) async {
    // Capture the token so concurrent 401s do not rotate the same refresh token twice.
    final sentToken = accessToken;
    Future<Response<dynamic>> send() => http.request(
      path,
      data: data,
      queryParameters: query,
      options: Options(
        method: method,
        responseType: responseType,
        headers: {
          if (authenticated && accessToken != null)
            'Authorization': 'Bearer $accessToken',
          'Idempotency-Key': ?idempotencyKey,
        },
      ),
    );
    try {
      return (await send()).data;
    } on DioException catch (e) {
      if (authenticated && e.response?.statusCode == 401 && session != null) {
        if (sentToken == accessToken) await refresh();
        try {
          return (await send()).data;
        } on DioException catch (retry) {
          if (retry.response?.statusCode == 401) await forget();
          throw failure(retry);
        }
      }
      throw failure(e);
    }
  }

  static ApiFailure failure(DioException e) {
    final body = object(e.response?.data);
    return ApiFailure(
      label(body['message']).isEmpty
          ? '서버에 연결하지 못했어요. 네트워크와 서버 주소를 확인하고 다시 시도해주세요.'
          : label(body['message']),
      code: label(body['code']),
      status: e.response?.statusCode,
    );
  }

  Future<void> logout() async {
    await call('/auth/session', method: 'DELETE');
    await forget();
  }
}

/// Keep an uncertain network retry identical; allow editing after a known rejection.
Future<dynamic> submitSnapshot(
  Api api,
  String path, {
  required String method,
  required Json? data,
  String? idempotencyKey,
  required VoidCallback onRejected,
}) async {
  try {
    return await api.call(
      path,
      method: method,
      data: data,
      idempotencyKey: idempotencyKey,
    );
  } on ApiFailure catch (e) {
    if (e.status != null && e.status! >= 400 && e.status! < 500) onRejected();
    rethrow;
  }
}
