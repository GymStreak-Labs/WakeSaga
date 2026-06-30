import 'package:flutter/material.dart';

import '../alarm/alarm_models.dart';
import '../alarm/wake_missions.dart';
import '../audio/music_bed_catalog.dart';

/// Outcome of a single day (one episode). Episodes are additive — the count
/// never decrements, knockdowns and fillers are canon chapters, not resets.
enum DayOutcome { cleared, filler, knockdown }

/// The Today tab's four time-aware states.
enum TodayBand { morning, day, night, postMiss }

class DayRecord {
  const DayRecord({
    required this.episode,
    required this.title,
    required this.outcome,
    this.wakeTime = '—',
    this.foil,
    this.musicBedId,
  });

  final int episode;
  final String title;
  final DayOutcome outcome;
  final String wakeTime;

  /// Truth-based foil name (e.g. "FIRST LIGHT") if earned, else null.
  final String? foil;
  final String? musicBedId;

  Map<String, Object?> toJson() => {
    'episode': episode,
    'title': title,
    'outcome': outcome.name,
    'wakeTime': wakeTime,
    'foil': foil,
    'musicBedId': musicBedId,
  };

  factory DayRecord.fromJson(Map<String, Object?> json) {
    return DayRecord(
      episode: (json['episode'] as num?)?.toInt() ?? 1,
      title: json['title'] as String? ?? 'THE ONE WHO STOOD UP',
      outcome: DayOutcome.values.firstWhere(
        (value) => value.name == json['outcome'],
        orElse: () => DayOutcome.cleared,
      ),
      wakeTime: json['wakeTime'] as String? ?? '—',
      foil: json['foil'] as String?,
      musicBedId: json['musicBedId'] as String?,
    );
  }
}

/// Derives a shonen episode title from the user's mission text.
/// "Crush the essay" -> "THE ESSAY DEMON".
String deriveEpisodeTitle(String mission, int episode) {
  const stopWords = {
    'THE',
    'A',
    'AN',
    'MY',
    'TO',
    'OF',
    'AND',
    'FOR',
    'ON',
    'AT',
    'BY',
    'IN',
    'IT',
    'DO',
    'GET',
    'GO',
    'BE',
    'NO',
    'UP',
    'OUT',
    'WITH',
    'FINISH',
    'CRUSH',
    'START',
    'STOP',
    'MAKE',
    'BEAT',
    'WIN',
  };
  const suffixes = ['DEMON', 'GAUNTLET', 'RECKONING', 'TRIAL'];
  final words = mission
      .toUpperCase()
      .replaceAll(RegExp(r'[^A-Z0-9 ]'), '')
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty && !stopWords.contains(w))
      .toList();
  if (words.isEmpty) return 'THE ONE WHO STOOD UP';
  return 'THE ${words.last} ${suffixes[episode % suffixes.length]}';
}

String formatTimeOfDay(TimeOfDay t) {
  final hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
  final minute = t.minute.toString().padLeft(2, '0');
  final period = t.period == DayPeriod.am ? 'AM' : 'PM';
  return '$hour:$minute $period';
}

/// Whole-app prototype state. Single ChangeNotifier, exposed via [AppScope].
class AppState extends ChangeNotifier {
  AppState({bool seedDemoHistory = false})
    : log = seedDemoHistory ? List<DayRecord>.of(_demoLog) : <DayRecord>[];

  // ---- First run ----------------------------------------------------------
  bool firstRunComplete = false;
  bool protagonistPassUnlocked = false;

  void completeFirstRun(TimeOfDay time) {
    alarmTime = time;
    alarmEnabled = true;
    _stageActiveAlarmPlan();
    firstRunComplete = true;
    notifyListeners();
  }

