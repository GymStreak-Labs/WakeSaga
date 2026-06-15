# Native Alarm Engine Plan

WakeSaga's core promise only works if the alarm is treated as native platform
infrastructure first, not as a Flutter timer. Flutter owns the Dawn Rail
experience. Native code owns waking the device and launching that experience.

## Product Loop

1. The user arms tomorrow's episode during onboarding or the Today tab.
2. WakeSaga persists both app state and an `AlarmPlan`: alarm id, time, repeat
   rhythm, quest, mission, narrator, episode number, fallback rule, paywall
   state, first-run completion, and expected-fire record.
3. The native alarm engine schedules the OS alarm.
4. When the alarm fires, the user sees a prominent system alarm surface.
5. The system surface opens WakeSaga into the Dawn Rail.
6. WakeSaga drains the native launch alarm before deciding whether to show
   onboarding, main app, or Dawn Rail.
7. WakeSaga stops/transfers the OS alarm signal into the in-app jolt/siren.
8. WakeSaga shows the epic in-app alarm takeover.
9. The user enters Wake Quest.
10. Completing Wake Quest silences the in-app alarm, records the clear, reveals
    `MORNING EPISODE UNLOCKED`, then plays the Morning Episode with the cached
    voiceover and cinematic instrumental score.
11. If the user uses an OS/system stop path, WakeSaga records a Filler/Emergency
    Stop instead of pretending the quest was cleared.

## Current Gap

The current prototype stores `alarmTime`, `alarmEnabled`, and `quest` in
`AppState`, and launches Dawn Rail through a debug route. There is no native
scheduler, permission flow, persistence layer, system alarm handoff, Android
receiver, or real terminated-app wake path yet.

Also important: `firstRunComplete` is not persisted today. If a real native
alarm launches the app from a cold/terminated state right now, WakeSaga can fall
back into onboarding/paywall instead of Dawn Rail. Persistence and launch
routing are therefore step zero.

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
9. Guard all AlarmKit code with `#available(iOS 26, *)` and weak linking unless
   the project raises its iOS baseline to 26+.

Important constraint:

AlarmKit provides the reliable OS-level wake surface. The strict "quest is what
silences the alarm" rule is strongest inside WakeSaga after the user opens the
Dawn Rail. If iOS exposes a system stop control, WakeSaga should treat that as
an emergency/filler outcome, not a successful Wake Quest clear. Do not claim
that iOS has no escape hatch unless device testing proves it.

The robust accounting path should not depend only on `StopIntent` executing
while the app is terminated. Persist an expected-fire record and reconcile on
next launch using AlarmKit updates plus WakeSaga's own clear/filler log. If an
alarm fired and no Wake Quest clear was recorded, log Filler/Knockdown.

Fallback path for iOS < 26:

- Use a clearly labelled reminder mode with local notifications.
- Do not market this as full WakeSaga alarm mode.
- The app can still open into Dawn Rail, but it cannot honestly guarantee the
  same prominent alarm behavior as AlarmKit.
- If we want Wayk-style iOS 17-25 coverage, this compatibility mode needs to be
  productized rather than hidden: local notification wake signal, bundled alarm
  sound within platform limits, deep link into Dawn Rail, in-app siren once
  foregrounded, Wake Quest verification, and Filler/Emergency Stop accounting
  for any OS-level dismiss path.

## Competitor Parity Note

Wayk's public behavior appears aligned with WakeSaga's intended loop: choose a
mission, alarm rings, complete the mission, then the alarm stops. Its iOS App
Store listing currently supports iOS 17+, so it cannot rely exclusively on
AlarmKit. The likely shape is an older compatibility stack on iOS and exact
alarm/full-screen/foreground service behavior on Android. WakeSaga should keep
the same behavioral promise while using the strongest available primitive per
platform:

- iOS 26+: true native AlarmKit mode.
- iOS 17-25: Wayk-style compatibility mode with honest limitations.
- Android: exact alarm / alarm-clock mode with foreground siren service.

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
   - exact-alarm permission split after Play policy review:
     `SCHEDULE_EXACT_ALARM` for API 31-32 and `USE_EXACT_ALARM` for API 33+
     when accepted for the alarm-clock use case,
   - `POST_NOTIFICATIONS` for Android 13+,
   - `USE_FULL_SCREEN_INTENT` for alarm takeover behavior,
   - `WAKE_LOCK`,
   - foreground service permission/type for siren playback,
   - `RECEIVE_BOOT_COMPLETED` for rescheduling after reboot.
3. Schedule alarms with `AlarmManager.setAlarmClock(...)`.
4. On fire, start WakeSaga with an alarm id and route to Dawn Rail.
5. Use a foreground service or alarm Activity to play the siren/jolt while the
   user is in Wake Quest.
6. On quest completion, stop the foreground alarm service and record the clear.
7. On system dismiss/emergency path, record a Filler/Emergency Stop.
8. On boot, read persisted `AlarmPlan` records and reschedule future alarms.

## Shared Flutter Contract

Create `lib/alarm/alarm_engine.dart`:

```dart
abstract interface class AlarmEngine {
  Future<AlarmCapabilityState> requestPermission();
  Future<ScheduledAlarm> schedule(AlarmPlan plan);
  Future<void> cancel(String alarmId);
  Future<List<ScheduledAlarm>> listScheduled();
  Future<AlarmLaunch?> consumeLaunchAlarm();
  Stream<AlarmEvent> get events;
}
```

