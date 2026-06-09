# WakeSaga Main App Section Variants

Date: 2026-06-09

Artifacts:

- Visual board: `wakesaga-main-app-section-variants.svg`
- Slack PNG render: `tmp/main-app-section-variants/wakesaga-main-app-section-variants.svg.png`
- User loop / progressive disclosure spec: `user-loop-progressive-disclosure-spec.md`

## Goal

Create mobile main-app variants that keep the current WakeSaga design language while solving the app-section/tab-bar question.

The key rule is: tabs should be durable places, not steps in the daily alarm sequence.

## Shared Visual Language

- Warm cream paper background.
- Bold black display type.
- Coral primary action.
- Aqua and gold status accents.
- Light diagonal manga-paper texture.
- Rounded phone-native controls, but utility hierarchy first.

## Variants

1. **Next Scene Home**
   - Recommended default.
   - Sections: Home, Lock In, Receipts, Settings.
   - Home owns Tonight, Alarm, Wake Quest, Morning Episode, First Action, and End Credits as one state-aware daily loop.

2. **Episode Timeline**
   - Best for comprehension.
   - Same 4-tab model, but Home is a visible daily timeline with the active row expanded.
   - Strong teaching model, but can become dense.

3. **Alarm Card First**
   - Most instantly intuitive for heavy sleepers.
   - Home feels like a familiar alarm app first, with WakeSaga's episode layer attached.
   - Clear, but less ownable.

4. **Arc Hub + Tabs**
   - Most app-like.
   - Adds `Arc` as a durable tab for stats/goals.
   - Useful later, but risks adding navigation weight before the core loop is habitual.

## Recommendation

Use **Next Scene Home** as the first implemented shell, borrowing the compact timeline/rail idea from **Episode Timeline**.

Start with 4 tabs:

- Home
- Lock In
- Receipts
- Settings

Do not make `Tonight`, `Alarm`, `Morning`, or `Credits` tabs. They are states inside Home.

## UX Guardrail

Use `user-loop-progressive-disclosure-spec.md` as the implementation source of truth. Every section should have:

- one default job,
- one dominant CTA,
- a glance layer,
- an action layer,
- edit/detail controls in sheets,
- no history or advanced settings competing with the current user need.