  void completeFirstRunWithSetup({
    required TimeOfDay time,
    required String name,
    required String mission,
    required String narratorChoice,
    required String rivalLevel,
    required String questType,
    required String arcChoice,
    required String stakeChoice,
    required String rivalChoice,
    required String questPlaceChoice,
    required String proofChoice,
    required String difficultyChoice,
    required String fallbackQuestChoice,
    required String repeatChoice,
    required String joltChoice,
    required String escapeRuleChoice,
  }) {
    alarmTime = time;
    alarmEnabled = true;
    if (name.trim().isNotEmpty) userName = name.trim();
    if (mission.trim().isNotEmpty) missionText = mission.trim();
    narrator = narratorChoice;
    rivalIntensity = rivalLevel;
    quest = questType;
    arc = arcChoice;
    stake = stakeChoice;
    rival = rivalChoice;
    questPlace = questPlaceChoice;
    proof = proofChoice;
    difficulty = difficultyChoice;
    fallbackQuest = fallbackQuestChoice;
    repeatRhythm = repeatChoice;
    wakeJolt = joltChoice;
    escapeRule = escapeRuleChoice;
    protagonistPassUnlocked = true;
    _stageActiveAlarmPlan();
    firstRunComplete = true;
    notifyListeners();
  }

  // ---- Identity / settings ------------------------------------------------
  String userName = 'Rookie';
  String narrator = 'Mentor';
  String rivalIntensity = 'Light'; // Off / Light / Full.
  String arc = 'Study Arc';
  String stake = 'Grades';
  String rival = 'Phone vortex';
  String questPlace = 'Across the room';
  String proof = 'Movement proof';
  String difficulty = 'Normal';
  String fallbackQuest = 'Shake';
  String repeatRhythm = 'Weekdays';
  String wakeJolt = 'Power shout';
  String escapeRule = 'Filler costs a chapter';

  String get arcShort => arc.replaceAll(' Arc', '').toUpperCase();
  String get openingSetupLine => '$arcShort · ${rival.toUpperCase()}';
  String get questReceipt =>
      '$quest · ${proof.replaceAll(' proof', '')} · $difficulty';

  void setUserName(String name) {
    if (name.trim().isEmpty) return;
    userName = name.trim();
    notifyListeners();
  }

  void setNarrator(String value) {
    narrator = value;
    notifyListeners();
  }

  void setRivalIntensity(String value) {
    rivalIntensity = value;
    notifyListeners();
  }

  void setWakeJolt(String value) {
    wakeJolt = value;
    notifyListeners();
  }

  // ---- Alarm + quest ------------------------------------------------------
  TimeOfDay alarmTime = const TimeOfDay(hour: 6, minute: 30);
  bool alarmEnabled = true;
  String quest = 'Get Up'; // A WakeMission name — see wake_missions.dart.

  /// Explicit per-day repeat selection; null = derive from [repeatRhythm].
  List<int>? customRepeatDays;
  AlarmPlan? activeAlarmPlan;
  ScheduledAlarm? scheduledAlarm;
  String? alarmScheduleError;
  final List<ExpectedFireRecord> expectedFires = [];
  AlarmLaunch? pendingAlarmLaunch;
  String? activeAlarmRunId;

  String get alarmLabel => formatTimeOfDay(alarmTime);

  bool get questIsRandom => quest == WakeMission.randomName;

  /// The concrete mission the Dawn Rail runs. Random Quest resolves by
  /// calendar date, so it is stable across rebuilds within a run and rotates
  /// nightly. Shake never comes up — it stays fallback-only.
  String get resolvedQuest => resolveQuestForDate(clock());

  String resolveQuestForDate(DateTime date) {
    if (!questIsRandom) return quest;
    final pool = WakeMission.rotation;
    final seed = date.year * 372 + date.month * 31 + date.day;
    return pool[seed % pool.length].name;
  }

  bool get alarmScheduleConfirmed =>
      scheduledAlarm != null && scheduledAlarm!.plan.id == activeAlarmPlan?.id;

  String get alarmScheduleMode => scheduledAlarm?.engineMode ?? 'not scheduled';

  /// ISO weekday numbers (1=Mon..7=Sun) the alarm repeats on.
  List<int> get repeatDays => customRepeatDays ?? _repeatDaysFor(repeatRhythm);

