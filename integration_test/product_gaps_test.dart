import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:daengle/core/api.dart';
import 'package:daengle/main.dart';

import 'helpers/product_fixture.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'personal schedule, notification inbox and readiness on the real server',
    (tester) async {
      final fixture = ProductFixture();
      Future<void> fixtureWork(Future<void> Function() work) async {
        Object? failure;
        StackTrace? trace;
        await tester.runAsync(() async {
          try {
            await work();
          } catch (error, stack) {
            failure = error;
            trace = stack;
          }
        });
        if (failure != null) Error.throwWithStackTrace(failure!, trace!);
      }

      addTearDown(() => fixtureWork(fixture.dispose));
      await fixtureWork(fixture.prepare);
      if (Platform.isAndroid) await binding.convertFlutterSurfaceToImage();
      await tester.pumpWidget(DaengleApp(api: fixture.api));

      Future<void> waitFor(Finder finder) async {
        for (var i = 0; i < 80 && finder.evaluate().isEmpty; i++) {
          await tester.pump(const Duration(milliseconds: 250));
        }
        await tester.pumpAndSettle();
        expect(finder, findsOneWidget);
      }

      Future<void> tap(Finder finder) async {
        await Scrollable.ensureVisible(tester.element(finder), alignment: .5);
        await tester.pumpAndSettle();
        await tester.tap(finder.hitTestable());
        await tester.pumpAndSettle();
      }

      Future<void> tab(String title) => tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text(title),
        ),
      );
      Future<void> shot(String name) async {
        await tester.pumpAndSettle();
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 400)),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await binding.takeScreenshot(
          '${Platform.isAndroid ? 'android' : 'ios'}-product-$name',
        );
      }

      await waitFor(find.text('저녁 공원 산책'));
      await shot('01-next-appointment');
      await tab('동네');
      await tap(find.text('나의 모임'));
      await waitFor(find.text('저녁 공원 산책'));
      await shot('02-upcoming');
      await tap(find.text('신청 중'));
      await waitFor(find.text('주말 강변 산책'));
      await shot('03-pending');
      await tap(find.text('지난 내역'));
      await waitFor(find.text('취소된 아침 산책'));
      await shot('04-history');
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('알림'));
      await tester.pumpAndSettle();
      await tap(find.text('안 읽음'));
      await waitFor(find.text('모임이 취소되었습니다.'));
      await shot('05-unread-notifications');
      await waitFor(
        find.byWidgetPredicate(
          (widget) =>
              widget is TextButton &&
              widget.onPressed != null &&
              widget.child is Text &&
              (widget.child as Text).data == '모두 읽기',
        ),
      );
      await tap(find.text('모두 읽기'));
      await waitFor(find.text('안 읽은 알림이 없어요'));
      expect(
        object(await fixture.api.call('/notifications/summary'))['unreadCount'],
        0,
      );
      await shot('06-read-all');
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tab('마이');
      await tester.scrollUntilVisible(
        find.text('산책 준비 상태'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tap(find.text('산책 준비 상태'));
      await waitFor(find.text('이제 함께 걸을\n준비가 됐어요'));
      await shot('07-readiness');
    },
  );
}
