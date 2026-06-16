import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../alarm/alarm_arming.dart';
import '../alarm/alarm_engine.dart';
import '../alarm/alarm_studio.dart';
import '../alarm/wake_missions.dart';
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
  late final AnimationController _breathe;
  bool _missionHydrated = false;

  @override
  void initState() {
    super.initState();
    _breathe = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

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

  Future<void> _lockTomorrow(AppState state) async {
    HapticFeedback.mediumImpact();
    state
      ..setMission(_missionField.text)
      ..setAlarm(enabled: true);
    await _scheduleAlarmPlan(state);
  }

  Future<void> _armComeback(AppState state) async {
    HapticFeedback.heavyImpact();
    state.setAlarm(enabled: true, questType: 'Get Up');
    await _scheduleAlarmPlan(state);
  }

  Future<void> _scheduleAlarmPlan(AppState state) async {
    final engine = AlarmScope.read(context);
    final armed = await armAlarmPlan(state: state, engine: engine);
    _showAlarmSnack(
      armed
          ? 'Episode ${state.nextEpisode} armed for ${state.alarmLabel}.'
          : 'Alarm not armed. Open the alarm to fix it.',
    );
  }

  void _showAlarmSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(milliseconds: 900),
        backgroundColor: InkSignal.surface,
        content: Text(
          message,
          style: InkSignal.ui(15, weight: FontWeight.w700),
        ),
      ),
    );
  }

  /// Core scheduling lives in the full-screen Alarm Studio — never a
  /// half-sheet. Every alarm affordance on Today routes here.
  void _openAlarmStudio() {
    unawaited(openAlarmStudio(context));
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
              if (_alarmAnchorFailed(state)) _notArmedBanner(state),
              _nextAlarmCard(state),
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

  /// True when the alarm is on but the system schedule did not stick.
  static bool _alarmAnchorFailed(AppState state) =>
      state.alarmEnabled && state.alarmScheduleError != null;

  /// Visible, actionable failure state: tap retries scheduling directly.
  Widget _notArmedBanner(AppState state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: GestureDetector(
        key: const Key('alarmNotArmedBanner'),
        behavior: HitTestBehavior.opaque,
        onTap: () => unawaited(_scheduleAlarmPlan(state)),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: InkSignal.knockdownInk, width: 2),
            borderRadius: BorderRadius.circular(InkSignal.panelRadius),
          ),
          child: Text(
            'ALARM NOT ARMED - TAP TO FIX',
            textAlign: TextAlign.center,
            style: InkSignal.ui(
              14,
              color: InkSignal.knockdownInk,
              weight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
        ),
      ),
    );
  }

  /// NEXT ALARM — the alarm-trust surface, above the fold in every band.
  /// Time, rhythm, schedule truth, Wake Quest contract, episode mission,
  /// and an explicit edit affordance into Alarm Studio.
  Widget _nextAlarmCard(AppState state) {
    final failed = _alarmAnchorFailed(state);
    final statusColor = !state.alarmEnabled
        ? InkSignal.paper.withValues(alpha: 0.45)
        : failed
        ? InkSignal.knockdownInk
        : state.alarmScheduleConfirmed
        ? InkSignal.verifyGreen
        : InkSignal.paper.withValues(alpha: 0.7);
    final mission = WakeMission.byName(state.quest);
    final missionText = _missionLine(state);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: GestureDetector(
        key: const Key('nextAlarmCard'),
        behavior: HitTestBehavior.opaque,
        onTap: _openAlarmStudio,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: InkSignal.panel(
            borderColor: failed ? InkSignal.knockdownInk : InkSignal.inkBorder,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'NEXT ALARM',
                      style: InkSignal.mono(
                        11,
                        color: InkSignal.paper.withValues(alpha: 0.45),
                      ),
                    ),
                  ),
                  Text(
                    'EDIT',
                    style: InkSignal.mono(
                      11,
                      color: InkSignal.paper.withValues(alpha: 0.6),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: InkSignal.paper.withValues(alpha: 0.6),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    state.alarmLabel,
                    style: InkSignal.display(
                      40,
                      color: state.alarmEnabled
                          ? InkSignal.paper
                          : InkSignal.paper.withValues(alpha: 0.35),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        state.repeatSummary,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: InkSignal.mono(
                          11,
                          color: InkSignal.paper.withValues(alpha: 0.55),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                _nextEpisodeLine(state),
                style: InkSignal.ui(
                  15,
                  weight: FontWeight.w900,
                  letterSpacing: 0.4,
                  color: statusColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                state.questIsRandom
                    ? 'QUEST RANDOM — A NEW MISSION EACH MORNING · '
                          '${state.difficulty.toUpperCase()} · '
                          'FALLBACK ${state.fallbackQuest.toUpperCase()}'
                    : 'QUEST ${mission.name.toUpperCase()} · '
                          '${mission.proof.toUpperCase()} · '
                          '${state.difficulty.toUpperCase()} · '
                          'FALLBACK ${state.fallbackQuest.toUpperCase()}',
                maxLines: 2,
                style: InkSignal.mono(
                  10,
                  color: InkSignal.paper.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'CLEAR WAKE QUEST -> TITLE CARD + MORNING EPISODE',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: InkSignal.mono(
                  10,
                  color: InkSignal.gold.withValues(alpha: 0.75),
                ),
              ),
              const SizedBox(height: 10),
              _EpisodeMissionBrief(
                episode: state.nextEpisode,
                mission: missionText,
                title: deriveEpisodeTitle(missionText, state.nextEpisode),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _anchorRow(AppState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              key: const Key('arcChip'),
              onTap: widget.onOpenSaga,
              child: Container(
                height: 42,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                alignment: Alignment.centerLeft,
                decoration: BoxDecoration(
                  border: Border.all(color: InkSignal.inkBorder, width: 2),
                  borderRadius: BorderRadius.circular(InkSignal.panelRadius),
                ),
                child: Text(
                  'ARC ${_roman(state.arcNumber)} · EP ${state.episodeCount} CLEARED',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: InkSignal.ui(
                    13,
                    weight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Compact alarm settings affordance. The full time/status belongs
          // to the large Next Alarm card below, so this row cannot overlap.
          GestureDetector(
            key: const Key('alarmAnchor'),
            behavior: HitTestBehavior.opaque,
            onTap: _openAlarmStudio,
            onLongPress: _ringAlarmNow,
            child: Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 11),
              decoration: BoxDecoration(
                color: InkSignal.base,
                border: Border.all(
                  color: _alarmAnchorFailed(state)
                      ? InkSignal.knockdownInk
                      : InkSignal.inkBorder,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(InkSignal.panelRadius),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _alarmAnchorFailed(state)
                        ? Icons.error_outline
                        : state.alarmEnabled
                        ? Icons.alarm_on
                        : Icons.alarm_off,
                    size: 18,
                    color: _alarmAnchorFailed(state)
                        ? InkSignal.knockdownInk
                        : state.alarmEnabled && state.alarmScheduleConfirmed
                        ? InkSignal.verifyGreen
                        : state.alarmEnabled
                        ? InkSignal.paper
                        : InkSignal.paper.withValues(alpha: 0.35),
                  ),
                  const SizedBox(width: 7),
                  Text(
                    'ALARM',
                    style: InkSignal.mono(
                      11,
                      color: InkSignal.paper.withValues(alpha: 0.65),
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: InkSignal.paper.withValues(alpha: 0.45),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---- Band bodies ---------------------------------------------------------

  Widget _morning(AppState state) {
    final card = state.mintedCards.isEmpty ? null : state.mintedCards.last;
    return SingleChildScrollView(
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
          _LoopRail(
            activeIndex: 4,
            state: state,
            title: "THIS MORNING'S WAKE PATH",
          ),
          const SizedBox(height: 28),
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
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _LoopRail(
            activeIndex: 5,
            state: state,
            title: 'WHAT HAPPENS WHEN THE ALARM RINGS',
          ),
          const SizedBox(height: 26),
          Text(
            'DAYTIME BOOST',
            style: InkSignal.ui(
              12,
              weight: FontWeight.w900,
              letterSpacing: 2,
              color: InkSignal.paper.withValues(alpha: 0.38),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Optional: use the same mission for a 20s Lock In clip.',
            style: InkSignal.ui(
              13,
              color: InkSignal.paper.withValues(alpha: 0.5),
              weight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          _LockInCard(
            breathe: _breathe,
            onTap: _openLockIn,
            mission: _missionLine(state),
          ),
        ],
      ),
    );
  }

  /// Truthful next-episode line: never claims an air time the system
  /// schedule hasn't confirmed.
  String _nextEpisodeLine(AppState state) {
    if (!state.alarmEnabled) {
      return 'EP ${state.nextEpisode} - ALARM OFF';
    }
    if (state.alarmScheduleError != null) {
      return 'ALARM NOT ARMED - TAP TO FIX';
    }
    if (state.alarmScheduleConfirmed) {
      return 'EP ${state.nextEpisode} airs ${state.alarmLabel} - ARMED';
    }
    return 'EP ${state.nextEpisode} set for ${state.alarmLabel} - ARMING...';
  }

  String _missionLine(AppState state) => state.missionText.isEmpty
      ? 'Hold the line until tonight'
      : state.missionText;

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
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Stamp(
                label: 'CLEARED',
                color: InkSignal.verifyGreen,
                active: today == DayOutcome.cleared,
              ),
              _Stamp(
                label: 'SURVIVED',
                color: InkSignal.paper,
                active: today == null,
              ),
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
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: InkSignal.panel(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'EPISODE 1 SETTINGS',
                  style: InkSignal.mono(
                    11,
                    color: InkSignal.paper.withValues(alpha: 0.45),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${state.arc} · ${state.rival} · ${state.quest}',
                  style: InkSignal.ui(17, weight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  '${state.repeatRhythm} · Pre-quest jolt: ${state.wakeJolt} · ${state.escapeRule}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: InkSignal.ui(
                    13,
                    color: InkSignal.paper.withValues(alpha: 0.55),
                    weight: FontWeight.w700,
                  ),
                ),
              ],
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
          _LoopRail(
            activeIndex: 0,
            state: state,
            title: "TOMORROW'S WAKE PATH",
          ),
          const SizedBox(height: 18),
          SlabButton(
            "LOCK TOMORROW'S COLD OPEN",
            key: const Key('lockTomorrow'),
            onTap: () => unawaited(_lockTomorrow(state)),
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
              state.alarmEnabled && state.alarmScheduleConfirmed
                  ? 'COMEBACK QUEST ARMED — ${state.alarmLabel}'
                  : 'COMEBACK QUEST READY — ${state.alarmLabel}',
              style: InkSignal.ui(
                15,
                color: InkSignal.knockdownInk,
                weight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(height: 22),
          _LoopRail(activeIndex: 0, state: state, title: 'COMEBACK WAKE PATH'),
          const Spacer(),
          SlabButton(
            'ARM COMEBACK QUEST',
            key: const Key('armComeback'),
            onTap: () => unawaited(_armComeback(state)),
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

class _EpisodeMissionBrief extends StatelessWidget {
  const _EpisodeMissionBrief({
    required this.episode,
    required this.mission,
    required this.title,
  });

  final int episode;
  final String mission;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 11),
      decoration: InkSignal.panel(
        color: InkSignal.base,
        borderColor: InkSignal.inkBorder.withValues(alpha: 0.75),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'EP $episode MISSION',
            style: InkSignal.mono(
              10,
              color: InkSignal.paper.withValues(alpha: 0.42),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            mission,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: InkSignal.ui(16, weight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            'Becomes "$title" after the Wake Quest clears.',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: InkSignal.ui(
              12,
              color: InkSignal.paper.withValues(alpha: 0.55),
              weight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _LockInCard extends StatelessWidget {
  const _LockInCard({
    required this.breathe,
    required this.onTap,
    required this.mission,
  });

  final Animation<double> breathe;
  final VoidCallback onTap;
  final String mission;

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween(
        begin: 1.0,
        end: 1.01,
      ).animate(CurvedAnimation(parent: breathe, curve: Curves.easeInOut)),
      child: GestureDetector(
        key: const Key('lockInButton'),
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: InkSignal.panel(
            color: InkSignal.surface,
            borderColor: InkSignal.inkBorder,
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: InkSignal.crimson,
                  borderRadius: BorderRadius.circular(InkSignal.panelRadius),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33FF2E4C),
                      blurRadius: 20,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: const Icon(Icons.bolt, color: Colors.white, size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MISSION BOOST',
                      style: InkSignal.ui(
                        15,
                        weight: FontWeight.w900,
                        letterSpacing: 0.9,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '20s clip for: $mission',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: InkSignal.ui(
                        13,
                        color: InkSignal.paper.withValues(alpha: 0.56),
                        weight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text('OPEN', style: InkSignal.mono(11, color: InkSignal.crimson)),
              const SizedBox(width: 2),
              const Icon(
                Icons.chevron_right,
                size: 18,
                color: InkSignal.crimson,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoopRail extends StatelessWidget {
  const _LoopRail({
    required this.activeIndex,
    required this.state,
    required this.title,
  });

  final int activeIndex;
  final AppState state;
  final String title;

  @override
  Widget build(BuildContext context) {
    final questLabel = state.questIsRandom ? 'Random draw' : state.quest;
    final completedIndex = activeIndex <= 0
        ? 0
        : activeIndex >= 4
        ? 2
        : 1;
    final steps = [
      _WakePathStep(
        number: '1',
        title: 'Alarm rings',
        detail: '${state.alarmLabel} · ${state.wakeJolt} before quest',
      ),
      _WakePathStep(
        number: '2',
        title: 'Clear Wake Quest',
        detail: '$questLabel turns the alarm off',
      ),
      _WakePathStep(
        number: '3',
        title: 'Episode unlocks',
        detail: 'Voice + cinematic score play',
      ),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 14),
      decoration: InkSignal.panel(color: InkSignal.base),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: InkSignal.mono(
              10,
              color: InkSignal.paper.withValues(alpha: 0.42),
            ),
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < steps.length; i++) ...[
            _WakePathRow(step: steps[i], active: i <= completedIndex),
            if (i != steps.length - 1)
              Padding(
                padding: const EdgeInsets.only(left: 13, top: 3, bottom: 3),
                child: Container(
                  width: 2,
                  height: 12,
                  color: i < completedIndex
                      ? InkSignal.paper.withValues(alpha: 0.62)
                      : InkSignal.inkBorder,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _WakePathStep {
  const _WakePathStep({
    required this.number,
    required this.title,
    required this.detail,
  });

  final String number;
  final String title;
  final String detail;
}

class _WakePathRow extends StatelessWidget {
  const _WakePathRow({required this.step, required this.active});

  final _WakePathStep step;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active
        ? InkSignal.paper
        : InkSignal.paper.withValues(alpha: 0.35);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? InkSignal.paper : Colors.transparent,
            border: Border.all(
              color: active ? InkSignal.paper : InkSignal.inkBorder,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            step.number,
            style: InkSignal.mono(
              11,
              color: active
                  ? InkSignal.base
                  : InkSignal.paper.withValues(alpha: 0.5),
            ),
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.title.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: InkSignal.ui(
                    13,
                    weight: FontWeight.w900,
                    letterSpacing: 0.7,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  step.detail,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: InkSignal.mono(
                    10,
                    color: InkSignal.paper.withValues(
                      alpha: active ? 0.55 : 0.32,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
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
