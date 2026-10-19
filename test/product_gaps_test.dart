import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daengle/core/api.dart';
import 'package:daengle/features/community.dart';
import 'package:daengle/features/home.dart';
import 'package:daengle/features/notifications.dart';
import 'package:daengle/features/readiness.dart';
import 'package:daengle/features/social.dart';
import 'package:daengle/main.dart';
import 'package:daengle/ui/shared.dart';

import 'widget_test.dart' show FakeApi;

class ProductApi extends FakeApi {
  String failureCode = '';
  final scopes = <String>[];
  final radii = <int>[];
  String? readThrough;
  String snapshot = '2026-10-18T02:00:00.000Z';
  Completer<void>? readCompletion;
  bool read = false;
  final notification = <String, dynamic>{
    'id': 'notice',
    'kind': 'meetups',
    'title': '모임 신청 결과가 도착했어요',
    'created_at': '2026-10-18T01:00:00Z',
  };
  Json meetup(String scope) => {
    'id': scope,
    'title': switch (scope) {
      'PENDING' => '신청한 저녁 산책',
      'HISTORY' => '취소된 아침 산책',
      _ => '확정된 공원 산책',
    },
    'status': scope == 'HISTORY' ? 'CANCELLED' : 'OPEN',
    'role': 'PARTICIPANT',
    'participationStatus': scope == 'PENDING' ? 'PENDING' : 'ACTIVE',
    'placeName': '동네 공원',
    'startsAt': '2026-10-19T10:00:00Z',
  };
  @override
  Future<dynamic> call(
    String path, {
    String method = 'GET',
    Json? data,
    Json? query,
    String? idempotencyKey,
    bool authenticated = true,
    dynamic responseType,
  }) async {
    switch (path) {
      case '/discovery/dogs':
        radii.add(query?['radiusMeters'] as int? ?? 5000);
        if (failureCode.isNotEmpty) {
          throw ApiFailure('활동을 준비해주세요.', code: failureCode, status: 403);
        }
        return {'items': []};
      case '/me/meetups':
        final scope = query?['scope'] as String? ?? 'UPCOMING';
        scopes.add(scope);
        return {
          'items': [meetup(scope)],
        };
      case '/home':
        final home = object(await super.call(path));
        return {
          ...home,
          'upcomingMeetups': {
            'items': [meetup('UPCOMING')],
          },
        };
      case '/notifications/summary':
        return {'unreadCount': read ? 0 : 1, 'asOf': snapshot};
      case '/notifications/read-all':
        readThrough = data?['before'] as String?;
        read = true;
        return {'updated': 1};
      case '/notifications/notice/read':
        await readCompletion?.future;
        read = true;
        return {'ok': true};
      case '/notifications':
        return {
          'items': query?['unreadOnly'] == 'true' && read
              ? []
              : [
                  {
                    ...notification,
                    'readAt': read ? '2026-10-18T02:00:00Z' : null,
                  },
                ],
        };
      default:
        return super.call(path, method: method, data: data, query: query);
    }
  }
}

Widget app(Widget screen, {double scale = 1}) => MaterialApp(
  theme: buildAppTheme(),
  navigatorObservers: [routeObserver],
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
    child: child!,
  ),
  home: screen,
);

