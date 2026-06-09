import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const _previewMainApp = bool.fromEnvironment('WAKE_SAGA_PREVIEW_MAIN_APP');
const _previewSection = String.fromEnvironment('WAKE_SAGA_PREVIEW_SECTION');
const _previewState = String.fromEnvironment('WAKE_SAGA_PREVIEW_STATE');

void main() {
  runApp(const WakeSagaApp());
}

class WakeSagaApp extends StatelessWidget {
  const WakeSagaApp({super.key});

  @override
  Widget build(BuildContext context) {
    final baseTheme = ThemeData.light(useMaterial3: true);

    return MaterialApp(
      title: 'WakeSaga',
      debugShowCheckedModeBanner: false,
      theme: baseTheme.copyWith(
        scaffoldBackgroundColor: _PrototypeColors.paper,
        colorScheme: const ColorScheme.light(
          primary: _PrototypeColors.coral,
          secondary: _PrototypeColors.gold,
          surface: Colors.white,
          error: _SagaColors.warning,
          onPrimary: Colors.white,
          onSecondary: _PrototypeColors.ink,
          onSurface: _PrototypeColors.ink,
        ),
        textTheme: baseTheme.textTheme
            .apply(
              bodyColor: _PrototypeColors.ink,
              displayColor: _PrototypeColors.ink,
            )
            .copyWith(
              displaySmall: baseTheme.textTheme.displaySmall?.copyWith(
                color: _PrototypeColors.ink,
                fontWeight: FontWeight.w900,
                height: 0.98,
                letterSpacing: 0,
              ),
              headlineMedium: baseTheme.textTheme.headlineMedium?.copyWith(
                color: _PrototypeColors.ink,
                fontWeight: FontWeight.w900,
                height: 1.05,
                letterSpacing: 0,
              ),
              titleLarge: baseTheme.textTheme.titleLarge?.copyWith(
                color: _PrototypeColors.ink,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
              labelLarge: baseTheme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          labelStyle: const TextStyle(
            color: _PrototypeColors.aquaDark,
            fontWeight: FontWeight.w800,
          ),
          hintStyle: const TextStyle(color: _PrototypeColors.muted),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _PrototypeColors.line),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: _PrototypeColors.coral,
              width: 1.8,
            ),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 3,
            backgroundColor: _PrototypeColors.coral,
            foregroundColor: Colors.white,
            shadowColor: _PrototypeColors.coral.withValues(alpha: 0.25),
            minimumSize: const Size(48, 48),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(13),
            ),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: _PrototypeColors.ink,
            minimumSize: const Size(48, 48),
            side: const BorderSide(color: _PrototypeColors.line, width: 1.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(13),
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
      ),
      home: const WakeSagaPrototype(),
    );
  }
}

class WakeSagaPrototype extends StatefulWidget {
  const WakeSagaPrototype({super.key});

  @override
  State<WakeSagaPrototype> createState() => _WakeSagaPrototypeState();
}

class _WakeSagaPrototypeState extends State<WakeSagaPrototype> {
  final _promiseController = PageController();
  final _nameController = TextEditingController();
  final _goalController = TextEditingController();
  final _reflectionController = TextEditingController();
  final _lockPromptController = TextEditingController(text: 'deep work block');

  SagaProfile? _profile;
  VoiceArchetype _voice = VoiceArchetype.futureSelf;
  TimeOfDay _wakeTime = const TimeOfDay(hour: 6, minute: 30);
  MissionType _mission = MissionType.deepWork;
  MissionType _lockContext = MissionType.deepWork;
  int _sectionIndex = 0;
  int _promiseIndex = 0;
  int _setupStepIndex = 0;
  int _lockDuration = 90;
  double _playback = 0.18;
  double _moodScore = 4;
  bool _showOnboardingSetup = false;
  bool _showSetupEntrance = true;
  final bool _useWakeQuestPrototypeOnboarding = true;
  bool _scriptGenerated = false;
  bool _alarmScheduled = false;
  bool _episodeSaved = false;
  bool _isPlaying = false;
  bool _wakeGateComplete = false;
  String _setupObstacle = 'warm_bed';
  String _setupRitual = 'object_hunt';
  String _selectedFirstAction = 'Desk';
  String _lockClip = '';
  Timer? _playbackTimer;
  final List<EpisodeCardData> _cards = [];
  final Set<String> _completedActions = {};
  final Map<String, String> _builderAnswers = {
    'morning_identity': 'not_yet',
    'alarm_after': 'snooze_scroll',
    'alarm_count': 'three_plus',
    'one_alarm_confidence': 'with_gate',
    'first_ten': 'phone_vortex',
    'night_feeling': 'quiet_dread',
    'wake_feeling': 'fog',
    'alive_delay': 'thirty',
    'current_wake': 'after_target',
    'target_shift': 'fifteen',
    'rival': 'warm_bed',
    'intensity': 'sharp',
    'wake_quest': 'object_hunt',
    'repeat_days': 'weekdays',
    'jolt_style': 'cinematic',
    'alarm_mode': 'hard_gate',
    'permission_intent': 'allow',
    'commitment': 'sign',
    'streak_style': 'rematch',
    'account_mode': 'save_later',
  };

  static const _sections = <_StageDestination>[
    _StageDestination('Home', Icons.home_rounded),
    _StageDestination('Lock In', Icons.bolt_outlined),
    _StageDestination('Receipts', Icons.style_outlined),
    _StageDestination('Settings', Icons.tune_outlined),
  ];

  static const _wakeQuestIds = <String>[
    'object_hunt',
    'sky_photo',
    'make_bed',
    'pushups',
    'water_check',
    'desk_photo',
    'shoes_on',
    'spoken_vow',
  ];

  static const _promiseFrames = <_OnboardingFrame>[
    _OnboardingFrame(
      number: '01',
      episode: 'COLD OPEN',
      title: 'What if you started your day like an anime character',
      highlight: 'anime character',
      subtitle: 'The city is still asleep. Your future self is already moving.',
      action: 'Roll Opening',
      scene: 0,
      accent: _SagaColors.gold,
      kind: _OnboardingKind.coldOpen,
      assetPath: 'assets/onboarding/opening.png',
    ),
    _OnboardingFrame(
      number: '02',
      episode: 'MISSION BEFORE SLEEP',
      title: 'Tomorrow gets a mission before you sleep',
      highlight: 'mission',
      subtitle: 'Choose the arc. WakeSaga frames the episode.',
      action: 'Next',
      scene: 1,
      accent: _SagaColors.gold,
      kind: _OnboardingKind.titleDrop,
      assetPath: 'assets/onboarding/night_setup.png',
    ),
    _OnboardingFrame(
      number: '03',
      episode: 'OPENING LINE',
      title: 'Your alarm becomes the opening line',
      highlight: 'opening line',
      subtitle: 'A short, urgent jolt. Made just for you.',
      action: 'Next',
      scene: 2,
      accent: _SagaColors.purple,
      kind: _OnboardingKind.alarmCut,
      assetPath: 'assets/onboarding/wake_jolt.png',
    ),
    _OnboardingFrame(
      number: '04',
      episode: 'POWER-UP MONTAGE',
      title: 'One move starts the arc',
      highlight: 'arc',
      subtitle: 'A cinematic episode. One tiny action. Then you move.',
      action: 'Set up my saga',
      scene: 3,
      accent: _SagaColors.purple,
      kind: _OnboardingKind.powerUp,
      assetPath: 'assets/onboarding/morning_arc.png',
    ),
  ];

  @override
  void initState() {
    super.initState();
    if (_previewMainApp) {
      _seedPreviewMainApp();
    }
    _lockClip = _buildLockClip();
  }

  @override
  void dispose() {
    _playbackTimer?.cancel();
    _promiseController.dispose();
    _nameController.dispose();
    _goalController.dispose();
    _reflectionController.dispose();
    _lockPromptController.dispose();
    super.dispose();
  }

