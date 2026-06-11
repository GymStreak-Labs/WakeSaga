import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../state/app_state.dart';
import '../theme/ink_signal.dart';
import '../widgets/cuts.dart';
import '../widgets/screentone.dart';
import 'title_card_slam.dart';

/// Dawn Rail step 3 — the earned unlock beat.
/// Wake Quest has silenced the alarm; this screen makes the reward explicit
/// before the title card slams and the Morning Episode auto-plays.
class EpisodeUnlock extends StatefulWidget {
  const EpisodeUnlock({super.key});

  @override
  State<EpisodeUnlock> createState() => _EpisodeUnlockState();
}

class _EpisodeUnlockState extends State<EpisodeUnlock>
    with SingleTickerProviderStateMixin {
  Timer? _hold;
  late final AnimationController _burst = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 860),
  )..forward();

  @override
  void initState() {
    super.initState();
    HapticFeedback.heavyImpact();
    _hold = Timer(const Duration(milliseconds: 1850), _advance);
  }

  void _advance() {
    if (!mounted) return;
    Navigator.of(
      context,
    ).push(hardCut(const SmashCutFlash(child: TitleCardSlam())));
  }

  @override
  void dispose() {
    _hold?.cancel();
    _burst.dispose();
    super.dispose();
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
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -0.42),
                  radius: 1.15,
                  colors: [Color(0xFF2E0D18), Colors.black],
                ),
              ),
            ),
            const CustomPaint(painter: SpeedLinesPainter(opacity: 0.18)),
            const CustomPaint(painter: ScreentonePainter(opacity: 0.045)),
            AnimatedBuilder(
              animation: _burst,
              builder: (context, _) {
                final value = Curves.easeOutBack.transform(
                  _burst.value.clamp(0.0, 1.0),
                );
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    Center(
                      child: Transform.rotate(
                        angle: (-9 + (5 * value)) * math.pi / 180,
                        child: Transform.scale(
                          scale: 0.78 + (0.22 * value),
                          child: Container(
                            width: 280,
                            height: 280,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: InkSignal.crimson,
                                width: 5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: InkSignal.crimson.withValues(
                                    alpha: 0.42,
                                  ),
                                  blurRadius: 54,
                                  spreadRadius: 8,
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'ALARM',
                                  style: InkSignal.mono(
                                    13,
                                    color: InkSignal.paper.withValues(
                                      alpha: 0.62,
                                    ),
                                  ),
                                ),
                                SkewedDisplay(
                                  'OFF',
                                  size: 86,
                                  color: InkSignal.verifyGreen,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 24,
                      right: 24,
                      top: MediaQuery.paddingOf(context).top + 42,
                      child: Opacity(
                        opacity: _burst.value.clamp(0.0, 1.0),
                        child: Text(
                          'QUEST CLEARED · ${state.quest.toUpperCase()}',
                          textAlign: TextAlign.center,
                          style: InkSignal.mono(
                            12,
                            color: InkSignal.paper.withValues(alpha: 0.55),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 24,
                      right: 24,
                      bottom: MediaQuery.paddingOf(context).bottom + 48,
                      child: Transform.translate(
                        offset: Offset(0, 28 * (1 - _burst.value)),
                        child: Opacity(
                          opacity: _burst.value.clamp(0.0, 1.0),
                          child: Column(
                            children: [
                              const SkewedDisplay('MORNING EPISODE', size: 36),
                              const SkewedDisplay(
                                'UNLOCKED',
                                size: 52,
                                color: InkSignal.crimson,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'TITLE CARD INCOMING',
                                style: InkSignal.mono(
                                  12,
                                  color: InkSignal.paper.withValues(
                                    alpha: 0.54,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
