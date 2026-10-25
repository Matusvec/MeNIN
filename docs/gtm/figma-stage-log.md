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

What that looks like in practice. MeNIN is built by one designer (Matus) and a team of Claude Code sessions: leader, pm, artist, swift, multiplayer, gtm.

1. **Two directions, one vocabulary.** The artist session put both looks into one Figma variable collection with two modes: **Atelier** (Matus's concept: cream, Bodoni Moda, wine) and **Cut paper** (the first art pass: a dark sea, Fraunces, ink slabs). Every variable carries its Swift name as code syntax, and the app reads the same tokens through one `Direction` switch. Flipping a frame's mode in Figma and flipping the launch flag in the app show the same thing.
2. **Editable designs, not screenshots.** Matus's home frame was rebuilt as token-bound components. A clickable prototype covers both flows (first open to practice, and battle: join → arena → champion).
3. **Figma Make as a sparring partner.** The live discus screens were seeded into a Make file on the same tokens. Make's AI explores variations; the agent reads the chosen one back through the MCP and ports it to SwiftUI.
4. **Honest log.** Every stage below lists what broke and what was redone.

That handoff is the reusable part. Another team could run the same setup on a different idea.

Before and after numbers to capture for Adoptability: minutes from a Figma frame to a working component, the number of rework rounds, and the number of times the design and the code disagreed.

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
