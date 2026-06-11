# WakeSaga

## Overview
WakeSaga is a GymStreak Labs app that turns the morning alarm into the start of a user's daily training arc: a short personalized wake-up jolt followed by a cinematic Morning Episode that sets the mission, obstacle, and first action for the day.

## Product Direction
- Wake-up audio: short, urgent, personalized alarm clip generated ahead of time.
- Morning Episode: 60–120 second motivational setup after the user opens the app.
- Lock In clips: short AI-generated motivation before study, gym, work, or recovery moments.
- End Credits: nightly reflection and tomorrow's mission setup.

## Tech Stack
- **Framework**: Flutter (planned)
- **Platform**: iOS + Android
- **AI Audio**: Gemini/Flash TTS pipeline (planned)

## Project Structure
```bash
docs/plans/     # product and implementation plans (cold-open-direction/ = design spec)
lib/theme/      # INK-AND-SIGNAL tokens (InkSignal)
lib/state/      # AppState — single ChangeNotifier exposed via AppScope
lib/onboarding/ # First Run cold-open flow
lib/tabs/       # Today / Saga / Cast (the only 3 tabs)
lib/dawn_rail/  # Alarm → Quest → Title Card → Episode → Card Mint pipeline
lib/widgets/    # screentone painters, hard-cut routes, mini card thumb
tmp/            # golden capture harnesses (not shipped)
```

## Commands
```bash
flutter analyze && flutter test
flutter build ios --simulator --no-codesign
flutter test tmp/cold_open_capture_test.dart --update-goldens   # screen captures
```

## UI Gotchas
- One crimson accent element per screen; gold ONLY for share/milestone/foil.
- The floating 3-tab bar in main.dart overlays tab bodies — reserve
  `InkSignal.tabBarClearance` at the bottom of every tab body.
- Today's DBG CLOCK row renders only in debug builds (`kDebugMode`).
- Preview env flags: WAKE_SAGA_PREVIEW_MAIN_APP / _TAB / _BAND, WAKE_SAGA_SHOW_RING_NOW.

## Environment Variables / Credentials
Use Mission Control vault workflows only. Do not store plaintext secrets in repo files.

## Company Boundary
WakeSaga is a GymStreak Labs app. Keep App Store, Firebase, RevenueCat, ad accounts, and credentials under GymStreak Labs unless Joe explicitly says otherwise.
