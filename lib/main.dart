import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'alarm/alarm_engine.dart';
import 'alarm/alarm_models.dart';
import 'alarm/native_alarm_engine.dart';
import 'dawn_rail/dawn_takeover.dart';
import 'onboarding/first_run.dart';
import 'state/app_state.dart';
import 'state/app_state_store.dart';
import 'tabs/profile.dart';
import 'tabs/saga.dart';
import 'tabs/today.dart';
import 'theme/ink_signal.dart';

const _previewMainApp = bool.fromEnvironment('WAKE_SAGA_PREVIEW_MAIN_APP');
const _previewTab = String.fromEnvironment('WAKE_SAGA_PREVIEW_TAB');
const _previewBand = String.fromEnvironment('WAKE_SAGA_PREVIEW_BAND');

final rootNavigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  final analytics = FirebaseAnalytics.instance;
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: InkSignal.base,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  final store = await AppStateStore.create();
  final alarmEngine = NativeAlarmEngine();
  final initialState = _previewMainApp ? null : store.loadState();
  final initialLaunch = await alarmEngine.consumeLaunchAlarm();
  runApp(
    WakeSagaApp(
      initialState: initialState,
      store: store,
      alarmEngine: alarmEngine,
      initialAlarmLaunch: initialLaunch,
      analytics: analytics,
    ),
  );
}

class WakeSagaApp extends StatefulWidget {
  const WakeSagaApp({
    super.key,
    this.initialState,
    this.store,
    this.alarmEngine,
    this.initialAlarmLaunch,
    this.analytics,
  });

  final AppState? initialState;
  final AppStateStore? store;
  final AlarmEngine? alarmEngine;
  final AlarmLaunch? initialAlarmLaunch;
  final FirebaseAnalytics? analytics;

  @override
  State<WakeSagaApp> createState() => _WakeSagaAppState();
}

class _WakeSagaAppState extends State<WakeSagaApp> {
  late final AppState _state;
  late final AlarmEngine _alarmEngine;
  AppStateStore? _store;

  @override
  void initState() {
    super.initState();
    _state = widget.initialState ?? _buildInitialState();
    _alarmEngine = widget.alarmEngine ?? FakeAlarmEngine();
    _store = widget.store;
    if (widget.initialAlarmLaunch != null) {
      _state.registerAlarmLaunch(widget.initialAlarmLaunch!);
    }
    _store?.bind(_state);
  }

  AppState _buildInitialState() {
    final state = AppState(seedDemoHistory: _previewMainApp);
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
    _store?.dispose();
    if (_alarmEngine case FakeAlarmEngine fake) {
      fake.dispose();
    } else if (_alarmEngine case NativeAlarmEngine native) {
      native.dispose();
    }
    _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlarmScope(
      engine: _alarmEngine,
      child: AppScope(
        state: _state,
        child: MaterialApp(
          navigatorKey: rootNavigatorKey,
          title: 'WakeSaga',
          debugShowCheckedModeBanner: false,
          navigatorObservers: [
            if (widget.analytics != null)
              FirebaseAnalyticsObserver(analytics: widget.analytics!),
          ],
          theme: InkSignal.theme(),
          home: const WakeSagaShell(),
        ),
      ),
    );
  }
}

class WakeSagaShell extends StatelessWidget {
  const WakeSagaShell({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final launchPending = state.pendingAlarmLaunch != null;
    if (!state.firstRunComplete && !launchPending) {
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
    'profile' || 'cast' => 2,
    _ => 0,
  };
  bool _profileAssetsPrecached = false;

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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final launch = AppScope.of(
        context,
        listen: false,
      ).consumePendingAlarmLaunch();
      if (launch != null) _ringAlarmNow();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_profileAssetsPrecached) return;
    _profileAssetsPrecached = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      precacheProfileNarratorAssets(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      TodayTab(onOpenSaga: _openSaga),
      SagaTab(onOpenToday: () => setState(() => _tabIndex = 0)),
      const ProfileTab(),
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
  const _ColdOpenTabBar({required this.selectedIndex, required this.onChanged});

  final int selectedIndex;
  final ValueChanged<int> onChanged;

  static const _items = [
    _TabSpec('TODAY', Icons.flash_on_rounded),
    _TabSpec('SAGA', Icons.auto_stories_rounded),
    _TabSpec('PROFILE', Icons.person_rounded),
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: FittedBox(
            fit: BoxFit.scaleDown,
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
                const SizedBox(width: 6),
                Text(
                  spec.label,
                  style: InkSignal.ui(
                    13,
                    color: selected
                        ? InkSignal.base
                        : InkSignal.paper.withValues(alpha: 0.48),
                    weight: FontWeight.w900,
                    letterSpacing: 0.7,
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

class _TabSpec {
  const _TabSpec(this.label, this.icon);

  final String label;
  final IconData icon;
}
