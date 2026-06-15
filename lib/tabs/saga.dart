import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../state/app_state.dart';
import '../theme/ink_signal.dart';
import '../widgets/screentone.dart';

/// SAGA — durable proof/history.
/// Today owns the live alarm loop. Saga owns the honest record: latest Wake
/// Card, arc progress, readable outcomes, and the episode/card archive.
class SagaTab extends StatefulWidget {
  const SagaTab({super.key, this.onOpenToday});

  final VoidCallback? onOpenToday;

  @override
  State<SagaTab> createState() => _SagaTabState();
}

class _SagaTabState extends State<SagaTab> {
  int _segment = 0; // 0 Log, 1 Cards.

  void _openRecordDetail(DayRecord record) {
    HapticFeedback.selectionClick();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EpisodeDetailSheet(record: record),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final latestCard = state.mintedCards.isEmpty
        ? null
        : state.mintedCards.last;
    final hasHistory = state.log.isNotEmpty;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          20,
          14,
          20,
          InkSignal.tabBarClearance + 18,
        ),
        children: [
          _SagaHeader(state: state),
          const SizedBox(height: 18),
          if (latestCard == null)
            _FirstPageHero(state: state, onOpenToday: widget.onOpenToday)
          else
            _LatestWakeCardHero(
              record: latestCard,
              onTap: () => _openRecordDetail(latestCard),
            ),
          const SizedBox(height: 14),
          _NextEpisodeStrip(state: state, onTap: widget.onOpenToday),
          const SizedBox(height: 16),
          _ArcProgressPanel(state: state),
          const SizedBox(height: 16),
          _StatsGrid(state: state),
          const SizedBox(height: 18),
          if (hasHistory) ...[
            _SegmentedBar(
              segments: const ['LOG', 'CARDS'],
              selected: _segment,
              onChanged: (value) => setState(() => _segment = value),
            ),
            const SizedBox(height: 14),
            switch (_segment) {
              0 => _Timeline(state: state, onRecordTap: _openRecordDetail),
              _ => _CardBinder(state: state, onRecordTap: _openRecordDetail),
            },
          ] else
            _EmptyLogHint(alarmLabel: state.alarmLabel),
        ],
      ),
    );
  }
}

