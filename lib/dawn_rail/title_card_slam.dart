import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../state/app_state.dart';
import '../theme/ink_signal.dart';
import '../widgets/cuts.dart';
import '../widgets/screentone.dart';
import 'episode_player.dart';

/// Dawn Rail step 3 — THE TITLE CARD SLAM.
/// Hard cut, 12-degree tilted episode title derived from last night's
/// mission, radial speed-line burst over a sunrise-palette wash.
/// Holds 2.5s, then auto-advances. Typography is the hero: near full-bleed.
class TitleCardSlam extends StatefulWidget {
  const TitleCardSlam({super.key});

  @override
  State<TitleCardSlam> createState() => _TitleCardSlamState();
}

class _TitleCardSlamState extends State<TitleCardSlam>
    with SingleTickerProviderStateMixin {
  Timer? _hold;
  late final AnimationController _slam = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 240),
  )..forward();

  @override
  void initState() {
    super.initState();
    HapticFeedback.heavyImpact();
    _hold = Timer(const Duration(milliseconds: 2500), _advance);
  }

  void _advance() {
    if (!mounted) return;
    Navigator.of(context).push(
      hardCut(const SmashCutFlash(child: EpisodePlayer())),
    );
  }

  @override
  void dispose() {
    _hold?.cancel();
    _slam.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final title = deriveEpisodeTitle(state.missionText, state.nextEpisode);
    final words = title.split(' ');
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // Sunrise-palette wash (the only gradient class allowed).
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, 0.85),
                  radius: 1.4,
                  colors: [
                    Color(0xFF7A2B1C),
                    Color(0xFF3B1A2E),
                    Color(0xFF0B0E14),
                  ],
                ),
              ),
            ),
            const CustomPaint(
              painter: SpeedLinesPainter(opacity: 0.16),
            ),
            const CustomPaint(
              painter: ScreentonePainter(opacity: 0.05),
            ),
            Center(
              child: ScaleTransition(
                // Panel scales 1.15 -> 1.0 with overshoot: the SMASH CUT.
                scale: Tween(begin: 1.15, end: 1.0).animate(
                  CurvedAnimation(parent: _slam, curve: Curves.easeOutBack),
                ),
                child: Transform.rotate(
                  angle: -7 * math.pi / 180,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 26),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: SkewedDisplay(
                            'EPISODE ${state.nextEpisode}',
                            size: 72,
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Each word slams at near full-bleed width.
                        for (final word in words)
                          SizedBox(
                            width: double.infinity,
                            child: FittedBox(
                              fit: BoxFit.contain,
                              child: SkewedDisplay(word, size: 82),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