  void _seedPreviewMainApp() {
    _profile = SagaProfile(
      name: 'Hero',
      goal: 'Beat warm bed gravity with object hunt',
      voice: _voice,
      wakeTime: _wakeTime,
    );
    _scriptGenerated = true;
    _alarmScheduled = true;
    _wakeGateComplete = false;
    _selectedFirstAction = _defaultFirstAction(_mission);
    _sectionIndex = switch (_previewSection) {
      'lock_in' => 1,
      'receipts' => 2,
      'settings' => 3,
      _ => 0,
    };

    if (_previewState == 'episode') {
      _wakeGateComplete = true;
      _playback = 0.36;
    }

    if (_previewState == 'first_action') {
      _wakeGateComplete = true;
      _playback = 1;
    }

    if (_previewState == 'complete' || _previewSection == 'receipts') {
      _wakeGateComplete = true;
      _playback = 1;
      _episodeSaved = true;
      _completedActions.add(_selectedFirstAction);
      _cards.add(
        EpisodeCardData(
          title: '${_mission.label}: Episode 1',
          mission: _mission.label,
          action: _selectedFirstAction,
          quote: _cardQuote(),
          reflection: 'Started before the old loop got a vote.',
          createdAt: DateTime(2026, 6, 9),
          score: _moodScore.round(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_profile == null) {
      return _buildOnboarding(context);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 920;

        return Scaffold(
          body: Stack(
            children: [
              const Positioned.fill(child: _MainAppBackdrop()),
              SafeArea(
                child: isWide
                    ? Row(
                        children: [
                          _SideNavigation(
                            profile: _profile!,
                            selectedIndex: _sectionIndex,
                            stages: _sections,
                            onSelect: (index) => setState(() {
                              _sectionIndex = index;
                            }),
                          ),
                          Expanded(child: _buildSectionBody(context, isWide)),
                        ],
                      )
                    : Column(
                        children: [
                          _CompactHeader(profile: _profile!),
                          Expanded(child: _buildSectionBody(context, isWide)),
                          _BottomSectionBar(
                            selectedIndex: _sectionIndex,
                            sections: _sections,
                            onSelect: (index) => setState(() {
                              _sectionIndex = index;
                            }),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOnboarding(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 420),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: _useWakeQuestPrototypeOnboarding
                ? _buildWakeQuestPrototypeOnboarding(context)
                : _showOnboardingSetup
                ? _buildOnboardingSetup(context)
                : _buildPromiseSequence(context),
          ),
        ],
      ),
    );
  }

  Widget _buildWakeQuestPrototypeOnboarding(BuildContext context) {
    return _WakeQuestPrototypeOnboarding(
      key: const ValueKey('wake-quest-prototype'),
      controller: _promiseController,
      pageIndex: _promiseIndex,
      selectedEnemy: _setupObstacle,
      selectedQuest: _setupRitual,
      mission: _mission,
      selectedVoice: _voice,
      wakeTime: _wakeTime.format(context),
      nameController: _nameController,
      goalController: _goalController,
      builderAnswers: _builderAnswers,
      onPageChanged: (index) => setState(() {
        _promiseIndex = index;
      }),
      onMissionSelected: (mission) => setState(() {
        _mission = mission;
        _selectedFirstAction = _defaultFirstAction(mission);
      }),
      onVoiceSelected: (voice) => setState(() {
        _voice = voice;
      }),
      onWakeTimePressed: () => _pickWakeTime(context),
      onAnswerSelected: _selectBuilderAnswer,
      onContinue: _advanceWakeQuestPrototype,
    );
  }

  Widget _buildPromiseSequence(BuildContext context) {
    return Stack(
      key: const ValueKey('promise-sequence'),
      children: [
        PageView.builder(
          controller: _promiseController,
          itemCount: _promiseFrames.length,
          onPageChanged: (index) => setState(() {
            _promiseIndex = index;
          }),
          itemBuilder: (context, index) {
            return _PromiseFrameView(
              frame: _promiseFrames[index],
              pageIndex: index,
              totalPages: _promiseFrames.length,
              onPrimaryPressed: _advancePromise,
            );
          },
        ),
      ],
    );
  }

  Widget _buildOnboardingSetup(BuildContext context) {
    return Stack(
      key: const ValueKey('onboarding-setup'),
      children: [
        const Positioned.fill(child: _PersonaBuilderBackdrop()),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  _SagaColors.ink.withValues(alpha: 0.18),
                  _SagaColors.ink.withValues(alpha: 0.48),
                  _SagaColors.ink.withValues(alpha: 0.94),
                ],
              ),
            ),
          ),
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 420),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: _showSetupEntrance
              ? _SagaCalibrationEntrance(
                  key: const ValueKey('setup-entrance'),
                  onComplete: () {
                    if (!mounted) {
                      return;
                    }

                    setState(() {
                      _showSetupEntrance = false;
                    });
                  },
                )
              : _SagaSetupQuiz(
                  key: const ValueKey('setup-quiz'),
                  stepIndex: _setupStepIndex,
                  nameController: _nameController,
                  goalController: _goalController,
                  selectedMission: _mission,
                  selectedVoice: _voice,
                  wakeTime: _wakeTime.format(context),
                  selectedObstacle: _setupObstacle,
                  selectedRitual: _setupRitual,
                  builderAnswers: _builderAnswers,
                  onMissionSelected: (mission) => setState(() {
                    _mission = mission;
                    _selectedFirstAction = _defaultFirstAction(mission);
                  }),
                  onVoiceSelected: (voice) => setState(() {
                    _voice = voice;
                  }),
                  onWakeTimePressed: () => _pickWakeTime(context),
                  onObstacleSelected: (obstacle) => setState(() {
                    _setupObstacle = obstacle;
                  }),
                  onRitualSelected: (ritual) => setState(() {
                    _setupRitual = ritual;
                  }),
                  onAnswerSelected: _selectBuilderAnswer,
                  onBack: _previousSetupStep,
                  onContinue: _advanceSetupStep,
                ),
        ),
      ],
    );
  }

  Widget _buildSectionBody(BuildContext context, bool isWide) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: KeyedSubtree(
        key: ValueKey(_sectionIndex),
        child: Align(
          alignment: Alignment.topCenter,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              isWide ? 40 : 16,
              isWide ? 34 : 8,
              isWide ? 40 : 16,
              isWide ? 34 : 12,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1080),
              child: _sectionForIndex(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionForIndex(BuildContext context) {
    return switch (_sectionIndex) {
      0 => _buildHomeScreen(context),
      1 => _buildLockInScreen(context),
      2 => _buildReceiptsScreen(context),
      _ => _buildSettingsScreen(context),
    };
  }

  Widget _buildHomeScreen(BuildContext context) {
    final profile = _profile!;
    final moment = _homeMoment;
    final showMomentPanel =
        moment != _HomeMoment.openingLocked &&
        moment != _HomeMoment.tomorrowSetup;

    return _ScreenStack(
      eyebrow: _homeEyebrow(moment),
      title: _homeTitle(moment),
      subtitle: _homeSubtitle(moment, profile),
      children: [
        _buildWakeProtocolCard(context, moment, profile),
        if (showMomentPanel) _buildHomeMomentPanel(context, moment),
        if (showMomentPanel) _buildProtocolRail(context),
      ],
    );
  }

  Widget _buildWakeProtocolCard(
    BuildContext context,
    _HomeMoment moment,
    SagaProfile profile,
  ) {
    final secondary = _homeSecondaryActions(context, moment);

    return _Panel(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      _wakeGateComplete
                          ? Icons.lock_open_outlined
                          : Icons.lock_outline,
                      color: _wakeGateComplete
                          ? _SagaColors.success
                          : _PrototypeColors.coral,
                      size: 18,
                    ),
                    const SizedBox(width: 7),
                    Flexible(
                      child: Text(
                        _wakeGateComplete ? 'Episode unlocked' : 'Quest gate',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _PrototypeColors.coral,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _AlarmTimeBadge(time: profile.wakeTime.format(context)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  _wakeQuestLabel(_setupRitual),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _PrototypeColors.ink,
                    fontSize: 28,
                    height: 0.96,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _StatusPill(
                icon: _scriptGenerated
                    ? Icons.graphic_eq
                    : Icons.pending_actions_outlined,
                label: _scriptGenerated ? 'Jolt ready' : 'Needs jolt',
                color: _scriptGenerated
                    ? _SagaColors.success
                    : _PrototypeColors.gold,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _homeMomentCopy(moment),
            style: const TextStyle(
              color: _PrototypeColors.muted,
              fontSize: 13,
              height: 1.28,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          _MiniProtocolTrack(
            steps: [
              _ProtocolStep(
                'Jolt',
                Icons.graphic_eq,
                _scriptGenerated,
                _scriptGenerated && !_wakeGateComplete,
              ),
              _ProtocolStep(
                'Quest',
                Icons.search_outlined,
                _wakeGateComplete,
                !_wakeGateComplete,
              ),
              _ProtocolStep(
                'Episode',
                Icons.play_arrow,
                _playback >= 1,
                _wakeGateComplete && _playback < 1,
              ),
              _ProtocolStep(
                'Action',
                Icons.flag_outlined,
                _episodeSaved,
                _playback >= 1 && !_episodeSaved,
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: _handleHomePrimaryAction,
              icon: Icon(_homePrimaryIcon(moment), size: 18),
              label: Text(_homePrimaryLabel(moment)),
            ),
          ),
          if (secondary.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                for (var i = 0; i < secondary.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(child: secondary[i]),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProtocolRail(BuildContext context) {
    return _ProtocolRail(
      steps: [
        _ProtocolStep(
          'Wake Jolt',
          Icons.graphic_eq,
          _scriptGenerated,
          _scriptGenerated && !_wakeGateComplete && _alarmScheduled,
        ),
        _ProtocolStep(
          'Wake Quest',
          Icons.search_outlined,
          _wakeGateComplete,
          _scriptGenerated && _alarmScheduled && !_wakeGateComplete,
        ),
        _ProtocolStep(
          'Episode',
          Icons.play_circle_outline,
          _playback >= 1,
          _wakeGateComplete && _playback < 1,
        ),
        _ProtocolStep(
          'First Action',
          Icons.flag_outlined,
          _episodeSaved,
          _playback >= 1 && !_episodeSaved,
        ),
        _ProtocolStep(
          'Receipt',
          Icons.style_outlined,
          _cards.isNotEmpty,
          _episodeSaved,
        ),
      ],
    );
  }

  Widget _buildHomeMomentPanel(BuildContext context, _HomeMoment moment) {
    if (moment == _HomeMoment.questCleared ||
        moment == _HomeMoment.episodePlaying) {
      return _Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _SectionLabel(
                    icon: Icons.play_circle_outline,
                    text: _isPlaying ? 'Episode playing' : 'Episode ready',
                  ),
                ),
                Text(
                  '${(_playback * 100).round()}%',
                  style: const TextStyle(
                    color: _PrototypeColors.coral,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: _playback,
                minHeight: 10,
                backgroundColor: _PrototypeColors.line,
                color: _PrototypeColors.coral,
              ),
            ),
            const SizedBox(height: 16),
            _ScriptPreviewLine(text: _buildMorningScript()),
          ],
        ),
      );
    }

    if (moment == _HomeMoment.firstAction) {
      return _Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionLabel(
              icon: Icons.flag_outlined,
              text: 'First action',
            ),
            const SizedBox(height: 14),
            Text(
              _selectedFirstAction,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
                height: 1.05,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _firstActionMicroInstruction(_mission, _selectedFirstAction),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: _PrototypeColors.muted,
                height: 1.34,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    if (moment == _HomeMoment.dayComplete) {
      return _Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionLabel(
              icon: Icons.auto_stories_outlined,
              text: 'End Credits',
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _reflectionController,
              minLines: 2,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'What did today prove?',
                prefixIcon: Icon(Icons.edit_note_outlined),
              ),
            ),
            const SizedBox(height: 16),
            Slider(
              value: _moodScore,
              min: 1,
              max: 5,
              divisions: 4,
              label: _moodScore.round().toString(),
              onChanged: (value) => setState(() {
                _moodScore = value;
              }),
            ),
          ],
        ),
      );
    }

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel(
            icon: Icons.visibility_outlined,
            text: 'Progressive details',
          ),
          const SizedBox(height: 12),
          Text(
            'Your script, mission library, narrator, and advanced alarm controls stay tucked away until you ask for them.',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: _PrototypeColors.muted,
              height: 1.35,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _homeSecondaryActions(BuildContext context, _HomeMoment moment) {
    if (moment == _HomeMoment.questCleared ||
        moment == _HomeMoment.episodePlaying) {
      return [
        OutlinedButton.icon(
          onPressed: _finishEpisode,
          icon: const Icon(Icons.done_all),
          label: const Text('Mark Heard'),
        ),
        OutlinedButton.icon(
          onPressed: () => setState(() {
            _sectionIndex = 1;
          }),
          icon: const Icon(Icons.bolt_outlined),
          label: const Text('Lock In later'),
        ),
      ];
    }

    if (moment == _HomeMoment.firstAction) {
      return [
        OutlinedButton.icon(
          onPressed: _showFirstActionSheet,
          icon: const Icon(Icons.swap_horiz),
          label: const Text('Swap Action'),
        ),
        OutlinedButton.icon(
          onPressed: () => setState(() {
            _sectionIndex = 1;
          }),
          icon: const Icon(Icons.bolt_outlined),
          label: const Text('Lock In'),
        ),
      ];
    }

    if (moment == _HomeMoment.dayComplete) {
      return [
        OutlinedButton.icon(
          onPressed: () => setState(() {
            _sectionIndex = 2;
          }),
          icon: const Icon(Icons.style_outlined),
          label: const Text('View Receipt'),
        ),
        OutlinedButton.icon(
          onPressed: _showMissionSheet,
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Change Tomorrow'),
        ),
      ];
    }

    return [
      OutlinedButton.icon(
        onPressed: _showMissionSheet,
        icon: const Icon(Icons.flag_outlined, size: 16),
        label: const Text('Mission'),
      ),
      OutlinedButton.icon(
        onPressed: _showWakeQuestSheet,
        icon: const Icon(Icons.search_outlined, size: 16),
        label: const Text('Quest'),
      ),
    ];
  }

  Widget _buildLockInScreen(BuildContext context) {
    final visibleModes = [
      MissionType.study,
      MissionType.gym,
      MissionType.deepWork,
      MissionType.recovery,
    ];

    return _ScreenStack(
      eyebrow: 'Lock In',
      title: 'Hard-task clip',
      subtitle: 'Type the avoided thing. Generate the jolt. Move.',
      children: [
        _Panel(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _lockPromptController,
                style: const TextStyle(
                  color: _PrototypeColors.ink,
                  fontWeight: FontWeight.w800,
                ),
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 11,
                  ),
                  labelText: 'What are you avoiding?',
                  prefixIcon: Icon(Icons.edit_outlined, size: 18),
                ),
                onChanged: (_) => setState(() {
                  _lockClip = _buildLockClip();
                }),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final mode in visibleModes)
                    _LockChip(
                      label: mode.label,
                      icon: mode.icon,
                      selected: _lockContext == mode,
                      onTap: () => setState(() {
                        _lockContext = mode;
                        _lockClip = _buildLockClip();
                      }),
                    ),
                  _LockChip(
                    label: 'More',
                    icon: Icons.more_horiz,
                    selected: false,
                    onTap: () => _showMissionSheet(forLockIn: true),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  for (final value in const [30, 90, 180]) ...[
                    if (value != 30) const SizedBox(width: 6),
                    Expanded(
                      child: _LockDurationButton(
                        label: value == 30
                            ? '30s'
                            : value == 90
                            ? '90s'
                            : '3m',
                        selected: _lockDuration == value,
                        onTap: () => setState(() {
                          _lockDuration = value;
                          _lockClip = _buildLockClip();
                        }),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: () => setState(() {
                    _lockClip = _buildLockClip(refresh: true);
                  }),
                  icon: const Icon(Icons.bolt_outlined, size: 18),
                  label: const Text('Generate Lock In'),
                ),
              ),
            ],
          ),
        ),
        _Panel(
          padding: const EdgeInsets.fromLTRB(14, 11, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.graphic_eq,
                    size: 16,
                    color: _PrototypeColors.aquaDark,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Latest clip',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: _PrototypeColors.aquaDark,
                      fontSize: 11,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: _PrototypeColors.muted,
                      minimumSize: const Size(36, 30),
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: _showVoiceSheet,
                    icon: Icon(_voice.icon, size: 14),
                    label: Text(
                      _voice.label,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 7),
              _ScriptBlock(text: _lockClip, compact: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReceiptsScreen(BuildContext context) {
    return _ScreenStack(
      eyebrow: 'Receipts',
      title: _cards.isEmpty ? 'No receipts yet' : 'Morning proof',
      subtitle: _cards.isEmpty
          ? 'Complete the daily loop and WakeSaga will save the first card.'
          : '${_cards.length} saved ${_cards.length == 1 ? 'receipt' : 'receipts'} from this saga.',
      children: [
        if (_cards.isEmpty)
          _Panel(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _EmptyMark(),
                const SizedBox(height: 12),
                Text(
                  'Your first receipt appears after the Wake Quest, Morning Episode, and first action.',
                  style: const TextStyle(
                    color: _PrototypeColors.muted,
                    height: 1.32,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: () => setState(() {
                      _sectionIndex = 0;
                    }),
                    icon: const Icon(Icons.home_rounded, size: 18),
                    label: const Text('Go Home'),
                  ),
                ),
              ],
            ),
          )
        else ...[
          _ReceiptSummaryStrip(
            count: _cards.length,
            action: _cards.last.action,
            score: _cards.last.score,
          ),
          _EpisodeCard(card: _cards.last),
          if (_cards.length > 1)
            _Panel(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Text(
                '${_cards.length - 1} older ${_cards.length == 2 ? 'receipt' : 'receipts'} tucked below.',
                style: const TextStyle(
                  color: _PrototypeColors.muted,
                  fontWeight: FontWeight.w800,
                  height: 1.28,
                ),
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildSettingsScreen(BuildContext context) {
    final wakeQuest = _wakeQuestLabel(_setupRitual);

    return _ScreenStack(
      eyebrow: 'Settings',
      title: 'Defaults',
      subtitle: 'Set it once. Return to the daily loop.',
      children: [
        _SettingsGroup(
          tiles: [
            _SettingsTile(
              icon: Icons.alarm_on_outlined,
              title: 'Alarm',
              value: _wakeTime.format(context),
              onTap: () => _pickWakeTime(context),
            ),
            _SettingsTile(
              icon: Icons.search_outlined,
              title: 'Wake Quest',
              value: wakeQuest,
              onTap: _showWakeQuestSheet,
            ),
            _SettingsTile(
              icon: _mission.icon,
              title: 'Mission default',
              value: _mission.label,
              onTap: _showMissionSheet,
            ),
            _SettingsTile(
              icon: _voice.icon,
              title: 'Voice',
              value: _voice.label,
              onTap: _showVoiceSheet,
            ),
          ],
        ),
        _SettingsGroup(
          tiles: [
            _SettingsTile(
              icon: Icons.person_outline,
              title: 'Account',
              value: 'Prototype profile',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Account settings are a later surface.'),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  _HomeMoment get _homeMoment {
    if (!_scriptGenerated || !_alarmScheduled) {
      return _HomeMoment.tomorrowSetup;
    }

    if (!_wakeGateComplete) {
      return _HomeMoment.openingLocked;
    }

    if (_playback < 1) {
      return _isPlaying ? _HomeMoment.episodePlaying : _HomeMoment.questCleared;
    }

    if (!_episodeSaved) {
      return _HomeMoment.firstAction;
    }

    return _HomeMoment.dayComplete;
  }

  String _homeEyebrow(_HomeMoment moment) {
    return switch (moment) {
      _HomeMoment.tomorrowSetup => 'Tonight setup',
      _HomeMoment.openingLocked => 'Next scene',
      _HomeMoment.questCleared => 'Quest cleared',
      _HomeMoment.episodePlaying => 'Morning episode',
      _HomeMoment.firstAction => 'First action',
      _HomeMoment.dayComplete => 'End Credits',
    };
  }

  String _homeTitle(_HomeMoment moment) {
    return switch (moment) {
      _HomeMoment.tomorrowSetup => 'Tomorrow\'s Opening',
      _HomeMoment.openingLocked => 'Opening Locked',
      _HomeMoment.questCleared => 'Episode Unlocked',
      _HomeMoment.episodePlaying => 'Morning Episode',
      _HomeMoment.firstAction => 'Start the first move',
      _HomeMoment.dayComplete => 'Close today cleanly',
    };
  }

  String _homeSubtitle(_HomeMoment moment, SagaProfile profile) {
    final quest = _wakeQuestLabel(_setupRitual).toLowerCase();

    return switch (moment) {
      _HomeMoment.tomorrowSetup =>
        '${profile.name}, set one clear scene before sleep.',
      _HomeMoment.openingLocked => 'Clear $quest to open the episode.',
      _HomeMoment.questCleared =>
        'Proof complete. Start the Morning Episode while the room is awake.',
      _HomeMoment.episodePlaying =>
        'Keep listening. The first action is already selected.',
      _HomeMoment.firstAction =>
        'One tiny move turns the episode into momentum.',
      _HomeMoment.dayComplete =>
        'Save the lesson, then prep tomorrow without making today heavy.',
    };
  }

  String _homeMomentCopy(_HomeMoment moment) {
    final quest = _wakeQuestLabel(_setupRitual);

    return switch (moment) {
      _HomeMoment.tomorrowSetup =>
        'Choose the mission, Wake Quest, and voice. Everything else stays tucked away.',
      _HomeMoment.openingLocked =>
        '$quest is armed. When the alarm fires, this is the only move that matters.',
      _HomeMoment.questCleared =>
        '$quest cleared. The Morning Episode is ready.',
      _HomeMoment.episodePlaying =>
        'Episode in progress. Your first move is $_selectedFirstAction.',
      _HomeMoment.firstAction =>
        'Start with $_selectedFirstAction. Keep it small, physical, and immediate.',
      _HomeMoment.dayComplete =>
        'Receipt saved. Close the loop and let tomorrow inherit the useful parts.',
    };
  }

  String _homePrimaryLabel(_HomeMoment moment) {
    return switch (moment) {
      _HomeMoment.tomorrowSetup =>
        _scriptGenerated ? 'Lock Tomorrow\'s Opening' : 'Generate Wake Jolt',
      _HomeMoment.openingLocked => 'Clear ${_wakeQuestLabel(_setupRitual)}',
      _HomeMoment.questCleared => 'Play Morning Episode',
      _HomeMoment.episodePlaying => _isPlaying ? 'Pause Episode' : 'Continue',
      _HomeMoment.firstAction => 'Mark First Action Done',
      _HomeMoment.dayComplete => 'Prep Tomorrow',
    };
  }

  IconData _homePrimaryIcon(_HomeMoment moment) {
    return switch (moment) {
      _HomeMoment.tomorrowSetup =>
        _scriptGenerated ? Icons.nights_stay_outlined : Icons.graphic_eq,
      _HomeMoment.openingLocked => Icons.task_alt,
      _HomeMoment.questCleared => Icons.play_arrow,
      _HomeMoment.episodePlaying => _isPlaying ? Icons.pause : Icons.play_arrow,
      _HomeMoment.firstAction => Icons.check_circle_outline,
      _HomeMoment.dayComplete => Icons.nights_stay_outlined,
    };
  }

  void _handleHomePrimaryAction() {
    final moment = _homeMoment;

    switch (moment) {
      case _HomeMoment.tomorrowSetup:
        if (_scriptGenerated) {
          _stageAlarm();
        } else {
          _generateTomorrowEpisode();
        }
        return;
      case _HomeMoment.openingLocked:
        _completeWakeGate();
        return;
      case _HomeMoment.questCleared:
      case _HomeMoment.episodePlaying:
        _togglePlayback();
        return;
      case _HomeMoment.firstAction:
        _completeFirstAction();
        return;
      case _HomeMoment.dayComplete:
        _closeCredits();
        return;
    }
  }

  void _finishEpisode() {
    _playbackTimer?.cancel();
    setState(() {
      _playback = 1;
      _isPlaying = false;
    });
  }

  void _showMissionSheet({bool forLockIn = false}) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: _PrototypeColors.paper,
      builder: (sheetContext) {
        return _SelectionSheet<MissionType>(
          title: forLockIn ? 'Choose Lock In mode' : 'Choose mission',
          values: MissionType.values,
          selected: forLockIn ? _lockContext : _mission,
          labelFor: (mission) => mission.label,
          descriptionFor: _missionMicrocopy,
          iconFor: (mission) => mission.icon,
          onSelected: (mission) {
            setState(() {
              if (forLockIn) {
                _lockContext = mission;
                _lockClip = _buildLockClip();
              } else {
                _mission = mission;
                _selectedFirstAction = _defaultFirstAction(mission);
                _scriptGenerated = false;
                _alarmScheduled = false;
                _episodeSaved = false;
                _wakeGateComplete = false;
                _completedActions.clear();
                _playback = 0.18;
              }
            });
            Navigator.of(sheetContext).pop();
          },
        );
      },
    );
  }

  void _showWakeQuestSheet() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: _PrototypeColors.paper,
      builder: (sheetContext) {
        return _SelectionSheet<String>(
          title: 'Choose Wake Quest',
          values: _wakeQuestIds,
          selected: _setupRitual,
          labelFor: _wakeQuestLabel,
          descriptionFor: _wakeQuestDescription,
          iconFor: _wakeQuestIcon,
          onSelected: (quest) {
            setState(() {
              _setupRitual = quest;
              _wakeGateComplete = false;
              _episodeSaved = false;
              _playback = 0.18;
            });
            Navigator.of(sheetContext).pop();
          },
        );
      },
    );
  }

  void _showVoiceSheet() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: _PrototypeColors.paper,
      builder: (sheetContext) {
        return _SelectionSheet<VoiceArchetype>(
          title: 'Choose narrator',
          values: VoiceArchetype.values,
          selected: _voice,
          labelFor: (voice) => voice.label,
          descriptionFor: _voiceMicrocopy,
          iconFor: (voice) => voice.icon,
          onSelected: (voice) {
            setState(() {
              _voice = voice;
              _lockClip = _buildLockClip();
            });
            Navigator.of(sheetContext).pop();
          },
        );
      },
    );
  }

  void _showFirstActionSheet() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: _PrototypeColors.paper,
      builder: (sheetContext) {
        return _SelectionSheet<String>(
          title: 'Swap first action',
          values: _mission.actions,
          selected: _selectedFirstAction,
          labelFor: (action) => action,
          descriptionFor: (_) => 'Tiny enough to start before the old loop.',
          iconFor: (_) => Icons.flag_outlined,
          onSelected: (action) {
            setState(() {
              _selectedFirstAction = action;
            });
            Navigator.of(sheetContext).pop();
          },
        );
      },
    );
  }

  Future<void> _pickWakeTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _wakeTime,
    );

    if (!mounted || picked == null) {
      return;
    }

    setState(() {
      _wakeTime = picked;
    });
  }

  void _advancePromise() {
    if (_promiseIndex == _promiseFrames.length - 1) {
      setState(() {
        _showOnboardingSetup = true;
        _showSetupEntrance = true;
        _setupStepIndex = 0;
      });
      return;
    }

    _promiseController.nextPage(
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutCubic,
    );
  }

  void _advanceWakeQuestPrototype() {
    if (_promiseIndex == _WakeQuestPrototypeOnboarding.totalPages - 1) {
      _completeOnboarding();
      return;
    }

    HapticFeedback.selectionClick();
    _promiseController.nextPage(
      duration: const Duration(milliseconds: 430),
      curve: Curves.easeOutCubic,
    );
  }

  void _advanceSetupStep() {
    if (_setupStepIndex == _sagaSetupSteps.length - 1) {
      _completeOnboarding();
      return;
    }

    HapticFeedback.selectionClick();
    setState(() {
      _setupStepIndex += 1;
    });
  }

  void _previousSetupStep() {
    if (_setupStepIndex == 0) {
      return;
    }

    HapticFeedback.selectionClick();
    setState(() {
      _setupStepIndex -= 1;
    });
  }

  void _selectBuilderAnswer(String stepId, String optionId) {
    HapticFeedback.selectionClick();
    setState(() {
      _builderAnswers[stepId] = optionId;

      if (stepId == 'rival' || stepId == 'first_ten') {
        _setupObstacle = optionId;
      }

      if (stepId == 'wake_quest') {
        _setupRitual = optionId;
      }
    });
  }

  void _completeOnboarding() {
    final name = _nameController.text.trim().isEmpty
        ? 'Hero'
        : _nameController.text.trim();
    final goal = _goalController.text.trim().isEmpty
        ? '${_mission.label}: beat ${_setupObstacleLabel(_setupObstacle).toLowerCase()} with ${_wakeQuestLabel(_setupRitual).toLowerCase()}'
        : _goalController.text.trim();

    setState(() {
      _profile = SagaProfile(
        name: name,
        goal: goal,
        voice: _voice,
        wakeTime: _wakeTime,
      );
      _scriptGenerated = true;
      _alarmScheduled = true;
      _wakeGateComplete = false;
      _selectedFirstAction = _defaultFirstAction(_mission);
      _sectionIndex = 0;
      _showOnboardingSetup = false;
      _showSetupEntrance = true;
      _setupStepIndex = 0;
    });
  }

  void _generateTomorrowEpisode() {
    setState(() {
      _scriptGenerated = true;
      _alarmScheduled = false;
      _episodeSaved = false;
      _wakeGateComplete = false;
      _completedActions.clear();
      _playback = 0.18;
      _sectionIndex = 0;
    });
  }

  void _stageAlarm() {
    setState(() {
      _alarmScheduled = true;
      _wakeGateComplete = false;
    });
  }

  void _completeWakeGate() {
    setState(() {
      _wakeGateComplete = true;
      _sectionIndex = 0;
    });
  }

  void _togglePlayback() {
    if (_isPlaying) {
      _playbackTimer?.cancel();
      setState(() {
        _isPlaying = false;
      });
      return;
    }

    setState(() {
      _isPlaying = true;
      if (_playback >= 1) {
        _playback = 0;
      }
    });

    _playbackTimer?.cancel();
    _playbackTimer = Timer.periodic(const Duration(milliseconds: 600), (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _playback = math.min(1, _playback + 0.055);
        if (_playback >= 1) {
          _isPlaying = false;
          _playbackTimer?.cancel();
        }
      });
    });
  }

  void _completeFirstAction() {
    setState(() {
      _completedActions.add(_selectedFirstAction);
      if (!_episodeSaved) {
        _cards.add(
          EpisodeCardData(
            title: '${_mission.label}: Episode ${_cards.length + 1}',
            mission: _mission.label,
            action: _selectedFirstAction,
            quote: _cardQuote(),
            reflection: '',
            createdAt: DateTime.now(),
            score: _moodScore.round(),
          ),
        );
        _episodeSaved = true;
      }
      _sectionIndex = 2;
    });
  }

  void _closeCredits() {
    final note = _reflectionController.text.trim();

    setState(() {
      if (_cards.isNotEmpty && note.isNotEmpty) {
        final last = _cards.removeLast();
        _cards.add(last.copyWith(reflection: note, score: _moodScore.round()));
      }

      _scriptGenerated = false;
      _alarmScheduled = false;
      _episodeSaved = false;
      _wakeGateComplete = false;
      _completedActions.clear();
      _selectedFirstAction = _defaultFirstAction(_mission);
      _reflectionController.clear();
      _isPlaying = false;
      _playbackTimer?.cancel();
      _playback = 0.18;
      _sectionIndex = 0;
    });
  }

  String _buildMorningScript() {
    final profile = _profile!;
    final voiceLine = profile.voice.promptLine;

    return '$voiceLine ${profile.name}, today is ${_mission.label.toLowerCase()}. '
        'Your goal is ${profile.goal}. The obstacle is the soft start: checking, drifting, negotiating. '
        'Your counter is physical and immediate. Complete ${_selectedFirstAction.toLowerCase()}, '
        'then give the first ten minutes to the person you said you were becoming.';
  }

  String _buildLockClip({bool refresh = false}) {
    final profile = _profile;
    final name = profile?.name ?? 'Hero';
    final moment = _lockPromptController.text.trim().isEmpty
        ? 'this block'
        : _lockPromptController.text.trim();
    final pressure = refresh ? 'Reset the room.' : 'Make the room smaller.';

    return '$name, $_lockDuration seconds is enough to cross the line. '
        '$pressure This is ${_lockContext.label.toLowerCase()} mode: one target, one timer, one clean rep. '
        'Start $moment before the feeling catches up.';
  }

  String _cardQuote() {
    return switch (_mission) {
      MissionType.study => 'First page before first excuse.',
      MissionType.gym => 'Shoes on. Story changed.',
      MissionType.deepWork => 'The day opened with focus.',
      MissionType.comeback => 'A setback became a rematch.',
      MissionType.monkMode => 'Silence did the heavy lifting.',
      MissionType.recovery => 'Recovery counted because it was chosen.',
    };
  }
}

enum VoiceArchetype {
  sensei,
  rival,
  captain,
  futureSelf,
  innerDemon;

  String get label {
    return switch (this) {
      VoiceArchetype.sensei => 'Sensei',
      VoiceArchetype.rival => 'Rival',
      VoiceArchetype.captain => 'Captain',
      VoiceArchetype.futureSelf => 'Future Self',
      VoiceArchetype.innerDemon => 'Inner Demon',
    };
  }

  String get promptLine {
    return switch (this) {
      VoiceArchetype.sensei => 'Breathe once, then begin.',
      VoiceArchetype.rival => 'Someone else is already moving.',
      VoiceArchetype.captain => 'Lock formation and execute.',
      VoiceArchetype.futureSelf =>
        'I remember this morning because you did not fold.',
      VoiceArchetype.innerDemon =>
        'The easy version of you does not get the wheel.',
    };
  }

  IconData get icon {
    return switch (this) {
      VoiceArchetype.sensei => Icons.spa_outlined,
      VoiceArchetype.rival => Icons.sports_mma_outlined,
      VoiceArchetype.captain => Icons.shield_outlined,
      VoiceArchetype.futureSelf => Icons.auto_awesome_outlined,
      VoiceArchetype.innerDemon => Icons.local_fire_department_outlined,
    };
  }
}

enum MissionType {
  study,
  gym,
  deepWork,
  comeback,
  monkMode,
  recovery;

  String get label {
    return switch (this) {
      MissionType.study => 'Study',
      MissionType.gym => 'Gym',
      MissionType.deepWork => 'Deep Work',
      MissionType.comeback => 'Comeback',
      MissionType.monkMode => 'Monk Mode',
      MissionType.recovery => 'Recovery',
    };
  }

  String get wakeLine {
    return switch (this) {
      MissionType.study => 'Open the page before the mind opens the exit.',
      MissionType.gym => 'Feet to floor, shoes on, body first.',
      MissionType.deepWork => 'Protect the first block like it matters.',
      MissionType.comeback => 'Yesterday does not get the final edit.',
      MissionType.monkMode => 'No noise. No feed. Just the rep.',
      MissionType.recovery =>
        'Move gently, recover on purpose, keep the promise.',
    };
  }

  IconData get icon {
    return switch (this) {
      MissionType.study => Icons.menu_book_outlined,
      MissionType.gym => Icons.fitness_center,
      MissionType.deepWork => Icons.data_object,
      MissionType.comeback => Icons.replay_circle_filled_outlined,
      MissionType.monkMode => Icons.do_not_disturb_on_outlined,
      MissionType.recovery => Icons.self_improvement_outlined,
    };
  }

  String get crestAsset {
    return switch (this) {
      MissionType.study => 'assets/onboarding/crest_study.png',
      MissionType.gym => 'assets/onboarding/crest_gym.png',
      MissionType.deepWork => 'assets/onboarding/crest_deep_work.png',
      MissionType.comeback => 'assets/onboarding/crest_comeback.png',
      MissionType.monkMode => 'assets/onboarding/crest_monk_mode.png',
      MissionType.recovery => 'assets/onboarding/crest_recovery.png',
    };
  }

  List<String> get actions {
    return switch (this) {
      MissionType.study => ['Water', 'First page', '25-minute timer'],
      MissionType.gym => ['Water', 'Shoes', 'Warm-up set'],
      MissionType.deepWork => ['Water', 'Desk', '25-minute timer'],
      MissionType.comeback => ['Water', 'Clean slate', 'One small win'],
      MissionType.monkMode => ['Phone away', 'Desk', 'First page'],
      MissionType.recovery => ['Water', 'Walk', 'Breathing set'],
    };
  }
}

Color _missionAccent(MissionType mission) {
  return switch (mission) {
    MissionType.study => _SagaColors.cyan,
    MissionType.gym => _SagaColors.lime,
    MissionType.deepWork => const Color(0xFFFFB56A),
    MissionType.comeback => _SagaColors.purple,
    MissionType.monkMode => _SagaColors.gold,
    MissionType.recovery => const Color(0xFF7BA7FF),
  };
}

String _missionMicrocopy(MissionType mission) {
  return switch (mission) {
    MissionType.study => 'Level Up',
    MissionType.gym => 'Get Stronger',
    MissionType.deepWork => 'Build Mastery',
    MissionType.comeback => 'Rewrite The Arc',
    MissionType.monkMode => 'Discipline First',
    MissionType.recovery => 'Heal & Rise',
  };
}

String _defaultFirstAction(MissionType mission) {
  return switch (mission) {
    MissionType.study => 'First page',
    MissionType.gym => 'Shoes',
    MissionType.deepWork => 'Desk',
    MissionType.comeback => 'One small win',
    MissionType.monkMode => 'Desk',
    MissionType.recovery => 'Walk',
  };
}

String _firstActionMicroInstruction(MissionType mission, String action) {
  final lower = action.toLowerCase();
  if (lower.contains('desk')) {
    return 'Open the laptop and write the first line.';
  }
  if (lower.contains('shoes')) {
    return 'Shoes on. One step out the door is enough.';
  }
  if (lower.contains('water')) {
    return 'Drink a full glass before anything else.';
  }
  if (lower.contains('page')) {
    return 'Open the book to the first unread page.';
  }
  if (lower.contains('walk')) {
    return 'Five-minute walk. Daylight on your face.';
  }
  if (lower.contains('timer')) {
    return 'Start the timer. Decide later, move now.';
  }
  if (lower.contains('phone away')) {
    return 'Phone face-down in another room.';
  }
  if (lower.contains('warm')) {
    return 'One easy warm-up set. Light, no ego.';
  }
  if (lower.contains('clean slate')) {
    return 'Reset the desk. Yesterday does not move with you.';
  }
  if (lower.contains('small win')) {
    return 'Pick the smallest possible win and finish it.';
  }
  if (lower.contains('breathing')) {
    return 'Three slow breaths. In four, out six.';
  }
  return 'Keep it small enough to start before the old loop wakes up.';
}

String _voiceMicrocopy(VoiceArchetype voice) {
  return switch (voice) {
    VoiceArchetype.sensei => 'Calm & Wise',
    VoiceArchetype.rival => 'Sharp & Competitive',
    VoiceArchetype.captain => 'Commanding Leader',
    VoiceArchetype.futureSelf => 'Proud & Personal',
    VoiceArchetype.innerDemon => 'Intense & Relentless',
  };
}

String _setupObstacleLabel(String id) {
  return switch (id) {
    'phone_vortex' => 'Phone vortex',
    'warm_bed' => 'Warm bed gravity',
    'late_start' => 'Late start panic',
    'low_mood' => 'Low-mood fog',
    _ => 'Warm bed gravity',
  };
}

String _wakeQuestLabel(String id) {
  return switch (id) {
    'object_hunt' => 'Object Hunt',
    'make_bed' => 'Make Bed',
    'shoes_on' => 'Shoes On',
    'desk_photo' => 'Desk photo',
    'sky_photo' => 'Sky photo',
    'water_check' => 'Water Check',
    'pushups' => 'Pushups',
    'spoken_vow' => 'Spoken vow',
    _ => 'Object Hunt',
  };
}

String _wakeQuestDescription(String id) {
  return switch (id) {
    'object_hunt' => 'Find a random object so your eyes and body engage.',
    'make_bed' => 'Change the sleep space before the bed pulls you back.',
    'shoes_on' => 'Put shoes on and make movement the default.',
    'desk_photo' => 'Prove your work setup is open before scrolling starts.',
    'sky_photo' => 'Face daylight and take a proof photo.',
    'water_check' => 'Drink water and create a physical wake cue.',
    'pushups' => 'Use quick movement to cut through sleep inertia.',
    'spoken_vow' => 'Say the first promise out loud before the day negotiates.',
    _ => 'Find a random object so your eyes and body engage.',
  };
}

IconData _wakeQuestIcon(String id) {
  return switch (id) {
    'object_hunt' => Icons.search_outlined,
    'make_bed' => Icons.bed_outlined,
    'shoes_on' => Icons.directions_run,
    'desk_photo' => Icons.desktop_mac_outlined,
    'sky_photo' => Icons.wb_sunny_outlined,
    'water_check' => Icons.water_drop_outlined,
    'pushups' => Icons.fitness_center,
    'spoken_vow' => Icons.record_voice_over_outlined,
    _ => Icons.search_outlined,
  };
}

String _optionLabelFor(String stepId, String? optionId) {
  if (optionId == null) {
    return 'Not selected';
  }

  for (final step in _sagaSetupSteps) {
    if (step.id != stepId) {
      continue;
    }

    for (final option in step.options) {
      if (option.id == optionId) {
        return option.label;
      }
    }
  }

  return optionId;
}

Color _viralChoiceAccent(int index, Color fallback) {
  final palette = [
    fallback,
    _SagaColors.cyan,
    _SagaColors.lime,
    _SagaColors.purple,
    _SagaColors.signal,
    _SagaColors.gold,
  ];

  return palette[index % palette.length];
}

Color _voiceAccent(VoiceArchetype voice) {
  return switch (voice) {
    VoiceArchetype.sensei => _SagaColors.cyan,
    VoiceArchetype.rival => _SagaColors.lime,
    VoiceArchetype.captain => _SagaColors.gold,
    VoiceArchetype.futureSelf => _SagaColors.signal,
    VoiceArchetype.innerDemon => _SagaColors.purple,
  };
}

String _episodeNumberForStep(String id) {
  final index = _sagaSetupSteps.indexWhere((step) => step.id == id);
  return (index + 1).toString().padLeft(2, '0');
}

String _socialChapterLabel(String chapter) {
  if (chapter.startsWith('DIAGNOSIS')) {
    return 'morning profile';
  }
  if (chapter.startsWith('SYSTEM BRIEFING')) {
    return 'how it works';
  }
  if (chapter.startsWith('PLAN PROOF')) {
    return 'plan update';
  }
  if (chapter.startsWith('TIME SCAN')) {
    return 'wake time';
  }
  if (chapter.startsWith('SAGA BUILD')) {
    return 'build the arc';
  }
  if (chapter.startsWith('WAKE QUEST')) {
    return 'wake quest';
  }
  if (chapter == 'REWARD PREVIEW') {
    return 'wake receipt';
  }
  if (chapter == 'RETENTION RULES') {
    return 'rematch rules';
  }
  if (chapter.startsWith('SAVE FILE')) {
    return 'save profile';
  }
  if (chapter == 'SAGA PASS') {
    return 'saga pass';
  }
  return chapter.toLowerCase();
}

IconData _iconForSetupStep(_SagaSetupStep step) {
  return switch (step.kind) {
    _SagaSetupStepKind.mission => Icons.workspace_premium_outlined,
    _SagaSetupStepKind.goal => Icons.flag_outlined,
    _SagaSetupStepKind.wakeTime => Icons.alarm_on_outlined,
    _SagaSetupStepKind.voice => Icons.record_voice_over_outlined,
    _SagaSetupStepKind.loadingChecklist => Icons.auto_awesome_motion_outlined,
    _SagaSetupStepKind.planReveal => Icons.map_outlined,
    _SagaSetupStepKind.receiptPreview => Icons.receipt_long_outlined,
    _SagaSetupStepKind.paywall => Icons.workspace_premium_outlined,
    _SagaSetupStepKind.review => Icons.verified_outlined,
    _ => step.options.isEmpty ? Icons.bolt_outlined : step.options.first.icon,
  };
}

String _guideLineForStep(_SagaSetupStep step) {
  return switch (step.kind) {
    _SagaSetupStepKind.mission =>
      'Mika: pick the arc your future self would flex.',
    _SagaSetupStepKind.goal => 'Future you: make the win easy to screenshot.',
    _SagaSetupStepKind.voice =>
      'Yui: who should talk you out of the snooze spiral?',
    _SagaSetupStepKind.wakeTime =>
      'Kai: this is when Episode 001 pings your lock screen.',
    _SagaSetupStepKind.loadingChecklist =>
      'WakeSaga: mixing your jolt, quest, episode, and receipt.',
    _SagaSetupStepKind.planReveal =>
      'Mika: your morning profile is turning into a plan.',
    _SagaSetupStepKind.receiptPreview =>
      'Yui: make the first win shareable, even if you keep it private.',
    _SagaSetupStepKind.paywall =>
      'WakeSaga: choose the pass once, then Episode 001 is ready.',
    _SagaSetupStepKind.review =>
      'Kai: Episode 001 is ready. Save the morning profile.',
    _ =>
      step.id == 'first_ten' || step.id == 'rival'
          ? 'Mika: name the tiny villain before it steals the opening scene.'
          : 'Yui: answer fast. The saga gets better when it sounds like you.',
  };
}

String _personaQuestionForStep(_SagaSetupStep step) {
  return switch (step.id) {
    'morning_identity' => 'Pick your wake persona',
    'alarm_after' => 'Be honest. After your alarm, you usually...',
    'alarm_count' => 'How many alarms are in the stack?',
    'one_alarm_confidence' => 'Could one alarm actually work?',
    'first_ten' => 'What steals your first 10 minutes?',
    'snooze_loop' => 'The snooze loop is built to win',
    'old_loop' => 'Old loop vs saga loop',
    'night_feeling' => 'Night-you feels...',
    'wake_feeling' => 'Morning-you wakes up...',
    'alive_delay' => 'How long until you feel human?',
    'sleep_inertia' => 'Biology, not weakness',
    'body_before_brain' => 'Body first. Brain second.',
    'current_wake' => 'When do you really get up?',
    'target_wake' => 'When should Episode 001 start?',
    'target_shift' => 'How much time are we winning back?',
    'time_gain' => 'The first win is time',
    'title_card' => 'Win the opening. Change the episode.',
    'mission' => 'Choose tomorrow\'s arc',
    'goal' => 'What are you training for?',
    'rival' => 'Name your morning rival',
    'voice' => 'Choose the narrator',
    'intensity' => 'Set the jolt pressure',
    'episode_formula' => 'Mission + rival + first move',
    'rival_detected' => 'Rival detected',
    'wake_quest' => 'Choose your Wake Quest',
    'quest_explain' => 'Why this quest works',
    'first_alarm_time' => 'Set your first wake time',
    'repeat_days' => 'Which days should it ring?',
    'jolt_style' => 'Pick the wake jolt style',
    'jolt_preview' => 'Preview the opening line',
    'alarm_mode' => 'How should the quest behave?',
    'permission_primer' => 'Let the opening scene fire',
    'permission_intent' => 'When the prompt appears...',
    'commitment' => 'Sign tomorrow\'s opening contract',
    'rendering' => 'Rendering Episode 001',
    'plan_reveal' => 'Your morning episode plan',
    'timeline' => 'Tomorrow\'s opening sequence',
    'receipt_preview' => 'Your first Wake Receipt',
    'streak_style' => 'If you miss, what happens?',
    'identity' => 'Save your saga',
    'account_mode' => 'How should we save it?',
    'paywall_intro' => 'Your Episode 001 is ready',
    'review' => 'Episode 001 is ready',
    _ =>
      step.title
          .replaceAll('\n', ' ')
          .toLowerCase()
          .replaceFirstMapped(
            RegExp(r'^[a-z]'),
            (match) => match[0]!.toUpperCase(),
          ),
  };
}

String _personaChapterForStep(_SagaSetupStep step) {
  return switch (step.kind) {
    _SagaSetupStepKind.identity => 'save file',
    _SagaSetupStepKind.mission => 'arc picker',
    _SagaSetupStepKind.goal => 'victory condition',
    _SagaSetupStepKind.wakeTime => 'alarm window',
    _SagaSetupStepKind.voice => 'voice cast',
    _SagaSetupStepKind.loadingChecklist => 'rendering',
    _SagaSetupStepKind.planReveal => 'blueprint',
    _SagaSetupStepKind.receiptPreview => 'wake receipt',
    _SagaSetupStepKind.paywall => 'saga pass',
    _SagaSetupStepKind.review => 'ready screen',
    _ => _socialChapterLabel(step.chapter),
  };
}

String _previewJoltLine(
  VoiceArchetype voice,
  MissionType mission,
  String quest,
) {
  return '${voice.promptLine} ${mission.wakeLine} Clear ${_wakeQuestLabel(quest).toLowerCase()} and unlock the episode.';
}

class SagaProfile {
  const SagaProfile({
    required this.name,
    required this.goal,
    required this.voice,
    required this.wakeTime,
  });

  final String name;
  final String goal;
  final VoiceArchetype voice;
  final TimeOfDay wakeTime;
}

class EpisodeCardData {
  const EpisodeCardData({
    required this.title,
    required this.mission,
    required this.action,
    required this.quote,
    required this.reflection,
    required this.createdAt,
    required this.score,
  });

  final String title;
  final String mission;
  final String action;
  final String quote;
  final String reflection;
  final DateTime createdAt;
  final int score;

  EpisodeCardData copyWith({String? reflection, int? score}) {
    return EpisodeCardData(
      title: title,
      mission: mission,
      action: action,
      quote: quote,
      reflection: reflection ?? this.reflection,
      createdAt: createdAt,
      score: score ?? this.score,
    );
  }
}

class _StageDestination {
  const _StageDestination(this.label, this.icon);

  final String label;
  final IconData icon;
}

enum _HomeMoment {
  tomorrowSetup,
  openingLocked,
  questCleared,
  episodePlaying,
  firstAction,
  dayComplete,
}

enum _OnboardingKind { coldOpen, titleDrop, rivalCut, alarmCut, powerUp }

enum _SagaSetupStepKind {
  singleChoice,
  education,
  identity,
  mission,
  goal,
  wakeTime,
  voice,
  loadingChecklist,
  planReveal,
  receiptPreview,
  paywall,
  review,
}

class _SagaChoiceOption {
  const _SagaChoiceOption({
    required this.id,
    required this.label,
    required this.description,
    required this.icon,
  });

  final String id;
  final String label;
  final String description;
  final IconData icon;
}

class _SagaSetupStep {
  const _SagaSetupStep({
    required this.id,
    required this.chapter,
    required this.title,
    required this.subtitle,
    required this.kind,
    required this.accent,
    this.options = const [],
  });

  final String id;
  final String chapter;
  final String title;
  final String subtitle;
  final _SagaSetupStepKind kind;
  final Color accent;
  final List<_SagaChoiceOption> options;
}

const _sagaSetupSteps = <_SagaSetupStep>[
  _SagaSetupStep(
    id: 'morning_identity',
    chapter: 'DIAGNOSIS 01',
    title: 'DO MORNINGS\nFEEL LIKE YOU?',
    subtitle: 'The builder starts by finding the old opening scene.',
    kind: _SagaSetupStepKind.singleChoice,
    accent: _SagaColors.gold,
    options: [
      _SagaChoiceOption(
        id: 'already_moving',
        label: 'Already moving',
        description: 'Some days work. You want the system to hold.',
        icon: Icons.directions_run_outlined,
      ),
      _SagaChoiceOption(
        id: 'not_yet',
        label: 'Not yet',
        description: 'You know there is a sharper version of the morning.',
        icon: Icons.hourglass_empty_outlined,
      ),
      _SagaChoiceOption(
        id: 'snooze_loop',
        label: 'I hit snooze',
        description: 'The first decision becomes a negotiation.',
        icon: Icons.snooze_outlined,
      ),
      _SagaChoiceOption(
        id: 'phone_first',
        label: 'Phone first',
        description: 'The day opens in someone else\'s feed.',
        icon: Icons.phone_iphone_outlined,
      ),
    ],
  ),
  _SagaSetupStep(
    id: 'alarm_after',
    chapter: 'DIAGNOSIS 02',
    title: 'WHAT HAPPENS\nAFTER THE ALARM?',
    subtitle: 'Tell the narrator what the old first scene looks like.',
    kind: _SagaSetupStepKind.singleChoice,
    accent: _SagaColors.purple,
    options: [
      _SagaChoiceOption(
        id: 'snooze_scroll',
        label: 'Snooze, then scroll',
        description: 'The alarm fires, but the day does not start.',
        icon: Icons.swipe_down_outlined,
      ),
      _SagaChoiceOption(
        id: 'stand_then_drift',
        label: 'Stand, then drift',
        description: 'You get up, but the first move is unclear.',
        icon: Icons.blur_on_outlined,
      ),
      _SagaChoiceOption(
        id: 'panic_launch',
        label: 'Panic launch',
        description: 'You move only after the clock turns hostile.',
        icon: Icons.emergency_outlined,
      ),
      _SagaChoiceOption(
        id: 'clean_start',
        label: 'Clean start',
        description: 'You already wake well. WakeSaga turns it into ritual.',
        icon: Icons.check_circle_outline,
      ),
    ],
  ),
  _SagaSetupStep(
    id: 'alarm_count',
    chapter: 'DIAGNOSIS 03',
    title: 'HOW MANY\nALARMS DO YOU SET?',
    subtitle:
        'The stack of alarms tells us how strong the Wake Quest needs to be.',
    kind: _SagaSetupStepKind.singleChoice,
    accent: _SagaColors.gold,
    options: [
      _SagaChoiceOption(
        id: 'one',
        label: 'One',
        description: 'The alarm is already clean. We protect it.',
        icon: Icons.looks_one_outlined,
      ),
      _SagaChoiceOption(
        id: 'two',
        label: 'Two',
        description: 'One alarm starts it. The second rescues it.',
        icon: Icons.looks_two_outlined,
      ),
      _SagaChoiceOption(
        id: 'three_plus',
        label: 'Three or more',
        description: 'The morning has become a stack of backup plans.',
        icon: Icons.filter_3_outlined,
      ),
      _SagaChoiceOption(
        id: 'chaotic',
        label: 'It changes',
        description: 'The system needs to adapt to uneven nights.',
        icon: Icons.shuffle_outlined,
      ),
    ],
  ),
  _SagaSetupStep(
    id: 'one_alarm_confidence',
    chapter: 'DIAGNOSIS 04',
    title: 'IF THERE WERE\nONLY ONE ALARM?',
    subtitle: 'One clean alarm only works when the first move is protected.',
    kind: _SagaSetupStepKind.singleChoice,
    accent: _SagaColors.purple,
    options: [
      _SagaChoiceOption(
        id: 'yes',
        label: 'I would get up',
        description: 'Then we make that one alarm cinematic and protected.',
        icon: Icons.bolt_outlined,
      ),
      _SagaChoiceOption(
        id: 'with_gate',
        label: 'Only with a quest',
        description: 'Exactly. The body moves before the brain debates.',
        icon: Icons.lock_outline,
      ),
      _SagaChoiceOption(
        id: 'probably_not',
        label: 'Probably not',
        description: 'Then the first build needs a harder Wake Quest.',
        icon: Icons.warning_amber_outlined,
      ),
    ],
  ),
  _SagaSetupStep(
    id: 'first_ten',
    chapter: 'DIAGNOSIS 05',
    title: 'WHAT STEALS\nTHE FIRST 10 MINUTES?',
    subtitle: 'This becomes the rival inside tomorrow\'s episode.',
    kind: _SagaSetupStepKind.singleChoice,
    accent: _SagaColors.gold,
    options: [
      _SagaChoiceOption(
        id: 'phone_vortex',
        label: 'Phone vortex',
        description: 'The feed takes the opening scene.',
        icon: Icons.phone_iphone_outlined,
      ),
      _SagaChoiceOption(
        id: 'warm_bed',
        label: 'Warm bed gravity',
        description: 'Comfort negotiates before you stand.',
        icon: Icons.bedtime_outlined,
      ),
      _SagaChoiceOption(
        id: 'late_start',
        label: 'Late-start panic',
        description: 'Pressure becomes the only engine.',
        icon: Icons.timer_off_outlined,
      ),
      _SagaChoiceOption(
        id: 'low_mood',
        label: 'Low-mood fog',
        description: 'The morning needs a spark before it needs a plan.',
        icon: Icons.cloud_outlined,
      ),
    ],
  ),
  _SagaSetupStep(
    id: 'rival_detected',
    chapter: 'PLAN PROOF 01',
    title: 'RIVAL\nDETECTED',
    subtitle:
        'This is where the setup starts paying you back: the enemy now becomes a quest.',
    kind: _SagaSetupStepKind.education,
    accent: _SagaColors.purple,
  ),
  _SagaSetupStep(
    id: 'snooze_loop',
    chapter: 'SYSTEM BRIEFING 01',
    title: 'THE SNOOZE LOOP\nIS BUILT TO WIN',
    subtitle:
        'Alarm, negotiate, delay, scroll, rush. WakeSaga changes the order.',
    kind: _SagaSetupStepKind.education,
    accent: _SagaColors.purple,
  ),
  _SagaSetupStep(
    id: 'old_loop',
    chapter: 'SYSTEM BRIEFING 02',
    title: 'OLD LOOP VS\nSAGA LOOP',
    subtitle: 'Normal alarms ask for willpower. WakeSaga asks for proof.',
    kind: _SagaSetupStepKind.education,
    accent: _SagaColors.gold,
  ),
  _SagaSetupStep(
    id: 'night_feeling',
    chapter: 'DIAGNOSIS 06',
    title: 'SETTING AN ALARM\nFEELS LIKE...',
    subtitle: 'The emotional state at night shapes the morning contract.',
    kind: _SagaSetupStepKind.singleChoice,
    accent: _SagaColors.purple,
    options: [
      _SagaChoiceOption(
        id: 'quiet_dread',
        label: 'Quiet dread',
        description: 'You already know tomorrow will be a fight.',
        icon: Icons.nightlight_outlined,
      ),
      _SagaChoiceOption(
        id: 'optimistic',
        label: 'Optimistic',
        description: 'Night-you believes. Morning-you needs a bridge.',
        icon: Icons.wb_twilight_outlined,
      ),
      _SagaChoiceOption(
        id: 'numb',
        label: 'Numb',
        description:
            'The alarm is just another setting until it becomes a scene.',
        icon: Icons.remove_circle_outline,
      ),
      _SagaChoiceOption(
        id: 'locked_in',
        label: 'Locked in',
        description: 'Good. WakeSaga turns intent into an automatic opening.',
        icon: Icons.lock_outline,
      ),
    ],
  ),
  _SagaSetupStep(
    id: 'wake_feeling',
    chapter: 'DIAGNOSIS 07',
    title: 'RIGHT AFTER\nWAKING, YOU FEEL...',
    subtitle: 'This tells the episode how hard the first line should hit.',
    kind: _SagaSetupStepKind.singleChoice,
    accent: _SagaColors.gold,
    options: [
      _SagaChoiceOption(
        id: 'fog',
        label: 'Foggy',
        description: 'The body needs a small external command.',
        icon: Icons.foggy,
      ),
      _SagaChoiceOption(
        id: 'resistant',
        label: 'Resistant',
        description: 'The rival voice needs to be named and beaten fast.',
        icon: Icons.sports_mma_outlined,
      ),
      _SagaChoiceOption(
        id: 'anxious',
        label: 'Anxious',
        description: 'The opener should feel grounding, not chaotic.',
        icon: Icons.favorite_border,
      ),
      _SagaChoiceOption(
        id: 'ready',
        label: 'Ready',
        description: 'Then we keep the morning clean and fast.',
        icon: Icons.flash_on,
      ),
    ],
  ),
  _SagaSetupStep(
    id: 'alive_delay',
    chapter: 'DIAGNOSIS 08',
    title: 'HOW LONG UNTIL\nYOU FEEL HUMAN?',
    subtitle: 'The episode has to meet your actual wake-up state.',
    kind: _SagaSetupStepKind.singleChoice,
    accent: _SagaColors.purple,
    options: [
      _SagaChoiceOption(
        id: 'five',
        label: '5 minutes',
        description: 'You need a spark, not a rescue plan.',
        icon: Icons.timer_3_outlined,
      ),
      _SagaChoiceOption(
        id: 'fifteen',
        label: '15 minutes',
        description: 'The opening scene can pull you across the gap.',
        icon: Icons.timer_outlined,
      ),
      _SagaChoiceOption(
        id: 'thirty',
        label: '30 minutes',
        description: 'We need body-first proof before the episode starts.',
        icon: Icons.hourglass_bottom_outlined,
      ),
      _SagaChoiceOption(
        id: 'hour',
        label: 'An hour',
        description:
            'The system should be gentle, structured, and hard to ignore.',
        icon: Icons.schedule_outlined,
      ),
    ],
  ),
  _SagaSetupStep(
    id: 'sleep_inertia',
    chapter: 'SYSTEM BRIEFING 03',
    title: 'BIOLOGY,\nNOT WEAKNESS',
    subtitle: 'Sleep inertia is the villain. Motion is the counterspell.',
    kind: _SagaSetupStepKind.education,
    accent: _SagaColors.gold,
  ),
  _SagaSetupStep(
    id: 'body_before_brain',
    chapter: 'SYSTEM BRIEFING 04',
    title: 'BODY FIRST.\nBRAIN SECOND.',
    subtitle:
        'The Wake Quest makes the first physical vote happen before debate.',
    kind: _SagaSetupStepKind.education,
    accent: _SagaColors.purple,
  ),
  _SagaSetupStep(
    id: 'current_wake',
    chapter: 'TIME SCAN 01',
    title: 'WHEN DO YOU\nACTUALLY GET UP?',
    subtitle: 'Not the alarm time. The real moment the day begins.',
    kind: _SagaSetupStepKind.singleChoice,
    accent: _SagaColors.gold,
    options: [
      _SagaChoiceOption(
        id: 'on_alarm',
        label: 'On the alarm',
        description: 'We protect the clean start.',
        icon: Icons.alarm_on_outlined,
      ),
      _SagaChoiceOption(
        id: 'after_target',
        label: '15-30 min later',
        description: 'The Wake Quest exists to recover this window.',
        icon: Icons.more_time_outlined,
      ),
      _SagaChoiceOption(
        id: 'rushed',
        label: 'When I am rushed',
        description: 'Pressure is driving the morning. We replace it.',
        icon: Icons.speed_outlined,
      ),
      _SagaChoiceOption(
        id: 'varies',
        label: 'It varies',
        description: 'Then the saga needs repeat rules and rematches.',
        icon: Icons.calendar_month_outlined,
      ),
    ],
  ),
  _SagaSetupStep(
    id: 'target_wake',
    chapter: 'TIME SCAN 02',
    title: 'WHEN SHOULD\nEPISODE 001 START?',
    subtitle: 'Pick the real alarm time. WakeSaga builds around it.',
    kind: _SagaSetupStepKind.wakeTime,
    accent: _SagaColors.purple,
  ),
  _SagaSetupStep(
    id: 'target_shift',
    chapter: 'TIME SCAN 03',
    title: 'HOW MUCH TIME\nDO WE WIN BACK?',
    subtitle: 'Small morning gains become a visible monthly receipt.',
    kind: _SagaSetupStepKind.singleChoice,
    accent: _SagaColors.gold,
    options: [
      _SagaChoiceOption(
        id: 'five',
        label: '5 minutes',
        description: 'A clean spark. Small, repeatable, real.',
        icon: Icons.exposure_plus_1_outlined,
      ),
      _SagaChoiceOption(
        id: 'fifteen',
        label: '15 minutes',
        description: 'Seven and a half hours reclaimed this month.',
        icon: Icons.bolt_outlined,
      ),
      _SagaChoiceOption(
        id: 'thirty',
        label: '30 minutes',
        description: 'Fifteen hours back from the snooze loop.',
        icon: Icons.local_fire_department_outlined,
      ),
    ],
  ),
  _SagaSetupStep(
    id: 'time_gain',
    chapter: 'PLAN PROOF 01',
    title: 'THE FIRST WIN\nIS TIME',
    subtitle:
        'This reward preview keeps the long funnel from feeling like homework.',
    kind: _SagaSetupStepKind.education,
    accent: _SagaColors.purple,
  ),
  _SagaSetupStep(
    id: 'title_card',
    chapter: 'TITLE CARD',
    title: 'WIN THE OPENING.\nCHANGE THE EPISODE.',
    subtitle:
        'A short reset before the builder starts configuring the actual saga.',
    kind: _SagaSetupStepKind.education,
    accent: _SagaColors.gold,
  ),
  _SagaSetupStep(
    id: 'mission',
    chapter: 'SAGA BUILD 01',
    title: 'CHOOSE\nTOMORROW\'S ARC',
    subtitle: 'Pick the genre of tomorrow morning before the alarm is forged.',
    kind: _SagaSetupStepKind.mission,
    accent: _SagaColors.purple,
  ),
  _SagaSetupStep(
    id: 'goal',
    chapter: 'SAGA BUILD 02',
    title: 'WHAT ARE YOU\nTRAINING FOR?',
    subtitle: 'Give the episode a victory condition.',
    kind: _SagaSetupStepKind.goal,
    accent: _SagaColors.gold,
  ),
  _SagaSetupStep(
    id: 'rival',
    chapter: 'SAGA BUILD 03',
    title: 'NAME\nTHE RIVAL',
    subtitle: 'The Morning Episode gets sharper when the enemy is specific.',
    kind: _SagaSetupStepKind.singleChoice,
    accent: _SagaColors.purple,
    options: [
      _SagaChoiceOption(
        id: 'warm_bed',
        label: 'Warm bed',
        description: 'Comfort is the first opponent.',
        icon: Icons.bedtime_outlined,
      ),
      _SagaChoiceOption(
        id: 'phone_vortex',
        label: 'Phone vortex',
        description: 'The feed steals the opening frame.',
        icon: Icons.phone_iphone_outlined,
      ),
      _SagaChoiceOption(
        id: 'late_start',
        label: 'Late panic',
        description: 'The clock turns into pressure.',
        icon: Icons.timer_off_outlined,
      ),
      _SagaChoiceOption(
        id: 'low_mood',
        label: 'Low-mood fog',
        description: 'The episode needs a gentler ignition.',
        icon: Icons.cloud_outlined,
      ),
    ],
  ),
  _SagaSetupStep(
    id: 'voice',
    chapter: 'SAGA BUILD 04',
    title: 'CHOOSE\nTHE NARRATOR',
    subtitle: 'The alarm hits harder when the voice belongs to the story.',
    kind: _SagaSetupStepKind.voice,
    accent: _SagaColors.gold,
  ),
  _SagaSetupStep(
    id: 'intensity',
    chapter: 'SAGA BUILD 05',
    title: 'SET\nTHE INTENSITY',
    subtitle: 'Same mechanic, different emotional pressure.',
    kind: _SagaSetupStepKind.singleChoice,
    accent: _SagaColors.purple,
    options: [
      _SagaChoiceOption(
        id: 'calm',
        label: 'Calm command',
        description: 'Grounded, firm, no chaos.',
        icon: Icons.spa_outlined,
      ),
      _SagaChoiceOption(
        id: 'sharp',
        label: 'Sharp',
        description: 'Direct pressure with no rambling.',
        icon: Icons.bolt_outlined,
      ),
      _SagaChoiceOption(
        id: 'cinematic',
        label: 'Cinematic',
        description: 'Opening-scene energy with a bigger build.',
        icon: Icons.movie_filter_outlined,
      ),
      _SagaChoiceOption(
        id: 'aggressive',
        label: 'Aggressive',
        description: 'Hard mode, but never abusive.',
        icon: Icons.local_fire_department_outlined,
      ),
    ],
  ),
  _SagaSetupStep(
    id: 'episode_formula',
    chapter: 'SYSTEM BRIEFING 05',
    title: 'MISSION + RIVAL\n+ FIRST MOVE',
    subtitle: 'That formula writes the wake jolt and the Morning Episode.',
    kind: _SagaSetupStepKind.education,
    accent: _SagaColors.gold,
  ),
  _SagaSetupStep(
    id: 'wake_quest',
    chapter: 'WAKE QUEST 01',
    title: 'CHOOSE\nYOUR WAKE QUEST',
    subtitle: 'Pick a real-world mission that proves you are up.',
    kind: _SagaSetupStepKind.singleChoice,
    accent: _SagaColors.purple,
    options: [
      _SagaChoiceOption(
        id: 'object_hunt',
        label: 'Object Hunt',
        description: 'Find a random object so your eyes and body engage.',
        icon: Icons.search_outlined,
      ),
      _SagaChoiceOption(
        id: 'sky_photo',
        label: 'Sky Photo',
        description: 'Point the camera at daylight before the feed wins.',
        icon: Icons.wb_sunny_outlined,
      ),
      _SagaChoiceOption(
        id: 'make_bed',
        label: 'Make Bed',
        description: 'Change the sleep space so rolling back is harder.',
        icon: Icons.bed_outlined,
      ),
      _SagaChoiceOption(
        id: 'water_check',
        label: 'Water Check',
        description: 'Drink or scan water for a tiny physical reset.',
        icon: Icons.water_drop_outlined,
      ),
      _SagaChoiceOption(
        id: 'pushups',
        label: 'Pushups',
        description: 'A short movement quest for hard-mode mornings.',
        icon: Icons.fitness_center,
      ),
      _SagaChoiceOption(
        id: 'desk_photo',
        label: 'Desk Photo',
        description: 'Show the study or work arena is open.',
        icon: Icons.desktop_windows_outlined,
      ),
      _SagaChoiceOption(
        id: 'shoes_on',
        label: 'Shoes On',
        description: 'Prove the body has left negotiation mode.',
        icon: Icons.hiking_outlined,
      ),
      _SagaChoiceOption(
        id: 'spoken_vow',
        label: 'Spoken Vow',
        description: 'Voice proof for quiet mornings.',
        icon: Icons.mic_none_outlined,
      ),
    ],
  ),
  _SagaSetupStep(
    id: 'quest_explain',
    chapter: 'WAKE QUEST 02',
    title: 'WHY THIS\nQUEST WORKS',
    subtitle:
        'A Wake Quest is not punishment. It is the first move of the arc.',
    kind: _SagaSetupStepKind.education,
    accent: _SagaColors.gold,
  ),
  _SagaSetupStep(
    id: 'first_alarm_time',
    chapter: 'WAKE QUEST 03',
    title: 'SET YOUR\nFIRST WAKE TIME',
    subtitle: 'This is the moment Episode 001 starts rendering toward.',
    kind: _SagaSetupStepKind.wakeTime,
    accent: _SagaColors.purple,
  ),
  _SagaSetupStep(
    id: 'repeat_days',
    chapter: 'WAKE QUEST 04',
    title: 'WHICH DAYS\nSHOULD IT RING?',
    subtitle: 'Simple repeat rules make the plan feel real.',
    kind: _SagaSetupStepKind.singleChoice,
    accent: _SagaColors.gold,
    options: [
      _SagaChoiceOption(
        id: 'weekdays',
        label: 'Weekdays',
        description: 'Training arc for school, work, and deep blocks.',
        icon: Icons.work_outline,
      ),
      _SagaChoiceOption(
        id: 'every_day',
        label: 'Every day',
        description: 'The opening scene never disappears.',
        icon: Icons.calendar_month_outlined,
      ),
      _SagaChoiceOption(
        id: 'custom',
        label: 'Custom later',
        description: 'Prototype keeps the intent, app can expose exact days.',
        icon: Icons.tune_outlined,
      ),
    ],
  ),
  _SagaSetupStep(
    id: 'jolt_style',
    chapter: 'WAKE JOLT 01',
    title: 'PICK THE\nWAKE JOLT STYLE',
    subtitle: 'Choose how the opening line should hit the room.',
    kind: _SagaSetupStepKind.singleChoice,
    accent: _SagaColors.purple,
    options: [
      _SagaChoiceOption(
        id: 'urgent',
        label: 'Urgent',
        description: 'Short, sharp, no soft landing.',
        icon: Icons.priority_high_outlined,
      ),
      _SagaChoiceOption(
        id: 'calm',
        label: 'Calm command',
        description: 'Firm voice, controlled room.',
        icon: Icons.spa_outlined,
      ),
      _SagaChoiceOption(
        id: 'cinematic',
        label: 'Cinematic',
        description: 'Trailer-style opening line.',
        icon: Icons.movie_creation_outlined,
      ),
      _SagaChoiceOption(
        id: 'recovery',
        label: 'Gentle recovery',
        description: 'For low-energy mornings that still need movement.',
        icon: Icons.self_improvement_outlined,
      ),
    ],
  ),
  _SagaSetupStep(
    id: 'jolt_preview',
    chapter: 'WAKE JOLT 02',
    title: 'PREVIEW\nTHE OPENING LINE',
    subtitle: 'Hear the first line before tomorrow tries to bargain.',
    kind: _SagaSetupStepKind.education,
    accent: _SagaColors.gold,
  ),
  _SagaSetupStep(
    id: 'alarm_mode',
    chapter: 'WAKE QUEST 05',
    title: 'HOW SHOULD\nTHE QUEST BEHAVE?',
    subtitle: 'Default to anti-snooze, but keep a humane escape route.',
    kind: _SagaSetupStepKind.singleChoice,
    accent: _SagaColors.purple,
    options: [
      _SagaChoiceOption(
        id: 'hard_gate',
        label: 'Keep ringing',
        description: 'Alarm stays active until the Wake Quest is complete.',
        icon: Icons.notifications_active_outlined,
      ),
      _SagaChoiceOption(
        id: 'app_focus',
        label: 'Stop in app',
        description: 'Softer mode: opening the app quiets the alarm.',
        icon: Icons.phone_android_outlined,
      ),
      _SagaChoiceOption(
        id: 'rematch_escape',
        label: 'Emergency rematch',
        description: 'Bypass records a setback, not a fake win.',
        icon: Icons.replay_circle_filled_outlined,
      ),
    ],
  ),
  _SagaSetupStep(
    id: 'permission_primer',
    chapter: 'PERMISSIONS',
    title: 'LET THE OPENING\nSCENE FIRE',
    subtitle: 'Prime notification/alarm access with product meaning first.',
    kind: _SagaSetupStepKind.education,
    accent: _SagaColors.gold,
  ),
  _SagaSetupStep(
    id: 'permission_intent',
    chapter: 'PERMISSIONS',
    title: 'WHEN THE PROMPT\nAPPEARS...',
    subtitle: 'Let the morning system fire when the phone is locked.',
    kind: _SagaSetupStepKind.singleChoice,
    accent: _SagaColors.purple,
    options: [
      _SagaChoiceOption(
        id: 'allow',
        label: 'Allow the alarm',
        description: 'WakeSaga can stage the jolt before morning.',
        icon: Icons.notifications_active_outlined,
      ),
      _SagaChoiceOption(
        id: 'decide_later',
        label: 'Decide later',
        description: 'Keep building the episode, ask again at alarm setup.',
        icon: Icons.schedule_outlined,
      ),
    ],
  ),
  _SagaSetupStep(
    id: 'commitment',
    chapter: 'CONTRACT',
    title: 'SIGN TOMORROW\'S\nOPENING CONTRACT',
    subtitle: 'Commitment screens work when they bind a concrete plan.',
    kind: _SagaSetupStepKind.singleChoice,
    accent: _SagaColors.gold,
    options: [
      _SagaChoiceOption(
        id: 'sign',
        label: 'I will clear the quest',
        description: 'Tomorrow starts when the proof is complete.',
        icon: Icons.draw_outlined,
      ),
      _SagaChoiceOption(
        id: 'soft_sign',
        label: 'Start me softer',
        description: 'Keep the plan, reduce the pressure.',
        icon: Icons.volunteer_activism_outlined,
      ),
    ],
  ),
  _SagaSetupStep(
    id: 'rendering',
    chapter: 'RENDERING',
    title: 'RENDERING\nEPISODE 001',
    subtitle: 'Your answers are becoming a jolt, quest, episode, and receipt.',
    kind: _SagaSetupStepKind.loadingChecklist,
    accent: _SagaColors.purple,
  ),
  _SagaSetupStep(
    id: 'plan_reveal',
    chapter: 'PLAN REVEAL',
    title: 'YOUR MORNING\nEPISODE PLAN',
    subtitle: 'The alarm, Wake Quest, narrator, and first move are now linked.',
    kind: _SagaSetupStepKind.planReveal,
    accent: _SagaColors.gold,
  ),
  _SagaSetupStep(
    id: 'timeline',
    chapter: 'PLAN REVEAL',
    title: 'TOMORROW\'S\nOPENING SEQUENCE',
    subtitle: 'Alarm, Wake Quest, episode, first action, receipt.',
    kind: _SagaSetupStepKind.education,
    accent: _SagaColors.purple,
  ),
  _SagaSetupStep(
    id: 'receipt_preview',
    chapter: 'REWARD PREVIEW',
    title: 'YOUR FIRST\nWAKE RECEIPT',
    subtitle: 'Make the first win feel collectible before tomorrow starts.',
    kind: _SagaSetupStepKind.receiptPreview,
    accent: _SagaColors.gold,
  ),
  _SagaSetupStep(
    id: 'streak_style',
    chapter: 'RETENTION RULES',
    title: 'IF YOU MISS,\nWHAT HAPPENS?',
    subtitle: 'WakeSaga uses rematches instead of shame resets.',
    kind: _SagaSetupStepKind.singleChoice,
    accent: _SagaColors.purple,
    options: [
      _SagaChoiceOption(
        id: 'rematch',
        label: 'Rematch episode',
        description: 'Missed mornings become a comeback arc.',
        icon: Icons.replay_circle_filled_outlined,
      ),
      _SagaChoiceOption(
        id: 'streak',
        label: 'Classic streak',
        description: 'Keep the pressure visible and simple.',
        icon: Icons.local_fire_department_outlined,
      ),
      _SagaChoiceOption(
        id: 'gentle',
        label: 'Gentle recovery',
        description: 'Protect consistency without guilt.',
        icon: Icons.favorite_border,
      ),
    ],
  ),
  _SagaSetupStep(
    id: 'identity',
    chapter: 'SAVE FILE 01',
    title: 'SAVE\nYOUR SAGA',
    subtitle: 'Now the name field has context: it belongs to the plan.',
    kind: _SagaSetupStepKind.identity,
    accent: _SagaColors.gold,
  ),
  _SagaSetupStep(
    id: 'account_mode',
    chapter: 'SAVE FILE 02',
    title: 'HOW SHOULD\nWE SAVE IT?',
    subtitle: 'Keep Episode 001 ready for tomorrow morning.',
    kind: _SagaSetupStepKind.singleChoice,
    accent: _SagaColors.purple,
    options: [
      _SagaChoiceOption(
        id: 'save_later',
        label: 'Save on this device',
        description: 'Fastest path into tomorrow\'s first episode.',
        icon: Icons.phone_iphone_outlined,
      ),
      _SagaChoiceOption(
        id: 'create_account',
        label: 'Create account later',
        description: 'Keep episode cards and voices synced.',
        icon: Icons.account_circle_outlined,
      ),
    ],
  ),
  _SagaSetupStep(
    id: 'paywall_intro',
    chapter: 'SAGA PASS',
    title: 'YOUR EPISODE 001\nIS READY',
    subtitle: 'Start the full voice stack for Episode 001.',
    kind: _SagaSetupStepKind.paywall,
    accent: _SagaColors.gold,
  ),
  _SagaSetupStep(
    id: 'review',
    chapter: 'SAGA BLUEPRINT',
    title: 'EPISODE 001\nIS READY',
    subtitle:
        'Confirm the arc and enter WakeSaga with the alarm already staged.',
    kind: _SagaSetupStepKind.review,
    accent: _SagaColors.gold,
  ),
];

class _WakeQuestPrototypeOnboarding extends StatelessWidget {
  const _WakeQuestPrototypeOnboarding({
    super.key,
    required this.controller,
    required this.pageIndex,
    required this.selectedEnemy,
    required this.selectedQuest,
    required this.mission,
    required this.selectedVoice,
    required this.wakeTime,
    required this.nameController,
    required this.goalController,
    required this.builderAnswers,
    required this.onPageChanged,
    required this.onMissionSelected,
    required this.onVoiceSelected,
    required this.onWakeTimePressed,
    required this.onAnswerSelected,
    required this.onContinue,
  });

  static int get totalPages => _sagaSetupSteps.length + 1;

  final PageController controller;
  final int pageIndex;
  final String selectedEnemy;
  final String selectedQuest;
  final MissionType mission;
  final VoiceArchetype selectedVoice;
  final String wakeTime;
  final TextEditingController nameController;
  final TextEditingController goalController;
  final Map<String, String> builderAnswers;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<MissionType> onMissionSelected;
  final ValueChanged<VoiceArchetype> onVoiceSelected;
  final VoidCallback onWakeTimePressed;
  final void Function(String stepId, String optionId) onAnswerSelected;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final activeStep = pageIndex == 0 ? null : _sagaSetupSteps[pageIndex - 1];

    return _PrototypeShell(
      pageIndex: pageIndex,
      totalPages: totalPages,
      buttonLabel: _prototypeButtonLabel(pageIndex, activeStep),
      onContinue: onContinue,
      child: PageView.builder(
        controller: controller,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: onPageChanged,
        itemCount: totalPages,
        itemBuilder: (context, index) {
          if (index == 0) {
            return const _PrototypeColdOpenPage();
          }

          final step = _sagaSetupSteps[index - 1];
          return _PrototypeSetupStepPage(
            key: ValueKey('prototype-step-${step.id}'),
            step: step,
            selectedEnemy: selectedEnemy,
            selectedQuest: selectedQuest,
            selectedMission: mission,
            selectedVoice: selectedVoice,
            wakeTime: wakeTime,
            nameController: nameController,
            goalController: goalController,
            builderAnswers: builderAnswers,
            onMissionSelected: onMissionSelected,
            onVoiceSelected: onVoiceSelected,
            onWakeTimePressed: onWakeTimePressed,
            onAnswerSelected: onAnswerSelected,
          );
        },
      ),
    );
  }

  static String _prototypeButtonLabel(int pageIndex, _SagaSetupStep? step) {
    if (pageIndex == 0) {
      return 'Build My Opening';
    }
    if (pageIndex == totalPages - 1) {
      return 'Start Tomorrow';
    }
    return switch (step?.kind) {
      _SagaSetupStepKind.education ||
      _SagaSetupStepKind.loadingChecklist ||
      _SagaSetupStepKind.planReveal ||
      _SagaSetupStepKind.receiptPreview => 'Continue',
      _SagaSetupStepKind.paywall => 'Activate Offer',
      _ => 'Next',
    };
  }
}

class _PrototypeShell extends StatelessWidget {
  const _PrototypeShell({
    required this.pageIndex,
    required this.totalPages,
    required this.buttonLabel,
    required this.onContinue,
    required this.child,
  });

  final int pageIndex;
  final int totalPages;
  final String buttonLabel;
  final VoidCallback onContinue;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _PrototypeColors.paper,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 20),
          child: Column(
            children: [
              _PrototypeTopBar(pageIndex: pageIndex, totalPages: totalPages),
              const SizedBox(height: 12),
              Expanded(child: child),
              const SizedBox(height: 14),
              _PrototypePrimaryButton(
                label: buttonLabel,
                onPressed: onContinue,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrototypeTopBar extends StatelessWidget {
  const _PrototypeTopBar({required this.pageIndex, required this.totalPages});

  final int pageIndex;
  final int totalPages;

  @override
  Widget build(BuildContext context) {
    final showBrand = pageIndex == 0 || pageIndex == totalPages - 1;

    return SizedBox(
      height: 34,
      child: Row(
        children: [
          if (showBrand)
            const _PrototypeBrandLockup()
          else
            Expanded(
              child: _PrototypeProgress(
                pageIndex: pageIndex,
                totalPages: totalPages,
              ),
            ),
          if (showBrand) ...[
            const Spacer(),
            Text(
              '${pageIndex + 1}/$totalPages',
              style: const TextStyle(
                color: _PrototypeColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PrototypeBrandLockup extends StatelessWidget {
  const _PrototypeBrandLockup();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: const [
        Icon(
          Icons.wb_twilight_outlined,
          color: _PrototypeColors.gold,
          size: 23,
        ),
        SizedBox(width: 7),
        Text(
          'WakeSaga',
          style: TextStyle(
            color: _PrototypeColors.ink,
            fontSize: 22,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
      ],
    );
  }
}

class _PrototypeProgress extends StatelessWidget {
  const _PrototypeProgress({required this.pageIndex, required this.totalPages});

  final int pageIndex;
  final int totalPages;

  @override
  Widget build(BuildContext context) {
    if (totalPages > 10) {
      final progress = (pageIndex + 1) / totalPages;

      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 78,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: _PrototypeColors.line,
                color: _PrototypeColors.coral,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '${pageIndex + 1}/$totalPages',
            style: const TextStyle(
              color: _PrototypeColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var index = 0; index < totalPages; index++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            width: index == pageIndex ? 24 : 8,
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: index <= pageIndex
                  ? _PrototypeColors.coral
                  : _PrototypeColors.line,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
      ],
    );
  }
}

class _PrototypePrimaryButton extends StatelessWidget {
  const _PrototypePrimaryButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 64,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _PrototypeColors.coral,
          foregroundColor: Colors.white,
          elevation: 3,
          shadowColor: _PrototypeColors.coral.withValues(alpha: 0.32),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
          textStyle: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(width: 14),
            const Icon(Icons.arrow_forward, size: 22),
          ],
        ),
      ),
    );
  }
}

class _PrototypeColdOpenPage extends StatelessWidget {
  const _PrototypeColdOpenPage();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Spacer(),
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Image.asset(
            'assets/onboarding/prototype_cold_open_hero.png',
            height: 286,
            width: double.infinity,
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
          ),
        ),
        const SizedBox(height: 34),
        const _PrototypeHeadline(
          'Start your day like an anime character',
          align: TextAlign.center,
        ),
        const SizedBox(height: 12),
        const Text(
          'Tomorrow becomes Episode 001.\nTurn your alarm into your first win.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _PrototypeColors.muted,
            fontSize: 13,
            height: 1.25,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 22),
        const _PrototypeTinyPips(active: 0, count: 3),
        const Spacer(),
      ],
    );
  }
}

class _PrototypeSetupStepPage extends StatelessWidget {
  const _PrototypeSetupStepPage({
    super.key,
    required this.step,
    required this.selectedEnemy,
    required this.selectedQuest,
    required this.selectedMission,
    required this.selectedVoice,
    required this.wakeTime,
    required this.nameController,
    required this.goalController,
    required this.builderAnswers,
    required this.onMissionSelected,
    required this.onVoiceSelected,
    required this.onWakeTimePressed,
    required this.onAnswerSelected,
  });

  final _SagaSetupStep step;
  final String selectedEnemy;
  final String selectedQuest;
  final MissionType selectedMission;
  final VoiceArchetype selectedVoice;
  final String wakeTime;
  final TextEditingController nameController;
  final TextEditingController goalController;
  final Map<String, String> builderAnswers;
  final ValueChanged<MissionType> onMissionSelected;
  final ValueChanged<VoiceArchetype> onVoiceSelected;
  final VoidCallback onWakeTimePressed;
  final void Function(String stepId, String optionId) onAnswerSelected;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).height < 740;

    if (step.kind == _SagaSetupStepKind.paywall) {
      return SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.only(bottom: compact ? 4 : 10),
        child: _PrototypePaywallContent(mission: selectedMission),
      );
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.only(bottom: compact ? 4 : 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PrototypeStagePill(label: _personaChapterForStep(step)),
          SizedBox(height: compact ? 14 : 18),
          _PrototypeSetupHeadline(_personaQuestionForStep(step)),
          SizedBox(height: compact ? 9 : 12),
          Text(
            step.subtitle,
            style: TextStyle(
              color: _PrototypeColors.muted,
              fontSize: compact ? 13 : 14,
              height: 1.28,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: compact ? 16 : 20),
          _PrototypeGuideStrip(
            icon: _iconForSetupStep(step),
            text: _guideLineForStep(step),
          ),
          SizedBox(height: compact ? 16 : 20),
          _buildContent(context, compact: compact),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, {required bool compact}) {
    final visibleEnemy = _visibleEnemyForStep();

    return switch (step.kind) {
      _SagaSetupStepKind.singleChoice =>
        step.id == 'wake_quest'
            ? _PrototypeQuestChoiceGrid(
                options: step.options,
                selectedId: builderAnswers[step.id] ?? selectedQuest,
                onSelected: (id) => onAnswerSelected(step.id, id),
              )
            : _PrototypeAnswerList(
                options: step.options,
                selectedId: builderAnswers[step.id] ?? step.options.first.id,
                onSelected: (id) => onAnswerSelected(step.id, id),
              ),
      _SagaSetupStepKind.education => _PrototypeEducationContent(
        step: step,
        selectedEnemy: visibleEnemy,
        selectedQuest: selectedQuest,
        selectedMission: selectedMission,
        wakeTime: wakeTime,
      ),
      _SagaSetupStepKind.identity => _PrototypeTextEntry(
        label: 'Protagonist name',
        controller: nameController,
        hint: 'Hero',
      ),
      _SagaSetupStepKind.mission => _PrototypeMissionChoiceGrid(
        selectedMission: selectedMission,
        onSelected: onMissionSelected,
      ),
      _SagaSetupStepKind.goal => _PrototypeTextEntry(
        label: 'Tomorrow should prove...',
        controller: goalController,
        hint: 'I do the hard thing before noon.',
        maxLines: compact ? 2 : 3,
      ),
      _SagaSetupStepKind.wakeTime => _PrototypeWakeTimeSelector(
        wakeTime: wakeTime,
        onPressed: onWakeTimePressed,
      ),
      _SagaSetupStepKind.voice => _PrototypeVoiceChoiceGrid(
        selectedVoice: selectedVoice,
        onSelected: onVoiceSelected,
      ),
      _SagaSetupStepKind.loadingChecklist => _PrototypeRenderingContent(
        mission: selectedMission,
        voice: selectedVoice,
        quest: selectedQuest,
        wakeTime: wakeTime,
      ),
      _SagaSetupStepKind.planReveal => _PrototypePlanSummaryContent(
        mission: selectedMission,
        voice: selectedVoice,
        quest: selectedQuest,
        enemy: visibleEnemy,
        wakeTime: wakeTime,
      ),
      _SagaSetupStepKind.receiptPreview => _PrototypeReceiptContent(
        mission: selectedMission,
        quest: selectedQuest,
        wakeTime: wakeTime,
      ),
      _SagaSetupStepKind.paywall => _PrototypePaywallContent(
        mission: selectedMission,
      ),
      _SagaSetupStepKind.review => _PrototypeReviewContent(
        name: nameController.text.trim().isEmpty
            ? 'Hero'
            : nameController.text.trim(),
        mission: selectedMission,
        voice: selectedVoice,
        quest: selectedQuest,
        enemy: visibleEnemy,
        wakeTime: wakeTime,
        repeatDays: _optionLabelFor(
          'repeat_days',
          builderAnswers['repeat_days'],
        ),
        mode: _optionLabelFor('alarm_mode', builderAnswers['alarm_mode']),
      ),
    };
  }

  String _visibleEnemyForStep() {
    final stepIndex = _sagaSetupSteps.indexWhere(
      (candidate) => candidate.id == step.id,
    );
    final rivalStepIndex = _sagaSetupSteps.indexWhere(
      (candidate) => candidate.id == 'rival',
    );

    if (stepIndex >= 0 && rivalStepIndex >= 0 && stepIndex < rivalStepIndex) {
      return builderAnswers['first_ten'] ?? selectedEnemy;
    }

    return builderAnswers['rival'] ??
        builderAnswers['first_ten'] ??
        selectedEnemy;
  }
}

class _PrototypeSetupHeadline extends StatelessWidget {
  const _PrototypeSetupHeadline(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: _PrototypeColors.ink,
        fontSize: 33,
        height: 0.98,
        fontWeight: FontWeight.w900,
        letterSpacing: 0,
      ),
    );
  }
}

class _PrototypeGuideStrip extends StatelessWidget {
  const _PrototypeGuideStrip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 14, 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF2EA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _PrototypeColors.line),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              color: _PrototypeColors.aqua,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: _PrototypeColors.ink, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: _PrototypeColors.ink,
                fontSize: 12.5,
                height: 1.22,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrototypeAnswerList extends StatelessWidget {
  const _PrototypeAnswerList({
    required this.options,
    required this.selectedId,
    required this.onSelected,
  });

  final List<_SagaChoiceOption> options;
  final String selectedId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final option in options) ...[
          _PrototypeAnswerCard(
            option: option,
            selected: selectedId == option.id,
            onTap: () => onSelected(option.id),
          ),
          if (option != options.last) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _PrototypeAnswerCard extends StatelessWidget {
  const _PrototypeAnswerCard({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final _SagaChoiceOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? _PrototypeColors.coral : _PrototypeColors.line,
              width: selected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: _PrototypeColors.ink.withValues(
                  alpha: selected ? 0.11 : 0.05,
                ),
                blurRadius: selected ? 18 : 10,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: selected
                      ? _PrototypeColors.aqua
                      : const Color(0xFFFFE7BD),
                  shape: BoxShape.circle,
                ),
                child: Icon(option.icon, color: _PrototypeColors.ink, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.label,
                      style: const TextStyle(
                        color: _PrototypeColors.ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      option.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _PrototypeColors.muted,
                        fontSize: 12,
                        height: 1.2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                selected ? Icons.check_circle : Icons.circle_outlined,
                color: selected
                    ? _PrototypeColors.coral
                    : _PrototypeColors.line,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrototypeQuestChoiceGrid extends StatelessWidget {
  const _PrototypeQuestChoiceGrid({
    required this.options,
    required this.selectedId,
    required this.onSelected,
  });

  final List<_SagaChoiceOption> options;
  final String selectedId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      crossAxisCount: 2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.08,
      children: [
        for (final option in options)
          _PrototypeChoiceCard(
            label: option.label,
            icon: option.icon,
            color: option.id == selectedId
                ? _PrototypeColors.aqua
                : const Color(0xFFFFE0B7),
            selected: selectedId == option.id,
            onTap: () => onSelected(option.id),
          ),
      ],
    );
  }
}

class _PrototypeMissionChoiceGrid extends StatelessWidget {
  const _PrototypeMissionChoiceGrid({
    required this.selectedMission,
    required this.onSelected,
  });

  final MissionType selectedMission;
  final ValueChanged<MissionType> onSelected;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      crossAxisCount: 2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.08,
      children: [
        for (final mission in MissionType.values)
          _PrototypeChoiceCard(
            label: mission.label,
            icon: mission.icon,
            color: mission == selectedMission
                ? _PrototypeColors.aqua
                : const Color(0xFFFFE0B7),
            selected: mission == selectedMission,
            onTap: () => onSelected(mission),
          ),
      ],
    );
  }
}

class _PrototypeVoiceChoiceGrid extends StatelessWidget {
  const _PrototypeVoiceChoiceGrid({
    required this.selectedVoice,
    required this.onSelected,
  });

  final VoiceArchetype selectedVoice;
  final ValueChanged<VoiceArchetype> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final voice in VoiceArchetype.values) ...[
          _PrototypeAnswerCard(
            option: _SagaChoiceOption(
              id: voice.name,
              label: voice.label,
              description: voice.promptLine,
              icon: voice.icon,
            ),
            selected: selectedVoice == voice,
            onTap: () => onSelected(voice),
          ),
          if (voice != VoiceArchetype.values.last) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _PrototypeTextEntry extends StatelessWidget {
  const _PrototypeTextEntry({
    required this.label,
    required this.controller,
    required this.hint,
    this.maxLines = 1,
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _PrototypeDecor.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: _PrototypeColors.aquaDark,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: controller,
            maxLines: maxLines,
            style: const TextStyle(
              color: _PrototypeColors.ink,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                color: _PrototypeColors.muted,
                fontWeight: FontWeight.w700,
              ),
              filled: true,
              fillColor: _PrototypeColors.paper,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide: const BorderSide(color: _PrototypeColors.line),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide: const BorderSide(color: _PrototypeColors.line),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide: const BorderSide(
                  color: _PrototypeColors.coral,
                  width: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrototypeWakeTimeSelector extends StatelessWidget {
  const _PrototypeWakeTimeSelector({
    required this.wakeTime,
    required this.onPressed,
  });

  final String wakeTime;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onPressed,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
          decoration: _PrototypeDecor.card,
          child: Row(
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: const BoxDecoration(
                  color: _PrototypeColors.aqua,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.alarm_on_outlined,
                  color: _PrototypeColors.ink,
                  size: 34,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Episode 001 starts at',
                      style: TextStyle(
                        color: _PrototypeColors.muted,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      wakeTime,
                      style: const TextStyle(
                        color: _PrototypeColors.ink,
                        fontSize: 34,
                        height: 1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.edit_outlined, color: _PrototypeColors.coral),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrototypeEducationContent extends StatelessWidget {
  const _PrototypeEducationContent({
    required this.step,
    required this.selectedEnemy,
    required this.selectedQuest,
    required this.selectedMission,
    required this.wakeTime,
  });

  final _SagaSetupStep step;
  final String selectedEnemy;
  final String selectedQuest;
  final MissionType selectedMission;
  final String wakeTime;

  @override
  Widget build(BuildContext context) {
    if (step.id == 'rival_detected') {
      return _PrototypeRivalDetectedCard(enemy: selectedEnemy);
    }
    if (step.id == 'old_loop' || step.id == 'timeline') {
      return const _PrototypeLoopDiagram();
    }

    final chips = [
      (Icons.my_location, _setupObstacleLabel(selectedEnemy)),
      (Icons.search_outlined, _wakeQuestLabel(selectedQuest)),
      (Icons.flag_outlined, selectedMission.label),
      (Icons.alarm_on_outlined, wakeTime),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _PrototypeDecor.card,
      child: Column(
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: const BoxDecoration(
              color: _PrototypeColors.aqua,
              shape: BoxShape.circle,
            ),
            child: Icon(
              _iconForSetupStep(step),
              color: _PrototypeColors.ink,
              size: 46,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            step.title.replaceAll('\n', ' '),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _PrototypeColors.ink,
              fontSize: 24,
              height: 1.03,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final chip in chips)
                _PrototypeMissionBadge(icon: chip.$1, label: chip.$2),
            ],
          ),
        ],
      ),
    );
  }
}

class _PrototypeRivalDetectedCard extends StatelessWidget {
  const _PrototypeRivalDetectedCard({required this.enemy});

  final String enemy;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      decoration: _PrototypeDecor.card,
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.asset(
              'assets/onboarding/prototype_rival_card.png',
              height: 174,
              width: double.infinity,
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
          ),
          const SizedBox(height: 14),
          _PrototypeMissionBadge(
            icon: Icons.my_location,
            label: _setupObstacleLabel(enemy).replaceAll(' gravity', ''),
          ),
          const SizedBox(height: 16),
          const Text(
            'You need a Wake Quest',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _PrototypeColors.ink,
              fontSize: 28,
              height: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrototypeLoopDiagram extends StatelessWidget {
  const _PrototypeLoopDiagram();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        _PrototypeLoopStep(
          number: 1,
          title: 'Alarm',
          icon: Icons.alarm_on_outlined,
          color: _PrototypeColors.coral,
        ),
        _PrototypeLoopArrow(),
        _PrototypeLoopStep(
          number: 2,
          title: 'Wake Quest',
          icon: Icons.directions_run_outlined,
          color: _PrototypeColors.aqua,
        ),
        _PrototypeLoopArrow(),
        _PrototypeLoopStep(
          number: 3,
          title: 'Morning Episode',
          icon: Icons.auto_stories_outlined,
          color: _PrototypeColors.gold,
        ),
      ],
    );
  }
}

class _PrototypeRenderingContent extends StatelessWidget {
  const _PrototypeRenderingContent({
    required this.mission,
    required this.voice,
    required this.quest,
    required this.wakeTime,
  });

  final MissionType mission;
  final VoiceArchetype voice;
  final String quest;
  final String wakeTime;

  @override
  Widget build(BuildContext context) {
    final rows = [
      (Icons.alarm_on_outlined, 'Wake jolt', wakeTime),
      (Icons.search_outlined, 'Wake Quest', _wakeQuestLabel(quest)),
      (Icons.record_voice_over_outlined, 'Narrator', voice.label),
      (Icons.flag_outlined, 'Arc', mission.label),
    ];

    return Column(
      children: [
        for (final row in rows) ...[
          _PrototypePlanRow(
            icon: row.$1,
            label: row.$2,
            value: row.$3,
            color: row.$2 == 'Wake Quest'
                ? _PrototypeColors.aqua
                : const Color(0xFFFFDCA8),
          ),
          if (row != rows.last) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _PrototypePlanSummaryContent extends StatelessWidget {
  const _PrototypePlanSummaryContent({
    required this.mission,
    required this.voice,
    required this.quest,
    required this.enemy,
    required this.wakeTime,
  });

  final MissionType mission;
  final VoiceArchetype voice;
  final String quest;
  final String enemy;
  final String wakeTime;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Image.asset(
            'assets/onboarding/prototype_plan_art.png',
            height: 210,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(height: 14),
        _PrototypePlanRow(
          icon: Icons.alarm_on_outlined,
          label: 'Alarm',
          value: wakeTime,
          color: _PrototypeColors.aqua,
        ),
        const SizedBox(height: 9),
        _PrototypePlanRow(
          icon: Icons.search_outlined,
          label: 'Wake Quest',
          value: _wakeQuestLabel(quest),
          color: _PrototypeColors.aqua,
        ),
        const SizedBox(height: 9),
        _PrototypePlanRow(
          icon: voice.icon,
          label: 'Narrator',
          value: voice.label,
          color: const Color(0xFFFFDCA8),
        ),
        const SizedBox(height: 9),
        _PrototypePlanRow(
          icon: Icons.my_location,
          label: 'Rival',
          value: _setupObstacleLabel(enemy),
          color: const Color(0xFFFFE0B7),
        ),
        const SizedBox(height: 9),
        _PrototypePlanRow(
          icon: Icons.flag_outlined,
          label: 'Mission',
          value: '${mission.label} before noon',
          color: const Color(0xFFCBEFE7),
        ),
      ],
    );
  }
}

class _PrototypeReceiptContent extends StatelessWidget {
  const _PrototypeReceiptContent({
    required this.mission,
    required this.quest,
    required this.wakeTime,
  });

  final MissionType mission;
  final String quest;
  final String wakeTime;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _PrototypeDecor.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _PrototypeMissionBadge(icon: Icons.wb_twilight, label: wakeTime),
              const Spacer(),
              const Icon(Icons.ios_share, color: _PrototypeColors.coral),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            '${mission.label} Episode Card',
            style: const TextStyle(
              color: _PrototypeColors.ink,
              fontSize: 28,
              height: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${_wakeQuestLabel(quest)} cleared. ${mission.wakeLine}',
            style: const TextStyle(
              color: _PrototypeColors.muted,
              fontSize: 14,
              height: 1.3,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrototypePaywallContent extends StatefulWidget {
  const _PrototypePaywallContent({required this.mission});

  final MissionType mission;

  @override
  State<_PrototypePaywallContent> createState() =>
      _PrototypePaywallContentState();
}

class _PrototypePaywallContentState extends State<_PrototypePaywallContent> {
  int _selectedPlan = 0;

  @override
  Widget build(BuildContext context) {
    final benefits = [
      (Icons.graphic_eq, 'Personal AI wake jolt'),
      (Icons.record_voice_over_outlined, 'Full narrator voice cast'),
      (Icons.emoji_events_outlined, 'Unlimited Wake Quests'),
      (Icons.style_outlined, 'Collectible Episode Cards'),
    ];

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: _PrototypeDecor.card,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _PrototypeMissionBadge(
                icon: Icons.workspace_premium_outlined,
                label: 'Saga Pass',
              ),
              const SizedBox(height: 14),
              const Text(
                'Episode 001 is ready',
                style: TextStyle(
                  color: _PrototypeColors.ink,
                  fontSize: 28,
                  height: 1.02,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Start the full ${widget.mission.label.toLowerCase()} morning system: AI jolt, narrator voice, Wake Quest, and first receipt.',
                style: const TextStyle(
                  color: _PrototypeColors.muted,
                  fontSize: 13.5,
                  height: 1.28,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: const [
                  _PrototypePaywallSignal(
                    icon: Icons.verified_outlined,
                    label: 'No ads',
                  ),
                  SizedBox(width: 8),
                  _PrototypePaywallSignal(
                    icon: Icons.lock_clock_outlined,
                    label: '7-day trial',
                  ),
                  SizedBox(width: 8),
                  _PrototypePaywallSignal(
                    icon: Icons.ios_share_outlined,
                    label: 'Cancel',
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _PrototypeSpecialOfferCard(
          selected: _selectedPlan == 0,
          onTap: () => setState(() => _selectedPlan = 0),
        ),
        const SizedBox(height: 10),
        _PrototypePaywallPlanCard(
          selected: _selectedPlan == 1,
          banner: '7-DAY FREE TRIAL',
          title: 'Annual',
          subtitle: 'Full voice stack after trial',
          price: '\$39.99',
          period: '/year',
          footnote: 'Just \$3.33/mo',
          onTap: () => setState(() => _selectedPlan = 1),
        ),
        const SizedBox(height: 10),
        _PrototypePaywallPlanCard(
          selected: _selectedPlan == 2,
          title: 'Weekly',
          subtitle: 'Flexible full access',
          price: '\$3.99',
          period: '/week',
          footnote: 'Cancel anytime',
          onTap: () => setState(() => _selectedPlan = 2),
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: _PrototypeDecor.card,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'WHAT YOU GET',
                style: TextStyle(
                  color: _PrototypeColors.aquaDark,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 10),
              for (final benefit in benefits) ...[
                _PrototypePaywallFeatureRow(
                  icon: benefit.$1,
                  label: benefit.$2,
                ),
                if (benefit != benefits.last) const SizedBox(height: 8),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Restore Purchase   Terms   Privacy',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _PrototypeColors.muted,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _PrototypePaywallSignal extends StatelessWidget {
  const _PrototypePaywallSignal({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          color: _PrototypeColors.paper,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _PrototypeColors.line),
        ),
        child: Column(
          children: [
            Icon(icon, color: _PrototypeColors.coral, size: 18),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _PrototypeColors.ink,
                fontSize: 10.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrototypeSpecialOfferCard extends StatelessWidget {
  const _PrototypeSpecialOfferCard({
    required this.selected,
    required this.onTap,
  });

  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? _PrototypeColors.gold : _PrototypeColors.line,
              width: selected ? 2 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: _PrototypeColors.gold.withValues(
                  alpha: selected ? 0.26 : 0.1,
                ),
                blurRadius: selected ? 22 : 12,
                offset: const Offset(0, 9),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: _PrototypeColors.gold.withValues(alpha: 0.28),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(14),
                  ),
                  border: Border(
                    bottom: BorderSide(
                      color: _PrototypeColors.gold.withValues(alpha: 0.45),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.auto_awesome,
                      size: 15,
                      color: _PrototypeColors.ink,
                    ),
                    const SizedBox(width: 7),
                    const Expanded(
                      child: Text(
                        'SPECIAL OFFER',
                        style: TextStyle(
                          color: _PrototypeColors.ink,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: const Text(
                        'SAVE 50%',
                        style: TextStyle(
                          color: _PrototypeColors.ink,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(13, 10, 13, 0),
                child: Row(
                  children: [
                    const Icon(
                      Icons.lock_clock_outlined,
                      size: 14,
                      color: _PrototypeColors.aquaDark,
                    ),
                    const SizedBox(width: 6),
                    const Expanded(
                      child: Text(
                        'EPISODE 001 RESERVED FOR',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _PrototypeColors.muted,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _PrototypeColors.paper,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: _PrototypeColors.line),
                      ),
                      child: const Text(
                        '14:59',
                        style: TextStyle(
                          color: _PrototypeColors.coral,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(13),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: selected
                            ? _PrototypeColors.gold.withValues(alpha: 0.24)
                            : Colors.transparent,
                        border: Border.all(
                          color: selected
                              ? _PrototypeColors.gold
                              : _PrototypeColors.line,
                          width: selected ? 2 : 1.5,
                        ),
                      ),
                      child: selected
                          ? const Icon(
                              Icons.check,
                              color: _PrototypeColors.ink,
                              size: 18,
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Best Value',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: _PrototypeColors.ink,
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Full saga for Episode 001',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: _PrototypeColors.muted,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Just \$2.50/mo',
                            style: TextStyle(
                              color: _PrototypeColors.aquaDark,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '\$59.99',
                          style: TextStyle(
                            color: _PrototypeColors.muted.withValues(
                              alpha: 0.65,
                            ),
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            decoration: TextDecoration.lineThrough,
                            decorationColor: _PrototypeColors.muted,
                          ),
                        ),
                        const Text(
                          '\$29.99',
                          style: TextStyle(
                            color: _PrototypeColors.ink,
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const Text(
                          '/year',
                          style: TextStyle(
                            color: _PrototypeColors.muted,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
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
      ),
    );
  }
}

class _PrototypePaywallPlanCard extends StatelessWidget {
  const _PrototypePaywallPlanCard({
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.price,
    required this.period,
    required this.footnote,
    required this.onTap,
    this.banner,
  });

  final bool selected;
  final String? banner;
  final String title;
  final String subtitle;
  final String price;
  final String period;
  final String footnote;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const accent = _PrototypeColors.coral;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? accent : _PrototypeColors.line,
              width: selected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: selected ? 0.24 : 0.08),
                blurRadius: selected ? 20 : 10,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              if (banner != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.28),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(14),
                    ),
                    border: Border(
                      bottom: BorderSide(color: accent.withValues(alpha: 0.45)),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.card_giftcard_outlined,
                        size: 14,
                        color: _PrototypeColors.ink,
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          banner!,
                          style: const TextStyle(
                            color: _PrototypeColors.ink,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: const Text(
                          'SAVE 45%',
                          style: TextStyle(
                            color: _PrototypeColors.ink,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(13),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: selected
                            ? accent.withValues(alpha: 0.22)
                            : Colors.transparent,
                        border: Border.all(
                          color: selected ? accent : _PrototypeColors.line,
                          width: selected ? 2 : 1.5,
                        ),
                      ),
                      child: selected
                          ? const Icon(
                              Icons.check,
                              color: _PrototypeColors.ink,
                              size: 16,
                            )
                          : null,
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _PrototypeColors.ink,
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _PrototypeColors.muted,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            footnote,
                            style: const TextStyle(
                              color: _PrototypeColors.aquaDark,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          price,
                          style: const TextStyle(
                            color: _PrototypeColors.ink,
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          period,
                          style: const TextStyle(
                            color: _PrototypeColors.muted,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
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
      ),
    );
  }
}

class _PrototypePaywallFeatureRow extends StatelessWidget {
  const _PrototypePaywallFeatureRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: const BoxDecoration(
            color: _PrototypeColors.aqua,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: _PrototypeColors.ink, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _PrototypeColors.ink,
              fontSize: 13.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const Icon(Icons.check_circle, color: _PrototypeColors.coral, size: 20),
      ],
    );
  }
}

class _PrototypeReviewContent extends StatelessWidget {
  const _PrototypeReviewContent({
    required this.name,
    required this.mission,
    required this.voice,
    required this.quest,
    required this.enemy,
    required this.wakeTime,
    required this.repeatDays,
    required this.mode,
  });

  final String name;
  final MissionType mission;
  final VoiceArchetype voice;
  final String quest;
  final String enemy;
  final String wakeTime;
  final String repeatDays;
  final String mode;

  @override
  Widget build(BuildContext context) {
    final rows = [
      (Icons.person_outline, 'Protagonist', name),
      (Icons.alarm_on_outlined, 'Wake jolt', wakeTime),
      (Icons.my_location, 'Rival', _setupObstacleLabel(enemy)),
      (Icons.search_outlined, 'Wake Quest', _wakeQuestLabel(quest)),
      (voice.icon, 'Narrator', voice.label),
      (mission.icon, 'Arc', mission.label),
      (Icons.calendar_month_outlined, 'Days', repeatDays),
      (Icons.notifications_active_outlined, 'Mode', mode),
    ];

    return Column(
      children: [
        for (final row in rows) ...[
          _PrototypePlanRow(
            icon: row.$1,
            label: row.$2,
            value: row.$3,
            color: row.$2 == 'Wake Quest'
                ? _PrototypeColors.aqua
                : const Color(0xFFFFDCA8),
          ),
          if (row != rows.last) const SizedBox(height: 9),
        ],
      ],
    );
  }
}

class _PrototypeHeadline extends StatelessWidget {
  const _PrototypeHeadline(this.text, {this.align = TextAlign.left});

  final String text;
  final TextAlign align;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      key: const ValueKey('prototype-onboarding-title'),
      textAlign: align,
      style: const TextStyle(
        color: _PrototypeColors.ink,
        fontSize: 36,
        height: 0.98,
        fontWeight: FontWeight.w900,
        letterSpacing: 0,
      ),
    );
  }
}

class _PrototypeStagePill extends StatelessWidget {
  const _PrototypeStagePill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF2EA),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: _PrototypeColors.line),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: _PrototypeColors.coral,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _PrototypeChoiceCard extends StatelessWidget {
  const _PrototypeChoiceCard({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? _PrototypeColors.coral : _PrototypeColors.line,
              width: selected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: _PrototypeColors.ink.withValues(
                  alpha: selected ? 0.12 : 0.05,
                ),
                blurRadius: selected ? 18 : 10,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              if (selected)
                const Positioned(
                  right: 0,
                  top: 0,
                  child: Icon(
                    Icons.check_circle,
                    color: _PrototypeColors.coral,
                    size: 24,
                  ),
                ),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 66,
                      height: 66,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: _PrototypeColors.ink, size: 34),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _PrototypeColors.ink,
                        fontSize: 14,
                        height: 1.05,
                        fontWeight: FontWeight.w900,
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

class _PrototypeMissionBadge extends StatelessWidget {
  const _PrototypeMissionBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _PrototypeColors.aqua,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: _PrototypeColors.ink),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: _PrototypeColors.ink, size: 17),
          const SizedBox(width: 7),
          Text(
            label,
            style: const TextStyle(
              color: _PrototypeColors.ink,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrototypeLoopStep extends StatelessWidget {
  const _PrototypeLoopStep({
    required this.number,
    required this.title,
    required this.icon,
    required this.color,
  });

  final int number;
  final String title;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 86,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: _PrototypeDecor.card,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Text(
              '$number',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.22),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: _PrototypeColors.ink, size: 30),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: _PrototypeColors.ink,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrototypeLoopArrow extends StatelessWidget {
  const _PrototypeLoopArrow();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Icon(Icons.keyboard_arrow_down, color: _PrototypeColors.ink),
    );
  }
}

class _PrototypePlanRow extends StatelessWidget {
  const _PrototypePlanRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _PrototypeDecor.card,
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(icon, color: _PrototypeColors.ink, size: 23),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: _PrototypeColors.aquaDark,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _PrototypeColors.ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.auto_awesome, color: _PrototypeColors.gold),
        ],
      ),
    );
  }
}

class _PrototypeTinyPips extends StatelessWidget {
  const _PrototypeTinyPips({required this.active, required this.count});

  final int active;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var index = 0; index < count; index++)
          Container(
            width: 7,
            height: 7,
            margin: const EdgeInsets.symmetric(horizontal: 5),
            decoration: BoxDecoration(
              color: index == active
                  ? _PrototypeColors.coral
                  : _PrototypeColors.line,
              shape: BoxShape.circle,
            ),
          ),
      ],
    );
  }
}

class _PrototypeDecor {
  static BoxDecoration get card {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: _PrototypeColors.line),
      boxShadow: [
        BoxShadow(
          color: _PrototypeColors.ink.withValues(alpha: 0.07),
          blurRadius: 18,
          offset: const Offset(0, 9),
        ),
      ],
    );
  }
}

class _PrototypeColors {
  static const paper = Color(0xFFFBF5EC);
  static const ink = Color(0xFF09090C);
  static const muted = Color(0xFF726B63);
  static const line = Color(0xFFE8DED1);
  static const coral = Color(0xFFFF6357);
  static const gold = Color(0xFFFFC743);
  static const aqua = Color(0xFFB7F3F4);
  static const aquaDark = Color(0xFF2AA2AA);
}

class _OnboardingFrame {
  const _OnboardingFrame({
    required this.number,
    required this.episode,
    required this.title,
    required this.highlight,
    required this.subtitle,
    required this.action,
    required this.scene,
    required this.accent,
    required this.kind,
    required this.assetPath,
  });

  final String number;
  final String episode;
  final String title;
  final String highlight;
  final String subtitle;
  final String action;
  final int scene;
  final Color accent;
  final _OnboardingKind kind;
  final String assetPath;
}

class _PromiseFrameView extends StatelessWidget {
  const _PromiseFrameView({
    required this.frame,
    required this.pageIndex,
    required this.totalPages,
    required this.onPrimaryPressed,
  });

  final _OnboardingFrame frame;
  final int pageIndex;
  final int totalPages;
  final VoidCallback onPrimaryPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: frame.title,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _OnboardingArtBackdrop(frame: frame),
          _AnimeOpeningTint(frame: frame, pageIndex: pageIndex),
          CustomPaint(
            painter: _AnimeOpeningMotionPainter(
              accent: frame.accent,
              pageIndex: pageIndex,
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 10, 22, 20),
              child: _buildLayout(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLayout(BuildContext context) {
    return switch (frame.kind) {
      _OnboardingKind.coldOpen => _AnimeColdOpenScreen(
        frame: frame,
        pageIndex: pageIndex,
        totalPages: totalPages,
        onPrimaryPressed: onPrimaryPressed,
      ),
      _OnboardingKind.titleDrop => _AnimeTitleDropScreen(
        frame: frame,
        pageIndex: pageIndex,
        totalPages: totalPages,
        onPrimaryPressed: onPrimaryPressed,
      ),
      _OnboardingKind.rivalCut => _AnimeRivalCutScreen(
        frame: frame,
        pageIndex: pageIndex,
        totalPages: totalPages,
        onPrimaryPressed: onPrimaryPressed,
      ),
      _OnboardingKind.alarmCut => _AnimeAlarmCutScreen(
        frame: frame,
        pageIndex: pageIndex,
        totalPages: totalPages,
        onPrimaryPressed: onPrimaryPressed,
      ),
      _OnboardingKind.powerUp => _AnimePowerUpScreen(
        frame: frame,
        pageIndex: pageIndex,
        totalPages: totalPages,
        onPrimaryPressed: onPrimaryPressed,
      ),
    };
  }
}

class _AnimeOpeningTint extends StatelessWidget {
  const _AnimeOpeningTint({required this.frame, required this.pageIndex});

  final _OnboardingFrame frame;
  final int pageIndex;

  @override
  Widget build(BuildContext context) {
    final color = frame.accent;
    final isColdOpen = pageIndex == 0;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            _SagaColors.ink.withValues(alpha: isColdOpen ? 0.42 : 0.62),
            _SagaColors.ink.withValues(alpha: isColdOpen ? 0.1 : 0.22),
            color.withValues(alpha: isColdOpen ? 0.02 : 0.06),
            _SagaColors.ink.withValues(alpha: 0.04),
          ],
          stops: const [0, 0.48, 0.74, 1],
        ),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _SagaColors.ink.withValues(alpha: isColdOpen ? 0.02 : 0.04),
              _SagaColors.ink.withValues(alpha: isColdOpen ? 0.04 : 0.08),
              _SagaColors.ink.withValues(alpha: isColdOpen ? 0.52 : 0.48),
            ],
            stops: const [0, 0.48, 1],
          ),
        ),
      ),
    );
  }
}

class _AnimeOpeningMotionPainter extends CustomPainter {
  const _AnimeOpeningMotionPainter({
    required this.accent,
    required this.pageIndex,
  });

  final Color accent;
  final int pageIndex;

  @override
  void paint(Canvas canvas, Size size) {
    final slashPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = accent.withValues(alpha: 0.035);
    final hairlinePaint = Paint()
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke
      ..color = _SagaColors.paper.withValues(alpha: 0.045);
    final flarePaint = Paint()
      ..style = PaintingStyle.fill
      ..color = accent.withValues(alpha: pageIndex == 0 ? 0.04 : 0.06);

    final shift = pageIndex * 38.0;
    final slash = Path()
      ..moveTo(size.width * 0.66 + shift, 0)
      ..lineTo(size.width * 0.86 + shift, 0)
      ..lineTo(size.width * 0.48 + shift, size.height)
      ..lineTo(size.width * 0.28 + shift, size.height)
      ..close();
    canvas.drawPath(slash, slashPaint);

    for (var i = 0; i < 5; i++) {
      final x = size.width * (0.12 + i * 0.19) + shift * 0.25;
      canvas.drawLine(
        Offset(x, size.height * 0.08),
        Offset(x - size.width * 0.28, size.height * 0.86),
        hairlinePaint,
      );
    }

    canvas.drawCircle(
      Offset(size.width * (0.82 - pageIndex * 0.04), size.height * 0.18),
      68,
      flarePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _AnimeOpeningMotionPainter oldDelegate) {
    return oldDelegate.accent != accent || oldDelegate.pageIndex != pageIndex;
  }
}

class _AnimeStoryEntry extends StatelessWidget {
  const _AnimeStoryEntry({required this.child, this.delay = Duration.zero});

  final Widget child;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 540 + delay.inMilliseconds),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        final settled = value.clamp(0.0, 1.0);

        return Opacity(
          opacity: settled,
          child: Transform.translate(
            offset: Offset((1 - settled) * -18, 0),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class _AnimeFooter extends StatelessWidget {
  const _AnimeFooter({
    required this.pageIndex,
    required this.totalPages,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  final int pageIndex;
  final int totalPages;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ReferenceProgress(index: pageIndex, total: totalPages),
        const SizedBox(height: 12),
        _ReferencePrimaryButton(
          label: label,
          color: color,
          onPressed: onPressed,
          compact: MediaQuery.sizeOf(context).height < 700,
        ),
      ],
    );
  }
}

class _AnimeColdOpenScreen extends StatelessWidget {
  const _AnimeColdOpenScreen({
    required this.frame,
    required this.pageIndex,
    required this.totalPages,
    required this.onPrimaryPressed,
  });

  final _OnboardingFrame frame;
  final int pageIndex;
  final int totalPages;
  final VoidCallback onPrimaryPressed;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).height < 720;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _OpHeader(number: frame.number, label: frame.episode),
        SizedBox(height: compact ? 12 : 18),
        const _EpisodeCapsule(label: 'EPISODE 001'),
        Spacer(flex: compact ? 2 : 3),
        _AnimeStoryEntry(
          child: _OpHeadline(
            title: frame.title,
            highlight: frame.highlight,
            color: _SagaColors.gold,
            maxFontSize: compact ? 37 : 43,
          ),
        ),
        SizedBox(height: compact ? 14 : 18),
        _AnimeStoryEntry(
          delay: const Duration(milliseconds: 90),
          child: _OpSubtitle(frame.subtitle),
        ),
        const Spacer(),
        const _AnimeStoryEntry(child: _OpeningWordmark()),
        SizedBox(height: compact ? 16 : 22),
        _AnimeStoryEntry(
          delay: const Duration(milliseconds: 150),
          child: const _OpeningStartLine(),
        ),
        SizedBox(height: compact ? 12 : 16),
        _AnimeFooter(
          pageIndex: pageIndex,
          totalPages: totalPages,
          label: frame.action,
          color: _SagaColors.purple,
          onPressed: onPrimaryPressed,
        ),
      ],
    );
  }
}

class _EpisodeCapsule extends StatelessWidget {
  const _EpisodeCapsule({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _SagaColors.purple.withValues(alpha: 0.18),
        border: Border.all(color: _SagaColors.purple, width: 2),
        boxShadow: [
          BoxShadow(
            color: _SagaColors.purple.withValues(alpha: 0.34),
            blurRadius: 18,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 7, 12, 6),
        child: Text(
          label,
          style: const TextStyle(
            color: _SagaColors.paper,
            fontSize: 14,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }
}

class _OpHeader extends StatelessWidget {
  const _OpHeader({required this.number, required this.label});

  final String number;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          number,
          style: const TextStyle(
            color: _SagaColors.paper,
            fontSize: 42,
            height: 0.9,
            fontWeight: FontWeight.w300,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: _SagaColors.paper.withValues(alpha: 0.76),
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

class _OpHeadline extends StatelessWidget {
  const _OpHeadline({
    required this.title,
    required this.highlight,
    required this.color,
    required this.maxFontSize,
    this.maxLines = 5,
  });

  final String title;
  final String highlight;
  final Color color;
  final double maxFontSize;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final upperTitle = title.toUpperCase();
    final upperHighlight = highlight.toUpperCase();
    final semanticTitle = title.replaceAll(RegExp(r'\s+'), ' ').trim();
    final parts = upperTitle.split(upperHighlight);

    return Text.rich(
      key: const ValueKey('onboarding-title'),
      TextSpan(
        children: [
          TextSpan(text: parts.first),
          TextSpan(
            text: upperHighlight,
            style: TextStyle(color: color),
          ),
          if (parts.length > 1)
            TextSpan(text: parts.sublist(1).join(upperHighlight)),
        ],
      ),
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.left,
      semanticsLabel: semanticTitle,
      style: TextStyle(
        color: _SagaColors.paper,
        fontSize: maxFontSize,
        height: 0.94,
        fontWeight: FontWeight.w900,
        letterSpacing: 0,
        shadows: [
          Shadow(
            color: _SagaColors.ink.withValues(alpha: 0.78),
            offset: const Offset(0, 2),
            blurRadius: 18,
          ),
        ],
      ),
    );
  }
}

class _OpSubtitle extends StatelessWidget {
  const _OpSubtitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.left,
      style: TextStyle(
        color: _SagaColors.paper.withValues(alpha: 0.82),
        fontSize: 15.5,
        height: 1.28,
        fontWeight: FontWeight.w800,
        shadows: [
          Shadow(
            color: _SagaColors.ink.withValues(alpha: 0.78),
            offset: const Offset(0, 2),
            blurRadius: 14,
          ),
        ],
      ),
    );
  }
}

class _OpeningStartLine extends StatelessWidget {
  const _OpeningStartLine();

  @override
  Widget build(BuildContext context) {
    return Text(
      'Your story begins tomorrow morning.',
      style: TextStyle(
        color: _SagaColors.paper.withValues(alpha: 0.88),
        fontSize: 18,
        height: 1.24,
        fontWeight: FontWeight.w900,
        shadows: [
          Shadow(
            color: _SagaColors.ink.withValues(alpha: 0.82),
            offset: const Offset(0, 2),
            blurRadius: 16,
          ),
        ],
      ),
    );
  }
}

class _OpeningWordmark extends StatelessWidget {
  const _OpeningWordmark();

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          const TextSpan(text: 'WAKE\n'),
          TextSpan(
            text: 'SAGA',
            style: TextStyle(
              color: _SagaColors.purple,
              shadows: [
                Shadow(
                  color: _SagaColors.purple.withValues(alpha: 0.52),
                  blurRadius: 18,
                ),
              ],
            ),
          ),
        ],
      ),
      style: TextStyle(
        color: _SagaColors.paper,
        fontSize: MediaQuery.sizeOf(context).height < 720 ? 30 : 36,
        height: 0.86,
        fontWeight: FontWeight.w900,
        letterSpacing: 0,
        shadows: [
          Shadow(
            color: _SagaColors.ink.withValues(alpha: 0.84),
            offset: const Offset(0, 2),
            blurRadius: 16,
          ),
        ],
      ),
    );
  }
}

class _AnimeTitleDropScreen extends StatelessWidget {
  const _AnimeTitleDropScreen({
    required this.frame,
    required this.pageIndex,
    required this.totalPages,
    required this.onPrimaryPressed,
  });

  final _OnboardingFrame frame;
  final int pageIndex;
  final int totalPages;
  final VoidCallback onPrimaryPressed;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).height < 720;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _OpHeader(number: frame.number, label: frame.episode),
        Spacer(flex: compact ? 1 : 2),
        _AnimeStoryEntry(
          child: _OpHeadline(
            title: frame.title,
            highlight: frame.highlight,
            color: _SagaColors.gold,
            maxFontSize: compact ? 34 : 39,
            maxLines: 4,
          ),
        ),
        SizedBox(height: compact ? 14 : 18),
        _AnimeStoryEntry(
          delay: const Duration(milliseconds: 90),
          child: _OpSubtitle(frame.subtitle),
        ),
        SizedBox(height: compact ? 18 : 24),
        const _OpeningMissionTeaserGrid(),
        const Spacer(),
        SizedBox(height: compact ? 18 : 24),
        _AnimeFooter(
          pageIndex: pageIndex,
          totalPages: totalPages,
          label: frame.action,
          color: _SagaColors.gold,
          onPressed: onPrimaryPressed,
        ),
      ],
    );
  }
}

class _OpeningMissionTeaserGrid extends StatelessWidget {
  const _OpeningMissionTeaserGrid();

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).height < 720;

    return GridView.count(
      crossAxisCount: 3,
      mainAxisSpacing: 9,
      crossAxisSpacing: 9,
      childAspectRatio: compact ? 0.82 : 0.72,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        for (final mission in MissionType.values)
          _OpeningMissionCard(mission: mission),
      ],
    );
  }
}

class _OpeningMissionCard extends StatelessWidget {
  const _OpeningMissionCard({required this.mission});

  final MissionType mission;

  @override
  Widget build(BuildContext context) {
    final color = _missionAccent(mission);

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 9, 8, 8),
      decoration: BoxDecoration(
        color: _SagaColors.ink.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.42)),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.16), blurRadius: 18),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Center(
              child: Image.asset(
                mission.crestAsset,
                width: 60,
                height: 60,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(mission.icon, color: color, size: 42);
                },
              ),
            ),
          ),
          Text(
            mission.label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _SagaColors.paper,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            _missionMicrocopy(mission),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _SagaColors.paper.withValues(alpha: 0.58),
              fontSize: 9,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimeRivalCutScreen extends StatelessWidget {
  const _AnimeRivalCutScreen({
    required this.frame,
    required this.pageIndex,
    required this.totalPages,
    required this.onPrimaryPressed,
  });

  final _OnboardingFrame frame;
  final int pageIndex;
  final int totalPages;
  final VoidCallback onPrimaryPressed;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).height < 720;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _OpHeader(number: frame.number, label: frame.episode),
        Spacer(flex: compact ? 1 : 2),
        _OpHeadline(
          title: frame.title,
          highlight: frame.highlight,
          color: _SagaColors.purple,
          maxFontSize: compact ? 29 : 34,
        ),
        SizedBox(height: compact ? 12 : 16),
        _OpSubtitle(frame.subtitle),
        const Spacer(),
        const _RivalCutList(),
        const Spacer(),
        _AnimeFooter(
          pageIndex: pageIndex,
          totalPages: totalPages,
          label: frame.action,
          color: _SagaColors.purple,
          onPressed: onPrimaryPressed,
        ),
      ],
    );
  }
}

class _RivalCutList extends StatelessWidget {
  const _RivalCutList();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _RivalCutLine(
          number: '01',
          label: 'Warm bed',
          color: _SagaColors.purple,
        ),
        _RivalCutLine(
          number: '02',
          label: 'Phone glow',
          color: _SagaColors.gold,
        ),
        _RivalCutLine(
          number: '03',
          label: 'Old loop',
          color: _SagaColors.signal,
        ),
      ],
    );
  }
}

class _RivalCutLine extends StatelessWidget {
  const _RivalCutLine({
    required this.number,
    required this.label,
    required this.color,
  });

