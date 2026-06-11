import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:in_app_review/in_app_review.dart';

import '../state/app_state.dart';
import '../theme/ink_signal.dart';
import '../widgets/screentone.dart';

enum _StepKind {
  coldOpen,
  titleCard,
  choice,
  education,
  text,
  time,
  render,
  reveal,
  rating,
  paywall,
}

enum _StepTransition { soft, crimson, slam }

class _Choice {
  const _Choice(this.label, {this.note});

  final String label;
  final String? note;
}

class _OnboardingStep {
  const _OnboardingStep({
    required this.kind,
    required this.kicker,
    required this.title,
    required this.body,
    this.field,
    this.choices = const [],
    this.entryTransition = _StepTransition.soft,
  });

  final _StepKind kind;
  final String kicker;
  final String title;
  final String body;
  final String? field;
  final List<_Choice> choices;
  final _StepTransition entryTransition;
}

/// Long Cold Open onboarding.
///
/// This restores a Wayk-length setup cadence, but keeps the newer product
/// thesis: every answer builds Episode 1, and the final output is an armed
/// alarm loop rather than a generic motivation profile.
class FirstRunFlow extends StatefulWidget {
  const FirstRunFlow({super.key});

  @override
  State<FirstRunFlow> createState() => _FirstRunFlowState();
}

class _FirstRunFlowState extends State<FirstRunFlow> {
  late final TextEditingController _nameController = TextEditingController(
    text: 'Rookie',
  );
  late final TextEditingController _missionController = TextEditingController(
    text: 'Finish the essay outline',
  );

  int _index = 0;
  int _transitionDirection = 1;
  int _transitionTick = 0;
  _StepTransition _activeTransition = _StepTransition.soft;
  bool _isTransitioning = false;
  bool _isFinishing = false;
  DateTime _picked = DateTime(2026, 1, 1, 6, 30);

  final Map<String, String> _answers = {
    'identity': 'I hit snooze',
    'firstAlarm': 'I negotiate',
    'backup': '2-3 alarms',
    'cost': 'Late start',
    'thief': 'Phone scroll',
    'gain': 'Study block',
    'nightFeeling': 'Hopeful',
    'wakeFeeling': 'Foggy',
    'humanAfter': '15 minutes',
    'arc': 'Study Arc',
    'stake': 'Grades',
    'rival': 'Phone vortex',
    'narrator': 'Mentor',
    'intensity': 'Light',
    'quest': 'Get Up',
    'questPlace': 'Across the room',
    'proof': 'Movement proof',
    'difficulty': 'Normal',
    'fallbackQuest': 'Shake',
    'repeat': 'Weekdays',
    'jolt': 'Hero trailer',
    'behavior': 'Filler costs a chapter',
    'permission': 'I understand',
    'commitment': 'Sign Episode 1',
  };

