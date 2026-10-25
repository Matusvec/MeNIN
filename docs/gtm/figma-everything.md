# Figma, everything: every file, page, frame and scrap

For our web designer, from the artist session. As of Sun Oct 25, 01:10 AM. The inventory was read-only. The one change to Figma since then was the leader's request at 01:10: the duplicate flow starting point on 29-320 is removed, and no frames were touched. ★ marks the links the leader already sent. `docs/gtm/submission-packet.md` says where each one goes on Devpost and in the deck, and `docs/gtm/figma-stage-log.md` has the full story.

Node links all follow one pattern: `https://www.figma.com/design/<file>/?node-id=X-Y`.

**One thing to know first.** The four background rounds, the first pass of the Hall frames and the first icon render were all reworked **in place**, so the file shows only the final version of each. Earlier states survive in two places: the file's version history (File → Show version history, Sat Oct 24 around 20:53–21:20), and the renders in section 3. Small previews of those are in the repo at `docs/figma/scrap/`.

## 1. MeNIN · Directions (Design)

★ https://www.figma.com/design/qyaXnV3HbIUPIfYVbyqKwv. Five pages, in this order.

**Variables** (not a node, so no link; open the file → Local variables): collection "MeNIN", **52 variables** in **3 modes**: **Atelier**, **Cut paper** and **Hall**. Each variable carries its Swift name as iOS code syntax (`Palette.hero`, `Palette.seats[0]`, `Palette.button…`). That's 31 originals, 5 seats and 16 button colours. **Shipped**: Hall is the app's default (`Direction.hall` in `ios/Homer/UI/Tokens.swift`), and the other two modes stay selectable in code.

### Page "Home · Directions" (Fri Oct 23, 23:45 – Sat 00:10)

https://www.figma.com/design/qyaXnV3HbIUPIfYVbyqKwv/?node-id=0-1

