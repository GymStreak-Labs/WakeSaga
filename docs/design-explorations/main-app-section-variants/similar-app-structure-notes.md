# Similar App Structure Notes

Date: 2026-06-09

## Sources Checked

- Wayk App Store: https://apps.apple.com/us/app/wayk-alarm-clock-to-wake-up/id6758021281
- Wayk site: https://wayk.io/
- Alarmy App Store: https://apps.apple.com/us/app/alarmy-loud-alarm-clock/id1163786766
- Sleep Cycle App Store: https://apps.apple.com/us/app/sleep-cycle-tracker-sounds/id320606217
- Fabulous App Store: https://apps.apple.com/us/app/fabulous-daily-habit-tracker/id1203637303
- Finch App Store: https://apps.apple.com/us/app/finch-self-care-pet/id1528595748
- Existing local Mobbin-informed notes: `docs/design-explorations/gpt-image-2-onboarding-anime-iphone-ui/mobbin-pattern-pass.md`

## Category Pattern

Similar apps structure around durable jobs, not chronological steps.

| Category | Examples | Common Structure | Lesson For WakeSaga |
| --- | --- | --- | --- |
| Mission alarm | Wayk, Alarmy | Home/alarm object, mission setup, alarm sound/settings, history/stats | Alarm and mission live together. Mission is nested under the alarm, not a separate tab. |
| Sleep tracker / smart alarm | Sleep Cycle | Current sleep/alarm session, trends/insights, sounds/content, profile/settings | Home is the current/next session. History is separate. |
| Habit/routine coach | Fabulous | Today routine, journeys/programs, challenges/community/content, progress/profile | The daily plan is Home; long-term program/progress is separate. |
| Companion self-care | Finch | Today/self-care actions, pet/identity, quests/content, history/rewards/profile | Emotional wrapper sits on top of daily actions, but users still land on today's tasks. |

## Main Pattern

Tabs are usually:

- current day/session/alarm
- content or tools
- history/progress/rewards
- profile/settings

Tabs are rarely:

- step 1
- step 2
- step 3
- step 4

## WakeSaga Recommendation

Use 4 tabs for v1:

1. **Home**
   - Current daily loop state.
   - Contains Tonight Setup, Alarm Armed, Wake Quest, Morning Episode, First Action, and End Credits.
   - One dominant CTA based on the user's current state.

2. **Lock In**
   - On-demand motivational clips for study, gym, work, or recovery.
   - Separate because it can be used outside the alarm/morning flow.

3. **Receipts**
   - Saved episode cards, wake history, streaks, proof, shares.
   - This is the reward/history section.

4. **Settings**
   - Alarm defaults, mission defaults, wake sound, narrator, schedule, account, subscription.

## Optional Later Tabs

- **Arc**
  - Add only if long-term stats, goals, ranks, and identity progression become deep enough.
  - Do not add in v1 unless it has real daily value.

- **Explore / Voices**
  - Add only if there is a real content library: narrator packs, episode styles, missions, sounds.

## Avoid As Tabs

- Tonight
- Alarm
- Morning
- End Credits
- Sound
- Mission
- Paywall

Those are either states inside Home or settings/details.

## Practical Rule

If the user would say "I am in this part of the app," it can be a tab.

If the user would say "I am at this point in today's sequence," it belongs inside Home.
