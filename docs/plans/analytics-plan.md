# WakeSaga Analytics Plan

WakeSaga analytics should answer three questions without logging sensitive user content:

1. Are users making it from onboarding to a scheduled alarm?
2. Are users clearing the morning loop: alarm, quest, episode, card?
3. Are generated-audio costs staying inside expected limits by cohort?

## Setup

- Firebase project: `wakesaga-prod`
- iOS bundle: `com.gymstreaklabs.wakesaga`
- Android package: `com.gymstreaklabs.wakesaga`
- SDK: Firebase Analytics via `firebase_analytics`
- Navigation tracking: `FirebaseAnalyticsObserver` in production app boot

## Privacy Rules

- Do not log raw mission text, generated episode scripts, wake-up phrases, diary/reflection text, or audio URLs.
- Do not log names, emails, phone numbers, exact wake times, or free-form user input.
- Prefer bounded enums, counts, durations, and coarse buckets.
- Keep user properties small and non-identifying.

## Core Funnels

### Onboarding Funnel

| Event | Key Parameters |
| --- | --- |
| `onboarding_started` | `entry_point` |
| `onboarding_step_viewed` | `step_id`, `step_index` |
| `onboarding_choice_saved` | `choice_type`, `choice_bucket` |
| `review_gate_viewed` | `source` |
| `paywall_viewed` | `placement`, `offer_id` |
| `onboarding_completed` | `duration_bucket`, `alarm_enabled` |

### Morning Loop Funnel

| Event | Key Parameters |
| --- | --- |
| `alarm_scheduled` | `quest_type`, `wake_window_bucket` |
| `wake_alarm_started` | `launch_source`, `episode_ready` |
| `wake_quest_started` | `quest_type`, `target_count` |
| `wake_quest_cleared` | `quest_type`, `attempt_count`, `duration_bucket` |
| `wake_quest_abandoned` | `quest_type`, `progress_bucket` |
| `morning_episode_started` | `episode_number`, `arc_type`, `music_bed_id` |
| `morning_episode_completed` | `episode_number`, `duration_bucket`, `music_bed_id` |
| `wake_card_minted` | `episode_number`, `card_rarity`, `arc_type` |

### Audio And Cost Funnel

| Event | Key Parameters |
| --- | --- |
| `audio_package_requested` | `package_type`, `episode_number` |
| `audio_package_generated` | `package_type`, `tts_seconds_bucket`, `cache_hit` |
| `audio_package_failed` | `package_type`, `failure_type`, `retry_count` |
| `music_bed_selected` | `music_bed_id`, `arc_type`, `intensity` |
| `lock_in_started` | `lock_in_type`, `source` |
| `lock_in_completed` | `lock_in_type`, `duration_bucket` |

Cost dashboards should group by `package_type`, daily active users, generated voice seconds, retry count, and lock-ins per user per day. Bundled music selection should not create provider cost and should be tracked as a local experience metric only.

## User Properties

Use bounded values only:

- `subscription_status`: `free`, `trial`, `paid`, `expired`
- `primary_arc_type`: `study`, `fitness`, `work`, `recovery`, `general`
- `quest_type`: `tap`, `hold`, `scan`, `movement`
- `narrator_type`: `mentor`, `rival`, `calm`, `drill`
- `music_preference`: `cinematic`, `minimal`, `high_energy`, `soft`

## First Implementation Pass

1. Firebase Analytics SDK and app config in both mobile apps.
2. Automatic app/session/screen analytics via Firebase.
3. Explicit events around onboarding, alarm scheduling, quest completion, episode playback, card minting, paywall view, and audio generation.
4. A tiny analytics wrapper service so UI code calls typed methods instead of raw event strings.
5. DebugView validation on a Firebase tester build before relying on dashboards.

## Dashboard Views

- Activation: install -> onboarding completed -> alarm scheduled.
- Morning habit: alarm started -> quest cleared -> episode completed -> card minted.
- Retention: day 1, day 2, day 7 morning-loop completion.
- Monetization: paywall views, trial starts, purchases, offer selected.
- Cost guardrails: generated voice packages per subscriber, failures/retries, lock-ins per subscriber, cache hit rate.
