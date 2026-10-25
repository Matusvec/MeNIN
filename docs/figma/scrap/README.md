# Figma scrap: the rounds and options that led to the finals

Small previews of the work in "MeNIN · Directions" that was reworked in place. Figma now shows only the finals, so these are the record of what came before (Sat Oct 24, times PDT). Full-size originals stay on the artist's Mac only; their paths are in `docs/gtm/figma-everything.md`, section 3.

## The Hall background, four rounds of Matus's feedback (21:03–21:20)

Each picture is the website's own WebGL scene code, rendered headless with the app's candidate values. The voice is scripted: emotion, energy and stressed syllables. Each round's render went full-bleed behind the Hall frames in Figma.

| File | Round | What it is | Shipped or dropped |
|---|---|---|---|
| round0-reference-website-rest.png | Reference | The website's rest scene, which everything was measured against | Reference |
| round1-probe-blue-7FBCD6.png | 1: "keep the cool wavy white … a mix of cool blue" | Deepest ink #7FBCD6 | Dropped for #7AB6D0 |
| round1-probe-blue-5FAACB.png | 1 | A deeper blue, #5FAACB | Dropped for #7AB6D0 |
| round1-probe-lift-0.06.png, round1-probe-lift-0.02.png, round1-probe-lift-minus-0.02.png | 1 | How much of the screen the blue covers (band lift +0.06, +0.02, −0.02) | +0.03 shipped |
| round1-rest-phone.png | 1 | The rest at phone size, deepest ink #7AB6D0 | Ink and lift shipped; see round 4 for the tilt |
| round2-shoot-joy.png | 2: "the background … that shoots colors" | A voice driving joy and awe, 1.3 s in | The idea shipped (round 4) |
| round2-shoot-longing.png | 2 | A voice driving longing and tenderness | The idea shipped (round 4) |
| round3-mono-joy.png, round3-mono-anger.png | 3: "I just want the BLUE shooting there" | The voice in blues only (#2E8EB5 → #B8DCEA) | Shipped in build 33 because the archive couldn't wait, then **dropped** |
| round4-final-rest.png | 4: **"blue at rest, colours on voice"** | The rest, with the tilt flipped so the blue gathers low behind the cards (ink text on the blue streak measured 4.1:1). Rendered at 21:12 after round 2 | **Shipped** (build 34). In every Hall frame except Turn |
| round4-final-voice.png | 4 | The voice washing colour through it, with the same tilt. Rendered at 21:12 and brought back for round 4 | **Shipped** (build 34). In both Turn frames |

Two blank renders, caused by a missing semicolon in the harness, aren't included.

## The app icon (21:34–22:16)

| File | What it is | Shipped or dropped |
|---|---|---|
| icon-bg-rest.png | The rest scene, square | Behind A, and under the key in C and μ |
| icon-gold-failed.png | The first voice render, captured too late in the wash: the whole square went gold | **Dropped**: it was re-rendered |
| icon-bg-voice-0.45s.png | The re-render 0.45 s into the shot (joy and awe) | Behind B |
| icon-bg-voice-0.65s-unused.png | An alternative at 0.65 s (longing and joy) | Not used |
| icon-A-rising-m.png | A · Rising M, Figma node 51-103 | **Dropped**: Bodoni's hairline thins out at 40 pt |
| icon-B-voice.png | B · Voice, node 51-106 | **Dropped**: same reason |
| icon-C-key.png | C · Key, node 51-109 | Picked at 21:38 (build 35), then **replaced** by μ |
| icon-mu.png | C · Key · μ, node 54-142, in Noto Serif Display Black | **Shipped**: the app icon (build 41) |

The clean 1024 px versions (sRGB, no alpha) are in `docs/design/app-icon/`.

## The deck stand-ins (17:28)

Exports from the "Prototype · Atelier" and "Home · Directions" pages, made for the Figma Slides draft.

| File | Figma node | Status |
|---|---|---|
| deck-home-atelier.png | 5-10, Home — Atelier | Atelier: the app's look until build 31 |
| deck-home-cut-paper.png | 5-116, Home — Cut paper | **Dropped** direction |
| deck-p1-first-open.png | 15-102 | Prototype, flow 1 |
| deck-p4-practice.png | 15-224 | Prototype, flow 1 |
| deck-p5-verdict.png | 15-270 | Prototype, flow 1 |
| deck-p9-champion.png | 16-310 | Prototype, flow 2 (arena, laptop size) |