  static const _steps = <_OnboardingStep>[
    _OnboardingStep(
      kind: _StepKind.coldOpen,
      kicker: 'WAKE SAGA · COLD OPEN',
      title: 'START YOUR DAY\nLIKE AN ANIME\nCHARACTER',
      body:
          'Your alarm becomes the first scene. Stand up, clear the quest, mint the episode.',
    ),
    _OnboardingStep(
      kind: _StepKind.titleCard,
      entryTransition: _StepTransition.crimson,
      kicker: 'EPISODE 0',
      title: "THE ONE WHO\nCOULDN'T WAKE UP",
      body: 'This is the last morning that gets written without you.',
    ),
    _OnboardingStep(
      kind: _StepKind.education,
      kicker: 'PREMISE',
      title: 'Tomorrow becomes Episode 1.',
      body:
          'WakeSaga is not another alarm skin. It is a forced opening sequence for the first minutes of the day.',
    ),
    _OnboardingStep(
      kind: _StepKind.choice,
      field: 'identity',
      kicker: 'ENEMY SCAN',
      title: 'What are mornings like right now?',
      body: 'No judgment. We need the opening scene.',
      choices: [
        _Choice('Already moving', note: 'I just need style'),
        _Choice('I hit snooze', note: 'The bed wins first'),
        _Choice('I disappear online', note: 'Phone opens before eyes'),
        _Choice('I wake up late', note: 'Panic is the routine'),
      ],
    ),
    _OnboardingStep(
      kind: _StepKind.choice,
      field: 'firstAlarm',
      kicker: 'FIRST HIT',
      title: 'When the first alarm hits...',
      body: 'The first ten seconds decide the whole episode.',
      choices: [
        _Choice('I stand up'),
        _Choice('I negotiate'),
        _Choice('I check my phone'),
        _Choice('I wait for backup'),
      ],
    ),
    _OnboardingStep(
      kind: _StepKind.choice,
      field: 'backup',
      kicker: 'ALARM STACK',
      title: 'How chaotic is your alarm stack?',
      body: 'This tells WakeSaga how much structure the Cold Open needs.',
      choices: [
        _Choice('1 alarm'),
        _Choice('2-3 alarms'),
        _Choice('4+ alarms'),
        _Choice('I do not trust alarms'),
      ],
    ),
    _OnboardingStep(
      kind: _StepKind.choice,
      field: 'cost',
      kicker: 'DAMAGE REPORT',
      title: 'What does the lost morning usually cost?',
      body: 'This tells the episode what is actually at stake.',
      choices: [
        _Choice('Late start'),
        _Choice('Missed workout'),
        _Choice('Study panic'),
        _Choice('Bad mood all day'),
      ],
    ),
    _OnboardingStep(
      kind: _StepKind.choice,
      field: 'thief',
      kicker: 'RIVAL DETECTED',
      title: 'What steals your first 10 minutes?',
      body: 'This becomes the rival your narrator writes against.',
      choices: [
        _Choice('Warm bed'),
        _Choice('Phone scroll'),
        _Choice('Low mood fog'),
        _Choice('Late panic'),
      ],
    ),
    _OnboardingStep(
      kind: _StepKind.choice,
      field: 'gain',
      kicker: 'REWARD PREVIEW',
      title: 'If WakeSaga wins back 15 minutes, where do they go?',
      body: 'The app should pull you toward something specific.',
      choices: [
        _Choice('Gym warmup'),
        _Choice('Study block'),
        _Choice('Quiet breakfast'),
        _Choice('No-rush commute'),
      ],
    ),
    _OnboardingStep(
      kind: _StepKind.education,
      entryTransition: _StepTransition.crimson,
      kicker: 'PAYOFF',
      title: 'Rival detected.',
      body:
          'A normal alarm asks your tired brain to decide. WakeSaga moves your body first, then rewards you with the episode.',
    ),
    _OnboardingStep(
      kind: _StepKind.choice,
      field: 'nightFeeling',
      kicker: 'NIGHT CHECK',
      title: 'At night, setting an alarm feels...',
      body: 'The app needs to meet the person you are before sleep too.',
      choices: [
        _Choice('Hopeful'),
        _Choice('Anxious'),
        _Choice('Fake confident'),
        _Choice('Already defeated'),
      ],
    ),
    _OnboardingStep(
      kind: _StepKind.choice,
      field: 'wakeFeeling',
      kicker: 'DAWN CHECK',
      title: 'Right after waking you feel...',
      body: 'This is biology, not a character flaw.',
      choices: [
        _Choice('Ready'),
        _Choice('Foggy'),
        _Choice('Annoyed'),
        _Choice('Heavy'),
      ],
    ),
    _OnboardingStep(
      kind: _StepKind.choice,
      field: 'humanAfter',
      kicker: 'BOOT TIME',
      title: 'How long until you feel human?',
      body: 'The opening sequence needs to survive this fog.',
      choices: [
        _Choice('Instantly'),
        _Choice('5 minutes'),
        _Choice('15 minutes'),
        _Choice('Half the morning'),
      ],
    ),
    _OnboardingStep(
      kind: _StepKind.education,
      kicker: 'SLEEP INERTIA',
      title: 'The villain is not weakness.',
      body:
          'Your brain wakes up unevenly. The fastest path is physical proof before motivation.',
    ),
    _OnboardingStep(
      kind: _StepKind.education,
      kicker: 'OLD LOOP',
      title: 'Alarm. Snooze. Scroll. Panic.',
      body: 'That loop is familiar because it gives you a tiny escape first.',
    ),
    _OnboardingStep(
      kind: _StepKind.education,
      entryTransition: _StepTransition.crimson,
      kicker: 'SAGA LOOP',
      title: 'Alarm. Wake Quest. Title Card. Episode. Wake Card.',
      body:
          'WakeSaga gives you a physical win first, then turns the morning into a scene worth continuing.',
    ),
    _OnboardingStep(
      kind: _StepKind.education,
      kicker: 'ONE RULE',
      title: 'The tired brain does not get the steering wheel.',
      body:
          'At alarm time, the app offers one path: clear the Wake Quest, then unlock the episode.',
    ),
    _OnboardingStep(
      kind: _StepKind.education,
      kicker: 'TITLE CARD',
      title: 'Standing up earns the anime moment.',
      body:
          'The title card hits after proof. That is why it feels like a reward instead of a motivational lecture.',
    ),
    _OnboardingStep(
      kind: _StepKind.choice,
      entryTransition: _StepTransition.crimson,
      field: 'arc',
      kicker: 'ARC SELECT',
      title: 'What kind of episode are we writing?',
      body: 'Pick the world tomorrow morning belongs to.',
      choices: [
        _Choice('Study Arc'),
        _Choice('Gym Arc'),
        _Choice('Deep Work Arc'),
        _Choice('Comeback Arc'),
        _Choice('Monk Mode'),
        _Choice('Recovery Arc'),
      ],
    ),
    _OnboardingStep(
      kind: _StepKind.choice,
      field: 'stake',
      kicker: 'STAKES',
      title: 'What kind of progress should Episode 1 protect?',
      body: 'This keeps the app from sounding generic.',
      choices: [
        _Choice('Grades'),
        _Choice('Body'),
        _Choice('Money'),
        _Choice('Self-respect'),
      ],
    ),
    _OnboardingStep(
      kind: _StepKind.text,
      field: 'mission',
      kicker: 'MISSION',
      title: 'What should tomorrow prove?',
      body: 'Short is better. Your title card will use this.',
    ),
    _OnboardingStep(
      kind: _StepKind.choice,
      field: 'rival',
      kicker: 'RIVAL',
      title: 'Name the thing you beat first.',
      body: 'The narrator needs something to push against.',
      choices: [
        _Choice('Warm bed'),
        _Choice('Phone vortex'),
        _Choice('Late panic'),
        _Choice('Low mood fog'),
      ],
    ),
    _OnboardingStep(
      kind: _StepKind.text,
      field: 'name',
      kicker: 'PROTAGONIST',
      title: 'What should the narrator call you?',
      body: 'This makes the Cold Open feel personal instead of generic.',
    ),
    _OnboardingStep(
      kind: _StepKind.choice,
      field: 'narrator',
      kicker: 'CAST',
      title: 'Who narrates Episode 1?',
      body: 'You can unlock more voices later. Mentor is the free pilot voice.',
      choices: [
        _Choice('Mentor', note: 'Believes first'),
        _Choice('Rival', note: 'Sharp and competitive'),
        _Choice('Captain', note: 'Direct and tactical'),
        _Choice('Quiet Senior', note: 'Calm pressure'),
      ],
    ),
    _OnboardingStep(
      kind: _StepKind.education,
      kicker: 'VOICE SAMPLE',
      title: 'Your narrator remembers yesterday.',
      body:
          '"You bought ninety seconds yesterday. Was it worth it?" The Cold Open should feel personal, not random.',
    ),
    _OnboardingStep(
      kind: _StepKind.choice,
      field: 'intensity',
      kicker: 'TONE',
      title: 'How hard should it push?',
      body: 'Rival energy should help, not shame.',
      choices: [
        _Choice('Off', note: 'Support only'),
        _Choice('Light', note: 'Firm but kind'),
        _Choice('Full', note: 'Competitive mode'),
      ],
    ),
    _OnboardingStep(
      kind: _StepKind.education,
      entryTransition: _StepTransition.crimson,
      kicker: 'WAKE QUEST',
      title: 'The alarm does not end until the quest is cleared.',
      body:
          'This is the Wayk-inspired mechanic: one tiny proof mission before the episode unlocks.',
    ),
    _OnboardingStep(
      kind: _StepKind.choice,
      field: 'quest',
      kicker: 'QUEST SELECT',
      title: 'Choose your first Wake Quest.',
      body: 'Start simple. You can make it harder after trust is built.',
      choices: [
        _Choice('Get Up', note: 'Movement proof'),
        _Choice('Object Hunt', note: 'Find a real item'),
        _Choice('Water Check', note: 'Start the body'),
        _Choice('Desk Ready', note: 'Prove the work zone'),
        _Choice('Sky Photo', note: 'Light proof'),
        _Choice('Shake', note: 'Fallback proof'),
      ],
    ),
    _OnboardingStep(
      kind: _StepKind.choice,
      field: 'questPlace',
      kicker: 'QUEST STAGE',
      title: 'Where should the quest pull you?',
      body: 'Great quests move you away from the bed.',
      choices: [
        _Choice('Across the room'),
        _Choice('Kitchen'),
        _Choice('Desk'),
        _Choice('Outside light'),
      ],
    ),
    _OnboardingStep(
      kind: _StepKind.choice,
      field: 'proof',
      kicker: 'PROOF',
      title: 'What counts as proof?',
      body: 'The app should ask for proof your body has started.',
      choices: [
        _Choice('Movement proof'),
        _Choice('Camera proof'),
        _Choice('Object proof'),
        _Choice('Voice proof'),
      ],
    ),
    _OnboardingStep(
      kind: _StepKind.choice,
      field: 'difficulty',
      kicker: 'DIFFICULTY',
      title: 'How strict should Episode 1 be?',
      body: 'Harder modes can come later. Day one should be winnable.',
      choices: [_Choice('Gentle'), _Choice('Normal'), _Choice('Hard')],
    ),
    _OnboardingStep(
      kind: _StepKind.choice,
      field: 'fallbackQuest',
      kicker: 'FALLBACK',
      title: 'If verification fails, what is the fallback quest?',
      body: 'The alarm should stay strict without becoming hostile.',
      choices: [
        _Choice('Shake'),
        _Choice('Tap pattern'),
        _Choice('Spoken vow'),
        _Choice('Emergency end'),
      ],
    ),
    _OnboardingStep(
      kind: _StepKind.time,
      kicker: 'AIR TIME',
      title: 'What time does your story start?',
      body: 'This arms Episode 1.',
    ),
    _OnboardingStep(
      kind: _StepKind.choice,
      field: 'repeat',
      kicker: 'RHYTHM',
      title: 'When should the saga run?',
      body:
          'The prototype stores the main alarm. Repeat scheduling comes with the real alarm engine.',
      choices: [
        _Choice('Weekdays'),
        _Choice('Every day'),
        _Choice('Training days'),
        _Choice('Custom later'),
      ],
    ),
    _OnboardingStep(
      kind: _StepKind.choice,
      field: 'jolt',
      kicker: 'WAKE JOLT',
      title: 'What should the first audio hit feel like?',
      body: 'Short, urgent, and generated before bed.',
      choices: [
        _Choice('Calm command'),
        _Choice('Rival callout'),
        _Choice('Hero trailer'),
        _Choice('Recovery gentle'),
      ],
    ),
    _OnboardingStep(
      kind: _StepKind.choice,
      field: 'behavior',
      kicker: 'ESCAPE RULE',
      title: 'If you snooze, what happens?',
      body: 'No shame. Just canon.',
      choices: [
        _Choice('Filler costs a chapter'),
        _Choice('Fallback quest first'),
        _Choice('Recovery mode if sick'),
      ],
    ),
    _OnboardingStep(
      kind: _StepKind.education,
      kicker: 'NO TRAPS',
      title: 'The alarm never traps you.',
      body:
          'Two failed verifies offer an easier quest. Three fails end the alarm and log Filler.',
    ),
    _OnboardingStep(
      kind: _StepKind.education,
      kicker: 'KNOCKDOWNS',
      title: 'Misses become canon, not failure.',
      body:
          'Episode count only goes up. A bad morning creates a comeback chapter instead of breaking a streak.',
    ),
    _OnboardingStep(
      kind: _StepKind.choice,
      field: 'permission',
      kicker: 'PERMISSIONS',
      title: 'WakeSaga needs permission to actually wake you.',
      body:
          'Production build: notifications, alarm access, motion, and camera only when the chosen quest needs them.',
      choices: [_Choice('I understand'), _Choice('Remind me why')],
    ),
    _OnboardingStep(
      kind: _StepKind.education,
      kicker: 'PERMISSION PRIMER',
      title: 'Ask only when the feature needs it.',
      body:
          'Notifications arm the alarm. Camera or motion are requested only for quests that use them.',
    ),
    _OnboardingStep(
      kind: _StepKind.education,
      kicker: 'REVIEW',
      title: 'Your opening scene is almost staged.',
      body:
          'Next you sign the contract, then WakeSaga renders the episode plan you just built.',
    ),
    _OnboardingStep(
      kind: _StepKind.choice,
      entryTransition: _StepTransition.crimson,
      field: 'commitment',
      kicker: 'CONTRACT',
      title: 'Sign tomorrow into canon.',
      body: 'This is not a streak. Episode count only goes up.',
      choices: [_Choice('Sign Episode 1'), _Choice('Keep it gentle')],
    ),
    _OnboardingStep(
      kind: _StepKind.render,
      entryTransition: _StepTransition.slam,
      kicker: 'RENDERING',
      title: 'Episode 1 is being staged.',
      body:
          'Scanning rival... syncing narrator... staging Wake Quest... minting card frame...',
    ),
    _OnboardingStep(
      kind: _StepKind.reveal,
      entryTransition: _StepTransition.slam,
      kicker: 'EPISODE 1 READY',
      title: 'Tomorrow has an opening scene.',
      body:
          'Alarm -> Wake Quest -> Title Card -> Morning Episode -> Wake Card.',
    ),
    _OnboardingStep(
      kind: _StepKind.rating,
      kicker: 'QUICK CHECK',
      title: 'Is this your kind of alarm?',
      body:
          'If the Cold Open feels better than another snooze button, tell the store.',
    ),
    _OnboardingStep(
      kind: _StepKind.paywall,
      entryTransition: _StepTransition.slam,
      kicker: 'PROTAGONIST PASS',
      title: 'Unlock the full Cold Open.',
      body: 'Full voices, daily episodes, unlimited Lock Ins, and foil cards.',
    ),
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _missionController.dispose();
    super.dispose();
  }

