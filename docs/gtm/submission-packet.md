# MeNIN: the submission packet

For our web designer, from Matus. As of Sun Oct 25, ~12:55 AM. Every line below is something to click or paste. The repo has the full detail: `docs/gtm/devpost.md` (the Devpost text), `docs/gtm/figma-stage-log.md` (the Figma story) and `docs/gtm/run-sheet.md` (judging day).

## 1. Deadlines

- **Tonight:** create the MeNIN Devpost draft (cal-hacks-13-0.devpost.com → My projects), add every teammate, and tick every track in section 3 to check each one is selectable. The draft stays editable until the deadline.
- **8:00 AM:** everyone at the venue and checked in. The Devpost page: "Get to the venue by October 25th @ 8 AM PST. You must've had been accepted and checked in as a hacker to submit."
- **8:00 AM:** the repo goes public (Sunya flips it). Check it in a logged-out window before submitting.
- **8:45 AM:** Devpost submitted, with every track ticked. **9:00 AM is the hard deadline.**
- **After 9:00 AM:** table numbers are assigned. Move to our table by 10:30.
- **10:30 AM–12:30 PM:** live judging. The whole team must be at the table, or we aren't judged.

## 2. Figma (the most detailed part)

**The one tick:** on Devpost, select **"[Figma] Best Figma Workflow Hack"**. Figma staff: it "will also opt you into the Figma Best Design, Most Creative, and Best Stage Log!" (#spons-figma, Sat 9:33 PM). That's all four Figma prizes: $2,000 + $2,000 + $500 + $500 in Figma's brief.

**Figma's entry steps, exactly as their staff said** (#spons-figma, Sat 3:07 PM):
1. Put the **Figma Slides link** in Devpost → Project Details → **"Try it Out links"**.
2. Select **"[Figma] Best Figma Workflow Hack"** under Sponsors & Special Prizes.
3. Set the Slides sharing to **"View all"**. Every Figma file must be viewable by "Anyone", and everyone on the team must be Edu verified (figma.com/education/apply).

**Figma's three deliverables** (their brief): a demo video (3 minutes max), the stage log (200 words max per stage), and a Figma Slides deck that **embeds** our Figma files and links the repo.

### Every file and link

| What | Link | What it shows | Where it goes |
| --- | --- | --- | --- |
| **The stage log deck** (Figma Slides) | https://www.figma.com/slides/oYPLd3JeIjhnkNyt75qfOm | The ten-slide stage log: problem, workflow, the four stages, prototypes, directions, before and after, demo, links | Devpost "Try it Out links" (required) |
| **MeNIN user interface concept art** (Matus's planning file) | https://www.figma.com/design/zBILNwJB2NaVofBNJouAOW/MeNIN-user-interface-concept-art?node-id=0-1 | Matus's original concept art: where the look started | The Ideation slide; the stage log's Ideation entries. **Sharing: confirm "Anyone with the link"** |
| "Homer · Atelier" (the concept frame) | https://www.figma.com/design/zBILNwJB2NaVofBNJouAOW/MeNIN-user-interface-concept-art?node-id=46-378 | The home-screen concept the app's Atelier look and tokens were read from through the Figma MCP (Fri 11:40 PM) | The Ideation and Code generation slides |
| **MeNIN · Directions** (the design file) | https://www.figma.com/design/qyaXnV3HbIUPIfYVbyqKwv | The variable collection with three modes (Atelier, Cut paper, Hall); every variable is named after its Swift token | Deck slide 9 (embed); the Devpost Figma paragraph |
| Hall reskin page | https://www.figma.com/design/qyaXnV3HbIUPIfYVbyqKwv/?node-id=30-102 | 12 Hall frames: Join, Turn, Wait, Verdict and the archery Arrow pad, at SE and Pro Max sizes, plus keyboard-up and held states | The "One hall, two codebases" slide |
| The flip, Atelier → Hall | https://www.figma.com/design/qyaXnV3HbIUPIfYVbyqKwv/?node-id=36-128 | One frame twice, side by side; only the variable mode differs | The "One hall, two codebases" slide (embed) |
| Turn, mid-shoot | https://www.figma.com/design/qyaXnV3HbIUPIfYVbyqKwv/?node-id=34-179 | "Colours on voice": the scene reacting to a speaker, rendered from the real scene code | The "Designer in the loop" slide |
| Join, at rest | https://www.figma.com/design/qyaXnV3HbIUPIfYVbyqKwv/?node-id=31-179 | "Blue at rest": the scene with nobody speaking | The "Designer in the loop" slide |
| The button system | https://www.figma.com/design/qyaXnV3HbIUPIfYVbyqKwv/?node-id=48-216 | 12 button variants on 16 new variables (component set: node 48-215) | The "Designer in the loop" slide |
| App icon page | https://www.figma.com/design/qyaXnV3HbIUPIfYVbyqKwv/?node-id=51-102 | Three Hall icon options, judged at real home-screen sizes | Optional slide |
| App icon, real-size mock | https://www.figma.com/design/qyaXnV3HbIUPIfYVbyqKwv/?node-id=51-114 | The icons at 180, 120, 60 and 40 pt in the iOS mask | Optional slide |
| App icon, μ | https://www.figma.com/design/qyaXnV3HbIUPIfYVbyqKwv/?node-id=54-142 | The shipped icon: the Greek letter μ (from μῆνιν) on the button system's key. The font comparison is node 53-142 | Optional slide |
| **How it works** (FigJam board) | https://www.figma.com/board/c8DkYceOjp3OJ7PPLeYUcn | The diagram: iPhone mic → Cartesia → SpacetimeDB → the website arena + Claude → Cartesia voice | The video's diagram card; the deck's workflow slide. **Sharing: Matus sets "Anyone with the link → can view"** |
| Prototype flow 1 | https://www.figma.com/proto/qyaXnV3HbIUPIfYVbyqKwv?node-id=15-102&starting-point-node-id=15%3A102 | Clickable: first open → event menu → Poetry → practice turn → verdict | Deck slide 8 (embed) |
| Prototype flow 2 | https://www.figma.com/proto/qyaXnV3HbIUPIfYVbyqKwv?node-id=15-364&starting-point-node-id=15%3A364 | Clickable: join → arena turn → carved line → champion | Deck slide 8 (embed) |
| **MeNIN (Make): the website** | https://www.figma.com/make/0o7GzG4KEQejktGJeUuNbt/MeNIN | The Figma Make app the website began as (Paul's), committed Sat 12:33 PM | The Ideation and Code generation slides; the Devpost Figma paragraph. **Sharing: confirm "Anyone with the link"** |
| **MeNIN · Discus (Make)** | https://www.figma.com/make/MexcUVEohKsNVAw5pHh596 | Figma Make seeded with the discus screens on our tokens (Sat 9:00 AM) | It counts as an embed; optional slide |

**PNG copies in the repo** (they survive any change to the files; drop one in if an embed won't load):
- `docs/figma/`: hall-join-promax, hall-join-se, hall-join-se-keyboard, hall-turn-promax (mid-shoot), hall-turn-se, hall-wait-promax, hall-wait-se, hall-verdict-promax, hall-verdict-se, hall-arrow-promax, hall-arrow-se, hall-arrow-se-held, hall-flip-atelier-to-hall, hall-buttons, app-icon-key, app-icon-mu (16 PNGs).
- `docs/design/app-icon/`: AppIcon-atelier, AppIcon-cutPaper, AppIcon-hall-A, AppIcon-hall-B, AppIcon-hall-C and AppIcon-hall-mu (each 1024 px).

**The text for the deck:** `docs/gtm/figma-stage-log.md`, section "Deck text for Matus", has two slides ready to paste: **"One hall, two codebases"** (195 words, with numbers: 128 hard-coded colors became 37 tokens; 119 views restyled with no edits) and **"The designer in the loop"** (163 words: four feedback rounds in 17 minutes). The slide plan is in `docs/gtm/tracks.md`, Figma section, rows 1–12 plus 9b and 9c.

### Still open on the deck (Matus, in the Figma Slides app)

- [ ] Share the deck: **Anyone with the link → can view** ("View all").
- [ ] **Slide 8:** embed prototype flows 1 and 2 over the stand-in images (Insert → Embed). Figma requires live embeds.
- [ ] **Slide 9:** embed the Directions file.
- [ ] **Slide 1:** the team's names.
- [ ] Add the two Hall slides from "Deck text for Matus".
- [ ] The stage log's first Ideation entry still has a TODO: did any Figma tool shape the idea or the palette? If none did, say so.

## 3. Devpost

**Where the paste-ready text lives:** `docs/gtm/devpost.md`.
- **Tagline:** the "Tagline" line (180 characters).
- **The project story:** paste from the bold "MeNIN is a live voice poetry battle" paragraph through "Where it can go wrong (and what we do about it)". The sections: Inspiration, What it does, How we built it, Challenges we ran into, Accomplishments that we're proud of, What we learned, What's next, Built for the real world, Where it can go wrong.
- **Sponsor blurbs:** "Sponsor-track blurbs": SpacetimeDB, Apify, Fetch.ai (only if it's confirmed) and Moss.
- **"Built with" tags:** the "Built with" section.
- **Try it Out links:** the website, the TestFlight link, the Figma Slides deck, the Apify Store page, the repo.

**Tick these tracks** (locked Sat 10:15 PM against Devpost's list):
- [Spacetime] Best Use of Spacetime
- [Cartesia] Best Use of Cartesia
- [Anthropic] Claude for Public Benefit
- [Meta] Meta/Facebook: Bringing People Closer Together with AI
- [Figma] Best Figma Workflow Hack
- [Apify] Best Use of Apify
- [Apify] Best Actor sponsored by Apify
- [Moss] Best Use of Moss
- [Microsoft] Built for the Real World (1st), Customer Impact Award (2nd)
- Cal Hacks Most Creative Hack · Cal Hacks First / Second / Third Overall · Cal Hacks Most Technically Complex Hack · Cal Hacks Best People-First Social Impact Hack · Cal Hacks Hacker's Choice
- **Only if true by 8:45 AM:** [Fetch.ai] Best Use of Fetch.ai (only if someone gets a real reply from homer-bard in ASI:One and pastes the link) · [MLH] Best Domain Name from GoDaddy Registry (only if Matus registers playmenin.tech) · [MLH] Commit Fellowship Prize Category (Matus's call)
- Organizers: sponsor tracks are judged independently ("Yes you can win multiple sponsor tracks they are independent").

**Open `[brackets]`, and who fills each** (search the page for `[` before submitting):

| Bracket | Who |
| --- | --- |
| `[N]`, `[first]`, `[last]`, `[time]` (the first-timer study numbers) | Matus's score sheet. Until then, use the `[B]` lines |
| `[poet's name]`, `[the poet's scene]`, `[poet quote]`, `[how the score was made]` | Matus (`[composer's name]` and `[team]` are filled: Paul; Matus, Sunya and Paul) |
| `[turn-to-voice p50]` | Read off the latency HUD at the video shoot |
| `[real-mic WER]` | swift (if it isn't run, keep the 3%/20% numbers as they are) |
| `[If debate passed]`, `[If discus passes on 31]`, `[If archery passes on 31]` | leader, from the clean-run counts; delete the line if the event didn't pass |
| ~~`[Video]`~~ | Filled: https://youtu.be/vazDlqfDaUs (2:41, Unlisted) |
| ~~`[TestFlight public link]`~~ | Filled: https://testflight.apple.com/join/r9KCHkhc (live once Apple approves the beta; submitted Sun 3:27 AM) |
| `[ASI:One link]` | Whoever tests homer-bard in ASI:One; otherwise untick Fetch.ai and delete its blurb |
| `[playmenin.tech, if registered]` | Matus; delete it if not registered |
| `[Matus: add "and Matus checked them" only if true]` (Apify blurb) | Matus |

## 4. Links

- **The website:** https://play.206.189.237.157.sslip.io (the Poets' Hall). **The arena is https://play.206.189.237.157.sslip.io/homer** → "Host a battle" → the Poetry battle card. Phones join with the iPhone app.
- **The iPhone app (TestFlight):** **build 45** (0.1.0, `202610242325`) is the confirmed judging build. Matus submits it to External Testing. The public TestFlight link is https://testflight.apple.com/join/r9KCHkhc (live once Apple approves the beta; submitted Sun 3:27 AM). It works only after Apple's Beta App Review, which is pending; Matus submits the judging build for external review.
- **The Apify Actor:** https://apify.com/matusnator/epithet-miner · Actor ID `v4i7ItNXjHMmnKzfo` (Apify staff want both in the submission).
- **The repo:** https://github.com/sunya-afrasiabi/MeNIN. Public from 8:00 AM; MIT license.

## 5. The video

- **Length:** 3 minutes at most (MLH: "3 min", and it's required on Devpost). Our final cut is **2:41** (`menin-demo-3min-final.mp4`, v8, Sun 7:20 AM). A **1:49** cut (`menin-demo-2min-final.mp4`), ending on the "Built responsibly" card, stands alone for Cartesia, and the rest of the 2:41 is the games and the Figma workflow. It's the same video for Figma.
- **What it opens on:** the live poetry battle, from the first second. 0:00–0:10 is a poet speaking with the scene moving, no narration. At 0:16–0:20 Homer's verdict lands, with Matus's voiceover: "MeNIN. A live poetry battle. You speak, and Homer judges you out loud."
- **The plan and shot list:** `docs/gtm/video.md`, with every shot, who records it, and the 3–4 s SpacetimeDB timeline split-screen.
- It's shot on the judging build, on both phones. The link is **https://youtu.be/vazDlqfDaUs** (Unlisted, 2:41). It goes into Devpost's video field, and it's already in the README.

## 6. What could be yours (suggestions)

- **The website's own Figma Make file** (found: https://www.figma.com/make/0o7GzG4KEQejktGJeUuNbt/MeNIN): check its sharing is "Anyone", plus one stage-log entry in `docs/gtm/figma-stage-log.md` on how you built the website in Make (the tool and why, the minutes, a 1–5 rating, what made it in, the friction). It's the one Figma file only you have, and it makes "two designers" visible to Figma's judges.
- **Website screenshots for the Devpost gallery and the deck:** the Poets' Hall, Homer's hall, the event board, and the arena mid-battle with the carved gold line. The Devpost cover image is an arena frame with the gold line: matte, no neon.
- **A logged-out check from your laptop:** open /homer in a private window, click "Host a battle" and the Poetry battle card, and confirm Homer speaks.
