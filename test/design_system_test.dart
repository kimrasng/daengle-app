import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daengle/ui/design_system/fields.dart';
import 'package:daengle/ui/design_system/pickers.dart';
import 'package:daengle/ui/design_system/theme.dart';

void main() {
  test('date changes retain valid days and respect the allowed range', () {
    final first = DateTime(1900), last = DateTime(2026, 10, 18);
    expect(boundedDate(2024, 2, 31, first, last), DateTime(2024, 2, 29));
    expect(boundedDate(2023, 2, 29, first, last), DateTime(2023, 2, 28));
    expect(boundedDate(2027, 1, 1, first, last), last);
    expect(boundedDate(1899, 1, 1, first, last), first);
  });
  testWidgets('label stays outside the control through focus and error', (
    tester,
  ) async {
    final controller = TextEditingController();
    final form = GlobalKey<FormState>();
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(
          body: Form(
            key: form,
            child: DsTextField(
              label: '닉네임',
              controller: controller,
              validator: (v) => '닉네임을 입력해주세요.',
            ),
          ),
        ),
      ),
    );
    final input = find.byType(TextFormField);
    expect(
      tester.getBottomLeft(find.text('닉네임')).dy,
      lessThan(tester.getTopLeft(input).dy),
    );
    await tester.tap(input);
    form.currentState!.validate();
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField)).decoration?.labelText,
      isNull,
    );
    expect(find.text('닉네임을 입력해주세요.'), findsOneWidget);
    expect(
      tester.getBottomLeft(find.text('닉네임')).dy,
      lessThan(tester.getTopLeft(input).dy),
    );
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });
  testWidgets(
    'birthday wheels stay usable on a narrow screen with large text',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 480);
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
          home: DsDatePicker(
            title: '생일',
            birthday: true,
            initialDate: DateTime(2024, 2, 29),
            firstDate: DateTime(1970),
            lastDate: DateTime(2026, 10, 18),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('선택').hitTestable(), findsOneWidget);
      await tester.ensureVisible(find.text('2024년'));
      await tester.pumpAndSettle();
      await tester.drag(
        find.byType(ListWheelScrollView).first,
        const Offset(0, -70),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('calendar disables dates outside its allowed range', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: DsDatePicker(
          title: '산책 날짜',
          initialDate: DateTime(2026, 10, 18),
          firstDate: DateTime(2026, 10, 18),
          lastDate: DateTime(2026, 10, 25),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextButton>(find.widgetWithText(TextButton, '17'))
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<TextButton>(find.widgetWithText(TextButton, '19'))
          .onPressed,
      isNotNull,
    );
    expect(
      tester
          .widget<TextButton>(find.widgetWithText(TextButton, '26'))
          .onPressed,
      isNull,
    );
    await tester.tap(find.text('19'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
