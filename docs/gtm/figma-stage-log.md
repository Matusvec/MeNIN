# Figma stage log

This log is the main thing Figma judges. Prizes: **Best Stage Log, $2,000** ("the clearest, most repeatable workflow of how a project was built"), **Best Figma Workflow, $2,000**, Best Design $500, Most Creative $500. Every winner also gets a session with Figma's Early Career Recruiter.

**Owner: artist session + Matus. Append entries as you work and never rewrite old ones.** Judges reward a log that is "honest about friction" and that records rework and dead ends, so keep those in.

## What Figma requires (from the official track doc)

- [ ] **Everyone on the team is Edu verified**: https://www.figma.com/education/apply
- [ ] **Figma Slides** deck (required) showing the work and the workflow. Drafted by the artist session through the Figma MCP (Sat 17:40), ten slides on tracks.md's plan, for Matus to edit: https://www.figma.com/slides/oYPLd3JeIjhnkNyt75qfOm. Still to do: Matus sets sharing to Anyone with the link → can view.
  - [x] Stage log in the deck: which Figma product we used and why, **200 words max per stage** (slides 4–7, one per stage, each with its entries, minutes, rating, what made it in and the friction)
  - [ ] Demo video, **3 min max** (our 2-minute video works)
  - [x] **A prototype exists to embed:** the "Prototype · Atelier" page in "MeNIN · Directions", with two flows (artist, Sat 08:40–09:10), both Anyone can view:
    - Flow 1, first open → event menu → Poetry → Practice turn → verdict: https://www.figma.com/proto/qyaXnV3HbIUPIfYVbyqKwv?node-id=15-102&starting-point-node-id=15%3A102
    - Flow 2, join → arena turn → carved line → champion: https://www.figma.com/proto/qyaXnV3HbIUPIfYVbyqKwv?node-id=15-364&starting-point-node-id=15%3A364
  - [ ] The prototype and the Directions file embedded in the deck, plus the repo link (it works once the repo goes public Sun 8 AM). Slides 8–10 show the real frames, with links to both flows, the Directions file and the repo. **The live embeds are required** ("Must embed your Figma files (Make(s) and/or Figma prototypes)") and are Matus's step in the Slides app: the Plugin API has no way to create an embed. Paste each prototype link onto slide 8 and the Directions link onto slide 9.
- [x] "MeNIN · Directions" shared as **Anyone with the link → can view** (Matus, Sat AM): https://www.figma.com/design/qyaXnV3HbIUPIfYVbyqKwv
- [ ] Any new Figma file (the deck, a FigJam diagram) also shared with "Anyone"
- [ ] Figma tagged on Devpost
- [ ] Booth #35 for the activation, Sat 10 AM to 2 PM; bring proof of Edu verification

## What they score

From the track doc, in their words:

- **Workflow Design**: "Is there a clear path from idea to demo... Are tools chosen on purpose... Could another team follow this process without the builder in the room?"
- **Adoptability**: "Does it remove real friction, with a measurable before and after (time saved, steps cut, fewer rounds of rework)?"
- **Output Quality**: "Does the demo work and do what the team says it does?"
- **Presentation / Pitch**
- **Innovation & Creativity**

"We're not judging on scope or technical difficulty. We care most about a clear problem, an honest account of how you built it and a demo that works."

## Our story

**"Don't treat the Figma as the ground truth. Use the power of Figma to make it better. Don't assume one way is good or not."** That was Matus to the artist session at 23:50 on Friday. The agent had just read his concept frame through the Figma MCP and started copying it over the work it had already done. His correction set the whole workflow: Figma is a tool for comparing ideas, not a spec to transcribe. AI is a creative partner, and the designer keeps the point of view.

What that looks like in practice. MeNIN is built by two designers (Matus designed the app; our web designer, a teammate, made the website in Figma Make) and a team of Claude Code sessions: leader, pm, artist, swift, multiplayer, builder, gtm.

