# Alarm Product UX Rethink

Date: 2026-06-12
Branch: `cold-open-rebuild`

## Why This Rethink Exists

WakeSaga currently has the emotional shape of a strong product: Cold Open,
Wake Quest, Morning Episode, Wake Card. The missing piece is that it still does
not feel like a fully trusted alarm app. A user who depends on it every morning
needs more than a pretty alarm moment. They need to know:

- exactly what alarms are armed,
- which days and times they fire,
- what mission will silence each alarm,
- what happens if verification fails,
- whether the phone/settings can actually wake them,
- what the episode payoff is after the alarm is cleared.

The UX should behave like an alarm utility first, then reveal the anime layer as
the reward system. If the utility layer feels ambiguous, the fantasy cannot
carry it.

## Competitive Alarm Functionality Baseline

Wayk's public positioning is simple: the alarm rings and a mission must be
completed before it turns off. App Store review/developer-response language also
calls out "object hunt" style missions. Alarmy has a broader, more mature alarm
feature set: photo/object missions, math/memory/shake/squat/step missions,
multiple missions, fallback/emergency modes, fall-back-asleep prevention, sleep
routine, morning report, labels, volume/vibration, and repeat schedules.

Useful source references:

- Wayk App Store: mission must be completed before alarm turns off.
  https://apps.apple.com/us/app/wayk-alarm-clock-to-wake-up/id6758021281
- Wayk reviews: object-hunt alarm missions are central to stopping snooze.
  https://apps.apple.com/us/app/wayk-alarm-clock-to-wake-up/id6758021281?platform=iphone&see-all=reviews
- Alarmy App Store: math, memory, shake, squat, photo missions; sleep routine
  and morning report.
  https://apps.apple.com/us/app/alarmy-loud-alarm-clock/id1163786766
- Alarmy mission guide: emergency dismiss for location-bound missions and
  fall-back-asleep prevention.
  https://alar.my/en/blog/how-to-choose-alarmy-mission
- Alarmy AI Mission: random household object hunt verified by AI photo.
  https://alar.my/en/blog/alarmy-ai-mission-household-item-hunt

## The Product Principle

WakeSaga should not be "a motivation app with an alarm." It should be:

> A serious mission alarm that turns off only after a Wake Quest, then rewards
> the clear with a cinematic Morning Episode.

That means the real app hierarchy becomes:

1. Reliability and schedule confidence.
2. Dismissal mission clarity.
3. Failure/fallback safety.
4. Anime reward/payoff.
5. Progress, cards, cast, and personalization.

## Recommended Information Architecture

Keep the 3-tab main app, but make the alarm system much more explicit.

### 1. Today

Job: "What is the next alarm and what happens when it fires?"

Default visible modules:

- `Next Alarm` card, always above the fold.
- Large time, repeat days, enabled state, native scheduling status.
- Wake Quest row: mission, proof type, difficulty, fallback.
- Episode payoff row: title card preview, narrator, mission.
- One primary action: `Preview Alarm`, `Arm Alarm`, `Fix Alarm`, or `Edit`.
- `Lock In` remains available, but does not dominate over alarm trust at night.

Today should not require the user to infer alarm details from a tiny chip.

### 2. Alarms

This should probably become a first-class surface, either a full-screen sheet
from Today or a fourth tab if we decide multiple alarms are core.

Job: "Manage my recurring wake schedule."

Recommended v1: full-screen `Alarm Studio`, not a tab yet.

Features:

- Alarm list: Morning, Weekend, Nap/Power alarm later.
- Each alarm row shows time, days, Wake Quest, narrator, armed/failing status.
- Add/edit alarm.
- Duplicate alarm.
- Pause for tomorrow / skip next occurrence.
- Vacation/travel mode.
- Test alarm preview.
- Last fired / next fires metadata.

If multiple alarms become important, promote this into a tab. Until then, Today
should lead into Alarm Studio.

### 3. Saga

Job: "Show my proof/history/reward."

Keep additive episodes, Wake Cards, knockdowns, streak-like progress, volumes.
Do not put alarm editing here.

### 4. Cast

Job: "Customize voices/persona/pass."

Narrator, voice samples, jolt intensity, Protagonist Pass, account/settings.
Do not hide critical alarm scheduling controls here.

## Alarm Studio UX

Alarm Studio is the missing product surface. It should feel like a serious
alarm editor with WakeSaga flavor.

### Screen Structure

1. Header: `Morning Alarm`
2. Time picker: large, native-feeling wheel or stepped time control.
3. Repeat days: clear day chips.
4. Wake Quest: selected mission card with `Change`.
5. Quest difficulty: easy / normal / hard.
6. Fallback rule: after two failed verifies, switch to fallback; after three,
   end alarm and log Filler.
7. Alarm behavior:
   - Volume/ramp behavior.
   - Snooze/filler enabled state.
   - Vibration/haptics.
   - Time reminder / narrator reminder while ringing.
8. Episode payoff:
   - Title card preview.
   - Narrator.
   - Mission / arc.
9. Health check:
   - Notifications / AlarmKit / exact alarm available.
   - Sound permission / focus mode warning when relevant.
   - Battery optimization warning on Android.
10. Sticky CTA:
   - `Arm Morning Alarm`
   - `Save Changes`
   - `Fix Alarm Setup`