class _SagaHeader extends StatelessWidget {
  const _SagaHeader({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: SkewedDisplay('SAGA', size: 86),
              ),
            ),
            const SizedBox(width: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
              decoration: InkSignal.panel(color: InkSignal.surface),
              child: Text(
                'EP ${state.episodeCount}',
                style: InkSignal.ui(
                  16,
                  weight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Every cleared alarm becomes an episode. This is your record.',
          style: InkSignal.ui(
            16,
            color: InkSignal.paper.withValues(alpha: 0.67),
            weight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _FirstPageHero extends StatelessWidget {
  const _FirstPageHero({required this.state, required this.onOpenToday});

  final AppState state;
  final VoidCallback? onOpenToday;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: InkSignal.panel(
        color: const Color(0xFF171D29),
        borderColor: InkSignal.paper.withValues(alpha: 0.34),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'VOLUME I · BLANK FIRST PAGE',
            style: InkSignal.mono(
              11,
              color: InkSignal.paper.withValues(alpha: 0.45),
            ),
          ),
          const SizedBox(height: 10),
          SkewedDisplay('EPISODE 1', size: 34),
          const SizedBox(height: 8),
          Text(
            'Clear your first Wake Quest at ${state.alarmLabel}. '
            'WakeSaga will mint the first card here.',
            style: InkSignal.ui(
              17,
              color: InkSignal.paper.withValues(alpha: 0.72),
              weight: FontWeight.w700,
            ),
          ),
          if (onOpenToday != null) ...[
            const SizedBox(height: 16),
            GestureDetector(
              key: const Key('sagaOpenToday'),
              onTap: onOpenToday,
              child: Container(
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: InkSignal.crimson,
                  borderRadius: BorderRadius.circular(InkSignal.panelRadius),
                ),
                child: Text(
                  'CHECK TODAY',
                  style: InkSignal.ui(
                    16,
                    color: Colors.white,
                    weight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LatestWakeCardHero extends StatelessWidget {
  const _LatestWakeCardHero({required this.record, required this.onTap});

  final DayRecord record;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasFoil = record.foil != null;
    return GestureDetector(
      key: const Key('latestWakeCardHero'),
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: InkSignal.panel(
          color: const Color(0xFF171D29),
          borderColor: hasFoil ? InkSignal.gold : InkSignal.inkBorder,
        ),
        child: Row(
          children: [
            MiniCardThumb(record: record, width: 84, height: 116),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'LATEST WAKE CARD',
                    style: InkSignal.mono(
                      11,
                      color: InkSignal.paper.withValues(alpha: 0.42),
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    'EP ${record.episode} CLEARED',
                    style: InkSignal.ui(
                      16,
                      weight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    record.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: InkSignal.ui(21, weight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${record.wakeTime} · tap to view card',
                    style: InkSignal.ui(
                      14,
                      color: InkSignal.paper.withValues(alpha: 0.58),
                      weight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Icon(
              Icons.chevron_right,
              color: hasFoil ? InkSignal.gold : InkSignal.paper,
            ),
          ],
        ),
      ),
    );
  }
}

class _NextEpisodeStrip extends StatelessWidget {
  const _NextEpisodeStrip({required this.state, required this.onTap});

  final AppState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: InkSignal.panel(color: InkSignal.base),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'NEXT',
                    style: InkSignal.mono(
                      10,
                      color: InkSignal.paper.withValues(alpha: 0.4),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'EP ${state.nextEpisode} drops at ${state.alarmLabel}',
                    style: InkSignal.ui(16, weight: FontWeight.w900),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${state.quest} first · ${state.missionText}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: InkSignal.ui(
                      13,
                      color: InkSignal.paper.withValues(alpha: 0.52),
                      weight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Text(
                'TODAY',
                style: InkSignal.mono(11, color: InkSignal.crimson),
              ),
          ],
        ),
      ),
    );
  }
}

class _ArcProgressPanel extends StatelessWidget {
  const _ArcProgressPanel({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final completedInVolume = state.episodeCount % AppState.arcLength;
    final progress = (completedInVolume / AppState.arcLength).clamp(0.0, 1.0);
    final nextDay = completedInVolume + 1;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: InkSignal.panel(color: InkSignal.surface),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ARC PROGRESS',
            style: InkSignal.mono(
              10,
              color: InkSignal.paper.withValues(alpha: 0.42),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Volume ${_Roman.of(state.arcNumber)} · Day $nextDay of ${AppState.arcLength}',
                  style: InkSignal.ui(18, weight: FontWeight.w900),
                ),
              ),
              Text(
                '$completedInVolume cleared',
                style: InkSignal.mono(
                  12,
                  color: InkSignal.paper.withValues(alpha: 0.55),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              color: progress >= 1 ? InkSignal.gold : InkSignal.paper,
              backgroundColor: InkSignal.inkBorder,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'A volume is a 14-day arc. Misses count too — they become canon chapters, not broken streaks.',
            style: InkSignal.ui(
              13,
              color: InkSignal.paper.withValues(alpha: 0.56),
              weight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          _VolumeShelf(state: state),
        ],
      ),
    );
  }
}

/// Horizontal shelf of bound manga volume spines, one per active arc.
class _VolumeShelf extends StatelessWidget {
  const _VolumeShelf({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final arcCount = state.arcNumber;
    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: arcCount,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final arc = index + 1;
          final isCurrent = arc == state.arcNumber;
          final currentProgress =
              (state.episodeCount % AppState.arcLength) / AppState.arcLength;
          final fill = isCurrent ? currentProgress.clamp(0.0, 1.0) : 1.0;
          final complete = !isCurrent;
          return Container(
            width: 54,
            decoration: InkSignal.panel(
              color: const Color(0xFF1B2230),
              borderColor: complete ? InkSignal.gold : InkSignal.inkBorder,
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                const CustomPaint(painter: ScreentonePainter(opacity: 0.06)),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: FractionallySizedBox(
                    heightFactor: fill,
                    widthFactor: 1,
                    child: ColoredBox(
                      color: InkSignal.paper.withValues(alpha: 0.08),
                    ),
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'VOL',
                      style: InkSignal.mono(
                        9,
                        color: InkSignal.paper.withValues(alpha: 0.48),
                      ),
                    ),
                    const SizedBox(height: 4),
                    SkewedDisplay(_Roman.of(arc), size: 26),
                    const SizedBox(height: 4),
                    Text(
                      complete ? 'DONE' : 'NOW',
                      style: InkSignal.mono(
                        8,
                        color: complete
                            ? InkSignal.gold
                            : InkSignal.paper.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final cleared = state.mintedCards.length;
    final snoozed = state.log
        .where((record) => record.outcome == DayOutcome.filler)
        .length;
    final missed = state.log
        .where((record) => record.outcome == DayOutcome.knockdown)
        .length;
    final foils = state.log.where((record) => record.foil != null).length;
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.7,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      children: [
        _StatChip(value: '$cleared', label: 'Cleared alarms'),
        _StatChip(value: '$snoozed', label: 'Snoozed chapters'),
        _StatChip(value: '$missed', label: 'Missed mornings'),
        _StatChip(value: '$foils', label: 'Foil cards', gold: foils > 0),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.value,
    required this.label,
    this.gold = false,
  });

  final String value;
  final String label;
  final bool gold;

  @override
  Widget build(BuildContext context) {
    final color = gold ? InkSignal.gold : InkSignal.paper;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: InkSignal.panel(color: InkSignal.base),
      child: Row(
        children: [
          Text(value, style: InkSignal.display(25, color: color)),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: InkSignal.ui(
                12,
                color: InkSignal.paper.withValues(alpha: 0.58),
                weight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentedBar extends StatelessWidget {
  const _SegmentedBar({
    required this.segments,
    required this.selected,
    required this.onChanged,
  });

  final List<String> segments;
  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: InkSignal.inkBorder, width: 2),
        borderRadius: BorderRadius.circular(InkSignal.panelRadius),
      ),
      child: Row(
        children: [
          for (var i = 0; i < segments.length; i++)
            Expanded(
              child: GestureDetector(
                key: Key('segment${segments[i]}'),
                onTap: () => onChanged(i),
                child: Container(
                  height: 44,
                  alignment: Alignment.center,
                  color: i == selected ? InkSignal.paper : Colors.transparent,
                  child: Text(
                    segments[i],
                    style: InkSignal.ui(
                      14,
                      weight: FontWeight.w900,
                      letterSpacing: 1.2,
                      color: i == selected
                          ? InkSignal.base
                          : InkSignal.paper.withValues(alpha: 0.55),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyLogHint extends StatelessWidget {
  const _EmptyLogHint({required this.alarmLabel});

  final String alarmLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: InkSignal.panel(color: InkSignal.base),
      child: Text(
        'Your episode log starts after the $alarmLabel alarm is cleared.',
        style: InkSignal.ui(
          15,
          color: InkSignal.paper.withValues(alpha: 0.58),
          weight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _Timeline extends StatelessWidget {
  const _Timeline({required this.state, required this.onRecordTap});

  final AppState state;
  final ValueChanged<DayRecord> onRecordTap;

  @override
  Widget build(BuildContext context) {
    final records = state.log.reversed.toList();
    return Column(
      children: [
        for (final record in records)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _TimelineRow(
              record: record,
              onTap: () => onRecordTap(record),
            ),
          ),
      ],
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.record, required this.onTap});

  final DayRecord record;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = _outcomeColor(record);
    final dim = record.outcome == DayOutcome.filler;
    return Opacity(
      opacity: dim ? 0.58 : 1,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: InkSignal.panel(
            color: record.outcome == DayOutcome.knockdown
                ? const Color(0xFF1A0D12)
                : InkSignal.surface,
            borderColor: record.outcome == DayOutcome.knockdown
                ? InkSignal.knockdownInk
                : record.foil != null
                ? InkSignal.gold
                : InkSignal.inkBorder,
          ),
          child: Row(
            children: [
              _OutcomeMark(record: record),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'EP ${record.episode} · ${_outcomeLabel(record)}',
                      style: InkSignal.mono(11, color: color),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      record.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: color == InkSignal.knockdownInk
                          ? InkSignal.ui(
                              17,
                              color: color,
                              weight: FontWeight.w900,
                              letterSpacing: 0.3,
                            )
                          : InkSignal.ui(
                              17,
                              weight: FontWeight.w900,
                              letterSpacing: 0.3,
                            ),
                    ),
                    if (record.outcome != DayOutcome.cleared) ...[
                      const SizedBox(height: 3),
                      Text(
                        record.outcome == DayOutcome.filler
                            ? 'Snoozed, still canon.'
                            : 'Missed, not reset.',
                        style: InkSignal.ui(
                          12,
                          color: InkSignal.paper.withValues(alpha: 0.44),
                          weight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                record.wakeTime == '—' ? 'VIEW' : record.wakeTime,
                style: InkSignal.ui(15, color: color, weight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OutcomeMark extends StatelessWidget {
  const _OutcomeMark({required this.record});

  final DayRecord record;

  @override
  Widget build(BuildContext context) {
    if (record.outcome == DayOutcome.cleared) {
      return MiniCardThumb(record: record, width: 44, height: 58);
    }
    final color = _outcomeColor(record);
    return Container(
      width: 44,
      height: 58,
      alignment: Alignment.center,
      decoration: InkSignal.panel(
        color: InkSignal.base,
        borderColor: color.withValues(alpha: 0.72),
      ),
      child: Icon(
        record.outcome == DayOutcome.filler
            ? Icons.snooze_rounded
            : Icons.report_gmailerrorred_rounded,
        color: color,
      ),
    );
  }
}

class _CardBinder extends StatelessWidget {
  const _CardBinder({required this.state, required this.onRecordTap});

  final AppState state;
  final ValueChanged<DayRecord> onRecordTap;

  @override
  Widget build(BuildContext context) {
    final cards = state.mintedCards.reversed.toList();
    if (cards.isEmpty) {
      return const _EmptyLogHint(alarmLabel: 'next');
    }
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 0.72,
      children: [
        for (final card in cards)
          GestureDetector(
            onTap: () => onRecordTap(card),
            child: MiniCardThumb(record: card, width: 88, height: 122),
          ),
      ],
    );
  }
}

class _EpisodeDetailSheet extends StatelessWidget {
  const _EpisodeDetailSheet({required this.record});

  final DayRecord record;

  @override
  Widget build(BuildContext context) {
    final cleared = record.outcome == DayOutcome.cleared;
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        18,
        20,
        20 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: const BoxDecoration(
        color: InkSignal.base,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: InkSignal.paper.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (cleared)
                MiniCardThumb(record: record, width: 94, height: 132)
              else
                _OutcomeMark(record: record),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'EP ${record.episode} · ${_outcomeLabel(record)}',
                      style: InkSignal.mono(11, color: _outcomeColor(record)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      record.title,
                      style: InkSignal.ui(23, weight: FontWeight.w900),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      cleared
                          ? 'Cleared at ${record.wakeTime}. This card is proof.'
                          : record.outcome == DayOutcome.filler
                          ? 'Snoozed chapter. Still counted, never hidden.'
                          : 'Knockdown chapter. The streak did not reset.',
                      style: InkSignal.ui(
                        15,
                        color: InkSignal.paper.withValues(alpha: 0.62),
                        weight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (cleared)
            GestureDetector(
              key: const Key('shareWakeCard'),
              onTap: () {
                HapticFeedback.mediumImpact();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    duration: const Duration(milliseconds: 950),
                    backgroundColor: InkSignal.surface,
                    content: Text(
                      'Share/export is next for Wake Cards.',
                      style: InkSignal.ui(15, weight: FontWeight.w800),
                    ),
                  ),
                );
              },
              child: Container(
                height: 54,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: InkSignal.gold,
                  borderRadius: BorderRadius.circular(InkSignal.panelRadius),
                ),
                child: Text(
                  'SHARE WAKE CARD',
                  style: InkSignal.ui(
                    16,
                    color: InkSignal.base,
                    weight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

Color _outcomeColor(DayRecord record) {
  if (record.foil != null) return InkSignal.gold;
  return switch (record.outcome) {
    DayOutcome.cleared => InkSignal.paper,
    DayOutcome.filler => InkSignal.paper.withValues(alpha: 0.58),
    DayOutcome.knockdown => InkSignal.knockdownInk,
  };
}

String _outcomeLabel(DayRecord record) {
  if (record.foil != null) return 'FOIL CARD';
  return switch (record.outcome) {
    DayOutcome.cleared => 'CLEARED',
    DayOutcome.filler => 'SNOOZED',
    DayOutcome.knockdown => 'MISSED',
  };
}

abstract final class _Roman {
  static String of(int value) => switch (value) {
    1 => 'I',
    2 => 'II',
    3 => 'III',
    4 => 'IV',
    5 => 'V',
    6 => 'VI',
    _ => '$value',
  };
}
