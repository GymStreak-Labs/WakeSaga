import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../state/app_state.dart';
import '../theme/ink_signal.dart';
import 'alarm_arming.dart';
import 'alarm_engine.dart';
import 'wake_missions.dart';

/// Opens the full-screen Morning Alarm editor over the root navigator.
Future<void> openAlarmStudio(BuildContext context) {
  HapticFeedback.mediumImpact();
  return Navigator.of(context, rootNavigator: true).push(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => const AlarmStudio(),
    ),
  );
}

/// ALARM STUDIO — the serious alarm editor. Default view stays light: time
/// wheel, repeat days, Wake Quest mission, one crimson CTA. Everything else
/// (quest rules, alarm behavior, episode payoff, device reliability) collapses
/// behind section headers so the surface never reads as settings sludge.
class AlarmStudio extends StatefulWidget {
  const AlarmStudio({super.key});

  @override
  State<AlarmStudio> createState() => _AlarmStudioState();
}

class _AlarmStudioState extends State<AlarmStudio> {
  late TimeOfDay _time;
  late bool _enabled;
  late Set<int> _days;
  late String _quest;
  late String _difficulty;
  late String _fallback;
  bool _hydrated = false;

  bool _rulesOpen = false;
  bool _behaviorOpen = false;
  bool _payoffOpen = false;
  bool _healthOpen = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hydrated) return;
    final state = AppScope.of(context, listen: false);
    _time = state.alarmTime;
    _enabled = state.alarmEnabled;
    _days = state.repeatDays.toSet();
    _quest = state.quest;
    _difficulty = state.difficulty;
    _fallback = state.fallbackQuest;
    _hydrated = true;
  }

  String get _daysSummary {
    if (_days.length == 7) return 'EVERY DAY';
    if (_days.length == 5 && _days.containsAll(const {1, 2, 3, 4, 5})) {
      return 'WEEKDAYS';
    }
    if (_days.length == 2 && _days.containsAll(const {6, 7})) {
      return 'WEEKENDS';
    }
    if (_days.isEmpty) return 'ONE TIME — fires once, then stays off';
    const letters = ['MO', 'TU', 'WE', 'TH', 'FR', 'SA', 'SU'];
    return (_days.toList()..sort()).map((d) => letters[d - 1]).join(' ');
  }

  void _shiftTime({int hours = 0, int minutes = 0}) {
    final totalMinutes = (_time.hour * 60 + _time.minute + hours * 60 + minutes)
        .remainder(24 * 60);
    final normalized = totalMinutes < 0 ? totalMinutes + 24 * 60 : totalMinutes;
    setState(
      () => _time = TimeOfDay(hour: normalized ~/ 60, minute: normalized % 60),
    );
    HapticFeedback.selectionClick();
  }

  /// Saves the plan, then schedules through the engine. The Studio pops
  /// immediately; Today's Next Alarm card shows ARMING… until the engine
  /// confirms, so "armed" is never claimed before it is true.
  void _save() {
    HapticFeedback.mediumImpact();
    final state = AppScope.of(context, listen: false);
    final engine = AlarmScope.read(context);
    final previousId =
        state.activeAlarmPlan?.id ?? state.scheduledAlarm?.plan.id;
    state.setAlarm(
      time: _time,
      enabled: _enabled,
      questType: _quest,
      difficultyLevel: _difficulty,
      fallbackQuestType: _fallback,
      repeatDays: _days.toList()..sort(),
    );
    Navigator.of(context).pop();
    if (_enabled) {
      unawaited(armAlarmPlan(state: state, engine: engine));
    } else if (previousId != null) {
      unawaited(engine.cancel(previousId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return Scaffold(
      key: const Key('alarmStudio'),
      backgroundColor: InkSignal.base,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _header(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                children: [
                  _timeControl(),
                  const SizedBox(height: 6),
                  _dayChips(),
                  const SizedBox(height: 24),
                  _sectionLabel('WAKE QUEST — TURNS THE ALARM OFF'),
                  const SizedBox(height: 10),
                  for (final mission in WakeMission.selectable) ...[
                    _missionCard(mission),
                    const SizedBox(height: 8),
                  ],
                  Text(
                    'Proof sensors are simulated in this build.',
                    style: InkSignal.mono(
                      10,
                      color: InkSignal.paper.withValues(alpha: 0.35),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _section(
                    key: const Key('sectionQuestRules'),
                    title: 'WAKE QUEST RULES',
                    summary: '$_difficulty · fallback $_fallback',
                    open: _rulesOpen,
                    onToggle: () => setState(() => _rulesOpen = !_rulesOpen),
                    child: _questRules(),
                  ),
                  _section(
                    key: const Key('sectionAlarmBehavior'),
                    title: 'WAKE JOLT STYLE',
                    summary: '${state.wakeJolt} before quest',
                    open: _behaviorOpen,
                    onToggle: () =>
                        setState(() => _behaviorOpen = !_behaviorOpen),
                    child: _alarmBehavior(state),
                  ),
                  _section(
                    key: const Key('sectionEpisodePayoff'),
                    title: 'EPISODE PAYOFF',
                    summary: 'EP ${state.nextEpisode} unlocks after the quest',
                    open: _payoffOpen,
                    onToggle: () => setState(() => _payoffOpen = !_payoffOpen),
                    child: _episodePayoff(state),
                  ),
                  _section(
                    key: const Key('sectionDeviceReliability'),
                    title: 'DEVICE RELIABILITY',
                    summary: _healthSummary(state),
                    open: _healthOpen,
                    onToggle: () => setState(() => _healthOpen = !_healthOpen),
                    child: _deviceHealth(state),
                  ),
                ],
              ),
            ),
            _stickyCta(),
          ],
        ),
      ),
    );
  }

  // ---- Header ---------------------------------------------------------------

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 12, 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ALARM STUDIO',
                  style: InkSignal.mono(
                    11,
                    color: InkSignal.paper.withValues(alpha: 0.45),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'MORNING ALARM',
                  style: InkSignal.ui(
                    24,
                    weight: FontWeight.w900,
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            key: const Key('alarmStudioEnabled'),
            value: _enabled,
            activeTrackColor: InkSignal.paper,
            activeThumbColor: InkSignal.base,
            onChanged: (value) => setState(() => _enabled = value),
          ),
          const SizedBox(width: 4),
          IconButton(
            key: const Key('alarmStudioClose'),
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: InkSignal.paper),
          ),
        ],
      ),
    );
  }

  // ---- Time + days ----------------------------------------------------------

  Widget _timeControl() {
    return Container(
      key: const Key('alarmStudioTime'),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: InkSignal.panel(color: InkSignal.base),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'ALARM TIME',
            style: InkSignal.mono(
              11,
              color: InkSignal.paper.withValues(alpha: 0.45),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            formatTimeOfDay(_time),
            textAlign: TextAlign.center,
            style: InkSignal.display(58),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _stepButton(
                  label: '-1H',
                  icon: Icons.remove,
                  onTap: () => _shiftTime(hours: -1),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _stepButton(
                  label: '+1H',
                  icon: Icons.add,
                  onTap: () => _shiftTime(hours: 1),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _stepButton(
                  label: '-5M',
                  icon: Icons.remove,
                  onTap: () => _shiftTime(minutes: -5),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _stepButton(
                  label: '+5M',
                  icon: Icons.add,
                  onTap: () => _shiftTime(minutes: 5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stepButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(color: InkSignal.inkBorder, width: 2),
          borderRadius: BorderRadius.circular(InkSignal.panelRadius),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: InkSignal.paper.withValues(alpha: 0.7)),
            const SizedBox(width: 3),
            Text(
              label,
              style: InkSignal.mono(
                11,
                color: InkSignal.paper.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dayChips() {
    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (var day = 1; day <= 7; day++)
              GestureDetector(
                key: Key('dayChip$day'),
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _days.contains(day) ? _days.remove(day) : _days.add(day);
                  });
                },
                child: Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _days.contains(day)
                        ? InkSignal.paper
                        : Colors.transparent,
                    border: Border.all(
                      color: _days.contains(day)
                          ? InkSignal.paper
                          : InkSignal.inkBorder,
                      width: 2,
                    ),
                  ),
                  child: Text(
                    labels[day - 1],
                    style: InkSignal.ui(
                      17,
                      weight: FontWeight.w900,
                      color: _days.contains(day)
                          ? InkSignal.base
                          : InkSignal.paper.withValues(alpha: 0.55),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          _daysSummary,
          style: InkSignal.mono(
            11,
            color: InkSignal.paper.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }

  // ---- Wake Quest mission picker ---------------------------------------------

  Widget _sectionLabel(String text) => Text(
    text,
    style: InkSignal.ui(
      13,
      weight: FontWeight.w900,
      letterSpacing: 2,
      color: InkSignal.paper.withValues(alpha: 0.45),
    ),
  );

  Widget _missionCard(WakeMission mission) {
    final selected = _quest == mission.name;
    return GestureDetector(
      key: Key('mission${mission.name}'),
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _quest = mission.name);
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: InkSignal.panel(
          color: selected ? const Color(0xFF1B2230) : InkSignal.surface,
          borderColor: selected ? InkSignal.paper : InkSignal.inkBorder,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              mission.icon,
              size: 26,
              color: selected
                  ? InkSignal.paper
                  : InkSignal.paper.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          mission.name.toUpperCase(),
                          style: InkSignal.ui(
                            17,
                            weight: FontWeight.w900,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                      if (selected)
                        const Icon(
                          Icons.check_circle,
                          size: 20,
                          color: InkSignal.verifyGreen,
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    mission.action,
                    style: InkSignal.ui(
                      15,
                      color: InkSignal.paper.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'PROOF: ${mission.proof.toUpperCase()} · '
                    'BEST FOR: ${mission.bestFor.toUpperCase()}',
                    style: InkSignal.mono(
                      10,
                      color: InkSignal.paper.withValues(alpha: 0.45),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---- Collapsed sections -----------------------------------------------------

  Widget _section({
    required Key key,
    required String title,
    required String summary,
    required bool open,
    required VoidCallback onToggle,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: InkSignal.panel(color: InkSignal.base),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GestureDetector(
              key: key,
              behavior: HitTestBehavior.opaque,
              onTap: onToggle,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: InkSignal.ui(
                              15,
                              weight: FontWeight.w900,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            summary,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: InkSignal.mono(
                              10,
                              color: InkSignal.paper.withValues(alpha: 0.45),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      open ? Icons.expand_less : Icons.expand_more,
                      color: InkSignal.paper.withValues(alpha: 0.5),
                    ),
                  ],
                ),
              ),
            ),
            if (open)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                child: child,
              ),
          ],
        ),
      ),
    );
  }

  Widget _questRules() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'DIFFICULTY',
          style: InkSignal.mono(
            10,
            color: InkSignal.paper.withValues(alpha: 0.45),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (final level in const ['Easy', 'Normal', 'Hard'])
              _pill(
                key: Key('difficulty$level'),
                label: level,
                selected: _difficulty == level,
                onTap: () => setState(() => _difficulty = level),
              ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          'FALLBACK QUEST',
          style: InkSignal.mono(
            10,
            color: InkSignal.paper.withValues(alpha: 0.45),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (final fallback in const ['Shake', 'Get Up'])
              _pill(
                key: Key('fallback$fallback'),
                label: fallback,
                selected: _fallback == fallback,
                onTap: () => setState(() => _fallback = fallback),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'No traps: 2 failed verifies switch to the fallback quest. '
          'A 3rd fail ends the alarm and logs a Filler chapter.',
          style: InkSignal.ui(
            15,
            color: InkSignal.paper.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Widget _alarmBehavior(AppState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _factRow('NARRATOR', '${state.narrator} — who speaks'),
        _factRow('PRE-QUEST JOLT', '${state.wakeJolt} while alarm rings'),
        _factRow('POST-QUEST VOICE', 'Morning Episode after quest clear'),
        _factRow('SIREN', 'In-app siren behind the jolt until clear'),
        _factRow('FILLER', 'Snooze 9 min — always visible while ringing'),
        _factRow('FILLER COST', state.escapeRule),
        _factRow('HAPTICS', 'Heavy impact while ringing'),
      ],
    );
  }

  Widget _episodePayoff(AppState state) {
    final title = state.missionText.isEmpty
        ? 'THE ONE WHO STOOD UP'
        : deriveEpisodeTitle(state.missionText, state.nextEpisode);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: InkSignal.panel(
        color: const Color(0xFF1A1610),
        borderColor: InkSignal.gold.withValues(alpha: 0.55),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'MORNING EPISODE — UNLOCKED BY THE QUEST',
            style: InkSignal.mono(10, color: InkSignal.gold),
          ),
          const SizedBox(height: 8),
          Text(
            'EP ${state.nextEpisode} · "$title"',
            style: InkSignal.ui(17, weight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            'Narrated by ${state.narrator} · mints a Wake Card on clear',
            style: InkSignal.ui(
              15,
              color: InkSignal.paper.withValues(alpha: 0.65),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'RING → QUEST → ALARM OFF → EPISODE UNLOCKED → '
            'TITLE CARD → EPISODE → WAKE CARD',
            style: InkSignal.mono(
              10,
              color: InkSignal.paper.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  String _healthSummary(AppState state) {
    if (!_enabled) return 'alarm off';
    if (state.alarmScheduleError != null) return 'NOT ARMED — needs fix';
    if (state.alarmScheduleConfirmed) {
      return 'scheduled · ${state.alarmScheduleMode}';
    }
    return 'will schedule on save';
  }

  Widget _deviceHealth(AppState state) {
    final failed = state.alarmScheduleError != null;
    final confirmed = state.alarmScheduleConfirmed;
    final statusColor = failed
        ? InkSignal.knockdownInk
        : confirmed
        ? InkSignal.verifyGreen
        : InkSignal.paper.withValues(alpha: 0.6);
    final statusText = failed
        ? state.alarmScheduleError!
        : confirmed
        ? 'System schedule confirmed (${state.alarmScheduleMode})'
        : _enabled
        ? 'Not scheduled yet — arming happens on save'
        : 'Alarm is off — nothing scheduled';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              failed
                  ? Icons.error_outline
                  : confirmed
                  ? Icons.verified
                  : Icons.schedule,
              size: 18,
              color: statusColor,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                statusText,
                style: InkSignal.ui(
                  15,
                  weight: FontWeight.w700,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'WakeSaga only shows ARMED after the system alarm engine '
          'confirms the schedule.',
          style: InkSignal.ui(
            15,
            color: InkSignal.paper.withValues(alpha: 0.55),
          ),
        ),
      ],
    );
  }

  Widget _factRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: InkSignal.mono(
                10,
                color: InkSignal.paper.withValues(alpha: 0.45),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: InkSignal.ui(15, weight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pill({
    required Key key,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      key: key,
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
            weight: FontWeight.w700,
            color: selected ? InkSignal.base : InkSignal.paper,
          ),
        ),
      ),
    );
  }

  // ---- Sticky CTA -------------------------------------------------------------

  /// The screen's single crimson element.
  Widget _stickyCta() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
      decoration: const BoxDecoration(
        color: InkSignal.base,
        border: Border(top: BorderSide(color: InkSignal.inkBorder, width: 2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SlabButton(
            _enabled ? 'ARM MORNING ALARM' : 'SAVE — ALARM OFF',
            key: const Key('armAlarm'),
            onTap: _save,
          ),
          const SizedBox(height: 8),
          Text(
            _enabled
                ? '${formatTimeOfDay(_time)} · $_daysSummary · '
                      '${_quest == WakeMission.randomName ? "TONIGHT'S RANDOM DRAW" : _quest.toUpperCase()} silences it'
                : 'No alarm will ring. Tomorrow stays unwritten.',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: InkSignal.mono(
              10,
              color: InkSignal.paper.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}
