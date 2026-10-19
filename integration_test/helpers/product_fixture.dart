// Local QA only: synthetic identity, document and explicit admin review.
import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:dio/dio.dart';
import 'package:daengle/core/api.dart';

class _MemoryStore implements TokenStore {
  String? value;
  @override
  Future<String?> read() async => value;
  @override
  Future<void> write(String next) async {
    value = next;
  }

  @override
  Future<void> clear() async {
    value = null;
  }
}

class ProductFixture {
  final accounts = <Api>[];
  final dogIds = <String>[];
  final meetupIds = <String>[];
  Dio? admin;
  Api get api => accounts[1];
  Future<void> prepare() async {
    const base = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://localhost:4000/v1',
    );
    if (![
      'localhost',
      '127.0.0.1',
      '10.0.2.2',
    ].contains(Uri.parse(base).host)) {
      throw StateError(
        'This QA fixture only supports a local development server.',
      );
    }
    final stamp = DateTime.now().microsecondsSinceEpoch;
    admin = Dio(BaseOptions(baseUrl: base));
    final login = await admin!.post<dynamic>(
      '/admin/login',
      data: {
        'email': const String.fromEnvironment(
          'LOCAL_ADMIN_EMAIL',
          defaultValue: 'admin@daengle.local',
        ),
        'password': const String.fromEnvironment(
          'LOCAL_ADMIN_PASSWORD',
          defaultValue: 'LocalAdmin-ChangeMe!2026',
        ),
      },
    );
    admin!.options.headers['Cookie'] = login.headers['set-cookie']!
        .map((c) => c.split(';').first)
        .join('; ');
    admin!.options.headers['X-CSRF-Token'] = object(login.data)['csrfToken'];
    final proof = base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAIAAAD8GO2jAAAACXBIWXMAAAPoAAAD6AG1e1JrAAAAMUlEQVR4nO3QMQ0AAAjAMPybBgm7+FoDSzb7bASKRcmiZFGyKFmULEoWJYuSRel90QGLVfSm++z7fAAAAABJRU5ErkJggg==',
    );
    for (var i = 0; i < 2; i++) {
      final account = Api(baseUrl: base, tokenStore: _MemoryStore());
      account.http.interceptors.add(
        InterceptorsWrapper(
          onError: (error, handler) {
            debugPrint(
              'QA transport failure: ${error.type.name}; HTTP ${error.response?.statusCode}; method ${error.requestOptions.method}',
            );
            handler.next(error);
          },
        ),
      );
      accounts.add(account);
      final t = object(
        await account.call(
          '/auth/identity/transactions',
          method: 'POST',
          authenticated: false,
          data: {'returnUrl': 'http://localhost:8081'},
        ),
      );
      if (t['provider'] != 'development') {
        throw StateError('Development identity provider required.');
      }
      await account.call(
        '/dev/identity/${t['transactionId']}',
        method: 'POST',
        authenticated: false,
        data: {
          'subject': 'product-qa-$stamp-$i',
          'birthDate': '1990-01-01',
          'gender': 'OTHER',
        },
      );
      final exchange = object(
        await account.call(
          '/auth/identity/exchange',
          method: 'POST',
          authenticated: false,
          data: {'transactionId': t['transactionId'], 'nonce': t['nonce']},
        ),
      );
      final terms = items(await account.call('/terms', authenticated: false));
      await account.establish(
        object(
          await account.call(
            '/auth/registrations',
            method: 'POST',
            authenticated: false,
            data: {
              'ticket': exchange['ticket'],
              'consentVersionIds': terms
                  .where((t) => t['required'] == true || t['required'] == 1)
                  .map((t) => t['id'])
                  .toList(),
            },
          ),
        ),
      );
      final me = object(await account.call('/me'));
      await account.call(
        '/me/profile',
        method: 'PATCH',
        data: {
          'displayName': i == 0 ? '감자 견주' : '두부 견주',
          'walkDays': [1, 2, 3],
          'walkPeriods': ['EVENING'],
          'maxWalkMinutes': 30,
          'version': object(me['profile'])['version'],
        },
      );
      final dog = object(
        await account.call(
          '/dogs',
          method: 'POST',
          data: {
            'name': i == 0 ? '감자' : '두부',
            'breed': '믹스',
            'birthDate': '2022-01-01',
            'birthIsEstimated': false,
            'size': 'SMALL',
            'traits': ['친근함'],
            'precautions': '',
            'photoUploadIds': [],
          },
        ),
      );
      dogIds.add(label(dog['id']));
      await account.call(
        '/region-verifications',
        method: 'POST',
        data: {
          'latitude': 37.5445,
          'longitude': 127.0374,
          'accuracy': 20,
          'measuredAt': DateTime.now().toUtc().toIso8601String(),
        },
      );
      final upload = object(
        await account.call(
          '/uploads',
          method: 'POST',
          data: {
            'purpose': 'HEALTH_DOCUMENT',
            'filename': 'synthetic-qa.png',
            'contentType': 'image/png',
            'size': proof.length,
            'resourceId': dog['id'],
          },
        ),
      );
      await Dio().put<dynamic>(
        label(upload['uploadUrl']),
        data: Stream.value(proof),
        options: Options(
          headers: {
            ...object(upload['headers']),
            'Content-Length': proof.length,
          },
        ),
      );
      await account.call('/uploads/${upload['id']}/complete', method: 'POST');
      var ready = false;
      for (var attempt = 0; attempt < 60; attempt++) {
        if (object(await account.call('/uploads/${upload['id']}'))['status'] ==
            'READY') {
          ready = true;
          break;
        }
        await Future<void>.delayed(const Duration(milliseconds: 500));
      }
      if (!ready) {
        throw StateError('Storage worker did not process synthetic document.');
      }
      final submission = object(
        await account.call(
          '/dogs/${dog['id']}/health-submissions',
          method: 'POST',
          data: {
            'uploadIds': [upload['id']],
            'note': '합성 QA 자료',
          },
        ),
      );
      await admin!.post<dynamic>(
        '/admin/reviews',
        data: {
          'submissionId': submission['id'],
          'decision': 'APPROVED',
          'reason': '합성 로컬 QA 자료',
          'internalNote': '',
          'verifiedItems': ['합성 자료'],
          'validUntil': DateTime.now()
              .add(const Duration(days: 1))
              .toUtc()
              .toIso8601String(),
          'version': 1,
        },
      );
    }
    final region = object(await accounts[0].call('/me/region-verification'));
    final places = items(
      await accounts[0].call(
        '/places',
        query: {'regionId': region['regionId']},
      ),
    );
    if (places.isEmpty) throw StateError('Seeded public place required.');
    for (var i = 0; i < 3; i++) {
      final meetup = object(
        await accounts[0].call(
          '/meetups',
          method: 'POST',
          idempotencyKey: uuid.v4(),
          data: {
            'channelId': null,
            'title': ['저녁 공원 산책', '주말 강변 산책', '취소된 아침 산책'][i],
            'description': '합성 QA 약속입니다.',
            'kind': 'SCHEDULED',
            'activities': ['WALK'],
            'placeId': places.first['id'],
            'startsAt': DateTime.now()
                .add(Duration(hours: i + 1))
                .toUtc()
                .toIso8601String(),
            'endsAt': DateTime.now()
                .add(Duration(hours: i + 2))
                .toUtc()
                .toIso8601String(),
            'capacity': 4,
            'dogIds': [dogIds[0]],
            'allowedSizes': ['SMALL'],
          },
        ),
      );
      meetupIds.add(label(meetup['id']));
      final application = object(
        await api.call(
          '/meetups/${meetup['id']}/applications',
          method: 'POST',
          data: {
            'dogIds': [dogIds[1]],
          },
        ),
      );
      if (i != 1) {
        await accounts[0].call(
          '/meetup-applications/${application['id']}/approve',
          method: 'POST',
        );
      }
      if (i == 2) {
        await accounts[0].call(
          '/meetups/${meetup['id']}/cancel',
          method: 'POST',
        );
      }
    }
  }

  Future<void> dispose() async {
    if (accounts.isNotEmpty) {
      for (final id in meetupIds) {
        try {
          await accounts[0].call('/meetups/$id/cancel', method: 'POST');
        } catch (_) {
          /* Continue independent fixture cleanup. */
        }
      }
    }
    for (var i = 0; i < accounts.length; i++) {
      if (accounts[i].accessToken == null) continue;
      if (i < dogIds.length) {
        await accounts[i].call('/dogs/${dogIds[i]}/archive', method: 'POST');
      }
      await accounts[i].call(
        '/me/withdrawal',
        method: 'POST',
        data: {'confirmation': '탈퇴합니다'},
      );
      await accounts[i].forget();
    }
    if (admin != null) {
      if (admin!.options.headers['Cookie'] != null) {
        await admin!.delete<dynamic>('/admin/session');
      }
      admin!.close();
    }
  }
}
