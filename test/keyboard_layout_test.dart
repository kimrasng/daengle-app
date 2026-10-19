import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daengle/features/auth.dart';
import 'package:daengle/features/chat.dart';
import 'package:daengle/features/community.dart';
import 'package:daengle/features/profile.dart';
import 'package:daengle/main.dart';
import 'package:daengle/ui/shared.dart';

import 'widget_test.dart' show FakeApi;

class KeyboardApi extends FakeApi {
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
    if (path == '/rooms/test') {
      return {'joinedSeq': 0, 'lastReadSeq': 0, 'members': []};
    }
    return super.call(
      path,
      method: method,
      data: data,
      query: query,
      idempotencyKey: idempotencyKey,
      authenticated: authenticated,
      responseType: responseType,
    );
  }
}

void main() {
  void screenSize(WidgetTester tester, Size size) {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
  }

  testWidgets('login actions stay at the bottom and above the keyboard', (
    tester,
  ) async {
    screenSize(tester, const Size(390, 844));
    await tester.pumpWidget(
      MaterialApp(theme: buildAppTheme(), home: LoginScreen(KeyboardApi())),
    );
    await tester.pumpAndSettle();
    final button = find.widgetWithText(FilledButton, '보호자 본인인증');
    final notice = find.text('만 19세 이상부터 이용할 수 있어요.');
    expect(tester.getBottomLeft(notice).dy, greaterThan(800));
    final original = tester.getTopLeft(button).dy;
    tester.view.viewInsets = const FakeViewPadding(bottom: 310);
    await tester.pumpAndSettle();
    expect(tester.getBottomLeft(notice).dy, lessThanOrEqualTo(534));
    expect(tester.getTopLeft(button).dy, lessThan(original));
    expect(button.hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  final editors = <String, Widget Function(KeyboardApi)>{
    'owner': (api) =>
        OwnerEditor(api, {'displayName': '감자 견주', 'maxWalkMinutes': 30}),
    'dog': (api) => DogEditor(api),
    'channel': (api) => ChannelEditor(api),
    'post': (api) => PostEditor(api, 'test'),
    'meetup': (api) => MeetupEditor(api),
    'instant meetup': (api) => MeetupEditor(api, instant: true),
    'health': (api) => HealthScreen(api, 'test'),
  };
  for (final entry in editors.entries) {
    for (final size in [const Size(320, 640), const Size(740, 360)]) {
      testWidgets(
        '${entry.key} fields remain reachable with the keyboard at ${size.width}px',
        (tester) async {
          screenSize(tester, size);
          final keyboardHeight = size.width > size.height ? 180.0 : 280.0;
          await tester.pumpWidget(
            MaterialApp(
              theme: buildAppTheme(),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: const TextScaler.linear(1.3)),
                child: child!,
              ),
              home: entry.value(KeyboardApi()),
            ),
          );
          await tester.pumpAndSettle();
          tester.view.viewInsets = FakeViewPadding(bottom: keyboardHeight);
          await tester.pumpAndSettle();
          final labels = switch (entry.key) {
            'owner' => ['닉네임', '한 번에 걷는 시간'],
            'dog' => ['강아지 이름', '견종', '미리 알아두면 좋아요'],
            'channel' => ['채널 이름', '채널 소개'],
            'post' => ['제목', '이야기를 나눠주세요'],
            'health' => ['심사자에게 전달할 내용 (선택)'],
            _ => ['모임 이름', '모임 소개', '함께할 인원'],
          };
          for (final label in labels) {
            final field = find.byKey(ValueKey('input:$label'));
            await tester.scrollUntilVisible(
              field,
              80,
              scrollable: find.byType(Scrollable).first,
            );
            await tester.ensureVisible(field);
            await tester.pumpAndSettle();
            await tester.tap(field);
            await tester.pumpAndSettle();
            await tester.enterText(field, '키보드 입력 확인');
            await tester.pumpAndSettle();
            final editable = find.descendant(
              of: field,
              matching: find.byType(EditableText),
            );
            final rect = tester.getRect(editable);
            expect(
              rect.bottom,
              lessThanOrEqualTo(size.height - keyboardHeight + 1),
              reason: '${entry.key}: $label',
            );
            expect(
              rect.top,
              greaterThanOrEqualTo(50),
              reason: '${entry.key}: $label',
            );
            expect(tester.takeException(), isNull, reason: entry.key);
          }
          await tester.pumpWidget(const SizedBox());
          await tester.pumpAndSettle();
        },
      );
    }
  }

  testWidgets('chat composer fits with a keyboard in landscape', (
    tester,
  ) async {
    screenSize(tester, const Size(740, 360));
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: ChatScreen(KeyboardApi(), 'test'),
      ),
    );
    await tester.pumpAndSettle();
    tester.view.viewInsets = const FakeViewPadding(bottom: 180);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '첫째 줄\n둘째 줄\n셋째 줄\n넷째 줄');
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.arrow_upward).hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets('text dialog scrolls on a short keyboard viewport', (
    tester,
  ) async {
    screenSize(tester, const Size(640, 360));
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => askText(context, '따뜻한 댓글을 남겨주세요.'),
              child: const Text('댓글'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('댓글'));
    await tester.pumpAndSettle();
    tester.view.viewInsets = const FakeViewPadding(bottom: 180);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '댓글 입력');
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(seconds: 1));
  });
}