  static const _dayLetters = ['MO', 'TU', 'WE', 'TH', 'FR', 'SA', 'SU'];

  String get repeatSummary {
    final days = repeatDays.toSet();
    if (days.length == 7) return 'EVERY DAY';
    if (days.length == 5 && days.containsAll(const {1, 2, 3, 4, 5})) {
      return 'WEEKDAYS';
    }
    if (days.length == 2 && days.containsAll(const {6, 7})) return 'WEEKENDS';
    if (days.isEmpty) return 'ONE TIME';
    return (days.toList()..sort()).map((d) => _dayLetters[d - 1]).join(' ');
  }

  void setAlarm({
    TimeOfDay? time,
    bool? enabled,
    String? questType,
    String? difficultyLevel,
    String? fallbackQuestType,
    List<int>? repeatDays,
  }) {
    alarmTime = time ?? alarmTime;
    alarmEnabled = enabled ?? alarmEnabled;
    if (questType != null && questType != quest) {
      quest = questType;
      proof = WakeMission.byName(questType).proof;
    }
    if (difficultyLevel != null) difficulty = difficultyLevel;
    if (fallbackQuestType != null) fallbackQuest = fallbackQuestType;
    if (repeatDays != null) _applyRepeatDays(repeatDays);
    if (alarmEnabled) {
      _stageActiveAlarmPlan();
    } else {
      activeAlarmPlan = null;
      scheduledAlarm = null;
      alarmScheduleError = null;
    }
    notifyListeners();
  }

  AlarmPlan ensureActiveAlarmPlan() {
    _stageActiveAlarmPlan();
    notifyListeners();
    return activeAlarmPlan!;
  }

  void confirmScheduledAlarm(ScheduledAlarm scheduled) {
    scheduledAlarm = scheduled;
    activeAlarmPlan = scheduled.plan;
    alarmEnabled = true;
    alarmScheduleError = null;
    _upsertExpectedFire(
      ExpectedFireRecord(
        alarmId: scheduled.plan.id,
        scheduledFor: scheduled.scheduledFor,
      ),
    );
    notifyListeners();
  }

  void markAlarmScheduleFailed(String message) {
    scheduledAlarm = null;
    alarmScheduleError = message;
    notifyListeners();
  }

  void registerAlarmLaunch(AlarmLaunch launch) {
    pendingAlarmLaunch = launch;
    activeAlarmRunId = launch.alarmId;
    final index = expectedFires.indexWhere(
      (record) => record.alarmId == launch.alarmId,
    );
    if (index != -1) {
      expectedFires[index] = expectedFires[index].copyWith(
        actualLaunchAt: launch.launchedAt,
        outcome: AlarmOutcome.unknown,
      );
    } else {
      _upsertExpectedFire(
        ExpectedFireRecord(
          alarmId: launch.alarmId,
          scheduledFor: _scheduledForLaunch(launch) ?? launch.launchedAt,
          actualLaunchAt: launch.launchedAt,
          outcome: AlarmOutcome.unknown,
        ),
      );
    }
    notifyListeners();
  }

  AlarmLaunch? consumePendingAlarmLaunch() {
    final launch = pendingAlarmLaunch;
    pendingAlarmLaunch = null;
    if (launch != null) notifyListeners();
    return launch;
  }

  void markSystemStopped(String alarmId) {
    activeAlarmRunId = alarmId;
    final index = expectedFires.indexWhere(
      (record) => record.alarmId == alarmId,
    );
    if (index != -1) {
      expectedFires[index] = expectedFires[index].copyWith(
        osStoppedAt: clock(),
        outcome: AlarmOutcome.emergencyStop,
      );
    }
    notifyListeners();
  }

  void markWakeQuestCleared() {
    _markActiveAlarmOutcome(AlarmOutcome.clear);
    notifyListeners();
  }

  // ---- Mission (tonight's input for tomorrow's episode) -------------------
  String missionText = 'Finish the essay outline';

