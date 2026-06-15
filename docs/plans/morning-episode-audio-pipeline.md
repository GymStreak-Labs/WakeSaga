# Morning Episode Audio Pipeline

WakeSaga's Morning Episode should feel like the reward after a verified wake,
not like a generic motivational clip. The production audio package should be
generated before the alarm and played locally after Wake Quest clears.

## Product Moment

1. Alarm fires with OS-level reliability and a short Wake Jolt.
2. User completes Wake Quest.
3. Alarm cuts out.
4. Title Card slams in.
5. Morning Episode starts with narrator voice plus a cinematic instrumental
   score underneath.

The music belongs after proof. The alarm itself should stay direct, urgent, and
legible to a half-asleep user.

## Generated Assets

For each armed episode, generate and cache:

- `wake_jolt_voice`: short pre-quest voice clip. This should be forceful and
  physical: name, wake up, get up, move now. It should not explain the mission,
  rival, episode, or deeper story.
- `episode_script`: 60-120 second script with mission, rival, first move, and
  callback to recent history.
- `episode_voice`: Gemini/Flash TTS render of the script.
- `episode_music_bed`: Google Lyria instrumental score bed.
- `episode_mix`: ducked final mix with voice prioritized over music.
- `subtitle_timing`: line or phrase timing for anime-style lower-third captions.

## Lyria Prompt Rules

Lyria prompts should be structured and guardrailed:

- instrumental only;
- no vocals, lyrics, chants, or recognizable melodies;
- no copyrighted anime, film, or game references;
- leave midrange room for narration;
- define arc mood: study, gym, comeback, recovery, monk mode, or deep work;
- define intensity: quiet, cinematic, rival, captain, or recovery;
- request a clean ending or loopable tail.

Example prompt:

```text
Create an instrumental-only cinematic anime morning underscore for a
motivational alarm app. No vocals, no lyrics, no copyrighted themes. Leave
space for spoken narration. Mood: epic but hopeful, like a hero standing up at
sunrise. Low strings, taiko-style drums, soft synth pulse, brief brass lift.
Structure: quiet tension, rising pulse, heroic lift, clean resolve.
```

## Mix Rules

- Narration stays intelligible at all times.
- Music ducks under voice and rises only between phrases.
- Loudness-normalize the final mix for phone speakers.
- Keep a bundled fallback instrumental for offline/failure cases.
- Cache before the alarm; never block the morning on live generation.

## Implementation Shape

The mobile app should not hold provider API keys. Use a callable backend:

1. App arms episode and sends a signed generation request.
2. Backend checks auth, entitlement, quota, and App Check.
3. Backend generates script, TTS, Lyria bed, and mix.
4. Backend stores signed/cached audio package metadata.
5. App downloads the package before bedtime or on the next launch.
6. Dawn Rail plays local files after Wake Quest clear.

If generation fails, WakeSaga should still arm the alarm with:

- bundled siren/jolt;
- text subtitles;
- bundled fallback score bed;
- clear UI that the episode is in fallback mode.

## Prototype Wiring

The current Flutter prototype uses bundled assets in `assets/audio/`:

- `alarm_pulse_loop.mp3`
- `wake_jolt_forceful.mp3`
- `quest_clear_sting.mp3`
- `lyria_morning_episode_bed.mp3`
- `morning_episode_scored.mp3`

`WakeSagaAudio` owns the lifecycle:

1. Dawn Takeover starts the alarm loop and forceful Wake Jolt.
2. Wake Quest keeps the alarm alive until verify.
3. Quest clear stops the alarm and plays the clear sting.
4. Morning Episode plays the scored mix.

This proves the product timing before the backend generation/cache path exists.

## Wake Jolt Prompt Rules

The Wake Jolt is not the Morning Episode. It is the thing that gets a
half-asleep person vertical.

Prompt style:

```text
Say this like a forceful anime commander shouting someone awake. Urgent,
direct, high energy, no cruelty. Do not explain the mission or story. No
paragraphs. No music. No sound effects.

Joe! WAKE UP! GET UP! TODAY IS YOUR DAY. SEIZE IT!
```

Rules:

- Use the user's name.
- Prefer shouty one-line commands.
- Say "wake up", "get up", "feet on the floor", "move now".
- Do not mention mission, rival, episode title, yesterday, productivity, or
  emotional analysis.
- Recovery mode can soften volume/tone, but still tells the user exactly what
  to do physically.
