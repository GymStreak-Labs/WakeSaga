import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../alarm/alarm_studio.dart';
import '../state/app_state.dart';
import '../theme/ink_signal.dart';

Future<void> precacheProfileNarratorAssets(BuildContext context) {
  return Future.wait([
    for (final narrator in _narrators)
      precacheImage(AssetImage(narrator.asset), context),
  ]);
}

/// PROFILE — identity, voice, and morning defaults. Since onboarding is now
/// hard-paywalled, this is not a locked narrator shop; it is the user's command
/// file for how WakeSaga should speak and wake them.
class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(bottom: InkSignal.tabBarClearance),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
          children: [
            const SkewedDisplay('PROFILE', size: 52, textAlign: TextAlign.left),
            const SizedBox(height: 8),
            Text(
              'Your protagonist file, narrator, pre-quest jolt, and morning defaults.',
              style: InkSignal.ui(
                16,
                color: InkSignal.paper.withValues(alpha: 0.58),
                weight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 18),
            _ProtagonistFile(state: state),
            const SizedBox(height: 14),
            _NarratorPanel(state: state),
            const SizedBox(height: 14),
            _VoiceStylePanel(state: state),
            const SizedBox(height: 14),
            _RivalIntensityPanel(state: state),
            const SizedBox(height: 14),
            _MorningDefaultsPanel(state: state),
            const SizedBox(height: 14),
            _AccountPanel(state: state),
          ],
        ),
      ),
    );
  }
}

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({
    required this.kicker,
    required this.title,
    required this.children,
    this.trailing,
  });

  final String kicker;
  final String title;
  final Widget? trailing;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: InkSignal.panel(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      kicker,
                      style: InkSignal.mono(
                        10,
                        color: InkSignal.paper.withValues(alpha: 0.45),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      title.toUpperCase(),
                      style: InkSignal.ui(
                        19,
                        weight: FontWeight.w900,
                        letterSpacing: 0.7,
                      ),
                    ),
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
          if (children.isNotEmpty) ...[const SizedBox(height: 14), ...children],
        ],
      ),
    );
  }
}

