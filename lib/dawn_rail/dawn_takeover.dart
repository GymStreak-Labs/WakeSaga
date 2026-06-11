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
    final height = MediaQuery.sizeOf(context).height;
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Column(
          children: [
            const SizedBox(height: 84),
            ScaleTransition(
              scale: Tween(begin: 1.0, end: 1.04).animate(
                CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
              ),
              child: SkewedDisplay('EP. ${state.nextEpisode}', size: 112),
            ),
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: StrokedSubtitle(
                '${state.userName}. Day ${state.nextEpisode}. '
                'The city is still asleep. You are not.',
                size: 19,
              ),
            ),
            const SizedBox(height: 22),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: InkSignal.panel(color: const Color(0xFF10141D)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MISSION',
                      style: InkSignal.mono(
                        11,
                        color: InkSignal.paper.withValues(alpha: 0.45),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      state.missionText.isEmpty
                          ? 'Stand up before the scene ends.'
                          : state.missionText,
                      style: InkSignal.ui(18, weight: FontWeight.w900),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'WAKE QUEST · ${state.quest.toUpperCase()}',
                      style: InkSignal.mono(
                        12,
                        color: InkSignal.paper.withValues(alpha: 0.62),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            // Bottom 45%: thumb-reachable from a pillow.
            SizedBox(
              height: height * 0.45,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // The one crimson element on this screen.
                    SlabButton(
                      'CLEAR ${state.quest}',
                      key: const Key('beginQuest'),
                      onTap: _beginQuest,
                      height: 88,
                    ),
                    const SizedBox(height: 12),
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
                          // secondary to BEGIN QUEST.
                          opacity: 0.6,
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
            ),
          ],
        ),
      ),
    );
  }
}
