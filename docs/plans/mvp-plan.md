# WakeSaga MVP Plan

## One-line concept
An AI alarm clock that wakes users into their own training arc, then gives them a personalized Morning Episode to start the day with purpose.

## Core loop
1. **Night setup** — user chooses tomorrow's mission: study, gym, deep work, comeback, monk mode, recovery.
2. **Wake-up jolt** — short personalized alarm audio, generated before the alarm time.
3. **Morning Episode** — after opening the app, a cinematic 60–120 second motivational speech sets the day's stage.
4. **First action** — user taps a tiny starting task: water, desk, shoes, first page, 25-minute timer.
5. **Lock In** — on-demand short clips before hard tasks during the day.
6. **End Credits** — night reflection, reward/card, and tomorrow's mission.

## MVP screens
- Onboarding: name, goal, preferred voice/archetype, wake time.
- Tonight: choose tomorrow's mission.
- Alarm setup: preview tomorrow's wake-up jolt.
- Morning Episode: title, mission, speech player, first action.
- Lock In: 30s / 90s / 3min motivational clip generator.
- Episode Cards: saved day cards and quotes.
- End Credits: reflection + tomorrow setup.

## Voice archetypes
- Sensei: calm, wise, grounded.
- Rival: confrontational, competitive, sharp.
- Captain: commanding, team-leader energy.
- Future Self: emotionally personal and proud.
- Inner Demon: intense, darker, but never abusive.

## Retention mechanics
- Training arcs instead of basic streaks.
- Missed days become Rematch/Setback episodes instead of a hard reset.
- Character stats: Discipline, Courage, Focus, Resilience, Strength.
- Episode cards as shareable collectible summaries.
- Personalized alarm creates daily utility, not just entertainment.

## Technical notes
- Generate/cache the alarm audio before sleep, not at alarm fire time.
- Keep alarm clip short; full speech happens in-app after wake.
- Use platform-native alarm/notification capabilities, with AlarmKit where suitable on iOS and stronger alarm behavior on Android.
- Avoid anime IP: no copyrighted characters, clips, OSTs, or voice imitation.

## First build milestone
Prototype the full loop without payments:
- Create tomorrow mission.
- Generate text script.
- Generate/cached TTS audio.
- Schedule local alarm/notification.
- Open Morning Episode screen.
- Complete first action and save an episode card.