`consumeLaunchAlarm()` is required because an alarm can launch the app before
Flutter has subscribed to the `events` stream. `WakeSagaApp` should check this
before building the normal shell, then route through a root `navigatorKey` to
the Dawn Rail.

`AlarmCapabilityState` should be structured, not a single authorized/denied
boolean. It needs to represent iOS AlarmKit auth and Android notification,
exact-alarm, full-screen-intent, and foreground-service capability separately.

Create `AlarmPlan` with:

- `id`
- `episode`
- `time`
- `repeatDays`
- `quest`
- `mission`
- `narrator`
- `joltAssetPath`
- `episodeVoiceAssetPath`
- `episodeMusicAssetPath`
- `episodeMixAssetPath`
- `fallbackQuest`
- `createdAt`

Persist it locally before scheduling. If scheduling fails after the paywall or
onboarding, the UI must show "alarm not armed" and retry instead of pretending
the episode is locked.

Also persist expected-fire records:

- `alarmId`
- scheduled fire timestamp
- actual launch timestamp, if observed
- OS stop/emergency stop, if observed
- Wake Quest clear timestamp, if completed
- final outcome: clear, filler, knockdown, emergency stop, unknown

These records let WakeSaga recover truthfully after terminated launches, app
crashes, OS-level stops, and Android reboots.

## Build Order

1. Add persistence for `AppState`, `AlarmPlan`, first-run completion, paywall
   unlock state, and expected-fire records.
2. Add `AlarmEngine` interface, `FakeAlarmEngine`, `consumeLaunchAlarm()`,
   root `navigatorKey`, and Dawn Rail launch routing.
3. Wire onboarding and Today arm/edit/cancel actions to the fake engine first,
   including scheduling-failure UI.
4. Spike AlarmKit on a real iOS 26 device before freezing the final Dart
   contract: authorization, locked/terminated firing, secondary action, stop
   semantics, `alarmUpdates`, and custom sound constraints.
5. Implement the iOS AlarmKit bridge, App Intents, authorization primer, launch
   routing, and OS-alarm-to-in-app-siren handoff.
6. Implement Android `setAlarmClock`, receiver, boot reschedule, exact-alarm
   permissions, full-screen intent, foreground siren service, and route handoff.
7. Add in-app jolt/siren playback and stop control tied to Wake Quest clear.
8. Add reconciliation tests: scheduled, cancelled, fired, OS stopped, quest
   cleared, emergency stopped, missed, reboot-rescheduled.
9. Run a feature-honesty pass: onboarding copy, real permissions, seed-data
   removal/gating, hard paywall purchase state, and "armed" copy tied to actual
   scheduling success.
10. Device-test locked phone, terminated app, silent mode, Focus mode, Android
    reboot, repeat alarm, timezone changes, and daylight-saving changes.

## Audio Reality

The reliable first wake signal should be the OS alarm. The personalized
Gemini/Flash TTS jolt should be pre-generated before bed and played immediately
inside WakeSaga once Dawn Rail opens. Do not promise custom AI audio as the
system-level iOS alarm sound until AlarmKit device testing proves that path.

The scored Morning Episode should also be generated before bed, not live at
6:30am. Treat it as an `EpisodeAudioPackage`:

1. Generate the episode script and subtitles from mission, rival, quest, recent
   outcomes, and narrator.
2. Render narrator voice with Gemini/Flash TTS.
3. Render an instrumental-only Google Lyria bed. Prompt by arc, intensity, and
   narrator, with explicit constraints: no vocals, no lyrics, no copyrighted
   themes, and leave midrange space for narration.
4. Mix server-side with voice-first ducking, loudness normalization, and a
   bundled fallback bed if Lyria fails or times out.
5. Cache the voice, music, mixed file, and subtitle timing locally before the
   alarm fires.

Do not use the Lyria bed as the main alarm signal. The alarm moment should stay
urgent and direct; the generated score is the earned post-Wake-Quest reward.

There is no audio dependency in the app today. The implementation needs an
audio package plus native audio-session configuration:

- iOS: `AVAudioSession` playback category/behavior appropriate for alarm audio.
- Android: foreground service audio focus and `USAGE_ALARM` attributes.

## Feature Honesty Fixes Before External Builds

- Replace copy like "The alarm turns off only after Wake Quest" with the more
  truthful model: Wake Quest is the verified clear; system stop becomes Filler
  or Emergency Stop.
- Do not show `EPISODE 1 IS ARMED` unless native scheduling succeeded.
- Wire the permission screen to the real `AlarmCapabilityState` or soften copy
  until the native permission flow exists.
- Remove or gate seeded demo history for real users.
- Wire purchases/restore before treating the hard paywall as production.

## Claude Code Second-Opinion Notes

Claude Code independently reviewed this plan on 2026-06-12. It agreed with the
choice of iOS AlarmKit and Android `setAlarmClock`, but flagged the blockers now
folded into this document: persistence before native scheduling, cold-start
launch draining before shell selection, explicit OS-alarm-to-in-app-siren
handoff, Android reboot/full-screen/foreground-service permissions, iOS 26
availability guards, and feature-honesty copy around system stop paths.

## Sources

- Apple AlarmKit documentation:
  https://developer.apple.com/documentation/AlarmKit
- Apple AlarmKit scheduling sample:
  https://developer.apple.com/documentation/alarmkit/scheduling-an-alarm-with-alarmkit
- Android alarm scheduling documentation:
  https://developer.android.com/develop/background-work/services/alarms/schedule
