import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../state/app_state.dart';
import '../theme/ink_signal.dart';
import '../widgets/cuts.dart';
import '../widgets/screentone.dart';
import 'episode_unlock.dart';

/// Dawn Rail step 2 — Wake Quest verification.
/// One 64pt instruction (max 5 words), the sensor IS the screen.
/// All sensors are SIMULATED in this prototype:
/// - Get Up: giant tap counter (stands in for motion/steps).
/// - Sky Photo: fake viewfinder + shutter (stands in for camera+liveness).
/// - Shake: counter ring, taps stand in for accelerometer shakes.
/// Failure ladder: 2 fails -> fallback card slides up ("20 SHAKES INSTEAD"),
/// 3rd fail -> alarm ends, Filler logged. No dialogs, no dead ends.
class WakeQuest extends StatefulWidget {
  const WakeQuest({super.key});

  @override
  State<WakeQuest> createState() => _WakeQuestState();
}

class _WakeQuestState extends State<WakeQuest>
    with SingleTickerProviderStateMixin {
  static const int target = int.fromEnvironment(
    'WAKE_SAGA_QUEST_TARGET',
    defaultValue: 20,
  );

  // Heartbeat for the still-ringing banner; stops the moment verify lands.
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  late String _mode; // First-run Wake Quest label.
  int _count = 0;
  int _fails = 0;
  bool _verified = false;
  Timer? _advanceTimer;

  bool _modeInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_modeInitialized) {
      _mode = AppScope.of(context).quest;
      _modeInitialized = true;
    }
  }

  @override
  void dispose() {
    _advanceTimer?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  String get _instruction => switch (_mode) {
    'Sky Photo' => 'SKY PHOTO TO SILENCE',
    'Shake' => 'SHAKE TO SILENCE',
    'Object Hunt' => 'FIND OBJECT TO SILENCE',
    'Water Check' => 'WATER CHECK TO SILENCE',
    'Desk Ready' => 'DESK PROOF TO SILENCE',
    _ => 'GET UP TO SILENCE',
  };

  String get _simHint => switch (_mode) {
    'Shake' => 'tap = one shake (simulated)',
    'Object Hunt' => 'tap = object found (simulated)',
    'Water Check' => 'tap = water check (simulated)',
    'Desk Ready' => 'tap = desk proof (simulated)',
    _ => 'tap = one step (simulated)',
  };

  void _increment() {
    if (_verified) return;
    HapticFeedback.selectionClick();
    setState(() => _count++);
    if (_count >= target) _succeed();
  }

  void _succeed() {
    if (_verified) return;
    HapticFeedback.heavyImpact();
    _pulse.stop();
    setState(() => _verified = true);
    // Brief verify-green beat, then the earned unlock screen makes the reward
    // explicit before the title card and episode playback.
    _advanceTimer = Timer(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      Navigator.of(
        context,
      ).push(hardCut(const SmashCutFlash(child: EpisodeUnlock())));
    });
  }

  void _simulateFail() {
    if (_verified) return;
    HapticFeedback.mediumImpact();
    setState(() => _fails++);
    if (_fails >= 3) {
      // 3rd fail: the alarm ends. Filler logged. Never trap.
      final state = AppScope.of(context);
      state.logFiller();
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  void _takeFallback() {
    HapticFeedback.selectionClick();
    setState(() {
      _mode = 'Shake';
      _count = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final showFallback = _fails >= 2 && _mode != 'Shake' && !_verified;
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  const SizedBox(height: 8),
                  // The alarm never leaves the screen: a live siren strip that
                  // snaps green the moment the quest verifies.
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _AlarmStatusBanner(
                      verified: _verified,
                      pulse: _pulse,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: SkewedDisplay(_instruction, size: 64),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _QuestProtocol(
                      verified: _verified,
                      count: _count,
                      target: target,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: _mode == 'Sky Photo'
                        ? _Viewfinder(verified: _verified, onShutter: _succeed)
                        : _CounterRing(
                            count: _count,
                            target: target,
                            verified: _verified,
                            hint: _verified
                                ? 'alarm off · title card next'
                                : _simHint,
                            onTap: _increment,
                          ),
                  ),
                  // Dim debug affordance to demo the failure ladder.
                  GestureDetector(
                    key: const Key('simFail'),
                    behavior: HitTestBehavior.opaque,
                    onTap: _simulateFail,
                    child: Container(
                      height: InkSignal.slabHeight,
                      alignment: Alignment.center,
                      child: Opacity(
                        opacity: _verified ? 0 : 0.3,
                        child: Text(
                          'SIMULATE FAILED VERIFY ($_fails/3)',
                          style: InkSignal.ui(15, weight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
              // Failure-ladder fallback card slides up after 2 fails.
              AnimatedSlide(
                offset: showFallback ? Offset.zero : const Offset(0, 1.2),
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 76),
                    child: GestureDetector(
                      key: const Key('fallbackCard'),
                      onTap: showFallback ? _takeFallback : null,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: InkSignal.panel(
                          color: InkSignal.surface,
                          borderColor: InkSignal.paper,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "CAN'T VERIFY — 20 SHAKES INSTEAD",
                              style: InkSignal.ui(
                                18,
                                weight: FontWeight.w900,
                                letterSpacing: 0.4,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Tap to swap quest. One more fail ends the '
                              'alarm — no traps.',
                              style: InkSignal.ui(
                                15,
                                color: InkSignal.paper.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuestProtocol extends StatelessWidget {
  const _QuestProtocol({
    required this.verified,
    required this.count,
    required this.target,
  });

  final bool verified;
  final int count;
  final int target;

  @override
  Widget build(BuildContext context) {
    final progress = (count / target).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: InkSignal.panel(color: const Color(0xFF0D1017)),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _ProtocolStep(
                  label: 'DO QUEST',
                  active: !verified,
                  complete: verified || count > 0,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _ProtocolStep(
                  label: 'VERIFY',
                  active: !verified && count > 0,
                  complete: verified,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _ProtocolStep(
                  label: 'ALARM OFF',
                  active: verified,
                  complete: verified,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              minHeight: 5,
              value: verified ? 1 : progress,
              backgroundColor: InkSignal.inkBorder,
              valueColor: AlwaysStoppedAnimation(
                verified ? InkSignal.verifyGreen : InkSignal.crimson,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProtocolStep extends StatelessWidget {
  const _ProtocolStep({
    required this.label,
    required this.active,
    required this.complete,
  });

  final String label;
  final bool active;
  final bool complete;

  @override
  Widget build(BuildContext context) {
    final color = complete
        ? InkSignal.verifyGreen
        : active
        ? InkSignal.crimson
        : InkSignal.paper.withValues(alpha: 0.24);
    return Container(
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: complete ? 0.16 : 0.08),
        border: Border.all(color: color.withValues(alpha: 0.82), width: 1.5),
        borderRadius: BorderRadius.circular(InkSignal.panelRadius),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(label, style: InkSignal.mono(10, color: color)),
      ),
    );
  }
}

/// Giant counter inside a filling ink-stroke ring. The crimson fill is the
/// screen's single accent; it turns verify-green at the moment of truth.
class _CounterRing extends StatelessWidget {
  const _CounterRing({
    required this.count,
    required this.target,
    required this.verified,
    required this.hint,
    required this.onTap,
  });

  final int count;
  final int target;
  final bool verified;
  final String hint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: const Key('questSurface'),
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 280,
              height: 280,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Speed-line burst lands only at the moment of truth.
                  AnimatedOpacity(
                    opacity: verified ? 1 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: const CustomPaint(
                      painter: SpeedLinesPainter(
                        color: InkSignal.verifyGreen,
                        opacity: 0.2,
                      ),
                    ),
                  ),
                  CustomPaint(
                    painter: _RingPainter(
                      progress: count / target,
                      color: verified
                          ? InkSignal.verifyGreen
                          : InkSignal.crimson,
                    ),
                    child: Center(
                      // Pop on every tap: re-keyed tween snaps to 1.16x and
                      // settles, so each rep visibly lands.
                      child: TweenAnimationBuilder<double>(
                        key: ValueKey(verified ? -1 : count),
                        tween: Tween(begin: count == 0 ? 1.0 : 1.16, end: 1.0),
                        duration: const Duration(milliseconds: 170),
                        curve: Curves.easeOutCubic,
                        builder: (context, scale, child) =>
                            Transform.scale(scale: scale, child: child),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              verified ? 'OFF' : '$count',
                              style: InkSignal.display(
                                verified ? 110 : 96,
                                color: verified
                                    ? InkSignal.verifyGreen
                                    : InkSignal.paper,
                              ),
                            ),
                            if (!verified) ...[
                              const SizedBox(height: 2),
                              Text(
                                '${target - count} MORE TO SILENCE',
                                style: InkSignal.mono(
                                  12,
                                  color: InkSignal.paper.withValues(
                                    alpha: 0.55,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              hint,
              style: InkSignal.ui(
                15,
                color: InkSignal.paper.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..color = InkSignal.inkBorder;
    canvas.drawCircle(center, radius, track);

    // Milestone ticks every quarter turn so progress reads at a glance.
    final tick = Paint()
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.square
      ..color = InkSignal.paper.withValues(alpha: 0.3);
    for (var i = 0; i < 4; i++) {
      final angle = -math.pi / 2 + i * math.pi / 2;
      final dir = Offset(math.cos(angle), math.sin(angle));
      canvas.drawLine(
        center + dir * (radius - 12),
        center + dir * (radius + 12),
        tick,
      );
    }

    final fill = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..color = color;
    final sweep = 2 * math.pi * progress.clamp(0.0, 1.0);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweep,
      false,
      fill,
    );
    // Glowing tip marks the live edge of progress.
    if (progress > 0 && progress < 1) {
      final tipAngle = -math.pi / 2 + sweep;
      final tip =
          center + Offset(math.cos(tipAngle), math.sin(tipAngle)) * radius;
      canvas.drawCircle(
        tip,
        9,
        Paint()
          ..color = color.withValues(alpha: 0.45)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
      canvas.drawCircle(tip, 6, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

/// Persistent alarm state strip. While ringing it pulses crimson with a live
/// mini waveform; on verify it snaps to a calm green "ALARM SILENCED".
class _AlarmStatusBanner extends StatelessWidget {
  const _AlarmStatusBanner({required this.verified, required this.pulse});

  final bool verified;
  final Animation<double> pulse;

  @override
  Widget build(BuildContext context) {
    if (verified) {
      return Container(
        height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: InkSignal.verifyGreen.withValues(alpha: 0.14),
          border: Border.all(
            color: InkSignal.verifyGreen.withValues(alpha: 0.85),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(InkSignal.panelRadius),
        ),
        child: Text(
          'ALARM SILENCED · EPISODE INCOMING',
          style: InkSignal.mono(12, color: InkSignal.verifyGreen),
        ),
      );
    }
    return AnimatedBuilder(
      animation: pulse,
      builder: (context, _) {
        final beat = Curves.easeInOut.transform(pulse.value);
        return Container(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: InkSignal.crimson.withValues(alpha: 0.08 + beat * 0.08),
            border: Border.all(
              color: InkSignal.crimson.withValues(alpha: 0.5 + beat * 0.4),
              width: 2,
            ),
            borderRadius: BorderRadius.circular(InkSignal.panelRadius),
          ),
          child: Row(
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(7, (index) {
                  final phase = math.sin(index * 1.1 + beat * math.pi * 2);
                  return Container(
                    width: 2.5,
                    height: 6 + phase.abs() * 12,
                    margin: const EdgeInsets.symmetric(horizontal: 1.6),
                    decoration: BoxDecoration(
                      color: InkSignal.crimson.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  );
                }),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'ALARM RINGING',
                  style: InkSignal.mono(12, color: InkSignal.crimson),
                ),
              ),
              Text(
                'QUEST SILENCES IT',
                style: InkSignal.mono(
                  10,
                  color: InkSignal.paper.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Simulated camera surface for Sky Photo: halftone-framed viewfinder with
/// a shutter occupying the bottom quarter.
class _Viewfinder extends StatelessWidget {
  const _Viewfinder({required this.verified, required this.onShutter});

  final bool verified;
  final VoidCallback onShutter;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: InkSignal.panel(
                color: const Color(0xFF10141D),
                borderColor: verified
                    ? InkSignal.verifyGreen
                    : InkSignal.inkBorder,
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const CustomPaint(painter: ScreentonePainter(opacity: 0.06)),
                  Center(
                    child: Text(
                      verified
                          ? 'SKY VERIFIED'
                          : 'POINT AT THE SKY\n(simulated viewfinder)',
                      textAlign: TextAlign.center,
                      style: InkSignal.ui(
                        17,
                        color: verified
                            ? InkSignal.verifyGreen
                            : InkSignal.paper.withValues(alpha: 0.4),
                        weight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Shutter: the single accent on this screen.
          SizedBox(
            height: 132,
            child: Center(
              child: GestureDetector(
                key: const Key('shutter'),
                onTap: onShutter,
                child: Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: verified ? InkSignal.verifyGreen : InkSignal.crimson,
                    border: Border.all(color: InkSignal.paper, width: 3),
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
