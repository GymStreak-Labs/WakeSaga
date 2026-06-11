import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../state/app_state.dart';
import '../theme/ink_signal.dart';
import '../widgets/cuts.dart';
import '../widgets/screentone.dart';
import 'title_card_slam.dart';

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

class _WakeQuestState extends State<WakeQuest> {
  static const int target = int.fromEnvironment(
    'WAKE_SAGA_QUEST_TARGET',
    defaultValue: 20,
  );

  late String _mode; // 'Get Up' | 'Sky Photo' | 'Shake'.
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
    super.dispose();
  }

  String get _instruction => switch (_mode) {
    'Sky Photo' => 'PHOTOGRAPH THE SKY',
    'Shake' => '20 SHAKES. GO.',
    _ => 'STAND UP. TAP 20.',
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
    setState(() => _verified = true);
    // Brief verify-green beat, then the smash cut IS the confirmation.
    _advanceTimer = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      Navigator.of(
        context,
      ).push(hardCut(const SmashCutFlash(child: TitleCardSlam())));
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
                  const SizedBox(height: 28),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: SkewedDisplay(_instruction, size: 64),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _mode == 'Sky Photo'
                        ? _Viewfinder(verified: _verified, onShutter: _succeed)
                        : _CounterRing(
                            count: _count,
                            target: target,
                            verified: _verified,
                            hint: _mode == 'Shake'
                                ? 'tap = one shake (simulated)'
                                : 'tap = one step (simulated)',
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
                        opacity: 0.3,
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
              child: CustomPaint(
                painter: _RingPainter(
                  progress: count / target,
                  color: verified ? InkSignal.verifyGreen : InkSignal.crimson,
                ),
                child: Center(
                  child: Text(
                    verified ? 'GO' : '$count/$target',
                    style: InkSignal.display(
                      verified ? 110 : 84,
                      color: verified ? InkSignal.verifyGreen : InkSignal.paper,
                    ),
                  ),
                ),
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
    final fill = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.butt
      ..color = color;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress.clamp(0.0, 1.0),
      false,
      fill,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
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
