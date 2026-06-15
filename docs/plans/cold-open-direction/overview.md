# WakeSaga: Cold Open — Final Design Direction

> Source: ground-up multi-agent design workflow (2026-06-10). 5 blind designer concepts
> (behavior-science, anime-native, dead-simple-utility, social-viral, apple-craft), each judged
> by 3 critical judges (first-use intuitiveness, day-30 love, ownability), then synthesized.
> Full machine-readable spec: `final-spec.json`. All concepts + verdicts: `workflow-full-results.json`.

## Pitch

An alarm clock that runs your life as a shonen anime: the alarm is the cold open, standing up
mints the episode, and missing a morning is a canon chapter — never a dead streak.

## Scores

| Lens | Avg (3 judges) | Concept name |
|---|---|---|
| behavior-science | 7.3 | WakeSaga — Cold Open (winner: spine) |
| dead-simple-utility | 7.3 | The Clock App With a Soul |
| apple-craft | 7.3 | Cold Open |
| anime-native | 7.2 | Cold Open |
| social-viral | 6.7 | Episode One (mostly killed) |

Notable: 4 of 5 blind designers independently converged on the "Cold Open / every morning is an
episode" framing.

## Core loop (condensed)

- **Night (optional, 30s, never required)**: alarm always armed by default. One optional prompt
  ("Tomorrow's mission?"), then the TO BE CONTINUED stinger + generated Cliffhanger Teaser.
  Episode audio generates server-side overnight — mornings need zero network.
- **Alarm**: Dawn Rail takeover. 8s personalized Cold Open in the narrator's voice with the user's
  real name/history, then tone escalates. One crimson BEGIN QUEST slab; visible labeled
  "FILLER (snooze 9 min)"; week-1 sick-day escape.
- **Quest (30–90s)**: one 64pt instruction, sensor IS the screen. Failure ladder: 2 fails →
  fallback quest, 3 fails → alarm ends, Filler logged. The alarm never traps.
- **Payoff (90s, skippable from second zero)**: TITLE CARD SLAM ("EPISODE 48: THE ESSAY DEMON"),
  Morning Episode with anime subtitles + Short Mode, Wake Card mint (screentone manga panel,
  truth-based foils), one-tap 9:16 share. Then: "Go. The episode is live."
- **Day**: pull-only, zero daytime pushes. One giant LOCK IN → 4 chips → 25s hype clip.
- **Failure**: a miss is a KNOCKDOWN — red-ink canon chapter + Comeback Quest. Episode count is
  additive and unbreakable; dead arcs archive as finished volumes, never reset to zero.

## Information architecture

Two modes for two brains:
1. **Dawn Rail** (80% of usage): Alarm → Quest → Title Card → Episode → Card. Forced linear modal
   pipeline, zero nav chrome.
2. **The App** — exactly 3 tabs:
   - **TODAY**: time-aware state machine (Morning / Day / Night / Post-Miss) with two persistent
     anchors that survive every state: alarm time + toggle (top-center) and LOCK IN.
   - **SAGA**: episode count, arc volume spines, card binder, knockdown chapters in red ink.
   - **PROFILE**: protagonist identity, active narrator, pre-quest Wake Jolt Style, rival intensity, morning
     defaults, and account/subscription controls. Because onboarding is hard-paywalled, narrator
     selection belongs here as a simple selector rather than as a separate locked shop.

## Design language: INK-AND-SIGNAL (dark-first)

- Base `#0B0E14` ink navy, surfaces `#161B26`, warm paper-white text `#F2EFE6`.
- One signal color per job: Shonen Crimson `#FF2E4C` (single primary action), Ember Gold `#FFC93C`
  (rarity/foils ONLY), knockdown red-ink `#B3122E`, verify green `#3DDC84`.
- Rule: **one accent element per screen, ever**.
- Type: ultra-condensed heavy display (Anton-class, ALL-CAPS, −6° skew) for episode numbers/title
  cards only; Inter for UI, 17pt min, 56pt buttons pre-9am.
- Shape: manga not bubbly — 4px radii + 2px ink borders on panels, native 20pt corners on chrome,
  12° slash dividers, 8–10% halftone screentone on imagery only.
- Motion: hard cuts never crossfades; two signature transitions only (SMASH CUT, CARD MINT).
- Narrators: high-craft flat-cel 2D portraits with 2-frame idle loops. No chibi mascots, no confetti.
- Copy: "taunt or salute, never nag"; rival never taunts during recovery; intensity setting.

## Signature moments

1. Title Card Slam (daily screenshot moment, 3s 9:16 export)
2. Cold Open With Receipts (alarm calls you out by name with yesterday's behavior)
3. Cliffhanger Teaser + TO BE CONTINUED (go to sleep mid-story)
4. Knockdown Chapter (failure becomes canon content, never a zero)
5. First Light Foils (truth-based rarity — users race their own alarm)
6. The Ember (Live Activity / StandBy countdown: "EP 48 airs in 7h 14m")

## What we explicitly killed

- Hidden hold-to-surrender escapes (panic moment / 1-star generator) → visible labeled escapes
- Unskippable episode audio → SKIP from second zero + Short Mode
- Verification dead-ends → failure ladder; the alarm never traps
- Breakable streaks as headline number → additive episode count
- Mandatory nightly arming/homework → alarm always armed; night ritual optional
- Social party layer / public failure shame → rival is a character, sharing flows outward only
- Day-1 jargon ("Cour Pass", "Vault", unlabeled buttons) → plain labels in week 1
- 5-tab dashboard IA (our prior attempts) → 3 tabs, 2 modes, 1 gold action per screen
- Timer/slashed-price paywall gimmicks → personalized voice samples ARE the pitch

## Build order

1. Alarm engine + Dawn Rail skeleton (trust floor)
2. Wake Quest verification + failure ladder (3 quests, not 8)
3. Title Card Slam + Wake Card mint (share engine; works before audio exists)
4. Morning Episode pipeline (overnight Gemini/Flash TTS + behavior-log memory + anti-sameness)
5. Today state machine + Alarm Sheet
6. Saga shelf
7. Lock In (smallest feature — do not let it grow)
8. Profile + account/subscription controls (RevenueCat; preserve the hard onboarding paywall)
9. Ambient surfaces (Live Activity, StandBy, widget)
10. Haptic/sound score + knockdown economy tuning → TestFlight with 16–26 anime-native cohort