  final String number;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: ClipPath(
        clipper: _SlantClipper(),
        child: Container(
          height: 58,
          padding: const EdgeInsets.fromLTRB(18, 0, 26, 0),
          color: _SagaColors.ink.withValues(alpha: 0.7),
          child: Row(
            children: [
              Text(
                number,
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _SagaColors.paper,
                    fontSize: 23,
                    height: 0.98,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
              ),
              Icon(Icons.close, color: color, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _SlantClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    return Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width - 18, size.height)
      ..lineTo(0, size.height)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _AlarmCutInPanel extends StatelessWidget {
  const _AlarmCutInPanel({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 16 : 20),
      decoration: BoxDecoration(
        color: _SagaColors.ink.withValues(alpha: 0.64),
        border: Border.all(color: _SagaColors.purple.withValues(alpha: 0.46)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: FittedBox(
                  alignment: Alignment.centerLeft,
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '06:30',
                    style: TextStyle(
                      color: _SagaColors.paper,
                      fontSize: compact ? 44 : 56,
                      height: 0.9,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Icon(
                Icons.keyboard_voice_outlined,
                color: _SagaColors.purple,
                size: 34,
              ),
            ],
          ),
          SizedBox(height: compact ? 12 : 18),
          const _OnboardingWaveform(),
        ],
      ),
    );
  }
}

class _PowerMontage extends StatelessWidget {
  const _PowerMontage({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(
          child: _PowerPanel(
            label: 'WAKE',
            caption: 'the cut-in',
            icon: Icons.bolt,
          ),
        ),
        SizedBox(width: 9),
        Expanded(
          child: _PowerPanel(
            label: 'FRAME',
            caption: 'the episode',
            icon: Icons.movie_creation_outlined,
          ),
        ),
        SizedBox(width: 9),
        Expanded(
          child: _PowerPanel(
            label: 'MOVE',
            caption: 'the opening',
            icon: Icons.flag,
          ),
        ),
      ],
    );
  }
}

class _PowerPanel extends StatelessWidget {
  const _PowerPanel({
    required this.label,
    required this.caption,
    required this.icon,
  });

  final String label;
  final String caption;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: _SlantClipper(),
      child: Container(
        height: 120,
        padding: const EdgeInsets.fromLTRB(11, 12, 9, 11),
        color: _SagaColors.ink.withValues(alpha: 0.64),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: _SagaColors.purple, size: 28),
            const Spacer(),
            Text(
              label,
              style: const TextStyle(
                color: _SagaColors.paper,
                fontSize: 15,
                height: 0.98,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _SagaColors.paper.withValues(alpha: 0.54),
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimeAlarmCutScreen extends StatelessWidget {
  const _AnimeAlarmCutScreen({
    required this.frame,
    required this.pageIndex,
    required this.totalPages,
    required this.onPrimaryPressed,
  });

  final _OnboardingFrame frame;
  final int pageIndex;
  final int totalPages;
  final VoidCallback onPrimaryPressed;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).height < 720;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _OpHeader(number: frame.number, label: frame.episode),
        Spacer(flex: compact ? 1 : 2),
        _OpHeadline(
          title: frame.title,
          highlight: frame.highlight,
          color: _SagaColors.purple,
          maxFontSize: compact ? 30 : 35,
        ),
        SizedBox(height: compact ? 12 : 16),
        _OpSubtitle(frame.subtitle),
        const Spacer(),
        _AlarmCutInPanel(compact: compact),
        SizedBox(height: compact ? 12 : 18),
        const _AnimeVoiceoverLine(),
        SizedBox(height: compact ? 14 : 22),
        _AnimeFooter(
          pageIndex: pageIndex,
          totalPages: totalPages,
          label: frame.action,
          color: _SagaColors.purple,
          onPressed: onPrimaryPressed,
        ),
      ],
    );
  }
}

class _AnimeVoiceoverLine extends StatelessWidget {
  const _AnimeVoiceoverLine();

  @override
  Widget build(BuildContext context) {
    return Text(
      '"Wake up. Your rivals don\'t sleep."',
      style: TextStyle(
        color: _SagaColors.paper.withValues(alpha: 0.88),
        fontSize: 17,
        height: 1.25,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _AnimePowerUpScreen extends StatelessWidget {
  const _AnimePowerUpScreen({
    required this.frame,
    required this.pageIndex,
    required this.totalPages,
    required this.onPrimaryPressed,
  });

  final _OnboardingFrame frame;
  final int pageIndex;
  final int totalPages;
  final VoidCallback onPrimaryPressed;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).height <= 720;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _OpHeader(number: frame.number, label: frame.episode),
        Spacer(flex: compact ? 1 : 2),
        _OpHeadline(
          title: frame.title,
          highlight: frame.highlight,
          color: _SagaColors.purple,
          maxFontSize: compact ? 30 : 35,
        ),
        SizedBox(height: compact ? 12 : 16),
        _OpSubtitle(frame.subtitle),
        const Spacer(),
        _PowerMontage(compact: compact),
        SizedBox(height: compact ? 14 : 18),
        const _AnimeFinalLine(),
        const Spacer(),
        _AnimeFooter(
          pageIndex: pageIndex,
          totalPages: totalPages,
          label: frame.action,
          color: _SagaColors.purple,
          onPressed: onPrimaryPressed,
        ),
      ],
    );
  }
}

class _AnimeFinalLine extends StatelessWidget {
  const _AnimeFinalLine();

  @override
  Widget build(BuildContext context) {
    return Text(
      'The opening ends when your feet hit the floor.',
      style: TextStyle(
        color: _SagaColors.paper.withValues(alpha: 0.76),
        fontSize: 15,
        height: 1.32,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _ReferencePrimaryButton extends StatelessWidget {
  const _ReferencePrimaryButton({
    required this.label,
    required this.color,
    required this.onPressed,
    this.compact = false,
  });

  final String label;
  final Color color;
  final VoidCallback onPressed;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final textColor = color.computeLuminance() > 0.5
        ? _SagaColors.ink
        : _SagaColors.paper;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          minimumSize: Size(48, compact ? 54 : 62),
          backgroundColor: color,
          foregroundColor: textColor,
          padding: EdgeInsets.fromLTRB(
            18,
            compact ? 8 : 10,
            14,
            compact ? 8 : 10,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                label.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: compact ? 16 : 18,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Roboto',
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.arrow_forward, color: _SagaColors.socialText),
          ],
        ),
      ),
    );
  }
}

class _ReferenceProgress extends StatelessWidget {
  const _ReferenceProgress({required this.index, required this.total});