  void setMission(String value) {
    missionText = value.trim();
    notifyListeners();
  }

  // ---- Behavior log / saga ------------------------------------------------
  /// Real users start with an empty Saga. Demo/capture harnesses may opt into
  /// this fixture explicitly so the proof/history surface still has rich data.
  final List<DayRecord> log;
  final List<String> recentMusicBedIds = [];

  static final List<DayRecord> _demoLog = [
    const DayRecord(
      episode: 1,
      title: 'THE ONE WHO STOOD UP',
      outcome: DayOutcome.cleared,
      wakeTime: '6:31 AM',
    ),
    const DayRecord(
      episode: 2,
      title: 'THE COLD START',
      outcome: DayOutcome.cleared,
      wakeTime: '6:30 AM',
    ),
    const DayRecord(
      episode: 3,
      title: 'FILLER — NINE MINUTES BOUGHT',
      outcome: DayOutcome.filler,
    ),
    const DayRecord(
      episode: 4,
      title: 'THE ESSAY DEMON',
      outcome: DayOutcome.cleared,
      wakeTime: '6:42 AM',
    ),
    const DayRecord(
      episode: 5,
      title: 'THE QUIET GRIND',
      outcome: DayOutcome.cleared,
      wakeTime: '6:29 AM',
    ),
    const DayRecord(
      episode: 6,
      title: 'KNOCKDOWN — THE FLOOR',
      outcome: DayOutcome.knockdown,
    ),
    const DayRecord(
      episode: 7,
      title: 'THE COMEBACK BELL',
      outcome: DayOutcome.cleared,
      wakeTime: '6:24 AM',
    ),
    const DayRecord(
      episode: 8,
      title: 'THE LONG WEDNESDAY',
      outcome: DayOutcome.cleared,
      wakeTime: '6:33 AM',
    ),
    const DayRecord(
      episode: 9,
      title: 'FIRST LIGHT',
      outcome: DayOutcome.cleared,
      wakeTime: '6:12 AM',
      foil: 'FIRST LIGHT',
    ),
    const DayRecord(
      episode: 10,
      title: 'THE DEADLINE GAUNTLET',
      outcome: DayOutcome.cleared,
      wakeTime: '6:30 AM',
    ),
    const DayRecord(
      episode: 11,
      title: 'FILLER — NINE MINUTES BOUGHT',
      outcome: DayOutcome.filler,
    ),
    const DayRecord(
      episode: 12,
      title: 'THE STORM RISER',
      outcome: DayOutcome.cleared,
      wakeTime: '6:27 AM',
      foil: 'STORM RISER',
    ),
    const DayRecord(
      episode: 13,
      title: 'THE PENULTIMATE PUSH',
      outcome: DayOutcome.cleared,
      wakeTime: '6:30 AM',
    ),
    const DayRecord(
      episode: 14,
      title: 'ARC FINALE — HOLD THE LINE',
      outcome: DayOutcome.cleared,
      wakeTime: '6:18 AM',
    ),
    const DayRecord(
      episode: 15,
      title: 'ARC II — NEW MORNING',
      outcome: DayOutcome.cleared,
      wakeTime: '6:31 AM',
    ),
    const DayRecord(
      episode: 16,
      title: 'THE OUTLINE RECKONING',
      outcome: DayOutcome.cleared,
      wakeTime: '6:28 AM',
    ),
  ];

  static const int arcLength = 14;

  int get episodeCount => log.length;
  int get nextEpisode => log.length + 1;
  int get arcNumber => (log.length ~/ arcLength) + 1;
  int get arcDay => (log.length % arcLength) + 1;

  String get activeEpisodeVoiceAssetPath =>
      activeAlarmPlan?.episodeVoiceAssetPath ??
      'assets/audio/episode_voice_sample.mp3';

  EpisodeMusicBed get activeEpisodeMusicBed {
    final activeBedId = activeAlarmPlan?.episodeMusicBedId;
    if (activeBedId != null && activeBedId.isNotEmpty) {
      return episodeMusicBedById(activeBedId);
    }
    return _selectMusicBedForEpisode(nextEpisode);
  }

