# WakeSaga Product Walkthrough

Audit date: 2026-06-11
Branch/context: `cold-open-rebuild` working tree

## Bottom Line

WakeSaga is not complete as an app. It is currently a strong, coherent Flutter prototype of the
new Cold Open direction: first-run setup, a time-aware Today/Saga/Cast shell, a simulated Dawn Rail,
a simulated Wake Quest, a simulated Morning Episode, a Wake Card mint, and a mock Protagonist Pass
sheet.

It is not yet a real alarm product. The alarm does not schedule native notifications or critical
alerts, AI audio is not generated or cached, Wake Quest verification uses taps/fake viewfinder
surfaces, state does not persist across launches, payments are not wired to RevenueCat/StoreKit,
and share/export is simulated.

## Validation Run

Passed locally:

```bash
flutter analyze
flutter test
flutter build ios --simulator --no-codesign
flutter test tmp/cold_open_capture_test.dart --update-goldens
```

The app compiles and the prototype flow renders, but these checks do not prove alarm delivery,
background audio, notification permissions, sensor verification, purchases, or persistence.

## Feature Status

| Feature | Status | Notes |
| --- | --- | --- |
| Cold Open visual direction | Works as prototype | The Ink-and-Signal language is implemented in `lib/theme/ink_signal.dart`, plus Today/Saga/Cast and Dawn Rail surfaces. |
| First-run onboarding | Concern | Active onboarding is a short 3-phase Cold Open: intro, Episode 0 title card, time picker. It does not collect mission, name, quest, permissions, or narrator choice. |
| Wayk-length Episode 001 Builder | Not active | Older docs and prior screenshots describe a long Wayk-style builder, but the current active app uses `FirstRunFlow`, not the 42-screen builder. |
| Native alarm scheduling | Missing | There is no local notification, AlarmKit, Android alarm, or background alarm engine. Dawn Rail is opened manually/debug via route. |
| Dawn Rail | Prototype works | `DawnTakeover -> WakeQuest -> TitleCardSlam -> EpisodePlayer -> CardMint` is a working in-app route pipeline. |
| Wake Quest verification | Simulated | Get Up and Shake are tap counters; Sky Photo is a fake viewfinder. No accelerometer, pedometer, camera, liveness, object/photo proof, or permissions yet. |
| Failure ladder | Prototype works | Two fails reveal fallback; third fail logs Filler and exits. This is a good UX pattern, but it operates only on simulated failures. |
| Morning Episode | Simulated | Script lines and timer-based playback exist. No Gemini/Flash TTS, no audio file cache, no subtitle/audio alignment, no background playback. |
| Title Card Slam | Prototype works | Episode title derives locally from mission text. No generated backgrounds or media export yet. |
| Wake Card | Prototype works | Card mints locally with title, mission, wake time, quest, and simple foil logic. It does not use a real quest photo or create a real share/export. |
| Today tab | Prototype works | Time-aware home exists with mission, Lock In, next episode, End Credits, post-miss state, and alarm sheet. State is memory-only. |
| Lock In | Simulated | Bottom sheet plays simulated text/waveform. No AI generation, audio, daily limit, timer, or premium gating. |
| Saga | Prototype works | Shows seeded demo history, volumes, timeline, binder, rival log. It is not backed by persistent real user history yet. |
| Cast | Prototype works | Roster, sample text, settings, and Protagonist Pass sheet exist. Samples are text-only; locked voices are not entitlement-gated. |
| Paywall/subscription | Mock only | Plan rows and CTA are UI only. No RevenueCat, StoreKit, restore, entitlement checks, or purchase flow. |
| Persistence | Missing | `AppState` is an in-memory `ChangeNotifier`. First-run completion, alarm, mission, cards, settings, and log reset on app restart. |
| Backend/AI | Missing | No network client, Firebase, API proxy, Gemini, Flash TTS, storage, or auth. |
| Platform readiness | Concern | iOS still targets device family `1,2` and supports landscape/iPad orientations in native files. Android release signing is still debug. |
| Store/release readiness | Missing | No real app icon pass, store screenshots, privacy strings for camera/notifications, subscription products, or production config. |

