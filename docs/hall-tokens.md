# The Hall's look: tokens from the website

What the website (`homer/web`, live at https://play.206.189.237.157.sslip.io) actually draws, for the app's reskin. Pulled read-only from the CSS (`src/index.css`, `src/wired.css`, `src/coach.css`, `src/music.css`) and the scene's shader (`src/scene/moods.ts`, `shaders.ts`, `Scene.ts`, `motion.ts`), Sat Oct 24, 9 PM. The website has **no colour variables**: index.css and wired.css hard-code 128 distinct colours (148 with coach and music), 69 type values, 17 radii, 73 spacing values and 16 shadows. The names below are new; the values are the site's. Field games (discus, stadion, boxing, archery) have their own pottery palettes and aren't covered here.

Reference screenshots (1440×900, Chrome) are in `docs/hall-tokens/`:

| | |
| --- | --- |
| `1-menu.png` | the menu, live site |
| `2-lobby.png` | a poetry hall's lobby, live site |
| `3-poetry-turn.png` | a poetry turn (the verse being weighed), test hall, same build |
| `4-verdict.png` | the verdict and the scoreboard, test hall, same build |

(3 and 4 come from the test hall, so the cream "Voice offline" note shows; on the live hall it says only "This screen hosts room …".)

## Colour

### Sea blues: the brand

| Token | Hex | Where |
| --- | --- | --- |
| `sea` | `#328EAF` | the primary blue: primary buttons (bottom of their gradient), the JOIN pill, the active scoreboard row, secondary-button text, score bars, the coach's mic mark |
| `sea-light` | `#65B9D8` | the primary button's top (gradient `#65B9D8 → #328EAF`, 180°) |
| `sea-press` | `#287794` | the primary button's hard drop shadow (`0 0.28rem 0`) |
| `sea-title` | `#2E8EB5` | "MeNIN" in the top bar (weight 300) |
| `sea-label` | `#2F7F9C` | small caps labels: "ROOM DNSE · ROUND 1 OF 1", scoreboard numbers |
| `sea-line` | `#9FCFE0` | secondary-button border, the live verse's left rule |
| `sea-track` | `#D4E8EE` | empty score-bar segments |
| `nameplate` | `rgb(39 75 108 / 90%) → rgb(61 102 139 / 83%)`, 90° | the menu's "Homer" nameplate (left-anchored, radius `0 1rem 1rem 0`) |
| `sky-root` | `#3699ED` | the page's base colour behind the menu |

### Ink: text on light

| Token | Hex | Where |
| --- | --- | --- |
| `ink` | `#2C4B5C` | headings in a hall ("The dog who knew you first"), names, the live verse, scores |
| `ink-2` | `#334B5B` | menu text, the select, the room code; also the dark slab behind the carved line and the crown |
| `ink-3` | `#355D72` | subtitles ("Scan the code with the MeNIN app…"), the menu workspace heading (weight 300) |
| `ink-muted` | `#4C6B7A` | epithets, neutral marks, the coach's mic caption |
| `ink-faint` | `#78909C` | small notes, captions |
| `ink-quote` | `#577685` | the verdict's quote text |

### Cream, card and paper

| Token | Value | Where |
| --- | --- | --- |
| `white` | `#FFFFFF` | button and card borders, text on blue and dark |
| `card` | `rgb(255 255 255 / 96%) → rgb(241 249 251 / 90%)`, 145° | the main hall card (`.workspace`); over the painted sea it's `84% → 76%` with `backdrop-filter: blur(1.4rem) saturate(1.1)` |
| `card-fill` | `#F7FBFC` | inner panels: the live verse, the join card, the verdict quote |
| `row` | `#EDF7F9` | scoreboard rows, settings, the coach's mic state |
| `row-line` | `rgb(79 148 171 / 18%)` | 1px borders on rows and inner cards |
| `button-light` | `#FFFFFF → #EDF6F8` | round light buttons (Main menu, the speaker) |
| `topbar` | `rgb(255 255 255 / 82%)` + `blur(1rem)` | the hall's top bar |
| `cream-note` | bg `#FBF3DC`, border `#ECD9A4`, text `#6B5A2E` | the host's operator note |
| `parchment` | `#F4F1E8` | text on the dark game tiles |

### Dark glass: Homer's box and the tiles

| Token | Value | Where |
| --- | --- | --- |
| `dialogue` | `rgb(36 52 65 / 84%) → rgb(55 64 70 / 76%)`, 135°, border `0.48rem solid rgb(249 249 244 / 90%)`, `blur(0.55rem)` | "Homer speaks" on the menu, the game tiles (border `0.2rem`), Homer's caption box in a hall (`rgb(40 62 77 / 90%) → rgb(55 73 82 / 82%)`) |
| `slab` | `#334B5B` | the carved-line and crown cards (solid) |

### Gold: honour and the carved line

| Token | Hex | Where |
| --- | --- | --- |
| `gold` | `#D7B46A` | the carved line's text, the "CARVED" / "CHAMPION" labels, the verdict quote's left rule, formula underlines |
| `gold-bright` | `#E2BD6C` | the coach's best-score seal, the last seconds of the turn clock, "HOMER" labels on dark |
| `gold-bar` | `#C99A3E` | a high score bar (8+) |
| `gold-deep` | `#9B7A35` | the leader's score on the scoreboard |
| `gold-ink` | `#2C2416` | text on the gold seal |

### Neutral and the judge's silence

| Token | Hex | Where |
| --- | --- | --- |
| `neutral-bar` | `#9AAAB3` on `#E3ECEF` | a neutral score (the judge timed out) |

### Seats: one ink per poet (= the app's `Palette.seats`)

| Seat | Hex | Name |
| --- | --- | --- |
| 1 | `#2D5C66` | sea |
| 2 | `#C8452C` | vermilion |
| 3 | `#A8741F` | gold |
| 4 | `#5B3F73` | plum |
| 5 | `#6E7A2E` | olive |

Used as the left border of each scoreboard row and the poet's colour everywhere in the battle.

### The menu's backdrop (behind Homer)

`linear-gradient(180deg, #58ACF0 0%, #64B4F0 43%, #2D8FDC 53%, #318FD6 67%, #D5C5A4 71%, #DFCFAD 100%)`: sky, horizon, sea, sand. It's masked to a soft ellipse (`radial-gradient(ellipse 53% 56% at 50% 51%, #000 58%, transparent)`), with a sun haze (`radial-gradient(circle, rgb(255 244 193 / 34%), transparent 68%)`) and a sea glint (`linear-gradient(90deg, transparent, rgb(255 255 255 / 42%), transparent)`).

## The painted sea (the Aegean scene)

A WebGL port of the iOS scene (`ios/Homer/Scene/Scene.metal`). It renders behind the hall in poetry, debate and Talk to Homer, and stays still on the field games.

**How it's drawn.** Three passes. (1) The field: domain-warped simplex noise cut into **four flat matte ink layers**, like torn paper; the cuts are at field heights **0.36, 0.52, 0.68** (ink 1 below 0.36, ink 4 above 0.68), each layer casting a soft shadow down and to the right. The field renders at half resolution (soft paint). (2) Flecks: flat dots, dashes and shards over it, no glow. (3) The finish: a matte grade (blacks lifted to `rgb(0.06, 0.05, 0.07)`, whites eased toward the page's white point), paper tooth (4.5%), a whisper of moving grain (1.8%), and a 5% vignette. White point: poetry `(0.99, 0.995, 1.0)`, debate `(0.965, 0.985, 1.0)`, coach `(0.995, 0.995, 0.99)`.

