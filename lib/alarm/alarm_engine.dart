import 'dart:async';

import 'package:flutter/widgets.dart';

import 'alarm_models.dart';

abstract interface class AlarmEngine {
  Future<AlarmCapabilityState> requestPermission();
  Future<ScheduledAlarm> schedule(AlarmPlan plan);
  Future<void> cancel(String alarmId);
  Future<List<ScheduledAlarm>> listScheduled();
  Future<AlarmLaunch?> consumeLaunchAlarm();
  Stream<AlarmEvent> get events;
}

class FakeAlarmEngine implements AlarmEngine {
  FakeAlarmEngine({AlarmLaunch? initialLaunch}) : _launch = initialLaunch;

  final _events = StreamController<AlarmEvent>.broadcast();
  final Map<String, ScheduledAlarm> _scheduled = {};
  AlarmLaunch? _launch;

  @override
  Stream<AlarmEvent> get events => _events.stream;

  @override
  Future<AlarmCapabilityState> requestPermission() async {
    return AlarmCapabilityState.fakeReady();
  }

  @override
  Future<ScheduledAlarm> schedule(AlarmPlan plan) async {
    final scheduled = ScheduledAlarm(
      plan: plan,
      scheduledFor: _nextFireDate(plan),
      engineMode: 'fake-compatibility',
    );
    _scheduled[plan.id] = scheduled;
    _events.add(
      AlarmEvent(
        type: AlarmEventType.scheduled,
        alarmId: plan.id,
        occurredAt: DateTime.now(),
      ),
    );
    return scheduled;
  }

  @override
  Future<void> cancel(String alarmId) async {
    _scheduled.remove(alarmId);
    _events.add(
      AlarmEvent(
        type: AlarmEventType.cancelled,
        alarmId: alarmId,
        occurredAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<List<ScheduledAlarm>> listScheduled() async {
    return _scheduled.values.toList(growable: false);
  }

  @override
  Future<AlarmLaunch?> consumeLaunchAlarm() async {
    final launch = _launch;
    _launch = null;
    return launch;
  }

  DateTime _nextFireDate(AlarmPlan plan) {
    final now = DateTime.now();
    var next = DateTime(now.year, now.month, now.day, plan.hour, plan.minute);
    if (!next.isAfter(now)) next = next.add(const Duration(days: 1));
    if (plan.repeatDays.isEmpty) return next;
    while (!plan.repeatDays.contains(next.weekday)) {
      next = next.add(const Duration(days: 1));
    }
    return next;
  }

  void dispose() {
    _events.close();
  }
}

class AlarmScope extends InheritedWidget {
  const AlarmScope({super.key, required this.engine, required super.child});

  final AlarmEngine engine;

  static AlarmEngine of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AlarmScope>();
    assert(scope != null, 'AlarmScope not found in widget tree');
    return scope!.engine;
  }

  static AlarmEngine read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<AlarmScope>();
    assert(scope != null, 'AlarmScope not found in widget tree');
    return scope!.engine;
  }

  @override
  bool updateShouldNotify(AlarmScope oldWidget) => engine != oldWidget.engine;
}
