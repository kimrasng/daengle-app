import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daengle/core/api.dart';

class MemoryStore implements TokenStore {
  String? value;
  @override
  Future<String?> read() async => value;
  @override
  Future<void> write(String value) async {
    this.value = value;
  }

  @override
  Future<void> clear() async {
    value = null;
  }
}

class Adapter implements HttpClientAdapter {
  final Future<ResponseBody> Function(RequestOptions options) handler;
  Adapter(this.handler);
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) => handler(options);
  @override
  void close({bool force = false}) {}
}

ResponseBody response(int status, Json body) => ResponseBody.fromString(
  jsonEncode(body),
  status,
  headers: {
    Headers.contentTypeHeader: ['application/json'],
  },
);
void main() {
  test(
    'concurrent unauthorized requests rotate refresh credentials only once',
    () async {
      final store = MemoryStore();
      var refreshes = 0;
      final client = Dio(BaseOptions(baseUrl: 'http://localhost/v1'));
      client.httpClientAdapter = Adapter((options) async {
        if (options.path == '/auth/refresh') {
          refreshes++;
          await Future<void>.delayed(const Duration(milliseconds: 20));
          return response(200, {
            'accessToken': 'new-access',
            'refreshToken': 'new-refresh',
            'userId': 'user',
          });
        }
        if (options.headers['Authorization'] != 'Bearer new-access') {
          return response(401, {'message': 'expired'});
        }
        return response(200, {'ok': true});
      });
      final api = Api(client: client, tokenStore: store);
      await api.establish({
        'accessToken': 'old-access',
        'refreshToken': 'old-refresh',
        'userId': 'user',
      });
      await Future.wait([
        api.call('/me'),
        api.call('/dogs'),
        api.call('/rooms'),
      ]);
      expect(refreshes, 1);
      expect(jsonDecode(store.value!)['refreshToken'], 'new-refresh');
      expect(store.value, isNot(contains('new-access')));
    },
  );
  test(
    'transient refresh failure preserves credentials; unauthorized clears them',
    () async {
      final store = MemoryStore();
      var status = 503;
      final client = Dio(BaseOptions(baseUrl: 'http://localhost/v1'));
      client.httpClientAdapter = Adapter(
        (_) async => response(status, {'message': 'retry'}),
      );
      final api = Api(client: client, tokenStore: store);
      await api.establish({'accessToken': 'a', 'refreshToken': 'r'});
      await expectLater(api.refresh(), throwsA(isA<ApiFailure>()));
      expect(store.value, isNotNull);
      status = 401;
      await expectLater(api.refresh(), throwsA(isA<ApiFailure>()));
      expect(store.value, isNull);
      expect(api.session, isNull);
    },
  );
  test('authenticated retry preserves body and idempotency key', () async {
    final requests = <RequestOptions>[];
    final client = Dio(BaseOptions(baseUrl: 'http://localhost/v1'));
    client.httpClientAdapter = Adapter((options) async {
      if (options.path == '/auth/refresh') {
        return response(200, {'accessToken': 'b', 'refreshToken': 's'});
      }
      requests.add(options);
      return options.headers['Authorization'] == 'Bearer a'
          ? response(401, {})
          : response(201, {'id': 'proposal'});
    });
    final api = Api(client: client, tokenStore: MemoryStore());
    await api.establish({'accessToken': 'a', 'refreshToken': 'r'});
    await api.call(
      '/proposals',
      method: 'POST',
      data: {
        'dogIds': ['dog'],
      },
      idempotencyKey: 'stable-key',
    );
    expect(requests.length, 2);
    expect(requests.map((r) => r.headers['Idempotency-Key']).toSet(), {
      'stable-key',
    });
    expect(requests.first.data, requests.last.data);
  });
}