  _OnboardingStep get _step => _steps[_index];

  double get _progress => (_index + 1) / _steps.length;

  void _next() {
    if (_isTransitioning || _isFinishing) return;
    if (_index == _steps.length - 1) {
      HapticFeedback.heavyImpact();
      _finish();
      return;
    }
    if (_step.kind == _StepKind.rating) {
      HapticFeedback.heavyImpact();
      unawaited(_requestRatingThenContinue());
      return;
    }
    final transition = _steps[_index + 1].entryTransition;
    if (transition == _StepTransition.slam) {
      HapticFeedback.heavyImpact();
    } else if (transition == _StepTransition.crimson) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.selectionClick();
    }
    _stagePageChange(1);
  }

  void _back() {
    if (_index == 0 || _isTransitioning || _isFinishing) return;
    HapticFeedback.selectionClick();
    _stagePageChange(-1);
  }

  Future<void> _stagePageChange(int direction) async {
    final targetIndex = (_index + direction).clamp(0, _steps.length - 1);
    final transition = direction > 0
        ? _steps[targetIndex].entryTransition
        : _StepTransition.soft;

    setState(() {
      _transitionDirection = direction;
      _transitionTick++;
      _activeTransition = transition;
      _isTransitioning = true;
    });

    if (transition == _StepTransition.soft) {
      setState(() => _index += direction);
      await Future<void>.delayed(const Duration(milliseconds: 280));
      if (!mounted) return;
      setState(() => _isTransitioning = false);
      return;
    }

    await Future<void>.delayed(
      Duration(milliseconds: transition == _StepTransition.slam ? 260 : 220),
    );
    if (!mounted) return;
    setState(() => _index += direction);

    await Future<void>.delayed(
      Duration(milliseconds: transition == _StepTransition.slam ? 460 : 410),
    );
    if (!mounted) return;
    setState(() => _isTransitioning = false);
  }

  void _select(String field, String value) {
    HapticFeedback.selectionClick();
    setState(() => _answers[field] = value);
  }

  void _finish() {
    final state = AppScope.of(context, listen: false);
    state.completeFirstRunWithSetup(
      time: TimeOfDay(hour: _picked.hour, minute: _picked.minute),
      name: _nameController.text,
      mission: _missionController.text,
      narratorChoice: _answers['narrator'] ?? 'Mentor',
      rivalLevel: _answers['intensity'] ?? 'Light',
      questType: _answers['quest'] ?? 'Get Up',
      arcChoice: _answers['arc'] ?? 'Study Arc',
      stakeChoice: _answers['stake'] ?? 'Grades',
      rivalChoice: _answers['rival'] ?? 'Phone vortex',
      questPlaceChoice: _answers['questPlace'] ?? 'Across the room',
      proofChoice: _answers['proof'] ?? 'Movement proof',
      difficultyChoice: _answers['difficulty'] ?? 'Normal',
      fallbackQuestChoice: _answers['fallbackQuest'] ?? 'Shake',
      repeatChoice: _answers['repeat'] ?? 'Weekdays',
      joltChoice: _answers['jolt'] ?? 'Hero trailer',
      escapeRuleChoice: _answers['behavior'] ?? 'Filler costs a chapter',
    );
  }

  Future<void> _requestRatingThenContinue() async {
    setState(() => _isFinishing = true);
    try {
      final inAppReview = InAppReview.instance;
      final isAvailable = await inAppReview.isAvailable().timeout(
        const Duration(milliseconds: 700),
        onTimeout: () => false,
      );
      if (isAvailable) {
        await inAppReview.requestReview().timeout(
          const Duration(milliseconds: 1200),
          onTimeout: () {},
        );
      }
    } catch (_) {
      // Native review prompts are best-effort and often suppressed in
      // simulator/debug. The onboarding gate must never block completion.
    }
    if (!mounted) return;
    setState(() => _isFinishing = false);
    _stagePageChange(1);
  }

  void _continueWithoutRating() {
    if (_isFinishing) return;
    HapticFeedback.selectionClick();
    _stagePageChange(1);
  }

  @override
  Widget build(BuildContext context) {
    final step = _step;
    final isPaywall = step.kind == _StepKind.paywall;
    return PopScope(
      canPop: !isPaywall,
      child: Scaffold(
        backgroundColor: InkSignal.base,
        body: Stack(
          fit: StackFit.expand,
          children: [
            const CustomPaint(painter: ScreentonePainter(opacity: 0.035)),
            SafeArea(
              child: Column(
                children: [
                  if (!isPaywall)
                    _TopBar(
                      index: _index,
                      total: _steps.length,
                      progress: _progress,
                      onBack: _index == 0 ? null : _back,
                    ),
                  Expanded(
                    child: TweenAnimationBuilder<double>(
                      key: ValueKey(_index),
                      tween: Tween(begin: 0, end: 1),
                      duration: Duration(
                        milliseconds: _activeTransition == _StepTransition.soft
                            ? 280
                            : 120,
                      ),
                      curve: Curves.easeOutCubic,
                      child: _StepBody(
                        step: step,
                        picked: _picked,
                        nameController: _nameController,
                        missionController: _missionController,
                        answers: _answers,
                        onSelect: _select,
                        onTimeChanged: (value) =>
                            setState(() => _picked = value),
                        onContinueWithoutRating: _continueWithoutRating,
                        onSubscribe: _finish,
                      ),
                      builder: (context, value, child) {
                        if (_activeTransition != _StepTransition.soft) {
                          return child!;
                        }
                        return Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(
                              (1 - value) *
                                  32 *
                                  _transitionDirection.toDouble(),
                              (1 - value) * 10,
                            ),
                            child: child,
                          ),
                        );
                      },
                    ),
                  ),
                  if (!isPaywall)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
                      child: SlabButton(
                        step.kind == _StepKind.rating
                            ? 'Rate WakeSaga'
                            : step.kind == _StepKind.coldOpen
                            ? 'Roll Episode 0'
                            : 'Continue',
                        key: Key('onboardingNext$_index'),
                        color: step.kind == _StepKind.reveal
                            ? InkSignal.gold
                            : InkSignal.crimson,
                        textColor: step.kind == _StepKind.reveal
                            ? Colors.black
                            : Colors.white,
                        onTap: _next,
                      ),
                    ),
                ],
              ),
            ),
            if (_isTransitioning && _activeTransition != _StepTransition.soft)
              _CrimsonSwipe(
                key: ValueKey(_transitionTick),
                direction: _transitionDirection,
                slam: _activeTransition == _StepTransition.slam,
              ),
          ],
        ),
      ),
    );
  }
}

