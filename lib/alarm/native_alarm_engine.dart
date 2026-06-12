import 'dart:async';

import 'package:flutter/services.dart';

import 'alarm_engine.dart';
import 'alarm_models.dart';

class NativeAlarmEngine implements AlarmEngine {
  NativeAlarmEngine({
    MethodChannel channel = const MethodChannel('wakesaga/alarm_engine'),
    AlarmEngine? fallback,
  }) : _channel = channel,
       _fallback = fallback ?? FakeAlarmEngine();

  final MethodChannel _channel;
  final AlarmEngine _fallback;
  final _events = StreamController<AlarmEvent>.broadcast();

  @override
  Stream<AlarmEvent> get events => _events.stream;

  @override
  Future<AlarmCapabilityState> requestPermission() async {
    final result = await _invokeMap('requestPermission');
    if (result == null) return _fallback.requestPermission();
    return _capabilityFromMap(result);
  }

  @override
  Future<ScheduledAlarm> schedule(AlarmPlan plan) async {
    final result = await _invokeMap('schedule', plan.toJson());
    if (result == null) return _fallback.schedule(plan);
    final scheduled = ScheduledAlarm.fromJson(result);
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
    final handled = await _invokeBool('cancel', {'alarmId': alarmId});
    if (!handled) {
      await _fallback.cancel(alarmId);
      return;
    }
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
    final result = await _invokeList('listScheduled');
    if (result == null) return _fallback.listScheduled();
    return result
        .whereType<Map>()
        .map((item) => ScheduledAlarm.fromJson(Map<String, Object?>.from(item)))
        .toList(growable: false);
  }

  @override
  Future<AlarmLaunch?> consumeLaunchAlarm() async {
    final result = await _invokeMap('consumeLaunchAlarm');
    if (result == null) return _fallback.consumeLaunchAlarm();
    return AlarmLaunch(
      alarmId: result['alarmId'] as String? ?? 'unknown',
      source: AlarmLaunchSource.values.firstWhere(
        (value) => value.name == result['source'],
        orElse: () => AlarmLaunchSource.coldStart,
      ),
      launchedAt:
          DateTime.tryParse(result['launchedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Future<Map<String, Object?>?> _invokeMap(
    String method, [
    Object? arguments,
  ]) async {
    try {
      final result = await _channel.invokeMapMethod<String, Object?>(
        method,
        arguments,
      );
      return result == null ? null : Map<String, Object?>.from(result);
    } on MissingPluginException {
      return null;
    } on PlatformException {
      rethrow;
    }
  }

  Future<List<Object?>?> _invokeList(String method) async {
    try {
      return await _channel.invokeListMethod<Object?>(method);
    } on MissingPluginException {
      return null;
    }
  }

  Future<bool> _invokeBool(String method, [Object? arguments]) async {
    try {
      return await _channel.invokeMethod<bool>(method, arguments) ?? false;
    } on MissingPluginException {
      return false;
    }
  }

  AlarmCapabilityState _capabilityFromMap(Map<String, Object?> map) {
    AlarmCapabilityStatus status(String key) {
      return AlarmCapabilityStatus.values.firstWhere(
        (value) => value.name == map[key],
        orElse: () => AlarmCapabilityStatus.unknown,
      );
    }

    return AlarmCapabilityState(
      alarmKit: status('alarmKit'),
      notifications: status('notifications'),
      exactAlarm: status('exactAlarm'),
      fullScreenIntent: status('fullScreenIntent'),
      foregroundService: status('foregroundService'),
      compatibilityMode: map['compatibilityMode'] as bool? ?? true,
      message: map['message'] as String?,
    );
  }

  void dispose() {
    _events.close();
    if (_fallback case FakeAlarmEngine fake) {
      fake.dispose();
    }
  }
}
