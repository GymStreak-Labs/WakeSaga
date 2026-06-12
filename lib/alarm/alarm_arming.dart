import '../state/app_state.dart';
import 'alarm_engine.dart';

/// Arms the active alarm plan through the engine and records the truthful
/// outcome on [state]. Returns true only when the engine confirmed a
/// schedule — callers must never claim "armed" on a false return.
Future<bool> armAlarmPlan({
  required AppState state,
  required AlarmEngine engine,
}) async {
  try {
    final capability = await engine.requestPermission();
    if (!capability.canSchedule) {
      state.markAlarmScheduleFailed(
        capability.message ?? 'Alarm permission is not ready yet.',
      );
      return false;
    }
    final scheduled = await engine.schedule(state.ensureActiveAlarmPlan());
    state.confirmScheduledAlarm(scheduled);
    return true;
  } catch (error) {
    state.markAlarmScheduleFailed('Could not arm alarm: $error');
    return false;
  }
}
