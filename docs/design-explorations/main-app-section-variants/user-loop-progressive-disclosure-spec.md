# WakeSaga Main App User Loop + Progressive Disclosure Spec

Date: 2026-06-09

## Design Thesis

WakeSaga should feel like a morning companion that always knows the next scene.

The main app must not start from features. It starts from user state:

- What time of day is it?
- Has tomorrow's alarm been prepared?
- Is the user currently waking up?
- Has the Wake Quest been cleared?
- Has the Morning Episode been played?
- Has the first action been completed?
- Is the user trying to lock in later in the day?
- Is the user reflecting at night?

The interface should reveal only what is useful for that moment.

## Core Rule

One screen, one dominant job.

- One primary CTA.
- Up to two secondary actions.
- Details and editing live in sheets.
- History, settings, and advanced controls never compete with the current action.

## User Loop

### 1. Before Bed: Prepare Tomorrow

User need:

- Know the alarm is ready.
- Know what they will do when it rings.
- Feel tomorrow has a motivating shape.
- Change mission/quest/sound only if needed.

Default Home state:

- Large next alarm time.
- Mission: `Deep Work`
- Wake Quest: `Object Hunt`
- Status: `Wake jolt cached` or `Needs generation`
- Primary CTA: `Lock Tomorrow's Opening`
- Compact rail: `Wake Jolt -> Wake Quest -> Episode -> First Action -> Receipt`

Progressive disclosure:

- Tap mission card -> bottom sheet with mission picker.
- Tap Wake Quest chip -> bottom sheet with quest picker and explanation.
- Tap sound/narrator -> detail sheet.
- Tap schedule -> settings sheet.
- Generated script preview is collapsed by default; it opens only from `Preview Episode`.

Avoid:

- Showing the full script by default.
- Showing all mission options on Home.
- Showing receipts/history before tomorrow is locked.

### 2. Alarm Moment: Get Out Of Bed

User need:

- Understand the exact required action.
- Stop negotiating.
- Complete the Wake Quest.
- Avoid accidental app wandering.

Default Home state:

- Huge current time.
- Alarm status: `Wake Jolt Playing`
- One instruction card: `Find a random object in your room.`
- Primary CTA: `Clear Object Hunt`
- Small secondary: `Emergency snooze` or `Need help`, if product policy allows it.

Progressive disclosure:

- Mission instructions expand only if tapped.
- Sound controls are limited to volume/mute policy.
- Settings are inaccessible or de-emphasized during active alarm except emergency controls.

Avoid:

- Bottom-tab distraction during active alarm if it interferes with the wake task.
- Script, cards, stats, or Lock In promos while the alarm is active.

### 3. Immediately After Quest: Reward + Next Step

User need:

- Feel success.
- Know the episode is unlocked.
- Start the Morning Episode quickly.

Default Home state:

- Success banner: `Quest cleared`
- Small proof line: `Object Hunt completed at 6:33`
- Primary CTA: `Play Morning Episode`
- Secondary: `Skip to First Action`
- Compact preview of first action.

Progressive disclosure:

- Quest proof details open in the receipt sheet.
- Episode script remains collapsed until playback starts.

Avoid:

- Dumping a full stats dashboard.
- Asking for reflection this early.

### 4. Morning Episode: Listen And Move

User need:

- Hear the motivational setup.
- Know the first action.
- Move into the first 10 minutes.

Default Home state:

- Episode player.
- Short current line or chapter title.
- Progress bar.
- First action preview.
- Primary CTA changes by state:
  - `Play Morning Episode`
  - `Continue Episode`
  - `Start First Action`

Progressive disclosure:

- Full transcript opens in a sheet.
- Voice/narrator edits are not shown in the player state.
- Episode details are saved to receipt after completion.

Avoid:

- Multiple players.
- Script block taking over the whole screen by default.
- Making the user choose from all possible actions after the episode; the chosen action should be preselected.

### 5. First Action: Convert Motivation Into Motion

User need:

- Do one tiny start action.
- Save proof/receipt.
- Leave the app.

Default Home state:

- First action card.
- Micro-instruction: `Open laptop and write the first line.`
- Primary CTA: `Mark First Action Done`
- Secondary: `Swap Action`

Progressive disclosure:

- Action swap opens a small picker.
- Receipt preview opens after completion.
- Sharing is secondary after receipt is saved.

Avoid:

- Showing Lock In options here unless the user explicitly asks.
- Making receipt customization mandatory.

### 6. Midday / Hard Task: Lock In

User need:

- Generate a short clip for the thing they are avoiding.
- Do it quickly without configuring a full saga.

Lock In default:

- Prompt field: `What are you avoiding?`
- Three templates: `Study`, `Gym`, `Work`
- Length control: `30s`, `90s`, `3min`
- Primary CTA: `Generate Lock In`
- Latest clip card.

Progressive disclosure:

- Advanced drawer: voice, intensity, goal, saved prompts.
- Context library hidden behind `More modes`.
- Past clips are below the fold.

Avoid:

- Full mission picker grid on first view.
- Showing all voice/persona controls by default.
- Making Lock In look as important as the morning alarm on Home.

