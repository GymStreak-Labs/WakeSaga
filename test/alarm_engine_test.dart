import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wakesaga/alarm/alarm_engine.dart';
import 'package:wakesaga/alarm/alarm_models.dart';
import 'package:wakesaga/alarm/native_alarm_engine.dart';
import 'package:wakesaga/state/app_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('AppState persists alarm plan and expected-fire records', () {
    final state = AppState()
      ..firstRunComplete = true
      ..protagonistPassUnlocked = true
      ..setMission('Beat the exam')
      ..setAlarm(
        time: const TimeOfDay(hour: 7, minute: 15),
        enabled: true,
        questType: 'Sky Photo',
      );

    final scheduled = ScheduledAlarm(
      plan: state.ensureActiveAlarmPlan(),
      scheduledFor: DateTime(2026, 6, 12, 7, 15),
      engineMode: 'fake-compatibility',
    );
    state.confirmScheduledAlarm(scheduled);

    final restored = AppState()..restoreFromJson(state.toJson());

    expect(restored.firstRunComplete, isTrue);
    expect(restored.protagonistPassUnlocked, isTrue);
    expect(restored.alarmLabel, '7:15 AM');
    expect(restored.quest, 'Sky Photo');
    expect(restored.activeAlarmPlan?.mission, 'Beat the exam');
    expect(restored.scheduledAlarm?.engineMode, 'fake-compatibility');
    expect(restored.activeAlarmPlan?.joltAssetPath, contains('wake_jolt'));
    expect(
      restored.activeAlarmPlan?.episodeVoiceAssetPath,
      contains('episode_voice_sample'),
    );
    expect(restored.activeAlarmPlan?.episodeMusicBedId, isNotNull);
    expect(
      restored.activeAlarmPlan?.episodeMusicAssetPath,
      contains('assets/audio/music_beds/'),
    );
    expect(restored.activeAlarmPlan?.episodeMixAssetPath, isNull);
    expect(restored.expectedFires, hasLength(1));
    expect(restored.expectedFires.single.outcome, AlarmOutcome.pending);
  });

  test('cold launch updates expected-fire record through quest clear', () {
    final state = AppState();
    state.clock = () => DateTime(2026, 6, 12, 6, 31);
    state.firstRunComplete = true;
    state.setAlarm(
      time: const TimeOfDay(hour: 6, minute: 30),
      enabled: true,
      questType: 'Get Up',
    );
    final plan = state.ensureActiveAlarmPlan();
    final scheduledFor = DateTime(2026, 6, 12, 6, 30);
    state.confirmScheduledAlarm(
      ScheduledAlarm(
        plan: plan,
        scheduledFor: scheduledFor,
        engineMode: 'fake-compatibility',
      ),
    );

    final launchedAt = DateTime(2026, 6, 12, 6, 30, 5);
    state.registerAlarmLaunch(
      AlarmLaunch(
        alarmId: plan.id,
        source: AlarmLaunchSource.coldStart,
        launchedAt: launchedAt,
      ),
    );

    expect(state.consumePendingAlarmLaunch()?.alarmId, plan.id);
    expect(state.expectedFires, hasLength(1));
    expect(state.expectedFires.single.scheduledFor, scheduledFor);
    expect(state.expectedFires.single.actualLaunchAt, launchedAt);
    expect(state.expectedFires.single.outcome, AlarmOutcome.unknown);

    state.markWakeQuestCleared();

    expect(state.expectedFires.single.outcome, AlarmOutcome.clear);
    expect(
      state.expectedFires.single.questClearedAt,
      DateTime(2026, 6, 12, 6, 31),
    );
  });

  test('unexpected native launch is kept as diagnostic evidence', () {
    final launchedAt = DateTime(2026, 6, 12, 6, 30, 5);
    final state = AppState()
      ..registerAlarmLaunch(
        AlarmLaunch(
          alarmId: 'native-only-alarm',
          source: AlarmLaunchSource.coldStart,
          launchedAt: launchedAt,
        ),
      );

    expect(state.expectedFires, hasLength(1));
    expect(state.expectedFires.single.alarmId, 'native-only-alarm');
    expect(state.expectedFires.single.scheduledFor, launchedAt);
    expect(state.expectedFires.single.actualLaunchAt, launchedAt);
    expect(state.expectedFires.single.outcome, AlarmOutcome.unknown);
  });

  test('FakeAlarmEngine schedules and drains a launch exactly once', () async {
    final launch = AlarmLaunch(
      alarmId: 'wake-test',
      source: AlarmLaunchSource.coldStart,
      launchedAt: DateTime(2026, 6, 12, 6, 30),
    );
    final engine = FakeAlarmEngine(initialLaunch: launch);

    final firstLaunch = await engine.consumeLaunchAlarm();
    final secondLaunch = await engine.consumeLaunchAlarm();

    expect(firstLaunch?.alarmId, 'wake-test');
    expect(secondLaunch, isNull);

    final plan = AlarmPlan(
      id: 'wake-test',
      episode: 1,
      hour: 6,
      minute: 30,
      repeatDays: const [1, 2, 3, 4, 5],
      quest: 'Get Up',
      mission: 'Finish outline',
      narrator: 'Mentor',
      joltAssetPath: null,
      episodeVoiceAssetPath: null,
      episodeMusicAssetPath: null,
      episodeMixAssetPath: null,
      fallbackQuest: 'Shake',
      createdAt: DateTime(2026, 6, 12),
    );
    final scheduled = await engine.schedule(plan);

    expect(scheduled.plan.id, 'wake-test');
    expect(scheduled.engineMode, 'fake-compatibility');
    expect(await engine.listScheduled(), hasLength(1));

    await engine.cancel('wake-test');
    expect(await engine.listScheduled(), isEmpty);
    engine.dispose();
  });

  test('NativeAlarmEngine falls back when platform plugin is absent', () async {
    final engine = NativeAlarmEngine(
      channel: const MethodChannel('wakesaga/test_missing_alarm_engine'),
    );

    final capability = await engine.requestPermission();
    expect(capability.canSchedule, isTrue);
    expect(capability.compatibilityMode, isTrue);

    final plan = AlarmPlan(
      id: 'wake-fallback',
      episode: 1,
      hour: 8,
      minute: 5,
      repeatDays: const [],
      quest: 'Get Up',
      mission: 'Finish outline',
      narrator: 'Mentor',
      joltAssetPath: null,
      episodeVoiceAssetPath: null,
      episodeMusicAssetPath: null,
      episodeMixAssetPath: null,
      fallbackQuest: 'Shake',
      createdAt: DateTime(2026, 6, 12),
    );
    final scheduled = await engine.schedule(plan);

    expect(scheduled.plan.id, 'wake-fallback');
    expect(scheduled.engineMode, 'fake-compatibility');
    expect(await engine.listScheduled(), hasLength(1));

    await engine.cancel('wake-fallback');
    expect(await engine.listScheduled(), isEmpty);
    engine.dispose();
  });

  test('NativeAlarmEngine parses pending native launch payload', () async {
    const channel = MethodChannel('wakesaga/test_native_alarm_engine');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'consumeLaunchAlarm') {
            return {
              'alarmId': 'wake-native',
              'source': 'warmAction',
              'launchedAt': '2026-06-12T06:30:05.000Z',
            };
          }
          return null;
        });
    final engine = NativeAlarmEngine(channel: channel);

    final launch = await engine.consumeLaunchAlarm();

    expect(launch?.alarmId, 'wake-native');
    expect(launch?.source, AlarmLaunchSource.warmAction);
    expect(launch?.launchedAt, DateTime.utc(2026, 6, 12, 6, 30, 5));

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    engine.dispose();
  });
}
