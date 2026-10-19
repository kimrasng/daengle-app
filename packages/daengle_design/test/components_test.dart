import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daengle_design/daengle_design.dart';

Widget host(Widget child) => MaterialApp(
  theme: DaengleTheme.light(),
  home: Scaffold(body: child),
);
void main() {
  testWidgets(
    'weekday selection keeps equal targets and adapts to large text',
    (tester) async {
      Set<int> days = {0};
      Future<void> show(double width, double scale) async {
        await tester.binding.setSurfaceSize(Size(width, 640));
        await tester.pumpWidget(
          host(
            MediaQuery(
              data: MediaQueryData(
                size: Size(width, 640),
                textScaler: TextScaler.linear(scale),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: StatefulBuilder(
                  builder: (context, setState) => DsWeekdayPicker(
                    value: days,
                    onChanged: (next) => setState(() => days = next),
                  ),
                ),
              ),
            ),
          ),
        );
      }

      addTearDown(() => tester.binding.setSurfaceSize(null));
      await show(402, 1);
      final sunday = find.widgetWithText(TextButton, '일');
      final saturday = find.widgetWithText(TextButton, '토');
      expect(tester.getTopLeft(sunday).dy, tester.getTopLeft(saturday).dy);
      final before = tester.getRect(saturday);
      await tester.tap(saturday);
      await tester.pumpAndSettle();
      expect(days, {0, 6});
      expect(tester.getRect(saturday), before);
      for (final size in [const Size(320, 1.6), const Size(390, 1)]) {
        await show(size.width, size.height);
        for (final button in find.byType(TextButton).evaluate()) {
          final rect = tester.getRect(find.byWidget(button.widget));
          expect(rect.width, greaterThanOrEqualTo(48));
          expect(rect.height, greaterThanOrEqualTo(48));
          expect(rect.right, lessThanOrEqualTo(size.width - 24));
        }
        expect(tester.takeException(), isNull);
      }
    },
  );
  testWidgets('chip selection does not shift surrounding options', (
    tester,
  ) async {
    var selected = false;
    await tester.pumpWidget(
      host(
        StatefulBuilder(
          builder: (context, setState) => Wrap(
            children: [
              DsChip(
                label: '느긋해요',
                selected: selected,
                onSelected: (next) => setState(() => selected = next),
              ),
              const DsChip(label: '활동적이에요', selected: false, onSelected: null),
            ],
          ),
        ),
      ),
    );
    final second = tester.getRect(find.text('활동적이에요'));
    await tester.tap(find.text('느긋해요'));
    await tester.pumpAndSettle();
    expect(selected, isTrue);
    expect(tester.getRect(find.text('활동적이에요')), second);
  });
  testWidgets('panel supplies a material surface for list rows and ink', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: DaengleTheme.light(),
        home: DsPanel(
          child: DsListTile(title: '산책 약속', onTap: () => taps++),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('산책 약속'));
    await tester.pumpAndSettle();
    expect(taps, 1);
    expect(tester.takeException(), isNull);
  });
  testWidgets('button preserves size and blocks taps while loading', (
    tester,
  ) async {
    var taps = 0;
    Widget button(bool loading) => host(
      Center(
        child: DsButton(
          label: '저장하기',
          onPressed: () => taps++,
          loading: loading,
        ),
      ),
    );
    await tester.pumpWidget(button(false));
    final before = tester.getSize(find.byType(FilledButton));
    await tester.tap(find.byType(FilledButton));
    expect(taps, 1);
    await tester.pumpWidget(button(true));
    await tester.pump();
    expect(tester.getSize(find.byType(FilledButton)), before);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    expect(taps, 1);
  });
  testWidgets('async button deduplicates and recovers from error', (
    tester,
  ) async {
    final pending = Completer<void>();
    var calls = 0;
    Object? error;
    await tester.pumpWidget(
      host(
        DsAsyncButton(
          label: '저장',
          onPressed: () {
            calls++;
            return pending.future;
          },
          onError: (e, _) => error = e,
        ),
      ),
    );
    final press = tester
        .widget<FilledButton>(find.byType(FilledButton))
        .onPressed!;
    press();
    press();
    await tester.pump();
    expect(calls, 1);
    pending.completeError(StateError('failed'));
    await tester.pumpAndSettle();
    expect(error, isA<StateError>());
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
    );
  });
  testWidgets('external label stays fixed, helper and validator work', (
    tester,
  ) async {
    final form = GlobalKey<FormState>();
    await tester.pumpWidget(
      host(
        Form(
          key: form,
          child: DsTextField(
            label: '이름',
            helper: '이름 안내',
            optional: true,
            validator: (v) => v == null || v.isEmpty ? '이름을 입력해주세요.' : null,
          ),
        ),
      ),
    );
    final field = find.byType(TextFormField);
    final labelTop = tester.getTopLeft(find.byType(Text).first).dy;
    await tester.tap(field);
    form.currentState!.validate();
    await tester.pumpAndSettle();
    expect(find.text('이름을 입력해주세요.'), findsOneWidget);
    expect(tester.getTopLeft(find.byType(Text).first).dy, labelTop);
    expect(
      tester.widget<TextField>(find.byType(TextField)).decoration?.labelText,
      isNull,
    );
  });
  testWidgets('read-only field rejects edits while remaining selectable', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(const DsTextField(label: '동네', initialValue: '연남동', readOnly: true)),
    );
    expect(tester.widget<TextField>(find.byType(TextField)).readOnly, isTrue);
    expect(find.text('연남동'), findsOneWidget);
    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isTrue);
  });
  testWidgets('choice group and switch are controlled by consumer', (
    tester,
  ) async {
    String value = 'a';
    bool switched = false;
    await tester.pumpWidget(
      host(
        StatefulBuilder(
          builder: (context, set) => Column(
            children: [
              DsChoiceGroup<String>(
                options: const {'a': '작은 친구', 'b': '중간 친구'},
                value: value,
                onChanged: (v) => set(() => value = v),
              ),
              DsSwitch(
                label: '알림',
                value: switched,
                onChanged: (v) => set(() => switched = v),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.tap(find.text('중간 친구'));
    await tester.pumpAndSettle();
    expect(value, 'b');
    await tester.tap(find.text('알림'));
    await tester.pumpAndSettle();
    expect(switched, isTrue);
  });
  testWidgets('date cancellation retains value; clear notifies consumer', (
    tester,
  ) async {
    DateTime? value = DateTime(2023, 4, 12);
    var changes = 0;
    await tester.pumpWidget(
      host(
        StatefulBuilder(
          builder: (context, set) => DsDateField(
            label: '생일',
            value: value,
            firstDate: DateTime(1970),
            lastDate: DateTime(2026, 10, 18),
            birthday: true,
            optional: true,
            onChanged: (v) => set(() {
              value = v;
              changes++;
            }),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('date:생일')));
    await tester.pumpAndSettle();
    expect(find.byType(DsDatePicker), findsOneWidget);
    await tester.tap(find.byTooltip('취소'));
    await tester.pumpAndSettle();
    expect(changes, 0);
    expect(value, DateTime(2023, 4, 12));
    await tester.tap(find.byTooltip('생일 지우기'));
    await tester.pumpAndSettle();
    expect(value, isNull);
    expect(changes, 1);
  });
  test('date normalization handles leap years and boundaries', () {
    final first = DateTime(1900), last = DateTime(2026, 10, 18);
    expect(boundedDate(2024, 2, 31, first, last), DateTime(2024, 2, 29));
    expect(boundedDate(2023, 2, 29, first, last), DateTime(2023, 2, 28));
    expect(boundedDate(2027, 1, 1, first, last), last);
  });
  testWidgets('footer and long field fit landscape keyboard with large text', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(740, 360);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpWidget(
      MaterialApp(
        theme: DaengleTheme.light(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(1.6)),
          child: child!,
        ),
        home: DsPage(
          title: '작성',
          footer: DsButton(label: '저장하기', onPressed: () {}),
          children: const [DsTextArea(label: '소개')],
        ),
      ),
    );
    tester.view.viewInsets = const FakeViewPadding(bottom: 180);
    await tester.pumpAndSettle();
    await tester.showKeyboard(find.byType(TextField));
    await tester.pumpAndSettle();
    final editable = find.byType(EditableText);
    await tester.ensureVisible(editable);
    await tester.pumpAndSettle();
    expect(tester.getBottomLeft(editable).dy, lessThanOrEqualTo(180));
    expect(tester.getTopLeft(editable).dy, greaterThanOrEqualTo(60));
    expect(find.text('저장하기').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
