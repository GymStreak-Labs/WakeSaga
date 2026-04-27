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
docs/plans/   # product and implementation plans
```

## Commands
```bash
# App scaffolding not created yet.
# Do not scaffold without confirming the chosen Flutter template/package name.
```

## Environment Variables / Credentials
Use Mission Control vault workflows only. Do not store plaintext secrets in repo files.

## Company Boundary
WakeSaga is a GymStreak Labs app. Keep App Store, Firebase, RevenueCat, ad accounts, and credentials under GymStreak Labs unless Joe explicitly says otherwise.
