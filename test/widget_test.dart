import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wakesaga/main.dart';

void main() {
  Future<void> pressPrimary(WidgetTester tester, String label) async {
    final button = find.widgetWithText(ElevatedButton, label);
    expect(button, findsOneWidget);
    tester.widget<ElevatedButton>(button).onPressed?.call();
    await tester.pump(const Duration(milliseconds: 450));
    await tester.pumpAndSettle();
  }

  testWidgets('full anime onboarding builder reaches staged alarm', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const WakeSagaApp());

    expect(find.text('Start your day like an anime character'), findsOneWidget);
    expect(find.textContaining('Episode 001'), findsWidgets);

    await pressPrimary(tester, 'Build My Opening');
    expect(find.text('Pick your wake persona'), findsOneWidget);
    await tester.tap(find.text('Phone first'));
    await tester.pumpAndSettle();

    await pressPrimary(tester, 'Next');
    expect(find.textContaining('After your alarm'), findsOneWidget);

    var reachedFinal = false;
    for (var index = 0; index < 60; index++) {
      if (find
          .widgetWithText(ElevatedButton, 'Start Tomorrow')
          .evaluate()
          .isNotEmpty) {
        await pressPrimary(tester, 'Start Tomorrow');
        reachedFinal = true;
        break;
      }

      final label =
          find
              .widgetWithText(ElevatedButton, 'Activate Offer')
              .evaluate()
              .isNotEmpty
          ? 'Activate Offer'
          : find
                .widgetWithText(ElevatedButton, 'Start Free Trial')
                .evaluate()
                .isNotEmpty
          ? 'Start Free Trial'
          : find
                .widgetWithText(ElevatedButton, 'Continue')
                .evaluate()
                .isNotEmpty
          ? 'Continue'
          : 'Next';
      await pressPrimary(tester, label);
    }

    expect(reachedFinal, isTrue);

    expect(find.text('Opening Locked'), findsOneWidget);
    expect(find.textContaining('Quest gate'), findsWidgets);
    expect(find.text('Home'), findsWidgets);
    expect(find.text('Lock In'), findsWidgets);
    expect(find.text('Receipts'), findsWidgets);
    expect(find.text('Settings'), findsWidgets);
  });
}
