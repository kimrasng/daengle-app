// Opt-in only. Creates synthetic users in the local development backend and
// withdraws them in finally. Never point this test at an operating service.
import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:daengle/core/api.dart';

import 'core/api_test.dart' show MemoryStore;

void main() {
  test(
    'local backend: registration → review → proposal → DM → community → meetup',
    () async {
      const base = String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'http://localhost:4000/v1',
      );
      final host = Uri.parse(base).host;
      expect(
        ['localhost', '127.0.0.1'].contains(host),
        true,
        reason: 'Local development server only',
      );
      final admin = Dio(BaseOptions(baseUrl: base));
      final accounts = <Api>[];
      final dogs = <String>[];
      String? channel, meetup;
      io.Socket? socket;
      final stamp = DateTime.now().microsecondsSinceEpoch;
      final login = await admin.post<dynamic>(
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
      admin.options.headers['Cookie'] = login.headers['set-cookie']!
          .map((c) => c.split(';').first)
          .join('; ');
      admin.options.headers['X-CSRF-Token'] = object(login.data)['csrfToken'];
      try {
        final proof = await File('test/fixtures/development-document.png')
            .readAsBytes();
        for (var i = 0; i < 2; i++) {
          final api = Api(baseUrl: base, tokenStore: MemoryStore());
          accounts.add(api);
          final transaction = object(
            await api.call(
              '/auth/identity/transactions',
              method: 'POST',
              authenticated: false,
              data: {'returnUrl': 'http://localhost:8081'},
            ),
          );
          expect(transaction['provider'], 'development');
          await api.call(
            '/dev/identity/${transaction['transactionId']}',
            method: 'POST',
            authenticated: false,
            data: {
              'subject': 'flutter-test-$stamp-$i',
              'birthDate': '1990-01-01',
              'gender': 'OTHER',
            },
          );
          final exchange = object(
            await api.call(
              '/auth/identity/exchange',
              method: 'POST',
              authenticated: false,
              data: {
                'transactionId': transaction['transactionId'],
                'nonce': transaction['nonce'],
              },
            ),
          );
          final terms = items(await api.call('/terms', authenticated: false));
          await api.establish(
            object(
              await api.call(
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
          final me = object(await api.call('/me'));
          await api.call(
            '/me/profile',
            method: 'PATCH',
            data: {
              'displayName': 'Flutter 검증 $i',
              'walkDays': [1, 2, 3],
              'walkPeriods': ['EVENING'],
              'maxWalkMinutes': 30,
              'version': object(me['profile'])['version'],
            },
          );
          await api.call(
            '/me/onboarding-draft',
            method: 'PUT',
            data: {
              'stage': 'DOG',
              'version': 0,
              'payload': {
                'dog': {'name': '검증 강아지'},
              },
            },
          );
          expect(object(await api.call('/me/onboarding-draft'))['version'], 1);
          final dog = object(
            await api.call(
              '/dogs',
              method: 'POST',
              data: {
                'name': 'Flutter 검증견 $i',
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
          dogs.add(label(dog['id']));
          await api.call('/me/onboarding-draft', method: 'DELETE');
          await api.call(
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
            await api.call(
              '/uploads',
              method: 'POST',
              data: {
                'purpose': 'HEALTH_DOCUMENT',
                'filename': 'development-document.png',
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
          await api.call('/uploads/${upload['id']}/complete', method: 'POST');
          var ready = false;
          for (var attempt = 0; attempt < 40; attempt++) {
            if (object(await api.call('/uploads/${upload['id']}'))['status'] ==
                'READY') {
              ready = true;
              break;
            }
            await Future<void>.delayed(const Duration(milliseconds: 500));
          }
          expect(
            ready,
            true,
            reason: 'Storage worker must process uploaded document',
          );
          final submission = object(
            await api.call(
              '/dogs/${dog['id']}/health-submissions',
              method: 'POST',
              data: {
                'uploadIds': [upload['id']],
                'note': '합성 개발 자료 · Flutter 통합 검증',
              },
            ),
          );
          await admin.post<dynamic>(
            '/admin/reviews',
            data: {
              'submissionId': submission['id'],
              'decision': 'APPROVED',
              'reason': '합성 Flutter 통합 검증 자료',
              'internalNote': '',
              'verifiedItems': ['합성 자료'],
              'validUntil': DateTime.now()
                  .add(const Duration(days: 1))
                  .toUtc()
                  .toIso8601String(),
              'version': 1,
            },
          );
          expect(
            object(await api.call('/me/capabilities'))['canPropose'],
            true,
          );
          final test = object(await api.call('/personality-tests/current'));
          final result = object(
            await api.call(
              '/dogs/${dog['id']}/personality-results',
              method: 'POST',
              data: {
                'testVersionId': test['id'],
                'answers': [
                  for (final q in records(test['questions']))
                    {'questionId': q['id'], 'value': 3},
                ],
              },
            ),
          );
          expect(result['code'], isNotEmpty);
          await api.refresh();
        }
        final alice = accounts[0], bob = accounts[1];
        final discovery = items(
          await alice.call(
            '/discovery/dogs',
            query: {'radiusMeters': 5000, 'limit': 100},
          ),
        );
        expect(discovery.any((d) => d['id'] == dogs[1]), true);
        final body = {
          'recipientId': bob.userId,
          'targetDogId': dogs[1],
          'dogIds': [dogs[0]],
          'activities': ['WALK', 'CAFE'],
        };
        expect(
          object(
            await alice.call('/proposal-previews', method: 'POST', data: body),
          )['title'],
          isNotEmpty,
        );
        final key = uuid.v4();
        final proposal = object(
          await alice.call(
            '/proposals',
            method: 'POST',
            data: body,
            idempotencyKey: key,
          ),
        );
        expect(
          object(
            await alice.call(
              '/proposals',
              method: 'POST',
              data: body,
              idempotencyKey: key,
            ),
          )['id'],
          proposal['id'],
        );
        final accepted = object(
          await bob.call(
            '/proposals/${proposal['id']}/accept',
            method: 'POST',
            data: {
              'dogIds': [dogs[1]],
            },
          ),
        );
        final room = label(accepted['roomId']);
        final connected = Completer<void>(), delivered = Completer<void>();
        socket = io.io(
          alice.origin,
          io.OptionBuilder()
              .setTransports(['websocket'])
              .disableAutoConnect()
              .enableForceNew()
              .setAuth({'accessToken': alice.accessToken})
              .build(),
        );
        socket.onConnect(
          (_) => socket!.emitWithAck(
            'room.subscribe',
            {'roomId': room},
            ack: (dynamic ack) {
              if (object(ack)['ok'] == true && !connected.isCompleted) {
                connected.complete();
              }
            },
          ),
        );
        socket.on('message.created', (dynamic event) {
          if (object(object(event)['data'])['roomId'] == room &&
              !delivered.isCompleted) {
            delivered.complete();
          }
        });
        socket.connect();
        await connected.future.timeout(const Duration(seconds: 15));
        final messageBody = {
          'clientMessageId': uuid.v4(),
          'text': 'Flutter 통합 검증 인사',
          'uploadIds': <String>[],
        };
        final message = object(
          await bob.call(
            '/rooms/$room/messages',
            method: 'POST',
            data: messageBody,
          ),
        );
        expect(
          object(
            await bob.call(
              '/rooms/$room/messages',
              method: 'POST',
              data: messageBody,
            ),
          )['id'],
          message['id'],
        );
        await delivered.future.timeout(const Duration(seconds: 20));
        final history = items(
          await alice.call('/rooms/$room/messages', query: {'afterSeq': 0}),
        );
        expect(history.where((m) => m['id'] == message['id']).length, 1);
        await alice.call(
          '/rooms/$room/read-position',
          method: 'PUT',
          data: {'seq': message['seq']},
        );
        final friend = object(
          await alice.call(
            '/friend-requests',
            method: 'POST',
            data: {'recipientId': bob.userId},
          ),
        );
        await bob.call(
          '/friend-requests/${friend['id']}/accept',
          method: 'POST',
        );
        expect(
          items(await alice.call('/friends'))
              .any((f) => f['userId'] == bob.userId),
          true,
        );
        final regions = items(await alice.call('/regions'));
        final region = object(await alice.call('/me/region-verification'));
        expect(regions.any((r) => r['id'] == region['regionId']), true);
        final channelResult = object(
          await alice.call(
            '/channels',
            method: 'POST',
            idempotencyKey: uuid.v4(),
            data: {
              'name': 'Flutter 검증 채널',
              'description': '합성 개발 검증',
              'type': 'INTEREST',
              'regionId': region['regionId'],
            },
          ),
        );
        channel = label(channelResult['id']);
        await bob.call('/channels/$channel/memberships', method: 'POST');
        final post = object(
          await alice.call(
            '/posts',
            method: 'POST',
            idempotencyKey: uuid.v4(),
            data: {
              'channelId': channel,
              'title': 'Flutter 검증 이야기',
              'body': '실제 백엔드 연결을 확인합니다.',
              'uploadIds': [],
            },
          ),
        );
        await bob.call(
          '/posts/${post['id']}/comments',
          method: 'POST',
          data: {'body': '연결 확인'},
        );
        expect(
          items(await alice.call('/posts/${post['id']}/comments')).length,
          1,
        );
        final places = items(
          await alice.call('/places', query: {'regionId': region['regionId']}),
        );
        final start = DateTime.now().add(const Duration(hours: 1));
        final meeting = object(
          await alice.call(
            '/meetups',
            method: 'POST',
            idempotencyKey: uuid.v4(),
            data: {
              'title': 'Flutter 검증 산책',
              'kind': 'SCHEDULED',
              'activities': ['WALK'],
              'placeId': places.first['id'],
              'startsAt': start.toUtc().toIso8601String(),
              'endsAt': start
                  .add(const Duration(hours: 1))
                  .toUtc()
                  .toIso8601String(),
              'capacity': 4,
              'dogIds': [dogs[0]],
            },
          ),
        );
        meetup = label(meeting['id']);
        final application = object(
          await bob.call(
            '/meetups/$meetup/applications',
            method: 'POST',
            data: {
              'dogIds': [dogs[1]],
            },
          ),
        );
        await alice.call(
          '/meetup-applications/${application['id']}/approve',
          method: 'POST',
        );
        expect(
          records(object(await bob.call('/meetups/$meetup'))['participants'])
              .length,
          2,
        );
        expect(items(await bob.call('/notifications')), isNotEmpty);
      } finally {
        socket?.dispose();
        if (accounts.isNotEmpty && accounts[0].accessToken != null) {
          if (meetup != null) {
            await accounts[0].call('/meetups/$meetup/cancel', method: 'POST');
          }
          if (channel != null) {
            await accounts[0].call(
              '/channels/$channel/archive',
              method: 'POST',
            );
          }
        }
        for (var i = 0; i < accounts.length; i++) {
          if (accounts[i].accessToken == null) continue;
          if (i < dogs.length) {
            await accounts[i].call('/dogs/${dogs[i]}/archive', method: 'POST');
          }
          await accounts[i].call(
            '/me/withdrawal',
            method: 'POST',
            data: {'confirmation': '탈퇴합니다'},
          );
          await accounts[i].forget();
          accounts[i].http.close();
        }
        await admin.delete<dynamic>('/admin/session');
        admin.close();
      }
    },
    skip: !const bool.fromEnvironment('RUN_LOCAL_BACKEND_TESTS'),
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
