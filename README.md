# WakeSaga

WakeSaga is a Flutter prototype for a cinematic AI alarm clock that turns the
morning alarm into the cold open of a daily anime-style training arc.

## Current Prototype

- Long Cold Open onboarding with morning diagnosis, education interstitials,
  saga personalization, Wake Quest setup, plan reveal, receipt preview, and mock
  monetization beats.
- Today/Saga/Cast app shell for the awake user.
- Simulated Dawn Rail: alarm takeover -> Wake Quest -> Title Card Slam ->
  Morning Episode -> Wake Card.
- Simulated Lock In moments for short motivation.
- Episode cards, post-miss comeback framing, and End Credits-style setup.

The current build is prototype-only: native alarm scheduling, Gemini/Flash TTS,
real Wake Quest verification, persistence, purchases, and share/export are not
production-wired yet.

## Development

```bash
flutter analyze
flutter test
flutter run
```

The current build is local-only and does not store credentials or connect to production services.
