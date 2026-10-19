import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daengle/core/api.dart';
import 'package:daengle/features/home.dart';
import 'package:daengle/main.dart';
import 'package:daengle/ui/shared.dart';

import 'core/api_test.dart' show MemoryStore;

class FakeApi extends Api {
  FakeApi() : super(tokenStore: MemoryStore());
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
    return switch (path) {
      '/me' => {
        'profile': {'displayName': '감자 견주', 'maxWalkMinutes': 30},
        'onboarding': {
          'profile': true,
          'dog': false,
          'region': false,
          'healthSubmitted': false,
        },
      },
      '/home' => {
        'recommendations': {'items': []},
        'receivedProposals': {'items': []},
        'neighborhoodPosts': [],
      },
      '/me/capabilities' => {
        'canPropose': false,
        'reason': 'REGION_VERIFICATION_REQUIRED',
      },
      _ => {'items': []},
    };
  }
}

void main() {
  testWidgets('returning from an editor refreshes the underlying data', (
    tester,
  ) async {
    var loads = 0;
    await tester.pumpWidget(
      MaterialApp(
        navigatorObservers: [routeObserver],
        home: Scaffold(
          body: AsyncView(
            load: () async => ++loads,
            builder: (data, reload) => ListView(
              children: [
                Text('조회 $data'),
                Builder(
                  builder: (context) => TextButton(
                    onPressed: () => openScreen(
                      context,
                      Scaffold(appBar: AppBar(title: const Text('수정 화면'))),
                    ),
                    child: const Text('수정'),
                  ),
                ),
                TextButton(onPressed: reload, child: const Text('새로고침')),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('조회 1'), findsOneWidget);
    await tester.tap(find.text('새로고침'));
    await tester.pumpAndSettle();
    expect(find.text('조회 2'), findsOneWidget);
    await tester.tap(find.text('수정'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('조회 3'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'fresh install displays authentication without placeholder data',
    (tester) async {
      await tester.pumpWidget(DaengleApp(api: FakeApi()));
      await tester.pumpAndSettle();
      expect(find.text('보호자 본인인증'), findsOneWidget);
      expect(find.text('만 19세 이상부터 이용할 수 있어요.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('home provides onboarding and five working tab destinations', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(theme: buildAppTheme(), home: AppShell(FakeApi())),
    );
    await tester.pumpAndSettle();
    expect(find.text('감자 견주님, 안녕하세요'), findsOneWidget);
    expect(find.text('우리 강아지 등록하기'), findsOneWidget);
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).destinations,
      hasLength(5),
    );
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('친구 찾기'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('이 조건에 맞는 친구를 기다리고 있어요.'), findsOneWidget);
    await tester.tap(find.text('조건 설정'));
    await tester.pumpAndSettle();
    expect(find.text('검색 거리'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('친구 찾아보기'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(of: find.byType(NavigationBar), matching: find.text('홈')),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('모두 보기'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await Scrollable.ensureVisible(
      tester.element(find.text('모두 보기')),
      alignment: .5,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('모두 보기').hitTestable());
    await tester.pumpAndSettle();
    expect(find.byType(BackButton), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'main screens remain usable on a narrow display with larger text',
    (tester) async {
      tester.view.physicalSize = const Size(320, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.6)),
            child: child!,
          ),
          home: AppShell(FakeApi()),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      for (final tab in ['친구 찾기', '동네', '채팅', '마이']) {
        await tester.tap(
          find.descendant(
            of: find.byType(NavigationBar),
            matching: find.text(tab),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          tester.takeException(),
          isNull,
          reason: '$tab should fit at 160% text size',
        );
      }
    },
  );
}
