import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daengle/features/auth.dart';
import 'package:daengle/main.dart';
import 'package:daengle/ui/shared.dart';

import 'widget_test.dart' show FakeApi;

void main() {
  testWidgets('birthday is selected in Korean and stored as an API date', (
    tester,
  ) async {
    final birth = TextEditingController(text: '2023-04-12');
    addTearDown(birth.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(
          body: PageBody(
            children: [BirthdayField(birth, title: '강아지 생일', optional: true)],
          ),
        ),
      ),
    );
    expect(find.text('2023년 4월 12일'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('date:강아지 생일')));
    await tester.pumpAndSettle();
    expect(find.byType(DsDatePicker), findsOneWidget);
    expect(tester.testTextInput.isVisible, isFalse);
    await tester.drag(
      find.byType(ListWheelScrollView).at(1),
      const Offset(0, -48),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('선택'));
    await tester.pumpAndSettle();
    expect(birth.text, '2023-05-12');
    expect(find.text('2023년 5월 12일'), findsOneWidget);
    await tester.tap(find.byTooltip('강아지 생일 지우기'));
    await tester.pumpAndSettle();
    expect(birth.text, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('trait chips preserve saved traits and toggle without typing', (
    tester,
  ) async {
    final traits = TextEditingController(text: '원래 성격');
    addTearDown(traits.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(
          body: PageBody(
            children: [
              TraitPicker(traits, choices: const ['차분해요', '활발해요']),
            ],
          ),
        ),
      ),
    );
    expect(
      tester
          .widget<FilterChip>(find.widgetWithText(FilterChip, '원래 성격'))
          .selected,
      isTrue,
    );
    await tester.tap(find.text('차분해요'));
    await tester.pumpAndSettle();
    expect(traits.text.split(', '), ['원래 성격', '차분해요']);
    await tester.tap(find.text('원래 성격'));
    await tester.pumpAndSettle();
    expect(traits.text, '차분해요');
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('login landing keeps test credentials out of the first screen', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(theme: buildAppTheme(), home: LoginScreen(FakeApi())),
    );
    await tester.pumpAndSettle();
    expect(find.byType(TextFormField), findsNothing);
    expect(find.text('산책 친구,\n우리 동네에서 만나요'), findsOneWidget);
    if (developmentIdentity) {
      await tester.tap(find.text('보호자 본인인증'));
      await tester.pumpAndSettle();
      expect(find.text('보호자님의 정보를 입력해주세요'), findsOneWidget);
      expect(find.byType(BottomSheet), findsNothing);
      expect(find.byType(BackButton), findsOneWidget);
      expect(find.byKey(const ValueKey('input:보호자 이름')), findsOneWidget);
      expect(find.textContaining('YYYY'), findsNothing);
      expect(tester.takeException(), isNull);
    }
  });
}
