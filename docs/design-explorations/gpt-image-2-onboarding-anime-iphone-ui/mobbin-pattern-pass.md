# WakeSaga Mobbin-Informed Onboarding Pattern Pass

## Status

The live Codex Mobbin MCP handshake failed during this pass with an OAuth refresh error. Two non-printing reauth attempts were made, but initialization still failed. This document uses the Mobbin screen references already pulled earlier in this WakeSaga thread as the evidence base and records the patterns that should shape the next concept/Flutter pass.

## Reference Set

| Pattern Cluster | Mobbin References | What It Contributes |
| --- | --- | --- |
| Social prompt-card onboarding | [BFF prompt-card flow](https://mobbin.com/screens/bc259132-ab0a-4733-a2f3-754b7212a495), [BFF yellow card style](https://mobbin.com/screens/12c21fc3-d184-48c0-84f3-ed7b2868f8c3), [NGL prompt flow](https://mobbin.com/screens/8b0403e9-41a2-485f-87ef-e9b4af6fe6a7) | Big casual questions, fast answer cards, friend/social energy without dense setup forms. |
| Identity/profile setup | [Instagram identity setup](https://mobbin.com/screens/8ed9f25c-1031-487a-9cf7-b3b77f6f4aac), [Yubo setup](https://mobbin.com/screens/cd3c7303-c0bf-4a3a-aec1-cc812e8efd34), [Locket onboarding](https://mobbin.com/screens/26d9c6fd-a5ed-4d0c-8069-e457f7c74ca2) | Establish a user/persona object early before configuration gets technical. |
| Goal/streak onboarding | [Duolingo quest setup](https://mobbin.com/screens/88ba156b-e484-4d98-b17b-7123a1d7c6cb), [Duolingo goal choices](https://mobbin.com/screens/1a2c3854-ea7a-41fa-ab1b-95466c2c0228), [Duolingo outcome preview](https://mobbin.com/screens/0eed678c-da44-4e3a-ba32-c02660e92866), [Finch streak/calendar](https://mobbin.com/screens/a9313448-4abd-422c-a068-f22b15d8d62f) | Show progress, make commitment concrete, preview the future reward. |
| Habit/behavior education | [Fabulous onboarding](https://mobbin.com/screens/55682dbc-5768-4131-9fa8-2698f4053745), [Habitify](https://mobbin.com/screens/669cf614-7eba-44ce-b06e-114b51e66c3), [Not Boring Habits](https://mobbin.com/screens/0f12f186-08d0-4e6d-bd1b-b044673d6e2f) | Alternate questions with education and rewards instead of stacking quiz screens. |
| Plan/result reveal | [Future coach/result](https://mobbin.com/screens/b14b3502-3399-475f-9f08-8d94662a6f0a), [Fitbod plan setup](https://mobbin.com/screens/64e855b8-2f61-4d02-9195-fc0ecd184235), [Zero onboarding](https://mobbin.com/screens/b6b92f01-d64c-4c87-b2c5-9bab649b7801) | Make the user feel a personalized plan is being assembled before asking for account/payment. |
| Sleep/emotional framing | [Loona](https://mobbin.com/screens/92fb4d65-5919-4562-bf48-2535088c115c), [Headspace](https://mobbin.com/screens/51407ae6-38dd-43a2-aece-70e2f7fac6bc), [How We Feel](https://mobbin.com/screens/ab369354-d120-45a7-8038-c580b083d4cf) | Use gentle emotional cards and illustrated state changes without making the interface heavy. |

## Common Patterns To Apply

### 1. Question, Then Payoff

Do not ask 12 questions in a row. Every 2-3 answers should update a visible artifact:

- `Rival detected`
- `Wake Quest selected`
- `Narrator synced`
- `Tomorrow's opening scene is forming`
- `Episode 001 ready`

### 2. Progress Should Mean Something

The progress indicator should not be a generic bar. Use stage labels:

1. Enemy
2. Arc
3. Quest
4. Voice
5. Plan

This gives the long onboarding permission to exist because the user can see the plan becoming real.

### 3. Start With Identity, Not Permissions

The first concrete object should be the user's morning persona/opening scene, not notification permission, account, age, or name.

Preferred order:

1. Promise
2. Morning enemy
3. Persona/arc
4. Wake Quest
5. Alarm time
6. Permission primer
7. Native permission
8. Plan reveal

### 4. Use One Decision Per Screen

Mobbin-style onboarding screens usually feel clean because each screen has a single job. For WakeSaga:

- one screen for morning enemy,
- one screen for arc,
- one screen for Wake Quest,
- one screen for narrator,
- one screen for alarm time,
- one screen for commitment.

Long-form is fine; dense-form is not.

### 5. Keep Permission Requests Just-In-Time

Do not ask for notifications/alarm access early. Ask after the user has chosen a wake time/Wake Quest and seen the line:

`So your opening scene can actually fire at 6:45 AM.`

Then show the native permission prompt.

### 6. Result Before Account/Paywall

Show `Your Opening Scene` before asking for account or subscription. The user should see:

- alarm time,
- Wake Quest,
- narrator,
- mission,
- what unlocks after the quest,
- first Wake Card preview.

Then use account/paywall copy like `Save Episode 001` or `Unlock full AI voice`.

### 7. Make The Anime Layer A System, Not Decoration

Anime should map to product state:

- Rival = user's obstacle.
- Mentor/Narrator = AI voice style.
- Wake Quest = the first physical/proof mission that stops the alarm and proves the user is up.
- Episode Card = shareable daily artifact.
- Arc = user's goal mode.

Avoid random manga stickers that do not update the plan.

## Improved Onboarding Structure

| Step | Screen | Pattern Borrowed | WakeSaga Job |
| --- | --- | --- | --- |
| 1 | Cold Open | Emotional illustrated promise | Sell `Tomorrow becomes Episode 001`. |
| 2 | Quick Commit CTA | Social app fast start | `Build my opening scene`. |
| 3 | Morning Enemy | BFF/NGL prompt cards | Diagnose the obstacle. |
| 4 | Plan Update 1 | Plan-building feedback | Show `Rival detected`. |
| 5 | Old Loop / Saga Loop | Habit education interstitial | Teach why the Wake Quest exists. |
| 6 | Choose Arc | Duolingo/Fitbod goal setup | Pick Study/Gym/Deep Work/etc. |
| 7 | Plan Update 2 | Outcome preview | Show `Arc selected`. |
| 8 | Choose Wake Quest | Wayk behavior + Mobbin cards | Pick the physical/proof mission. |
| 9 | Why This Quest Works | Fabulous education beat | Explain body-before-brain in one sentence. |
| 10 | Set Wake Time | Native utility setup | Capture real alarm time. |
| 11 | Set Days | Native utility setup | Capture schedule. |
| 12 | Choose Narrator | Identity/coach setup | Pick Mentor/Rival/Future Me/Hype Friend. |
| 13 | Preview Wake Jolt | Audio/product proof | Let user hear or visualize the AI audio. |
| 14 | Permission Primer | Just-in-time permission | Explain why notifications/alarm access matters. |
| 15 | Native Permission | Platform prompt | Request permission after intent exists. |
| 16 | Commitment | Challenge/streak pattern | Sign tomorrow's opening scene. |
| 17 | Rendering Episode 001 | Plan-building loader | Show generated pieces assembling. |
| 18 | Plan Reveal | Future/Fitbod result reveal | Show complete morning plan. |
| 19 | Wake Card Preview | Not Boring/Finch collectible | Show first shareable artifact. |
| 20 | Save Saga | Account after value | Ask for account after plan reveal. |
| 21 | Paywall Intro | Subscription after value | Premium = AI voices, generated jolts, custom arcs, unlimited cards. |

## Next Concept Sheet Should Show

The next six anchor screens should change from generic anchors to Mobbin-pattern anchors:

1. `Cold Open` - promise and CTA.
2. `Morning Enemy` - one question, four cards.
3. `Rival Detected` - first plan-building payoff.
4. `Saga Loop` - three-step education.
5. `Wake Quest` - Wayk-inspired mission setup.
6. `Opening Scene Ready` - result reveal before account/paywall.

This is more useful than showing every field because it proves the cadence: question, payoff, education, configuration, reveal.

## Wake Quest Naming Update

Use **Wake Quest** as the top-level mechanic name. It is stronger than `Wake Gate` because it keeps the anime/adventure identity while still describing the Wayk-inspired requirement: the alarm is not truly done until the user completes a small real-world mission.

Quest options should be concrete, proof-like, and physical:

- `Object Hunt` - find a random everyday object.
- `Sky Photo` - take a photo facing daylight/outside.
- `Make Bed` - prove the sleep space changed.
- `Pushups` - quick movement mission.
- `Water Check` - drink/scan a water bottle or glass.
- `Desk Photo` - prove study/work setup.
- `Shoes On` - prove gym/outside readiness.
- `Spoken Vow` - short voice commitment.

Use `Wake Mission` as the sublabel for individual quest cards, for example: `Wake Quest: Object Hunt`.
