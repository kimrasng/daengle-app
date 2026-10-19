import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daengle/features/auth.dart';
import 'package:daengle/features/profile.dart';
import 'package:daengle/core/api.dart';
import 'package:daengle/main.dart';

import 'widget_test.dart' show FakeApi;

class GuardianIdentityApi extends FakeApi {
  final calls = <String>[];
  Json? completion;
  @override
  Future<dynamic> call(
    String path, {
    String method = 'GET',
    Map<String, dynamic>? data,
    Map<String, dynamic>? query,
    String? idempotencyKey,
    bool authenticated = true,
    dynamic responseType,
  }) async {
    calls.add(path);
    return switch (path) {
      '/auth/identity/transactions' => {
        'transactionId': 'guardian-id',
        'nonce': 'guardian-nonce',
        'provider': 'development',
        'developmentCompletionPath': '/v1/dev/identity/guardian-id',
      },
      '/dev/identity/guardian-id' => _complete(data!),
      '/auth/identity/exchange' => {
        'kind': 'REGISTRATION',
        'ticket': 'registration-ticket',
      },
      '/terms' => {'items': <Json>[]},
      _ => super.call(
        path,
        method: method,
        data: data,
        query: query,
        authenticated: authenticated,
        responseType: responseType,
      ),
    };
  }

  Json _complete(Json value) {
    completion = value;
    return {'verified': true};
  }
}

void main() {
  testWidgets('guardian entry uses product copy without test account UI', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(theme: buildAppTheme(), home: LoginScreen(FakeApi())),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('보호자 본인인증'));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsNothing);
    expect(find.text('테스트 로그인'), findsNothing);
    expect(find.text('테스트 계정'), findsNothing);
    if (developmentIdentity) {
      expect(find.text('보호자님의 정보를 입력해주세요'), findsOneWidget);
      expect(find.byKey(const ValueKey('input:보호자 이름')), findsOneWidget);
      expect(find.text('1990년 1월 1일'), findsNothing);
    } else {
      expect(find.text('보호자님의 본인인증을 진행해주세요'), findsOneWidget);
      expect(find.textContaining('미리보기 환경'), findsNothing);
    }
    expect(tester.takeException(), isNull);
  });
  testWidgets('guardian profile explains the requested information', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: OwnerEditor(FakeApi(), {
          'displayName': '감자 보호자',
          'maxWalkMinutes': 30,
        }),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('보호자 정보'), findsOneWidget);
    expect(find.text('보호자님의 정보를 입력해주세요'), findsOneWidget);
    expect(find.text('이웃에게 보여줄 닉네임과 산책 취향을 알려주세요.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  if (developmentIdentity) {
    testWidgets(
      'guardian birthday is required and only explicit selection is submitted',
      (tester) async {
        final api = GuardianIdentityApi();
        await tester.pumpWidget(
          MaterialApp(theme: buildAppTheme(), home: LoginScreen(api)),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('보호자 본인인증'));
        await tester.pumpAndSettle();
        final submit = find.byKey(
          const ValueKey('guardian-verification-submit'),
        );
        await tester.tap(submit);
        await tester.pumpAndSettle();
        expect(api.calls, isEmpty);
        expect(find.text('보호자님의 이름을 입력해주세요.'), findsOneWidget);
        await tester.enterText(
          find.byKey(const ValueKey('input:보호자 이름')),
          '김보호자',
        );
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
        await tester.tap(submit);
        await tester.pumpAndSettle();
        expect(api.calls, isEmpty);
        await tester.tap(find.byKey(const ValueKey('date:보호자 생년월일')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('선택'));
        await tester.pumpAndSettle();
        await tester.tap(submit);
        await tester.pumpAndSettle();
        expect(api.completion?['subject'], '김보호자');
        expect(
          RegExp(r'^\d{4}-\d{2}-\d{2}$')
              .hasMatch(api.completion!['birthDate'] as String),
          isTrue,
        );
        expect(find.text('함께 시작하기'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
  if (developmentIdentity) {
    testWidgets('guardian form stays usable above a landscape keyboard', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(740, 360);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.3)),
            child: child!,
          ),
          home: LoginScreen(FakeApi()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('보호자 본인인증'));
      await tester.pumpAndSettle();
      tester.view.viewInsets = const FakeViewPadding(bottom: 180);
      await tester.pumpAndSettle();
      final field = find.byKey(const ValueKey('input:보호자 이름'));
      await tester.scrollUntilVisible(
        field,
        80,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.showKeyboard(field);
      await tester.pumpAndSettle();
      final editable = find.descendant(
        of: field,
        matching: find.byType(EditableText),
      );
      await tester.ensureVisible(editable);
      await tester.pumpAndSettle();
      expect(tester.getBottomLeft(editable).dy, lessThanOrEqualTo(180));
      expect(tester.getTopLeft(editable).dy, greaterThanOrEqualTo(60));
      expect(
        find
            .byKey(const ValueKey('guardian-verification-submit'))
            .hitTestable(),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