  List<DayRecord> get mintedCards =>
      log.where((r) => r.outcome == DayOutcome.cleared).toList();

  /// Set true once today's Dawn Rail mints a card.
  bool clearedToday = false;

  void logFiller() {
    _markActiveAlarmOutcome(AlarmOutcome.filler);
    log.add(
      DayRecord(
        episode: nextEpisode,
        title: 'FILLER — NINE MINUTES BOUGHT',
        outcome: DayOutcome.filler,
      ),
    );
    notifyListeners();
  }

  void logKnockdown() {
    _markActiveAlarmOutcome(AlarmOutcome.knockdown);
    log.add(
      DayRecord(
        episode: nextEpisode,
        title: 'KNOCKDOWN — CH. $nextEpisode',
        outcome: DayOutcome.knockdown,
      ),
    );
    notifyListeners();
  }

  void mintEpisode({required String wakeTime, String? foil}) {
    final episode = nextEpisode;
    final musicBedId = activeEpisodeMusicBed.id;
    _markActiveAlarmOutcome(AlarmOutcome.clear);
    log.add(
      DayRecord(
        episode: episode,
        title: deriveEpisodeTitle(missionText, episode),
        outcome: DayOutcome.cleared,
        wakeTime: wakeTime,
        foil: foil,
        musicBedId: musicBedId,
      ),
    );
    _rememberMusicBed(musicBedId);
    clearedToday = true;
    notifyListeners();
  }

  Map<String, Object?> toJson() => {
    'firstRunComplete': firstRunComplete,
    'protagonistPassUnlocked': protagonistPassUnlocked,
    'userName': userName,
    'narrator': narrator,
    'rivalIntensity': rivalIntensity,
    'arc': arc,
    'stake': stake,
    'rival': rival,
    'questPlace': questPlace,
    'proof': proof,
    'difficulty': difficulty,
    'fallbackQuest': fallbackQuest,
    'repeatRhythm': repeatRhythm,
    'wakeJolt': wakeJolt,
    'escapeRule': escapeRule,
    'alarmHour': alarmTime.hour,
    'alarmMinute': alarmTime.minute,
    'alarmEnabled': alarmEnabled,
    'quest': quest,
    'customRepeatDays': customRepeatDays,
    'missionText': missionText,
    'clearedToday': clearedToday,
    'log': log.map((record) => record.toJson()).toList(),
    'activeAlarmPlan': activeAlarmPlan?.toJson(),
    'scheduledAlarm': scheduledAlarm?.toJson(),
    'alarmScheduleError': alarmScheduleError,
    'expectedFires': expectedFires.map((record) => record.toJson()).toList(),
    'activeAlarmRunId': activeAlarmRunId,
    'recentMusicBedIds': recentMusicBedIds,
  };

