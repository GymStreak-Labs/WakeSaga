import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../state/app_state.dart';
import '../theme/ink_signal.dart';
import '../widgets/screentone.dart';

/// CAST — narrator roster as full-color fighting-game-select cards.
/// Locked narrators get a small lock, never greyed husks. Tapping any card
/// shows a sample line speaking the user's real name + episode count
/// (audio simulated as text). Protagonist Pass is a SHEET, never a tab.
class CastTab extends StatefulWidget {
  const CastTab({super.key});

  @override
  State<CastTab> createState() => _CastTabState();
}

class _Narrator {
  const _Narrator(this.name, this.role, this.color, {this.locked = true});

  final String name;
  final String role;
  final Color color;
  final bool locked;
}

const _roster = [
  _Narrator(
    'Mentor',
    'The one who believes first',
    Color(0xFF2E4A66),
    locked: false,
  ),
  _Narrator('Rival', 'Five steps ahead, always', Color(0xFF5A2333)),
  _Narrator('Captain', 'No excuses survive the brief', Color(0xFF3C4D2A)),
  _Narrator('Quiet Senior', 'Says little. Means all of it', Color(0xFF4A3A5E)),
  _Narrator('Guest', 'A new voice every month', Color(0xFF6B4A21)),
];

class _CastTabState extends State<CastTab> {
  _Narrator? _sampling;

  String _sampleLine(AppState state, _Narrator narrator) {
    final name = state.userName;
    final ep = state.episodeCount;
    return switch (narrator.name) {
      'Rival' =>
        '"$name. Episode $ep and you still set the alarm that '
            'late? Cute."',
      'Captain' =>
        '"$name! $ep episodes on the board. Report at '
            '${state.alarmLabel} sharp."',
      'Quiet Senior' =>
        '"…$ep mornings, $name. The work is starting to '
            'show."',
      'Guest' =>
        '"$name?! THE $name? Episode $ep of the saga everyone\'s '
            'talking about?"',
      _ =>
        '"$name. $ep episodes in. I told you the person who stands up '
            'is the story."',
    };
  }

  void _tapNarrator(AppState state, _Narrator narrator) {
    HapticFeedback.selectionClick();
    setState(() => _sampling = narrator);
  }