class _ProtagonistFile extends StatelessWidget {
  const _ProtagonistFile({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final volume = (state.episodeCount ~/ AppState.arcLength) + 1;
    return _ProfileSection(
      kicker: 'PROTAGONIST FILE',
      title: state.userName,
      trailing: _MiniAction(
        label: 'Edit',
        icon: Icons.edit_rounded,
        onTap: () => _openNameSheet(context, state),
      ),
      children: [
        Text(
          '${state.arc} · Volume $volume · EP ${state.nextEpisode} next',
          style: InkSignal.ui(
            16,
            color: InkSignal.paper.withValues(alpha: 0.72),
            weight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _MiniMetric(label: 'ARC DAY', value: '${state.arcDay}/14'),
            const SizedBox(width: 8),
            _MiniMetric(label: 'CARDS', value: '${state.mintedCards.length}'),
            const SizedBox(width: 8),
            _MiniMetric(label: 'QUEST', value: state.quest),
          ],
        ),
      ],
    );
  }

  void _openNameSheet(BuildContext context, AppState state) {
    HapticFeedback.selectionClick();
    final controller = TextEditingController(text: state.userName);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          18,
          20,
          20 + MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PROTAGONIST NAME',
              style: InkSignal.mono(
                11,
                color: InkSignal.paper.withValues(alpha: 0.45),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('profileNameField'),
              controller: controller,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              style: InkSignal.ui(20, weight: FontWeight.w800),
              decoration: InputDecoration(
                hintText: 'What should the narrator call you?',
                hintStyle: InkSignal.ui(
                  16,
                  color: InkSignal.paper.withValues(alpha: 0.35),
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
              onSubmitted: (value) {
                state.setUserName(value);
                Navigator.of(sheetContext).pop();
              },
            ),
            const SizedBox(height: 14),
            SlabButton(
              'SAVE NAME',
              key: const Key('profileSaveName'),
              color: InkSignal.paper,
              textColor: InkSignal.base,
              onTap: () {
                state.setUserName(controller.text);
                Navigator.of(sheetContext).pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _NarratorPanel extends StatelessWidget {
  const _NarratorPanel({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final selected = _narrators.firstWhere(
      (narrator) => narrator.name == state.narrator,
      orElse: () => _narrators.first,
    );
    return _ProfileSection(
      kicker: 'NOW NARRATING',
      title: selected.name,
      children: [
        _NarratorSample(state: state, narrator: selected),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 2.45,
          children: [
            for (final narrator in _narrators)
              _NarratorChoice(
                narrator: narrator,
                selected: narrator.name == state.narrator,
                onTap: () {
                  HapticFeedback.selectionClick();
                  state.setNarrator(narrator.name);
                },
              ),
          ],
        ),
      ],
    );
  }
}

class _NarratorSample extends StatelessWidget {
  const _NarratorSample({required this.state, required this.narrator});

  final AppState state;
  final _Narrator narrator;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: InkSignal.panel(
        color: narrator.color.withValues(alpha: 0.9),
        borderColor: InkSignal.paper.withValues(alpha: 0.18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 98,
            height: 108,
            alignment: Alignment.bottomCenter,
            child: _NarratorPortrait(narrator: narrator, size: 108),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  narrator.role,
                  style: InkSignal.mono(
                    10,
                    color: InkSignal.paper.withValues(alpha: 0.52),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _lineFor(state, narrator.name),
                  style: InkSignal.ui(16, weight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  'Who speaks. Jolt before quest. Full episode after.',
                  style: InkSignal.ui(
                    13,
                    color: InkSignal.paper.withValues(alpha: 0.58),
                    weight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _lineFor(AppState state, String narrator) {
    final name = state.userName;
    final episode = state.nextEpisode;
    return switch (narrator) {
      'Rival' => '"$name, EP $episode does not start from bed."',
      'Captain' => '"Report in, $name. Quest first. Episode after."',
      'Quiet Senior' => '"Stand up. The rest gets easier after that."',
      _ => '"$name, your Cold Open starts when you move."',
    };
  }
}

class _NarratorChoice extends StatelessWidget {
  const _NarratorChoice({
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
      key: Key('profileNarrator${narrator.name.replaceAll(' ', '')}'),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(10),
        decoration: InkSignal.panel(
          color: selected ? InkSignal.paper : InkSignal.base,
          borderColor: selected ? InkSignal.paper : InkSignal.inkBorder,
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected
                    ? InkSignal.base
                    : narrator.color.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(2),
              ),
              clipBehavior: Clip.antiAlias,
              child: _NarratorPortrait(
                narrator: narrator,
                size: 40,
                selected: selected,
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                narrator.name.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: InkSignal.ui(
                  13,
                  color: selected ? InkSignal.base : InkSignal.paper,
                  weight: FontWeight.w900,
                  letterSpacing: 0.6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VoiceStylePanel extends StatelessWidget {
  const _VoiceStylePanel({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return _ProfileSection(
      kicker: 'WAKE JOLT STYLE',
      title: state.wakeJolt,
      children: [
        Text(
          'Short voice lines while the alarm rings. Clear the Wake Quest, then the full Morning Episode begins with narrator voice and cinematic score.',
          style: InkSignal.ui(
            15,
            color: InkSignal.paper.withValues(alpha: 0.6),
            weight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final style in _voiceStyles)
              _ProfileChip(
                label: style,
                selected: state.wakeJolt == style,
                onTap: () {
                  HapticFeedback.selectionClick();
                  state.setWakeJolt(style);
                },
              ),
          ],
        ),
      ],
    );
  }
}

class _RivalIntensityPanel extends StatelessWidget {
  const _RivalIntensityPanel({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return _ProfileSection(
      kicker: 'RIVAL MODE',
      title: state.rivalIntensity,
      children: [
        Text(
          'How hard WakeSaga pushes when you snooze, stall, or miss.',
          style: InkSignal.ui(
            15,
            color: InkSignal.paper.withValues(alpha: 0.6),
            weight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            for (final level in const ['Off', 'Light', 'Full']) ...[
              Expanded(
                child: _ProfileChip(
                  label: level,
                  selected: state.rivalIntensity == level,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    state.setRivalIntensity(level);
                  },
                ),
              ),
              if (level != 'Full') const SizedBox(width: 8),
            ],
          ],
        ),
      ],
    );
  }
}

class _MorningDefaultsPanel extends StatelessWidget {
  const _MorningDefaultsPanel({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return _ProfileSection(
      kicker: 'MORNING DEFAULTS',
      title: '${state.alarmLabel} · ${state.repeatSummary}',
      trailing: _MiniAction(
        key: const Key('profileEditAlarm'),
        label: 'Edit',
        icon: Icons.alarm_rounded,
        onTap: () => openAlarmStudio(context),
      ),
      children: [
        _SettingRow(
          icon: Icons.notifications_active_rounded,
          label: 'Alarm',
          value: state.alarmEnabled
              ? '${state.alarmLabel} · ${state.repeatSummary}'
              : 'Off',
        ),
        _SettingRow(
          icon: Icons.directions_run_rounded,
          label: 'Wake Quest',
          value: state.questIsRandom ? 'Random Quest' : state.quest,
        ),
        _SettingRow(
          icon: Icons.shield_rounded,
          label: 'Fallback',
          value: '${state.fallbackQuest} after 2 failed tries',
        ),
        _SettingRow(
          icon: Icons.movie_filter_rounded,
          label: 'Episode',
          value: 'EP ${state.nextEpisode} reveals after quest clear',
        ),
      ],
    );
  }
}

class _AccountPanel extends StatelessWidget {
  const _AccountPanel({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return _ProfileSection(
      kicker: 'ACCOUNT',
      title: state.protagonistPassUnlocked
          ? 'Protagonist Pass active'
          : 'Protagonist Pass',
      children: [
        Text(
          state.protagonistPassUnlocked
              ? 'Full cast, custom arcs, unlimited Lock Ins, and foil Wake Cards are unlocked.'
              : 'Onboarding hard-gates the pass. If this appears inactive, restore purchases.',
          style: InkSignal.ui(
            15,
            color: InkSignal.paper.withValues(alpha: 0.62),
            weight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        _SettingRow(
          icon: Icons.restore_rounded,
          label: 'Restore',
          value: 'Purchases and entitlement',
        ),
        _SettingRow(
          icon: Icons.help_outline_rounded,
          label: 'Support',
          value: 'Alarm reliability, billing, account',
        ),
      ],
    );
  }
}

class _ProfileChip extends StatelessWidget {
  const _ProfileChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: Key('profileChip${label.replaceAll(' ', '')}'),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
        decoration: InkSignal.panel(
          color: selected ? InkSignal.paper : InkSignal.base,
          borderColor: selected ? InkSignal.paper : InkSignal.inkBorder,
        ),
        child: Text(
          label.toUpperCase(),
          style: InkSignal.ui(
            12,
            color: selected ? InkSignal.base : InkSignal.paper,
            weight: FontWeight.w900,
            letterSpacing: 0.6,
          ),
        ),
      ),
    );
  }
}

class _MiniAction extends StatelessWidget {
  const _MiniAction({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: InkSignal.panel(
          color: InkSignal.base,
          borderColor: InkSignal.paper.withValues(alpha: 0.24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: InkSignal.paper),
            const SizedBox(width: 6),
            Text(
              label.toUpperCase(),
              style: InkSignal.mono(10, color: InkSignal.paper),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: InkSignal.panel(color: InkSignal.base),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: InkSignal.mono(
                9,
                color: InkSignal.paper.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              value.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: InkSignal.ui(13, weight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: InkSignal.paper.withValues(alpha: 0.52)),
          const SizedBox(width: 10),
          Text(
            label.toUpperCase(),
            style: InkSignal.mono(
              10,
              color: InkSignal.paper.withValues(alpha: 0.45),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: InkSignal.ui(
                14,
                color: InkSignal.paper.withValues(alpha: 0.76),
                weight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NarratorPortrait extends StatelessWidget {
  const _NarratorPortrait({
    required this.narrator,
    required this.size,
    this.selected = false,
  });

  final _Narrator narrator;
  final double size;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${narrator.name} narrator portrait',
      image: true,
      child: Image.asset(
        narrator.asset,
        width: size,
        height: size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        opacity: AlwaysStoppedAnimation(selected ? 1 : 0.96),
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded || frame != null) return child;
          return _PortraitFallback(narrator: narrator, size: size);
        },
        errorBuilder: (_, _, _) =>
            _PortraitFallback(narrator: narrator, size: size),
      ),
    );
  }
}

class _PortraitFallback extends StatelessWidget {
  const _PortraitFallback({required this.narrator, required this.size});

  final _Narrator narrator;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Center(
        child: Text(
          narrator.name.substring(0, 1).toUpperCase(),
          style: InkSignal.ui(
            size * 0.42,
            color: InkSignal.paper,
            weight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _Narrator {
  const _Narrator(this.name, this.role, this.color, this.asset);

  final String name;
  final String role;
  final Color color;
  final String asset;
}

const _narrators = [
  _Narrator(
    'Mentor',
    'Warm pressure',
    Color(0xFF2E4A66),
    'assets/narrators/mentor.png',
  ),
  _Narrator(
    'Rival',
    'Sharp receipt energy',
    Color(0xFF5A2333),
    'assets/narrators/rival.png',
  ),
  _Narrator(
    'Captain',
    'Direct field command',
    Color(0xFF3C4D2A),
    'assets/narrators/captain.png',
  ),
  _Narrator(
    'Quiet Senior',
    'Minimal, heavy lines',
    Color(0xFF4A3A5E),
    'assets/narrators/quiet_senior.png',
  ),
];

const _voiceStyles = [
  'Hero trailer',
  'Calm command',
  'Rival cut-in',
  'Recovery mode',
];