| Node | What it is | Shipped or dropped, and why |
|---|---|---|
| [3-2](https://www.figma.com/design/qyaXnV3HbIUPIfYVbyqKwv/?node-id=3-2) Icons | 10 icon components taken from Matus's concept: feather (×3), arrow-right, chevron-right, scan-text, swords, book-open, arrow-up-right and library | **Shipped**: in `ios/Homer/UI/Art.xcassets`, stored as template images so each direction tints them |
| [4-24](https://www.figma.com/design/qyaXnV3HbIUPIfYVbyqKwv/?node-id=4-24) Mode row | Component: symbol, description and chevron | **Shipped**: `ModeRowView` in `HomeView.swift` |
| [4-45](https://www.figma.com/design/qyaXnV3HbIUPIfYVbyqKwv/?node-id=4-45) Tab item | Component set, Selected = Yes / No | **Shipped**: `HomeTabBar` in `HomeView.swift` |
| [5-10](https://www.figma.com/design/qyaXnV3HbIUPIfYVbyqKwv/?node-id=5-10) Home — Atelier | Matus's concept home, rebuilt as editable layers bound to the variables, in mode Atelier | **Shipped** as the app's look from Fri night through build 31. Hall replaced it as the default in build 32 (Sat 21:06) |
| [5-116](https://www.figma.com/design/qyaXnV3HbIUPIfYVbyqKwv/?node-id=5-116) Home — Cut paper | The same frame in mode Cut paper, the first art pass: dark sea, Fraunces, ink slabs | **Dropped**: the clickable prototype (Sat 08:40) and every screen after it went with Atelier, then Hall. It's still a mode and `Direction.cutPaper` |
| [5-168](https://www.figma.com/design/qyaXnV3HbIUPIfYVbyqKwv/?node-id=5-168), [5-171](https://www.figma.com/design/qyaXnV3HbIUPIfYVbyqKwv/?node-id=5-171) | Text labels above the two homes ("Atelier", "Cut paper") | Labels only |

### Page "App renders (reference)" (Fri Oct 23, 23:53)

https://www.figma.com/design/qyaXnV3HbIUPIfYVbyqKwv/?node-id=5-220

Simulator renders of the real SwiftUI app (iPhone 17) in two directions: 8 screens × 2 = **16 frames**, each 300 × 652. They're images, not editable layers. **Reference**: the side-by-side that settled the direction. The Atelier row became the app; the Cut paper row was **dropped** (see 5-116). Two renders caught the simulator mid-launch and were re-shot.

| Screen | Atelier | Cut paper |
|---|---|---|
| 1 Home | [5-236](https://www.figma.com/design/qyaXnV3HbIUPIfYVbyqKwv/?node-id=5-236) | [5-228](https://www.figma.com/design/qyaXnV3HbIUPIfYVbyqKwv/?node-id=5-228) |
| 2 First open | [5-221](https://www.figma.com/design/qyaXnV3HbIUPIfYVbyqKwv/?node-id=5-221) | [5-229](https://www.figma.com/design/qyaXnV3HbIUPIfYVbyqKwv/?node-id=5-229) |
| 3 Turn (phone) | [5-222](https://www.figma.com/design/qyaXnV3HbIUPIfYVbyqKwv/?node-id=5-222) | [5-230](https://www.figma.com/design/qyaXnV3HbIUPIfYVbyqKwv/?node-id=5-230) |
| 4 Verdict | [5-223](https://www.figma.com/design/qyaXnV3HbIUPIfYVbyqKwv/?node-id=5-223) | [5-231](https://www.figma.com/design/qyaXnV3HbIUPIfYVbyqKwv/?node-id=5-231) |
| 5 Carved line | [5-224](https://www.figma.com/design/qyaXnV3HbIUPIfYVbyqKwv/?node-id=5-224) | [5-232](https://www.figma.com/design/qyaXnV3HbIUPIfYVbyqKwv/?node-id=5-232) |
| 6 Event menu | [5-225](https://www.figma.com/design/qyaXnV3HbIUPIfYVbyqKwv/?node-id=5-225) | [5-233](https://www.figma.com/design/qyaXnV3HbIUPIfYVbyqKwv/?node-id=5-233) |
| 7 Lobby and entrance | [5-226](https://www.figma.com/design/qyaXnV3HbIUPIfYVbyqKwv/?node-id=5-226) | [5-234](https://www.figma.com/design/qyaXnV3HbIUPIfYVbyqKwv/?node-id=5-234) |
| 8 Champion | [5-227](https://www.figma.com/design/qyaXnV3HbIUPIfYVbyqKwv/?node-id=5-227) | [5-235](https://www.figma.com/design/qyaXnV3HbIUPIfYVbyqKwv/?node-id=5-235) |

The page also holds the title "MeNIN · two directions, same components" ([5-237](https://www.figma.com/design/qyaXnV3HbIUPIfYVbyqKwv/?node-id=5-237)) and row labels (5-238 to 5-250).

### Page "Prototype · Atelier" (Sat Oct 24, 08:40–09:10)

https://www.figma.com/design/qyaXnV3HbIUPIfYVbyqKwv/?node-id=13-102. It has 16 nodes with prototype interactions. The flows:

- ★ Flow 1, "1 · First open → Practice": https://www.figma.com/proto/qyaXnV3HbIUPIfYVbyqKwv?node-id=15-102&starting-point-node-id=15%3A102
- ★ Flow 2, "2 · Battle: join → arena → champion": https://www.figma.com/proto/qyaXnV3HbIUPIfYVbyqKwv?node-id=15-364&starting-point-node-id=15%3A364
- **Removed Sun 01:10: a duplicate starting point** on 29-320 with the same name as flow 2. It had been copied along with the frame for the Hall flip test, so the prototype's flow menu listed "2 · Battle" twice. Only the starting point went; the frame stays. Now the page has exactly two flows. Flow 2 still starts on 15-364 and runs Join → Arena · turn → carved line → champion (traced through its interactions), and its public link and embed respond (HTTP 200).

| Node | What it is | Shipped or dropped, and why |
|---|---|---|
| [13-103](https://www.figma.com/design/qyaXnV3HbIUPIfYVbyqKwv/?node-id=13-103) Prototype components | Chip (13-104); Button set (13-112: Primary, Secondary, Cream); Caption (13-113); Transcript (13-116); Formula chip (13-127: Default, Played, Whispered); Scene (13-148: Rest, Longing, Awe, Joy, Defiance), stills of the Metal scene painted as matte layered paper | All Atelier, all bound to the variables. The **Button set was superseded** in Hall by the button system (48-215). The **painted Scene was dropped** for real renders of the scene code (21:03), because its inks are hard-coded: it's the one fill that didn't flip to Hall |
| [15-102](https://www.figma.com/design/qyaXnV3HbIUPIfYVbyqKwv/?node-id=15-102) 1 · First open | Flow 1 start | Prototype |
| [15-135](https://www.figma.com/design/qyaXnV3HbIUPIfYVbyqKwv/?node-id=15-135) 2 · Event menu | | Prototype |
| [15-172](https://www.figma.com/design/qyaXnV3HbIUPIfYVbyqKwv/?node-id=15-172) 3 · Home · Poetry | The token-bound concept home | Prototype |
| [15-224](https://www.figma.com/design/qyaXnV3HbIUPIfYVbyqKwv/?node-id=15-224) 4 · Practice turn | | Prototype |
| [15-270](https://www.figma.com/design/qyaXnV3HbIUPIfYVbyqKwv/?node-id=15-270) 5 · Verdict | | Prototype |
| [15-364](https://www.figma.com/design/qyaXnV3HbIUPIfYVbyqKwv/?node-id=15-364) 6 · Join | Flow 2 start | Prototype |
| [16-193](https://www.figma.com/design/qyaXnV3HbIUPIfYVbyqKwv/?node-id=16-193) 7 · Arena · turn | Laptop size, 1440 × 900 | Prototype. The real arena is the website |
| [16-264](https://www.figma.com/design/qyaXnV3HbIUPIfYVbyqKwv/?node-id=16-264) 8 · Arena · carved line | 1440 × 900 | Prototype |
| [16-310](https://www.figma.com/design/qyaXnV3HbIUPIfYVbyqKwv/?node-id=16-310) 9 · Arena · champion | 1440 × 900 | Prototype |
| [29-226](https://www.figma.com/design/qyaXnV3HbIUPIfYVbyqKwv/?node-id=29-226) 5 · Verdict → Hall | Flip test (Sat 20:50): the Verdict frame duplicated and set to mode Hall. **72 of 73** bound fills flipped | Test. The deck uses the cleaner side by side, 36-128 |
| [29-320](https://www.figma.com/design/qyaXnV3HbIUPIfYVbyqKwv/?node-id=29-320) 6 · Join → Hall | The same test on Join: **8 of 9** flipped | Test. Its duplicate starting point was removed Sun 01:10 |

### Page "Hall · Reskin" (Sat Oct 24, 20:48–21:23)

★ https://www.figma.com/design/qyaXnV3HbIUPIfYVbyqKwv/?node-id=30-102. Every phone frame has a full-bleed "Scene · render" rectangle behind it (40-142 to 40-154): a real render of the website's scene code with the app's values.

| Node | What it is | Shipped or dropped, and why |
|---|---|---|
| [48-215](https://www.figma.com/design/qyaXnV3HbIUPIfYVbyqKwv/?node-id=48-215) Hall/Button system | Component set, 12 variants: Primary, Secondary, Tertiary and Destructive × Default, Pressed and Disabled, with properties Label and Icon. Bound to 16 button variables | **Shipped** in build 34 (`HomerButtonStyle`). Matus had called the old buttons "generic and boring" |
| ★ [48-216](https://www.figma.com/design/qyaXnV3HbIUPIfYVbyqKwv/?node-id=48-216) Hall · Buttons | The sheet: every variant over the scene, plus a 440-wide phone action area and the spec line | **Approved** by Matus about 21:35. Arimo Bold stands in for Helvetica Neue, which Figma doesn't serve |
| [30-103](https://www.figma.com/design/qyaXnV3HbIUPIfYVbyqKwv/?node-id=30-103) Hall components | Hall/Button (30-104), Phrase (30-106, 6 instances), Chip (30-108, 9), Loading (30-110, 2) | Phrase, Chip and Loading **shipped** as specs. **Hall/Button 30-104 was dropped** at 21:23: the button system replaced it and **0 instances** are left |
| [31-102](https://www.figma.com/design/qyaXnV3HbIUPIfYVbyqKwv/?node-id=31-102) Join · SE | 375 × 667 | **Shipped** (build 32 on) |
| ★ [31-179](https://www.figma.com/design/qyaXnV3HbIUPIfYVbyqKwv/?node-id=31-179) Join · Pro Max | 440 × 956, "blue at rest" | **Shipped** |
| [34-233](https://www.figma.com/design/qyaXnV3HbIUPIfYVbyqKwv/?node-id=34-233) Join · SE · keyboard up | With a 260 pt stand-in keyboard, added after pm's review | **Shipped** (the fit check) |
| [34-128](https://www.figma.com/design/qyaXnV3HbIUPIfYVbyqKwv/?node-id=34-128) Turn · SE | The ring beside SPEAK, the "Stuck?" line, live words. Holds the mid-shoot render | **Shipped** |
| ★ [34-179](https://www.figma.com/design/qyaXnV3HbIUPIfYVbyqKwv/?node-id=34-179) Turn · Pro Max | "Colours on voice", mid-shoot | **Shipped** (build 34) |
| [32-114](https://www.figma.com/design/qyaXnV3HbIUPIfYVbyqKwv/?node-id=32-114) Wait · SE | | **Shipped** |
| [32-294](https://www.figma.com/design/qyaXnV3HbIUPIfYVbyqKwv/?node-id=32-294) Wait · Pro Max | | **Shipped** |
| [32-144](https://www.figma.com/design/qyaXnV3HbIUPIfYVbyqKwv/?node-id=32-144) Verdict · battle · SE | Image / Answer / Craft scores; Inter numerals | **Shipped** |
| [32-324](https://www.figma.com/design/qyaXnV3HbIUPIfYVbyqKwv/?node-id=32-324) Verdict · battle · Pro Max | | **Shipped** |
| [32-247](https://www.figma.com/design/qyaXnV3HbIUPIfYVbyqKwv/?node-id=32-247) Arrow pad · camera · SE | The archery phone with a camera aim | **Shipped** |
| [32-427](https://www.figma.com/design/qyaXnV3HbIUPIfYVbyqKwv/?node-id=32-427) Arrow pad · camera · Pro Max | | **Shipped** |
| [35-248](https://www.figma.com/design/qyaXnV3HbIUPIfYVbyqKwv/?node-id=35-248) Arrow pad · camera · SE · held | The pressed state | **Shipped** |
| ★ [36-128](https://www.figma.com/design/qyaXnV3HbIUPIfYVbyqKwv/?node-id=36-128) Flip · Atelier → Hall | One Verdict frame twice; only the mode differs. Inside the Hall copy, the painted Scene (36-223) is **hidden** and a render (40-154) sits over it | **For the deck** |

**What isn't on this page any more (reworked in place):**

- **The first pass of the Hall frames** (Sat 20:53). They drew what a turn should show rather than what the app does: 5 axes, "Round 2 of 3" and no countdown ring. They were rebuilt to the app after pm's two review rounds (7 blocking fixes, 10 notes), and pm approved both batches by 21:01. The old version is only in version history.
- **A vector stand-in for the scene** behind the first frames. It was replaced by real renders at 21:03.
- **Background rounds 1–4** (21:03–21:20). Each round replaced the image fill on the same 13 "Scene · render" rectangles, so Figma now shows only round 4. Every round's render is in the repo at `docs/figma/scrap/` (section 3a):
  1. "keep the cool wavy white background … and maybe even throw in a mix of cool blue": wavy white plus cool blue, at rest. **Kept** as the rest.
  2. "the background behind the poetry battle that shoots colors": a voice washing colour through the sea. **Kept** as the voice.
  3. "I just want the BLUE shooting there": the voice in blues only. **Shipped in build 33** because the archive couldn't wait, then **dropped**.
  4. **"blue at rest, colours on voice"** ("I LOVE the background"): rest from 1, voice from 2, with the tilt flipped so the blue gathers low behind the cards (ink on the blue streak measured 4.1:1). **Shipped in build 34**, and it's what the frames show now.

### Page "App icon" (Sat Oct 24, 21:34–22:16)

★ https://www.figma.com/design/qyaXnV3HbIUPIfYVbyqKwv/?node-id=51-102

| Node | What it is | Shipped or dropped, and why |
|---|---|---|
| [51-103](https://www.figma.com/design/qyaXnV3HbIUPIfYVbyqKwv/?node-id=51-103) App icon · A · Rising M | Sea-ink Bodoni M rising out of the rest scene: the Atelier icon's idea in Hall colours | **Dropped**: at 40 pt Bodoni's hairline left stem thins out |
| [51-106](https://www.figma.com/design/qyaXnV3HbIUPIfYVbyqKwv/?node-id=51-106) App icon · B · Voice | The same M over a voice shooting colour | **Dropped**, for the same hairline problem |
| [51-109](https://www.figma.com/design/qyaXnV3HbIUPIfYVbyqKwv/?node-id=51-109) App icon · C · Key | A white M on the button system's pressable key | **Picked** by Matus at 21:38 and sent to swift for build 35. **Replaced** at 22:16 by μ |
| ★ [54-142](https://www.figma.com/design/qyaXnV3HbIUPIfYVbyqKwv/?node-id=54-142) App icon · C · Key · μ | μ (from μῆνιν, the Iliad's first word) on the same key, set in Noto Serif Display Black and centred by its ink, not its text box | **The shipped icon** (sent to swift for build 41) |
| ★ [51-114](https://www.figma.com/design/qyaXnV3HbIUPIfYVbyqKwv/?node-id=51-114) Home screen · real sizes | All four icons at 180, 120, 60 and 40 pt in the iOS mask, on a dark and a light strip, built from instances | The test that ruled out A and B |
| [53-142](https://www.figma.com/design/qyaXnV3HbIUPIfYVbyqKwv/?node-id=53-142) μ face test | Five Greek-capable faces, white on the key's blue, at 220 px and 40 pt: Noto Serif Display Black and ExtraBold, Literata Black, Playfair Display Black, EB Garamond ExtraBold | **Noto Serif Display Black won**: a Didone like Bodoni, with a solid tail at 40 pt. Bodoni Moda has no Greek. Playfair was too curly and Garamond too thin |

## 2. Every other Figma file

| File | Link | What it is | Status |
|---|---|---|---|
| **MeNIN user interface concept art** (Matus, Design) | https://www.figma.com/design/zBILNwJB2NaVofBNJouAOW | Matus's first concept, the earliest Figma work. One page with one top-level frame: **"Homer · Atelier"** ([46-378](https://www.figma.com/design/zBILNwJB2NaVofBNJouAOW/?node-id=46-378)), a 402 × 945 home: cream #F7F3EC, Bodoni Moda, Inter, wine #682C3E, hairline cards, Lucide icons and an engraved Homer portrait | **The origin of Atelier.** Read through the MCP on Fri 23:40 and turned into the Atelier mode and `HomeView.swift`. Its icons and portrait are in the app's asset catalog. Figma's public oEmbed check returns 200 (Sun 01:08), so the link should open logged out; Matus's Share dialog is the final word |
| ★ **MeNIN · Stage log (Figma track)** (Slides) | https://www.figma.com/slides/oYPLd3JeIjhnkNyt75qfOm | The ten-slide deck, drafted Sat 17:40 | Matus still has to add the live embeds and the sharing |
| ★ **MeNIN · Discus (Make)** | https://www.figma.com/make/MexcUVEohKsNVAw5pHh596 | A Make file seeded with the discus phone and arena on our tokens (Sat 09:00–09:15) | Make's own AI was never prompted: the MCP can import into Make but can't prompt it |
| Figma's example stage-log deck | https://www.figma.com/slides/hViyGFvaHxTBqzYKkaYPho | Figma's own template from the track brief | **Not ours**. Listed only because `tracks.md` cites it |
| The website's original Figma Make app | https://www.figma.com/make/0o7GzG4KEQejktGJeUuNbt/MeNIN | The Make app the website began as, committed at 12:33 PM Sat | Found in Sunya's stage-log deck (leader, Sun ~3:25 AM). Matus confirms it's shared "Anyone with the link" |

No FigJam boards were made. No other Figma file key appears in the repo or in any session's transcript.

## 3. Scrap: renders, exports and round shots

### 3a. In the repo: `docs/figma/scrap/` (27 small previews, 3.9 MB)

The four background rounds round by round, the icon backgrounds and options (including the failed gold render), and the deck stand-ins. `docs/figma/scrap/README.md` maps each file to its round and says whether it shipped or was dropped. Nothing in it comes from a phone or a camera. Copied Sun 01:11.

| Repo file (`docs/figma/scrap/`) | Full-size original, local only | Full size |
|---|---|---|
| round0-reference-website-rest.png | `/private/tmp/claude-501/-Users-matus-dev-projects-MeNIN/cdc82907-34ad-4765-ad09-633b214734fb/scratchpad/scenetest/` → web.png | the same file (450×300) |
| round1-probe-blue-7FBCD6.png, round1-probe-blue-5FAACB.png | `/private/tmp/claude-501/-Users-matus-dev-projects-MeNIN/cdc82907-34ad-4765-ad09-633b214734fb/scratchpad/scenetest/` → blueA.png, blueB.png | the same files (450×300) |
| round1-probe-lift-0.06.png, round1-probe-lift-0.02.png, round1-probe-lift-minus-0.02.png | `/private/tmp/claude-501/-Users-matus-dev-projects-MeNIN/cdc82907-34ad-4765-ad09-633b214734fb/scratchpad/scenetest/` → b_l06.png, b_l02.png, b_lm02.png | the same files (450×300) |
| round1-rest-phone.png | `/private/tmp/claude-501/-Users-matus-dev-projects-MeNIN/cdc82907-34ad-4765-ad09-633b214734fb/scratchpad/scenetest/` → hall_portrait.png | 880×1912, 1.4 MB |
| round2-shoot-joy.png, round2-shoot-longing.png | `/private/tmp/claude-501/-Users-matus-dev-projects-MeNIN/cdc82907-34ad-4765-ad09-633b214734fb/scratchpad/scenetest/` → shoot_joy.png, shoot_long.png | 880×1912, 1.5 MB each |
| round3-mono-joy.png, round3-mono-anger.png | `/private/tmp/claude-501/-Users-matus-dev-projects-MeNIN/cdc82907-34ad-4765-ad09-633b214734fb/scratchpad/scenetest/` → mono_joy.png, mono_anger.png | 880×1912, 1.5 MB each |
| round4-final-rest.png, round4-final-voice.png | `/private/tmp/claude-501/-Users-matus-dev-projects-MeNIN/cdc82907-34ad-4765-ad09-633b214734fb/scratchpad/scenetest/` → base2.png, shoot2.png | 880×1912, 1.4 and 1.5 MB |
| icon-bg-rest.png, icon-gold-failed.png | `/private/tmp/claude-501/-Users-matus-dev-projects-MeNIN/cdc82907-34ad-4765-ad09-633b214734fb/scratchpad/scenetest/` → icon_rest.png, icon_shoot.png | 1024², about 1 MB each |
| icon-bg-voice-0.45s.png, icon-bg-voice-0.65s-unused.png | `/private/tmp/claude-501/-Users-matus-dev-projects-MeNIN/cdc82907-34ad-4765-ad09-633b214734fb/scratchpad/scenetest/` → icon_shoot_a.png, icon_shoot_b.png | 1024², 1.1 MB each |
| icon-A-rising-m.png, icon-B-voice.png, icon-C-key.png, icon-mu.png | `/private/tmp/claude-501/-Users-matus-dev-projects-MeNIN/cdc82907-34ad-4765-ad09-633b214734fb/scratchpad/icons/` → A.jpg, B.jpg, C.jpg, mu.jpg | 1024², 640–762 KB each |
| deck-*.png (6) | `/private/tmp/claude-501/-Users-matus-dev-projects-MeNIN/cdc82907-34ad-4765-ad09-633b214734fb/scratchpad/deck/` → *.png | the same files (402 wide; the champion is 1440×900) |

### 3b. Full size, local only: the artist session's scratchpad

**These are on Matus's Mac under `/private/tmp`, which macOS clears on a restart, and they aren't in the repo.** The small previews in 3a are the copies that last.

**Background rounds and icon backgrounds** (small copies in 3a): `/private/tmp/claude-501/-Users-matus-dev-projects-MeNIN/cdc82907-34ad-4765-ad09-633b214734fb/scratchpad/scenetest/`. These are renders of the website's own WebGL scene code, run headless with the app's candidate values and a scripted voice (Sat 21:05–21:35). Files ending `_s` are small previews of the file before them.

| File | Size | Pixels | Time | What it is |
|---|---|---|---|---|
| web.png | 118.6 KB | 450×300 | 21:07 | The website's own rest scene, the reference everything was measured against |
| blueA.png | 121.2 KB | 450×300 | 21:05 | Round 1 probe: deepest ink #7FBCD6 |
| blueB.png | 123.6 KB | 450×300 | 21:06 | Round 1 probe: deepest ink #5FAACB, a deeper blue |
| b_l06.png | 122.1 KB | 450×300 | 21:07 | Round 1 sweep: blue bands lifted 0.06 |
| b_l02.png | 124.2 KB | 450×300 | 21:07 | Round 1 sweep: lift 0.02 |
| b_lm02.png | 127.0 KB | 450×300 | 21:07 | Round 1 sweep: lift −0.02 |
| b_l00.png, b_lm03.png | 1.0 KB each | 450×300 | 21:06 | **Failed renders** (blank): the harness bug with a missing semicolon |
| hall_portrait.png, hall_portrait_s.png | 1.4 MB, 227.6 KB | 880×1912, 322×700 | 21:08 | **Round 1** at phone size: rest, deepest ink #7AB6D0 (the value that shipped) |
| shoot_joy.png, shoot_joy_s.png | 1.5 MB, 252.5 KB | 880×1912, 322×700 | 21:09 | **Round 2**: a voice driving joy and awe, 1.3 s in |
| shoot_long.png, shoot_long_s.png | 1.5 MB, 258.9 KB | 880×1912, 322×700 | 21:09 | Round 2: a voice driving longing and tenderness |
| base2.png, base2_s.png | 1.4 MB, 180.8 KB | 880×1912, 276×600 | 21:12 | **The final rest**: tilt 0.45, so the blue gathers low. It's in every Hall frame except Turn |
| shoot2.png, shoot2_s.png | 1.5 MB, 195.2 KB | 880×1912, 276×600 | 21:12 | **The final voice** with the same tilt, made at 21:12 after round 2 and put back for round 4: it's in both Turn frames now |
| mono_joy.png, mono_joy_s.png | 1.5 MB, 190.9 KB | 880×1912, 276×600 | 21:15 | **Round 3 (dropped)**: "just the BLUE", joy in a blue-only ramp #2E8EB5 → #B8DCEA |
| mono_anger.png, mono_anger_s.png | 1.5 MB, 193.1 KB | 880×1912, 276×600 | 21:15 | Round 3 (dropped): anger and defiance in the same ramp |
| icon_rest.png, icon_rest_s.png | 965.6 KB, 183.9 KB | 1024², 400² | 21:35 | The rest background used in the icons (A, and under the key in C and μ) |
| icon_shoot.png, icon_shoot_s.png | 1.1 MB, 224.9 KB | 1024², 400² | 21:35 | **Failed**: captured too late in the wash, so the whole square went gold |
| icon_shoot_a.png, icon_shoot_a_s.png | 1.1 MB, 130.1 KB | 1024², 300² | 21:35 | The re-render 0.45 s into the shot (joy and awe), used for icon B |
| icon_shoot_b.png, icon_shoot_b_s.png | 1.1 MB, 129.1 KB | 1024², 300² | 21:35 | An alternative at 0.65 s (longing and joy), not used |

The same folder also holds the harness (`app.js`, `entry.ts`, `cdp.mjs`, `index.html`) and a headless Chrome profile (`profile/`, which is junk).

**Icon exports from Figma**: `/private/tmp/claude-501/-Users-matus-dev-projects-MeNIN/cdc82907-34ad-4765-ad09-633b214734fb/scratchpad/icons/`. These are the raw `get_screenshot` exports. The `.png` files carry alpha, and the `.jpg` files are the round-trip that dropped it. The clean sRGB finals are in the repo at `docs/design/app-icon/`.

| File | Size | Pixels | Time |
|---|---|---|---|
| A.png, A.jpg, A_s.png | 1.0 MB, 684.7 KB, 149.8 KB | 1024², 1024², 360² | Sat 21:37 |
| B.png, B.jpg | 1.1 MB, 761.8 KB | 1024² | 21:37 |
| C.png, C.jpg, C_s.png | 864.2 KB, 654.2 KB, 136.5 KB | 1024², 1024², 360² | 21:37 |
| mu.png, mu.jpg, mu_s.png | 863.3 KB, 640.0 KB, 94.6 KB | 1024², 1024², 300² | 22:16 |

**Prototype frames exported for the deck**: `/private/tmp/claude-501/-Users-matus-dev-projects-MeNIN/cdc82907-34ad-4765-ad09-633b214734fb/scratchpad/deck/` (Sat 17:28), made for the deck draft.

| File | Size | Pixels |
|---|---|---|
| home-atelier.png | 69.7 KB | 402×944 |
| home-cut.png | 71.9 KB | 402×930 |
| p1-first-open.png | 45.2 KB | 402×874 |
| p4-practice.png | 57.0 KB | 402×874 |
| p5-verdict.png | 48.8 KB | 402×874 |
| p9-champion.png | 107.0 KB | 1440×900 |

**Atelier and Cut paper app icons**: `/private/tmp/claude-501/-Users-matus-dev-projects-MeNIN/cdc82907-34ad-4765-ad09-633b214734fb/scratchpad/HomerLab/icon/` (Sat 09:01). AppIcon-atelier-1024.png (845.9 KB) and AppIcon-cutPaper-1024.png (870.3 KB) are already in `docs/design/app-icon/`. The previews pa.png (71.3 KB, 300²), pc.png (76.5 KB, 300²) and t.jpg (143.3 KB, 1024²) are not.

**Make seed**: `/private/tmp/claude-501/-Users-matus-dev-projects-MeNIN/cdc82907-34ad-4765-ad09-633b214734fb/scratchpad/make-discus/index.html`, the static discus sketch that was imported into the Make file.

### 3c. Full size, local only: the artist session's other art scrap (simulator and browser checks, not Figma)

All of these are under `/private/tmp/claude-501/-Users-matus-dev-projects-MeNIN/cdc82907-34ad-4765-ad09-633b214734fb/scratchpad/`.

| Folder | Files | Size | When (Sat) | What it is |
|---|---|---|---|---|
| HomerLab/shots/ | 103 JPG + 21 MOV | 647.0 MB (the MOVs are 21–87 MB each) | 01:45–14:26 | Simulator stills and screen recordings from the Saturday-morning scene and layout passes (`before-*`, `after-*`, `re-*`, `s-*`, `hall.mov`, `fit*`, `ph*`, `arr*`, `type*`) |
| HomerLab/fire/ | 52 JPG | 6.0 MB | 11:08–12:44 | 300×225 frames from the type-size check at 2 m (`2m-before-*`, `2m-after-*`) |
| HomerLab/fit/ | 21 JPG | 1.7 MB | 12:52–12:54 | SE fit pass: `e-*`, `exl-*` (323×700) and contact sheets `sheet1–4` (1316×700) |
| fit2/ | 93 JPG | 6.4 MB | 13:50–14:28 | Second fit pass, every screen at SE, 390 and Pro Max (`after-{se,390,max}-*`) |
| web/ | 9 JPG | 1.6 MB | 14:51–16:52 | Website contact sheets, 1990×560: the sea, cues, the coach |
| tox/ | 5 PNG | 1.1 MB | 18:37–19:22 | Archery: the done layout at 1440 and 390, the aim page, scene options |
| coachprev/ | 2 PNG | 188.4 KB | 17:27–19:05 | Talk to Homer reply card |
| boxv2/, boxprev/ | 1 PNG; 6 SVG + 6 PNG + 1 JPG | 263.8 KB; 151.3 KB | 17:09–18:06 | Boxing poses and scene options |
| stadion/ | 4 SVG, 4 PNG, 2 JPG sheets | 99.6 KB | 16:56–16:57 | Stadion runner figures |
| laurel.svg | 1 | 1.3 KB | 14:33 | Laurel glyph |

### 3d. Local only: other sessions' scratchpads

These belong to the other sessions; ask the owner before using anything here.

| Owner | Folder | Files | Size | When | What it is |
|---|---|---|---|---|---|
| swift | `/private/tmp/claude-501/-Users-matus-dev-projects-MeNIN/2ad722dd-4ba3-4bf9-a094-3e6eeba175bb/scratchpad/shots/` | 27 | 39.7 MB | Sat 20:51–21:01 | Simulator shots of the Hall tokens going in (build 32) |
| swift | `…/2ad722dd-4ba3-4bf9-a094-3e6eeba175bb/scratchpad/se-renders/` (+ `small/`) | 22 + 22 | 15.2 MB + 4.2 MB | Sat 21:10–21:29 | SE renders of the Hall build: home, menu, join, turn (incl. worst case), arrow pad, result |
| swift | `…/2ad722dd-4ba3-4bf9-a094-3e6eeba175bb/scratchpad/` (top level) | 6 | 870.2 KB | Sat | icon-c-small.png, icon-mu-small.png and 4 `mp-*.png` |
| builder | `/private/tmp/claude-501/-Users-matus-dev-projects-MeNIN/420b4cd7-2c7a-4d88-a723-026d5d5d44f5/scratchpad/browser/shots/` | 220 | 105.7 MB | Sat 14:53 – Sun 01:00 | Website screenshots from every check |
| builder | `…/420b4cd7-2c7a-4d88-a723-026d5d5d44f5/scratchpad/browser/ref/` | 3 | 2.1 MB | Sat 20:49 | Website references for the Hall token sheet |
| builder | `…/420b4cd7-2c7a-4d88-a723-026d5d5d44f5/scratchpad/hall-tokens/` | 4 | 2.7 MB | Sat 20:57 | The same four as `docs/hall-tokens/` |
| leader | `/private/tmp/claude-501/-Users-matus-dev-projects-MeNIN/9814bc16-d39c-40ed-a917-8cf83d8801c1/scratchpad/figma/turn.png` | 1 | 270.1 KB | Sat 21:17 | A Turn frame, saved during the background rounds |
| multiplayer | `/private/tmp/claude-501/-Users-matus-dev-projects-MeNIN/a25f5442-b6f4-48e4-b3bd-5e7b60a688c3/scratchpad/browser/shots/` | 13 | 5.3 MB | Sat 18:44–18:49 | Website screenshots |

### 3e. Already in the repo, outside `docs/figma/`

- `docs/design/app-icon/`: AppIcon-atelier-1024.png (866 KB), AppIcon-cutPaper-1024.png (891 KB), AppIcon-hall-A-1024.png (1.28 MB), AppIcon-hall-B-1024.png (1.36 MB), AppIcon-hall-C-1024.png (1.13 MB) and AppIcon-hall-mu-1024.png (1.13 MB). The Hall ones are exports of 51-103, 51-106, 51-109 and 54-142.
- `docs/hall-tokens/`: 1-menu.png (777 KB), 2-lobby.png (627 KB), 3-poetry-turn.png (646 KB) and 4-verdict.png (784 KB). These are builder's website captures behind the Hall token sheet `docs/hall-tokens.md`.
