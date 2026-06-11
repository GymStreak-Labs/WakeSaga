import 'package:flutter/material.dart';

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
  });

  final int episode;
  final String title;
  final DayOutcome outcome;
  final String wakeTime;

  /// Truth-based foil name (e.g. "FIRST LIGHT") if earned, else null.
  final String? foil;
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
  // ---- First run ----------------------------------------------------------
  bool firstRunComplete = false;

  void completeFirstRun(TimeOfDay time) {
    alarmTime = time;
    alarmEnabled = true;
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
  String wakeJolt = 'Hero trailer';
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

  // ---- Alarm + quest ------------------------------------------------------
  TimeOfDay alarmTime = const TimeOfDay(hour: 6, minute: 30);
  bool alarmEnabled = true;
  String quest = 'Get Up'; // 'Get Up' | 'Sky Photo' | 'Shake'.

  String get alarmLabel => formatTimeOfDay(alarmTime);

  void setAlarm({TimeOfDay? time, bool? enabled, String? questType}) {
    alarmTime = time ?? alarmTime;
    alarmEnabled = enabled ?? alarmEnabled;
    quest = questType ?? quest;
    notifyListeners();
  }

  // ---- Mission (tonight's input for tomorrow's episode) -------------------
  String missionText = 'Finish the essay outline';

  void setMission(String value) {
    missionText = value.trim();
    notifyListeners();
  }

  // ---- Behavior log / saga ------------------------------------------------
  /// Seeded demo history: Arc I (14 episodes) + start of Arc II.
  final List<DayRecord> log = [
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

  List<DayRecord> get mintedCards =>
      log.where((r) => r.outcome == DayOutcome.cleared).toList();

  /// Set true once today's Dawn Rail mints a card.
  bool clearedToday = false;

  void logFiller() {
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
    log.add(
      DayRecord(
        episode: nextEpisode,
        title: deriveEpisodeTitle(missionText, nextEpisode),
        outcome: DayOutcome.cleared,
        wakeTime: wakeTime,
        foil: foil,
      ),
    );
    clearedToday = true;
    notifyListeners();
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