  final int index;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < total; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            width: i == index ? 28 : 22,
            height: 5,
            margin: const EdgeInsets.symmetric(horizontal: 5),
            decoration: BoxDecoration(
              color: i == index
                  ? _SagaColors.purple
                  : _SagaColors.paper.withValues(alpha: 0.36),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
      ],
    );
  }
}

class _MissionCardGrid extends StatelessWidget {
  const _MissionCardGrid({
    required this.selectedMission,
    required this.onMissionSelected,
  });

  final MissionType selectedMission;
  final ValueChanged<MissionType> onMissionSelected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 430 ? 2 : 1;
        final width = (constraints.maxWidth - (columns - 1) * 10) / columns;

        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final mission in MissionType.values)
              SizedBox(
                width: width,
                child: _MissionReferenceCard(
                  mission: mission,
                  selected: mission == selectedMission,
                  onTap: () => onMissionSelected(mission),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _MissionReferenceCard extends StatelessWidget {
  const _MissionReferenceCard({
    required this.mission,
    required this.selected,
    required this.onTap,
  });

  final MissionType mission;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = _missionAccent(mission);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutBack,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected
                ? _SagaColors.panelHigh.withValues(alpha: 0.96)
                : _SagaColors.panelHigh.withValues(alpha: 0.76),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected
                  ? color
                  : _SagaColors.socialText.withValues(alpha: 0.08),
              width: selected ? 2 : 1,
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withValues(alpha: selected ? 0.28 : 0.08),
                _SagaColors.panelHigh.withValues(alpha: 0.94),
                _SagaColors.socialCream.withValues(
                  alpha: selected ? 0.46 : 0.18,
                ),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: selected ? 0.24 : 0.1),
                blurRadius: selected ? 26 : 12,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -18,
                top: -18,
                child: Icon(
                  mission.icon,
                  color: _SagaColors.socialText.withValues(
                    alpha: selected ? 0.08 : 0.04,
                  ),
                  size: 82,
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          color.withValues(alpha: selected ? 0.38 : 0.18),
                          _SagaColors.panelHigh.withValues(alpha: 0.52),
                          Colors.transparent,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: selected ? 0.42 : 0.2),
                          blurRadius: selected ? 26 : 16,
                        ),
                      ],
                    ),
                    child: Image.asset(
                      mission.crestAsset,
                      width: selected ? 54 : 50,
                      height: selected ? 54 : 50,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(mission.icon, color: color, size: 34);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _MiniSticker(
                          label: selected ? 'picked' : 'arc',
                          color: selected ? color : _SagaColors.socialYellow,
                        ),
                        const SizedBox(height: 7),
                        Text(
                          mission.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _SagaColors.socialText,
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _missionMicrocopy(mission),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _SagaColors.socialMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingWaveform extends StatelessWidget {
  const _OnboardingWaveform();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 116,
      width: double.infinity,
      child: CustomPaint(painter: _OnboardingWaveformPainter()),
    );
  }
}

