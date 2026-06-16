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
- Bundled/pre-generated cinematic music bed selected locally.
- App plays voice and music as separate local tracks with ducking/fades.
- Voice audio is generated before the alarm window, downloaded, and cached
  locally.

The alarm moment must never require network. If generation fails, the app uses
bundled fallback jolt/music and a local script.

## Current Cost Decision: Bundle Music, Generate Voice

WakeSaga should not generate background music per user in production v1.
Instead, generate a strong library of cinematic music treatments before launch,
ship them in the app or as pre-cached remote assets, and select one locally for
each episode.

This removes the largest per-user variable cost while preserving the premium
feel:

```text
Production v1 variable generation = script + Wake Jolt TTS + episode TTS
Production v1 music = bundled/pre-cached beds, selected locally
```

Fresh text-to-music can return later for milestone moments, paid add-ons, or
share/export packs, but it should not be part of the daily generation loop.

## Per-Episode AI COGS

Approximate costs:

| Package | Cost per generated morning | Monthly cost for daily active user |
| --- | ---: | ---: |
| Voice + bundled music bed | ~$0.022 | ~$0.65 |
| Voice + fresh Lyria 3 30s bed daily | ~$0.062 | ~$1.85 |
| Voice + fresh Lyria 3 Pro song daily | ~$0.102 | ~$3.05 |

Script generation with Gemini Flash is effectively tiny compared with audio,
assuming short prompts and 60-120 second scripts. Storage and egress are also
small versus TTS/music if packages are downloaded once and retained with a
short TTL.

The first row is the recommended production v1 path.

## Subscriber Scale Scenarios

Assume music is bundled/pre-cached and the only daily AI cost is generated
voice/script. Subscriber usage matters more than subscriber count.

| Subscribers | 40% daily usage | 60% daily usage | 80% daily usage | 100% daily usage |
| ---: | ---: | ---: | ---: | ---: |
| 10,000 | ~$2,600/mo | ~$3,900/mo | ~$5,200/mo | ~$6,500/mo |
| 100,000 | ~$26,000/mo | ~$39,000/mo | ~$52,000/mo | ~$65,000/mo |

This is the economics unlock: production music generation disappears from the
recurring user-level cost line.

## Revenue Benchmarks

Conservative net revenue after a 30% store cut:

| Product | Net ARPU |
| --- | ---: |
| $29.99/year special | ~$1.75/user/month |
| $39.99/year annual | ~$2.33/user/month |
| $59.99/year annual | ~$3.50/user/month |
| $6.99/week | ~$21.20/user/month |

At 60% daily usage, generated voice costs roughly `$0.39/user/month`.

| Product | AI COGS at 60% usage | AI gross margin before cloud/support |
| --- | ---: | ---: |
| $29.99/year special | ~$0.39/user/month | ~78% |
| $39.99/year annual | ~$0.39/user/month | ~83% |
| $59.99/year annual | ~$0.39/user/month | ~89% |
| $6.99/week | ~$0.39/user/month | ~98% |

Implication:

- $29.99/year becomes workable if music is bundled/reused.
- $39.99/year gives more room for trials, free pilot credits, and overhead.
- $59.99/year supports richer AI usage, more Lock Ins, and healthier margin.
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
  "musicBedAssetId": "rival_dawn_03",
  "durationSeconds": 75,
  "modelCosts": {
    "scriptUsd": 0.001,
    "ttsUsd": 0.022,
    "musicUsd": 0
  },
  "expiresAt": "..."
}
```

The app downloads voice before the wake window and plays it locally over a
bundled/pre-cached music bed. No provider keys ship in the app.

### 2. Use Client-Side Layered Playback For V1

Do not server-mix every episode by default. Generate/cache voice and select
music locally:

```text
episodeVoice.mp3 + bundledMusicBed(assetId)
```

The app starts both after Wake Quest clears, ducks the music under voice, and
fades the bed at the end. Server-side mixes are optional later for sharing or
exports.

### 3. Bundle Music Treatments

Ship a music library with several reusable treatments:

- `dawn_rise`: hopeful first-day bed.
- `rival_pulse`: aggressive wake-up aftermath.
- `deep_work_tension`: study/focus bed.
- `gym_charge`: movement/training bed.
- `comeback_low`: post-miss recovery bed.
- `monk_mode_minimal`: sparse disciplined bed.
- `recovery_soft`: gentle low-mood bed.
- `victory_foil`: milestone/share-card bed.

Each bed should be instrumental, loopable, phone-speaker-safe, and designed to
leave room for narration.

### 4. Select Music Locally

Selection should be deterministic enough to avoid repeats, but varied enough to
feel alive:

```text
candidate beds = filter by arc + intensity + user mode
exclude last 2-3 recently used beds
seed = userId + episodeNumber + localDate
pick weighted random candidate
```

The selected `musicBedAssetId` is saved into the episode record so replay and
share cards are consistent.

### 5. Meter Expensive Actions

Backend should enforce:

- `dailyEpisodeGenerations`
- `lockInClipsPerDay`
- `regenerationsPerDay`
- `maxEpisodeSeconds`
- `maxJoltSeconds`
- per-device/IP/account abuse limits
- project-level daily spend caps

The app should show premium value, but the backend owns quotas.

### 6. Cache By Reusable Inputs

Cache generated voice assets by:

- voice/narrator
- intensity
- arc
- locale
- episode length band

Music beds are app assets. Avoid per-user music generation entirely in v1.

## Hard Paywall Model

Hard paywall is the safest cost model:

- Onboarding can use bundled/demo audio.
- No expensive production generation until entitlement exists.
- First paid/trial activation generates Episode 1.
- Cancels/failures stay on paywall and do not unlock AI generation.

Recommended if hard paywall:

- Special offer can stay at $29.99/year if the daily generated asset is voice
  only and music is bundled.
- Default annual at $39.99-$59.99/year gives more margin for Lock Ins, free
  trials, and failed generation retries.
- Weekly can include the richest version.

## Freemium Model

Freemium can work, but only if the free tier is mostly local.

Good free tier:

- native alarm
- Wake Quest
- bundled forceful Wake Jolt
- bundled music beds
- local/bundled Morning Episode template
- limited receipts/streaks
- maybe 1 generated voice pilot episode or 1-3 AI voice credits total

Bad free tier:

- daily generated TTS
- unlimited Lock In clips
- repeated regenerations

Freemium cost examples:

| Free offer | Cost risk |
| --- | --- |
| Local/bundled only | Very low |
| 1 generated voice pilot for each new signup | ~$0.022 per signup |
| 2 generated free voice episodes / MAU / month | ~$0.044 per MAU/month |
| Daily generated episodes for free users | Not viable |

Freemium recommendation:

- Free users get the behavior loop, not the expensive AI loop.
- Use credits: `1 free AI Episode`, then premium or paid credits.
- Keep all music bundled/pre-cached.
- Free Lock In should be bundled/template clips, not generated clips.

## Best Initial Decision

Launch with a hard paywall or very tight freemium:

1. Daily generated voice is okay for paid users.
2. Background music should be bundled/pre-cached, not generated in production.
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
strong bundled music direction, not through unbounded daily media generation.
