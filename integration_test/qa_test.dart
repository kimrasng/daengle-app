import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:daengle/core/api.dart';
import 'package:daengle/main.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('native registration, dog creation and five tabs', (
    tester,
  ) async {
    final api = Api();
    if (Platform.isAndroid) {
      await binding.convertFlutterSurfaceToImage();
    }
    Future<void> shot(String name) async {
      await tester.pumpAndSettle();
      // Let the native screenshot surface present the settled route frame.
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 400)),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await binding.takeScreenshot(
        '${Platform.isAndroid ? 'android' : 'ios'}-$name',
      );
    }

    final stamp = DateTime.now().millisecondsSinceEpoch;
    addTearDown(() async {
      if (api.accessToken == null) return;
      for (final dog in items(await api.call('/dogs'))) {
        await api.call('/dogs/${dog['id']}/archive', method: 'POST');
      }
      await api.call(
        '/me/withdrawal',
        method: 'POST',
        data: {'confirmation': '탈퇴합니다'},
      );
      await api.forget();
    });
    await tester.pumpWidget(DaengleApp(api: api));
    await tester.pumpAndSettle();
    Future<void> tapVisible(Finder finder) async {
      await Scrollable.ensureVisible(tester.element(finder), alignment: .5);
      await tester.pumpAndSettle();
      await tester.tap(finder.hitTestable());
      await tester.pumpAndSettle();
    }

    await shot('01-login');
    await tester.tap(find.text('보호자 본인인증'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'flutter-ui-$stamp',
    );
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('date:보호자 생년월일')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('선택'));
    await tester.pumpAndSettle();
    await tapVisible(
      find.byKey(const ValueKey('guardian-verification-submit')),
    );
    for (var i = 0; i < 40 && find.text('함께 시작하기').evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
    expect(find.text('함께 시작하기'), findsOneWidget);
    await shot('02-terms');
    final terms = items(await api.call('/terms', authenticated: false));
    for (final term in terms.where(
      (t) => t['required'] == true || t['required'] == 1,
    )) {
      final tile = find.textContaining(label(term['title']));
      await tester.scrollUntilVisible(
        tile,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tapVisible(tile);
    }
    await tester.scrollUntilVisible(
      find.text('동의하고 가입하기'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tapVisible(find.text('동의하고 가입하기'));
    for (
      var i = 0;
      i < 40 && find.byType(NavigationBar).evaluate().isEmpty;
      i++
    ) {
      await tester.pump(const Duration(milliseconds: 250));
    }
    await tester.pumpAndSettle();
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).destinations,
      hasLength(5),
    );
    await shot('03-home');
    await tapVisible(find.text('우리 강아지 등록하기'));
    await shot('04-dog-form');
    await tester.enterText(
      find.byKey(const ValueKey('input:강아지 이름')),
      '네이티브 검증견',
    );
    await tester.enterText(find.byKey(const ValueKey('input:견종')), '믹스');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('사교적이에요'));
    await tester.tap(find.text('사교적이에요'));
    await tester.pumpAndSettle();
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('저장하기'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tapVisible(find.text('저장하기'));
    for (var i = 0; i < 40 && find.text('강아지 프로필').evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('건강 서류 제출 · 심사 내역'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('건강 서류 제출 · 심사 내역'), findsOneWidget);
    await shot('05-dog-detail');
    await tester.pageBack();
    await tester.pumpAndSettle();
    for (final tab in ['친구 찾기', '동네', '채팅', '마이']) {
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text(tab),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await shot(
        'tab-${{'친구 찾기': 'discovery', '동네': 'neighborhood', '채팅': 'chat', '마이': 'profile'}[tab]}',
      );
      if (tab == '친구 찾기') {
        await tapVisible(find.text('조건 설정'));
        expect(find.text('어떤 친구를 만나볼까요?'), findsOneWidget);
        await shot('06-discovery-filter');
        await tapVisible(find.text('친구 찾아보기'));
      }
    }
    await tester.scrollUntilVisible(
      find.text('설정 및 계정'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    // A partially visible row may still sit behind the bottom navigation bar.
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -240));
    await tester.pumpAndSettle();
    await tester.tap(find.text('설정 및 계정').hitTestable());
    await tester.pumpAndSettle();
    await shot('07-settings');
    expect(find.text('설정 및 계정'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('알림'));
    await tester.pumpAndSettle();
    await shot('08-notifications');
  });
}
