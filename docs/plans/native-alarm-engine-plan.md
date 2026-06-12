# Native Alarm Engine Plan

WakeSaga's core promise only works if the alarm is treated as native platform
infrastructure first, not as a Flutter timer. Flutter owns the Dawn Rail
experience. Native code owns waking the device and launching that experience.

## Product Loop

1. The user arms tomorrow's episode during onboarding or the Today tab.
2. WakeSaga persists an `AlarmPlan`: alarm id, time, repeat rhythm, quest,
   mission, narrator, episode number, and fallback rule.
3. The native alarm engine schedules the OS alarm.
4. When the alarm fires, the user sees a prominent system alarm surface.
5. The system surface opens WakeSaga into the Dawn Rail.
6. WakeSaga shows the epic in-app alarm takeover and starts the local jolt/siren.
7. The user enters Wake Quest.
8. Completing Wake Quest silences the in-app alarm, records the clear, reveals
   `MORNING EPISODE UNLOCKED`, then plays the Morning Episode.
9. If the user uses an OS/system stop path, WakeSaga records a Filler/Emergency
   Stop instead of pretending the quest was cleared.

## Current Gap

The current prototype stores `alarmTime`, `alarmEnabled`, and `quest` in
`AppState`, and launches Dawn Rail through a debug route. There is no native
scheduler, permission flow, persistence layer, system alarm handoff, Android
receiver, or real terminated-app wake path yet.

## iOS Plan

Primary path: `AlarmKit` on iOS 26+.

Apple's AlarmKit documentation describes it as scheduling prominent alarms and
countdowns, and the scheduling sample is available for iOS/iPadOS 26+. It can
schedule alarms through `AlarmManager`, request authorization, provide alert UI
content, and attach custom button behavior through App Intents.

Implementation:

1. Add a Dart `AlarmEngine` interface and a platform channel.
2. Add `ios/Runner/AlarmEngine.swift`.
3. Add `NSAlarmKitUsageDescription` to `Info.plist`.
4. On first arm, call `AlarmManager.shared.requestAuthorization()`.
5. Schedule an `AlarmConfiguration` with:
   - a stable WakeSaga alarm id,
   - one-time or weekly relative schedule,
   - title like `EP 17: THE ESSAY DEMON`,
   - tint color aligned to Ink-and-Signal crimson,
   - secondary action like `Open Wake Quest`.
6. Add App Intents for:
   - `OpenWakeQuestIntent`: opens WakeSaga with the alarm id.
   - `StopIntent`: records/logs system stop as Filler/Emergency Stop when
     possible, because system stop is not a verified quest clear.
7. Subscribe to `AlarmManager.shared.alarmUpdates` on app launch so WakeSaga can
   reconcile alarms changed while the app was not running.
8. Use deep-link or method-channel handoff to route to `DawnTakeover(alarmId)`.

Important constraint:

AlarmKit provides the reliable OS-level wake surface. The strict "quest is what
silences the alarm" rule is strongest inside WakeSaga after the user opens the
Dawn Rail. If iOS exposes a system stop control, WakeSaga should treat that as
an emergency/filler outcome, not a successful Wake Quest clear. Do not claim
that iOS has no escape hatch unless device testing proves it.

Fallback path for iOS < 26:

- Use a clearly labelled reminder mode with local notifications.
- Do not market this as full WakeSaga alarm mode.
- The app can still open into Dawn Rail, but it cannot honestly guarantee the
  same prominent alarm behavior as AlarmKit.

## Android Plan

Primary path: `AlarmManager.setAlarmClock`.

Android documentation describes `setAlarmClock()` as a precise, highly visible
alarm that the system treats as critical and does not adjust for low-power
modes. WakeSaga's use case is an alarm-clock app, so this is the right Android
primitive.

Implementation:

1. Add a native Android alarm plugin:
   - `AlarmScheduler.kt`
   - `AlarmReceiver.kt`
   - alarm launch Activity or full-screen Flutter route.
2. Declare platform permissions:
   - `SCHEDULE_EXACT_ALARM` or `USE_EXACT_ALARM` after Play policy review,
   - `POST_NOTIFICATIONS` for Android 13+,
   - full-screen intent support if needed for the alarm takeover.
3. Schedule alarms with `AlarmManager.setAlarmClock(...)`.
4. On fire, start WakeSaga with an alarm id and route to Dawn Rail.
5. Use a foreground service or alarm Activity to play the siren/jolt while the
   user is in Wake Quest.
6. On quest completion, stop the foreground alarm service and record the clear.
7. On system dismiss/emergency path, record a Filler/Emergency Stop.

## Shared Flutter Contract

Create `lib/alarm/alarm_engine.dart`:

```dart
abstract interface class AlarmEngine {
  Future<AlarmPermissionState> requestPermission();
  Future<ScheduledAlarm> schedule(AlarmPlan plan);
  Future<void> cancel(String alarmId);
  Future<List<ScheduledAlarm>> listScheduled();
  Stream<AlarmEvent> get events;
}
```

Create `AlarmPlan` with:

- `id`
- `episode`
- `time`
- `repeatDays`
- `quest`
- `mission`
- `narrator`
- `joltAssetPath`
- `fallbackQuest`
- `createdAt`

Persist it locally before scheduling. If scheduling fails after the paywall or
onboarding, the UI must show "alarm not armed" and retry instead of pretending
the episode is locked.

## Build Order

1. Add persistent `AlarmPlan` model and `AlarmEngine` interface.
2. Wire Today/onboarding arm actions to the interface using a fake engine in
   tests and previews.
3. Implement iOS AlarmKit bridge for iOS 26+.
4. Add AlarmKit authorization primer and native permission call.
5. Route AlarmKit launch/custom action into Dawn Rail.
6. Add Android `setAlarmClock` implementation.
7. Add in-app jolt/siren playback and stop control tied to Wake Quest clear.
8. Add reconciliation tests: scheduled, cancelled, fired, quest cleared,
   emergency stopped, missed.
9. Device-test locked phone, terminated app, silent mode, focus mode, repeat
   alarm, and timezone/daylight-saving changes.

## Audio Reality

The reliable first wake signal should be the OS alarm. The personalized
Gemini/Flash TTS jolt should be pre-generated before bed and played immediately
inside WakeSaga once Dawn Rail opens. Do not promise custom AI audio as the
system-level iOS alarm sound until AlarmKit device testing proves that path.

## Sources

- Apple AlarmKit documentation:
  https://developer.apple.com/documentation/AlarmKit
- Apple AlarmKit scheduling sample:
  https://developer.apple.com/documentation/alarmkit/scheduling-an-alarm-with-alarmkit
- Android alarm scheduling documentation:
  https://developer.android.com/develop/background-work/services/alarms/schedule
