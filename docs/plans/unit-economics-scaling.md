# WakeSaga Unit Economics and Scaling

Last updated: 2026-06-16

This model is for product architecture decisions, not accounting. Provider
prices change, so refresh the source pricing before launch or large spend.

## Pricing Inputs Used

- Gemini 2.5 Flash text generation: $0.30 / 1M input tokens and $2.50 /
  1M output tokens on Google Cloud Agent Platform pricing.
- Gemini 2.5 Flash TTS: $0.50 / 1M text input tokens and $10 / 1M audio
  output tokens. Google says audio tokens correspond to 25 tokens per second.
- Gemini 3.1 Flash TTS / Gemini 2.5 Pro TTS: $20 / 1M audio output tokens.
- Lyria 3: $0.04 per 30 second music clip. Lyria 3 Pro: $0.08 per full
  song up to 3 minutes. Lyria 2: $0.06 per 30 seconds.
- Cloud Storage Standard in common US single-region examples is roughly
  $0.020 / GB-month, with example outbound network at $0.12 / GB.

Sources:

- https://cloud.google.com/text-to-speech/pricing
- https://cloud.google.com/vertex-ai/generative-ai/pricing
- https://cloud.google.com/storage/pricing
- https://cloud.google.com/storage/pricing-examples

## Product Assumptions

One premium morning package:

- 10 second forceful Wake Jolt.
- 75 second Morning Episode voiceover.
- Optional 30 second cinematic music bed looped on device.
- App plays voice and music as separate local tracks with ducking/fades.
- Audio is generated before the alarm window, downloaded, and cached locally.

The alarm moment must never require network. If generation fails, the app uses
bundled fallback jolt/music and a local script.

## Per-Episode AI COGS

Approximate costs:

| Package | Cost per generated morning | Monthly cost for daily active user |
| --- | ---: | ---: |
| Voice only, Gemini 2.5 Flash TTS | ~$0.022 | ~$0.65 |
| Voice + fresh Lyria 3 30s bed daily | ~$0.062 | ~$1.85 |
| Voice + fresh Lyria 3 Pro song daily | ~$0.102 | ~$3.05 |

Script generation with Gemini Flash is effectively tiny compared with audio,
assuming short prompts and 60-120 second scripts. Storage and egress are also
small versus TTS/music if packages are downloaded once and retained with a
short TTL.

## Subscriber Scale Scenarios

Assume 60% of subscribers generate a Morning Episode on a given day.

| Subscribers | Daily voice + daily Lyria | Daily voice + weekly Lyria | Daily voice + library music |
| ---: | ---: | ---: | ---: |
| 10,000 | ~$11,100/mo | ~$5,500/mo | ~$3,900/mo |
| 100,000 | ~$111,000/mo | ~$55,000/mo | ~$39,000/mo |

The dangerous version is fresh AI music every day for every user. The safer
version is daily generated voice with music reused by arc/week, or a curated
music-bed library.

## Revenue Benchmarks

Conservative net revenue after a 30% store cut:

| Product | Net ARPU |
| --- | ---: |
| $29.99/year special | ~$1.75/user/month |
| $59.99/year annual | ~$3.50/user/month |
| $6.99/week | ~$21.20/user/month |

Implication:

- $29.99/year can support daily voice, but not unlimited daily fresh AI music
  with much margin.
- $59.99/year can support a richer daily package if music is controlled.
- Weekly pricing has plenty of AI margin, but churn and conversion must carry
  the business.

## Recommended Cost Architecture

### 1. Separate Generation From Playback

Backend produces an `EpisodeAudioPackage`:

```json
{
  "scriptId": "...",
  "wakeJoltUrl": "...",
  "episodeVoiceUrl": "...",
  "musicBedUrl": "...",
  "durationSeconds": 75,
  "modelCosts": {
    "scriptUsd": 0.001,
    "ttsUsd": 0.022,
    "musicUsd": 0.04
  },
  "expiresAt": "..."
}
```

The app downloads the assets before the wake window and plays them locally.
No provider keys ship in the app.

### 2. Use Client-Side Layered Playback For V1

Do not server-mix every episode by default. Generate/cache voice and music as
separate assets:

```text
episodeVoice.mp3 + musicBed.mp3
```

The app starts both after Wake Quest clears, ducks the music under voice, and
fades the bed at the end. Server-side mixes are optional later for sharing or
exports.

### 3. Reuse Music Aggressively

Cost-safe tiers:

- Daily generated voice.
- Weekly/arc-level generated music bed.
- Curated bundled music library for most days.
- Fresh Lyria music only for premium moments: first day, milestone, comeback,
  new arc, or user-triggered regeneration.

### 4. Meter Expensive Actions

Backend should enforce:

- `dailyEpisodeGenerations`
- `musicGenerationsPerMonth`
- `lockInClipsPerDay`
- `regenerationsPerDay`
- `maxEpisodeSeconds`
- `maxJoltSeconds`
- per-device/IP/account abuse limits
- project-level daily spend caps

The app should show premium value, but the backend owns quotas.

### 5. Cache By Reusable Inputs

Cache generated assets by:

- voice/narrator
- intensity
- arc
- music style
- locale
- episode length band

Avoid regenerating the same style bed for every user when a reusable bed will
feel just as good.

## Hard Paywall Model

Hard paywall is the safest cost model:

- Onboarding can use bundled/demo audio.
- No expensive production generation until entitlement exists.
- First paid/trial activation generates Episode 1.
- Cancels/failures stay on paywall and do not unlock AI generation.

Recommended if hard paywall:

- Special offer can stay at $29.99/year only if daily music generation is not
  unlimited.
- Default annual should likely be closer to $59.99/year if the promise is daily
  generated voice plus periodic generated music.
- Weekly can include the richest version.

## Freemium Model

Freemium can work, but only if the free tier is mostly local.

Good free tier:

- native alarm
- Wake Quest
- bundled forceful Wake Jolt
- local/bundled Morning Episode template
- limited receipts/streaks
- maybe 1 generated pilot episode or 1-3 AI credits total

Bad free tier:

- daily generated TTS
- daily generated music
- unlimited Lock In clips
- repeated regenerations

Freemium cost examples:

| Free offer | Cost risk |
| --- | --- |
| Local/bundled only | Very low |
| 1 generated pilot for each new signup | ~$0.06 per signup if voice + one Lyria bed |
| 3 generated episodes per MAU/month | ~$0.18 per MAU/month with music, too risky at scale |
| Daily generated episodes for free users | Not viable |

Freemium recommendation:

- Free users get the behavior loop, not the expensive AI loop.
- Use credits: `1 free AI Episode`, then premium or paid credits.
- Keep music generation premium-only.
- Free Lock In should be bundled/template clips, not generated clips.

## Best Initial Decision

Launch with a hard paywall or very tight freemium:

1. Daily generated voice is okay for paid users.
2. Fresh AI music should be milestone/weekly/arc-level, not daily by default.
3. App-side layered playback should be v1.
4. Backend quotas must exist before any public freemium test.
5. Track `grossMarginPerActiveSubscriber` from day one:

```text
net_subscription_revenue
- tts_generation_cost
- music_generation_cost
- storage_egress_cost
- cloud_runtime_cost
= gross margin before support/ads
```

The product should feel premium through timing, writing, voice, animation, and
reuse of strong music beds, not through unbounded daily media generation.
