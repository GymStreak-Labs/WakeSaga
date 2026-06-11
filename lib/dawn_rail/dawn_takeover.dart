import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../state/app_state.dart';
import '../theme/ink_signal.dart';
import '../widgets/cuts.dart';
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
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 20),
              Text(
                'ALARM RINGING',
                style: InkSignal.mono(
                  12,
                  color: InkSignal.paper.withValues(alpha: 0.56),
                ),
              ),
              const SizedBox(height: 14),
              ScaleTransition(
                scale: Tween(begin: 1.0, end: 1.035).animate(
                  CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
                ),
                child: _RingingAlarmFace(
                  alarmLabel: state.alarmLabel,
                  episode: state.nextEpisode,
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: StrokedSubtitle(
                  'To turn it off: clear ${state.quest}.',
                  size: 19,
                ),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: InkSignal.panel(color: const Color(0xFF10141D)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'WAKE QUEST REQUIRED',
                        style: InkSignal.mono(
                          11,
                          color: InkSignal.paper.withValues(alpha: 0.48),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        state.quest,
                        style: InkSignal.ui(24, weight: FontWeight.w900),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${state.proof} · ${state.questPlace}',
                        style: InkSignal.ui(
                          15,
                          color: InkSignal.paper.withValues(alpha: 0.62),
                          weight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Alarm off -> Title Card reveal -> Episode auto-plays',
                        style: InkSignal.mono(
                          11,
                          color: InkSignal.paper.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // The one crimson element on this screen.
                    SlabButton(
                      'TURN OFF ALARM',
                      key: const Key('beginQuest'),
                      onTap: _beginQuest,
                      height: 88,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Requires Wake Quest',
                      style: InkSignal.mono(
                        12,
                        color: InkSignal.paper.withValues(alpha: 0.5),
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
                          // Legible to a half-asleep brain; still clearly
                          // secondary to turning the alarm off properly.
                          opacity: 0.52,
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
    );
  }
}

class _RingingAlarmFace extends StatelessWidget {
  const _RingingAlarmFace({required this.alarmLabel, required this.episode});

  final String alarmLabel;
  final int episode;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 246,
      height: 246,
      child: CustomPaint(
        painter: _AlarmRingsPainter(),
        child: Center(
          child: Container(
            width: 184,
            height: 184,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black,
              border: Border.all(
                color: InkSignal.paper.withValues(alpha: 0.9),
                width: 3,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'EP $episode',
                  style: InkSignal.mono(
                    12,
                    color: InkSignal.paper.withValues(alpha: 0.48),
                  ),
                ),
                const SizedBox(height: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: SkewedDisplay(alarmLabel, size: 42),
                ),
                const SizedBox(height: 8),
                Text(
                  'WAKE QUEST LOCK',
                  style: InkSignal.mono(
                    10,
                    color: InkSignal.paper.withValues(alpha: 0.42),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AlarmRingsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    for (final (radius, alpha, stroke) in const [
      (112.0, 0.10, 2.0),
      (96.0, 0.16, 2.5),
      (80.0, 0.22, 3.0),
    ]) {
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..color = InkSignal.paper.withValues(alpha: alpha),
      );
    }

    for (final dx in const [-74.0, 74.0]) {
      canvas.drawLine(
        center.translate(dx, -82),
        center.translate(dx + (dx.isNegative ? -18 : 18), -104),
        Paint()
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.square
          ..color = InkSignal.paper.withValues(alpha: 0.62),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _AlarmRingsPainter oldDelegate) => false;
}