1. **Two directions, one vocabulary.** The artist session put both looks into one Figma variable collection with two modes: **Atelier** (Matus's concept: cream, Bodoni Moda, wine) and **Cut paper** (the first art pass: a dark sea, Fraunces, ink slabs). Every variable carries its Swift name as code syntax, and the app reads the same tokens through one `Direction` switch. Flipping a frame's mode in Figma and flipping the launch flag in the app show the same thing.
2. **Editable designs, not screenshots.** Matus's home frame was rebuilt as token-bound components. A clickable prototype covers both flows (first open to practice, and battle: join → arena → champion).
3. **Figma Make as a sparring partner.** The live discus screens were seeded into a Make file on the same tokens. Make's AI explores variations; the agent reads the chosen one back through the MCP and ports it to SwiftUI.
4. **Honest log.** Every stage below lists what broke and what was redone.

That handoff is the reusable part. Another team could run the same setup on a different idea.

Before and after numbers to capture for Adoptability: minutes from a Figma frame to a working component, the number of rework rounds, and the number of times the design and the code disagreed.

## Sat night: one hall, two codebases, one set of variables

*gtm writes this from the sessions' entries below; the numbers in brackets are filled from them. SPEC `6144b56` (Matus, Sat 8:40 PM: "now it's about polish").*

**The problem.** By Saturday afternoon MeNIN had two front ends that didn't look like one product. The website, the big screen everyone sees, began as a **Figma Make app** that our web designer built and committed at 12:33 PM. It kept its own art and palette: Aegean blues, creams, a flowing white scene. The iPhone app wore **Atelier**: cream, Bodoni and wine. The 12:36 PM handoff between them was a CSS reference file (`docs/design/atelier-tokens.css`). It shared the seat colors and the type scale, but not the look. We rated it 3 of 5, because nothing kept the two in sync.

**What we did.** Matus asked for the app to "match the color scheme on the website, like the blue". The team ran it through the Figma variables we already had, not through code:
1. **builder** pulled the website's real tokens out of its CSS (`homer/web/src/index.css`, `wired.css`) in 15 minutes, with Claude Code (a CSS scan plus headless Chrome), not Figma. **The website had no color variables at all.** 128 distinct hard-coded colors became 37 named color tokens. 69 type values became 16 type roles on 2 families, and 17 radii became 8 radius tokens. The 73 spacing values were left as they are. The sheet is `docs/hall-tokens.md`.
2. **artist** added a third mode, **Hall**, to the "MeNIN" collection in "MeNIN · Directions". It sits beside Atelier and Cut paper, and every variable keeps its Swift name. All 36 variables got Hall values: the 31 existing ones plus 5 new seat variables. That took 5 minutes, plus a 3-minute contrast round. Then artist laid out the frames that change, with more of the flowing scene behind them: 12 frames in 8 minutes: 5 screens (join, a turn, the wait, the verdict and the arrow pad), each on the SE and the Pro Max, plus keyboard-up and held states. **The flip test:** switching the Verdict frame to Hall flipped 72 of its 73 bound fills in one step, and 8 of 9 on Join. The one left in each is the painted scene art, whose inks are hard-coded. Side by side: https://www.figma.com/design/qyaXnV3HbIUPIfYVbyqKwv/?node-id=36-128 · the Hall page: https://www.figma.com/design/qyaXnV3HbIUPIfYVbyqKwv/?node-id=30-102
3. **swift** added `case hall` to the app's `Direction` switch (`ios/Homer/UI/Tokens.swift`), put in the Hall values, and shipped **build 32** (0.1.0, `202610242101`, uploaded 9:06 PM). It took 22 minutes from the agreed token table to the upload. Tokens.swift changed by +69/−36 lines, and only 5 view files outside it were touched, 1–9 lines each. **32 view files (119 views) took the new look with no edits, and no screen needed a hand-edited color.**

**Before → after (Adoptability).**
- Before (Sat 12:36 PM): matching the app to the website meant hand-copying values from a CSS file into Swift, screen by screen, with no record of which value came from where.
- After (Sat 9:06 PM, build 32 uploaded): one new mode in Figma and one new case in the app. Flipping a Figma frame to Hall shows the app's look before any code is written: 72 of 73 fills on the Verdict frame, in one step. In code, the whole-app reskin was +69/−36 lines of tokens plus 5 small view edits, in 22 minutes, with 3 rework rounds. [What the real-phone visual pass on build 33 finds.]

**Friction, kept honest.**
- The sync is still by convention, not live. A Figma change reaches Swift only when an agent re-reads the variables (the same limit as the Fri 23:39 entry).
- In Figma, the first pass of the Hall frames didn't match the real app and was rebuilt to it. pm's two review rounds raised 7 blocking issues and 10 notes, and artist caught 3 more fixes. The seat colors didn't match the website and were fixed before the build. Contrast took two rounds of computed ratios.
- The painted scene art doesn't follow the variables (its inks are hard-coded), so it was the one fill per frame that didn't flip.
- In code, 13 hard-coded colors are left (12 in the app-icon art, 1 shadow). There were 3 rework rounds: builder's sheet changed 6 values, the computed contrast ratios changed 3, and a grey system blur was dropped.
- **The values went into Swift by hand**, from a token table agreed in both directions. They weren't read back from Figma with `get_variable_defs`. That read-back is the cheap check to add next time.
- Step 1 was an audit, not a lookup: the Make-built website kept every color hard-coded (128 of them), so naming them took judgment, and the spacing (73 values) was too scattered to tokenize tonight.
- [What the real-phone visual pass on build 33 caught that the Figma frames didn't.]
- The website itself didn't change. It was already the reference, so this stage only moved the app.

**Why it's repeatable.** One variable collection, one mode per look, and every variable named after its code token. A third look cost one mode and one enum case, not a fork. Another team can copy exactly that.

### Deck text for Matus (one slide, 200 words max; Matus edits the deck)

**Slide: "One hall, two codebases"**
> Our big screen is a website that began in **Figma Make**. Our phone app is **SwiftUI**. By Saturday night they looked like two products.
>
> We already kept every design token in one Figma variable collection, each variable named after its Swift token, with one mode per look (Atelier, Cut paper). So the fix was a **third mode, Hall**:
> 1. Audit the website's CSS: 128 hard-coded colors became 37 named tokens. (15 min)
> 2. Add Hall to the variables (36, in 5 min) and lay out the changed frames in Figma first (12, in 8 min). Flipping a frame to Hall turned 72 of its 73 fills in one step.
> 3. Add one case to the app's `Direction` switch, and ship build 32. (22 min)
>
> **Before:** hand-copying values from a CSS file, screen by screen.
> **After:** one mode in Figma, one case in code. +69/−36 lines of tokens and 5 small view edits restyled 119 views. (22 min to build 32)
>
> **Friction:** the sync is by convention, not live: values went in by hand, not read back from Figma. 3 rework rounds. 13 hard-coded colors left. [what the real-phone pass caught]
>
> *Embed: the Atelier → Hall side by side (https://www.figma.com/design/qyaXnV3HbIUPIfYVbyqKwv/?node-id=36-128); a photo of build 32 next to the website. Live embeds need the Directions file shared "Anyone with the link → can view".*

## Log format

Figma's four stages are **Ideation, Prototyping, Handoff, Code generation**. Give each entry these fields:

```
### <Stage> · <what> · <Sat 10:40>
- Tool(s): Figma Design / Make / Figma agent / MCP / FigJam — and why this tool for this step
- Minutes: <n>
- Worked (1-5): <n>
- What made it into the project: <file, component, token, screen>
- Friction: <what broke, what we redid, what we abandoned>
```

## Entries

### Ideation · Project plan and spec · Fri Oct 23, evening
- Tool(s): TODO(Matus): say whether any Figma tool (FigJam or Design) was used for the idea, the moodboard or the palette. If none was, write "none; ideation happened in docs" and say so honestly.
- Minutes: TODO
- Worked (1-5): TODO
- What made it into the project: `Homer Cal Hacks 13.0 Project Plan.md`, `SPEC.md`, `docs/ux-flow.md` (the flow, states and screen inventory to design against)
- Friction: the plan's prize table and pitch length were wrong and were corrected from the Hacker Guide (see `docs/gtm/README.md`)

### Ideation · Scene look: from glow to matte · Fri Oct 23, 22:45
- Tool(s): none yet. The artist session planned the look in code and docs. Matus asked to work in his Figma account, but the session had no Figma connector, so no Figma file exists yet.
- Minutes: 15
- Worked (1-5): 4
- What made it into the project: the first plan was a glowing, neon-ember scene with bloom. Matus redirected it to "colorful but matte, open, simple". The scene became flat paper-cut ink layers: four inks per emotion, soft cast shadows between layers, lifted blacks, and paper grain. Particles became flat flecks instead of glowing embers. Mixed emotions are marbled into separate patches, not averaged into mud. The resting state is the "wine-dark sea" (wine, sea teal, parchment). The palettes now live in code (`Moods.swift`).
- Friction: one plan discarded before any pixels shipped. Missing Figma connector: the palette exists only in code until the connector is set up, which breaks our "Figma is the source of truth" story for now. Once it's connected, the inks need to go into Figma as color styles.

### Prototyping · Platform pivot: web to iOS · Fri Oct 23, 23:00
- Tool(s): none (code). The artist session built a React + Three.js + GLSL scene and a `/dev/scene` lab with sliders and a mic toggle.
- Minutes: 35
- Worked (1-5): 2. Complete, but never run.
- What made it into the project: the shader math and the palette and motion tables, which carry over to Metal almost line for line. The web code itself is abandoned (`web/`, left for the leader to remove).
- Friction: the team chose iOS-only (SwiftUI + Metal) mid-build, so the web scaffold, React lab, and Web Audio pitch detector are dead ends. Lesson for the log: lock the platform before the art lead writes renderer code. One more process note: an agent can hold its renderer work in pure math tables, so a platform switch costs only the glue.

### Prototyping · Scene in Metal, tested on the simulator · Fri Oct 23, 23:05–23:20
- Tool(s): none in Figma yet. Code: Metal + SwiftUI, with a throwaway XcodeGen project that the artist session uses to build and screenshot on the iOS Simulator, plus a contact-sheet mode that shows all nine moods in one screenshot.
- Minutes: 25
- Worked (1-5): 4
- What made it into the project: `ios/Homer/Scene/` (Scene.metal, SceneRenderer, SceneMotion, Moods, SceneView, SceneDriver). The first render was technically right but read as busy marbled endpaper, not "open, simple". Rework: the inks now stack as layered horizons (a `tilt` and `amp` per mood), shapes are wide and slow, and the intense moods (anger, fear, defiance) dropped their fine octaves to show big torn shapes. Paper-cut shadows moved from screen derivatives (blocky 2×2 stair-steps) to a real offset sample.
- Friction: three visual iterations in about 20 minutes, each judged from a screenshot. Found and fixed a marbling bug where leftover weight leaked into the last palette.

### Prototyping · Components and the legibility rule · Fri Oct 23, 23:20–23:30
- Tool(s): none in Figma yet. Code: SwiftUI components, reviewed in a debug gallery over the live scene on the iPhone and iPad simulators.
- Minutes: 25
- Worked (1-5): 4
- What made it into the project: `ios/Homer/UI/`: tokens (Fraunces + Inter, paper/ink + one-job accents), caption, transcript, beat lane, formula hand, scorecard, carved line, broadcast set (entrance, round title, theme cards, scoreboard, join QR, champion).
- Friction: paper text set straight on the scene failed on light moods (joy, awe). Gold on gold was unreadable for the carved line. New rule: Homer's words on paper slabs, the poet's words on ink slabs, hero moments on seat-color slabs, labels in ink chips. The join code truncated at phone width, so the card now reflows.

### Ideation · Reading Matus's concept through the Figma MCP · Fri Oct 23, 23:40
- Tool(s): Figma Design, read through the Figma MCP server (get_metadata, get_design_context, get_screenshot) once Matus connected his account
- Minutes: 10
- Worked (1-5): 5
- What made it into the project: Matus's frame "Homer · Atelier" (node 46:378): cream page #F7F3EC, Bodoni Moda display, Inter UI, wine #682C3E, hairline cards, Lucide icons and an engraved Homer portrait. Exact sizes, colors, radii (12/14/18) and leading (1.10–1.12) came straight from the file. The icons and portrait were downloaded into `ios/Homer/UI/Art.xcassets`.
- Friction: the artist session first treated the concept as the source of truth and started overwriting the bold "Cut paper" direction. Matus corrected it: "don't treat the figma as the ground truth, use the power of figma to make it better." That changed the plan from "copy the frame" to "compare directions".

### Prototyping · Two directions, one token switch · Fri Oct 23, 23:45 – Sat Oct 24, 00:10
- Tool(s): Figma Design via the MCP (use_figma, upload_assets) plus SwiftUI. Variables with modes were the right tool: one collection, two modes, so a frame flips direction in one click.
- Minutes: 30
- Worked (1-5): 4
- What made it into the project: Figma file "MeNIN · Directions" (https://www.figma.com/design/qyaXnV3HbIUPIfYVbyqKwv). It has a "MeNIN" variable collection with modes **Atelier** and **Cut paper**: 23 colors, display font family and style as string variables, radii and margin. Every variable carries its Swift name as iOS code syntax (`Palette.hero`, `Metrics.radiusL`). The Home screen is rebuilt as editable layers bound to those variables, using components "Mode row" and "Tab item" plus 10 icon components. The same frame appears twice, with only the mode changed. A reference page holds simulator renders of 8 screens in both directions. In code, `Direction` in `ios/Homer/UI/Tokens.swift` mirrors the two modes with the same semantic names, so Figma and Swift share one vocabulary.
- Friction: Apple's iOS 27 kit couldn't be imported into the new file ("Not permitted to upsert from library"), so the status bar and home indicator are drawn from tokens instead. The first batch of uploads mangled em dashes in the layer names, and two renders caught the simulator mid-launch and had to be re-shot. Bodoni's natural line height is looser than the concept's 1.12, which needed iOS 26's `lineHeight(.exact)` in code.
- Before/after for Adoptability: before, comparing directions meant two code branches and a rebuild per screen; after, it takes one mode switch in Figma or one launch flag in the app.

### Prototyping · Battle screens (arena and phone) · Sat Oct 24, 00:15–00:40
- Tool(s): SwiftUI, reviewed on the iPad simulator in landscape (closest to the laptop arena) and the iPhone simulator. Not in Figma yet; the arena moments will join the renders page once Matus picks a direction.
- Minutes: 25
- Worked (1-5): 4
- What made it into the project: `ios/Homer/UI/Battle/ArenaView.swift` and `PlayerView.swift`, driven by plain value models (`BattleModels.swift`) that the iOS lead maps from SpacetimeDB, so the views never touch state. Arena moments covered: lobby with entrance, theme pick, round title, step up, speaking (transcript and beat lane side by side, played card flipping in), judging, verdict with live scoreboard, carved line, the stitched song, and champion. The phone covers join, mic check, waiting, on deck, speaking, weighing, result and final.
- Friction: on the first phone layout the hand got squeezed to a sliver mid-verse, so the whispered rescue card, the whole point of a freeze, was invisible. It became a compact chip layout with the whispered card as a bold hero chip. In Atelier, seat 0 was wine, the same as the hero surface, so the seat colors moved off wine. A build failure stayed hidden behind a silenced build step for one round, and I stopped silencing builds.

### Prototyping · Debate and discus join the hall · Sat Oct 24, 01:00–01:50
- Tool(s): SwiftUI on the iPad and iPhone simulators. These were run one at a time and shut down after each screenshot run, under the team's new memory budget for the shared 24 GB Mac.
- Minutes: 50
- Worked (1-5): 4
- What made it into the project: `ios/Homer/UI/Events.swift`: one config per game (host, rubric labels, beat on or off) and a `Ruling` that makes the scorecard work for any rubric. `UI/Debate/` holds Socrates' question card, For/Against side chips, a turn clock where the beat lane was, and a tap-to-play moves hand. `UI/Discus/` holds the arena throw (power gauge, flight arc with the distance counting up, field leaderboard) and a phone you hold like a discus.
- Friction: the discus arena first overflowed the laptop canvas and pushed the top bar and caption off screen, so the flight field now takes a height. Labels hard-coded "Homer" leaked into the Socrates event ("Homer hears", "Homer whispers") and became the event's host. The session scratchpad was wiped mid-session and the throwaway build project had to be recreated from memory. Nothing in the repo was lost.

### Prototyping · Clickable prototype of both flows · Sat Oct 24, 08:40–09:10
- Tool(s): Figma Design prototyping, built through the Figma MCP (use_figma: components, variables, `setReactionsAsync`, flow starting points). Prototype links are the right tool for a judge-facing walk-through: the same file holds the tokens, the components and the flows.
- Minutes: 30
- Worked (1-5): 4
- What made it into the project: page "Prototype · Atelier" in "MeNIN · Directions". New components: Chip, Button (Primary / Secondary / Cream), Caption, Transcript, Formula chip (Default / Played / Whispered) and Scene. Scene is a still of the Metal backdrop in five moods, built as matte layered paper. All of them are bound to the two-mode token collection. Nine frames: first open, event menu, home (the token-bound concept frame), practice turn, verdict, join, and on the arena (laptop size) the turn, carved line and champion. There are 13 interactions: taps on the real tiles, mode rows and buttons, plus timed advances where the app auto-advances. Two named flows: "1 · First open → Practice" and "2 · Battle: join → arena → champion".
- Friction: the first build referenced component property IDs by guess, and the script rolled back atomically, so nothing half-built was left. `resize()` silently turned auto-height components fixed, which clipped the transcript and caption and truncated buttons. Fixing it on the component fixed every instance. Vectors from `createVector` come with a default 1 px black stroke, which drew outlines on the cream backdrop. Arena chips needed scaling to read at laptop size, the same rule as `Stage.arena` in code.

### Prototyping · Seeding Figma Make with the live discus screens · Sat Oct 24, 09:00–09:15
- Tool(s): Figma Make. The artist session created the Make file and imported a static HTML/CSS/JS seed through the Figma MCP (`create_new_file` with type figmake, then `send_code_to_figma`). Make's own AI was not run by the agent, because the MCP can import code but can't prompt Make. The prompting is Matus's step (see the 10-minute guide sent to the leader).
- Minutes: 15
- Worked (1-5): 3, pending Matus's Make session
- What made it into the project: "MeNIN · Discus (Make)" (https://www.figma.com/make/MexcUVEohKsNVAw5pHh596) holds a playable sketch of the discus phone (hold, a power ring, release) and arena (an arc over an 80 m field, the Phayllos flag, the leaderboard, Homer's caption). Its CSS variables match the Figma tokens and `Palette` in Swift, so Make's variations come back in the app's vocabulary.
- Friction: the MCP reaches Make for import and for reading results (`get_design_context` on a Make file), not for prompting. That means a human-in-the-loop step, which matches the thesis: the designer drives the AI. Design-file code layers aren't enabled on this plan, so it had to be a standalone Make file.

### Handoff · One vocabulary: the Swift tokens, then Figma variables named after them · Fri Oct 23, 23:39 – Sat Oct 24, 00:10
- Tool(s): Figma MCP `get_variable_defs` on the concept frame, then Figma variables written through `use_figma`. Variables were the right contract because each one can carry its code name as iOS code syntax (`Palette.hero`, `Metrics.radiusL`).
- Minutes: 10 for the code side. Building the Figma collection is the 30 minutes in "Two directions, one token switch" above, so it isn't counted twice.
- Worked (1-5): 4
- What made it into the project: `ios/Homer/UI/Tokens.swift`. At 23:46 the concept's literal colors were split into semantic tokens (`hero`, `onHero`, `accent`) that map to wine in Atelier and to ink and sea in Cut paper, behind one `Direction` switch (committed 23:52). The "MeNIN" collection in Figma then took the same names and the same two modes, so a designer and the code talk about the same `Palette.hero`. Every app screen reads color, type and radii only through those tokens.
- Friction: `get_variable_defs` on Matus's frame returned `{}`. The concept had raw values, no variables, so the handoff ran code-first: the names were made in Swift and Figma was named after them. The sync is by convention, not live. A change in Figma reaches Swift only when the agent re-reads the variables and edits Tokens.swift. We kept it that way on purpose after Matus's note: Figma is where we compare and decide; the code is what runs.

### Handoff · The same tokens to the website team · Sat Oct 24, 12:36–12:40
- Tool(s): Claude Code (artist session), from `Tokens.swift` and the Figma variables, so the website team had the app's vocabulary without opening Xcode.
- Minutes: 5
- Worked (1-5): 3
- What made it into the project: `docs/design/atelier-tokens.css`: the Atelier palette, seats, type, radii, spacing and motion as CSS variables named after the Swift tokens. Its rules then shaped the website's battle screen (`homer/web/src/wired.css`): the 2 m type scale, the seat colors, the matte "no glow" rule, and the carved-line and crown cards.
- Friction: the website kept HohHamNap's own art and palette (Matus's call: his art is the big screen), so the file is a reference and the source of the seat colors, not the site's theme. Hence the 3.

### Code generation · Matus's concept frame to SwiftUI · Fri Oct 23, 23:39–23:54
- Tool(s): Figma MCP `get_design_context` on "Homer · Atelier" (node 46:378), asked for SwiftUI, plus `get_screenshot` to compare. It returns reference code with exact values, which beats measuring a screenshot.
- Minutes: 15
- Worked (1-5): 4
- What made it into the project: `ios/Homer/UI/Hall/HomeView.swift` (written 23:48): the greeting with Homer's portrait, the lesson card, the three modes, the hoard. Sizes, radii (12/14/18) and leading came from the frame and were bound to the tokens, not hard-coded. By 23:51 the home rendered in both directions on the simulator, and by 23:53 eight screens were rendered in both, which became the reference page in the Directions file. That home's look (paper cards, Bodoni and Inter, wine and gold, hairlines) became the language of every phone screen after it.
- Friction: the reference code came back as React and Tailwind even when asked for SwiftUI, so every value was mapped onto our tokens by hand. Bodoni Moda wasn't in the app yet and was pulled from Google Fonts mid-step. Its natural leading is looser than the frame's 1.12, which took iOS 26's `lineHeight(.exact)`. Later a playtest on Matus's phone made us rebuild the phone layouts (top band, middle, one action in the thumb zone); the frame's styling held.

### Code generation · Icons and Homer's portrait straight from the file · Fri Oct 23, 23:39–23:41
- Tool(s): the asset URLs that `get_design_context` returns, downloaded as SVG and PNG, so the art in the app is the exact art in the file.
- Minutes: 2
- Worked (1-5): 5
- What made it into the project: `ios/Homer/UI/Art.xcassets`: ten Lucide-style icons (feather, arrows, book, swords, library, scan) and the engraved Homer portrait, on the home, the menus and the back buttons.
- Friction: the SVGs arrived with the concept's wine stroke baked in, so they were stored as template images to take each direction's color. The new asset catalog broke the throwaway test build once (it expected an app icon), a one-line fix in that project.

### Handoff · The website's tokens for the Hall mode · Sat Oct 24, 20:43–20:58
- Tool(s): Claude Code (builder session), not Figma: a Python scan of the website's CSS (every colour, gradient, type, radius and shadow declaration, with its selectors), a read of the scene's shader and mood table, and headless Chrome for four reference screenshots. The site had no variables to read, so the values had to come from the code itself.
- Minutes: 15
- Worked (1-5): 4
- What made it into the project: `docs/hall-tokens.md`, plus `docs/hall-tokens/1-menu.png … 4-verdict.png`. From `homer/web/src/index.css` and `wired.css`: **128 distinct colours** (148 with coach.css and music.css), distilled into **37 named colour tokens** (9 sea blues, 6 inks, 9 creams and card fills, 2 dark glass, 5 golds, 1 neutral, 5 seat inks). **69 distinct type values**, distilled into **16 type roles** on 2 families (Georgia for words and numbers, Helvetica Neue for chrome). **17 radii** into 8 radius tokens; **73 spacing values** left as they are; **16 shadows**, with the 6 that carry the look named. From the scene: 9 moods × 4 inks (36 colours), the cut thresholds (0.36/0.52/0.68) and each mood's speed, drift and amplitude.
- Friction: the website defines **no colour variables at all** (its only two custom properties, `--fill` and `--i`, are layout values), so every name in the sheet is new. Three inks within a shade of each other (`#2C4B5C`, `#334B5B`, `#355D72`) and two golds (`#D7B46A`, `#E2BD6C`) are kept as separate tokens rather than merged, because they're used in different places; merging them is a design call. Gradients and translucent whites (`rgb(255 255 255 / 96%) → rgb(241 249 251 / 90%)`) have no clean name and are documented as values. The scene's colours live in a TypeScript array, not CSS. Two of the four screenshots come from the test hall (same build), so a "Voice offline" note shows in them.

### Prototyping · Hall: a third mode in the Directions variables · Sat Oct 24, 20:48–20:52 (contrast round 21:00)
- Tool(s): Figma Design via the MCP (use_figma). Adding a mode to the existing "MeNIN" collection was the right tool: every frame already bound to those variables can wear the website's palette with one mode switch, and the variables already carry the Swift names as code syntax.
- Minutes: 5, plus 3 for the contrast round
- Worked (1-5): 4
- What made it into the project: a third mode, **Hall**, in the "MeNIN" collection of the Directions file (https://www.figma.com/design/qyaXnV3HbIUPIfYVbyqKwv). **All 31 existing variables** got Hall values: 23 colours from the website (ink `#2C4B5C`, hero `#334B5B`, accent `#328EAF`, brand `#2E8EB5`, frosted paper white at 0.86, and so on), plus the type and radius variables kept at Atelier's values. **5 new seat variables** (`color/seat-1…5`, code syntax `Palette.seats[0…4]`) were added for all three modes, 36 variables in all. The same values went into `ios/Homer/UI/Tokens.swift` (swift) the same hour. **Flip test:** the Atelier prototype's Verdict and Join frames, duplicated and switched to Hall, flipped **72 of 73** and **8 of 9** bound fills in one step. A side-by-side frame for the deck is at https://www.figma.com/design/qyaXnV3HbIUPIfYVbyqKwv/?node-id=36-128.
- Friction: the one fill per frame that didn't flip is the painted scene art, which has hardcoded inks. It stayed gold, and the 0.86 frosted card picked up its tint, so the app got a note to put a blur under the frost. The seats weren't in Figma at all, and the first Hall seat proposal differed from the website's seat inks. A poet would have changed colour between phone and big screen; comparing against `Arena.tsx` caught it before anything was built. The labels failed contrast twice: `#577685`, then `#46677A`, measured 4.45:1 on the scene's `#C4E3EE`. They're now `#3F5F72` (5.0:1). Gold text went from `#9B7A35` (3.0:1) to `#7A5A1E` (4.7:1). Ratios are computed, not eyeballed. builder's 37-name token sheet arrived after the mode was built, so the Figma names stay the Swift names.

### Prototyping · Hall frames: join, a turn, the wait, the verdict, the arrow pad · Sat Oct 24, 20:53–21:01
- Tool(s): Figma Design via the MCP (use_figma, get_screenshot), with 4 local components (Button, Phrase, Chip, Loading) bound to the Hall variables, over a vector stand-in for the Metal scene drawn in the same inks as the app's new Hall rest. Figma first, so the product manager could review layout and contrast at both phone sizes before swift built anything.
- Minutes: 8, over 3 build passes and 2 review rounds (each review came back within minutes)
- Worked (1-5): 4
- What made it into the project: page "Hall · Reskin" (https://www.figma.com/design/qyaXnV3HbIUPIfYVbyqKwv/?node-id=30-102), with **12 frames**: Join, Turn, Wait, Verdict (battle) and the camera Arrow pad, each at iPhone SE 375×667 and Pro Max 440×956, plus Join · SE · keyboard up and Arrow pad · SE · held. All are filled with the worst-case strings ("Konstantina, Tamer of the Wine-Dark Sea", a 7-word theme, three long phrases, a 100/100 score). Every frame's fit is **measured in the script** (stack height = frame height, spacers ≥ 5 pt), not eyeballed. Into the build: the Hall contrast values above, the frosted-card blur, Inter for small numerals, and the SE turn layout (the ring beside SPEAK). In code the same evening: the app's Metal scene got a Hall rest from the website's moods (`ios/Homer/Scene/Moods.swift`, `SceneRenderer.swift`).
- Friction: **2 review rounds** from the product manager, with 7 blocking fixes and 10 notes. The first pass drew what a turn screen should show rather than what the app does: 5 axes with Flow first, "Round 2 of 3", Talk to Homer's "↑ from your last" on a battle verdict, and no countdown ring. The leader asked for frames that match the app, because judges will compare them. They were rebuilt to the app: Image/Answer/Craft, the 20 s ring, the required "Stuck?" line, live words as a tail with no ellipsis, and a keyboard-up Join. **3 self-caught fixes:** a draw-meter card stretched by a grow flag; Bodoni's "10" and "14" read as "IO" and "I4" at small sizes, so the numerals went to Inter; and Turn · Pro Max overflowed by 28 pt once the ring went in. The product manager approved both batches by 21:01 and said the measured fits made the reviews quick.

### Code generation · Hall: the app takes the website's palette through the Direction switch · Sat Oct 24, 20:44–21:06
- Tool(s): Swift by hand, from one token table agreed with the artist session by message before either of us built. The Swift names are the Figma variable names (code syntax `Palette.x`), so the table was the handoff. We didn't read the values back with `get_variable_defs`: the Figma mode and `Tokens.swift` were typed from the same table in parallel. A read-back after both land would be the cheap check to add next time. Renders came from one headless simulator, muted and booted only for screenshots (a debug route `-startScreen gallery -galleryPage N` opens any screen sample), because Matus's phone wasn't on the cable.
- Minutes: 22, from the agreed table to build 32 uploaded (tokens compiling at 20:49, upload at 21:06)
- Worked (1-5): 4
- What made it into the project: **a whole-app reskin as one enum case.** `Direction.hall` is the new default, and every `Palette` token picks three ways. `ios/Homer/UI/Tokens.swift` is **+69/−36**, and **5 view files** changed outside it, each by 1–9 lines: `Controls.swift` (the primary key becomes the website's sea gradient on a hard ledge, through a new `Palette.action` token), `Scorecard.swift` (verdict numerals in Inter), `HomeView.swift` (no page fill, so the scene shows), and `AppIconArt.swift` and `RootView.swift` (light/dark through `Direction.isLight`). **32 view files (119 views) restyled with no edits and 0 hand-edited colours in any screen.** 13 hard-coded colours remain outside the tokens: 12 in the app-icon art and 1 shadow. The sports' pottery colours stay on purpose, because the website's sports use the same ones. Build **32 (0.1.0, 202610242101)**, uploaded to TestFlight at 21:06.
- Friction: **3 rework rounds in 20 minutes.** (1) builder's extracted sheet (`docs/hall-tokens.md`) landed after the first values were in, and changed 6 of them: ink2, ink3, onPage2, accent (the website's label blue `#2F7F9C`), sea and gold. Gold text stayed at the darker bar gold so it reads on light. (2) The artist's computed contrast ratios changed 3 more (ink2 and onPage2 `#3F5F72`, goldDeep `#7A5A1E`). (3) A system blur under the frosted cards, which the Figma flip test asked for, rendered **grey** on the light sea, so it was dropped for 0.92 white alone, which stays readable over a strong gold mood. The leader also caught a stale gallery sample that still drew the old metronome turn ("BREATHE · 3 bars left"); the live turn has used the free-verse ring since build 17, and the sample now shows the real one. Still open: the product manager's SE-to-Pro-Max pass on a real phone (build 32), and Matus's whiter-scene tweak (build 33).

### Prototyping · Designer feedback on the scene: keep the wavy white, add cool blue · Sat Oct 24, 21:03–21:20
- Tool(s): Figma Design via the MCP (upload_assets onto full-bleed scene layers in all 12 Hall frames plus the flip frame), fed by real renders: the website's own WebGL scene code, run headless with the app's candidate values and driven by a scripted voice (emotion, energy, stressed-syllable strikes). A painted stand-in couldn't show Matus what the phone would actually do.
- Minutes: 17
- Worked (1-5): 4
- What made it into the project: Matus's direction in his own words, round by round: "keep the cool wavy white background … and maybe even throw in a mix of cool blue"; then "the background behind the poetry battle that shoots colors, that background is what I want"; then "I just want the BLUE shooting there"; and finally **"blue at rest, colours on voice"** ("I LOVE the background"). Each round got a fresh render in Figma within 2–3 minutes: Turn · Pro Max (34-179) mid-shoot and Join · Pro Max (31-179) at rest. In code (`ios/Homer/Scene/Moods.swift`): the Hall rest is the website's wavy-white field (same speed, drift, amplitude, flecks), with the deepest ink a light tint of the site's #328EAF (#7AB6D0) covering about 13% of the screen, and the voice's moods washing in over it.
- Friction: four direction changes in 17 minutes, three of them after values were already in the tree. Build 33 shipped the blue-only round because the archive couldn't wait; colours-on-voice goes into 34. The ink areas were measured from the renders (the website's rest is 16% deepest ink by nearest colour, about 8% once the layer shadows are separated). One deliberate departure from the site: the tilt is flipped so the blue gathers low, behind the cards, because ink text on the blue streak measured 4.1:1. Two render bugs cost a pass: a viewport shorter than the canvas left a white band at the bottom, and a missing semicolon in the harness.

### Prototyping · One button system for the Hall · Sat Oct 24, 21:17–21:23
- Tool(s): Figma Design via the MCP: a component set with variant axes Kind × State, plus Label (text) and Icon (boolean) properties, bound to new variables, and a showcase sheet over the real scene render. Matus had called the buttons "generic and boring"; one component set gives swift a single spec to build and lets Matus judge them over the background he loves.
- Minutes: 6
- Worked (1-5): 4
- What made it into the project: "Hall/Button system" (https://www.figma.com/design/qyaXnV3HbIUPIfYVbyqKwv/?node-id=48-215). That's **12 variants**: Primary, Secondary, Tertiary/link and Destructive, each in Default, Pressed and Disabled, with and without an icon. **16 new colour variables** (`color/button/*`, code syntax `Palette.button…`) are bound to the gradient stops, rims, labels and ledge effects. The primary is the website's pressable key: the sea gradient #65B9D8 → #328EAF, a 2 pt white rim, and a hard 4.5 pt ledge (#287794) with no blur; pressed, it travels 3.5 pt onto a 1 pt ledge. One typeface: Helvetica Neue Bold 17. The sheet is at https://www.figma.com/design/qyaXnV3HbIUPIfYVbyqKwv/?node-id=48-216, and the 5 buttons in the Hall frames are swapped to the new primary. The spec went to swift as values for build 34 (`HomerButtonStyle`).
- Friction: Helvetica Neue isn't served to Figma (it's an Apple system font), so the sheet renders in Arimo Bold as a stand-in and the app uses the real face. The website's #328EAF fails as a small label on white (3.6:1), so the link and secondary labels use a deeper sea, #2A7A9A (4.8:1). Binding a fill to a variable dropped its paint opacity (the link's 10% pressed tint came out solid blue), so it's bound to paper-3 instead. Every instance first showed the set's default label until the labels were set per kind. Binding the gradient stops themselves to variables worked first time.
