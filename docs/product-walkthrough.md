# WakeSaga Product Walkthrough

Audit date: 2026-06-11
Branch/context: `cold-open-rebuild`

## Bottom Line

WakeSaga is now a coherent Flutter prototype of the Cold Open direction. The
active build has the long first-run onboarding Joe asked for, a Today/Saga/Cast
app shell, a simulated alarm-to-card Dawn Rail, a simulated Wake Quest, a
simulated Morning Episode, a Wake Card mint, and a mock Protagonist Pass sheet.

It is not yet a production alarm app. The current app does not schedule native
notifications, critical alerts, AlarmKit/Android alarms, or background audio.
Gemini/Flash TTS is planned but not wired. Wake Quest verification uses
simulated controls, state is memory-only, payments are mock UI, and share/export
is not real yet.

## Validation Run

Passed locally:

```bash
flutter analyze
flutter test
flutter test tmp/long_onboarding_capture_test.dart --update-goldens
flutter build ios --simulator --no-codesign
```

Simulator proof recordings were captured for:

- Full long onboarding through handoff into the app.
- Main app + Dawn Rail loop: Today/Cast, alarm takeover, Wake Quest, episode,
  and Wake Card.

These checks prove the prototype renders and the in-app flow can be driven. They
do not prove OS alarm delivery, background execution, notification permissions,
camera/motion verification, purchases, persistence, or generated audio.

## Feature Status

| Feature | Status | Notes |
| --- | --- | --- |
| Cold Open visual direction | Prototype works | Ink-and-Signal is implemented in `lib/theme/ink_signal.dart`: ink navy, paper type, one crimson action, gold reserved for reward/foil. |
| Long onboarding | Prototype works | `FirstRunFlow` is the active onboarding. It runs the long Cold Open builder with diagnosis, education, arc/rival/narrator setup, Wake Quest configuration, permission primer, commitment, rendering, plan reveal, receipt, and mock pass beats. |
| Onboarding transitions | Prototype works | The duplicate animation glitch was fixed by managing the crimson swipe as a staged overlay instead of stacking route/page switch animations. |
| First screen | Prototype works | The cold open starts with `Start your day like an anime character`. |
| Native alarm scheduling | Missing | Dawn Rail is opened through an in-app/debug route. No native alarm/notification/critical-alert engine exists yet. |
| Dawn Rail | Prototype works | `DawnTakeover -> WakeQuest -> TitleCardSlam -> EpisodePlayer -> CardMint` is a working in-app route pipeline. |
| Wake Quest verification | Simulated | Get Up and Shake are tap counters; Sky Photo is a fake viewfinder. No accelerometer, pedometer, camera, liveness, object/photo proof, or permissions yet. |
| Failure ladder | Prototype works | Two failed verifies reveal a fallback; the third logs Filler and exits so the alarm does not trap the user. |
| Morning Episode | Simulated | Script lines and timer-based playback exist. No Gemini/Flash TTS, cached audio, subtitle/audio alignment, or background playback yet. |
| Title Card Slam | Prototype works | Episode title derives locally from mission text. No generated title-card media/export yet. |
| Wake Card | Prototype works | Card mints locally with title, mission, wake time, quest, and simple foil logic. It does not use a real quest photo or create a real share/export. |
| Today tab | Prototype works | State-aware Today has morning/day/night/post-miss modes, mission editing, lock-tomorrow CTA, comeback CTA, and loop rail. State is memory-only. |
| Saga | Prototype works | Shows seeded demo history, volume shelf, timeline, binder, and rival log. It is not backed by persistent real user history yet. |
| Cast | Prototype works | Narrator roster, samples, settings, and Protagonist Pass sheet exist. Samples are text-only and locked voices are not entitlement-gated. |
| Lock In | Simulated | Lock In exists as a fast in-app moment. No generated audio, timer, limits, or entitlement rules yet. |
| Paywall/subscription | Mock only | Protagonist Pass UI exists. There is no RevenueCat, StoreKit, restore handling, purchase flow, or entitlement check. |
| Persistence | Missing | `AppState` is an in-memory `ChangeNotifier`; first-run completion, settings, alarm time, mission, cards, and logs reset on restart. |
| Backend/AI | Missing | No Firebase/auth/API proxy/Gemini/Flash TTS/storage implementation yet. |
| Store/release readiness | Missing | Needs production app icon, screenshots, privacy strings, subscription products, native permissions, signing, and platform config hardening. |

## Onboarding Assessment

The long onboarding is active again. It is intentionally long, but it now has
one job per page and alternates diagnosis, proof/education, configuration, and
payoff so it feels like WakeSaga is building the user's episode rather than
asking a generic quiz.

Current strengths:

1. It opens with the correct product promise: `Start your day like an anime
   character`.
2. It diagnoses the old morning loop before asking for setup details.
3. It explains the loop clearly: Alarm -> Wake Quest -> Title Card -> Morning
   Episode -> Wake Card.
4. It uses the Wayk-inspired Wake Quest mechanic without copying Wayk's brand.
5. It avoids the earlier repeated `CANON NOTE` issue by giving each education
   beat its own label.
6. It hands off into the Today app instead of ending as a detached demo.

Still needed before user testing:

1. Persist onboarding completion and chosen setup.
2. Add real permission priming tied to native prompts.
3. Replace mock pass pricing with a real purchase/restore path or hide it.
4. Add at least one real Wake Quest verification path.
5. Make the final plan reveal schedule a real native alarm.

## GPT-Image-1.5 Asset Opportunities

Transparent-background assets would help most where they support story moments
without adding UI clutter:

1. Cold open protagonist cutout behind the first-run promise.
2. Title Card Slam crimson/ink speed slash.
3. Small Wake Quest mission cutouts for Object Hunt, Water Check, Sky Photo,
   Desk Ready, and Get Up.
4. Flat-cel narrator busts for Cast.
5. Wake Card foil stamps such as First Light, Comeback, No Snooze, and Storm
   Riser.
6. Post-miss comeback red-ink stamp.

Detailed prompt seeds and implementation order live in
`docs/plans/cold-open-asset-opportunities.md`.

## Must Fix Before TestFlight With Real Users

1. Implement native alarm/notification scheduling and the degraded
   notification-tap path.
2. Persist first-run completion, alarm settings, mission, quest, narrator,
   episode log, and cards.
3. Add permission primer screens that trigger native permission prompts at the
   right moment.
4. Replace simulated Wake Quest taps with at least one real verification path.
5. Wire a minimal real Gemini/Flash TTS pipeline or keep all audio clearly
   prototype-labeled.
6. Add real Wake Card / Title Card export.
7. Wire RevenueCat/StoreKit or remove purchase-facing UI from test builds.
8. Harden iOS/Android release config, icons, privacy strings, and signing.

## What Is Good

- The app now has a coherent Cold Open product loop rather than a dashboard of
  equal features.
- The long onboarding is back and aligned with the app's identity.
- Today/Saga/Cast is the right app-section structure for an awake user.
- Dawn Rail is the right morning structure for a half-asleep user: no nav, one
  primary action, visible fallback.
- Failure-as-canon and additive episode count are implemented at the model
  level.
- The design language is distinctive enough to continue building real product
  mechanics on top of it.