  void _openSettings(AppState state) {
    final nameController = TextEditingController(text: state.userName);
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          20 + MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SETTINGS',
              style: InkSignal.ui(
                15,
                weight: FontWeight.w900,
                letterSpacing: 2,
                color: InkSignal.paper.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              key: const Key('nameField'),
              controller: nameController,
              style: InkSignal.ui(18),
              onSubmitted: state.setUserName,
              decoration: InputDecoration(
                labelText: 'Protagonist name',
                labelStyle: InkSignal.ui(
                  15,
                  color: InkSignal.paper.withValues(alpha: 0.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(InkSignal.panelRadius),
                  borderSide: const BorderSide(
                    color: InkSignal.inkBorder,
                    width: 2,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(InkSignal.panelRadius),
                  borderSide: const BorderSide(
                    color: InkSignal.paper,
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Rival intensity',
              style: InkSignal.ui(
                15,
                color: InkSignal.paper.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final level in const ['Off', 'Light', 'Full'])
                  GestureDetector(
                    onTap: () {
                      state.setRivalIntensity(level);
                      state.setUserName(nameController.text);
                      Navigator.of(sheetContext).pop();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: state.rivalIntensity == level
                            ? InkSignal.paper
                            : Colors.transparent,
                        border: Border.all(
                          color: state.rivalIntensity == level
                              ? InkSignal.paper
                              : InkSignal.inkBorder,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(
                          InkSignal.panelRadius,
                        ),
                      ),
                      child: Text(
                        level,
                        style: InkSignal.ui(
                          15,
                          weight: FontWeight.w700,
                          color: state.rivalIntensity == level
                              ? InkSignal.base
                              : InkSignal.paper,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _openPassSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => const _ProtagonistPassSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SkewedDisplay('CAST', size: 56),
                IconButton(
                  key: const Key('settingsGear'),
                  onPressed: () => _openSettings(state),
                  icon: Icon(
                    Icons.settings,
                    color: InkSignal.paper.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Text(
              'WHO NARRATES YOUR LIFE? '
              'TAP A CARD — EVERY SAMPLE SPEAKS YOUR NAME.',
              style: InkSignal.mono(
                12,
                color: InkSignal.paper.withValues(alpha: 0.55),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                20,
                0,
                20,
                InkSignal.tabBarClearance,
              ),
              children: [
                for (final narrator in _roster)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _NarratorCard(
                      narrator: narrator,
                      selected: state.narrator == narrator.name,
                      onTap: () => _tapNarrator(state, narrator),
                    ),
                  ),
              ],
            ),
          ),
          if (_sampling != null)
            _SamplePanel(
              narrator: _sampling!,
              line: _sampleLine(state, _sampling!),
              onUnlock: _sampling!.locked ? _openPassSheet : null,
              onUse: !_sampling!.locked
                  ? () => state.setNarrator(_sampling!.name)
                  : null,
            ),
        ],
      ),
    );
  }
}

class _NarratorCard extends StatelessWidget {
  const _NarratorCard({
    required this.narrator,
    required this.selected,
    required this.onTap,
  });

  final _Narrator narrator;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: Key('narrator${narrator.name.replaceAll(' ', '')}'),
      onTap: onTap,
      child: Container(
        height: 92,
        decoration: InkSignal.panel(
          color: narrator.color, // Full color — never a greyed husk.
          borderColor: selected ? InkSignal.paper : InkSignal.inkBorder,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const CustomPaint(painter: ScreentonePainter(opacity: 0.08)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  // Flat-cel portrait placeholder.
                  SkewedDisplay(narrator.name.substring(0, 1), size: 44),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          narrator.name.toUpperCase(),
                          style: InkSignal.ui(
                            18,
                            weight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          narrator.role,
                          style: InkSignal.ui(
                            14,
                            color: InkSignal.paper.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (narrator.locked)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.lock,
                          size: 16,
                          color: InkSignal.paper,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'PASS',
                          style: InkSignal.mono(11, color: InkSignal.paper),
                        ),
                      ],
                    )
                  else if (selected)
                    Text(
                      'ACTIVE',
                      style: InkSignal.mono(11, color: InkSignal.paper),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Inline sample playback panel — the demo IS the pitch.
class _SamplePanel extends StatelessWidget {
  const _SamplePanel({
    required this.narrator,
    required this.line,
    this.onUnlock,
    this.onUse,
  });

  final _Narrator narrator;
  final String line;
  final VoidCallback? onUnlock;
  final VoidCallback? onUse;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      // Bottom inset keeps the CTA above the floating tab bar.
      padding: const EdgeInsets.fromLTRB(
        20,
        16,
        20,
        InkSignal.tabBarClearance + 12,
      ),
      decoration: const BoxDecoration(
        color: InkSignal.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(InkSignal.chromeRadius),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${narrator.name.toUpperCase()} · 5s SAMPLE (SIMULATED AUDIO)',
            style: InkSignal.mono(
              11,
              color: InkSignal.paper.withValues(alpha: 0.45),
            ),
          ),
          const SizedBox(height: 10),
          Text(line, style: InkSignal.ui(18, weight: FontWeight.w700)),
          const SizedBox(height: 14),
          if (onUnlock != null)
            // The screen's single crimson element.
            SlabButton(
              'PROTAGONIST PASS',
              key: const Key('passEntry'),
              height: InkSignal.slabHeight,
              onTap: onUnlock!,
            )
          else if (onUse != null)
            SlabButton(
              'NARRATE MY MORNINGS',
              key: const Key('useNarrator'),
              color: InkSignal.paper,
              textColor: InkSignal.base,
              height: InkSignal.slabHeight,
              onTap: onUse!,
            ),
        ],
      ),
    );
  }
}

/// Protagonist Pass — a sheet, never a tab. Three plain benefit lines,
/// annual pre-selected with a trial badge, monthly, restore.
/// NO countdown timers. NO slashed prices.
class _ProtagonistPassSheet extends StatefulWidget {
  const _ProtagonistPassSheet();

  @override
  State<_ProtagonistPassSheet> createState() => _ProtagonistPassSheetState();
}

class _ProtagonistPassSheetState extends State<_ProtagonistPassSheet> {
  bool _annual = true;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: InkSignal.paper.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const SkewedDisplay('PROTAGONIST PASS', size: 32),
          const SizedBox(height: 16),
          for (final benefit in const [
            'Personalized daily episodes with callbacks',
            'Full cast + custom arcs',
            'Unlimited Lock Ins + better foil odds',
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text('·  $benefit', style: InkSignal.ui(17)),
            ),
          const SizedBox(height: 16),
          _PlanRow(
            key: const Key('planAnnual'),
            title: 'ANNUAL',
            price: r'$39.99 / year',
            badge: '7-DAY TRIAL',
            selected: _annual,
            onTap: () => setState(() => _annual = true),
          ),
          const SizedBox(height: 8),
          _PlanRow(
            key: const Key('planMonthly'),
            title: 'MONTHLY',
            price: r'$6.99 / month',
            selected: !_annual,
            onTap: () => setState(() => _annual = false),
          ),
          const SizedBox(height: 16),
          // The sheet's single crimson element.
          SlabButton(
            _annual ? 'START 7-DAY TRIAL' : 'START PILOT ARC',
            key: const Key('passCta'),
            onTap: () => Navigator.of(context).pop(),
          ),
          const SizedBox(height: 4),
          Center(
            child: TextButton(
              key: const Key('restorePurchases'),
              onPressed: () {},
              child: Text(
                'Restore purchases',
                style: InkSignal.ui(
                  15,
                  color: InkSignal.paper.withValues(alpha: 0.45),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanRow extends StatelessWidget {
  const _PlanRow({
    super.key,
    required this.title,
    required this.price,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  final String title;
  final String price;
  final String? badge;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: InkSignal.panel(
          color: InkSignal.base,
          borderColor: selected ? InkSignal.paper : InkSignal.inkBorder,
        ),
        child: Row(
          children: [
            Text(
              title,
              style: InkSignal.ui(
                17,
                weight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(width: 10),
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  border: Border.all(color: InkSignal.paper, width: 1.5),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(badge!, style: InkSignal.mono(10)),
              ),
            const Spacer(),
            Text(
              price,
              style: InkSignal.ui(
                16,
                color: InkSignal.paper.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