  void restoreFromJson(Map<String, Object?> json) {
    firstRunComplete = json['firstRunComplete'] as bool? ?? firstRunComplete;
    protagonistPassUnlocked =
        json['protagonistPassUnlocked'] as bool? ?? protagonistPassUnlocked;
    userName = json['userName'] as String? ?? userName;
    narrator = json['narrator'] as String? ?? narrator;
    rivalIntensity = json['rivalIntensity'] as String? ?? rivalIntensity;
    arc = json['arc'] as String? ?? arc;
    stake = json['stake'] as String? ?? stake;
    rival = json['rival'] as String? ?? rival;
    questPlace = json['questPlace'] as String? ?? questPlace;
    proof = json['proof'] as String? ?? proof;
    difficulty = json['difficulty'] as String? ?? difficulty;
    fallbackQuest = json['fallbackQuest'] as String? ?? fallbackQuest;
    repeatRhythm = json['repeatRhythm'] as String? ?? repeatRhythm;
    wakeJolt = json['wakeJolt'] as String? ?? wakeJolt;
    escapeRule = json['escapeRule'] as String? ?? escapeRule;
    alarmTime = TimeOfDay(
      hour: (json['alarmHour'] as num?)?.toInt() ?? alarmTime.hour,
      minute: (json['alarmMinute'] as num?)?.toInt() ?? alarmTime.minute,
    );
    alarmEnabled = json['alarmEnabled'] as bool? ?? alarmEnabled;
    quest = json['quest'] as String? ?? quest;
    customRepeatDays = (json['customRepeatDays'] as List?)
        ?.whereType<num>()
        .map((value) => value.toInt())
        .toList();
    missionText = json['missionText'] as String? ?? missionText;
    clearedToday = json['clearedToday'] as bool? ?? clearedToday;

    final restoredLog = (json['log'] as List?)
        ?.whereType<Map>()
        .map((item) => DayRecord.fromJson(Map<String, Object?>.from(item)))
        .toList();
    if (restoredLog != null && restoredLog.isNotEmpty) {
      log
        ..clear()
        ..addAll(restoredLog);
    }
    recentMusicBedIds
      ..clear()
      ..addAll(
        (json['recentMusicBedIds'] as List? ?? const [])
            .whereType<String>()
            .take(6),
      );
    if (recentMusicBedIds.isEmpty) {
      recentMusicBedIds.addAll(
        log.reversed
            .map((record) => record.musicBedId)
            .whereType<String>()
            .take(6),
      );
    }

    final activePlanJson = json['activeAlarmPlan'];
    activeAlarmPlan = activePlanJson is Map
        ? AlarmPlan.fromJson(Map<String, Object?>.from(activePlanJson))
        : null;
    final scheduledJson = json['scheduledAlarm'];
    scheduledAlarm = scheduledJson is Map
        ? ScheduledAlarm.fromJson(Map<String, Object?>.from(scheduledJson))
        : null;
    alarmScheduleError = json['alarmScheduleError'] as String?;

    expectedFires
      ..clear()
      ..addAll(
        (json['expectedFires'] as List? ?? const []).whereType<Map>().map(
          (item) =>
              ExpectedFireRecord.fromJson(Map<String, Object?>.from(item)),
        ),
      );
    activeAlarmRunId = json['activeAlarmRunId'] as String?;
  }

  // ---- Time-aware Today state machine -------------------------------------
  /// Debug override for the clock-driven band; null = derive from [clock].
  TodayBand? debugBand;

  DateTime Function() clock = DateTime.now;

  void setDebugBand(TodayBand? band) {
    debugBand = band;
    notifyListeners();
  }

  TodayBand get band {
    if (debugBand != null) return debugBand!;
    if (log.isNotEmpty &&
        log.last.outcome == DayOutcome.knockdown &&
        !clearedToday) {
      return TodayBand.postMiss;
    }
    final hour = clock().hour;
    if (hour >= 5 && hour < 12) return TodayBand.morning;
    if (hour < 20) return TodayBand.day;
    return TodayBand.night;
  }

  void _stageActiveAlarmPlan() {
    final existingId = activeAlarmPlan?.id;
    final musicBed = _selectMusicBedForEpisode(nextEpisode);
    activeAlarmPlan = AlarmPlan(
      id: existingId ?? 'wake-${DateTime.now().microsecondsSinceEpoch}',
      episode: nextEpisode,
      hour: alarmTime.hour,
      minute: alarmTime.minute,
      repeatDays: repeatDays,
      quest: quest,
      mission: missionText,
      narrator: narrator,
      joltAssetPath: 'assets/audio/wake_jolt_forceful.mp3',
      episodeVoiceAssetPath: activeEpisodeVoiceAssetPath,
      episodeMusicBedId: musicBed.id,
      episodeMusicAssetPath: musicBed.assetPath,
      episodeMixAssetPath: null,
      fallbackQuest: fallbackQuest,
      createdAt: activeAlarmPlan?.createdAt ?? clock(),
    );
    scheduledAlarm = null;
    alarmScheduleError = null;
    activeAlarmRunId = null;
  }

