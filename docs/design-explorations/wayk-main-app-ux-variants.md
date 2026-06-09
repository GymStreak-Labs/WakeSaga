# WakeSaga Main App UX Variants After Wayk Research

Date: 2026-06-09

## Research Base

- Local reference: `/Users/missioncontrol/.mission-control/knowledge/reference-bank/wayk_sequence_recreation_spec.md`
- Current public Wayk site: https://wayk.io/
- Current App Store page: https://apps.apple.com/us/app/wayk-alarm-clock-to-wake-up/id6758021281
- App Store screenshot contact sheet saved locally at `tmp/wayk-research/wayk-appstore-contact-sheet.jpg`

The App Store listing currently positions Wayk as `Wayk: Alarm Clock to Wake Up`, with the subtitle `Heavy sleepers, Stop snoozing`. Public listing data observed on 2026-06-09 showed roughly 15K ratings and a 4.77 average rating.

## What Wayk Gets Right

Wayk's UX is not complicated. That is the product advantage.

1. **One protocol**
   - Choose a mission before bed.
   - Alarm rings.
   - Complete the mission.
   - Alarm turns off.
   - Start the day.

2. **The home screen has a real anchor**
   - The visible object is tomorrow's alarm time.
   - The mission and sound sit directly under that alarm.
   - History is present, but secondary.

3. **Missions are concrete**
   - Pushups, sky photo, make bed, object hunt, affirmation.
   - These read as physical proof tasks, not abstract settings.

4. **The morning success screen is simple**
   - It says the alarm turned off.
   - It gives a few small stats.
   - The next button is `Start My Day`.

5. **Advanced configuration stays below the core loop**
   - Choose Mission and Alarm Sound are utility screens.
   - They support the main alarm, they do not become the main app.

## Why The Current WakeSaga Main App Feels Off

The current main app has the right ingredients, but the wrong interaction model.

- It exposes six equal destinations: Tonight, Alarm, Morning, Lock In, Cards, Credits.
- The user has to know which stage they are in before the app helps them.
- The most important sequence is split across separate tabs: stage alarm, clear quest, play episode, complete action, save card.
- `Cards` and `Credits` are exposed like primary app areas before the user has built the daily habit.
- The interface feels like an admin dashboard for WakeSaga's concepts instead of the morning companion itself.
- Anime language is present, but not yet doing enough product work. It should map to state: current episode, current obstacle, next scene, wake proof, receipt.

The first-principles correction: WakeSaga should not ask, "Which section do you want?" It should answer, "Here is the next scene."

## Design Principle

WakeSaga's main app should be a time-aware state machine:

- Before bed: prepare tomorrow's opening scene.
- At alarm time: complete the Wake Quest.
- After the quest: play the Morning Episode.
- After the episode: do the first action and save the receipt.
- Later: generate a Lock In clip when needed.
- At night: run End Credits and set tomorrow.

The home screen can show the whole loop, but only one action should be visually dominant at a time.

## Variant 1: Next Scene Home

Recommended.

### Core idea

Replace the six-stage navigation with a single home screen titled by the current state:

- `Tomorrow's Opening`
- `Wake Quest`
- `Morning Episode`
- `First Action`
- `Lock In`
- `End Credits`

The screen has one large hero card and one primary CTA. The CTA changes based on state:

- `Lock Tomorrow's Opening`
- `Clear Object Hunt`
- `Play Morning Episode`
- `Start First Action`
- `Generate Lock In`
- `Roll End Credits`

### Screen structure

1. Top status row
   - WakeSaga logo
   - next alarm time
   - small streak/receipt button

2. Hero protocol card
   - Large time, for example `6:30 AM`
   - Mission, for example `Deep Work`
   - Wake Quest, for example `Object Hunt`
   - Current state label, for example `Quest armed`
   - One primary CTA

3. Mini loop rail
   - `Wake Jolt`
   - `Wake Quest`
   - `Morning Episode`
   - `First Action`
   - `Receipt`

4. Secondary actions
   - Edit mission
   - Change sound
   - Generate Lock In
   - View cards

### Why this works

It keeps Wayk's clarity: a mission alarm with a clear next action. It also keeps WakeSaga's twist: the mission unlocks a personal episode, not just an alarm dismissal.

