import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wakesaga/alarm/alarm_engine.dart';
import 'package:wakesaga/alarm/alarm_models.dart';

import 'package:wakesaga/main.dart';
import 'package:wakesaga/state/app_state.dart';

void main() {
  testWidgets('first run arms the Cold Open app shell', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const WakeSagaApp());

    expect(find.text('START YOUR DAY'), findsOneWidget);
    expect(find.text('LIKE AN ANIME'), findsOneWidget);
    expect(find.text('CHARACTER'), findsOneWidget);

    await tester.tap(find.byKey(const Key('onboardingNext0')));
    await tester.pumpAndSettle();
    expect(find.text('EPISODE 0'), findsOneWidget);

    var stepsCleared = 1;
    while (find.text('Is this your kind of alarm?').evaluate().isEmpty &&
        stepsCleared < 60) {
      final next = find.byKey(Key('onboardingNext$stepsCleared'));
      expect(next, findsOneWidget);
      await tester.tap(next);
      await tester.pumpAndSettle();
      stepsCleared++;
    }

    expect(stepsCleared, greaterThanOrEqualTo(35));
    expect(find.text('Is this your kind of alarm?'), findsOneWidget);

    await tester.tap(find.byKey(const Key('ratingMaybeLater')));
    await tester.pump(const Duration(milliseconds: 900));

    expect(find.text('UNLOCK THE FULL\nCOLD OPEN'), findsOneWidget);
    expect(find.text('SPECIAL OFFER'), findsOneWidget);

    await tester.tap(find.byKey(const Key('beginButton')));
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('TODAY'), findsWidgets);
    expect(find.text('SAGA'), findsWidgets);
    expect(find.text('PROFILE'), findsWidgets);
    expect(find.byKey(const Key('alarmAnchor')), findsOneWidget);
    expect(find.textContaining(' - ARMED'), findsOneWidget);
  });

  testWidgets('cold alarm launch bypasses onboarding into Dawn Rail', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      WakeSagaApp(
        initialState: AppState(),
        alarmEngine: FakeAlarmEngine(),
        initialAlarmLaunch: AlarmLaunch(
          alarmId: 'wake-test',
          source: AlarmLaunchSource.coldStart,
          launchedAt: DateTime(2026, 6, 12, 6, 30),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('START YOUR DAY'), findsNothing);
    expect(find.byKey(const Key('beginQuest')), findsOneWidget);
    expect(find.text('RINGING'), findsOneWidget);
  });
}
