import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daengle_design/daengle_design.dart';
import 'package:daengle/ui/shared.dart'
    show SubmitButton, Input, BirthdayField, PageBody;
import 'package:daengle/core/api.dart';

void main() {
  testWidgets(
    'app consumes packaged fonts, fields and button with error recovery',
    (tester) async {
      final name = TextEditingController();
      final pending = Completer<void>();
      var calls = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: DaengleTheme.light(),
          home: Scaffold(
            body: PageBody(
              children: [
                Input(name, '이름'),
                SubmitButton(
                  '저장하기',
                  onPressed: () {
                    calls++;
                    return pending.future;
                  },
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(DsTextField), findsOneWidget);
      expect(find.byType(DsAsyncButton), findsOneWidget);
      final font = await rootBundle.load(
        'packages/daengle_design/assets/fonts/Pretendard.ttf',
      );
      expect(font.lengthInBytes, greaterThan(1000));
      final press = tester
          .widget<FilledButton>(find.byType(FilledButton))
          .onPressed!;
      press();
      press();
      await tester.pump();
      expect(calls, 1);
      pending.completeError(const ApiFailure('저장하지 못했어요.'));
      await tester.pumpAndSettle();
      expect(find.text('저장하지 못했어요.'), findsOneWidget);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNotNull,
      );
      await tester.pumpWidget(const SizedBox());
      name.dispose();
    },
  );
  testWidgets(
    'birthday adapter keeps required validation and API serialization',
    (tester) async {
      final birth = TextEditingController();
      final form = GlobalKey<FormState>();
      await tester.pumpWidget(
        MaterialApp(
          theme: DaengleTheme.light(),
          home: Scaffold(
            body: Form(
              key: form,
              child: PageBody(children: [BirthdayField(birth, title: '생년월일')]),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(DsDateField), findsOneWidget);
      expect(form.currentState!.validate(), isFalse);
      await tester.pumpAndSettle();
      expect(find.text('생일을 선택해주세요'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('date:생년월일')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('선택'));
      await tester.pumpAndSettle();
      expect(RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(birth.text), isTrue);
      expect(form.currentState!.validate(), isTrue);
      await tester.pumpWidget(const SizedBox());
      birth.dispose();
    },
  );
}
