import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wakesaga/audio/music_bed_catalog.dart';
import 'package:wakesaga/state/app_state.dart';

void main() {
  group('Episode music bed selection', () {
    test('is deterministic for the same episode seed', () {
      final first = selectEpisodeMusicBed(
        arc: 'Study Arc',
        rivalIntensity: 'Light',
        narrator: 'Mentor',
        difficulty: 'Normal',
        quest: 'Desk Ready',
        episode: 7,
        localDate: DateTime(2026, 6, 16),
        userKey: 'Rookie',
      );
      final second = selectEpisodeMusicBed(
        arc: 'Study Arc',
        rivalIntensity: 'Light',
        narrator: 'Mentor',
        difficulty: 'Normal',
        quest: 'Desk Ready',
        episode: 7,
        localDate: DateTime(2026, 6, 16),
        userKey: 'Rookie',
      );

      expect(second.id, first.id);
      expect(first.assetPath, startsWith('assets/audio/music_beds/'));
      expect(first.assetSourcePath, startsWith('audio/music_beds/'));
    });

    test('avoids recently used beds when enough alternatives exist', () {
      final recent = ['dawn_rise', 'deep_work_tension', 'monk_mode_minimal'];
      final selected = selectEpisodeMusicBed(
        arc: 'Deep Work Arc',
        rivalIntensity: 'Light',
        narrator: 'Quiet Senior',
        difficulty: 'Normal',
        quest: 'Desk Ready',
        episode: 9,
        localDate: DateTime(2026, 6, 17),
        userKey: 'Rookie',
        recentBedIds: recent,
      );

      expect(recent, isNot(contains(selected.id)));
      expect(selected.isMilestone, isFalse);
    });

    test('routes special episodes to reserved treatments', () {
      final milestone = selectEpisodeMusicBed(
        arc: 'Gym Arc',
        rivalIntensity: 'Full',
        narrator: 'Captain',
        difficulty: 'Hard',
        quest: 'Get Up',
        episode: 14,
        localDate: DateTime(2026, 6, 18),
        userKey: 'Rookie',
        milestone: true,
      );
      final comeback = selectEpisodeMusicBed(
        arc: 'Comeback Arc',
        rivalIntensity: 'Light',
        narrator: 'Mentor',
        difficulty: 'Gentle',
        quest: 'Water Check',
        episode: 15,
        localDate: DateTime(2026, 6, 19),
        userKey: 'Rookie',
        comeback: true,
      );

      expect(milestone.id, 'victory_foil');
      expect(comeback.id, 'comeback_low');
    });
  });

  test('AppState stages and persists selected music bed metadata', () {
    final state = AppState();
    state.clock = () => DateTime(2026, 6, 16);
    state.setUserName('Maya');
    state.setAlarm(
      time: const TimeOfDay(hour: 6, minute: 20),
      enabled: true,
      questType: 'Desk Ready',
    );

    final plan = state.ensureActiveAlarmPlan();
    expect(plan.episodeVoiceAssetPath, contains('episode_voice_sample'));
    expect(plan.episodeMusicBedId, isNotNull);
    expect(plan.episodeMusicAssetPath, contains('assets/audio/music_beds/'));
    expect(plan.episodeMixAssetPath, isNull);

    state.mintEpisode(wakeTime: '6:21 AM');

    expect(state.log.single.musicBedId, plan.episodeMusicBedId);
    expect(state.recentMusicBedIds.first, plan.episodeMusicBedId);

    final restored = AppState()..restoreFromJson(state.toJson());
    expect(restored.log.single.musicBedId, plan.episodeMusicBedId);
    expect(restored.recentMusicBedIds.first, plan.episodeMusicBedId);
  });
}
