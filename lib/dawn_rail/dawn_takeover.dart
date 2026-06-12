import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../alarm/wake_missions.dart';
import '../state/app_state.dart';
import '../theme/ink_signal.dart';
import '../widgets/cuts.dart';
import '../widgets/screentone.dart';
import 'wake_quest.dart';

/// Dawn Rail step 1 — the alarm-ringing takeover.
/// Full-bleed OLED black, zero nav chrome, no back. The screen must read in
/// 5 seconds to a half-asleep user: the time is huge and BLARING (shockwaves,
/// edge flash, shaking bell), and the one crimson command — TURN OFF ALARM —
/// carries its own mechanic ("enter Wake Quest") so nothing else has to
/// explain it. A visible dim FILLER row keeps the no-trap rule.
class DawnTakeover extends StatefulWidget {
  const DawnTakeover({super.key});

  @override
  State<DawnTakeover> createState() => _DawnTakeoverState();
}

class _DawnTakeoverState extends State<DawnTakeover>
    with TickerProviderStateMixin {
  // Heartbeat: drives glows, edge flash, waveform. Reverses like breathing.
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  // Siren: one-way loop driving the outward shockwave rings and bell shake,
  // so the alarm always radiates outward instead of breathing in.
  late final AnimationController _siren = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat();

  // Keeps the hero clock on the current minute while the alarm blares.
  Timer? _clockTick;

  @override
  void initState() {
    super.initState();
    _clockTick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _clockTick?.cancel();
    _pulse.dispose();
    _siren.dispose();
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
    // Random Quest resolves to today's concrete mission before anything
    // renders — the ringing screen never says "Random", it names the quest.
    final quest = state.resolvedQuest;
    final mission = WakeMission.byName(quest);
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            _AlarmBackplate(pulse: _pulse),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
                child: Column(
                  children: [
                    _AlarmHeader(episode: state.nextEpisode, pulse: _pulse),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _BlaringClock(
                            nowLabel: formatTimeOfDay(
                              TimeOfDay.fromDateTime(state.clock()),
                            ),
                            alarmLabel: state.alarmLabel,
                            quest: quest,
                            pulse: _pulse,
                            siren: _siren,
                          ),
                          const SizedBox(height: 6),
                          StrokedSubtitle(
                            '"${state.userName}. Up. '
                            '$quest turns this off."',
                            size: 19,
                          ),
                          const SizedBox(height: 16),
                          _QuestStrip(
                            quest: quest,
                            proof: mission.proof,
                            randomDraw: state.questIsRandom,
                          ),
                        ],
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // The one hard crimson command: the alarm can only be
                        // silenced by entering the Wake Quest, and the slab
                        // itself says so.
                        _SirenSlab(
                          key: const Key('beginQuest'),
                          quest: quest,
                          pulse: _pulse,
                          onTap: _beginQuest,
                        ),
                        const SizedBox(height: 12),
                        _AlarmWaveform(pulse: _pulse),
                        const SizedBox(height: 6),
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

/// Dark crimson dawn gradient + speed lines + screentone, with a pulsing
/// crimson frame around the screen edge so the whole device reads as blaring.
class _AlarmBackplate extends StatelessWidget {
  const _AlarmBackplate({required this.pulse});

  final Animation<double> pulse;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, -0.64),
              radius: 1.08,
              colors: [Color(0xFF3B0714), Color(0xFF160811), Colors.black],
              stops: [0, 0.45, 1],
            ),
          ),
        ),
        const CustomPaint(
          painter: SpeedLinesPainter(color: InkSignal.crimson, opacity: 0.09),
        ),
        const CustomPaint(painter: ScreentonePainter(opacity: 0.04)),
        IgnorePointer(
          child: AnimatedBuilder(
            animation: pulse,
            builder: (context, _) {
              final beat = Curves.easeInOut.transform(pulse.value);
              return DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: InkSignal.crimson.withValues(
                      alpha: 0.10 + beat * 0.30,
                    ),
                    width: 4,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _AlarmHeader extends StatelessWidget {
  const _AlarmHeader({required this.episode, required this.pulse});

  final int episode;
  final Animation<double> pulse;

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
                'COLD OPEN',
                style: InkSignal.mono(
                  12,
                  color: InkSignal.paper.withValues(alpha: 0.55),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'EP $episode',
                style: InkSignal.ui(20, weight: FontWeight.w900),
              ),
            ],
          ),
        ),
        AnimatedBuilder(
          animation: pulse,
          builder: (context, _) {
            final beat = Curves.easeInOut.transform(pulse.value);
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: InkSignal.crimson.withValues(alpha: 0.10 + beat * 0.12),
                border: Border.all(
                  color: InkSignal.crimson.withValues(alpha: 0.82),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(InkSignal.panelRadius),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: InkSignal.crimson.withValues(
                        alpha: 0.35 + beat * 0.65,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'RINGING',
                    style: InkSignal.mono(11, color: InkSignal.crimson),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

/// The hero: a shaking bell over the giant CURRENT time, with continuous
/// outward shockwave rings. The alarm time reads as secondary metadata so a
/// half-asleep user never mistakes the set time for the actual time.
class _BlaringClock extends StatelessWidget {
  const _BlaringClock({
    required this.nowLabel,
    required this.alarmLabel,
    required this.quest,
    required this.pulse,
    required this.siren,
  });

  final String nowLabel;
  final String alarmLabel;
  final String quest;
  final Animation<double> pulse;
  final Animation<double> siren;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([pulse, siren]),
      builder: (context, _) {
        final beat = Curves.easeInOut.transform(pulse.value);
        return SizedBox(
          width: double.infinity,
          height: 252,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: CustomPaint(painter: _ShockwavePainter(t: siren.value)),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Transform.rotate(
                    // Hard bell shake — clearly ringing, not breathing.
                    angle: math.sin(siren.value * math.pi * 6) * 0.16,
                    child: Icon(
                      Icons.alarm,
                      size: 46,
                      color: InkSignal.paper.withValues(alpha: 0.92),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Transform.scale(
                    scale: 1 + beat * 0.025,
                    child: Transform(
                      transform: Matrix4.skewX(-6 * math.pi / 180),
                      alignment: Alignment.center,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            nowLabel.toUpperCase(),
                            maxLines: 1,
                            style: InkSignal.display(104).copyWith(
                              shadows: [
                                Shadow(
                                  color: InkSignal.crimson.withValues(
                                    alpha: 0.45 + beat * 0.35,
                                  ),
                                  blurRadius: 28 + beat * 26,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'ALARM - ${alarmLabel.toUpperCase()}',
                    style: InkSignal.mono(
                      11,
                      color: InkSignal.paper.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'QUEST: ${quest.toUpperCase()} - TURNS THIS OFF',
                    style: InkSignal.mono(
                      11,
                      color: InkSignal.paper.withValues(alpha: 0.72),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Three shockwave rings expanding outward from the time, forever.
class _ShockwavePainter extends CustomPainter {
  const _ShockwavePainter({required this.t});

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.shortestSide * 0.72;
    for (var i = 0; i < 3; i++) {
      final tt = (t + i / 3) % 1.0;
      final radius = 84 + (maxRadius - 84) * Curves.easeOut.transform(tt);
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.5 - tt * 2
          ..color = InkSignal.crimson.withValues(alpha: (1 - tt) * 0.4),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ShockwavePainter oldDelegate) =>
      oldDelegate.t != t;
}

/// One compact line of quest facts — replaces the old narrator panel.
class _QuestStrip extends StatelessWidget {
  const _QuestStrip({
    required this.quest,
    required this.proof,
    this.randomDraw = false,
  });

  final String quest;
  final String proof;

  /// True when this mission came from the Random Quest nightly draw.
  final bool randomDraw;

  @override
  Widget build(BuildContext context) {
    Widget fact(String label, String value) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.34),
        border: Border.all(
          color: InkSignal.paper.withValues(alpha: 0.16),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(InkSignal.panelRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: InkSignal.mono(
              10,
              color: InkSignal.paper.withValues(alpha: 0.42),
            ),
          ),
          const SizedBox(width: 7),
          Text(
            value.toUpperCase(),
            style: InkSignal.ui(14, weight: FontWeight.w800),
          ),
        ],
      ),
    );

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        fact('QUEST', quest),
        fact('PROOF', proof),
        if (randomDraw) fact('DRAWN', 'Tonight'),
      ],
    );
  }
}

/// The single crimson action: a tall glowing slab that carries the mechanic
/// in its own sublabel, so a half-asleep user needs no other copy.
class _SirenSlab extends StatelessWidget {
  const _SirenSlab({
    super.key,
    required this.quest,
    required this.pulse,
    required this.onTap,
  });

  final String quest;
  final Animation<double> pulse;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedBuilder(
        animation: pulse,
        builder: (context, _) {
          final beat = Curves.easeInOut.transform(pulse.value);
          return Container(
            height: 96,
            width: double.infinity,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: InkSignal.crimson,
              borderRadius: BorderRadius.circular(InkSignal.panelRadius),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2 + beat * 0.4),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: InkSignal.crimson.withValues(alpha: 0.3 + beat * 0.3),
                  blurRadius: 24 + beat * 20,
                  spreadRadius: 1 + beat * 3,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'TURN OFF ALARM',
                  style: InkSignal.ui(
                    22,
                    color: Colors.white,
                    weight: FontWeight.w900,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ENTER WAKE QUEST · ${quest.toUpperCase()}',
                  style: InkSignal.mono(
                    11,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          );
        },
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
          height: 30,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(23, (index) {
              final phase = math.sin(index * 0.9 + beat * math.pi * 2);
              final height = 8 + phase.abs() * 18;
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
