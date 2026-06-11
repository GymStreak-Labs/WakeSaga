import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme/ink_signal.dart';
import '../widgets/screentone.dart';

/// SAGA — the identity shelf. Episode count enormous at top, manga volume
/// spines per 14-day arc, then Timeline / Binder / Rival segments.
/// Knockdowns in red ink, fillers grey. A personal manga library.
class SagaTab extends StatefulWidget {
  const SagaTab({super.key});

  @override
  State<SagaTab> createState() => _SagaTabState();
}

class _SagaTabState extends State<SagaTab> {
  int _segment = 0; // 0 Timeline, 1 Binder, 2 Rival.

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          20,
          12,
          20,
          InkSignal.tabBarClearance + 16,
        ),
        children: [
          // The headline number: additive, unbreakable. Full-bleed type.
          SizedBox(
            width: double.infinity,
            child: FittedBox(
              fit: BoxFit.contain,
              alignment: Alignment.centerLeft,
              child: SkewedDisplay('EP ${state.episodeCount}', size: 140),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'ADDITIVE. UNBREAKABLE. NEVER RESETS.',
            style: InkSignal.mono(
              12,
              color: InkSignal.paper.withValues(alpha: 0.45),
            ),
          ),
          const SizedBox(height: 8),
          // Honest ledger: every outcome is canon, so every outcome counts.
          Text(
            '${state.mintedCards.length} CLEARED · '
            '${state.log.where((r) => r.outcome == DayOutcome.filler).length} FILLER · '
            '${state.log.where((r) => r.outcome == DayOutcome.knockdown).length} KNOCKDOWN · '
            '${state.log.where((r) => r.foil != null).length} ✦ FOIL',
            style: InkSignal.mono(
              12,
              color: InkSignal.paper.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 24),
          _VolumeShelf(state: state),
          const SizedBox(height: 24),
          _SegmentedBar(
            segments: const ['TIMELINE', 'BINDER', 'RIVAL'],
            selected: _segment,
            onChanged: (value) => setState(() => _segment = value),
          ),
          const SizedBox(height: 16),
          switch (_segment) {
            0 => _Timeline(state: state),
            1 => _Binder(state: state),
            _ => _RivalLog(state: state),
          },
        ],
      ),
    );
  }
}

/// Horizontal shelf of bound manga volume spines, one per 14-day arc.
class _VolumeShelf extends StatelessWidget {
  const _VolumeShelf({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final arcCount = state.arcNumber;
    return SizedBox(
      height: 150,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: arcCount,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final arc = index + 1;
          final isCurrent = arc == state.arcNumber;
          final fill = isCurrent
              ? (state.arcDay - 1) / AppState.arcLength
              : 1.0;
          final complete = !isCurrent;
          return Container(
            width: 64,
            decoration: InkSignal.panel(
              color: const Color(0xFF1B2230),
              // Gold trim only on finished volumes — a milestone.
              borderColor: complete ? InkSignal.gold : InkSignal.inkBorder,
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                const CustomPaint(painter: ScreentonePainter(opacity: 0.06)),
                // Spine progress fill (bottom-up) for the current arc.
                Align(
                  alignment: Alignment.bottomCenter,
                  child: FractionallySizedBox(
                    heightFactor: fill.clamp(0.0, 1.0),
                    widthFactor: 1,
                    child: ColoredBox(
                      color: InkSignal.paper.withValues(alpha: 0.08),
                    ),
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        'VOL',
                        style: InkSignal.mono(
                          10,
                          color: InkSignal.paper.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                    SkewedDisplay(_TodayRoman.of(arc), size: 30),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        complete ? 'DONE' : 'DAY ${state.arcDay}',
                        style: InkSignal.mono(
                          9,
                          color: complete
                              ? InkSignal.gold
                              : InkSignal.paper.withValues(alpha: 0.5),
                        ),
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

/// Vertical list of daily pages, newest first. Knockdowns in red ink with a
/// struck treatment; filler rows grey-toned, no shame copy.
class _Timeline extends StatelessWidget {
  const _Timeline({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final records = state.log.reversed.toList();
    return Column(
      children: [
        for (final record in records)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _TimelineRow(record: record),
          ),
      ],
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.record});

  final DayRecord record;

  @override
  Widget build(BuildContext context) {
    switch (record.outcome) {
      case DayOutcome.knockdown:
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: InkSignal.panel(
            color: const Color(0xFF1A0D12),
            borderColor: InkSignal.knockdownInk,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'EP ${record.episode}',
                      style: InkSignal.mono(11, color: InkSignal.knockdownInk),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      record.title,
                      style: InkSignal.ui(
                        17,
                        color: InkSignal.knockdownInk,
                        weight: FontWeight.w900,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'CANON',
                style: InkSignal.mono(11, color: InkSignal.knockdownInk),
              ),
            ],
          ),
        );
      case DayOutcome.filler:
        return Opacity(
          opacity: 0.45,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: InkSignal.panel(),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('EP ${record.episode}', style: InkSignal.mono(11)),
                      const SizedBox(height: 4),
                      Text(
                        record.title,
                        style: InkSignal.ui(17, weight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                Text('FILLER', style: InkSignal.mono(11)),
              ],
            ),
          ),
        );
      case DayOutcome.cleared:
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: InkSignal.panel(),
          child: Row(
            children: [
              MiniCardThumb(record: record, width: 44, height: 58),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'EP ${record.episode}'
                      '${record.foil != null ? ' · ✦ ${record.foil}' : ''}',
                      style: InkSignal.mono(
                        11,
                        color: record.foil != null
                            ? InkSignal.gold
                            : InkSignal.paper.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      record.title,
                      style: InkSignal.ui(
                        17,
                        weight: FontWeight.w900,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                record.wakeTime,
                style: InkSignal.ui(17, weight: FontWeight.w700),
              ),
            ],
          ),
        );
    }
  }
}

class _Binder extends StatelessWidget {
  const _Binder({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final cards = state.mintedCards.reversed.toList();
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 0.72,
      children: [
        for (final card in cards)
          MiniCardThumb(record: card, width: 72, height: 100),
      ],
    );
  }
}

class _RivalLog extends StatelessWidget {
  const _RivalLog({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final taunts = [
      '"${state.userName}. ${state.alarmLabel} again tomorrow. '
          "I'll be up at 5.\"",
      '"You bought nine minutes on episode 11. I counted."',
      '"Arc ${state.arcNumber} already? Try to keep it interesting."',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final taunt in taunts)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: InkSignal.panel(),
              child: Text(
                taunt,
                style: InkSignal.ui(
                  17,
                  color: InkSignal.paper.withValues(alpha: 0.85),
                ),
              ),
            ),
          ),
        const SizedBox(height: 6),
        Text(
          'RIVAL INTENSITY: ${state.rivalIntensity.toUpperCase()} — '
          'CHANGE IT IN CAST · NEVER TAUNTS DURING RECOVERY',
          style: InkSignal.mono(
            11,
            color: InkSignal.paper.withValues(alpha: 0.4),
          ),
        ),
      ],
    );
  }
}

abstract final class _TodayRoman {
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
