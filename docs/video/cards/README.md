# Video cards and lower thirds

The cards, lower thirds and Figma clip for the 3:00 Devpost video. The IDs are the ones in `docs/gtm/video.md`, and each file name starts with its ID, which is how `homer/scripts/rough_cut.py` finds it. Everything is 1920×1080 at 60 fps.

Every moving background is the website's own WebGL scene (`homer/web/src/scene`) at the app's Hall rest, rendered frame by frame in headless Chrome.

## Grades

- **Graded once:** every .mp4 and every opaque .png. The grade is matte: cream highlights, lifted blacks, saturation at 0.86 and light grain. Don't grade these again.
- **Ungraded:** the transparent PNGs (C0 and the lower thirds). They take the edit's grade along with the footage under them.

## Cards

| File | What it is |
|---|---|
| C0-greek.png | Transparent overlay for the scene shot: **μῆνιν ἄειδε θεὰ** (Noto Serif Display, 136 px) over *Sing, goddess, the rage…* |
| C1-title.mp4 / .png | μῆνιν · MeNIN / *Homer teaches you to speak. Then you battle.*, 4 s. C1-title-v2 has the same text and sorts first, so it's the one the edit uses |
| C2-diagram.mp4 / .png | How it works, 6.6 s (the slot for line 6): Your voice → Cartesia → SpacetimeDB → Claude + Homer's voice. A gold line carries the word "rage" through the four boxes, in italic with a wave until Cartesia hears it. The FigJam version is "MeNIN · How it works (video card C2)". |
| C3-wer.mp4 / .png | 20% → 3% word errors with keyterms, 4.6 s |
| C5-responsible.mp4 / .png | Built responsibly, five lines, 6 s |
| C6-end.mp4 / .png | Play it now, the URL, the repo, the score credit, the sponsors and the team, 10 s. The URLs are set in Inter, because Bodoni's slashes vanish at video size |
| F1-flip.mp4 / .png | The Verdict frame (Figma 36-128), wiping from Atelier to Hall between 2.5 and 5 s, 15 s (the Figma slot). L14 carries the stat over it, bottom-left. |
| BG-rest-loop.mp4 | The scene at rest as a graded, seamless 6 s plate |

## Lower thirds

All the lower thirds are transparent full-frame PNGs: put them at 0,0 with no positioning. They're Inter on a frosted plate with the sea-blue bar, at the bottom-left, 96 px from the left edge and 168 px from the bottom, clear of YouTube's controls.

- L1–L10 and L14 are word for word from video.md.
- LM is "Matus · MeNIN", for Matus's on-camera answers.
- L13-stadion, -toxeia, -pygmachia and -discus are marked "· beta". L13-poetry is not.

## Spares

Files starting with `x-` are spares the edit doesn't pick up: two other versions of C0's text, and "Every phone in sync · SpacetimeDB".

## Re-rendering

The render harness is in the artist session's scratchpad (`video/`: `run.sh`, `batch.mjs`, `post.sh`). Changing the composer's name is one variable: `COMPOSER=Paulo` re-renders C6.
