import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'dawn_rail/dawn_takeover.dart';
import 'onboarding/first_run.dart';
import 'state/app_state.dart';
import 'tabs/cast.dart';
import 'tabs/saga.dart';
import 'tabs/today.dart';
import 'theme/ink_signal.dart';

const _previewMainApp = bool.fromEnvironment('WAKE_SAGA_PREVIEW_MAIN_APP');
const _previewTab = String.fromEnvironment('WAKE_SAGA_PREVIEW_TAB');
const _previewBand = String.fromEnvironment('WAKE_SAGA_PREVIEW_BAND');

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: InkSignal.base,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const WakeSagaApp());
}

class WakeSagaApp extends StatefulWidget {
  const WakeSagaApp({super.key});

  @override
  State<WakeSagaApp> createState() => _WakeSagaAppState();
}

class _WakeSagaAppState extends State<WakeSagaApp> {
  late final AppState _state = _buildInitialState();

  AppState _buildInitialState() {
    final state = AppState();
    if (_previewMainApp) {
      state.firstRunComplete = true;
      state.alarmEnabled = true;
      state.userName = 'Joe';
      state.narrator = 'Mentor';
      state.quest = 'Get Up';
      state.missionText = 'Finish the essay outline';
      state.debugBand = switch (_previewBand) {
        'morning' => TodayBand.morning,
        'day' => TodayBand.day,
        'night' => TodayBand.night,
        'postMiss' || 'miss' => TodayBand.postMiss,
        _ => TodayBand.day,
      };
    }
    return state;
  }

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: _state,
      child: MaterialApp(
        title: 'WakeSaga',
        debugShowCheckedModeBanner: false,
        theme: InkSignal.theme(),
        home: const WakeSagaShell(),
      ),
    );
  }
}

class WakeSagaShell extends StatelessWidget {
  const WakeSagaShell({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    if (!state.firstRunComplete) {
      return const FirstRunFlow();
    }
    return const MainAppShell();
  }
}

class MainAppShell extends StatefulWidget {
  const MainAppShell({super.key});

  @override
  State<MainAppShell> createState() => _MainAppShellState();
}

class _MainAppShellState extends State<MainAppShell> {
  late int _tabIndex = switch (_previewTab) {
    'saga' => 1,
    'cast' => 2,
    _ => 0,
  };

  void _openSaga() {
    setState(() => _tabIndex = 1);
  }

  void _ringAlarmNow() {
    HapticFeedback.heavyImpact();
    Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder<void>(
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
        pageBuilder: (_, _, _) => const DawnTakeover(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      TodayTab(onOpenSaga: _openSaga),
      const SagaTab(),
      const CastTab(),
    ];

    return Scaffold(
      backgroundColor: InkSignal.base,
      body: Stack(
        children: [
          Positioned.fill(
            child: IndexedStack(index: _tabIndex, children: pages),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 12 + MediaQuery.paddingOf(context).bottom,
            child: _ColdOpenTabBar(
              selectedIndex: _tabIndex,
              onChanged: (index) => setState(() => _tabIndex = index),
            ),
          ),
          // TestFlight/dev affordance: not part of the user path, but lets us
          // capture the full Dawn Rail without waiting for the OS alarm engine.
          if (const bool.fromEnvironment('WAKE_SAGA_SHOW_RING_NOW'))
            Positioned(
              right: 20,
              top: MediaQuery.paddingOf(context).top + 12,
              child: IconButton(
                key: const Key('ringNow'),
                tooltip: 'Ring alarm now',
                color: InkSignal.paper.withValues(alpha: 0.5),
                onPressed: _ringAlarmNow,
                icon: const Icon(Icons.alarm),
              ),
            ),
        ],
      ),
    );
  }
}

class _ColdOpenTabBar extends StatelessWidget {
  const _ColdOpenTabBar({
    required this.selectedIndex,
    required this.onChanged,
  });

  final int selectedIndex;
  final ValueChanged<int> onChanged;

  static const _items = [
    _TabSpec('TODAY', Icons.flash_on_rounded),
    _TabSpec('SAGA', Icons.auto_stories_rounded),
    _TabSpec('CAST', Icons.record_voice_over_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xF2161B26),
        borderRadius: BorderRadius.circular(InkSignal.chromeRadius),
        border: Border.all(color: InkSignal.inkBorder, width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0xAA000000),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Row(
          children: [
            for (var i = 0; i < _items.length; i++)
              Expanded(
                child: _TabButton(
                  spec: _items[i],
                  selected: selectedIndex == i,
                  onTap: () => onChanged(i),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.spec,
    required this.selected,
    required this.onTap,
  });

  final _TabSpec spec;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: Key('tab${spec.label}'),
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: 54,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? InkSignal.paper : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              spec.icon,
              size: 20,
              color: selected
                  ? InkSignal.base
                  : InkSignal.paper.withValues(alpha: 0.48),
            ),
            const SizedBox(width: 7),
            Text(
              spec.label,
              style: InkSignal.ui(
                13,
                color: selected
                    ? InkSignal.base
                    : InkSignal.paper.withValues(alpha: 0.48),
                weight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabSpec {
  const _TabSpec(this.label, this.icon);

  final String label;
  final IconData icon;
}
