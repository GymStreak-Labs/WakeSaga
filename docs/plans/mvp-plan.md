# WakeSaga MVP Plan

## One-line concept
An AI alarm clock that wakes users into their own training arc, then gives them a personalized Morning Episode to start the day with purpose.

## Core loop
1. **Episode 001 Builder** — a Wayk-length onboarding sequence diagnoses the user's morning loop, teaches the WakeSaga system, configures a Wayk-inspired Wake Quest, previews the plan, and introduces monetization after value is visible.
2. **Night setup** — user chooses tomorrow's mission: study, gym, deep work, comeback, monk mode, recovery.
3. **Wake-up jolt** — short personalized alarm audio, generated before the alarm time.
4. **Wake Quest** — the alarm is cleared by a tiny physical proof mission: Object Hunt, Sky Photo, Make Bed, Pushups, Water Check, Desk Photo, Shoes On, or Spoken Vow.
5. **Morning Episode** — after the Wake Quest is complete, a cinematic 60–120 second motivational speech sets the day's stage.
6. **First action / receipt** — user starts the mission and saves a collectible Wake Receipt.
7. **Lock In** — on-demand short clips before hard tasks during the day.
8. **End Credits** — night reflection, reward/card, and tomorrow's mission.

## MVP screens
- Onboarding: long Episode 001 Builder with diagnosis questions, education interstitials, mission/rival/narrator setup, Wake Quest configuration, commitment, rendering checklist, plan reveal, account prompt, and mock paywall/downsell screens.
- Tonight: choose tomorrow's mission.
- Alarm setup: preview tomorrow's wake-up jolt and complete the configured Wake Quest.
- Morning Episode: title, mission, speech player, unlocked after Wake Quest completion.
- Lock In: 30s / 90s / 3min motivational clip generator.
- Episode Cards: saved day cards and quotes.
- End Credits: reflection + tomorrow setup.

## Onboarding pattern
The onboarding intentionally stays long, matching Wayk-length structure, but it should not feel like a long form. It alternates:

1. **Question** — diagnose the old morning loop.
2. **Education/proof** — explain why WakeSaga changes that loop.
3. **Configuration** — choose mission, rival, narrator, Wake Quest, alarm behavior.
4. **Reward preview** — show the plan, wake receipt, and premium unlock.

The current prototype implements this as a data-driven Episode Builder with 45 setup beats after the cinematic opener.

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
- Wake Quests create verified first movement before the motivational episode, making the episode feel earned.

## Technical notes
- Generate/cache the alarm audio before sleep, not at alarm fire time.
- Keep alarm clip short; full speech happens in-app after wake.
- Use platform-native alarm/notification capabilities, with AlarmKit where suitable on iOS and stronger alarm behavior on Android.
- Avoid anime IP: no copyrighted characters, clips, OSTs, or voice imitation.

## First build milestone
Prototype the full loop without payments:
- Complete the Episode 001 Builder.
- Create tomorrow mission and Wake Quest.
- Generate text script.
- Generate/cached TTS audio.
- Schedule local alarm/notification.
- Complete the Wake Quest.
- Open Morning Episode screen.
- Complete first action and save an episode card.
