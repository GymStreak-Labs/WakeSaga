import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wakesaga/alarm/wake_missions.dart';
import 'package:wakesaga/dawn_rail/wake_quest.dart';
import 'package:wakesaga/state/app_state.dart';

void main() {
  group('Random Quest resolution', () {
    test('concrete quests resolve to themselves', () {
      final state = AppState()..quest = 'Sky Photo';
      expect(state.resolvedQuest, 'Sky Photo');
    });

    test('random resolves to a concrete rotation mission, stable all day', () {
      final state = AppState()..quest = WakeMission.randomName;
      state.clock = () => DateTime(2026, 6, 12, 7);
      final drawn = state.resolvedQuest;
      expect(drawn, isNot(WakeMission.randomName));
      expect(drawn, isNot('Shake'), reason: 'Shake is fallback-only');
      expect(WakeMission.rotation.map((m) => m.name), contains(drawn));
      // Same day, later hour — same draw. No per-rebuild randomness.
      state.clock = () => DateTime(2026, 6, 12, 22);
      expect(state.resolvedQuest, drawn);
    });

    test('rotates through every rotation mission across consecutive days', () {
      final state = AppState()..quest = WakeMission.randomName;
      final pool = WakeMission.rotation.map((m) => m.name).toSet();
      final seen = <String>{
        for (var day = 1; day <= pool.length; day++)
          state.resolveQuestForDate(DateTime(2026, 6, day)),
      };
      expect(seen, pool);
    });

    test('rotation excludes Shake and Random itself', () {
      final names = WakeMission.rotation.map((m) => m.name).toList();
      expect(names, isNot(contains('Shake')));
      expect(names, isNot(contains(WakeMission.randomName)));
      expect(names, isNotEmpty);
    });
  });

  testWidgets('Wake Quest shows the concrete drawn mission, never "Random"', (
    WidgetTester tester,
  ) async {
    final state = AppState()..quest = WakeMission.randomName;
    state.clock = () => DateTime(2026, 6, 12, 7);
    final drawn = state.resolvedQuest;

    await tester.pumpWidget(
      AppScope(
        state: state,
        child: const MaterialApp(home: WakeQuest()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.textContaining('RANDOM'), findsNothing);
    // The 64pt instruction names the drawn mission, never the sentinel.
    final expectedInstruction = switch (drawn) {
      'Sky Photo' => 'SKY PHOTO TO SILENCE',
      'Object Hunt' => 'FIND OBJECT TO SILENCE',
      'Desk Ready' => 'DESK PROOF TO SILENCE',
      _ => 'GET UP TO SILENCE',
    };
    expect(find.text(expectedInstruction), findsOneWidget);

    // Tear down to dispose the repeating pulse animation cleanly.
    await tester.pumpWidget(const SizedBox());
  });
}