class _OnboardingWaveformPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..color = _SagaColors.purple.withValues(alpha: 0.88);
    final centerY = size.height / 2;
    final bars = 40;
    for (var i = 0; i < bars; i++) {
      final x = size.width * (i + 0.5) / bars;
      final pulse = math.sin(i * 0.78).abs();
      final accent = math.sin(i * 0.31 + 1.2).abs();
      final h = 18 + pulse * 44 + accent * 24;
      canvas.drawLine(
        Offset(x, centerY - h / 2),
        Offset(x, centerY + h / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _OnboardingArtBackdrop extends StatelessWidget {
  const _OnboardingArtBackdrop({required this.frame});

  final _OnboardingFrame frame;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      frame.assetPath,
      fit: BoxFit.cover,
      alignment: Alignment.center,
      errorBuilder: (context, error, stackTrace) {
        return _NativeAnimeBackdrop(scene: frame.scene, accent: frame.accent);
      },
    );
  }
}

class _NativeAnimeBackdrop extends StatelessWidget {
  const _NativeAnimeBackdrop({required this.scene, required this.accent});

  final int scene;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _NativeAnimeBackdropPainter(scene: scene, accent: accent),
    );
  }
}

class _NativeAnimeBackdropPainter extends CustomPainter {
  const _NativeAnimeBackdropPainter({
    required this.scene,
    required this.accent,
  });

