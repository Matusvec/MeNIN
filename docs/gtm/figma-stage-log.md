# Figma stage log

This log is the main thing Figma judges. Prizes: **Best Stage Log, $2,000** ("the clearest, most repeatable workflow of how a project was built"), **Best Figma Workflow, $2,000**, Best Design $500, Most Creative $500. Every winner also gets a session with Figma's Early Career Recruiter.

**Owner: artist session + Matus. Append entries as you work and never rewrite old ones.** Judges reward a log that is "honest about friction" and that records rework and dead ends, so keep those in.

## What Figma requires (from the official track doc)

- [ ] **Everyone on the team is Edu verified**: https://www.figma.com/education/apply
- [ ] **Figma Slides** deck (required) showing the work and the workflow. Start from their example and edit it: https://www.figma.com/slides/hViyGFvaHxTBqzYKkaYPho
  - [ ] Stage log in the deck: which Figma product we used and why, **200 words max per stage**
  - [ ] Demo video, **3 min max** (our 2-minute video works)
  - [ ] Figma files embedded (Make and/or prototypes), plus a link to the repo
- [ ] Every Figma file shared with **"Anyone"**
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

## Our story (draft; it's only true once it happens)

Homer is built by one designer and a team of Claude Code sessions: leader, pm, artist, multiplayer, voice and gtm. Figma is the shared source of truth between the human and the agents. Design tokens such as the eight emotion palettes and type go from Figma to code through the Figma agent or MCP, so the artist session builds from the file rather than from screenshots. That handoff is what makes it reusable: another team could run the same setup on a different idea.

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
