# Cold Open Transparent Asset Opportunities

Use GPT-image-1.5 only where alpha PNG cutouts add emotional clarity without
adding more UI chrome. The app should still be native Flutter first: big type,
one action, one state. Transparent art supports the scene.

## Best Places

1. First-run cold open hero
   - Current asset: `assets/onboarding/cold-open-anime-character.png`
   - Keep: one protagonist with alarm energy, right-side composition.
   - Improve: generate a cleaner transparent full-body cutout with stronger
     upward motion and less edge clutter.
   - Why: this is the first emotional promise: "Start your day like an anime
     character."

2. Title Card Slam speed-cut accent
   - Asset: transparent angular crimson/ink slash behind the generated episode
     title.
   - Why: the title card already has huge type; a sparse alpha slash would make
     the slam feel custom without turning the whole screen into a poster.

3. Wake Quest proof icons
   - Assets: tiny transparent cutouts for Object Hunt, Water Check, Sky Photo,
     Desk Ready, Get Up.
   - Why: these make Wayk-inspired missions instantly legible when a user is
     half asleep.

4. Narrator busts for Profile
   - Assets: flat-cel transparent busts for Mentor, Rival, Captain, Quiet
     Senior.
   - Why: Profile currently uses letter placeholders. Character portraits would
     make narrator selection feel like the app's identity, not generic settings.

5. Wake Card foil stamps
   - Assets: transparent rarity seals: FIRST LIGHT, COMEBACK, NO SNOOZE,
     STORM RISER.
   - Why: reward artifacts benefit from collectible texture. Keep gold rationed
     to this surface only.

6. Post-miss comeback mark
   - Asset: red-ink knockdown slash / comeback stamp.
   - Why: missed mornings should feel canon, not like a broken streak dashboard.

## Avoid

- Do not add background scenes behind every screen.
- Do not add character art to dense choice screens.
- Do not put transparent assets behind body copy.
- Do not use generated UI text inside assets.
- Do not use gold except foil/share/reward artifacts.

## GPT-image-1.5 Prompt Seeds

Cold open protagonist:
```text
Create an original anime-inspired teenage protagonist sprinting forward while
holding a ringing alarm clock, dynamic morning energy, bold cel-shaded line art,
crimson motion accents, full body, transparent background, PNG alpha, no text,
no logo, no scenery, no shadow, clean edges, generous padding.
```

Wake Quest object hunt icon:
```text
Create an original anime-style transparent PNG sticker of a glowing room object
being discovered by a morning protagonist hand, simplified cel-shaded object
hunt icon, crimson accent only, no text, no background, no shadow.
```

Narrator Mentor bust:
```text
Create an original anime mentor narrator bust portrait, calm confident morning
coach energy, flat cel shading, ink navy and warm paper palette with a single
crimson accent, transparent background, PNG alpha, no text, no logo.
```

First Light foil stamp:
```text
Create a transparent PNG collectible foil seal for a morning wake card: radiant
sunburst crest, manga stamp shape, gold foil effect, no readable text, no
background, clean alpha edges.
```

## Implementation Order

1. Replace/refine the first-run cold open protagonist.
2. Add narrator busts to Profile.
3. Add small Wake Quest mission cutouts.
4. Add card/stamp rewards once the core flow records well.