**Its palette.** Each mood is four inks, dark to light. `rest` is what you see between turns; the emotions wash in from a direction while a poet speaks (the voice's emotion picks them, marbled rather than averaged).

| Mood | Ink 1 | Ink 2 | Ink 3 | Ink 4 | Speed | Drift | Amp | Flecks | Washes in from |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| rest | `#A9D3E2` | `#C4E3EE` | `#D9EEF5` | `#EAF7FB` | 0.05 | (0.02, 0) | 0.38 | dots, anywhere | below |
| anger | `#3D0B10` | `#B3161F` | `#EC4A1C` | `#FF9B52` | 0.40 | (0, 0.05) | 0.50 | shards, centre | centre |
| grief | `#070B1D` | `#12245A` | `#294C98` | `#7F97CB` | 0.04 | (0, −0.02) | 0.35 | dots, top (falling) | above |
| joy | `#E23F7C` | `#FF7A59` | `#FFC23A` | `#FFF0B0` | 0.20 | (0.02, 0.05) | 0.55 | dots, bottom (rising) | |
| awe | `#2E2108` | `#A8720F` | `#E8B73A` | `#FFF3D2` | 0.09 | (0, 0.04) | 0.45 | dots, bottom | |
| tenderness | `#47294D` | `#C27596` | `#B6A2E0` | `#F4E4EE` | 0.06 | (0.015, 0.01) | 0.40 | dots, anywhere | |
| fear | `#0B1712` | `#2C5243` | `#6F8F7F` | `#B3BCB6` | 0.18 | (0, 0) | 0.60 | dots, edges | |
| defiance | `#1B0838` | `#5A1FD0` | `#AE84FF` | `#FBF3FF` | 0.30 | (0, 0.03) | 0.65 | dashes, centre | |
| longing | `#1F1033` | `#593877` | `#C0694A` | `#F2A65A` | 0.06 | (0.05, 0) | 0.40 | dashes, left | |

Debate's rest is greener: `#8FA59F #ADC0B9 #C8D6D0 #E1EAE6`.

**How it moves.** The field drifts at the mood's speed (rest is nearly still, 0.05; anger is 8× that). Per room, the motion is bent: debate ×1.15 speed, sharper (jag 0.3), harder edges; Talk to Homer ×0.55 speed, ×0.75 amplitude, softer edges. Mood weights ease in with a 0.9 s time constant, so a new feeling takes about 2 s to wash over. The poet's voice drives it live from the phone's 20 Hz prosody: loudness eases in over 35 ms and out over 80 ms; a syllable onset (a rise above the running base) "punches" the field, decaying over 0.32 s; pitch shifts tilt it, easing over 0.15 s.

## Type

Two families, nothing else:

- **Serif: Georgia** for everything a poet or Homer says, every name and every number.
- **Sans: "Helvetica Neue", Helvetica, Arial, system-ui** for chrome, headings in the hall card, and small-caps labels.

| Role | Family | Weight | Size (1440 px wide) | Notes |
| --- | --- | --- | --- | --- |
| Hall heading ("The dog who knew you first", "Enter the hall") | sans | 500 | `clamp(2.2rem, 4.2vw, 3.8rem)` | `#2C4B5C`, tracking −0.01em, line 1.08 |
| Menu workspace heading | sans | 300 | `clamp(1.8rem, 4vw, 2.8rem)` | `#355D72`, tracking −0.04em |
| "MeNIN" in the top bar | sans | 300 | 1.55rem | `#2E8EB5` |
| Small-caps label ("ROOM · ROUND", "JOIN", "IMAGE", "CARVED") | system-ui | 700 | 0.85–0.95rem | uppercase, tracking 0.08–0.2em |
| Live verse | Georgia | 400 | `clamp(1.7rem, 3vw, 2.8rem)` | line 1.22 |
| Poet's name (scoreboard) | Georgia | 600 | `clamp(1.25rem, 2vw, 1.7rem)` | |
| Epithet | Georgia italic | 400 | `clamp(0.9rem, 1.3vw, 1.1rem)` | `#4C6B7A` |
| Score number (scoreboard) | Georgia | 700 | `clamp(1.8rem, 3vw, 2.6rem)` | |
| Axis score (verdict) | Georgia | 700 | `clamp(1.6rem, 2.6vw, 2.4rem)` | |
| Verdict quote / best line | Georgia italic | 400 | `clamp(1.4rem, 2.2vw, 1.9rem)` | gold left rule |
| Carved line | Georgia italic | 600 | `clamp(2.2rem, 4vw, 3.6rem)` | gold on the slab |
| Champion's name | Georgia | 700 | `clamp(3rem, 6vw, 5rem)` | |
| SPEAK cue | Georgia | 800 | `clamp(4rem, 9vw, 7.5rem)` | |
| Room code (join card) | Georgia | 600 | 3rem | tracked out |
| Homer's reply (Talk to Homer) | Georgia italic | 400 | `clamp(1.5rem, 2.5vw, 2.3rem)` | |
| Body / captions | sans | 400–600 | 0.9–1.1rem | |

## Shape: radii, borders, shadows

| Token | Value | Where |
| --- | --- | --- |
| `r-pill` | `99rem` | every button, the JOIN pill, chips |
| `r-round` | `50%` | round buttons (the A button, the speaker, Main menu's ends) |
| `r-card` | `2rem` (1.5rem on small screens) | the main hall card |
| `r-dialogue` | `2.1rem` | Homer's box on the menu |
| `r-slab` | `1.4rem` | the carved line and crown slabs |
| `r-row` | `1rem` | scoreboard rows, the join card, game tiles |
| `r-inner` | `0.85rem` | the verdict quote panel |
| `r-note` | `0.6rem` | the host note |
| border, card | `2px solid rgb(255 255 255 / 95%)` | the hall card's white rim |
| border, button | `2px solid #fff` (primary), `2px solid #9FCFE0` (secondary) | |
| shadow, card | `0 1.5rem 4rem rgb(49 104 126 / 16%)` | big and soft, blue-tinted |
| shadow, primary button | `0 0.28rem 0 #287794` | a hard ledge, no blur (a pressable key) |
| shadow, select | `0 0.28rem 0 rgb(110 135 150 / 72%), inset 0 1px 0 #fff` | same ledge idea, grey |
| shadow, dialogue | `0 1rem 2.5rem rgb(25 44 56 / 22%), inset 0 0 0 0.18rem rgb(121 143 155 / 22%)` | |
| shadow, nameplate | `0 0.35rem 0.8rem rgb(22 63 96 / 18%)` | |
| shadow, top bar | `0 0.4rem 1.2rem rgb(53 108 130 / 8%)` | |

## Patterns worth carrying over

- **Pressable keys:** pill buttons with a hard, unblurred ledge shadow in a darker shade of the fill (`#287794` under `#328EAF`).
- **Frosted cards over a moving scene:** a near-white gradient card with blur over the painted sea, so the sea's colour reads through and every word stays legible.
- **Segmented bars:** score bars are ten segments (a repeating mask with 3px gaps), filled in `sea`, or `gold-bar` for 8+.
- **Gold means honour:** the carved line, the champion, the best attempt and the leader's score.
- **Serif for words and numbers, sans for chrome.**