### Progressive Disclosure

Default editor should show only:

- Time
- Days
- Wake Quest
- Primary CTA

Advanced rows collapse under:

- `Alarm Strength`
- `Wake Quest Rules`
- `Episode Payoff`
- `Device Reliability`

This keeps the surface powerful without feeling like settings sludge.

## Wake Quest UX

Wake Quest should not be abstract. It is the thing that turns off the alarm.

### Mission Categories

V1 missions should be few but trustworthy:

- `Get Up` / Movement proof: tap/step/motion simulation now, pedometer later.
- `Object Hunt`: photograph a household object.
- `Sky Photo`: camera + light/sky heuristic.
- `Desk Ready`: photo of desk/book/laptop.
- `Shake`: fallback mission.

Later:

- QR/barcode scan.
- Math/memory.
- Squat/pushup.
- Multi-mission chain.
- Location-aware/gym/study missions.

### Mission Picker

Each mission card should answer:

- What do I physically do?
- How does WakeSaga verify it?
- How hard is it?
- What can go wrong?
- What fallback exists?

Example card:

`Object Hunt`

- "Find the object WakeSaga names."
- Proof: camera + object recognition.
- Best for: heavy snoozers.
- Fallback: Shake if verification fails twice.

## Alarm Ringing UX

The ringing screen should feel like an alarm first and an anime cut second.

Mandatory hierarchy:

1. Current time huge.
2. `RINGING` state.
3. Alarm name/time metadata.
4. One action: `Start Wake Quest` / `Turn Off Alarm`.
5. Copy directly says: `{Quest} turns this off`.
6. Honest fallback: `Filler / Snooze` with consequence.

No extra nav, tabs, cards, settings, or cast controls during alarm.

## After Wake Quest

The current path is directionally right but should be made more explicit.

Recommended sequence:

1. Wake Quest verifies.
2. The alarm sound stops immediately.
3. Green/white impact: `ALARM OFF`.
4. One beat of silence.
5. Gold payoff: `MORNING EPISODE UNLOCKED`.
6. Title Card Slam.
7. Episode player starts automatically, muted/subtitled safe.
8. User can skip from second zero.
9. Wake Card mints after episode or skip.
10. Today opens with the first action.

The key is that "alarm off" and "episode unlocked" must be two distinct beats:
relief first, reward second.

## Scheduling Functionality Checklist

To feel like a real Wayk/Alarmy-class alarm app, WakeSaga needs:

- Multiple alarm records, even if v1 only exposes Morning Alarm.
- Repeat days.
- One-time alarm option.
- Skip next alarm.
- Pause/resume.
- Duplicate alarm.
- Alarm labels.
- Per-alarm Wake Quest.
- Per-alarm fallback quest.
- Per-alarm narrator/jolt intensity.
- Test alarm / preview Dawn Rail.
- Native scheduling status, visible to user.
- Permission health check.
- Failure state with retry.
- Last fired / next fire timestamp.
- Timezone/DST handling.
- Boot reschedule on Android.
- Battery/focus/do-not-disturb warnings.
- Emergency stop/filler accounting.
- Fall-back-asleep prevention/re-check later.

## What Changes About The Hard Paywall

The hard paywall should gate the premium app, but once the user passes it, the
main app must feel fully unlocked and immediately useful. It changes the main
app UX in three ways:

1. The first post-paywall surface should be `Episode 1 Armed`, not a generic
   dashboard.
2. There should be no locked core alarm controls after paywall. Premium locks
   can remain for extra voices, custom arcs, advanced missions, extra alarms,
   and generated audio, but the primary alarm setup must be solid.
3. If purchase succeeds but alarm scheduling fails, the app must show `Fix
   Alarm Setup` immediately. A paid user who thinks the alarm is armed when it
   is not will churn instantly.

## Recommended New User Flow

1. Long onboarding builds the user's first alarm:
   - name, mission, rival, narrator,
   - Wake Quest,
   - time,
   - repeat days,
   - fallback rule.
2. Episode 1 reveal.
3. Rating gate.
4. Hard paywall.
5. Purchase CTA.
6. Permission/schedule health check if not already done.
7. `Episode 1 Armed` confirmation screen:
   - time,
   - days,
   - Wake Quest,
   - fallback,
   - Morning Episode payoff.
8. Today tab opens with the Next Alarm card.

## Build Recommendation

Do not add more anime decoration first. Build alarm-product confidence.

Implementation order:

1. Add `AlarmStudio` full-screen editor.
2. Replace the tiny alarm sheet with Alarm Studio.
3. Add `Next Alarm` card to Today above Lock In.
4. Add multiple-alarm data model or at least a list-ready `AlarmPlan` store.
5. Add `skip next`, `pause`, `duplicate`, `test alarm`.
6. Add clear permission/health status row.
7. Tighten Wake Quest picker with mission details/fallback.
8. Add post-quest `ALARM OFF -> MORNING EPISODE UNLOCKED` clarity if needed.
9. Only then add richer illustration/assets.

## UX North Star

At 10:30pm, the user should feel:

> "Tomorrow is actually set up. I know exactly what will happen."

At 6:30am, the user should feel:

> "This is ringing. I know the one thing I must do to turn it off."

After the quest, the user should feel:

> "I earned the episode. Now play it."

