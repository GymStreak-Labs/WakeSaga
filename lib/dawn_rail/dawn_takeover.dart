import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../state/app_state.dart';
import '../theme/ink_signal.dart';
import '../widgets/cuts.dart';
import '../widgets/screentone.dart';
import 'wake_quest.dart';

/// Dawn Rail step 1 — the alarm-ringing takeover.
/// Full-bleed OLED black, zero nav chrome, no back. EP number huge,
/// cold-open subtitle, one crimson BEGIN QUEST slab in the bottom 45%,
/// and a visible dim "FILLER (snooze 9 min)" row. The alarm never traps.
class DawnTakeover extends StatefulWidget {
  const DawnTakeover({super.key});

  @override
  State<DawnTakeover> createState() => _DawnTakeoverState();
}

class _DawnTakeoverState extends State<DawnTakeover>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  void _beginQuest() {
    HapticFeedback.heavyImpact();
    Navigator.of(
      context,
    ).push(hardCut(const SmashCutFlash(child: WakeQuest())));
  }

  void _takeFiller() {
    HapticFeedback.mediumImpact();
    final state = AppScope.of(context);
    state.logFiller();
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            const _AlarmBackplate(),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
                child: Column(
                  children: [
                    _AlarmHeader(
                      alarmLabel: state.alarmLabel,
                      episode: state.nextEpisode,
                    ),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final faceSize = math.min(
                            292.0,
                            math.max(232.0, constraints.maxHeight * 0.48),
                          );
                          return Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _EpicAlarmFace(
                                alarmLabel: state.alarmLabel,
                                episode: state.nextEpisode,
                                size: faceSize,
                                pulse: _pulse,
                              ),
                              const SizedBox(height: 14),
                              StrokedSubtitle(
                                'Alarm is live. ${state.quest} turns it off.',
                                size: 20,
                              ),
                              const SizedBox(height: 14),
                              _QuestLockPanel(
                                name: state.userName,
                                quest: state.quest,
                                proof: state.proof,
                                questPlace: state.questPlace,
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(2, 0, 2, 0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // The one hard crimson command: the alarm can only
                          // be silenced by entering the Wake Quest.
                          SlabButton(
                            'TURN OFF ALARM',
                            key: const Key('beginQuest'),
                            onTap: _beginQuest,
                            height: 88,
                          ),
                          const SizedBox(height: 10),
                          _AlarmWaveform(pulse: _pulse),
                          const SizedBox(height: 10),
                          Text(
                            'Wake Quest required',
                            style: InkSignal.mono(
                              12,
                              color: InkSignal.paper.withValues(alpha: 0.54),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Honest, labeled, visible escape. Costs a grey panel.
                          GestureDetector(
                            key: const Key('fillerRow'),
                            behavior: HitTestBehavior.opaque,
                            onTap: _takeFiller,
                            child: Container(
                              height: InkSignal.slabHeight,
                              alignment: Alignment.center,
                              child: Opacity(
                                opacity: 0.5,
                                child: Text(
                                  'FILLER (snooze 9 min)',
                                  style: InkSignal.ui(
                                    18,
                                    weight: FontWeight.w700,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
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
}

class _AlarmBackplate extends StatelessWidget {
  const _AlarmBackplate();

  @override
  Widget build(BuildContext context) {
    return const Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, -0.64),
              radius: 1.08,
              colors: [Color(0xFF3B0714), Color(0xFF160811), Colors.black],
              stops: [0, 0.45, 1],
            ),
          ),
        ),
        CustomPaint(
          painter: SpeedLinesPainter(color: InkSignal.crimson, opacity: 0.09),
        ),
        CustomPaint(painter: ScreentonePainter(opacity: 0.04)),
      ],
    );
  }
}

class _AlarmHeader extends StatelessWidget {
  const _AlarmHeader({required this.alarmLabel, required this.episode});

  final String alarmLabel;
  final int episode;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'COLD OPEN ALARM',
                style: InkSignal.mono(
                  12,
                  color: InkSignal.paper.withValues(alpha: 0.55),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'EP $episode · $alarmLabel',
                style: InkSignal.ui(20, weight: FontWeight.w900),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: InkSignal.crimson.withValues(alpha: 0.16),
            border: Border.all(
              color: InkSignal.crimson.withValues(alpha: 0.82),
              width: 2,
            ),
            borderRadius: BorderRadius.circular(InkSignal.panelRadius),
          ),
          child: Text(
            'RINGING',
            style: InkSignal.mono(11, color: InkSignal.crimson),
          ),
        ),
      ],
    );
  }
}

class _EpicAlarmFace extends StatelessWidget {
  const _EpicAlarmFace({
    required this.alarmLabel,
    required this.episode,
    required this.size,
    required this.pulse,
  });

  final String alarmLabel;
  final int episode;
  final double size;
  final Animation<double> pulse;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulse,
      builder: (context, _) {
        final beat = Curves.easeInOut.transform(pulse.value);
        return SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _AlarmShockPainter(beat: beat),
            child: Center(
              child: Transform.scale(
                scale: 1 + beat * 0.035,
                child: Container(
                  width: size * 0.68,
                  height: size * 0.68,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black,
                    border: Border.all(
                      color: InkSignal.paper.withValues(alpha: 0.92),
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: InkSignal.crimson.withValues(
                          alpha: 0.24 + beat * 0.24,
                        ),
                        blurRadius: 38 + beat * 24,
                        spreadRadius: 2 + beat * 8,
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _AlarmTicksPainter(beat: beat),
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'ALARM LIVE',
                            style: InkSignal.mono(
                              10,
                              color: InkSignal.crimson.withValues(alpha: 0.9),
                            ),
                          ),
                          const SizedBox(height: 8),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: SkewedDisplay(alarmLabel, size: size * 0.17),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'EP $episode · WAKE QUEST LOCK',
                            textAlign: TextAlign.center,
                            style: InkSignal.mono(
                              9,
                              color: InkSignal.paper.withValues(alpha: 0.48),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _QuestLockPanel extends StatelessWidget {
  const _QuestLockPanel({
    required this.name,
    required this.quest,
    required this.proof,
    required this.questPlace,
  });

  final String name;
  final String quest;
  final String proof;
  final String questPlace;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 14),
      decoration: InkSignal.panel(color: const Color(0xFF0F131C)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'NARRATOR',
                style: InkSignal.mono(
                  10,
                  color: InkSignal.paper.withValues(alpha: 0.44),
                ),
              ),
              const Spacer(),
              Text(
                'ALARM -> QUEST -> EPISODE',
                style: InkSignal.mono(
                  10,
                  color: InkSignal.paper.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            '"$name. Up. $quest turns this off."',
            style: InkSignal.ui(18, weight: FontWeight.w900),
          ),
          const SizedBox(height: 11),
          Row(
            children: [
              Expanded(
                child: _LockFact(label: 'QUEST', value: quest),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _LockFact(label: 'PROOF', value: proof),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            questPlace,
            style: InkSignal.mono(
              11,
              color: InkSignal.paper.withValues(alpha: 0.52),
            ),
          ),
        ],
      ),
    );
  }
}

class _LockFact extends StatelessWidget {
  const _LockFact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.28),
        border: Border.all(
          color: InkSignal.paper.withValues(alpha: 0.12),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(InkSignal.panelRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: InkSignal.mono(
              9,
              color: InkSignal.paper.withValues(alpha: 0.38),
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: InkSignal.ui(14, weight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _AlarmWaveform extends StatelessWidget {
  const _AlarmWaveform({required this.pulse});

  final Animation<double> pulse;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulse,
      builder: (context, _) {
        final beat = Curves.easeInOut.transform(pulse.value);
        return SizedBox(
          height: 28,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(23, (index) {
              final phase = math.sin(index * 0.9 + beat * math.pi * 2);
              final height = 8 + phase.abs() * 16;
              final isCenter = (index - 11).abs() < 3;
              return Container(
                width: 3,
                height: height,
                margin: const EdgeInsets.symmetric(horizontal: 2.4),
                decoration: BoxDecoration(
                  color: (isCenter ? InkSignal.crimson : InkSignal.paper)
                      .withValues(alpha: isCenter ? 0.88 : 0.28),
                  borderRadius: BorderRadius.circular(1),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}

class _AlarmShockPainter extends CustomPainter {
  const _AlarmShockPainter({required this.beat});

  final double beat;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.shortestSide / 2;

    for (var i = 0; i < 4; i++) {
      final t = ((beat + i * 0.23) % 1.0);
      final radius = maxRadius * (0.38 + t * 0.58);
      final alpha = (1 - t) * 0.34;
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4 - t * 2
          ..color = InkSignal.crimson.withValues(alpha: alpha),
      );
    }

    final slashPaint = Paint()
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.square
      ..color = InkSignal.paper.withValues(alpha: 0.55);
    for (final side in const [-1.0, 1.0]) {
      final x = center.dx + side * size.width * 0.34;
      canvas.drawLine(
        Offset(x, center.dy - size.height * 0.34),
        Offset(x + side * 18, center.dy - size.height * 0.45),
        slashPaint,
      );
    }

    final tickPaint = Paint()
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.square
      ..color = InkSignal.crimson.withValues(alpha: 0.45);
    for (var i = 0; i < 18; i++) {
      if (i.isOdd) continue;
      final angle = -math.pi / 2 + i * (math.pi * 2 / 18);
      final outer = maxRadius * 0.98;
      final inner = maxRadius * 0.88;
      canvas.drawLine(
        center + Offset(math.cos(angle), math.sin(angle)) * inner,
        center + Offset(math.cos(angle), math.sin(angle)) * outer,
        tickPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _AlarmShockPainter oldDelegate) =>
      oldDelegate.beat != beat;
}

class _AlarmTicksPainter extends CustomPainter {
  const _AlarmTicksPainter({required this.beat});

  final double beat;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide * 0.38;
    final paint = Paint()
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.square
      ..color = InkSignal.paper.withValues(alpha: 0.22);

    for (var i = 0; i < 12; i++) {
      final angle = -math.pi / 2 + i * (math.pi * 2 / 12);
      final length = i % 3 == 0 ? 11.0 : 6.0;
      final p1 = center + Offset(math.cos(angle), math.sin(angle)) * radius;
      final p2 =
          center + Offset(math.cos(angle), math.sin(angle)) * (radius - length);
      canvas.drawLine(p1, p2, paint);
    }

    final handPaint = Paint()
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.square
      ..color = InkSignal.crimson.withValues(alpha: 0.92);
    final shake = (beat - 0.5) * 0.13;
    canvas.drawLine(
      center,
      center +
          Offset(
                math.cos(-math.pi / 2 + shake),
                math.sin(-math.pi / 2 + shake),
              ) *
              radius *
              0.58,
      handPaint,
    );
    canvas.drawLine(
      center,
      center +
          Offset(math.cos(-0.08 - shake), math.sin(-0.08 - shake)) *
              radius *
              0.44,
      handPaint..strokeWidth = 3,
    );
  }

  @override
  bool shouldRepaint(covariant _AlarmTicksPainter oldDelegate) =>
      oldDelegate.beat != beat;
}