class _CrimsonSwipe extends StatelessWidget {
  const _CrimsonSwipe({super.key, required this.direction, required this.slam});

  final int direction;
  final bool slam;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: Duration(milliseconds: slam ? 720 : 620),
        curve: Curves.easeInOutCubic,
        builder: (context, value, _) {
          final size = MediaQuery.sizeOf(context);
          final start = direction > 0 ? -size.width * 2.65 : size.width * 3.65;
          final end = direction > 0 ? size.width * 3.65 : -size.width * 2.65;
          final x = switch (value) {
            < 0.36 =>
              start + (0 - start) * Curves.easeOutCubic.transform(value / 0.36),
            < 0.56 => 0.0,
            _ =>
              0 +
                  (end - 0) *
                      Curves.easeInCubic.transform((value - 0.56) / 0.44),
          };
          final edgeOpacity = value < 0.5 ? value * 2 : (1 - value) * 2;

          return Stack(
            fit: StackFit.expand,
            children: [
              Opacity(
                opacity: (edgeOpacity * 0.16).clamp(0, 0.16),
                child: const ColoredBox(color: Colors.black),
              ),
              Transform.translate(
                offset: Offset(x, 0),
                child: CustomPaint(
                  painter: _CrimsonSwipePainter(
                    direction: direction,
                    slam: slam,
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CrimsonSwipePainter extends CustomPainter {
  const _CrimsonSwipePainter({required this.direction, required this.slam});

  final int direction;
  final bool slam;

  @override
  void paint(Canvas canvas, Size size) {
    final bandWidth = size.width * (slam ? 2.62 : 2.35);
    final skew = size.width * (slam ? 0.88 : 0.72) * direction;
    final top = -size.height * 0.9;
    final bottom = size.height * 1.9;
    final centerX = size.width / 2;

    final path = Path()
      ..moveTo(centerX - bandWidth / 2 - skew, top)
      ..lineTo(centerX + bandWidth / 2 - skew, top)
      ..lineTo(centerX + bandWidth / 2 + skew, bottom)
      ..lineTo(centerX - bandWidth / 2 + skew, bottom)
      ..close();

    canvas
      ..drawPath(
        path,
        Paint()
          ..color = InkSignal.crimson.withValues(alpha: slam ? 0.58 : 0.44)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, slam ? 42 : 34),
      )
      ..drawPath(
        path.shift(Offset(-18 * direction.toDouble(), 0)),
        Paint()
          ..color = InkSignal.gold.withValues(alpha: slam ? 0.22 : 0.14)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, slam ? 24 : 18),
      )
      ..drawPath(path, Paint()..color = InkSignal.crimson);
  }

  @override
  bool shouldRepaint(covariant _CrimsonSwipePainter oldDelegate) {
    return oldDelegate.direction != direction || oldDelegate.slam != slam;
  }
}

class _TimedEntrance extends StatefulWidget {
  const _TimedEntrance({
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 340),
    this.offset = const Offset(0.04, 0),
    this.scale = 0.98,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;
  final Offset offset;
  final double scale;

  @override
  State<_TimedEntrance> createState() => _TimedEntranceState();
}

class _TimedEntranceState extends State<_TimedEntrance> {
  bool _shown = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.delay, () {
      if (mounted) setState(() => _shown = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _shown ? 1 : 0,
      duration: widget.duration,
      curve: Curves.easeOutCubic,
      child: AnimatedSlide(
        offset: _shown ? Offset.zero : widget.offset,
        duration: widget.duration,
        curve: Curves.easeOutCubic,
        child: AnimatedScale(
          scale: _shown ? 1 : widget.scale,
          duration: widget.duration,
          curve: Curves.easeOutCubic,
          child: widget.child,
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.index,
    required this.total,
    required this.progress,
    required this.onBack,
  });

  final int index;
  final int total;
  final double progress;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 8),
      child: Row(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onBack,
            child: SizedBox(
              width: 42,
              height: 42,
              child: Icon(
                Icons.arrow_back,
                color: onBack == null
                    ? InkSignal.paper.withValues(alpha: 0.18)
                    : InkSignal.paper.withValues(alpha: 0.7),
              ),
            ),
          ),
          Expanded(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 420),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: value,
                  minHeight: 4,
                  color: InkSignal.paper,
                  backgroundColor: InkSignal.inkBorder,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${index + 1}/$total',
            style: InkSignal.mono(
              11,
              color: InkSignal.paper.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepBody extends StatelessWidget {
  const _StepBody({
    required this.step,
    required this.picked,
    required this.nameController,
    required this.missionController,
    required this.answers,
    required this.onSelect,
    required this.onTimeChanged,
    required this.onContinueWithoutRating,
    required this.onSubscribe,
  });

  final _OnboardingStep step;
  final DateTime picked;
  final TextEditingController nameController;
  final TextEditingController missionController;
  final Map<String, String> answers;
  final void Function(String field, String value) onSelect;
  final ValueChanged<DateTime> onTimeChanged;
  final VoidCallback onContinueWithoutRating;
  final VoidCallback onSubscribe;

  @override
  Widget build(BuildContext context) {
    if (step.kind == _StepKind.paywall) {
      return _HardPaywallStep(
        picked: picked,
        name: nameController.text,
        mission: missionController.text,
        answers: answers,
        onSubscribe: onSubscribe,
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
      child: switch (step.kind) {
        _StepKind.coldOpen => _ColdOpenStep(step: step),
        _StepKind.titleCard => _TitleCardStep(step: step),
        _StepKind.choice => _ChoiceStep(
          step: step,
          selected: answers[step.field],
          onSelect: (value) => onSelect(step.field!, value),
        ),
        _StepKind.education => _EducationStep(step: step),
        _StepKind.text => _TextStep(
          step: step,
          controller: step.field == 'name' ? nameController : missionController,
        ),
        _StepKind.time => _TimeStep(
          step: step,
          picked: picked,
          onChanged: onTimeChanged,
        ),
        _StepKind.render => _RenderStep(step: step, answers: answers),
        _StepKind.reveal => _RevealStep(
          step: step,
          picked: picked,
          name: nameController.text,
          mission: missionController.text,
          answers: answers,
        ),
        _StepKind.rating => _RatingStep(
          step: step,
          onContinueWithoutRating: onContinueWithoutRating,
        ),
        _StepKind.paywall => const SizedBox.shrink(),
      },
    );
  }
}

class _ColdOpenStep extends StatelessWidget {
  const _ColdOpenStep({required this.step});

  static const _heroAsset = 'assets/onboarding/cold-open-anime-character.png';

  final _OnboardingStep step;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          right: -92,
          top: 72,
          bottom: 112,
          child: Opacity(
            opacity: 0.68,
            child: Image.asset(
              _heroAsset,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              step.kicker,
              style: InkSignal.mono(12, color: InkSignal.crimson),
            ),
            const Spacer(),
            const SkewedDisplay(
              'START YOUR DAY',
              size: 42,
              textAlign: TextAlign.left,
            ),
            const SkewedDisplay(
              'LIKE AN ANIME',
              size: 42,
              textAlign: TextAlign.left,
            ),
            const SkewedDisplay(
              'CHARACTER',
              size: 42,
              textAlign: TextAlign.left,
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: 245,
              child: Text(
                step.body,
                style: InkSignal.ui(
                  17,
                  color: InkSignal.paper.withValues(alpha: 0.78),
                  weight: FontWeight.w700,
                ),
              ),
            ),
            const Spacer(),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'LONG COLD OPEN',
                style: InkSignal.mono(
                  12,
                  color: InkSignal.paper.withValues(alpha: 0.45),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TitleCardStep extends StatelessWidget {
  const _TitleCardStep({required this.step});

  final _OnboardingStep step;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 620),
      curve: Curves.easeOutBack,
      builder: (context, value, _) {
        final opacity = value.clamp(0.0, 1.0);
        return Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(
              painter: SpeedLinesPainter(opacity: 0.04 + (0.16 * opacity)),
            ),
            Center(
              child: Opacity(
                opacity: opacity,
                child: Transform.rotate(
                  angle: -0.24 + (0.10 * value),
                  child: Transform.scale(
                    scale: 0.78 + (0.22 * value),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SkewedDisplay(step.kicker, size: 62),
                        const SizedBox(height: 14),
                        SkewedDisplay(step.title, size: 40),
                        const SizedBox(height: 18),
                        Text(
                          step.body,
                          textAlign: TextAlign.center,
                          style: InkSignal.ui(
                            17,
                            color: InkSignal.paper.withValues(alpha: 0.65),
                            weight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ChoiceStep extends StatelessWidget {
  const _ChoiceStep({
    required this.step,
    required this.selected,
    required this.onSelect,
  });

  final _OnboardingStep step;
  final String? selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Header(step: step),
        const SizedBox(height: 18),
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.zero,
            itemCount: step.choices.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final choice = step.choices[index];
              final isSelected = selected == choice.label;
              return _TimedEntrance(
                delay: Duration(milliseconds: 36 * index),
                offset: const Offset(0.08, 0),
                child: GestureDetector(
                  key: Key(
                    'choice${step.field}${choice.label.replaceAll(' ', '')}',
                  ),
                  onTap: () => onSelect(choice.label),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    margin: EdgeInsets.only(
                      left: isSelected ? 3 : 0,
                      right: isSelected ? 0 : 3,
                    ),
                    padding: const EdgeInsets.all(16),
                    decoration: InkSignal.panel(
                      color: isSelected ? InkSignal.paper : InkSignal.surface,
                      borderColor: isSelected
                          ? InkSignal.paper
                          : InkSignal.inkBorder,
                    ),
                    child: Row(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 34,
                          height: 34,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isSelected
                                  ? InkSignal.base
                                  : InkSignal.paper,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(
                              InkSignal.panelRadius,
                            ),
                          ),
                          child: Text(
                            String.fromCharCode(65 + index),
                            style: InkSignal.ui(
                              15,
                              color: isSelected
                                  ? InkSignal.base
                                  : InkSignal.paper,
                              weight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                choice.label,
                                style: InkSignal.ui(
                                  18,
                                  color: isSelected
                                      ? InkSignal.base
                                      : InkSignal.paper,
                                  weight: FontWeight.w900,
                                ),
                              ),
                              if (choice.note != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  choice.note!,
                                  style: InkSignal.ui(
                                    14,
                                    color: isSelected
                                        ? InkSignal.base.withValues(alpha: 0.62)
                                        : InkSignal.paper.withValues(
                                            alpha: 0.55,
                                          ),
                                    weight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
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

class _EducationStep extends StatelessWidget {
  const _EducationStep({required this.step});

  final _OnboardingStep step;

  String get _label => switch (step.kicker) {
    'PAYOFF' => 'RIVAL FILE',
    'SLEEP INERTIA' => 'BODY NOTE',
    'OLD LOOP' => 'LOOP BREAK',
    'SAGA LOOP' => 'NEW LOOP',
    'ONE RULE' => 'ALARM RULE',
    'TITLE CARD' => 'REWARD RULE',
    'VOICE SAMPLE' => 'VOICE TEST',
    'WAKE QUEST' => 'QUEST RULE',
    'NO TRAPS' => 'SAFETY RULE',
    'KNOCKDOWNS' => 'CANON RULE',
    'PERMISSION PRIMER' => 'ACCESS NOTE',
    'REVIEW' => 'FINAL CHECK',
    _ => 'CANON NOTE',
  };

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _Header(step: step, showBody: false),
        const SizedBox(height: 36),
        _TimedEntrance(
          delay: const Duration(milliseconds: 90),
          offset: const Offset(0, 0.05),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: InkSignal.panel(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // The panel label changes by beat so the long flow does
                // not feel like the same note card repeating.
                SkewedDisplay(_label, size: 34, textAlign: TextAlign.left),
                const SizedBox(height: 16),
                Text(
                  step.body,
                  style: InkSignal.ui(
                    20,
                    color: InkSignal.paper.withValues(alpha: 0.78),
                    weight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _TextStep extends StatelessWidget {
  const _TextStep({required this.step, required this.controller});

  final _OnboardingStep step;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _Header(step: step),
        const SizedBox(height: 34),
        _TimedEntrance(
          delay: const Duration(milliseconds: 80),
          offset: const Offset(0.06, 0),
          child: TextField(
            key: Key('${step.field}Field'),
            controller: controller,
            style: InkSignal.ui(22, weight: FontWeight.w900),
            minLines: step.field == 'mission' ? 2 : 1,
            maxLines: step.field == 'mission' ? 3 : 1,
            decoration: InputDecoration(
              hintText: step.field == 'name'
                  ? 'Rookie'
                  : 'Finish the essay outline',
              hintStyle: InkSignal.ui(
                20,
                color: InkSignal.paper.withValues(alpha: 0.3),
              ),
              filled: true,
              fillColor: InkSignal.surface,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(InkSignal.panelRadius),
                borderSide: const BorderSide(
                  color: InkSignal.inkBorder,
                  width: 2,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(InkSignal.panelRadius),
                borderSide: const BorderSide(color: InkSignal.paper, width: 2),
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          step.field == 'name'
              ? 'The Cold Open uses this in the first line.'
              : 'Example title: ${deriveEpisodeTitle(controller.text, 1)}',
          style: InkSignal.mono(
            13,
            color: InkSignal.paper.withValues(alpha: 0.55),
          ),
        ),
      ],
    );
  }
}

class _TimeStep extends StatelessWidget {
  const _TimeStep({
    required this.step,
    required this.picked,
    required this.onChanged,
  });

  final _OnboardingStep step;
  final DateTime picked;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _Header(step: step),
        const SizedBox(height: 28),
        SizedBox(
          height: 230,
          child: CupertinoTheme(
            data: const CupertinoThemeData(
              brightness: Brightness.dark,
              textTheme: CupertinoTextThemeData(
                dateTimePickerTextStyle: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  color: InkSignal.paper,
                ),
              ),
            ),
            child: CupertinoDatePicker(
              mode: CupertinoDatePickerMode.time,
              initialDateTime: picked,
              onDateTimeChanged: onChanged,
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'EPISODE 1 AIRS AT '
          '${formatTimeOfDay(TimeOfDay(hour: picked.hour, minute: picked.minute))}',
          key: const Key('episodeOneTeaser'),
          style: InkSignal.mono(
            13,
            color: InkSignal.paper.withValues(alpha: 0.65),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _RenderStep extends StatelessWidget {
  const _RenderStep({required this.step, required this.answers});

  final _OnboardingStep step;
  final Map<String, String> answers;

  @override
  Widget build(BuildContext context) {
    const items = [
      'Rival detected',
      'Narrator synced',
      'Wake Quest staged',
      'Title Card drafted',
      'Wake Card frame minted',
    ];
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _Header(step: step),
        const SizedBox(height: 28),
        for (final item in items)
          _TimedEntrance(
            delay: Duration(milliseconds: 70 * items.indexOf(item)),
            offset: const Offset(0.07, 0),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: InkSignal.panel(),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check,
                      color: InkSignal.verifyGreen,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item,
                        style: InkSignal.ui(17, weight: FontWeight.w900),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _RevealStep extends StatelessWidget {
  const _RevealStep({
    required this.step,
    required this.picked,
    required this.name,
    required this.mission,
    required this.answers,
  });

  final _OnboardingStep step;
  final DateTime picked;
  final String name;
  final String mission;
  final Map<String, String> answers;

  @override
  Widget build(BuildContext context) {
    final time = formatTimeOfDay(
      TimeOfDay(hour: picked.hour, minute: picked.minute),
    );
    final quest = answers['quest'] ?? 'Get Up';
    final narrator = answers['narrator'] ?? 'Mentor';
    final title = deriveEpisodeTitle(mission, 1);
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _Header(step: step),
        const SizedBox(height: 18),
        _TimedEntrance(
          delay: const Duration(milliseconds: 100),
          offset: const Offset(0, 0.06),
          scale: 0.94,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: InkSignal.panel(borderColor: InkSignal.gold),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'EPISODE 1',
                  style: InkSignal.mono(12, color: InkSignal.gold),
                ),
                const SizedBox(height: 8),
                SkewedDisplay(title, size: 34, textAlign: TextAlign.left),
                const SizedBox(height: 12),
                Text(
                  '$name · $time · $quest · $narrator',
                  style: InkSignal.ui(
                    17,
                    color: InkSignal.paper.withValues(alpha: 0.72),
                    weight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        for (final item in const [
          'Alarm rings',
          'Clear Wake Quest',
          'Title Card slams',
          'Morning Episode plays',
          'Wake Card mints',
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text('-> $item', style: InkSignal.mono(14)),
          ),
      ],
    );
  }
}

class _RatingStep extends StatelessWidget {
  const _RatingStep({
    required this.step,
    required this.onContinueWithoutRating,
  });

  final _OnboardingStep step;
  final VoidCallback onContinueWithoutRating;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _Header(step: step),
        const SizedBox(height: 24),
        _TimedEntrance(
          delay: const Duration(milliseconds: 90),
          offset: const Offset(0, 0.05),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: InkSignal.panel(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'EPISODE 1 IS ARMED EITHER WAY',
                  style: InkSignal.mono(
                    12,
                    color: InkSignal.paper.withValues(alpha: 0.58),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Tap the crimson button to rate WakeSaga. iOS may show the '
                  'native review sheet. If not, you still go straight into '
                  'Today.',
                  style: InkSignal.ui(
                    18,
                    color: InkSignal.paper.withValues(alpha: 0.72),
                    weight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _SecondaryRatingAction(
                key: const Key('ratingMaybeLater'),
                label: 'Later',
                onTap: onContinueWithoutRating,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SecondaryRatingAction(
                key: const Key('ratingNeedsWork'),
                label: 'Needs work',
                onTap: onContinueWithoutRating,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _HardPaywallStep extends StatefulWidget {
  const _HardPaywallStep({
    required this.picked,
    required this.name,
    required this.mission,
    required this.answers,
    required this.onSubscribe,
  });

  final DateTime picked;
  final String name;
  final String mission;
  final Map<String, String> answers;
  final VoidCallback onSubscribe;

  @override
  State<_HardPaywallStep> createState() => _HardPaywallStepState();
}

class _HardPaywallStepState extends State<_HardPaywallStep> {
  int _selectedPlan = 0; // 0 = special offer, 1 = annual trial, 2 = weekly.
  int _secondsLeft = 15 * 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _secondsLeft == 0) return;
      setState(() => _secondsLeft--);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _timerLabel {
    final minutes = (_secondsLeft ~/ 60).toString().padLeft(2, '0');
    final seconds = (_secondsLeft % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String get _ctaLabel => switch (_selectedPlan) {
    0 => 'Activate Offer',
    1 => 'Start 7-Day Free Trial',
    _ => 'Start Weekly',
  };

  void _selectPlan(int plan) {
    HapticFeedback.selectionClick();
    setState(() => _selectedPlan = plan);
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    final time = formatTimeOfDay(
      TimeOfDay(hour: widget.picked.hour, minute: widget.picked.minute),
    );
    final quest = widget.answers['quest'] ?? 'Get Up';
    final narrator = widget.answers['narrator'] ?? 'Mentor';
    final arc = widget.answers['arc'] ?? 'Study Arc';
    return Stack(
      fit: StackFit.expand,
      children: [
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.92),
                radius: 1.12,
                colors: [Color(0xFF25111A), InkSignal.base],
              ),
            ),
          ),
        ),
        SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(20, 18, 20, 112 + bottomPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('PROTAGONIST PASS', style: InkSignal.mono(12)),
              const SizedBox(height: 12),
              const SkewedDisplay(
                'UNLOCK THE FULL\nCOLD OPEN',
                size: 36,
                textAlign: TextAlign.left,
              ),
              const SizedBox(height: 10),
              Text(
                'Episode 1 is staged for $time. Protagonist Pass unlocks '
                'the voices, daily AI episodes, Lock Ins, and foil Wake Cards.',
                style: InkSignal.ui(
                  17,
                  color: InkSignal.paper.withValues(alpha: 0.68),
                  weight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              _PaywallProofStrip(quest: quest, narrator: narrator, arc: arc),
              const SizedBox(height: 16),
              _SpecialOfferCard(
                selected: _selectedPlan == 0,
                timerLabel: _timerLabel,
                onTap: () => _selectPlan(0),
              ),
              const SizedBox(height: 10),
              _StandardPlanCard(
                key: const Key('planAnnual'),
                selected: _selectedPlan == 1,
                title: 'Annual',
                price: r'$59.99',
                period: '/year',
                subtitle: r'Just $5.00/mo',
                banner: '7-DAY FREE TRIAL',
                onTap: () => _selectPlan(1),
              ),
              const SizedBox(height: 10),
              _StandardPlanCard(
                key: const Key('planWeekly'),
                selected: _selectedPlan == 2,
                title: 'Weekly',
                price: r'$9.99',
                period: '/week',
                subtitle: 'Flexible pilot pass',
                onTap: () => _selectPlan(2),
              ),
              const SizedBox(height: 18),
              _PaywallDivider(),
              const SizedBox(height: 14),
              for (final feature in const [
                (
                  'Personalized AI wake episodes',
                  'Daily narrator scripts with callbacks to your real mornings.',
                ),
                (
                  'Full cast + custom arcs',
                  'Rival, Captain, Quiet Senior, recovery tone, and more.',
                ),
                (
                  'Unlimited Lock Ins',
                  'Generate short focus clips for study, gym, work, or reset.',
                ),
                (
                  'Foil Wake Cards',
                  'Collect stronger episode cards when you beat the alarm.',
                ),
              ])
                _PaywallFeature(title: feature.$1, body: feature.$2),
              const SizedBox(height: 10),
              Center(
                child: TextButton(
                  key: const Key('restorePurchases'),
                  onPressed: () => HapticFeedback.selectionClick(),
                  child: Text(
                    'Restore purchases',
                    style: InkSignal.ui(
                      15,
                      color: InkSignal.paper.withValues(alpha: 0.5),
                      weight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              Text(
                'Subscription auto-renews unless cancelled at least 24 hours '
                'before renewal. Manage in Apple ID subscriptions.',
                textAlign: TextAlign.center,
                style: InkSignal.ui(
                  12,
                  color: InkSignal.paper.withValues(alpha: 0.34),
                  weight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Terms', style: InkSignal.mono(11)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      '·',
                      style: InkSignal.mono(
                        11,
                        color: InkSignal.paper.withValues(alpha: 0.35),
                      ),
                    ),
                  ),
                  Text('Privacy', style: InkSignal.mono(11)),
                ],
              ),
            ],
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            padding: EdgeInsets.fromLTRB(20, 18, 20, bottomPadding + 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  InkSignal.base.withValues(alpha: 0),
                  InkSignal.base.withValues(alpha: 0.94),
                  InkSignal.base,
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_selectedPlan == 1) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.check_circle_outline,
                        size: 16,
                        color: InkSignal.verifyGreen,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'No payment now',
                        style: InkSignal.ui(
                          13,
                          color: InkSignal.verifyGreen,
                          weight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
                SlabButton(
                  _ctaLabel,
                  key: const Key('beginButton'),
                  onTap: widget.onSubscribe,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PaywallProofStrip extends StatelessWidget {
  const _PaywallProofStrip({
    required this.quest,
    required this.narrator,
    required this.arc,
  });

  final String quest;
  final String narrator;
  final String arc;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: InkSignal.panel(),
      child: Row(
        children: [
          Expanded(
            child: _ProofStat(label: 'ARC', value: _shortArc(arc)),
          ),
          Container(width: 1, height: 38, color: InkSignal.inkBorder),
          Expanded(
            child: _ProofStat(label: 'QUEST', value: _shortValue(quest)),
          ),
          Container(width: 1, height: 38, color: InkSignal.inkBorder),
          Expanded(
            child: _ProofStat(label: 'VOICE', value: _shortValue(narrator)),
          ),
        ],
      ),
    );
  }

  static String _shortArc(String value) {
    return value.replaceAll(' Arc', '').toUpperCase();
  }

  static String _shortValue(String value) {
    final cleaned = value
        .replaceAll(' vortex', '')
        .replaceAll(' panic', '')
        .replaceAll(' fog', '')
        .replaceAll(' Check', '')
        .replaceAll(' Ready', '');
    return cleaned.toUpperCase();
  }
}

class _ProofStat extends StatelessWidget {
  const _ProofStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: InkSignal.mono(
            10,
            color: InkSignal.paper.withValues(alpha: 0.42),
          ),
        ),
        const SizedBox(height: 4),
        Text(value, style: InkSignal.ui(14, weight: FontWeight.w900)),
      ],
    );
  }
}

class _SpecialOfferCard extends StatelessWidget {
  const _SpecialOfferCard({
    required this.selected,
    required this.timerLabel,
    required this.onTap,
  });

  final bool selected;
  final String timerLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: const Key('planSpecial'),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: InkSignal.panel(
          color: InkSignal.surface,
          borderColor: selected ? InkSignal.crimson : InkSignal.inkBorder,
        ),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: const BoxDecoration(
                color: InkSignal.crimson,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(InkSignal.panelRadius - 1),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    'SPECIAL OFFER',
                    style: InkSignal.mono(11, color: Colors.white),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    color: InkSignal.paper,
                    child: Text(
                      'SAVE 50%',
                      style: InkSignal.mono(9, color: InkSignal.base),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  _PlanCheck(selected: selected),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Pilot Season Offer', style: InkSignal.ui(18)),
                        const SizedBox(height: 4),
                        Text(
                          'Reserved for $timerLabel · Just \$2.50/mo',
                          style: InkSignal.ui(
                            13,
                            color: InkSignal.paper.withValues(alpha: 0.56),
                            weight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        r'$59.99',
                        style: InkSignal.ui(
                          12,
                          color: InkSignal.paper.withValues(alpha: 0.34),
                          weight: FontWeight.w700,
                        ).copyWith(decoration: TextDecoration.lineThrough),
                      ),
                      Text(
                        r'$29.99',
                        style: InkSignal.ui(22, weight: FontWeight.w900),
                      ),
                      Text(
                        '/year',
                        style: InkSignal.ui(
                          12,
                          color: InkSignal.paper.withValues(alpha: 0.48),
                          weight: FontWeight.w800,
                        ),
                      ),
                    ],
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

class _StandardPlanCard extends StatelessWidget {
  const _StandardPlanCard({
    super.key,
    required this.selected,
    required this.title,
    required this.price,
    required this.period,
    required this.subtitle,
    required this.onTap,
    this.banner,
  });

  final bool selected;
  final String title;
  final String price;
  final String period;
  final String subtitle;
  final VoidCallback onTap;
  final String? banner;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: InkSignal.panel(
          color: InkSignal.surface,
          borderColor: selected ? InkSignal.paper : InkSignal.inkBorder,
        ),
        child: Column(
          children: [
            if (banner != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 7),
                decoration: BoxDecoration(
                  color: InkSignal.paper.withValues(alpha: 0.08),
                  border: const Border(
                    bottom: BorderSide(color: InkSignal.inkBorder),
                  ),
                ),
                child: Text(
                  banner!,
                  textAlign: TextAlign.center,
                  style: InkSignal.mono(
                    10,
                    color: InkSignal.paper.withValues(alpha: 0.72),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  _PlanCheck(selected: selected),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: InkSignal.ui(18)),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: InkSignal.ui(
                            13,
                            color: InkSignal.paper.withValues(alpha: 0.54),
                            weight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        price,
                        style: InkSignal.ui(20, weight: FontWeight.w900),
                      ),
                      Text(
                        period,
                        style: InkSignal.ui(
                          12,
                          color: InkSignal.paper.withValues(alpha: 0.48),
                          weight: FontWeight.w800,
                        ),
                      ),
                    ],
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

class _PlanCheck extends StatelessWidget {
  const _PlanCheck({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? InkSignal.crimson : InkSignal.paper,
          width: selected ? 2.5 : 1.5,
        ),
      ),
      child: selected
          ? const Icon(Icons.check, size: 15, color: InkSignal.crimson)
          : null,
    );
  }
}

class _PaywallDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Container(height: 1, color: InkSignal.inkBorder)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'WHAT YOU GET',
            style: InkSignal.mono(
              10,
              color: InkSignal.paper.withValues(alpha: 0.5),
            ),
          ),
        ),
        Expanded(child: Container(height: 1, color: InkSignal.inkBorder)),
      ],
    );
  }
}

class _PaywallFeature extends StatelessWidget {
  const _PaywallFeature({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.bolt, size: 18, color: InkSignal.crimson),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: InkSignal.ui(16, weight: FontWeight.w900)),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: InkSignal.ui(
                    13,
                    color: InkSignal.paper.withValues(alpha: 0.58),
                    weight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SecondaryRatingAction extends StatelessWidget {
  const _SecondaryRatingAction({
    super.key,
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 54,
        alignment: Alignment.center,
        decoration: InkSignal.panel(
          color: InkSignal.base.withValues(alpha: 0.3),
          borderColor: InkSignal.inkBorder,
        ),
        child: Text(
          label,
          style: InkSignal.ui(
            15,
            color: InkSignal.paper.withValues(alpha: 0.7),
            weight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.step, this.showBody = true});

  final _OnboardingStep step;
  final bool showBody;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TimedEntrance(
          duration: const Duration(milliseconds: 300),
          offset: const Offset(0.04, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                step.kicker,
                style: InkSignal.mono(12, color: InkSignal.crimson),
              ),
              const SizedBox(height: 12),
              Text(
                step.title,
                style: InkSignal.ui(
                  32,
                  weight: FontWeight.w900,
                ).copyWith(height: 1.04),
              ),
              if (showBody) ...[
                const SizedBox(height: 12),
                Text(
                  step.body,
                  style: InkSignal.ui(
                    18,
                    color: InkSignal.paper.withValues(alpha: 0.66),
                    weight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
