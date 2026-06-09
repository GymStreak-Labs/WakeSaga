# Wake Quest + Wayk-Inspired Mission Pass

## Naming Decision

Use **Wake Quest** as the feature name.

Why:

- It is more on-brand than `Wake Gate`.
- It keeps the anime/training-arc identity.
- It still implies a required action before the Morning Episode unlocks.
- It can contain multiple mission types without sounding like a generic alarm setting.

## Wayk-Inspired Mechanics To Borrow

From the local Wayk sequence recreation spec:

- Wayk asks the user to `Choose your wake up mission`.
- The mission exists to turn off the alarm.
- Mission examples include `Object Hunt`, `Push Ups`, `Math Problem`, `Sky Photo`, `Make Your Bed`, `Affirmation`, and `Bible Verse`.
- Wayk follows mission choice with an explanation screen, e.g. why finding a random object wakes the user up.
- Wayk asks whether the alarm keeps ringing during the mission.
- Wayk later shows the selected mission in the morning plan.

## WakeSaga Translation

WakeSaga should not copy Wayk's plain utility tone. It should translate the mechanic into anime/product language:

`Alarm rings → Complete Wake Quest → Morning Episode unlocks → First move starts`

## Recommended Quest List

Use short labels that look good in iPhone UI:

- Object Hunt
- Sky Photo
- Make Bed
- Pushups
- Water Check
- Desk Photo
- Shoes On
- Spoken Vow

## Onboarding Screens Affected

1. `Rival detected` should say the user needs a `Wake Quest`, not a gate.
2. `Saga Loop` should show `Alarm → Wake Quest → Morning Episode`.
3. `Choose Wake Quest` should present concrete mission cards inspired by Wayk.
4. `Why this quest works` should explain the selected mission.
5. `Opening Scene Ready` should summarize the selected Wake Quest.
6. Paywall/premium later can say premium unlocks advanced Wake Quests and AI-generated mission variants.
