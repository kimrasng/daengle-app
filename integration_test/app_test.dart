import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:daengle/core/api.dart';
import 'package:daengle/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('native registration, dog creation and five tabs', (
    tester,
  ) async {
    final api = Api();
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
    await tapVisible(find.text('우리 강아지 등록하기'));
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
    }
  });
}