  List<int> _repeatDaysFor(String rhythm) {
    return switch (rhythm) {
      'Every day' => const [1, 2, 3, 4, 5, 6, 7],
      'Weekends' || 'Weekend' => const [6, 7],
      'Tomorrow only' || 'One time' => const [],
      _ => const [1, 2, 3, 4, 5],
    };
  }

  /// Stores an explicit day selection, snapping back to the named rhythm
  /// presets so existing rhythm-string copy stays truthful.
  void _applyRepeatDays(List<int> days) {
    final set = days.toSet();
    bool matches(Set<int> preset) =>
        set.length == preset.length && set.containsAll(preset);
    if (matches(const {1, 2, 3, 4, 5, 6, 7})) {
      repeatRhythm = 'Every day';
      customRepeatDays = null;
    } else if (matches(const {1, 2, 3, 4, 5})) {
      repeatRhythm = 'Weekdays';
      customRepeatDays = null;
    } else if (matches(const {6, 7})) {
      repeatRhythm = 'Weekends';
      customRepeatDays = null;
    } else if (set.isEmpty) {
      repeatRhythm = 'Tomorrow only';
      customRepeatDays = null;
    } else {
      repeatRhythm = 'Custom';
      customRepeatDays = set.toList()..sort();
    }
  }

  void _upsertExpectedFire(ExpectedFireRecord record) {
    final index = expectedFires.indexWhere(
      (existing) => existing.alarmId == record.alarmId,
    );
    if (index == -1) {
      expectedFires.add(record);
    } else {
      expectedFires[index] = record;
    }
  }

  void _markActiveAlarmOutcome(AlarmOutcome outcome) {
    final alarmId =
        activeAlarmRunId ?? activeAlarmPlan?.id ?? scheduledAlarm?.plan.id;
    if (alarmId == null) return;
    final index = expectedFires.indexWhere(
      (record) => record.alarmId == alarmId,
    );
    if (index == -1) return;
    expectedFires[index] = expectedFires[index].copyWith(
      questClearedAt: outcome == AlarmOutcome.clear ? clock() : null,
      outcome: outcome,
    );
    activeAlarmRunId = null;
  }

  DateTime? _scheduledForLaunch(AlarmLaunch launch) {
    if (scheduledAlarm?.plan.id == launch.alarmId) {
      return scheduledAlarm!.scheduledFor;
    }
    if (activeAlarmPlan?.id == launch.alarmId) {
      return DateTime(
        launch.launchedAt.year,
        launch.launchedAt.month,
        launch.launchedAt.day,
        activeAlarmPlan!.hour,
        activeAlarmPlan!.minute,
      );
    }
    return null;
  }

  EpisodeMusicBed _selectMusicBedForEpisode(int episode) {
    final comeback =
        log.isNotEmpty &&
        log.last.outcome == DayOutcome.knockdown &&
        !clearedToday;
    return selectEpisodeMusicBed(
      arc: arc,
      rivalIntensity: rivalIntensity,
      narrator: narrator,
      difficulty: difficulty,
      quest: resolvedQuest,
      episode: episode,
      localDate: clock(),
      userKey: userName,
      recentBedIds: recentMusicBedIds,
      comeback: comeback,
      milestone: episode % arcLength == 0,
    );
  }

  void _rememberMusicBed(String? bedId) {
    if (bedId == null || bedId.isEmpty) return;
    recentMusicBedIds
      ..remove(bedId)
      ..insert(0, bedId);
    if (recentMusicBedIds.length > 6) {
      recentMusicBedIds.removeRange(6, recentMusicBedIds.length);
    }
  }
}

/// InheritedNotifier scope for [AppState].
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child})
    : super(notifier: state);

  static AppState of(BuildContext context, {bool listen = true}) {
    final scope = listen
        ? context.dependOnInheritedWidgetOfExactType<AppScope>()
        : context.getInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope not found in widget tree');
    return scope!.notifier!;
  }
}