### Risk

If the hero card becomes too poster-like, it can drift back into decoration. The CTA and status must stay more important than the art.

## Variant 2: Episode Timeline

### Core idea

Make the main screen a vertical daily timeline. The user sees the whole day, but the active row is expanded and everything else is compact.

### Screen structure

1. Header
   - `Episode 001`
   - `Starts at 6:30 AM`
   - small edit control

2. Timeline rows
   - `Tonight: Opening scene locked`
   - `6:30 AM: Wake Jolt`
   - `6:31 AM: Object Hunt`
   - `After quest: Morning Episode`
   - `First 10 min: Deep Work block`
   - `Tonight: End Credits`

3. Active row
   - Expanded card with copy, player, proof UI, or CTA depending on state.

4. Bottom nav
   - Home
   - Lock In
   - Cards
   - Settings

### Why this works

It makes the product model understandable without hiding anything. It is the best variant for teaching users what WakeSaga does after the long onboarding.

### Risk

It can still feel busy if too many rows are expanded or if every row gets a card. The inactive rows need to be extremely compact.

## Variant 3: Alarm Card First

### Core idea

Lean closer to Wayk's utility model. Home is mostly an alarm app screen, with the WakeSaga episode layer attached to the alarm.

### Screen structure

1. Calendar strip
   - Weekdays and next alarm date.

2. Large alarm card
   - `Tomorrow`
   - `6:30 AM`
   - toggle armed/on
   - mission and sound cards

3. Today's wake receipt
   - latest completion result
   - time to clear quest
   - first action done/not done

4. Primary CTA
   - `Arm Episode 001`
   - morning state becomes `Clear Wake Quest`

5. Bottom nav
   - Home
   - Alarm
   - Lock In
   - Cards
   - Settings

### Why this works

It is probably the most intuitive for heavy sleepers because it starts from a familiar alarm mental model. It keeps the AI/anime layer as the reward after the concrete alarm is trusted.

### Risk

It may feel less ownable than Variant 1. WakeSaga could become "Wayk plus an episode" instead of a distinct story-driven product.

## Variant 4: Episode Poster Hub

### Core idea

Make each day feel like a collectible episode poster, but put a strict utility checklist underneath it.

### Screen structure

1. Poster area
   - `No More Snooze Arc`
   - mission art
   - alarm time
   - narrator badge

2. Checklist
   - `Wake Jolt cached`
   - `Object Hunt armed`
   - `Morning Episode ready`
   - `First action chosen`

3. Primary CTA
   - `Lock Episode`
   - morning state becomes `Clear Wake Quest`

4. Secondary drawer
   - edit mission, sound, narrator, card library.

### Why this works

It is the most viral and brand-forward. It may produce the most shareable screenshots.

### Risk

This is the easiest one to make pretty but unintuitive. It should only win if the checklist and primary CTA remain brutally clear.

## Recommendation

Build **Variant 1: Next Scene Home**, borrowing the compact daily rail from Variant 2.

This gives WakeSaga a clearer product sentence:

`WakeSaga prepares tomorrow's opening scene, makes you clear a Wake Quest, then unlocks your Morning Episode and first action.`

It also avoids the current dashboard problem. The user lands on one state, one hero object, and one next action.

## Implementation Direction

Replace the current main app shell with:

- `SagaMoment` enum: `tonight`, `alarmArmed`, `questActive`, `episodeReady`, `firstAction`, `daytime`, `endCredits`.
- `NextSceneHome` widget as the primary screen after onboarding.
- `WakeProtocolCard` for the main alarm/mission/quest hero.
- `ProtocolRail` for the compact loop.
- `SecondaryActionGrid` for edit mission, sound, Lock In, cards.
- Move Cards and Credits out of top-level navigation and into secondary routes/sheets.
- Keep a small bottom nav only for `Home`, `Lock In`, `Cards`, `Settings`.

Acceptance criteria:

- First post-onboarding screen has one dominant CTA above the fold.
- No horizontal six-stage carousel on mobile.
- The user can understand the full loop without tapping.
- The user can change mission, quest, sound, and narrator from secondary controls.
- Morning mode makes `Clear Wake Quest` the only dominant action until cleared.
- After quest completion, `Play Morning Episode` becomes the dominant action.