## Onboarding Assessment

The active onboarding is not the older long Wayk-style onboarding. It is intentionally aligned with
the new Cold Open spec: a fast emotional setup whose only real choice is alarm time.

That is the right strategic direction if WakeSaga is now "an alarm where the morning is the Cold
Open." A long 40-screen quiz would slow down the one job users came for: set the alarm and trust it.

However, the current onboarding is incomplete even for the simplified direction. It needs four
practical pieces before user testing:

1. **Name capture or soft default**  
   The product promise depends on the narrator using the user's name. Current default is `Rookie`,
   and name entry is buried in Cast settings.

2. **Permission primer and native prompts**  
   A real alarm app must request notification/critical alert/alarm/camera/motion permissions with
   clear timing. Current onboarding does not ask or prepare the user.

3. **Wake Quest confirmation**  
   Current setup defaults to `Get Up`. That is okay for speed, but the first run should at least
   preview "Your first Wake Quest: Get Up" with a clear Change path.

4. **Armed plan reveal**  
   After picking a time, the app should show "Episode 1 airs at 6:30 AM" plus the actual loop:
   Alarm -> Wake Quest -> Title Card -> Episode -> Wake Card. Current setup jumps straight into
   Today without a final trust-building confirmation.

Recommended onboarding shape for the current Cold Open product:

1. Cold Open intro: "Start your day like an anime character."
2. Episode 0 title card.
3. Time picker: "What time does your story start?"
4. First Wake Quest preview: Get Up default, Change optional.
5. Permission primer and native notification/alarm prompts.
6. Armed confirmation: Episode 1, time, quest, narrator, and "Alarm will ring even if app is closed."

Do not resurrect the full Wayk-length onboarding unless the product direction changes back from
Cold Open to Episode 001 Builder. The old long onboarding exists in docs/screenshots, but it is no
longer the active product model.

## Misleading Or Overstated Promises

- README says "Wayk-length Episode 001 Builder onboarding"; active code does not implement that.
- README says "cached wake-up jolt placeholder"; current Cold Open code has no audio cache path.
- README says "Lock In clip generator"; current Lock In is a simulated bottom sheet.
- Cast says "5s sample (simulated audio)"; honest, but still not a real audio pitch.
- Paywall benefits promise personalized episodes and unlimited Lock Ins; no entitlement system
  exists yet.
- "Sky Photo" implies camera verification; current implementation is a simulated viewfinder.

## Must Fix Before TestFlight With Real Users

1. Implement real native alarm/notification scheduling and the degraded notification-tap path.
2. Persist first-run completion, alarm settings, mission, quest, narrator, episode log, and cards.
3. Add permission primer and native permission requests.
4. Replace simulated Wake Quest taps with at least one real verification path.
5. Wire a minimal real audio pipeline or relabel all audio as prototype-only.
6. Update README/MVP docs so they match the active Cold Open product.
7. Fix iOS device/orientation defaults: iPhone-only, portrait-only, full-screen.
8. Remove Android release debug signing before any release build.

## Should Fix Soon

1. Add an "Episode armed" confirmation at the end of onboarding.
2. Make post-miss state actionable with a clear Comeback Quest CTA.
3. Add real share/export for Wake Card and Title Card.
4. Add real Protagonist Pass gating or hide pricing until payments are wired.
5. Replace placeholder narrator initials with real flat-cel portraits.
6. Add tests for Dawn Rail progression, fallback ladder, Card Mint, and persistence.

## What's Good

- The Cold Open IA is much clearer than the earlier 5-tab/dashboard attempts.
- Today/Saga/Cast is the right app-section structure.
- Dawn Rail has the right UX shape: no nav, one primary action, visible fallback.
- Failure-as-canon and additive episode count are implemented at the model level.
- The visual language is cohesive and distinctive enough for further iteration.
- The prototype captures the core emotional promise well enough to guide the real build.
