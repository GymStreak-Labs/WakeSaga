import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../alarm/wake_missions.dart';
import '../state/app_state.dart';
import '../theme/ink_signal.dart';
import '../widgets/screentone.dart';

/// Dawn Rail step 5 — the Wake Card mint.
/// Centered card at 70% height: screentone manga-panel placeholder
/// (real quest photo + filter pipeline comes later), EP stamp, huge wake
/// time, mono receipt footer. Gold SHARE + dim Done. The gold foil shimmer
/// appears ONLY when a truth condition is met (woke before the alarm).
class CardMint extends StatefulWidget {
  const CardMint({super.key});

  @override
  State<CardMint> createState() => _CardMintState();
}

class _CardMintState extends State<CardMint>
    with SingleTickerProviderStateMixin {
  String _wakeLabel = '';
  String? _foil;
  bool _minted = false;
  bool _shared = false;
  int _episode = 0;
  late final AnimationController _shimmer = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  );

  @override
  void initState() {
    super.initState();
    HapticFeedback.mediumImpact(); // The "mint" snap.
    // Mint after the first frame so notifyListeners never fires mid-build.
    WidgetsBinding.instance.addPostFrameCallback((_) => _mint());
  }

  void _mint() {
    if (_minted || !mounted) return;
    final state = AppScope.of(context, listen: false);
    final now = state.clock();
    final wake = TimeOfDay.fromDateTime(now);
    final nowMinutes = wake.hour * 60 + wake.minute;
    final alarmMinutes = state.alarmTime.hour * 60 + state.alarmTime.minute;
    // Truth-based foil: beat your own alarm.
    final foil = nowMinutes < alarmMinutes ? 'FIRST LIGHT' : null;
    setState(() {
      _wakeLabel = formatTimeOfDay(wake);
      _foil = foil;
      _episode = state.nextEpisode;
      _minted = true;
    });
    state.mintEpisode(wakeTime: _wakeLabel, foil: foil);
    if (foil != null) _shimmer.repeat();
  }

  void _done() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _share() {
    HapticFeedback.mediumImpact();
    setState(() => _shared = true);
  }

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final quest = state.resolvedQuest;
    final mission = WakeMission.byName(quest);
    final height = MediaQuery.sizeOf(context).height;
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: InkSignal.base,
        body: SafeArea(
          child: Column(
            children: [
              const Spacer(),
              Center(
                child: SizedBox(
                  height: height * 0.62,
                  child: AspectRatio(
                    aspectRatio: 0.62,
                    child: _WakeCard(
                      episode: _episode == 0 ? state.nextEpisode : _episode,
                      title: deriveEpisodeTitle(
                        state.missionText,
                        _episode == 0 ? state.nextEpisode : _episode,
                      ),
                      mission: state.missionText,
                      wakeLabel: _wakeLabel,
                      foil: _foil,
                      arcNumber: state.arcNumber,
                      arcDay: state.arcDay,
                      quest: quest,
                      proof: mission.proof,
                      shimmer: _shimmer,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    // Gold: rationed to rarity/share. This is the share.
                    SlabButton(
                      'SHARE',
                      key: const Key('shareCard'),
                      color: InkSignal.gold,
                      textColor: Colors.black,
                      onTap: _share,
                    ),
                    SizedBox(
                      height: 28,
                      child: _shared
                          ? Center(
                              child: Text(
                                '9:16 EXPORT SAVED (SIMULATED)',
                                style: InkSignal.mono(
                                  12,
                                  color: InkSignal.paper.withValues(alpha: 0.5),
                                ),
                              ),
                            )
                          : null,
                    ),
                    GestureDetector(
                      key: const Key('mintDone'),
                      behavior: HitTestBehavior.opaque,
                      onTap: _done,
                      child: Container(
                        height: InkSignal.slabHeight,
                        alignment: Alignment.center,
                        child: Opacity(
                          opacity: 0.45,
                          child: Text(
                            'Done',
                            style: InkSignal.ui(18, weight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _WakeCard extends StatelessWidget {
  const _WakeCard({
    required this.episode,
    required this.title,
    required this.mission,
    required this.wakeLabel,
    required this.foil,
    required this.arcNumber,
    required this.arcDay,
    required this.quest,
    required this.proof,
    required this.shimmer,
  });

  final int episode;
  final String title;
  final String mission;
  final String wakeLabel;
  final String? foil;
  final int arcNumber;
  final int arcDay;
  final String quest;
  final String proof;
  final AnimationController shimmer;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: InkSignal.panel(
        color: const Color(0xFF1B2230),
        borderColor: foil != null ? InkSignal.gold : InkSignal.paper,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Manga screentone panel placeholder — the screentone-filtered
          // quest photo pipeline replaces this later.
          const CustomPaint(painter: ScreentonePainter(opacity: 0.09)),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // EP stamp like a chapter mark.
                Transform.rotate(
                  angle: -4 * math.pi / 180,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: InkSignal.paper, width: 2),
                      borderRadius: BorderRadius.circular(
                        InkSignal.panelRadius,
                      ),
                    ),
                    child: Text('EP $episode', style: InkSignal.display(22)),
                  ),
                ),
                const SizedBox(height: 28),
                SkewedDisplay(title, size: 30, textAlign: TextAlign.left),
                const SizedBox(height: 10),
                Text(
                  mission.isEmpty ? 'No mission logged.' : mission,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: InkSignal.ui(
                    16,
                    color: InkSignal.paper.withValues(alpha: 0.7),
                    weight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                if (foil != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      '✦ $foil FOIL',
                      style: InkSignal.ui(
                        15,
                        color: InkSignal.gold,
                        weight: FontWeight.w900,
                        letterSpacing: 1.4,
                      ),
                    ),
                  ),
                // Huge wake time — the proof.
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: SkewedDisplay(
                    wakeLabel.isEmpty ? '--:--' : wakeLabel,
                    size: 64,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  height: 2,
                  color: InkSignal.paper.withValues(alpha: 0.25),
                ),
                const SizedBox(height: 10),
                // Receipt-style mono footer.
                Text(
                  'WX CLEAR · ARC $arcNumber · DAY $arcDay\n'
                  'QUEST ${quest.toUpperCase()} · ${proof.toUpperCase()}',
                  style: InkSignal.mono(
                    12,
                    color: InkSignal.paper.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          // Gold foil sweep — ONLY when the truth condition is met.
          if (foil != null)
            IgnorePointer(
              child: AnimatedBuilder(
                animation: shimmer,
                builder: (context, _) {
                  final t = shimmer.value * 2 - 1;
                  return DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment(t - 0.6, -1),
                        end: Alignment(t + 0.6, 1),
                        colors: [
                          Colors.transparent,
                          InkSignal.gold.withValues(alpha: 0.18),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
