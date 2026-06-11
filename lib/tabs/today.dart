import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../dawn_rail/dawn_takeover.dart';
import '../dawn_rail/episode_player.dart';
import '../state/app_state.dart';
import '../theme/ink_signal.dart';
import '../widgets/cuts.dart';
import '../widgets/screentone.dart';

/// TODAY — a time-aware state machine (Morning / Day / Night / Post-Miss).
/// Two persistent anchors survive every state:
/// 1. Alarm time + toggle, top-center (tap -> Alarm Sheet; long-press is the
///    debug "ring alarm now" affordance that launches the Dawn Rail).
/// 2. LOCK IN — big crimson circle by day, compact pill otherwise.
class TodayTab extends StatefulWidget {
  const TodayTab({super.key, required this.onOpenSaga});

  final VoidCallback onOpenSaga;

  @override
  State<TodayTab> createState() => _TodayTabState();
}

class _TodayTabState extends State<TodayTab>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _missionField = TextEditingController();
  late final AnimationController _breathe = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  )..repeat(reverse: true);
  bool _missionHydrated = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_missionHydrated) {
      _missionField.text = AppScope.of(context).missionText;
      _missionHydrated = true;
    }
  }

  @override
  void dispose() {
    _missionField.dispose();
    _breathe.dispose();
    super.dispose();
  }

  void _ringAlarmNow() {
    HapticFeedback.heavyImpact();
    Navigator.of(
      context,
      rootNavigator: true,
    ).push(hardCut(const SmashCutFlash(child: DawnTakeover())));
  }

  void _lockTomorrow(AppState state) {
    HapticFeedback.mediumImpact();
    state
      ..setMission(_missionField.text)
      ..setAlarm(enabled: true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(milliseconds: 900),
        backgroundColor: InkSignal.surface,
        content: Text(
          'Episode ${state.nextEpisode} locked for ${state.alarmLabel}.',
          style: InkSignal.ui(15, weight: FontWeight.w700),
        ),
      ),
    );
  }

  void _armComeback(AppState state) {
    HapticFeedback.heavyImpact();
    state.setAlarm(enabled: true, questType: 'Get Up');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(milliseconds: 900),
        backgroundColor: InkSignal.surface,
        content: Text(
          'Comeback quest armed for ${state.alarmLabel}.',
          style: InkSignal.ui(15, weight: FontWeight.w700),
        ),
      ),
    );
  }

  void _openAlarmSheet() {
    final state = AppScope.of(context, listen: false);
    var pickedTime = state.alarmTime;
    var pickedQuest = state.quest;
    var enabled = state.alarmEnabled;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        final sheetHeight = MediaQuery.sizeOf(sheetContext).height * 0.55;
        return StatefulBuilder(
          builder: (context, setSheetState) => SizedBox(
            height: sheetHeight,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: InkSignal.paper.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'ALARM',
                        style: InkSignal.ui(
                          15,
                          weight: FontWeight.w900,
                          letterSpacing: 2,
                          color: InkSignal.paper.withValues(alpha: 0.5),
                        ),
                      ),
                      Switch(
                        value: enabled,
                        activeTrackColor: InkSignal.paper,
                        activeThumbColor: InkSignal.base,
                        onChanged: (value) =>
                            setSheetState(() => enabled = value),
                      ),
                    ],
                  ),
                  Expanded(
                    child: CupertinoTheme(
                      data: const CupertinoThemeData(
                        brightness: Brightness.dark,
                        textTheme: CupertinoTextThemeData(
                          dateTimePickerTextStyle: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w700,
                            color: InkSignal.paper,
                          ),
                        ),
                      ),
                      child: CupertinoDatePicker(
                        mode: CupertinoDatePickerMode.time,
                        initialDateTime: DateTime(
                          2026,
                          1,
                          1,
                          pickedTime.hour,
                          pickedTime.minute,
                        ),
                        onDateTimeChanged: (value) => pickedTime = TimeOfDay(
                          hour: value.hour,
                          minute: value.minute,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final (quest, note) in const [
                        ('Get Up', 'motion'),
                        ('Sky Photo', 'camera'),
                        ('Shake', 'sensor'),
                      ])
                        _Chip(
                          label: '$quest · $note',
                          selected: pickedQuest == quest,
                          onTap: () => setSheetState(() => pickedQuest = quest),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final narrator in const [
                        'Mentor',
                        'Rival',
                        'Captain',
                      ])
                        _Chip(
                          label: narrator == 'Mentor'
                              ? 'Mentor'
                              : '$narrator 🔒',
                          selected: state.narrator == narrator,
                          onTap: narrator == 'Mentor'
                              ? () => state.setNarrator(narrator)
                              : null,
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // The sheet's single crimson element.
                  SlabButton(
                    'SAVE',
                    key: const Key('saveAlarm'),
                    height: InkSignal.slabHeight,
                    onTap: () {
                      state.setAlarm(
                        time: pickedTime,
                        enabled: enabled,
                        questType: pickedQuest,
                      );
                      Navigator.of(sheetContext).pop();
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _openLockIn() {
    HapticFeedback.mediumImpact();
    String? playingContext;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          final height = MediaQuery.sizeOf(sheetContext).height * 0.38;
          return SizedBox(
            height: height,
            child: playingContext == null
                ? Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'LOCK IN — 20s of hype',
                          style: InkSignal.ui(17, weight: FontWeight.w900),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: Row(
                            children: [
                              for (final (label, asset) in const [
                                ('GYM', 'assets/onboarding/crest_gym.png'),
                                ('STUDY', 'assets/onboarding/crest_study.png'),
                                (
                                  'WORK',
                                  'assets/onboarding/crest_deep_work.png',
                                ),
                                (
                                  'RESET',
                                  'assets/onboarding/crest_recovery.png',
                                ),
                              ]) ...[
                                Expanded(
                                  child: GestureDetector(
                                    key: Key('lockIn$label'),
                                    onTap: () => setSheetState(
                                      () => playingContext = label,
                                    ),
                                    child: Container(
                                      decoration: InkSignal.panel(),
                                      padding: const EdgeInsets.all(8),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Expanded(
                                            child: Image.asset(
                                              asset,
                                              fit: BoxFit.contain,
                                              errorBuilder: (_, _, _) =>
                                                  const Icon(
                                                    Icons.bolt,
                                                    color: InkSignal.paper,
                                                  ),
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            label,
                                            style: InkSignal.ui(
                                              15,
                                              weight: FontWeight.w900,
                                              letterSpacing: 1,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                if (label != 'RESET') const SizedBox(width: 8),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                : _LockInPlayer(
                    contextLabel: playingContext!,
                    onClose: () => Navigator.of(sheetContext).pop(),
                  ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final band = state.band;
    return SafeArea(
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              _anchorRow(state),
              Expanded(
                child: switch (band) {
                  TodayBand.morning => _morning(state),
                  TodayBand.day => _day(state),
                  TodayBand.night => _night(state),
                  TodayBand.postMiss => _postMiss(state),
                },
              ),
              if (kDebugMode &&
                  const bool.fromEnvironment('WAKE_SAGA_SHOW_DEBUG_CLOCK'))
                _debugBandRow(state),
              const SizedBox(height: InkSignal.tabBarClearance),
            ],
          ),
          // Anchor 2: LOCK IN is always reachable. Compact pill in
          // non-day states (the screen's one crimson element).
          if (band == TodayBand.morning)
            Positioned(
              right: 16,
              bottom: InkSignal.tabBarClearance + 8,
              child: GestureDetector(
                key: const Key('lockInPill'),
                onTap: _openLockIn,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: InkSignal.crimson,
                    borderRadius: BorderRadius.circular(InkSignal.chromeRadius),
                  ),
                  child: Text(
                    'LOCK IN',
                    style: InkSignal.ui(
                      17,
                      color: Colors.white,
                      weight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ---- Persistent anchor row ----------------------------------------------

  Widget _anchorRow(AppState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        height: 44,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: GestureDetector(
                key: const Key('arcChip'),
                onTap: widget.onOpenSaga,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: InkSignal.inkBorder, width: 2),
                    borderRadius: BorderRadius.circular(InkSignal.panelRadius),
                  ),
                  child: Text(
                    'ARC ${_roman(state.arcNumber)} · EP ${state.episodeCount}',
                    style: InkSignal.ui(
                      13,
                      weight: FontWeight.w700,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ),
            ),
            // Anchor 1: alarm time + toggle. Tap -> Alarm Sheet.
            // Long-press -> debug "ring alarm now" (launches Dawn Rail).
            GestureDetector(
              key: const Key('alarmAnchor'),
              behavior: HitTestBehavior.opaque,
              onTap: _openAlarmSheet,
              onLongPress: _ringAlarmNow,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                color: InkSignal.base,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'WAKE ',
                      style: InkSignal.mono(
                        11,
                        color: InkSignal.paper.withValues(alpha: 0.45),
                      ),
                    ),
                    Text(
                      state.alarmLabel,
                      style: InkSignal.ui(
                        22,
                        weight: FontWeight.w900,
                        color: state.alarmEnabled
                            ? InkSignal.paper
                            : InkSignal.paper.withValues(alpha: 0.35),
                      ),
                    ),
                    const SizedBox(width: 7),
                    Icon(
                      state.alarmEnabled ? Icons.alarm_on : Icons.alarm_off,
                      size: 20,
                      color: state.alarmEnabled
                          ? InkSignal.paper
                          : InkSignal.paper.withValues(alpha: 0.35),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---- Band bodies ---------------------------------------------------------

  Widget _morning(AppState state) {
    final card = state.mintedCards.isEmpty ? null : state.mintedCards.last;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          GestureDetector(
            key: const Key('replayTile'),
            onTap: () => Navigator.of(
              context,
              rootNavigator: true,
            ).push(hardCut(const EpisodePlayer(replay: true))),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: InkSignal.panel(),
              child: Row(
                children: [
                  const Icon(
                    Icons.play_arrow,
                    color: InkSignal.paper,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'THIS MORNING',
                          style: InkSignal.mono(
                            11,
                            color: InkSignal.paper.withValues(alpha: 0.45),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'REPLAY EPISODE ${state.episodeCount}',
                          style: InkSignal.ui(
                            17,
                            weight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            "TODAY'S MISSION",
            style: InkSignal.ui(
              13,
              weight: FontWeight.w900,
              letterSpacing: 2,
              color: InkSignal.paper.withValues(alpha: 0.45),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            state.missionText.isEmpty
                ? 'Hold the line until tonight.'
                : state.missionText,
            style: InkSignal.ui(22, weight: FontWeight.w700),
          ),
          const SizedBox(height: 20),
          const _LoopRail(activeIndex: 4),
          const Spacer(),
          if (card != null)
            Row(
              children: [
                MiniCardThumb(record: card, width: 88, height: 116),
                const SizedBox(width: 14),
                Text(
                  'MINTED ${card.wakeTime}',
                  style: InkSignal.mono(
                    13,
                    color: InkSignal.paper.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _day(AppState state) {
    final width = MediaQuery.sizeOf(context).width;
    final card = state.mintedCards.isEmpty ? null : state.mintedCards.last;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          Text(
            "TODAY'S MISSION",
            textAlign: TextAlign.center,
            style: InkSignal.ui(
              13,
              weight: FontWeight.w900,
              letterSpacing: 2,
              color: InkSignal.paper.withValues(alpha: 0.45),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            state.missionText.isEmpty
                ? 'Hold the line until tonight.'
                : state.missionText,
            textAlign: TextAlign.center,
            style: InkSignal.ui(22, weight: FontWeight.w700),
          ),
          const Spacer(),
          // The one crimson element: a breathing LOCK IN circle.
          Center(
            child: ScaleTransition(
              scale: Tween(begin: 1.0, end: 1.035).animate(
                CurvedAnimation(parent: _breathe, curve: Curves.easeInOut),
              ),
              child: GestureDetector(
                key: const Key('lockInButton'),
                onTap: _openLockIn,
                child: Container(
                  width: width * 0.56,
                  height: width * 0.56,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: InkSignal.crimson,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x66FF2E4C),
                        blurRadius: 48,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'LOCK IN',
                    style: InkSignal.ui(
                      28,
                      color: Colors.white,
                      weight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '20s of hype before gym · study · work',
            textAlign: TextAlign.center,
            style: InkSignal.ui(
              15,
              color: InkSignal.paper.withValues(alpha: 0.45),
            ),
          ),
          const Spacer(),
          const _LoopRail(activeIndex: 5),
          const SizedBox(height: 12),
          // Next-scene strip: the daily loop always points at tonight.
          Container(
            padding: const EdgeInsets.all(14),
            decoration: InkSignal.panel(),
            child: Row(
              children: [
                if (card != null) ...[
                  MiniCardThumb(record: card, width: 44, height: 58),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'NEXT EPISODE',
                        style: InkSignal.mono(
                          11,
                          color: InkSignal.paper.withValues(alpha: 0.45),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'EP ${state.nextEpisode} airs ${state.alarmLabel}'
                        '${state.alarmEnabled ? '' : ' — ALARM OFF'}',
                        style: InkSignal.ui(
                          17,
                          weight: FontWeight.w900,
                          letterSpacing: 0.4,
                          color: state.alarmEnabled
                              ? InkSignal.paper
                              : InkSignal.knockdownInk,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _night(AppState state) {
    final today = state.clearedToday
        ? DayOutcome.cleared
        : (state.log.isNotEmpty &&
                  state.log.last.outcome == DayOutcome.knockdown
              ? DayOutcome.knockdown
              : null);
    final teaser = state.missionText.isEmpty
        ? 'NEXT EPISODE… the narrator writes one anyway. '
              '${state.alarmLabel}.'
        : 'NEXT EPISODE… "${deriveEpisodeTitle(state.missionText, state.nextEpisode)}" — ${state.alarmLabel}.';
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Text(
            'END CREDITS',
            style: InkSignal.ui(
              13,
              weight: FontWeight.w900,
              letterSpacing: 2,
              color: InkSignal.paper.withValues(alpha: 0.45),
            ),
          ),
          const SizedBox(height: 14),
          // Stamp row.
          Row(
            children: [
              _Stamp(
                label: 'CLEARED',
                color: InkSignal.verifyGreen,
                active: today == DayOutcome.cleared,
              ),
              const SizedBox(width: 8),
              _Stamp(
                label: 'SURVIVED',
                color: InkSignal.paper,
                active: today == null,
              ),
              const SizedBox(width: 8),
              _Stamp(
                label: 'KNOCKED DOWN',
                color: InkSignal.knockdownInk,
                active: today == DayOutcome.knockdown,
              ),
            ],
          ),
          const SizedBox(height: 28),
          Text(
            "TOMORROW'S MISSION?",
            style: InkSignal.ui(
              13,
              weight: FontWeight.w900,
              letterSpacing: 2,
              color: InkSignal.paper.withValues(alpha: 0.45),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            key: const Key('missionField'),
            controller: _missionField,
            style: InkSignal.ui(18),
            onSubmitted: state.setMission,
            decoration: InputDecoration(
              hintText: 'Say it. The narrator is listening.',
              hintStyle: InkSignal.ui(
                17,
                color: InkSignal.paper.withValues(alpha: 0.3),
              ),
              filled: true,
              fillColor: InkSignal.surface,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(InkSignal.panelRadius),
                borderSide: const BorderSide(
                  color: InkSignal.inkBorder,
                  width: 2,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(InkSignal.panelRadius),
                borderSide: const BorderSide(color: InkSignal.paper, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final suggestion in const [
                'Crush the essay',
                'Leg day, no excuses',
                'Inbox zero by nine',
              ])
                _Chip(
                  label: suggestion,
                  selected: state.missionText == suggestion,
                  onTap: () {
                    _missionField.text = suggestion;
                    state.setMission(suggestion);
                  },
                ),
            ],
          ),
          const SizedBox(height: 32),
          // Typed-on teaser. Keyed by mission so it retypes on change.
          TypeOnText(
            teaser,
            key: ValueKey(state.missionText),
            style: InkSignal.mono(
              15,
              color: InkSignal.paper.withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(height: 18),
          // The signature sleep stinger.
          SkewedDisplay(
            'TO BE CONTINUED',
            size: 30,
            color: InkSignal.paper.withValues(alpha: 0.85),
            textAlign: TextAlign.left,
          ),
          const SizedBox(height: 20),
          const _LoopRail(activeIndex: 0),
          const SizedBox(height: 18),
          SlabButton(
            "LOCK TOMORROW'S COLD OPEN",
            key: const Key('lockTomorrow'),
            onTap: () => _lockTomorrow(state),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _postMiss(AppState state) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: InkSignal.panel(borderColor: InkSignal.knockdownInk),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'KNOCKDOWN — CH. ${state.episodeCount}',
                  style: InkSignal.display(
                    28,
                  ).copyWith(color: InkSignal.knockdownInk),
                ),
                const SizedBox(height: 10),
                Text(
                  'Canon. Written in red ink. Not a reset.',
                  style: InkSignal.ui(
                    17,
                    color: InkSignal.paper.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Every protagonist eats the floor in episode '
            '${state.episodeCount}. What matters is episode '
            '${state.nextEpisode}.',
            style: InkSignal.ui(22, weight: FontWeight.w700),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(color: InkSignal.knockdownInk, width: 2),
              borderRadius: BorderRadius.circular(InkSignal.panelRadius),
            ),
            child: Text(
              'COMEBACK QUEST ARMED — ${state.alarmLabel}',
              style: InkSignal.ui(
                15,
                color: InkSignal.knockdownInk,
                weight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(height: 22),
          const _LoopRail(activeIndex: 0),
          const Spacer(),
          SlabButton(
            'ARM COMEBACK QUEST',
            key: const Key('armComeback'),
            onTap: () => _armComeback(state),
          ),
        ],
      ),
    );
  }

  // ---- Debug clock override ------------------------------------------------

  Widget _debugBandRow(AppState state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
      child: Opacity(
        opacity: 0.35,
        child: Row(
          children: [
            Text('DBG CLOCK', style: InkSignal.mono(10)),
            const SizedBox(width: 10),
            for (final (label, band) in const [
              ('AUTO', null),
              ('AM', TodayBand.morning),
              ('DAY', TodayBand.day),
              ('PM', TodayBand.night),
              ('MISS', TodayBand.postMiss),
            ])
              GestureDetector(
                key: Key('dbgBand$label'),
                onTap: () => state.setDebugBand(band),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  child: Text(
                    label,
                    style: InkSignal.mono(
                      11,
                      color:
                          state.debugBand == band &&
                              (band != null || state.debugBand == null)
                          ? InkSignal.paper
                          : InkSignal.paper.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static String _roman(int value) => switch (value) {
    1 => 'I',
    2 => 'II',
    3 => 'III',
    4 => 'IV',
    5 => 'V',
    _ => '$value',
  };
}

class _Stamp extends StatelessWidget {
  const _Stamp({
    required this.label,
    required this.color,
    required this.active,
  });

  final String label;
  final Color color;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(
          color: active ? color : InkSignal.inkBorder,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(InkSignal.panelRadius),
      ),
      child: Text(
        label,
        style: InkSignal.ui(
          13,
          weight: FontWeight.w900,
          letterSpacing: 1,
          color: active ? color : InkSignal.paper.withValues(alpha: 0.35),
        ),
      ),
    );
  }
}

class _LoopRail extends StatelessWidget {
  const _LoopRail({required this.activeIndex});

  final int activeIndex;

  static const _steps = ['Alarm', 'Quest', 'Title', 'Episode', 'Card', 'Next'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: InkSignal.panel(color: InkSignal.base),
      child: Row(
        children: [
          for (var i = 0; i < _steps.length; i++) ...[
            Expanded(
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: i <= activeIndex
                          ? InkSignal.paper
                          : Colors.transparent,
                      border: Border.all(
                        color: i <= activeIndex
                            ? InkSignal.paper
                            : InkSignal.inkBorder,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _steps[i].toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: InkSignal.mono(
                      9,
                      color: i == activeIndex
                          ? InkSignal.paper
                          : InkSignal.paper.withValues(alpha: 0.38),
                    ),
                  ),
                ],
              ),
            ),
            if (i != _steps.length - 1)
              Container(
                width: 10,
                height: 2,
                color: i < activeIndex
                    ? InkSignal.paper.withValues(alpha: 0.7)
                    : InkSignal.inkBorder,
              ),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.selected, this.onTap});

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? InkSignal.paper : Colors.transparent,
          border: Border.all(
            color: selected ? InkSignal.paper : InkSignal.inkBorder,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(InkSignal.panelRadius),
        ),
        child: Text(
          label,
          style: InkSignal.ui(
            15,
            color: onTap == null
                ? InkSignal.paper.withValues(alpha: 0.4)
                : selected
                ? InkSignal.base
                : InkSignal.paper,
            weight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _LockInPlayer extends StatelessWidget {
  const _LockInPlayer({required this.contextLabel, required this.onClose});

  final String contextLabel;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'LOCKED IN — $contextLabel',
                style: InkSignal.ui(
                  17,
                  weight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              // Visible X — no invisible affordances.
              GestureDetector(
                key: const Key('lockInClose'),
                onTap: onClose,
                child: const Icon(Icons.close, color: InkSignal.paper),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Center(
              child: StrokedSubtitle(
                contextLabel == 'RESET'
                    ? 'Breathe. The arc is long.\nRecovery is canon too.'
                    : 'One block. Full send.\nThe narrator is watching, '
                          '$contextLabel mode.',
                size: 20,
              ),
            ),
          ),
          // Simulated 20s hype clip progress.
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(seconds: 20),
            builder: (context, value, _) => ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: value,
                minHeight: 4,
                backgroundColor: InkSignal.inkBorder,
                color: InkSignal.paper,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'SIMULATED AUDIO CLIP',
            style: InkSignal.mono(
              10,
              color: InkSignal.paper.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }
}
