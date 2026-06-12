import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wakesaga/alarm/alarm_engine.dart';
import 'package:wakesaga/main.dart';
import 'package:wakesaga/state/app_state.dart';

AppState mainAppState() => AppState()
  ..firstRunComplete = true
  ..protagonistPassUnlocked = true;

Future<void> pumpShell(WidgetTester tester, AppState state) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    WakeSagaApp(initialState: state, alarmEngine: FakeAlarmEngine()),
  );
  await tester.pump(const Duration(milliseconds: 100));
}

// Today hosts repeating animations, so settle with timed pumps only.
Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  testWidgets('Today shows the Next Alarm card and opens Alarm Studio', (
    WidgetTester tester,
  ) async {
    final state = mainAppState();
    await pumpShell(tester, state);

    expect(find.byKey(const Key('nextAlarmCard')), findsOneWidget);
    expect(find.text('NEXT ALARM'), findsOneWidget);

    await tester.tap(find.byKey(const Key('nextAlarmCard')));
    await settle(tester);

    expect(find.byKey(const Key('alarmStudio')), findsOneWidget);
    expect(find.text('MORNING ALARM'), findsOneWidget);
    expect(find.byKey(const Key('armAlarm')), findsOneWidget);
  });

  testWidgets('Alarm Studio saves the quest setup and arms the alarm', (
    WidgetTester tester,
  ) async {
    final state = mainAppState();
    await pumpShell(tester, state);

    await tester.tap(find.byKey(const Key('alarmAnchor')));
    await settle(tester);

    // Pick a mission and open quest rules for difficulty + fallback.
    await tester.tap(find.byKey(const Key('missionObject Hunt')));
    await tester.pump();

    await tester.scrollUntilVisible(
      find.byKey(const Key('sectionQuestRules')),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('sectionQuestRules')));
    await tester.pump();
    await tester.scrollUntilVisible(
      find.byKey(const Key('difficultyHard')),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('difficultyHard')));
    await tester.pump();

    await tester.tap(find.byKey(const Key('armAlarm')));
    await settle(tester);

    expect(state.quest, 'Object Hunt');
    expect(state.difficulty, 'Hard');
    expect(state.alarmEnabled, isTrue);
    expect(state.alarmScheduleConfirmed, isTrue);
    expect(state.alarmScheduleError, isNull);
    // Back on Today, the card reports the confirmed schedule truthfully.
    expect(find.textContaining(' - ARMED'), findsOneWidget);
    expect(find.textContaining('OBJECT HUNT'), findsWidgets);
  });

  testWidgets('saving with the alarm off never claims armed', (
    WidgetTester tester,
  ) async {
    final state = mainAppState();
    await pumpShell(tester, state);

    await tester.tap(find.byKey(const Key('nextAlarmCard')));
    await settle(tester);

    await tester.tap(find.byKey(const Key('alarmStudioEnabled')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('armAlarm')));
    await settle(tester);

    expect(state.alarmEnabled, isFalse);
    expect(state.alarmScheduleConfirmed, isFalse);
    expect(find.textContaining('EP 17 - ALARM OFF'), findsOneWidget);
  });
}
