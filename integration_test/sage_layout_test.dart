import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:daengle/features/auth.dart';
import 'package:daengle/features/home.dart';
import 'package:daengle/features/profile.dart';
import 'package:daengle/features/community.dart';
import 'package:daengle/main.dart';
import 'package:daengle/ui/design_system/gallery.dart';

import '../test/widget_test.dart' show FakeApi;

// UI-only fixture: no accounts, uploads or backend writes are made.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('sage screens and native keyboard layouts', (tester) async {
    if (Platform.isAndroid) await binding.convertFlutterSurfaceToImage();
    Future<void> show(Widget page) async {
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: buildAppTheme(),
          home: page,
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<void> shot(String name) async {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 500)),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await binding.takeScreenshot('ios-sage-$name');
    }

    await show(const DesignSystemGallery());
    await shot('design-system');
    final api = FakeApi();
    await show(LoginScreen(api));
    await shot('login');
    await tester.tap(find.text('보호자 본인인증'));
    await tester.pumpAndSettle();
    await shot('login-form');
    await tester.tap(find.byType(TextFormField).first);
    await tester.pumpAndSettle();
    await shot('login-keyboard');
    final loginContext = tester.element(find.byType(EditableText).first);
    expect(View.of(loginContext).viewInsets.bottom, greaterThan(0));
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    await show(AppShell(api));
    await shot('home');
    for (final tab in ['친구 찾기', '동네', '채팅', '마이']) {
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text(tab),
        ),
      );
      await tester.pumpAndSettle();
      await shot('tab-${['친구 찾기', '동네', '채팅', '마이'].indexOf(tab)}');
    }
    await show(
      OwnerEditor(api, {'displayName': '감자 보호자', 'maxWalkMinutes': 30}),
    );
    await shot('guardian-profile');
    await show(DogEditor(api));
    final dogField = find.byKey(const ValueKey('input:강아지 이름'));
    await tester.tap(dogField);
    await tester.pumpAndSettle();
    await shot('dog-keyboard');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    final birthday = find.byKey(const ValueKey('date:강아지 생일'));
    await tester.ensureVisible(birthday);
    await tester.tap(birthday);
    await tester.pumpAndSettle();
    await shot('dog-birthday');
    await tester.tap(find.byTooltip('취소'));
    await tester.pumpAndSettle();
    await show(PostEditor(api, 'preview'));
    final body = find.byKey(const ValueKey('input:이야기를 나눠주세요'));
    await tester.ensureVisible(body);
    await tester.tap(body);
    await tester.pumpAndSettle();
    await shot('post-keyboard');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
}