void main() {
  testWidgets(
    'recommendation cards display reason labels without transport codes',
    (tester) async {
      await tester.pumpWidget(
        app(
          Scaffold(
            body: DogCard(ProductApi(), {
              'id': 'dog',
              'name': '감자',
              'breed': '믹스',
              'size': 'SMALL',
              'reasons': [
                {'code': 'NEARBY', 'label': '선택한 거리 안에 있어요'},
                '산책 시간대가 비슷해요',
                {'code': 'INTERNAL_ONLY'},
              ],
            }),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('✓ 선택한 거리 안에 있어요'), findsOneWidget);
      expect(find.text('✓ 산책 시간대가 비슷해요'), findsOneWidget);
      expect(find.textContaining('NEARBY'), findsNothing);
      expect(find.textContaining('INTERNAL_ONLY'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'region denial opens its remedy and returning refreshes discovery',
    (tester) async {
      final api = ProductApi()..failureCode = 'REGION_VERIFICATION_REQUIRED';
      await tester.pumpWidget(app(DiscoveryScreen(api)));
      await tester.pumpAndSettle();
      expect(find.text('우리 동네부터 알려주세요'), findsOneWidget);
      await tester.tap(find.text('동네 인증하기'));
      await tester.pumpAndSettle();
      expect(find.text('우리 동네 인증'), findsOneWidget);
      api.failureCode = '';
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('우리 동네부터 알려주세요'), findsNothing);
      await tester.tap(find.text('30km까지 넓혀보기'));
      await tester.pumpAndSettle();
      expect(api.radii.last, 30000);
      expect(find.text('30km까지 넓혀보기'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'my meetups switches between confirmed pending and history queries',
    (tester) async {
      final api = ProductApi();
      await tester.pumpWidget(app(MyMeetupsScreen(api)));
      await tester.pumpAndSettle();
      expect(find.text('확정된 공원 산책'), findsOneWidget);
      await tester.tap(find.text('신청 중'));
      await tester.pumpAndSettle();
      expect(find.text('신청한 저녁 산책'), findsOneWidget);
      expect(find.textContaining('승인 대기'), findsOneWidget);
      await tester.tap(find.text('지난 내역'));
      await tester.pumpAndSettle();
      expect(find.text('취소된 아침 산책'), findsOneWidget);
      expect(api.scopes, ['UPCOMING', 'PENDING', 'HISTORY']);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'notification count clears after snapshot read-all and returning to bell',
    (tester) async {
      final api = ProductApi();
      await tester.pumpWidget(
        app(
          Scaffold(
            appBar: AppBar(actions: [NotificationBell(api, refreshKey: 0)]),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.widget<Badge>(find.byType(Badge)).isLabelVisible, true);
      await tester.tap(find.byTooltip('알림'));
      await tester.pumpAndSettle();
      api.snapshot = '2026-10-18T03:00:00.000Z';
      await tester.tap(find.text('안 읽음'));
      await tester.pumpAndSettle();
      expect(find.text('모임 신청 결과가 도착했어요'), findsOneWidget);
      await tester.tap(find.text('모두 읽기'));
      await tester.pumpAndSettle();
      expect(api.readThrough, '2026-10-18T03:00:00.000Z');
      expect(find.text('안 읽은 알림이 없어요'), findsOneWidget);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      api.read = false;
      api.snapshot = '2026-10-18T04:00:00.000Z';
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(find.text('모임 신청 결과가 도착했어요'), findsOneWidget);
      await tester.tap(find.text('모두 읽기'));
      await tester.pumpAndSettle();
      expect(api.readThrough, '2026-10-18T04:00:00.000Z');
      expect(find.text('안 읽은 알림이 없어요'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(tester.widget<Badge>(find.byType(Badge)).isLabelVisible, false);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('home shows the next confirmed appointment', (tester) async {
    await tester.pumpWidget(app(HomeScreen(ProductApi())));
    await tester.pumpAndSettle();
    expect(find.text('확정된 공원 산책'), findsOneWidget);
    expect(find.textContaining('다가오는 약속'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'leaving the inbox during a slow read does not update disposed screens',
    (tester) async {
      final api = ProductApi()..readCompletion = Completer<void>();
      await tester.pumpWidget(
        app(
          Scaffold(
            appBar: AppBar(actions: [NotificationBell(api, refreshKey: 0)]),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('알림'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('모임 신청 결과가 도착했어요'));
      await tester.pump();
      await tester.pageBack();
      await tester.pumpAndSettle();
      api.readCompletion!.complete();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('new screens support a narrow display and 160% text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final api = ProductApi();
    for (final screen in [
      MyMeetupsScreen(api),
      NotificationsScreen(api),
      ActivityReadinessScreen(api),
    ]) {
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(app(screen, scale: 1.6));
      await tester.pumpAndSettle();
      expect(
        tester.takeException(),
        isNull,
        reason: '${screen.runtimeType} should fit',
      );
    }
  });
}