  final int scene;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final sky = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF050609),
          Color.lerp(_SagaColors.panel, accent, 0.18)!,
          _SagaColors.ink,
        ],
        stops: const [0, 0.48, 1],
      ).createShader(rect);
    canvas.drawRect(rect, sky);

    _paintSunrise(canvas, size);
    _paintScene(canvas, size);
    _paintSpeedLines(canvas, size);
    _paintMangaFrame(canvas, size);
  }

  void _paintSunrise(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.64, size.height * 0.27);
    for (var i = 0; i < 5; i++) {
      canvas.drawCircle(
        center,
        64.0 + i * 42,
        Paint()..color = accent.withValues(alpha: 0.13 - i * 0.018),
      );
    }
    canvas.drawCircle(
      center,
      48,
      Paint()
        ..shader = RadialGradient(
          colors: [accent, _SagaColors.gold.withValues(alpha: 0.1)],
        ).createShader(Rect.fromCircle(center: center, radius: 72)),
    );
  }

  void _paintScene(Canvas canvas, Size size) {
    switch (scene) {
      case 1:
        _paintMissionDesk(canvas, size);
      case 2:
        _paintWakeSignal(canvas, size);
      case 3:
        _paintDoorwayRun(canvas, size);
      default:
        _paintProtagonistWake(canvas, size);
    }
  }

  void _paintProtagonistWake(Canvas canvas, Size size) {
    final horizon = Offset(size.width * 0.54, size.height * 0.62);
    canvas.drawCircle(
      horizon,
      size.width * 0.28,
      Paint()
        ..shader = RadialGradient(
          colors: [
            _SagaColors.gold.withValues(alpha: 0.82),
            const Color(0xFFFF7A45).withValues(alpha: 0.34),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: horizon, radius: size.width)),
    );

    final mountain = Path()
      ..moveTo(0, size.height * 0.66)
      ..lineTo(size.width * 0.18, size.height * 0.55)
      ..lineTo(size.width * 0.36, size.height * 0.64)
      ..lineTo(size.width * 0.56, size.height * 0.5)
      ..lineTo(size.width * 0.84, size.height * 0.67)
      ..lineTo(size.width, size.height * 0.57)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(mountain, Paint()..color = const Color(0xFF10131D));

    final skylinePaint = Paint()..color = const Color(0xFF080A0E);
    for (var i = 0; i < 13; i++) {
      final width = 18.0 + (i % 3) * 9;
      final height = size.height * (0.08 + (i % 5) * 0.026);
      final left = size.width * 0.02 + i * size.width * 0.078;
      canvas.drawRect(
        Rect.fromLTWH(left, size.height * 0.72 - height, width, height),
        skylinePaint,
      );
    }

    final shadow = Paint()..color = _SagaColors.ink.withValues(alpha: 0.92);
    final head = Offset(size.width * 0.58, size.height * 0.47);
    canvas.drawCircle(head, 22, shadow);
    final body = Path()
      ..moveTo(size.width * 0.53, size.height * 0.51)
      ..lineTo(size.width * 0.64, size.height * 0.51)
      ..lineTo(size.width * 0.71, size.height * 0.73)
      ..lineTo(size.width * 0.47, size.height * 0.73)
      ..close();
    canvas.drawPath(body, shadow);
    canvas.drawLine(
      Offset(size.width * 0.52, size.height * 0.58),
      Offset(size.width * 0.44, size.height * 0.7),
      shadow..strokeWidth = 12,
    );
    canvas.drawLine(
      Offset(size.width * 0.64, size.height * 0.58),
      Offset(size.width * 0.74, size.height * 0.69),
      shadow..strokeWidth = 12,
    );
    canvas.drawLine(
      Offset(size.width * 0.55, size.height * 0.53),
      Offset(size.width * 0.47, size.height * 0.61),
      shadow..strokeWidth = 9,
    );
  }

  void _paintMissionDesk(Canvas canvas, Size size) {
    final window = Rect.fromLTWH(
      size.width * 0.12,
      size.height * 0.06,
      size.width * 0.76,
      size.height * 0.38,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(window, const Radius.circular(18)),
      Paint()..color = const Color(0xFF101729),
    );
    canvas.drawCircle(
      Offset(
        window.left + window.width * 0.72,
        window.top + window.height * 0.28,
      ),
      24,
      Paint()..color = _SagaColors.gold.withValues(alpha: 0.82),
    );
    final horizon = Path()
      ..moveTo(window.left, window.bottom)
      ..lineTo(
        window.left + window.width * 0.28,
        window.top + window.height * 0.58,
      )
      ..lineTo(window.left + window.width * 0.5, window.bottom)
      ..lineTo(
        window.left + window.width * 0.7,
        window.top + window.height * 0.5,
      )
      ..lineTo(window.right, window.bottom)
      ..close();
    canvas.drawPath(horizon, Paint()..color = const Color(0xFF1F2740));

    final desk = Paint()..color = const Color(0xFF17120E);
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.48, size.width, size.height * 0.52),
      desk,
    );
    final phoneRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(size.width * 0.63, size.height * 0.56),
        width: 112,
        height: 172,
      ),
      const Radius.circular(24),
    );
    canvas.drawRRect(phoneRect, Paint()..color = _SagaColors.ink);
    canvas.drawCircle(
      Offset(size.width * 0.63, size.height * 0.56),
      26,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..color = accent,
    );
    _paintShoe(canvas, Offset(size.width * 0.24, size.height * 0.58), 1.0);
    _paintNotebook(canvas, size);
  }

  void _paintWakeSignal(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.56, size.height * 0.36);
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = const Color(0xFF73E8FF).withValues(alpha: 0.38);
    for (var i = 0; i < 4; i++) {
      canvas.drawCircle(center, 54.0 + i * 46, ringPaint);
    }
    for (var i = 0; i < 18; i++) {
      final angle = i * math.pi / 9;
      canvas.drawLine(
        center,
        center + Offset(math.cos(angle), math.sin(angle)) * size.width * 0.42,
        Paint()
          ..color = const Color(0xFF73E8FF).withValues(alpha: 0.09)
          ..strokeWidth = 1.4,
      );
    }

    final phone = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(size.width * 0.56, size.height * 0.38),
        width: 158,
        height: 58,
      ),
      const Radius.circular(18),
    );
    canvas.drawRRect(phone, Paint()..color = const Color(0xFF070809));
    final signal = Paint()
      ..color = accent
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final path = Path()..moveTo(size.width * 0.08, size.height * 0.38);
    for (var i = 0; i < 24; i++) {
      final x = size.width * (0.08 + i * 0.038);
      final y = size.height * (0.38 + math.sin(i * 0.9) * 0.052);
      path.lineTo(x, y);
    }
    canvas.drawPath(path, signal);
    for (var i = 0; i < 9; i++) {
      canvas.drawLine(
        Offset(size.width * (0.36 + i * 0.035), size.height * 0.52),
        Offset(
          size.width * (0.36 + i * 0.035),
          size.height * (0.34 - i * 0.01),
        ),
        signal..color = accent.withValues(alpha: 0.56),
      );
    }
  }

  void _paintDoorwayRun(Canvas canvas, Size size) {
    final door = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.36,
        size.height * 0.08,
        size.width * 0.44,
        size.height * 0.62,
      ),
      const Radius.circular(18),
    );
    canvas.drawRRect(
      door,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _SagaColors.gold.withValues(alpha: 0.86),
            const Color(0xFFFF6E39).withValues(alpha: 0.62),
            _SagaColors.ink.withValues(alpha: 0.12),
          ],
        ).createShader(door.outerRect),
    );
    for (var i = 0; i < 18; i++) {
      final start = Offset(size.width * 0.58, size.height * 0.32);
      final end = Offset(
        size.width * (0.12 + i * 0.05),
        size.height * (0.05 + (i % 6) * 0.12),
      );
      canvas.drawLine(
        start,
        end,
        Paint()
          ..color = _SagaColors.gold.withValues(alpha: 0.18)
          ..strokeWidth = 1.4,
      );
    }

    final floor = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width * 0.42, size.height * 0.56)
      ..lineTo(size.width * 0.58, size.height * 0.56)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(floor, Paint()..color = const Color(0xFF10100E));
    final bodyPaint = Paint()..color = _SagaColors.ink.withValues(alpha: 0.9);
    canvas.drawCircle(
      Offset(size.width * 0.52, size.height * 0.29),
      28,
      bodyPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(size.width * 0.52, size.height * 0.42),
          width: 64,
          height: 130,
        ),
        const Radius.circular(22),
      ),
      bodyPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.5, size.height * 0.49),
      Offset(size.width * 0.42, size.height * 0.68),
      bodyPaint..strokeWidth = 18,
    );
    canvas.drawLine(
      Offset(size.width * 0.55, size.height * 0.49),
      Offset(size.width * 0.65, size.height * 0.69),
      bodyPaint..strokeWidth = 18,
    );
  }

  void _paintShoe(Canvas canvas, Offset center, double scale) {
    final shoe = Path()
      ..moveTo(center.dx - 62 * scale, center.dy + 20 * scale)
      ..quadraticBezierTo(
        center.dx - 18 * scale,
        center.dy - 38 * scale,
        center.dx + 38 * scale,
        center.dy - 12 * scale,
      )
      ..quadraticBezierTo(
        center.dx + 78 * scale,
        center.dy + 10 * scale,
        center.dx + 56 * scale,
        center.dy + 28 * scale,
      )
      ..lineTo(center.dx - 58 * scale, center.dy + 34 * scale)
      ..close();
    canvas.drawPath(shoe, Paint()..color = const Color(0xFF1B1D1A));
    canvas.drawPath(
      shoe,
      Paint()
        ..color = accent.withValues(alpha: 0.38)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  void _paintNotebook(Canvas canvas, Size size) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.62, size.height * 0.62, 120, 92),
        const Radius.circular(8),
      ),
      Paint()..color = const Color(0xFF2A241B),
    );
    for (var i = 0; i < 4; i++) {
      canvas.drawLine(
        Offset(size.width * 0.65, size.height * (0.65 + i * 0.025)),
        Offset(size.width * 0.84, size.height * (0.65 + i * 0.025)),
        Paint()
          ..color = _SagaColors.gold.withValues(alpha: 0.18)
          ..strokeWidth = 1,
      );
    }
  }

  void _paintSpeedLines(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = accent.withValues(alpha: 0.2)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    final origin = Offset(size.width * 0.68, size.height * 0.26);
    for (var i = 0; i < 24; i++) {
      final angle = -math.pi * 0.9 + i * math.pi / 18;
      final start = Offset(
        origin.dx + math.cos(angle) * 90,
        origin.dy + math.sin(angle) * 90,
      );
      final end = Offset(
        origin.dx + math.cos(angle) * 360,
        origin.dy + math.sin(angle) * 360,
      );
      canvas.drawLine(start, end, paint);
    }
  }

  void _paintMangaFrame(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _SagaColors.paper.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(14, 58, size.width - 28, size.height - 100),
        const Radius.circular(24),
      ),
      paint,
    );
    canvas.drawLine(
      Offset(24, size.height * 0.18),
      Offset(size.width * 0.62, 72),
      paint..color = accent.withValues(alpha: 0.3),
    );
  }

  @override
  bool shouldRepaint(covariant _NativeAnimeBackdropPainter oldDelegate) {
    return oldDelegate.scene != scene || oldDelegate.accent != accent;
  }
}

class _ScreenStack extends StatelessWidget {
  const _ScreenStack({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow.toUpperCase(),
          style: const TextStyle(
            color: _PrototypeColors.coral,
            fontWeight: FontWeight.w900,
            fontSize: 10.5,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          title,
          style: const TextStyle(
            color: _PrototypeColors.ink,
            fontSize: 24,
            fontWeight: FontWeight.w900,
            height: 1.05,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 5),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Text(
            subtitle,
            style: const TextStyle(
              color: _PrototypeColors.muted,
              fontSize: 13,
              height: 1.3,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 12),
        ...children.expand((child) => [child, const SizedBox(height: 10)]),
      ],
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child, this.padding = const EdgeInsets.all(22)});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: _PrototypeDecor.card,
      child: child,
    );
  }
}

class _SideNavigation extends StatelessWidget {
  const _SideNavigation({
    required this.profile,
    required this.selectedIndex,
    required this.stages,
    required this.onSelect,
  });

  final SagaProfile profile;
  final int selectedIndex;
  final List<_StageDestination> stages;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 244,
      padding: const EdgeInsets.fromLTRB(22, 26, 18, 22),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        border: const Border(right: BorderSide(color: _PrototypeColors.line)),
        boxShadow: [
          BoxShadow(
            color: _PrototypeColors.ink.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(8, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _BrandLockup(),
          const SizedBox(height: 28),
          _ProfilePlate(profile: profile),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.separated(
              itemCount: stages.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final stage = stages[index];
                return _StageButton(
                  destination: stage,
                  selected: selectedIndex == index,
                  onTap: () => onSelect(index),
                );
              },
            ),
          ),
          const _StatStack(),
        ],
      ),
    );
  }
}

class _CompactHeader extends StatelessWidget {
  const _CompactHeader({required this.profile});

  final SagaProfile profile;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 5, 16, 5),
      decoration: const BoxDecoration(
        color: Color(0xFFFBF5EC),
        border: Border(
          bottom: BorderSide(color: _PrototypeColors.line, width: 0.6),
        ),
      ),
      child: Row(
        children: [
          const _BrandLockup(compact: true),
          const Spacer(),
          _StatusPill(
            icon: Icons.alarm_on_outlined,
            label: profile.wakeTime.format(context),
            color: _SagaColors.gold,
          ),
        ],
      ),
    );
  }
}

class _BottomSectionBar extends StatelessWidget {
  const _BottomSectionBar({
    required this.selectedIndex,
    required this.sections,
    required this.onSelect,
  });

  final int selectedIndex;
  final List<_StageDestination> sections;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: _PrototypeColors.line, width: 0.6),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 50,
          child: Row(
            children: [
              for (var index = 0; index < sections.length; index++)
                Expanded(
                  child: _BottomSectionTab(
                    section: sections[index],
                    selected: selectedIndex == index,
                    onTap: () => onSelect(index),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomSectionTab extends StatelessWidget {
  const _BottomSectionTab({
    required this.section,
    required this.selected,
    required this.onTap,
  });

  final _StageDestination section;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? _PrototypeColors.coral : _PrototypeColors.muted;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(section.icon, color: color, size: 21),
            const SizedBox(height: 2),
            Text(
              section.label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrandLockup extends StatelessWidget {
  const _BrandLockup({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'WakeSaga',
      image: true,
      child: Image.asset(
        'assets/brand/wakesaga_logo.png',
        width: compact ? 96 : 180,
        height: compact ? 30 : 62,
        fit: BoxFit.contain,
        alignment: Alignment.centerLeft,
        errorBuilder: (context, error, stackTrace) {
          return _FallbackBrandLockup(compact: compact);
        },
      ),
    );
  }
}

class _FallbackBrandLockup extends StatelessWidget {
  const _FallbackBrandLockup({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: compact ? 34 : 40,
          height: compact ? 34 : 40,
          decoration: BoxDecoration(
            color: _PrototypeColors.gold,
            shape: BoxShape.circle,
            border: Border.all(color: _PrototypeColors.ink, width: 1.4),
          ),
          child: const Icon(
            Icons.wb_twilight_outlined,
            color: _PrototypeColors.ink,
          ),
        ),
        const SizedBox(width: 10),
        Text('WakeSaga', style: Theme.of(context).textTheme.titleLarge),
      ],
    );
  }
}

class _ProfilePlate extends StatelessWidget {
  const _ProfilePlate({required this.profile});

  final SagaProfile profile;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(profile.name, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            profile.goal,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _PrototypeColors.muted,
              height: 1.28,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          _StatusPill(
            icon: profile.voice.icon,
            label: profile.voice.label,
            color: _SagaColors.signal,
          ),
          const SizedBox(height: 8),
          _StatusPill(
            icon: Icons.alarm_on_outlined,
            label: profile.wakeTime.format(context),
            color: _SagaColors.gold,
          ),
        ],
      ),
    );
  }
}

class _StageButton extends StatelessWidget {
  const _StageButton({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final _StageDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(
            minWidth: double.infinity,
            minHeight: 50,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? _PrototypeColors.coral.withValues(alpha: 0.1)
                : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? _PrototypeColors.coral : _PrototypeColors.line,
              width: selected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: _PrototypeColors.ink.withValues(
                  alpha: selected ? 0.08 : 0.03,
                ),
                blurRadius: selected ? 16 : 8,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: selected
                      ? _PrototypeColors.aqua
                      : const Color(0xFFFFE7BD),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  destination.icon,
                  size: 17,
                  color: _PrototypeColors.ink,
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  destination.label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected
                        ? _PrototypeColors.ink
                        : _PrototypeColors.muted,
                    fontWeight: FontWeight.w900,
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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: const BoxDecoration(
            color: _PrototypeColors.aqua,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: _PrototypeColors.ink),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            text,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
        ),
      ],
    );
  }
}

class _ScriptBlock extends StatelessWidget {
  const _ScriptBlock({required this.text, this.compact = false});