### 7. Night Reflection: End Credits

User need:

- Close the day without shame.
- Capture one reflection.
- Set up tomorrow.

Default Home state:

- `End Credits` card appears at night or after first action.
- One reflection prompt: `What did today prove?`
- Mood slider or 3-option chips.
- Primary CTA: `Prep Tomorrow`

Progressive disclosure:

- Full reflection history is in Receipts.
- Missed-day recovery opens a `Rematch Tomorrow` sheet.
- Tomorrow setup inherits today's choices by default.

Avoid:

- Long journaling form.
- Too many stats at bedtime.
- Language that makes missed days feel like failure.

## Sections

### Home

Job:

- Tell the user exactly what happens next in the daily loop.

Default visible hierarchy:

1. Current/next state title.
2. Alarm/mission hero.
3. One primary CTA.
4. Compact protocol rail.
5. Two secondary controls.

Hidden by default:

- Full script.
- Full mission picker.
- Wake Quest library.
- Historical receipts.
- Advanced settings.

Home states:

- `tomorrowSetup`
- `openingLocked`
- `alarmActive`
- `questCleared`
- `episodePlaying`
- `firstAction`
- `dayComplete`
- `endCredits`

Component rules:

- The hero card always answers `when`, `what`, and `what next`.
- The protocol rail is context, not navigation.
- Secondary actions use sheets, not new tabs.

### Lock In

Job:

- Create a motivational clip for a hard task outside the morning loop.

Default visible hierarchy:

1. Prompt input or selected task.
2. Mode chips: Study, Gym, Work, Recovery.
3. Length segmented control.
4. Primary CTA.
5. Latest/generated clip.

Hidden by default:

- Voice intensity.
- Saved prompt library.
- All mission categories.
- Clip history.

Progressive disclosure:

- `Customize` opens advanced voice/intensity drawer.
- `Saved` opens reusable prompts.
- `History` opens past clips.

### Receipts

Job:

- Prove progress and make the morning feel collectible.

Default visible hierarchy:

1. Latest receipt.
2. Current streak / wake consistency.
3. Recent cards.
4. Share/export action.

Hidden by default:

- Filters.
- Detailed charts.
- Full transcript.
- Reflection history.

Progressive disclosure:

- Tap a receipt -> detail view with quest proof, episode quote, first action, reflection.
- Tap streak -> simple trend view.
- Tap share -> share card editor.

Avoid:

- Dense analytics dashboard in v1.
- Fake stats before data exists.

### Settings

Job:

- Configure defaults without distracting from the daily loop.

Default visible hierarchy:

1. Next alarm schedule.
2. Wake Quest default.
3. Sound/narrator.
4. Account/subscription.

Hidden by default:

- Advanced alarm behavior.
- Permission diagnostics.
- Notification cadence.
- Data/export/legal.

Progressive disclosure:

- Group settings into cards:
  - `Alarm`
  - `Wake Quest`
  - `Voice`
  - `Account`
  - `Support`
- Each card opens a focused detail page.

Avoid:

- Making Settings a long ungrouped list.
- Putting urgent alarm status only in Settings.

## Tab Bar Recommendation

Use four tabs:

- Home
- Lock In
- Receipts
- Settings

Do not use tabs for:

- Tonight
- Alarm
- Morning
- Credits
- Mission
- Sound

Those are states, sheets, or settings.

## Progressive Disclosure Levels

### Level 0: Glance

What the user should understand in under 2 seconds.

- Next alarm or current state.
- Mission / Wake Quest.
- Primary CTA.

### Level 1: Act

The minimum controls needed to complete the current job.

- Lock opening.
- Clear quest.
- Play episode.
- Start first action.
- Generate Lock In.
- Save receipt.

### Level 2: Adjust

Controls the user may need occasionally.

- Edit mission.
- Change quest.
- Change sound.
- Change narrator.
- Swap first action.

### Level 3: Review

Lower-frequency details.

- Receipts.
- Streaks.
- Transcript.
- Reflections.
- Clip history.

### Level 4: Configure

Rare or careful settings.

- Permissions.
- Subscription.
- Advanced alarm behavior.
- Account.

## Anti-Clutter Rules

- No screen has more than one coral primary button.
- No Home state shows more than two secondary buttons above the fold.
- No default Home screen shows more than one long text block.
- Do not show a grid when a single selected object plus `Change` works.
- Do not show history until the current action is complete.
- Do not show settings during an urgent wake state unless it is an emergency control.
- Do not use the protocol rail as a second tab bar.
- Avoid fake stats. Empty states should be honest and useful.

## Implementation Acceptance Criteria

- First post-onboarding screen answers: `What happens next?`
- User can lock tomorrow's opening without opening another tab.
- User can complete the Wake Quest without seeing unrelated app sections.
- After quest completion, the dominant CTA becomes `Play Morning Episode`.
- After episode completion, the dominant CTA becomes the selected first action.
- Lock In is reachable from the tab bar but never competes with the morning action on Home.
- Receipts are rewarding but not required to complete the daily loop.
- Settings are complete enough to configure the app, but grouped behind focused cards.