  final String text;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFFFFF2EA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _PrototypeColors.line),
      ),
      child: Stack(
        children: [
          const Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: SizedBox(
              width: 3,
              child: DecoratedBox(
                decoration: BoxDecoration(color: _PrototypeColors.coral),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(compact ? 12 : 18),
            child: Text(
              text,
              maxLines: compact ? 3 : null,
              overflow: compact ? TextOverflow.ellipsis : null,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontSize: compact ? 13 : null,
                height: compact ? 1.32 : 1.45,
                color: _PrototypeColors.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LockChip extends StatelessWidget {
  const _LockChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? _PrototypeColors.aqua : Colors.white,
      borderRadius: BorderRadius.circular(99),
      child: InkWell(
        borderRadius: BorderRadius.circular(99),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(99),
            border: Border.all(
              color: selected ? _PrototypeColors.coral : _PrototypeColors.line,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 15,
                color: selected ? _PrototypeColors.ink : _PrototypeColors.coral,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: selected ? _PrototypeColors.ink : _PrototypeColors.ink,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LockDurationButton extends StatelessWidget {
  const _LockDurationButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? _PrototypeColors.gold : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? _PrototypeColors.ink : _PrototypeColors.line,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (selected) ...[
                const Icon(Icons.check, color: _PrototypeColors.ink, size: 15),
                const SizedBox(width: 5),
              ],
              Text(
                label,
                style: const TextStyle(
                  color: _PrototypeColors.ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final visibleColor = color == _SagaColors.muted
        ? _PrototypeColors.muted
        : color;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: visibleColor.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: visibleColor.withValues(alpha: 0.46)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: visibleColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: visibleColor,
              fontSize: 11.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _AlarmTimeBadge extends StatelessWidget {
  const _AlarmTimeBadge({required this.time});

  final String time;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _PrototypeColors.gold.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.alarm_on_outlined,
            color: _PrototypeColors.gold,
            size: 16,
          ),
          const SizedBox(width: 5),
          Text(
            time,
            style: const TextStyle(
              color: _PrototypeColors.ink,
              fontSize: 14,
              height: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniProtocolTrack extends StatelessWidget {
  const _MiniProtocolTrack({required this.steps});

  final List<_ProtocolStep> steps;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var index = 0; index < steps.length; index++) ...[
          Expanded(child: _MiniProtocolDot(step: steps[index])),
          if (index != steps.length - 1)
            Container(
              width: 12,
              height: 2,
              color: steps[index].complete
                  ? _PrototypeColors.coral
                  : _PrototypeColors.line,
            ),
        ],
      ],
    );
  }
}

class _MiniProtocolDot extends StatelessWidget {
  const _MiniProtocolDot({required this.step});

  final _ProtocolStep step;

  @override
  Widget build(BuildContext context) {
    final color = step.complete
        ? _PrototypeColors.coral
        : step.active
        ? _PrototypeColors.gold
        : _PrototypeColors.muted;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.13),
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha: 0.5)),
          ),
          child: Icon(
            step.complete ? Icons.check : step.icon,
            color: color,
            size: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          step.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: step.active || step.complete
                ? _PrototypeColors.ink
                : _PrototypeColors.muted,
            fontSize: 9.5,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _ProtocolStep {
  const _ProtocolStep(this.label, this.icon, this.complete, this.active);

  final String label;
  final IconData icon;
  final bool complete;
  final bool active;
}

class _ProtocolRail extends StatelessWidget {
  const _ProtocolRail({required this.steps});

  final List<_ProtocolStep> steps;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var index = 0; index < steps.length; index++) ...[
              _ProtocolStepChip(step: steps[index]),
              if (index != steps.length - 1)
                Container(
                  width: 28,
                  height: 3,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: steps[index].complete
                        ? _PrototypeColors.coral
                        : _PrototypeColors.line,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProtocolStepChip extends StatelessWidget {
  const _ProtocolStepChip({required this.step});

  final _ProtocolStep step;

  @override
  Widget build(BuildContext context) {
    final color = step.complete
        ? _PrototypeColors.coral
        : step.active
        ? _PrototypeColors.gold
        : _PrototypeColors.muted;

    return SizedBox(
      width: 82,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.16),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.5)),
            ),
            child: Icon(
              step.complete ? Icons.check : step.icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            step.label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: step.active || step.complete
                  ? _PrototypeColors.ink
                  : _PrototypeColors.muted,
              fontSize: 11,
              height: 1.1,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScriptPreviewLine extends StatelessWidget {
  const _ScriptPreviewLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF2EA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _PrototypeColors.line),
      ),
      child: Text(
        text,
        maxLines: 4,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: _PrototypeColors.ink,
          height: 1.38,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ReceiptSummaryStrip extends StatelessWidget {
  const _ReceiptSummaryStrip({
    required this.count,
    required this.action,
    required this.score,
  });

  final int count;
  final String action;
  final int score;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Row(
        children: [
          Expanded(
            child: _ReceiptMicroStat(
              icon: Icons.style_outlined,
              label: 'Receipts',
              value: '$count',
            ),
          ),
          _TinyDivider(),
          Expanded(
            child: _ReceiptMicroStat(
              icon: Icons.flag_outlined,
              label: 'Action',
              value: action,
            ),
          ),
          _TinyDivider(),
          Expanded(
            child: _ReceiptMicroStat(
              icon: Icons.auto_awesome_outlined,
              label: 'Score',
              value: '$score/5',
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceiptMicroStat extends StatelessWidget {
  const _ReceiptMicroStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: _PrototypeColors.coral, size: 17),
        const SizedBox(width: 7),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _PrototypeColors.aquaDark,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _PrototypeColors.ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TinyDivider extends StatelessWidget {
  const _TinyDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 34,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: _PrototypeColors.line,
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.tiles});

  final List<Widget> tiles;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          for (var index = 0; index < tiles.length; index++) ...[
            tiles[index],
            if (index != tiles.length - 1) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _PrototypeColors.line),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(
                  color: _PrototypeColors.aqua,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: _PrototypeColors.ink, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: _PrototypeColors.ink,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _PrototypeColors.muted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: _PrototypeColors.muted,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectionSheet<T> extends StatelessWidget {
  const _SelectionSheet({
    required this.title,
    required this.values,
    required this.selected,
    required this.labelFor,
    required this.descriptionFor,
    required this.iconFor,
    required this.onSelected,
  });

  final String title;
  final Iterable<T> values;
  final T selected;
  final String Function(T value) labelFor;
  final String Function(T value) descriptionFor;
  final IconData Function(T value) iconFor;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 14),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: values.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final value = values.elementAt(index);
                  final isSelected = value == selected;

                  return Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => onSelected(value),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? _PrototypeColors.coral
                                : _PrototypeColors.line,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? _PrototypeColors.aqua
                                    : const Color(0xFFFFE7BD),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                iconFor(value),
                                color: _PrototypeColors.ink,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    labelFor(value),
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    descriptionFor(value),
                                    style: const TextStyle(
                                      color: _PrototypeColors.muted,
                                      fontWeight: FontWeight.w700,
                                      height: 1.25,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              isSelected
                                  ? Icons.check_circle
                                  : Icons.radio_button_unchecked,
                              color: isSelected
                                  ? _PrototypeColors.coral
                                  : _PrototypeColors.muted,
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
        ),
      ),
    );
  }
}

class _EpisodeCard extends StatelessWidget {
  const _EpisodeCard({required this.card});

  final EpisodeCardData card;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _PrototypeColors.coral.withValues(alpha: 0.56),
        ),
        boxShadow: [
          BoxShadow(
            color: _PrototypeColors.coral.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: _PrototypeColors.coral.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.bolt,
                  color: _PrototypeColors.coral,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Wake Receipt',
                  style: TextStyle(
                    color: _PrototypeColors.aquaDark,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                '${card.createdAt.month}/${card.createdAt.day}',
                style: const TextStyle(color: _PrototypeColors.muted),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            card.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _PrototypeColors.ink,
              fontSize: 21,
              fontWeight: FontWeight.w900,
              height: 1.04,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            card.quote,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _PrototypeColors.coral,
              fontSize: 14,
              height: 1.28,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          Divider(color: _PrototypeColors.line),
          const SizedBox(height: 8),
          _CardMeta(label: 'Mission', value: card.mission),
          _CardMeta(label: 'Action', value: card.action),
          _CardMeta(label: 'Score', value: '${card.score}/5'),
          if (card.reflection.isNotEmpty)
            _CardMeta(label: 'Note', value: card.reflection),
        ],
      ),
    );
  }
}

class _CardMeta extends StatelessWidget {
  const _CardMeta({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 64,
            child: Text(
              label,
              style: const TextStyle(
                color: _PrototypeColors.aquaDark,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: _PrototypeColors.ink,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SagaCalibrationEntrance extends StatefulWidget {
  const _SagaCalibrationEntrance({super.key, required this.onComplete});

  final VoidCallback onComplete;

  @override
  State<_SagaCalibrationEntrance> createState() =>
      _SagaCalibrationEntranceState();
}

class _SagaCalibrationEntranceState extends State<_SagaCalibrationEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    HapticFeedback.mediumImpact();
    _controller =
        AnimationController(
            vsync: this,
            duration: const Duration(milliseconds: 4200),
          )
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) {
              HapticFeedback.heavyImpact();
              widget.onComplete();
            }
          })
          ..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final value = _controller.value;
        final title = value < 0.26
            ? 'PICKING YOUR\nWAKE PERSONA'
            : value < 0.58
            ? 'NAMING\nTHE RIVAL'
            : value < 0.84
            ? 'BUILDING\nYOUR ARC'
            : 'OPENING\nSAGA GATE';
        final phase = value < 0.26
            ? 'PERSONA'
            : value < 0.58
            ? 'RIVAL'
            : value < 0.84
            ? 'ARC'
            : 'READY';
        final subtitle = value < 0.26
            ? 'Choosing the version of you that actually gets up.'
            : value < 0.58
            ? 'Finding what steals the opening scene.'
            : value < 0.84
            ? 'Linking narrator, Wake Quest, and first win.'
            : 'Your morning persona is ready.';
        final glow = Color.lerp(
          _SagaColors.socialYellow,
          _SagaColors.socialPink,
          value,
        )!;
        final flashOpacity = value > 0.92 ? (value - 0.92) * 9 : 0.0;
        final bootOpacity = (value / 0.18).clamp(0.0, 1.0);
        final titleOpacity = ((value - 0.1) / 0.2).clamp(0.0, 1.0);
        final percent = (value * 100).clamp(0, 99).round();

        return Stack(
          fit: StackFit.expand,
          children: [
            const _PersonaBuilderBackdrop(),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    _SagaColors.socialCard.withValues(alpha: 0.22),
                    _SagaColors.socialLilac.withValues(alpha: 0.48),
                    _SagaColors.socialCream.withValues(alpha: 0.96),
                  ],
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0.1 + value * 0.12, -0.22),
                  radius: 1.02,
                  colors: [
                    glow.withValues(alpha: 0.34),
                    _SagaColors.socialBlue.withValues(alpha: 0.16),
                    _SagaColors.socialCard.withValues(alpha: 0.2),
                  ],
                  stops: const [0, 0.44, 1],
                ),
              ),
            ),
            CustomPaint(
              painter: _SagaEntranceRiftPainter(progress: value, color: glow),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 34),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Opacity(
                      opacity: bootOpacity.toDouble(),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'WAKE SAGA / PERSONA BUILDER',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: _SagaColors.socialText,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0,
                              ),
                            ),
                          ),
                          Text(
                            '$percent%',
                            style: const TextStyle(
                              color: _SagaColors.socialText,
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              height: 0.9,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Opacity(
                      opacity: bootOpacity.toDouble(),
                      child: Row(
                        children: [
                          _SagaEntranceChip(label: phase, color: glow),
                          const SizedBox(width: 8),
                          _SagaEntranceChip(
                            label: 'EPISODE 001',
                            color: _SagaColors.paper,
                          ),
                        ],
                      ),
                    ),
                    const Spacer(flex: 3),
                    Center(
                      child: Transform.scale(
                        scale:
                            0.92 + Curves.easeOutBack.transform(value) * 0.08,
                        child: Container(
                          width: double.infinity,
                          constraints: const BoxConstraints(maxWidth: 460),
                          padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
                          decoration: BoxDecoration(
                            color: _SagaColors.socialCard.withValues(
                              alpha: 0.94,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _SagaColors.socialText.withValues(
                                alpha: 0.1,
                              ),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _SagaColors.socialPink.withValues(
                                  alpha: 0.18,
                                ),
                                blurRadius: 34,
                                spreadRadius: 3,
                                offset: const Offset(0, 16),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 30,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      color: glow,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.auto_awesome,
                                      color: _SagaColors.socialText,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'MORNING PERSONA',
                                      style: TextStyle(
                                        color: _SagaColors.socialMuted,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Transform.translate(
                                offset: Offset(0, 28 * (1 - titleOpacity)),
                                child: Opacity(
                                  opacity: titleOpacity.toDouble(),
                                  child: Text(
                                    title,
                                    style: const TextStyle(
                                      color: _SagaColors.socialText,
                                      fontSize: 41,
                                      fontWeight: FontWeight.w900,
                                      height: 0.9,
                                      letterSpacing: 0,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                subtitle,
                                style: const TextStyle(
                                  color: _SagaColors.socialMuted,
                                  fontSize: 16,
                                  height: 1.25,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const Spacer(flex: 2),
                    Opacity(
                      opacity: bootOpacity.toDouble(),
                      child: Row(
                        children: [
                          _SagaEntranceSignal(
                            label: 'ARC',
                            value: value > 0.22,
                            color: glow,
                          ),
                          _SagaEntranceSignal(
                            label: 'VOICE',
                            value: value > 0.5,
                            color: glow,
                          ),
                          _SagaEntranceSignal(
                            label: 'JOLT',
                            value: value > 0.74,
                            color: glow,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: Opacity(
                        opacity: bootOpacity.toDouble(),
                        child: LinearProgressIndicator(
                          value: value,
                          minHeight: 9,
                          backgroundColor: _SagaColors.socialText.withValues(
                            alpha: 0.13,
                          ),
                          color: glow,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            IgnorePointer(
              child: Opacity(
                opacity: flashOpacity.clamp(0.0, 0.8),
                child: const DecoratedBox(
                  decoration: BoxDecoration(color: _SagaColors.paper),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SagaEntranceChip extends StatelessWidget {
  const _SagaEntranceChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: _SagaColors.socialCard.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _SagaColors.socialText.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.14),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Text(
        label,
        style: TextStyle(
          color: _SagaColors.socialText,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _SagaEntranceSignal extends StatelessWidget {
  const _SagaEntranceSignal({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final bool value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: value
              ? color.withValues(alpha: 0.18)
              : _SagaColors.socialCard.withValues(alpha: 0.74),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: value
                ? color.withValues(alpha: 0.62)
                : _SagaColors.socialText.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              value ? Icons.check_circle : Icons.radio_button_unchecked,
              color: value ? _SagaColors.socialText : _SagaColors.socialMuted,
              size: 15,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: value
                      ? _SagaColors.socialText
                      : _SagaColors.socialMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SagaEntranceRiftPainter extends CustomPainter {
  const _SagaEntranceRiftPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.52, size.height * 0.42);
    final pulse = Curves.easeInOutCubic.transform(progress);
    final shock = math.sin(progress * math.pi).abs();
    final haloPaint = Paint()
      ..shader =
          RadialGradient(
            colors: [
              color.withValues(alpha: 0.34),
              color.withValues(alpha: 0.08),
              Colors.transparent,
            ],
          ).createShader(
            Rect.fromCircle(center: center, radius: size.width * 0.72),
          );
    canvas.drawCircle(center, size.width * (0.28 + shock * 0.08), haloPaint);

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = color.withValues(alpha: 0.28 + progress * 0.28);

    for (var i = 0; i < 6; i++) {
      final radius = 42 + i * 34 + pulse * 52;
      canvas.drawCircle(
        center,
        radius,
        ringPaint..strokeWidth = math.max(0.8, 3 - i * 0.28),
      );
    }

    final slashPaint = Paint()
      ..strokeWidth = 1.35
      ..strokeCap = StrokeCap.round
      ..color = color.withValues(alpha: 0.18 + shock * 0.12);
    for (var i = 0; i < 20; i++) {
      final t = (i / 20 + progress * 1.8) % 1;
      final x = size.width * t;
      canvas.drawLine(
        Offset(x - 62, size.height * -0.04),
        Offset(x + 70, size.height * 0.86),
        slashPaint,
      );
    }

    final scanPaint = Paint()
      ..strokeWidth = 2
      ..color = _SagaColors.socialText.withValues(alpha: 0.06 + shock * 0.1);
    final scanY = size.height * (0.14 + (progress * 1.35 % 1) * 0.62);
    canvas.drawLine(Offset(0, scanY), Offset(size.width, scanY), scanPaint);

    final cornerPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.square
      ..color = color.withValues(alpha: 0.38);
    final inset = size.width * 0.08;
    final top = size.height * 0.2;
    final bottom = size.height * 0.72;
    final corner = size.width * 0.12;
    canvas.drawLine(
      Offset(inset, top),
      Offset(inset + corner, top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(inset, top),
      Offset(inset, top + corner),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(size.width - inset, top),
      Offset(size.width - inset - corner, top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(size.width - inset, top),
      Offset(size.width - inset, top + corner),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(inset, bottom),
      Offset(inset + corner, bottom),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(size.width - inset, bottom),
      Offset(size.width - inset - corner, bottom),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _SagaEntranceRiftPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

class _SagaSetupQuiz extends StatelessWidget {
  const _SagaSetupQuiz({
    super.key,
    required this.stepIndex,
    required this.nameController,
    required this.goalController,
    required this.selectedMission,
    required this.selectedVoice,
    required this.wakeTime,
    required this.selectedObstacle,
    required this.selectedRitual,
    required this.builderAnswers,
    required this.onMissionSelected,
    required this.onVoiceSelected,
    required this.onWakeTimePressed,
    required this.onObstacleSelected,
    required this.onRitualSelected,
    required this.onAnswerSelected,
    required this.onBack,
    required this.onContinue,
  });

  final int stepIndex;
  final TextEditingController nameController;
  final TextEditingController goalController;
  final MissionType selectedMission;
  final VoiceArchetype selectedVoice;
  final String wakeTime;
  final String selectedObstacle;
  final String selectedRitual;
  final Map<String, String> builderAnswers;
  final ValueChanged<MissionType> onMissionSelected;
  final ValueChanged<VoiceArchetype> onVoiceSelected;
  final VoidCallback onWakeTimePressed;
  final ValueChanged<String> onObstacleSelected;
  final ValueChanged<String> onRitualSelected;
  final void Function(String stepId, String optionId) onAnswerSelected;
  final VoidCallback onBack;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final step = _sagaSetupSteps[stepIndex];
    final progress = (stepIndex + 1) / _sagaSetupSteps.length;
    final isFinal = stepIndex == _sagaSetupSteps.length - 1;
    final media = MediaQuery.of(context);
    final keyboardInset = media.viewInsets.bottom;
    final keyboardVisible = keyboardInset > 0;
    final compactVertical = keyboardVisible || media.size.height <= 700;
    final scrollBottomPadding = keyboardVisible ? 168.0 : 132.0;

    return Column(
      children: [
        if (keyboardVisible)
          SizedBox(height: media.padding.top + 8)
        else
          SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                22,
                compactVertical ? 8 : 16,
                22,
                compactVertical ? 6 : 10,
              ),
              child: _SagaQuizProgress(
                progress: progress,
                chapter: step.chapter,
                stepNumber: stepIndex + 1,
                totalSteps: _sagaSetupSteps.length,
                color: step.accent,
              ),
            ),
          ),
        Expanded(
          child: ShaderMask(
            shaderCallback: (bounds) {
              return LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white,
                  Colors.white,
                  _SagaColors.panelHigh.withValues(alpha: 0),
                ],
                stops: const [0, 0.88, 1],
              ).createShader(bounds);
            },
            blendMode: BlendMode.dstIn,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(
                22,
                compactVertical ? 10 : 18,
                22,
                scrollBottomPadding,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 360),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) {
                      final offset = Tween<Offset>(
                        begin: const Offset(0.08, 0),
                        end: Offset.zero,
                      ).animate(animation);

                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(position: offset, child: child),
                      );
                    },
                    child: _SagaQuizStepCard(
                      key: ValueKey(step.id),
                      step: step,
                      compact: compactVertical,
                      child: _buildStepContent(
                        step,
                        compact: compactVertical,
                        keyboardInset: keyboardInset,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        _SagaQuizBottomNav(
          showBack: stepIndex > 0,
          primaryLabel: isFinal ? 'Build my arc' : 'Keep going',
          color: step.accent,
          compact: compactVertical,
          keyboardInset: keyboardInset,
          onBack: onBack,
          onContinue: onContinue,
        ),
      ],
    );
  }

  Widget _buildStepContent(
    _SagaSetupStep step, {
    required bool compact,
    required double keyboardInset,
  }) {
    final fieldScrollPadding = EdgeInsets.only(
      top: 24,
      bottom: math.max(96, keyboardInset + 92),
    );

    return switch (step.kind) {
      _SagaSetupStepKind.singleChoice =>
        step.id == 'wake_quest'
            ? _WakeQuestMissionGrid(
                options: step.options,
                selectedId: builderAnswers[step.id] ?? step.options.first.id,
                color: step.accent,
                onSelected: (id) {
                  onRitualSelected(id);
                  onAnswerSelected(step.id, id);
                },
              )
            : _SagaOptionChoiceList(
                options: step.options,
                selectedId: builderAnswers[step.id] ?? step.options.first.id,
                color: step.accent,
                onSelected: (id) {
                  if (step.id == 'rival') {
                    onObstacleSelected(id);
                  }
                  onAnswerSelected(step.id, id);
                },
              ),
      _SagaSetupStepKind.education => _SagaEducationPanel(
        step: step,
        answers: builderAnswers,
        selectedMission: selectedMission,
        selectedVoice: selectedVoice,
        wakeTime: wakeTime,
        selectedGate: selectedRitual,
        compact: compact,
      ),
      _SagaSetupStepKind.identity => _SetupInput(
        label: 'PROTAGONIST NAME',
        child: TextField(
          key: const ValueKey('name-field'),
          controller: nameController,
          style: const TextStyle(
            color: _SagaColors.socialText,
            fontWeight: FontWeight.w800,
          ),
          textInputAction: TextInputAction.done,
          scrollPadding: fieldScrollPadding,
          decoration: const InputDecoration(
            hintText: 'Hero',
            fillColor: _SagaColors.socialCard,
            hintStyle: TextStyle(color: _SagaColors.socialMuted),
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ),
      _SagaSetupStepKind.mission => _MissionCardGrid(
        selectedMission: selectedMission,
        onMissionSelected: onMissionSelected,
      ),
      _SagaSetupStepKind.goal => _SetupInput(
        label: 'PRIMARY GOAL',
        child: TextField(
          key: const ValueKey('goal-field'),
          controller: goalController,
          style: const TextStyle(
            color: _SagaColors.socialText,
            fontWeight: FontWeight.w800,
          ),
          minLines: compact ? 1 : 2,
          maxLines: compact ? 2 : 3,
          scrollPadding: fieldScrollPadding,
          decoration: const InputDecoration(
            hintText: 'What should tomorrow prove?',
            fillColor: _SagaColors.socialCard,
            hintStyle: TextStyle(color: _SagaColors.socialMuted),
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ),
      _SagaSetupStepKind.wakeTime => _WakeTimeSetupButton(
        wakeTime: wakeTime,
        onPressed: onWakeTimePressed,
      ),
      _SagaSetupStepKind.voice => _VoiceCardGrid(
        selected: selectedVoice,
        onSelected: onVoiceSelected,
      ),
      _SagaSetupStepKind.loadingChecklist => _SagaRenderingChecklist(
        mission: selectedMission,
        voice: selectedVoice,
        wakeTime: wakeTime,
        gate: selectedRitual,
      ),
      _SagaSetupStepKind.planReveal => _SagaPlanReveal(
        mission: selectedMission,
        voice: selectedVoice,
        wakeTime: wakeTime,
        gate: selectedRitual,
        rival: selectedObstacle,
      ),
      _SagaSetupStepKind.receiptPreview => _SagaReceiptPreview(
        mission: selectedMission,
        gate: selectedRitual,
        wakeTime: wakeTime,
      ),
      _SagaSetupStepKind.paywall => _SagaPaywallPreview(
        mission: selectedMission,
      ),
      _SagaSetupStepKind.review => _SagaBlueprintReview(
        name: nameController.text.trim().isEmpty
            ? 'Hero'
            : nameController.text.trim(),
        mission: selectedMission,
        voice: selectedVoice,
        wakeTime: wakeTime,
        obstacle: _setupObstacleLabel(selectedObstacle),
        ritual: _wakeQuestLabel(selectedRitual),
        repeatDays: _optionLabelFor(
          'repeat_days',
          builderAnswers['repeat_days'],
        ),
        mode: _optionLabelFor('alarm_mode', builderAnswers['alarm_mode']),
      ),
    };
  }
}

class _SagaQuizProgress extends StatelessWidget {
  const _SagaQuizProgress({
    required this.progress,
    required this.chapter,
    required this.stepNumber,
    required this.totalSteps,
    required this.color,
  });

  final double progress;
  final String chapter;
  final int stepNumber;
  final int totalSteps;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: _SagaColors.ink.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.34)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.22),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: _PersonaWordmark(compact: true)),
              const SizedBox(width: 10),
              Flexible(
                child: _PersonaTag(label: 'training arc setup', color: color),
              ),
              const SizedBox(width: 8),
              Text(
                '$stepNumber/$totalSteps',
                style: const TextStyle(
                  color: _SagaColors.socialText,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: _SagaColors.paper.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: color.withValues(alpha: 0.24)),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: AnimatedFractionallySizedBox(
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeOutCubic,
                widthFactor: progress.clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(99),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.34),
                        blurRadius: 14,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  _socialChapterLabel(chapter),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _SagaColors.socialMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _PersonaStepDots(progress: progress, color: color, total: 6),
            ],
          ),
        ],
      ),
    );
  }
}

class _PersonaWordmark extends StatelessWidget {
  const _PersonaWordmark({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text.rich(
            TextSpan(
              children: [
                const TextSpan(text: 'Wake'),
                TextSpan(
                  text: 'Saga',
                  style: TextStyle(color: _SagaColors.purple),
                ),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: _SagaColors.personaCoral,
              fontSize: compact ? 20 : 26,
              height: 0.95,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 6),
        CustomPaint(
          size: Size.square(compact ? 18 : 24),
          painter: const _PersonaSunPainter(),
        ),
      ],
    );
  }
}

class _PersonaSunPainter extends CustomPainter {
  const _PersonaSunPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = _SagaColors.socialYellow
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.7;
    canvas.drawCircle(center, size.width * 0.24, paint);
    for (var i = 0; i < 9; i++) {
      final angle = i * math.pi * 2 / 9;
      canvas.drawLine(
        center + Offset(math.cos(angle), math.sin(angle)) * size.width * 0.34,
        center + Offset(math.cos(angle), math.sin(angle)) * size.width * 0.48,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PersonaSunPainter oldDelegate) => false;
}

class _PersonaTag extends StatelessWidget {
  const _PersonaTag({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.46)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: _SagaColors.paper,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _PersonaStepDots extends StatelessWidget {
  const _PersonaStepDots({
    required this.progress,
    required this.color,
    required this.total,
  });

  final double progress;
  final Color color;
  final int total;

  @override
  Widget build(BuildContext context) {
    final active = (progress * total).ceil().clamp(1, total);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var index = 0; index < total; index++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            width: index < active ? 13 : 8,
            height: 8,
            margin: const EdgeInsets.only(left: 4),
            decoration: BoxDecoration(
              color: index < active
                  ? color
                  : _SagaColors.socialText.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
      ],
    );
  }
}

class _SagaQuizStepCard extends StatelessWidget {
  const _SagaQuizStepCard({
    super.key,
    required this.step,
    required this.child,
    required this.compact,
  });

  final _SagaSetupStep step;
  final Widget child;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 12 : 18),
      decoration: BoxDecoration(
        color: _SagaColors.panel.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: step.accent.withValues(alpha: 0.32)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            step.accent.withValues(alpha: 0.26),
            _SagaColors.panel.withValues(alpha: 0.96),
            _SagaColors.ink.withValues(alpha: 0.98),
          ],
          stops: const [0, 0.52, 1],
        ),
        boxShadow: [
          BoxShadow(
            color: step.accent.withValues(alpha: 0.22),
            blurRadius: 34,
            spreadRadius: 1,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -28,
            top: -20,
            child: Transform.rotate(
              angle: -0.16,
              child: _AnimeSticker(
                label: 'EP ${_episodeNumberForStep(step.id)}',
                color: step.accent,
              ),
            ),
          ),
          Positioned(
            right: 12,
            bottom: 8,
            child: Icon(
              _iconForSetupStep(step),
              color: _SagaColors.paper.withValues(alpha: 0.055),
              size: compact ? 92 : 128,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PersonaSetupHeader(
                color: step.accent,
                chapter: _personaChapterForStep(step),
                compact: compact,
              ),
              SizedBox(height: compact ? 12 : 16),
              if (!compact) ...[
                _SagaGuideBubble(
                  color: step.accent,
                  message: _guideLineForStep(step),
                  compact: compact,
                ),
                const SizedBox(height: 10),
                _SocialFriendChips(color: step.accent),
                const SizedBox(height: 16),
              ],
              Text(
                _personaQuestionForStep(step),
                style: TextStyle(
                  color: _SagaColors.socialText,
                  fontSize: compact ? 25 : 34,
                  fontWeight: FontWeight.w900,
                  height: 1.02,
                  letterSpacing: 0,
                  shadows: [
                    Shadow(
                      color: step.accent.withValues(alpha: 0.28),
                      offset: const Offset(0, 1),
                      blurRadius: 0,
                    ),
                  ],
                ),
              ),
              SizedBox(height: compact ? 8 : 14),
              Text(
                step.subtitle,
                style: TextStyle(
                  color: _SagaColors.socialMuted,
                  fontSize: compact ? 12.5 : 15,
                  height: 1.32,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: compact ? 10 : 22),
              child,
            ],
          ),
        ],
      ),
    );
  }
}

class _PersonaSetupHeader extends StatelessWidget {
  const _PersonaSetupHeader({
    required this.color,
    required this.chapter,
    required this.compact,
  });

  final Color color;
  final String chapter;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _PersonaAvatarMedallion(color: color, size: compact ? 72 : 96),
        SizedBox(width: compact ? 12 : 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PersonaTag(label: chapter, color: color),
              SizedBox(height: compact ? 8 : 10),
              const _PersonaEnergyField(),
              if (!compact) ...[
                const SizedBox(height: 10),
                const _PersonaChipRail(),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _PersonaAvatarMedallion extends StatelessWidget {
  const _PersonaAvatarMedallion({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _SagaColors.personaAqua.withValues(alpha: 0.88),
        border: Border.all(color: _SagaColors.paper, width: 2.2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.24),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(child: _WakeGateMedallionArt(color: color)),
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              width: size * 0.28,
              height: size * 0.28,
              decoration: BoxDecoration(
                color: _SagaColors.personaPaper,
                shape: BoxShape.circle,
                border: Border.all(color: _SagaColors.paper, width: 1.4),
              ),
              child: Icon(
                Icons.lock_open_outlined,
                size: size * 0.15,
                color: _SagaColors.socialText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WakeGateMedallionArt extends StatelessWidget {
  const _WakeGateMedallionArt({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned.fill(child: CustomPaint(painter: _WakeGateRingPainter())),
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: _SagaColors.ink.withValues(alpha: 0.86),
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha: 0.64)),
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.34), blurRadius: 18),
            ],
          ),
          child: Icon(Icons.bolt, color: color, size: 26),
        ),
      ],
    );
  }
}

class _WakeGateRingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = _SagaColors.ink.withValues(alpha: 0.64);
    final rayPaint = Paint()
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..color = _SagaColors.paper.withValues(alpha: 0.42);

    canvas.drawCircle(center, size.width * 0.27, ringPaint);
    canvas.drawCircle(center, size.width * 0.38, ringPaint);
    for (var i = 0; i < 10; i++) {
      final angle = i * math.pi * 2 / 10;
      canvas.drawLine(
        center + Offset(math.cos(angle), math.sin(angle)) * size.width * 0.18,
        center + Offset(math.cos(angle), math.sin(angle)) * size.width * 0.43,
        rayPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PersonaEnergyField extends StatelessWidget {
  const _PersonaEnergyField();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: _SagaColors.ink.withValues(alpha: 0.56),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _SagaColors.paper.withValues(alpha: 0.12)),
      ),
      child: const Text(
        'episode 001 energy',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: _SagaColors.socialText,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _PersonaChipRail extends StatelessWidget {
  const _PersonaChipRail();

  @override
  Widget build(BuildContext context) {
    const chips = [
      ('rival scan', _SagaColors.purple),
      ('wake gate', _SagaColors.cyan),
      ('episode unlock', _SagaColors.signal),
      ('receipt', _SagaColors.gold),
    ];

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final chip in chips) _PersonaTag(label: chip.$1, color: chip.$2),
      ],
    );
  }
}

class _SagaGuideBubble extends StatelessWidget {
  const _SagaGuideBubble({
    required this.color,
    required this.message,
    required this.compact,
  });

  final Color color;
  final String message;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: compact ? 42 : 48,
          height: compact ? 42 : 48,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _SagaColors.paper.withValues(alpha: 0.12),
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.22),
                blurRadius: 18,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Icon(
            Icons.auto_awesome,
            color: color.computeLuminance() > 0.5
                ? _SagaColors.ink
                : _SagaColors.paper,
            size: compact ? 22 : 25,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: EdgeInsets.fromLTRB(
              12,
              compact ? 9 : 10,
              12,
              compact ? 9 : 10,
            ),
            decoration: BoxDecoration(
              color: _SagaColors.panelHigh.withValues(alpha: 0.76),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withValues(alpha: 0.22)),
            ),
            child: Text(
              message,
              style: TextStyle(
                color: _SagaColors.socialText,
                fontSize: compact ? 11.5 : 12.5,
                height: 1.25,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SocialFriendChips extends StatelessWidget {
  const _SocialFriendChips({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    const friends = [
      ('Rival', 'move first', _SagaColors.socialPink),
      ('Guide', 'gate clears', _SagaColors.socialBlue),
      ('Arc', 'episode unlocks', _SagaColors.socialGreen),
    ];

    return Row(
      children: [
        const Text(
          'narrator cue',
          style: TextStyle(
            color: _SagaColors.socialMuted,
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final friend in friends) ...[
                  _FriendSayChip(
                    initial: friend.$1.substring(0, 1),
                    label: friend.$2,
                    color: friend.$3,
                  ),
                  const SizedBox(width: 7),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _FriendSayChip extends StatelessWidget {
  const _FriendSayChip({
    required this.initial,
    required this.label,
    required this.color,
  });

  final String initial;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 4, 9, 4),
      decoration: BoxDecoration(
        color: _SagaColors.panelHigh.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _SagaColors.socialText.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(7),
            ),
            child: Text(
              initial,
              style: const TextStyle(
                color: _SagaColors.socialText,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: _SagaColors.socialText,
              fontSize: 10.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimeSticker extends StatelessWidget {
  const _AnimeSticker({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 7, 12, 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: _SagaColors.paper.withValues(alpha: 0.38)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: _SagaColors.ink,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _SagaBriefingPoster extends StatelessWidget {
  const _SagaBriefingPoster({
    required this.color,
    required this.compact,
    required this.kicker,
    required this.title,
    required this.caption,
    required this.icon,
  });

  final Color color;
  final bool compact;
  final String kicker;
  final String title;
  final String caption;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: compact ? 172 : 214,
      padding: EdgeInsets.all(compact ? 16 : 20),
      decoration: BoxDecoration(
        color: _SagaColors.socialYellow.withValues(alpha: 0.34),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _SagaColors.socialText.withValues(alpha: 0.08),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            top: compact ? 18 : 16,
            child: Icon(
              icon,
              color: _SagaColors.socialText.withValues(alpha: 0.08),
              size: compact ? 118 : 148,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                kicker,
                style: TextStyle(
                  color: _SagaColors.socialMuted,
                  fontSize: compact ? 10 : 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
              const Spacer(),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _SagaColors.socialText,
                  fontSize: compact ? 48 : 60,
                  height: 0.9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
              SizedBox(height: compact ? 10 : 12),
              Text(
                caption,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _SagaColors.socialMuted,
                  fontSize: compact ? 13 : 15,
                  height: 1.28,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SagaQuizBottomNav extends StatelessWidget {
  const _SagaQuizBottomNav({
    required this.showBack,
    required this.primaryLabel,
    required this.color,
    required this.compact,
    required this.keyboardInset,
    required this.onBack,
    required this.onContinue,
  });

  final bool showBack;
  final String primaryLabel;
  final Color color;
  final bool compact;
  final double keyboardInset;
  final VoidCallback onBack;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.of(context).padding.bottom;
    final bottomPadding = keyboardInset > 0 ? keyboardInset + 8 : safeBottom;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _SagaColors.ink.withValues(alpha: 0),
            _SagaColors.ink.withValues(alpha: 0.78),
            _SagaColors.ink.withValues(alpha: 0.98),
          ],
          stops: const [0, 0.38, 1],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            22,
            compact ? 10 : 20,
            22,
            bottomPadding + (compact ? 8 : 20),
          ),
          child: Row(
            children: [
              if (showBack) ...[
                SizedBox(
                  width: 92,
                  child: OutlinedButton(
                    onPressed: onBack,
                    style: OutlinedButton.styleFrom(
                      minimumSize: Size(48, compact ? 54 : 58),
                      side: BorderSide(
                        color: _SagaColors.paper.withValues(alpha: 0.18),
                      ),
                      foregroundColor: _SagaColors.paper,
                      backgroundColor: _SagaColors.panel.withValues(
                        alpha: 0.82,
                      ),
                    ),
                    child: const Icon(Icons.arrow_back),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: _ReferencePrimaryButton(
                  label: primaryLabel,
                  color: color,
                  onPressed: onContinue,
                  compact: compact,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WakeQuestMissionGrid extends StatelessWidget {
  const _WakeQuestMissionGrid({
    required this.options,
    required this.selectedId,
    required this.color,
    required this.onSelected,
  });

  final List<_SagaChoiceOption> options;
  final String selectedId;
  final Color color;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final twoColumns = constraints.maxWidth >= 340;
        final gap = twoColumns ? 10.0 : 0.0;
        final tileWidth = twoColumns
            ? (constraints.maxWidth - gap) / 2
            : constraints.maxWidth;

        return Wrap(
          spacing: gap,
          runSpacing: 10,
          children: [
            for (var index = 0; index < options.length; index++)
              SizedBox(
                width: tileWidth,
                child: _WakeQuestMissionTile(
                  option: options[index],
                  index: index,
                  selected: selectedId == options[index].id,
                  color: _viralChoiceAccent(index, color),
                  onTap: () => onSelected(options[index].id),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _WakeQuestMissionTile extends StatelessWidget {
  const _WakeQuestMissionTile({
    required this.option,
    required this.index,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final _SagaChoiceOption option;
  final int index;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          constraints: const BoxConstraints(minHeight: 142),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected
                ? _SagaColors.panelHigh.withValues(alpha: 0.97)
                : _SagaColors.panelHigh.withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected
                  ? color
                  : _SagaColors.socialText.withValues(alpha: 0.08),
              width: selected ? 2 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.2),
                      blurRadius: 22,
                      offset: const Offset(0, 10),
                    ),
                  ]
                : null,
          ),
          child: Stack(
            children: [
              Positioned(
                right: -8,
                bottom: -10,
                child: Icon(
                  option.icon,
                  color: _SagaColors.socialText.withValues(alpha: 0.045),
                  size: 74,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: selected ? 0.86 : 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          option.icon,
                          color: _SagaColors.socialText,
                          size: 22,
                        ),
                      ),
                      const Spacer(),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: selected ? color : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: selected
                                ? color
                                : _SagaColors.socialText.withValues(
                                    alpha: 0.18,
                                  ),
                          ),
                        ),
                        child: selected
                            ? const Icon(
                                Icons.check,
                                color: _SagaColors.ink,
                                size: 16,
                              )
                            : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    option.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _SagaColors.socialText,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    option.description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _SagaColors.socialMuted,
                      fontSize: 11.5,
                      height: 1.24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _MiniSticker(
                    label: 'WAKE MISSION',
                    color: color.withValues(alpha: 0.74),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SagaOptionChoiceList extends StatelessWidget {
  const _SagaOptionChoiceList({
    required this.options,
    required this.selectedId,
    required this.color,
    required this.onSelected,
  });

  final List<_SagaChoiceOption> options;
  final String selectedId;
  final Color color;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < options.length; index++)
          _SagaChoiceTile(
            id: options[index].id,
            index: index,
            selected: selectedId == options[index].id,
            color: color,
            label: options[index].label,
            description: options[index].description,
            icon: options[index].icon,
            onTap: () => onSelected(options[index].id),
          ),
      ],
    );
  }
}

class _SagaEducationPanel extends StatelessWidget {
  const _SagaEducationPanel({
    required this.step,
    required this.answers,
    required this.selectedMission,
    required this.selectedVoice,
    required this.wakeTime,
    required this.selectedGate,
    required this.compact,
  });

  final _SagaSetupStep step;
  final Map<String, String> answers;
  final MissionType selectedMission;
  final VoiceArchetype selectedVoice;
  final String wakeTime;
  final String selectedGate;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final rows = _rowsForStep();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 14 : 18),
      decoration: BoxDecoration(
        color: _SagaColors.panelHigh.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _SagaColors.socialText.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SagaArtifactHeader(
            icon: _iconForStep(),
            label: _artifactLabel(),
            color: step.accent,
          ),
          const SizedBox(height: 16),
          if (step.id == 'title_card')
            _SagaTitleCard(color: step.accent, compact: compact)
          else
            for (final row in rows)
              _SagaArtifactLine(
                icon: row.icon,
                title: row.title,
                body: row.body,
                color: step.accent,
              ),
        ],
      ),
    );
  }

  IconData _iconForStep() {
    return switch (step.id) {
      'snooze_loop' => Icons.snooze_outlined,
      'rival_detected' => Icons.warning_amber_outlined,
      'old_loop' => Icons.compare_arrows,
      'sleep_inertia' => Icons.bedtime_outlined,
      'body_before_brain' => Icons.directions_run_outlined,
      'time_gain' => Icons.more_time_outlined,
      'episode_formula' => Icons.functions,
      'quest_explain' => Icons.emoji_events_outlined,
      'jolt_preview' => Icons.graphic_eq,
      'permission_primer' => Icons.notifications_active_outlined,
      'timeline' => Icons.timeline,
      _ => Icons.auto_awesome_outlined,
    };
  }

  String _artifactLabel() {
    return switch (step.id) {
      'rival_detected' => 'PLAN UPDATE',
      'jolt_preview' => 'AUDIO PREVIEW',
      'timeline' => 'OPENING SEQUENCE',
      'permission_primer' => 'SYSTEM ACCESS',
      'time_gain' => 'MONTHLY RECEIPT',
      _ => 'BUILDER INSIGHT',
    };
  }

  List<({IconData icon, String title, String body})> _rowsForStep() {
    final gate = _wakeQuestLabel(selectedGate);
    final rival = _optionLabelFor('rival', answers['rival']);
    final shift = _optionLabelFor('target_shift', answers['target_shift']);
    final jolt = _optionLabelFor('jolt_style', answers['jolt_style']);

    return switch (step.id) {
      'snooze_loop' => [
        (
          icon: Icons.alarm_outlined,
          title: 'Alarm fires',
          body: 'The room gets a signal, but the body has not moved yet.',
        ),
        (
          icon: Icons.snooze_outlined,
          title: 'Negotiation starts',
          body: 'A normal alarm gives the tired brain too much authority.',
        ),
        (
          icon: Icons.phone_iphone_outlined,
          title: 'The feed wins',
          body: 'WakeSaga interrupts this with a required Wake Quest.',
        ),
      ],
      'rival_detected' => [
        (
          icon: Icons.warning_amber_outlined,
          title: rival,
          body: 'This is the obstacle tomorrow has to beat first.',
        ),
        (
          icon: Icons.emoji_events_outlined,
          title: 'You need a Wake Quest',
          body:
              'A real-world mission proves you are up before the episode starts.',
        ),
      ],
      'old_loop' => [
        (
          icon: Icons.close,
          title: 'Old loop',
          body: 'Alarm -> snooze -> scroll -> panic.',
        ),
        (
          icon: Icons.check,
          title: 'Saga loop',
          body: 'Alarm -> Wake Quest -> episode -> first action -> receipt.',
        ),
      ],
      'sleep_inertia' => [
        (
          icon: Icons.bedtime_outlined,
          title: 'The first minutes are foggy',
          body: 'The system should not depend on perfect motivation at wake.',
        ),
        (
          icon: Icons.directions_run_outlined,
          title: 'Motion changes state',
          body:
              'The Wake Quest gives the body a command before the brain debates.',
        ),
      ],
      'body_before_brain' => [
        (
          icon: Icons.lock_outline,
          title: 'Quest before episode',
          body:
              'The Morning Episode becomes the reward for proving you are up.',
        ),
        (
          icon: Icons.movie_creation_outlined,
          title: 'Then the story starts',
          body:
              'You hear the episode after you have already won the first move.',
        ),
      ],
      'time_gain' => [
        (
          icon: Icons.more_time_outlined,
          title: shift,
          body: 'Even small reclaimed mornings compound into a visible month.',
        ),
        (
          icon: Icons.receipt_long_outlined,
          title: 'Wake receipt',
          body: 'WakeSaga shows what the morning recovered.',
        ),
      ],
      'episode_formula' => [
        (
          icon: selectedMission.icon,
          title: selectedMission.label,
          body: 'The mission sets the scene and what the first action means.',
        ),
        (
          icon: Icons.warning_amber_outlined,
          title: rival,
          body: 'The rival gives the episode its conflict.',
        ),
        (
          icon: selectedVoice.icon,
          title: selectedVoice.label,
          body: 'The narrator determines the pressure.',
        ),
      ],
      'quest_explain' => [
        (
          icon: Icons.lock_open_outlined,
          title: gate,
          body: 'This Wake Quest is the proof that unlocks Episode 001.',
        ),
        (
          icon: Icons.psychology_alt_outlined,
          title: 'Why it works',
          body:
              'It forces one small physical reality before the tired mind can bargain.',
        ),
      ],
      'jolt_preview' => [
        (
          icon: Icons.graphic_eq,
          title: jolt,
          body: _previewJoltLine(selectedVoice, selectedMission, gate),
        ),
        (
          icon: Icons.cached_outlined,
          title: 'Generated before sleep',
          body: 'The wake clip is ready before the alarm window.',
        ),
      ],
      'permission_primer' => [
        (
          icon: Icons.notifications_active_outlined,
          title: 'Alarm access',
          body: 'Needed so the jolt can fire even when the phone is locked.',
        ),
        (
          icon: Icons.lock_clock_outlined,
          title: 'Quest timing',
          body: 'WakeSaga needs to know when to move from alarm to proof.',
        ),
      ],
      'timeline' => [
        (
          icon: Icons.alarm_on_outlined,
          title: wakeTime,
          body: 'Wake jolt starts.',
        ),
        (
          icon: Icons.task_alt,
          title: gate,
          body: 'Complete the Wake Quest to unlock the Morning Episode.',
        ),
        (
          icon: Icons.play_circle_outline,
          title: 'Episode 001',
          body: '${selectedMission.label} opens with ${selectedVoice.label}.',
        ),
        (
          icon: Icons.style_outlined,
          title: 'Wake receipt',
          body: 'The first morning gets saved as a collectible card.',
        ),
      ],
      _ => [
        (
          icon: Icons.auto_awesome_outlined,
          title: 'Builder update',
          body: 'WakeSaga is turning answers into tomorrow\'s opening scene.',
        ),
      ],
    };
  }
}

class _SagaArtifactHeader extends StatelessWidget {
  const _SagaArtifactHeader({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: _SagaColors.socialText, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: _SagaColors.socialMuted,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ),
      ],
    );
  }
}

class _SagaArtifactLine extends StatelessWidget {
  const _SagaArtifactLine({
    required this.icon,
    required this.title,
    required this.body,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String body;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: _SagaColors.socialCream.withValues(alpha: 0.48),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _SagaColors.socialText.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _SagaColors.socialText, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: const TextStyle(
                    color: _SagaColors.socialText,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: const TextStyle(
                    color: _SagaColors.socialMuted,
                    fontSize: 12.5,
                    height: 1.28,
                    fontWeight: FontWeight.w700,
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

class _SagaTitleCard extends StatelessWidget {
  const _SagaTitleCard({required this.color, required this.compact});

  final Color color;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        16,
        compact ? 22 : 28,
        16,
        compact ? 22 : 28,
      ),
      decoration: BoxDecoration(
        color: _SagaColors.socialYellow.withValues(alpha: 0.46),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _SagaColors.socialText.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        children: [
          Text(
            'EPISODE 001',
            style: TextStyle(
              color: _SagaColors.socialMuted,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'THE OPENING\nSCENE IS BUILT',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _SagaColors.socialText,
              fontSize: compact ? 26 : 34,
              height: 0.94,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _SagaRenderingChecklist extends StatelessWidget {
  const _SagaRenderingChecklist({
    required this.mission,
    required this.voice,
    required this.wakeTime,
    required this.gate,
  });

  final MissionType mission;
  final VoiceArchetype voice;
  final String wakeTime;
  final String gate;

  @override
  Widget build(BuildContext context) {
    final rows = [
      ('Rival calibrated', Icons.warning_amber_outlined),
      ('Wake jolt drafted', Icons.graphic_eq),
      ('${_wakeQuestLabel(gate)} staged', Icons.emoji_events_outlined),
      ('${voice.label} narrator synced', voice.icon),
      ('${mission.label} episode rendered', mission.icon),
      ('Wake receipt minted', Icons.style_outlined),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SagaBriefingPoster(
          color: _SagaColors.purple,
          compact: false,
          kicker: 'ALARM WINDOW',
          title: wakeTime,
          caption: 'Rendering toward tomorrow morning.',
          icon: Icons.movie_creation_outlined,
        ),
        const SizedBox(height: 14),
        for (final row in rows)
          _SagaArtifactLine(
            icon: row.$2,
            title: row.$1,
            body: 'Ready for Episode 001.',
            color: _SagaColors.purple,
          ),
      ],
    );
  }
}

class _SagaPlanReveal extends StatelessWidget {
  const _SagaPlanReveal({
    required this.mission,
    required this.voice,
    required this.wakeTime,
    required this.gate,
    required this.rival,
  });

  final MissionType mission;
  final VoiceArchetype voice;
  final String wakeTime;
  final String gate;
  final String rival;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SagaBlueprintRow(
          label: 'Alarm',
          value: '$wakeTime wake jolt',
          icon: Icons.alarm_on_outlined,
        ),
        const SizedBox(height: 10),
        _SagaBlueprintRow(
          label: 'Wake Quest',
          value: _wakeQuestLabel(gate),
          icon: Icons.emoji_events_outlined,
        ),
        const SizedBox(height: 10),
        _SagaBlueprintRow(
          label: 'Episode',
          value: '${mission.label} with ${voice.label}',
          icon: mission.icon,
        ),
        const SizedBox(height: 10),
        _SagaBlueprintRow(
          label: 'Rival',
          value: _setupObstacleLabel(rival),
          icon: Icons.warning_amber_outlined,
        ),
        const SizedBox(height: 14),
        _ScriptBlock(
          text:
              'At $wakeTime, WakeSaga fires the jolt. Clear the ${_wakeQuestLabel(gate).toLowerCase()} Wake Quest to unlock Episode 001. Then the ${mission.label.toLowerCase()} arc starts before the old morning can take over.',
        ),
      ],
    );
  }
}

class _SagaReceiptPreview extends StatelessWidget {
  const _SagaReceiptPreview({
    required this.mission,
    required this.gate,
    required this.wakeTime,
  });

  final MissionType mission;
  final String gate;
  final String wakeTime;

  @override
  Widget build(BuildContext context) {
    final color = _missionAccent(mission);
    final gateLabel = _wakeQuestLabel(gate);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _SagaColors.socialCard.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.58), width: 1.4),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.28),
            _SagaColors.panelHigh.withValues(alpha: 0.95),
            _SagaColors.socialBlue.withValues(alpha: 0.22),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.22),
            blurRadius: 34,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -34,
            top: -36,
            child: Icon(
              Icons.wb_sunny_outlined,
              color: _SagaColors.socialText.withValues(alpha: 0.06),
              size: 164,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _MiniSticker(label: 'WAKE RECEIPT', color: color),
                  _MiniSticker(
                    label: 'shareable',
                    color: _SagaColors.socialPink,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Tomorrow needs an opening scene',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: _SagaColors.socialText,
                  fontWeight: FontWeight.w900,
                  height: 1.02,
                ),
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _SagaColors.panelHigh.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _SagaColors.socialText.withValues(alpha: 0.1),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.14),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _ReceiptField(
                      icon: Icons.alarm_on_outlined,
                      label: 'wake time',
                      value: wakeTime,
                      color: _SagaColors.socialPink,
                    ),
                    _ReceiptField(
                      icon: Icons.cloud_outlined,
                      label: 'first enemy',
                      value: 'Snooze loop',
                      color: _SagaColors.socialBlue,
                    ),
                    _ReceiptField(
                      icon: Icons.emoji_events_outlined,
                      label: 'first win',
                      value: gateLabel,
                      color: _SagaColors.socialGreen,
                    ),
                    _ReceiptField(
                      icon: mission.icon,
                      label: 'arc mood',
                      value: '${mission.label} arc',
                      color: _SagaColors.socialYellow,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const _PersonaChipRail(),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReceiptField extends StatelessWidget {
  const _ReceiptField({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 17, color: _SagaColors.socialText),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 82,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _SagaColors.socialMuted,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _SagaColors.socialText,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SagaPaywallPreview extends StatelessWidget {
  const _SagaPaywallPreview({required this.mission});

  final MissionType mission;

  @override
  Widget build(BuildContext context) {
    final benefits = [
      ('AI wake jolts', Icons.graphic_eq),
      ('Custom narrators', Icons.record_voice_over_outlined),
      ('Unlimited Wake Quests', Icons.emoji_events_outlined),
      ('Episode cards', Icons.style_outlined),
      ('Morning insights', Icons.insights_outlined),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: _SagaColors.socialYellow.withValues(alpha: 0.44),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _SagaColors.socialText.withValues(alpha: 0.08),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'WAKE SAGA PRO',
                style: TextStyle(
                  color: _SagaColors.socialMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Unlock the full ${mission.label} opening system',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: _SagaColors.socialText,
                  fontWeight: FontWeight.w900,
                  height: 1.05,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        for (final benefit in benefits)
          _SagaArtifactLine(
            icon: benefit.$2,
            title: benefit.$1,
            body: 'Part of the full daily saga system.',
            color: _SagaColors.gold,
          ),
      ],
    );
  }
}

class _SagaChoiceTile extends StatelessWidget {
  const _SagaChoiceTile({
    required this.id,
    required this.index,
    required this.selected,
    required this.color,
    required this.label,
    required this.description,
    required this.icon,
    required this.onTap,
  });

  final String id;
  final int index;
  final bool selected;
  final Color color;
  final String label;
  final String description;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = _viralChoiceAccent(index, color);
    final optionNumber = (index + 1).toString().padLeft(2, '0');

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutBack,
            padding: EdgeInsets.zero,
            decoration: BoxDecoration(
              color: selected
                  ? _SagaColors.panelHigh.withValues(alpha: 0.96)
                  : _SagaColors.panelHigh.withValues(alpha: 0.78),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: selected
                    ? accent
                    : _SagaColors.socialText.withValues(alpha: 0.08),
                width: selected ? 2 : 1,
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  accent.withValues(alpha: selected ? 0.28 : 0.08),
                  _SagaColors.panelHigh.withValues(alpha: 0.92),
                  _SagaColors.socialCream.withValues(
                    alpha: selected ? 0.62 : 0.28,
                  ),
                ],
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.22),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ]
                  : null,
            ),
            child: Stack(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 58,
                      height: 92,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: selected ? 0.9 : 0.66),
                        borderRadius: const BorderRadius.horizontal(
                          left: Radius.circular(8),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(icon, color: _SagaColors.socialText, size: 24),
                          const SizedBox(height: 7),
                          Text(
                            optionNumber,
                            style: const TextStyle(
                              color: _SagaColors.socialText,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    label,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: _SagaColors.socialText,
                                      fontSize: 20,
                                      height: 0.98,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 220),
                                  width: 25,
                                  height: 25,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    color: selected
                                        ? accent
                                        : Colors.transparent,
                                    border: Border.all(
                                      color: selected
                                          ? accent
                                          : _SagaColors.socialText.withValues(
                                              alpha: 0.2,
                                            ),
                                    ),
                                  ),
                                  child: selected
                                      ? const Icon(
                                          Icons.check,
                                          size: 16,
                                          color: _SagaColors.ink,
                                        )
                                      : null,
                                ),
                              ],
                            ),
                            const SizedBox(height: 7),
                            Text(
                              description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _SagaColors.socialMuted,
                                fontSize: 12.5,
                                height: 1.24,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                Positioned(
                  right: -16,
                  bottom: -22,
                  child: Icon(
                    icon,
                    color: _SagaColors.socialText.withValues(
                      alpha: selected ? 0.055 : 0.035,
                    ),
                    size: 92,
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

class _MiniSticker extends StatelessWidget {
  const _MiniSticker({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: _SagaColors.ink,
          fontSize: 9,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _SagaBlueprintReview extends StatelessWidget {
  const _SagaBlueprintReview({
    required this.name,
    required this.mission,
    required this.voice,
    required this.wakeTime,
    required this.obstacle,
    required this.ritual,
    required this.repeatDays,
    required this.mode,
  });

  final String name;
  final MissionType mission;
  final VoiceArchetype voice;
  final String wakeTime;
  final String obstacle;
  final String ritual;
  final String repeatDays;
  final String mode;

  @override
  Widget build(BuildContext context) {
    final rows = [
      (label: 'Hero', value: name, icon: Icons.person),
      (label: 'Mission', value: mission.label, icon: mission.icon),
      (label: 'Wake jolt', value: wakeTime, icon: Icons.alarm_on_outlined),
      (label: 'Voice', value: voice.label, icon: voice.icon),
      (label: 'Obstacle', value: obstacle, icon: Icons.warning_amber_outlined),
      (label: 'Wake Quest', value: ritual, icon: Icons.emoji_events_outlined),
      (label: 'Repeat', value: repeatDays, icon: Icons.calendar_month_outlined),
      (label: 'Mode', value: mode, icon: Icons.notifications_active_outlined),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final useColumns = constraints.maxWidth >= 280;
        final tileWidth = useColumns
            ? (constraints.maxWidth - 10) / 2
            : constraints.maxWidth;

        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final row in rows)
              SizedBox(
                width: tileWidth,
                child: _SagaBlueprintRow(
                  label: row.label,
                  value: row.value,
                  icon: row.icon,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _SagaBlueprintRow extends StatelessWidget {
  const _SagaBlueprintRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _SagaColors.panelHigh.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _SagaColors.socialText.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: _SagaColors.socialPink, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                    color: _SagaColors.socialMuted,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _SagaColors.socialText,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
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

class _PersonaBuilderBackdrop extends StatelessWidget {
  const _PersonaBuilderBackdrop();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(color: _SagaColors.ink),
      child: CustomPaint(painter: _PersonaBuilderBackdropPainter()),
    );
  }
}

class _PersonaBuilderBackdropPainter extends CustomPainter {
  const _PersonaBuilderBackdropPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF060710),
            Color(0xFF14111F),
            Color(0xFF26162B),
            Color(0xFF070810),
          ],
          stops: [0, 0.43, 0.72, 1],
        ).createShader(rect),
    );

    final dotPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = _SagaColors.paper.withValues(alpha: 0.045);
    for (var row = 0; row < 14; row++) {
      for (var col = 0; col < 7; col++) {
        final x = size.width * 0.05 + col * size.width * 0.16;
        final y = size.height * 0.05 + row * 40.0;
        canvas.drawCircle(Offset(x, y), 1.1 + (row % 3) * 0.3, dotPaint);
      }
    }

    final slashPaint = Paint()
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..color = _SagaColors.purple.withValues(alpha: 0.18);
    for (var i = 0; i < 9; i++) {
      final x = size.width * (0.12 + i * 0.12);
      canvas.drawLine(
        Offset(x, size.height * 0.02),
        Offset(x - size.width * 0.22, size.height * 0.42),
        slashPaint,
      );
    }

    _paintCornerSwash(
      canvas,
      Offset(size.width * -0.04, size.height * 0.12),
      _SagaColors.personaAqua,
      1,
    );
    _paintCornerSwash(
      canvas,
      Offset(size.width * 0.84, size.height * 0.03),
      _SagaColors.personaLavender,
      -1,
    );
    _paintCornerSwash(
      canvas,
      Offset(size.width * -0.02, size.height * 0.86),
      _SagaColors.socialYellow,
      1,
    );

    final sunCenter = Offset(size.width * 0.86, size.height * 0.18);
    canvas.drawCircle(
      sunCenter,
      22,
      Paint()..color = _SagaColors.socialYellow.withValues(alpha: 0.42),
    );
    for (var i = 0; i < 10; i++) {
      final angle = i * math.pi * 2 / 10;
      canvas.drawLine(
        sunCenter + Offset(math.cos(angle), math.sin(angle)) * 30,
        sunCenter + Offset(math.cos(angle), math.sin(angle)) * 42,
        slashPaint..color = _SagaColors.socialYellow.withValues(alpha: 0.48),
      );
    }
  }

  void _paintCornerSwash(
    Canvas canvas,
    Offset origin,
    Color color,
    double dir,
  ) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = color.withValues(alpha: 0.58);
    final path = Path()
      ..moveTo(origin.dx, origin.dy)
      ..lineTo(origin.dx + 110 * dir, origin.dy + 18)
      ..lineTo(origin.dx + 70 * dir, origin.dy + 72)
      ..lineTo(origin.dx + 132 * dir, origin.dy + 96)
      ..lineTo(origin.dx + 22 * dir, origin.dy + 124)
      ..lineTo(origin.dx - 20 * dir, origin.dy + 48)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SetupInput extends StatelessWidget {
  const _SetupInput({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [_SetupLabel(label), const SizedBox(height: 8), child],
    );
  }
}

class _SetupLabel extends StatelessWidget {
  const _SetupLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: _SagaColors.socialMuted,
        fontSize: 11,
        fontWeight: FontWeight.w900,
        letterSpacing: 0,
      ),
    );
  }
}

class _VoiceCardGrid extends StatelessWidget {
  const _VoiceCardGrid({required this.selected, required this.onSelected});

  final VoiceArchetype selected;
  final ValueChanged<VoiceArchetype> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final voice in VoiceArchetype.values)
          _VoiceReferenceCard(
            voice: voice,
            selected: selected == voice,
            onTap: () => onSelected(voice),
          ),
      ],
    );
  }
}

class _VoiceReferenceCard extends StatelessWidget {
  const _VoiceReferenceCard({
    required this.voice,
    required this.selected,
    required this.onTap,
  });

  final VoiceArchetype voice;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = _voiceAccent(voice);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutBack,
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected
                ? _SagaColors.panelHigh.withValues(alpha: 0.96)
                : _SagaColors.panelHigh.withValues(alpha: 0.78),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected
                  ? color
                  : _SagaColors.socialText.withValues(alpha: 0.08),
              width: selected ? 1.8 : 1,
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withValues(alpha: selected ? 0.28 : 0.09),
                _SagaColors.panelHigh.withValues(alpha: 0.94),
                _SagaColors.socialLilac.withValues(
                  alpha: selected ? 0.42 : 0.18,
                ),
              ],
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: selected ? 0.24 : 0.13),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color.withValues(alpha: 0.48)),
                ),
                child: Icon(
                  voice.icon,
                  color: _SagaColors.socialText,
                  size: 26,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _MiniSticker(label: 'GUIDE', color: color),
                    const SizedBox(height: 6),
                    Text(
                      voice.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _SagaColors.socialText,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _voiceMicrocopy(voice),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _SagaColors.socialMuted,
                        fontSize: 12,
                        height: 1.12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: selected ? color : Colors.transparent,
                  border: Border.all(
                    color: selected
                        ? color
                        : _SagaColors.socialText.withValues(alpha: 0.2),
                  ),
                ),
                child: selected
                    ? const Icon(
                        Icons.check,
                        size: 14,
                        color: _SagaColors.socialText,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WakeTimeSetupButton extends StatelessWidget {
  const _WakeTimeSetupButton({required this.wakeTime, required this.onPressed});

  final String wakeTime;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 50),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        side: BorderSide(color: _SagaColors.socialText.withValues(alpha: 0.1)),
        backgroundColor: _SagaColors.panelHigh.withValues(alpha: 0.84),
      ),
      child: Row(
        children: [
          Text(
            wakeTime,
            style: const TextStyle(
              color: _SagaColors.socialText,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Spacer(),
          Icon(Icons.alarm_on_outlined, color: _SagaColors.socialMuted),
        ],
      ),
    );
  }
}

class _OnboardingPoster extends StatefulWidget {
  const _OnboardingPoster({
    required this.wakeTime,
    required this.voice,
    required this.mission,
  });

  final String wakeTime;
  final VoiceArchetype voice;
  final MissionType mission;

  @override
  State<_OnboardingPoster> createState() => _OnboardingPosterState();
}

class _OnboardingPosterState extends State<_OnboardingPoster>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 560),
      decoration: BoxDecoration(
        color: _SagaColors.panel.withValues(alpha: 0.48),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _SagaColors.paper.withValues(alpha: 0.08)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final progress = Curves.easeInOutCubic.transform(_controller.value);

            return Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _CinematicPosterPainter(
                      progress: progress,
                      mission: widget.mission,
                    ),
                  ),
                ),
                Positioned(
                  left: 24,
                  right: 24,
                  top: 24,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth < 360) {
                        return const _BrandLockup();
                      }

                      return Row(
                        children: [
                          const Expanded(child: _BrandLockup()),
                          _StatusPill(
                            icon: Icons.movie_filter_outlined,
                            label: 'Opening sequence',
                            color: _SagaColors.gold,
                          ),
                        ],
                      );
                    },
                  ),
                ),
                Positioned(
                  left: 26,
                  right: 26,
                  bottom: 28,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Transform.translate(
                        offset: Offset(0, 8 - progress * 8),
                        child: Opacity(
                          opacity: 0.84 + progress * 0.16,
                          child: Text(
                            'WAKESAGA',
                            style: Theme.of(context).textTheme.displaySmall
                                ?.copyWith(
                                  fontSize: 62,
                                  fontWeight: FontWeight.w900,
                                  height: 0.88,
                                ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 560),
                        child: Text(
                          'The alarm is not the start. It is the opening shot.',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: _SagaColors.paper,
                                fontWeight: FontWeight.w800,
                                height: 1.08,
                              ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _StatusPill(
                            icon: widget.mission.icon,
                            label: 'Mission: ${widget.mission.label}',
                            color: _SagaColors.signal,
                          ),
                          _StatusPill(
                            icon: Icons.alarm_on_outlined,
                            label: widget.wakeTime,
                            color: _SagaColors.gold,
                          ),
                          _StatusPill(
                            icon: widget.voice.icon,
                            label: widget.voice.label,
                            color: _SagaColors.success,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Positioned(
                  right: 28,
                  top: 108,
                  child: _MissionBeacon(
                    progress: progress,
                    mission: widget.mission,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _MissionBeacon extends StatelessWidget {
  const _MissionBeacon({required this.progress, required this.mission});

  final double progress;
  final MissionType mission;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(0, math.sin(progress * math.pi * 2) * 4),
      child: Container(
        width: 172,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _SagaColors.ink.withValues(alpha: 0.62),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _SagaColors.gold.withValues(alpha: 0.38)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(mission.icon, color: _SagaColors.gold, size: 28),
            const SizedBox(height: 12),
            const Text(
              'NEXT ARC',
              style: TextStyle(
                color: _SagaColors.dim,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              mission.label,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                height: 1.02,
              ),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: 0.68 + math.sin(progress * math.pi * 2) * 0.08,
                minHeight: 6,
                backgroundColor: _SagaColors.panelHigh,
                color: _SagaColors.signal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CinematicPosterPainter extends CustomPainter {
  const _CinematicPosterPainter({
    required this.progress,
    required this.mission,
  });

  final double progress;
  final MissionType mission;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final sky = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF050607),
          Color(0xFF121513),
          Color(0xFF271611),
          Color(0xFF0A0B0C),
        ],
        stops: [0, 0.45, 0.72, 1],
      ).createShader(rect);
    canvas.drawRect(rect, sky);

    final horizonY = size.height * 0.62;
    final sunCenter = Offset(
      size.width * (0.52 + math.sin(progress * math.pi * 2) * 0.015),
      horizonY + 22 - progress * 18,
    );

    for (var i = 0; i < 5; i++) {
      final radius = 80.0 + i * 44 + progress * 8;
      final glow = Paint()
        ..color = Color.lerp(
          _SagaColors.signal,
          _SagaColors.gold,
          i / 5,
        )!.withValues(alpha: 0.12 - i * 0.016);
      canvas.drawCircle(sunCenter, radius, glow);
    }

    final sunPaint = Paint()
      ..shader = const LinearGradient(
        colors: [_SagaColors.gold, _SagaColors.signal],
      ).createShader(Rect.fromCircle(center: sunCenter, radius: 90));
    canvas.drawCircle(sunCenter, 72, sunPaint);

    final maskPaint = Paint()..color = _SagaColors.ink.withValues(alpha: 0.72);
    canvas.drawRect(
      Rect.fromLTWH(0, horizonY, size.width, size.height - horizonY),
      maskPaint,
    );

    final ridgePaint = Paint()..color = const Color(0xFF11120F);
    final ridge = Path()
      ..moveTo(0, horizonY + 34)
      ..lineTo(size.width * 0.18, horizonY - 8)
      ..lineTo(size.width * 0.34, horizonY + 22)
      ..lineTo(size.width * 0.52, horizonY - 28)
      ..lineTo(size.width * 0.72, horizonY + 20)
      ..lineTo(size.width, horizonY - 12)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(ridge, ridgePaint);

    final pathPaint = Paint()
      ..color = _SagaColors.gold.withValues(alpha: 0.58)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(size.width * 0.1, size.height * 0.86)
      ..cubicTo(
        size.width * 0.28,
        size.height * 0.74,
        size.width * 0.36,
        size.height * 0.86,
        size.width * 0.5,
        horizonY + 24,
      )
      ..cubicTo(
        size.width * 0.62,
        horizonY - 8,
        size.width * 0.78,
        horizonY + 20,
        size.width * 0.9,
        horizonY - 26,
      );
    canvas.drawPath(path, pathPaint);

    final gridPaint = Paint()
      ..color = _SagaColors.paper.withValues(alpha: 0.08)
      ..strokeWidth = 1;
    const gap = 34.0;
    for (var x = -gap + progress * gap; x < size.width + gap; x += gap) {
      canvas.drawLine(
        Offset(x, horizonY),
        Offset(x - 80, size.height),
        gridPaint,
      );
      canvas.drawLine(
        Offset(size.width - x, horizonY),
        Offset(size.width - x + 80, size.height),
        gridPaint,
      );
    }
    for (var y = horizonY; y < size.height; y += gap) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final framePaint = Paint()
      ..color = _SagaColors.signal.withValues(alpha: 0.26)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (var i = 0; i < 4; i++) {
      final inset = 16.0 + i * 16;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            inset,
            inset,
            size.width - inset * 2,
            size.height - inset * 2,
          ),
          const Radius.circular(18),
        ),
        framePaint,
      );
    }

    final scanPaint = Paint()
      ..color = mission == MissionType.recovery
          ? _SagaColors.success.withValues(alpha: 0.28)
          : _SagaColors.signal.withValues(alpha: 0.24)
      ..strokeWidth = 1.4;
    final scanY = size.height * (0.18 + progress * 0.58);
    canvas.drawLine(
      Offset(18, scanY),
      Offset(size.width - 18, scanY),
      scanPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CinematicPosterPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.mission != mission;
  }
}

class _EmptyMark extends StatelessWidget {
  const _EmptyMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        color: _SagaColors.panelHigh,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _SagaColors.line),
      ),
      child: const Icon(
        Icons.style_outlined,
        color: _SagaColors.gold,
        size: 34,
      ),
    );
  }
}

class _StatStack extends StatelessWidget {
  const _StatStack();

  @override
  Widget build(BuildContext context) {
    const stats = [
      ('Discipline', 0.78),
      ('Courage', 0.64),
      ('Focus', 0.82),
      ('Resilience', 0.69),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ARC STATS',
          style: TextStyle(
            color: _PrototypeColors.aquaDark,
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        for (final stat in stats)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stat.$1,
                  style: const TextStyle(
                    color: _PrototypeColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: stat.$2,
                    minHeight: 5,
                    backgroundColor: _PrototypeColors.line,
                    color: _PrototypeColors.gold,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _MainAppBackdrop extends StatelessWidget {
  const _MainAppBackdrop();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFFFAF2),
            _PrototypeColors.paper,
            Color(0xFFFFF0E8),
          ],
        ),
      ),
      child: CustomPaint(painter: _MainAppBackdropPainter()),
    );
  }
}

class _MainAppBackdropPainter extends CustomPainter {
  const _MainAppBackdropPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = _PrototypeColors.line.withValues(alpha: 0.46)
      ..strokeWidth = 1;
    final coralPaint = Paint()
      ..color = _PrototypeColors.coral.withValues(alpha: 0.09)
      ..style = PaintingStyle.fill;
    final aquaPaint = Paint()
      ..color = _PrototypeColors.aqua.withValues(alpha: 0.34)
      ..style = PaintingStyle.fill;
    final goldStroke = Paint()
      ..color = _PrototypeColors.gold.withValues(alpha: 0.48)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    const gap = 88.0;
    for (var x = -size.height; x < size.width; x += gap) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + size.height * 0.42, size.height),
        linePaint,
      );
    }

    final panelPath = Path()
      ..moveTo(size.width * 0.64, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height * 0.42)
      ..lineTo(size.width * 0.82, size.height * 0.5)
      ..close();
    canvas.drawPath(panelPath, coralPaint);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-30, size.height * 0.72, size.width * 0.52, 170),
        const Radius.circular(36),
      ),
      aquaPaint,
    );

    canvas.drawArc(
      Rect.fromCircle(
        center: Offset(size.width * 0.9, size.height * 0.12),
        radius: 126,
      ),
      math.pi * 0.08,
      math.pi * 1.05,
      false,
      goldStroke,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

class _SagaColors {
  static const ink = Color(0xFF080912);
  static const panel = Color(0xFF14121E);
  static const panelHigh = Color(0xFF211A2E);
  static const paper = Color(0xFFFFF6E8);
  static const muted = Color(0xFFC8C0B5);
  static const dim = Color(0xFF8A8390);
  static const line = Color(0xFF3A3246);
  static const signal = Color(0xFFFF6B3D);
  static const gold = Color(0xFFFFD166);
  static const purple = Color(0xFFFF4FA3);
  static const cyan = Color(0xFF66E8FF);
  static const lime = Color(0xFFB9FF4A);
  static const success = Color(0xFF67E087);
  static const warning = Color(0xFFFF7B72);

  static const socialText = paper;
  static const socialMuted = muted;
  static const socialCard = panelHigh;
  static const socialCream = panel;
  static const socialPink = purple;
  static const socialLilac = Color(0xFF3C244D);
  static const socialBlue = cyan;
  static const socialGreen = lime;
  static const socialYellow = gold;
  static const personaPaper = ink;
  static const personaAqua = cyan;
  static const personaCoral = signal;
  static const personaLavender = Color(0xFF6B4EFF);
}
