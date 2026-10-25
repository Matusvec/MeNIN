# Demo-day run sheet

Logistics for judging day, Sunday Oct 25: what goes where, what gets charged, how the table is set, how we reset between judges, and what to do when something breaks. The 2-minute script is in [demo-script.md](demo-script.md), and what the app does in demo mode is in `docs/ux-flow.md`, section 6. This sheet doesn't repeat them.

**Print it, and tape a copy to the back of the Mac's lid.**

**Our gear (Matus's list):** one Mac (a MacBook Air), three iPhones and power banks. There's no iPad and no portable monitor. gtm checked the venue items against the Hacker Guide and the Cal Hacks announcements on Fri Oct 23, and marks them **(confirmed)** or **(not in the guide)**.

**The build: every phone on build 44** (0.1.0, `202610242226`, in TestFlight since Sat 10:29 PM) for the video shoot and judging (leader, Sat ~10:35 PM). Check Settings → About in MeNIN (or the TestFlight app) for the build number before each run, each study session and each judge.
- **Which runs count.** Build 31 fixed the SpacetimeDB SDK's cache, which ended the stuck game screens after a reconnect, so every series started again on 31 (runs on 24–30 don't count). Builds 32–44 change only the UI, the scene, the lessons, Practice and the home screen (pm's diffs), so **runs on 31 or later count for 44**. Poetry, debate, Talk to Homer and archery runs count only from **8:29 PM**, after the hall music and the camera-archery tune went live; Stadion, boxing and discus runs from before 8:29 stand.
- **Lessons.** Never film a lesson on anything older than 38 (older builds play lessons 1 and 2's old poem under the new captions). Since build 40, Homer speaks his own Iliad and Odyssey lines naturally, **on purpose**, not locked to the pulse (Matus: "don't make the Bard a beatbox"), and the pulse is a staff strike. Filming his demo is fine.
- **Renamed phone buttons (since build 34):** Join → "Enter the hall"; Ready (battle and debate) → "Step up"; the bow's Ready → "Take aim"; Leave → "Walk away"; the discus "Got it" → "I'll hold on" and "Begin" → "Start throwing"; Homer failing → "Call Homer back"; home "Resume" → "Back to it". SPEAK, "I'm done", "I'm here", "Fight", "Throw again" and every website button are unchanged.
- **New event** switches games live with every phone still joined. If a phone stays on the old game, it leaves and rejoins with the same code; that's a fallback, and it counts as one.
- **Build 18** (0.1.0, `202610241606`) is only the first-timer study's build; `docs/study.md` records which build ran.
- **The visual pass** runs once, on build 44, on Matus's iPhone 16 Plus (15 minutes; see the timeline).

**The website (since PR #1, Sat ~10:40 PM):** "/" is now the **Poets' Hall** landing page ("Choose Homer"), and **https://play.206.189.237.157.sslip.io/homer** goes straight into Homer's hall. **On the arena Mac, always open https://play.206.189.237.157.sslip.io/homer** (bookmark it). Then click **"Host a battle"**: under the heading "Open the hall" is the board of event cards. Click the **Poetry battle** card (tagged "Start here"), or another game's card. After a reload, it's /homer → "Host a battle" → **"Resume [code]"**.

**The hands: Moss deals them, judging included** (leader, Sat ~11 AM). `HOMER_DEALER=moss` is on in production; the old tag dealer takes over silently only if Moss stalls. So **the poets rehearse on Moss hands: start from [demo-hands.md](demo-hands.md)**, builder's sample Moss hands for the three demo themes. The Sat 1:30 PM full-battle checkpoint, the Sat 8 PM runs and every rehearsal use Moss hands. Moss ranks by meaning, so the hand for the same theme can vary a little between deals. Rehearse the theme's feel, not a fixed five.

## Sunday timeline

| Time | What | Who |
| --- | --- | --- |
| Sat 11 PM | Feature freeze. The demo build goes to TestFlight and is installed on all three iPhones and the Mac. Write the build number here: ______ | iOS lead |
| Sat night | Everything charges overnight to 100% (see Power). Five rematch drills in a row, timed. Save the backup video (`menin-backup-90s.mp4`; spec in [video.md](video.md)) to the Mac **and** to all three phones, in **Files → On My iPhone**, and play it once in Airplane Mode. On the Mac, confirm `python3 --version` works (it needs Xcode or the Command Line Tools) and that the repo is pulled, then run the demo check once against the production URL. | All |
| Sat night | Matus pings Sunya (the repo owner) so they're ready to flip the repo public at 8:00 Sunday. | Matus |
| Sun ~1:00 AM if Matus is up and his phone is cabled; otherwise Sun 8:00–8:30, before the table setup | **The real-phone visual pass on build 44, 15 minutes.** Matus walks the screens in `docs/ux-flow.md`, "Visual pass": join, a poetry turn, the verdict, the archery pad, Bard lesson 1, Talk to Homer and Practice, and he says "on screen" at each one. pm takes one capture over the cable, reads it and deletes it. No capture loops, and nothing between 11 PM and 1 AM (quiet hours). In the same slot comes **the lesson 1 ear check**: Homer's demo is *Iliad* 1.1–4, spoken live over the staff strike, and Matus says whether it sounds right. If something fails, swift fixes it; if that means a new build, pm diffs it for the runs rule before 9:30. | Matus, pm |
| Sat ~11 PM | After the freeze: rerun the **full-history secret scan** on the repo. The repo stays private until Sunday morning (Matus's call). | Leader |
| Sun 7:00 | Pack, using the list at the bottom. | All |
| 8:00 | At the venue. **By 8:00, Sunya makes the repo public** (GitHub → Settings → General → Danger Zone → Change visibility). Organizers require it (#0-ask-directors, Sat 2:20 AM). | Sunya |
| 8:00–8:40 | Open the GitHub link in a **logged-out browser** (a private window) and confirm it loads, before the Devpost submit. | Anyone but Sunya |
| 8:00–8:40 | **Only if Homer on Agentverse shipped:** submit Fetch.ai's second form. In ASI:One, open the "Cal Hacks ASI:One Submission agent", where Matus creates the team as lead and enters the public GitHub URL, the Devpost URL and the Fetch video URL. **Every teammate joins with the Team ID**, until the status reads "Submitted" ([opportunities.md](opportunities.md)). | Matus, then all |
| 8:45 | Devpost submitted, every track tagged. The hard deadline is 9:00. | Matus |
| 9:00–9:20 | **Get our judging table number and move there.** The Hacker Guide: "Shortly after the 9:00 AM submission deadline, all projects will be assigned a table number. You will need to move to your assigned table by 10:30 AM." Watch #0-announcements and the app. The table may not be where we hacked. | Matus |
| 9:20–10:00 | Hall check **at the assigned table**: find the nearest hardline switch (there's one every 3 tables, per the announcements), plug in ethernet, and **run the demo check until it says GO with no no-go warnings** (see Before each judge). Then set sound at demo volume, run the noise test, and do two full warm-up runs. If no switch reaches, tell a director immediately. Two teams had dead table ethernet on Friday night: one got no DHCP address, and one had a tripped cable. If the Mac shows no IP address on ethernet, tell a director right away and use venue Wi-Fi meanwhile. | All |
| 10:10 | **Start the live SpacetimeDB timeline** on the Mac's second desktop, once, and leave it running (see "The SpacetimeDB flip" below). | Operator |
| 10:15 | Table set: demo config loaded, the main room open, the website's hall open (/homer → "Host a battle" → the **Poetry battle** card clicked, Homer heard), and the backup video cued. | Operator |
| 10:30–12:30 | Judging. The whole team stays at the table. The guide: "If your entire team is not present while a judge comes, you will not be judged!" Take bathroom breaks one at a time, never two at once. Reset with the rematch drill between judges. | All |

## Device roles

Every device runs the same TestFlight build. Check under TestFlight, MeNIN, build number, and write it in the timeline above.

| Device | Held by | Role | Connection | Power |
| --- | --- | --- | --- | --- |
| **Mac (arena)** | Operator | **The website, full screen in a browser, at https://play.206.189.237.157.sslip.io/homer**, with the display turned to face the judges (SPEC: the website is the only arena people see; the app's arena mode is an emergency fallback behind the Dev screen). Click **"Host a battle"**, then **the **Poetry battle** card** (or **"Resume [code]"** after a reload), which also lets the browser play sound, then check Homer speaks. Demo config on, operator keys, latency HUD on. A Terminal sits on a second desktop for the demo check. The main room is live. **There's no second backup room:** the website allows one driving tab per browser, so recovery is a reload and "Resume" (see Fallbacks). The backup video is paused in a second window. | Ethernet, through the USB-C adapter | **100% at the start.** Wall outlet if the table has one, or a power bank if one can feed it (see Power). |
| **iPhone A** | The poet | Poet 1: mic and hand. | Venue Wi-Fi, with cellular data as plan B | Power bank between runs |
| **iPhone B** | Matus | Poet 2: mic and hand, and the staged freeze. | Same | Same |
| **iPhone C** | Operator | **The spare, with duties in priority order:** 1) replaces a dead poet phone; 2) **backup arena** if the Mac dies: the website in Safari (one column under 900 px), or the app's Dev-screen arena as the last resort; 3) plays the backup video if the Mac is gone; 4) the judge's phone after 2:00, for discus or a rematch. Grippy case. | Same | Same |

If iPhone C is already covering for a dead poet phone, the judge's phone after 2:00 is Matus's iPhone B, once his turn is done.

**On every device:**

- Do Not Disturb on, so no notification ever pops up on the arena.
- Ringer silent. Brightness up. System haptics on, for the 3-2-1 ticks and the turn's thump.
- **Low Power Mode off on the phones during runs.** It throttles performance and can delay network work. Turn it on only between runs if a phone is under 30%.
- **On the Mac:** notifications off, sleep and the screen saver off, the Dock hidden, and nothing open except MeNIN and the backup video. Confirm MeNIN really goes **full screen** in arena mode on the Mac. Keep **Low Power Mode off** too: it lowers the GPU clock, which can drop the scene's 60 fps and dim the display. Only turn it on if the battery falls under 30%.

**Headsets:** see "To buy or bring" below. A wired headset uses the iPhone's port, so phones charge between judges, not during a run.

## Power

- **Saturday night:** the Mac, all three iPhones and every power bank go to 100%.
- **The Mac:** a MacBook Air charges over USB-C PD (Power Delivery).
  - Read the USB-C output printed on each power bank.
  - **30 W or more** charges the Air even while it runs the arena.
  - 20 W only slows the drain.
  - Under 20 W, or USB-A only, can't charge it.
  - Write down which bank, if any, can feed the Mac: ______
  - **Plug the Mac in if the table has power** (leader, Sat 4:24 PM). If it doesn't (on Saturday some mezzanine tables' power strips were dead, and the top floor had no table power; #0-general, Sat 5:43–5:50 PM, hackers), an Air at 100% lasts the 2-hour window on battery, and `caffeinate -dims` keeps it awake: its `-i` stops idle sleep on battery too (`man caffeinate`). Find a live outlet in the 9:20 hall check, or use the power strip and extension cord, or a 30 W+ bank. Plug into the table's outlet if it has one; a hacker reported a dead outlet at their table on Friday, so don't count on it. MLH on judging: outlets "probably limited, make sure all your devices are fully charged before demos!" (#0-ask-directors, Sat 12:43 PM).
- **Phones:** on power banks between runs, off them for runs.
- **The 40% rule:** any phone under 40% swaps roles with iPhone C between judges and goes on a bank. Write the swap on the sheet, so nobody grabs the wrong phone.
- **Budget:** mic streaming, a bright screen and constant network drain a phone fast. Expect roughly 15 to 20% an hour during judging. Bank top-ups between judges cover the 2-hour window.

## Room setup

Rough table layout, with the judges in front. There's no external screen, so the Mac *is* the screen.

```
   Poet (A)      [ Mac, display facing judges ]   [speaker]     Matus (B)
                  Operator beside it, at an angle

   ---------- judges sit here ----------

   (discus space: one arm's length clear, away from the table)
```

- **The Mac** sits at the front edge, display tilted toward the judges, with captions large enough to read from their seats (check this during the hall check). Push the scene and captions to fill the display.
- **The operator** sits beside the Mac at an angle, so they can see the screen edge-on and reach the keyboard and trackpad. Use **keyboard shortcuts** for the operator keys (replay opening, Rematch, theme pick, switch room) so nobody reaches around the lid mid-run. If the app has no shortcuts, the operator uses the trackpad from the side.
- **The speaker** sits next to the Mac, aimed at the judges, low and close. Set the volume during the hall check: loud enough over the noise, not so loud it reaches the next team.
- **The poets** stand on either side of the Mac, facing the judges, headsets in, phones in hand. They're performing, not reading the screen.
- **Discus space:** before any throw, check one arm's length of clear space away from the shared table, the Mac and the neighbors' laptops. The release is a thumb lift, never an open hand.
- **Cables** are taped down where people step.
- **Optional:** a small card on the table with MeNIN, its pronunciation (MAY-nin), and the Devpost QR code.

## The SpacetimeDB flip (leader, Sat ~10:50 PM)

The SpacetimeDB judges want "something that's hard to build without Spacetime". This shows the server running the battle, live, for about 5 seconds.

- **Start it once in the morning (10:10),** in a Terminal on the Mac's **second desktop**, from the repo root (multiplayer, Sat ~11 PM):
  `cd spacetime && export PATH="$HOME/.local/bin:$PATH" && npm run -s bindings && while true; do STDB_URL=https://maincloud.spacetimedb.com STDB_DB=homer-calhacks npx tsx scripts/watch.ts; sleep 2; done`
  It regenerates the bindings from the committed module (the `spacetime` CLI is in `~/.local/bin`, not on PATH), then restarts itself if it ever exits. It's read-only and anonymous: a fresh identity each connect, no reducer calls, subscriptions only. On prod since 7:30 PM it has used 0.0% CPU and about 25 MB, and it writes nothing to disk (leave `AIM_DIR` unset). As a separate client, it can't touch the arena tab's one-tab lock or host identity. **Nobody publishes to homer-calhacks during judging** (leader has frozen publishes); a schema change would need `npm run -s bindings` and a restart.
- **The first line lists every room on prod (~50), a long wrapped line.** Flip only once it has scrolled away. The lines worth showing are the live ones: joins, phases, scores, arrows (with push latency in ms), punches and heats. [multiplayer can trim the start line Sunday morning, after quiet hours, if leader wants it.]
- **The flip, during Matus's sponsor line (demo script 1:10–1:26):** on "SpacetimeDB runs the hall", the operator swipes to desktop 2 (three fingers, or Ctrl+→). The judges see the timeline. Matus: "That's the server running the battle: every turn, every score, every timer." After about 5 s, swipe back.
- **Rehearse the flip twice in the warm-up runs** (9:20–10:00). Never flip while a poet is speaking or the verdict is on screen.
- **If it has stopped or errors:** don't flip. Say the line without it, then restart the timeline between judges.

## Before each judge (about 2 minutes)

Before every run:

- [ ] **The live SpacetimeDB timeline is still running on desktop 2** (it's the flip at 1:10–1:26).
- [ ] **Keep the arena Mac awake** (leader, Sat 4:24 PM: both phones and the arena dropped in the same second). **A network blip self-recovers:** the arena shows "Reconnecting…" and finishes the battle (builder killed the database mid-battle to test it). **Only a sleeping Mac or a closed tab kills the battle,** because the arena drives it:
  - [ ] In a Terminal, run `caffeinate -dims` and leave it running for the whole session. Or set System Settings → Battery → Options → prevent automatic sleeping on power adapter, plus Lock Screen → turn display off → Never.
  - [ ] **The Mac is plugged in if the table has power.** On battery, `caffeinate`'s `-i` still stops idle sleep (`-s` only adds AC-only protection), so a charged Air stays awake either way. Some mezzanine and top-floor tables had no power on Saturday (#0-general, Sat 5:43–5:50 PM, hackers).
  - [ ] **The arena tab stays in front** in its own full-screen window. Browsers slow down background tabs.
  - [ ] The lid stays open. Closing it sleeps the Mac whatever caffeinate says.
- [ ] The main room is open on the website, both poets have joined, and demo config is on. Nothing is preloaded: Homer writes a fresh theme and coins fresh epithets every battle (SPEC 7866476).
- [ ] A **fresh hall** is open (https://play.206.189.237.157.sslip.io/homer → "Host a battle" → the **Poetry battle** card, Sunday morning on the judging build; never Resume a Saturday room, since older rooms keep their old settings), and Homer speaks.
- [ ] The hands-free mic opens on each phone's turn, and the 3-2-1 ticks and the thump can be felt.
- [ ] Speaker volume is set and captions are on.
- [ ] The operator key "replay opening" is ready.
- [ ] The backup video is paused at 0:00 on the Mac.
- [ ] **Run the demo check** on the Mac, from the repo root, in a Terminal on a second desktop (never over the arena while a judge is looking):
  `python3 homer/scripts/demo_check.py https://206.189.237.157.sslip.io` *(the agent service on its DigitalOcean server)*
  It takes about 5 s. It checks the agent's health, times one real judged turn (Practice mode, so nothing is written to the room), and checks the themes, the freeze rescue and the voice token. **Read the lines, not just the last one.** It prints GO whenever nothing FAILs.
  - `FAIL spacetimedb ... battles can't be written`: **no battle.** Run Practice Spar for this judge and tell leader.
  - `FAIL voice token ... Homer is mute`: fix it before the judge sits down, or use the backup video.
  - Any other `FAIL`: **NO-GO.** Use the fallbacks below.
  - `WARN judge cache ... cold`: run the check again. The second run warms it.
  - `WARN judge ... verdict in X s` over 2.5 s: still GO. Expect the stall line, and tell Matus.
  - `WARN this python3 uses LibreSSL 2.8`: this won't appear on Matus's Mac. It has Homebrew Python 3.13, and the check switches to it automatically. If you ever see it, you're on a different Mac, so run the check from the arena Mac instead.
- [ ] The latency HUD shows the last run's verdict under 3.5 s.
- [ ] Mac battery: ____%. If it's under 30%, tell Matus, and only then turn on Low Power Mode.
- [ ] Phones come off their banks only when the judge sits down.

## The rematch drill

Between judges, or after a judge stays for a rematch. The spec's target is under 10 seconds.

| Seconds | Operator | Poets |
| --- | --- | --- |
| 0–2 | Press **Rematch**: same poets, and Homer coins a fresh theme. | Lower the phones and reset your stance. |
| 2–6 | Check the arena: the fresh theme is up and the old carved line is gone. | Check your phone: three new phrases, and the mic opens on your turn. |
| 6–10 | Nod "ready". | Nod "ready". |

- **If it isn't reset in 10 s:** reload the website's tab and click "Resume" (see Fallbacks). Don't press Rematch a second time.
- **Drill it Saturday night:** five times in a row, timed. Write the slowest time here: ______
- **More than 30 s until the next judge:** phones go back on their banks.

## Switching events, and the motion games

These are the only operator steps for Talk to Homer, the Stadion, boxing (Pygmachia) and archery. **The 8 PM runs fail any run where someone does a step that isn't on this sheet** (`docs/ux-flow.md`, "Sat 8 PM runs"), so do exactly these. Sources: `homer/web/src/Arena.tsx`, `lib/stadion.ts`, `lib/boxing.ts`, `lib/toxeia.ts` and the phone's archery screens (archery on the website since 0dd557e, Sat 6:35 PM).

### Every event

- **Begin needs at least two players joined** (one for Talk to Homer).
- **Switching events stays in the same hall** ("New event", builder, Sat 6:44 PM). Every phone stays joined, with no reload and no new code:
  1. Operator: in the lobby or on the results screen, click **"New event"** (next to Begin or Rematch). It opens a picker of the other games: Poetry battle, Talk to Homer, Socratic debate, Discus, Stadion, Pygmachia and Toxeia (the last two tagged "Beta"), as compact cards. "Cancel" closes it.
  2. Operator: click the game. The room goes back to the lobby with everyone still in it, and the phones change to the new game by themselves.
  3. Operator: **Begin.**
  - **Every phone on build 31 or later** (the judging build; see the top of this sheet). If a phone stays on the old game, it leaves and rejoins with the same code. That counts as a fallback.
  - Only pick a game that's unlocked for judges (see each event below). A locked one still shows in the picker.
- **"Next" is the operator's button** if a phase between turns sticks. It's on screen except while someone is racing, fighting or shooting, and never in Talk to Homer (which has End instead). **Pressing Next counts as a fallback:** use it so the run finishes, but that run isn't clean for the 8 PM count. (gtm's default; leader can overrule it.)
- At the end of every event, the operator presses **Rematch** (the same game again; "New conversation" in Talk to Homer) or **New event** (another game). Nothing else.

### Grip rule, for every phone that's swung or pumped

- A firm grip, with a grippy case or a wrist strap on **every** phone used in the discus, the Stadion, boxing or archery, not just iPhone C.
- **If a phone leaves someone's hand, that event is stopped for the night.** No exceptions at the table.

### Talk to Homer

3 runs at 8 PM; the checklist is in `docs/ux-flow.md`, "Talk to Homer". Source: `homer/web/src/Arena.tsx`, `Coach.tsx`, `lib/arena.ts` (pm, Sat ~7 PM). **One poet is enough.** There's no score to win: Homer answers each verse.

| Who | Step |
| --- | --- |
| Operator | **New event → Talk to Homer** (or "Host a battle" → the **Talk to Homer** card). Until a phone joins, Begin reads "Waiting for a poet". **Begin.** |
| Homer, automatic | Opens on his own: "Give me a verse about {theme}." With two poets he adds "{name}, you first." |
| Each turn, automatic | 3-2-1, SPEAK on the phone, a 20 s window ("I'm done" ends it early), then "Homer is answering…" and his reply out loud. The next turn follows by itself. |
| Operator | **Press nothing while it runs.** Talk to Homer has no "Next"; the only operator button is **End**. |
| To end | It never ends by itself. The operator presses **End**, and the arena reads "The conversation is over". |
| Operator | On that screen: **New conversation** (Talk to Homer's Rematch: a fresh one with a new theme) or **New event** (another game). |

### The Stadion (running)

| Who | Step |
| --- | --- |
| Operator | "Host a battle" → the **Stadion** card (or **New event → Stadion** from an open hall, phones stay joined). Begin. |
| Homer, automatic | "One stadion. Phone in hand, pump your arms like a sprinter." Then "Runners, to your marks.", the 3-2-1 and the race (40 s at most), the places, and "The stadion goes to {name}." |
| Operator | **Press nothing until Rematch.** |
| Runners | Phone in hand, pump your arms. Stand with arm room all around; nobody next to the table's laptops. |

### Boxing (Pygmachia, beta)

| Who | Step |
| --- | --- |
| Operator | "Host a battle" → the **Pygmachia** card, tagged Beta (or **New event → Pygmachia**, phones stay joined). Begin. |
| Homer, automatic | "{A} and {B}. Fists up." The bell starts by itself: 60 s or a knockout, then the result and "{winner}. The ring is yours." With three fighters, the winner stays on automatically, and the waiting fighter's phone (not the arena) shows "Up next: you fight the winner of {A} vs {B}". |
| Operator | Press nothing until Rematch. |
| Fighters | Phone held like a fist. **Stand more than an arm's length apart and punch the air, never at each other.** |

### Archery (Toxeia, beta)

> **Don't run archery at the table until it passes its 5 camera runs on build 31** (two-phone mode gets 2 clean fallback runs with Camera off; leader, Sat ~8:25 PM). Every phone on build 31 or later. Steps from pm, checked against `Arena.tsx`, `lib/arena.ts` and `lib/toxeia.ts` (Sat ~8:25 PM).

**Camera mode is the main mode** (live on the website since Sat 8:10 PM). The Mac's webcam tracks the bow arm and the draw, each archer's own phone nocks and looses, and **nobody passes phones**. Archers are the joined players, in join order, and the arena calls each one up itself: there's nothing to tap and no name to type. Once the range opens, the arena's scoreboard of joined phones hides (the range has its own board).

| Who | Step |
| --- | --- |
| **Everyone who'll shoot** | **Joins with the code before Begin, on their own phone.** |
| Operator | **New event → Toxeia** (or "Host a battle" → the **Toxeia** card, tagged Beta). Until two phones are in, Begin reads "Waiting for the bow and the arrow". |
| Operator | Press **Camera on** (in the button row; it works in the lobby too, so turn it on as soon as the archery hall opens). The judging hall starts with the camera off. The first time, allow the browser's camera prompt. A small camera view with the tracked skeleton appears in a corner of the range. Then **Begin**. |
| Homer, automatic | "Toxeia. Face the target and raise your bow arm. Phone in the other hand: thumb down, draw it back to your face, lift your thumb to loose." Then "{name}, step up to the line." and "{name} steps to the line." |
| Each archer, 3 arrows | Stand facing the target, **where the camera sees your whole upper body**. Raise the bow arm: the aim dot follows it, and it zeroes at the start of each arrow once the arm is still. Thumb down on your own phone, bring the drawing hand back to your jaw while the draw meter fills, and **lift your thumb to loose**. 45 s an arrow before it's lost. |
| Between archers, automatic | "{name} finishes on {total}." then "{next}, step up to the line." No phones change hands. |
| The end, automatic | After the last joined player's third arrow: "The bow goes to {name}, with {total}." |
| Operator | Press nothing while arrows fly. **"Next" during an arrow's score skips its reveal**, so it counts as a fallback. **Rematch** or **New event** at the end. |
| **If the camera loses the archer, automatic** (they lean or step out of view) | The aim dot freezes, the corner says "Step into view", and **the arrow's clock keeps running** (45 s). Step back in, and the arrow resumes on the same aim. The phones take over only if the camera is switched off or fails: the corner then says "Camera denied: phones" or "No camera: phones", and the two-phone fallback below applies (builder, a040a40, Sat 8:18 PM). Every camera run stages one 2 s step-out as a pass/fail check (`docs/ux-flow.md`). |
| **If the camera can't work at all** | The operator presses **Camera off**. It stays in two-phone mode for good, with the steps below. That counts as a fallback. |

#### Fallback: two-phone mode

Only when the camera is off, or by itself for one arrow when the camera loses the archer. **Nobody types a name.** Archers are the joined players, in the order they joined. The first phone in is the **bow** and its player shoots first; the second phone is the **arrow** and its player shoots second. Once the range opens, the arena's scoreboard of joined phones hides (the range has its own board).

| Who | Step |
| --- | --- |
| Operator | "Host a battle" → the **Toxeia** card, tagged Beta (or **New event → Toxeia**, phones stay joined). Until two phones are in, Begin reads "Waiting for the bow and the arrow". |
| **Everyone who'll shoot** | **Joins with the code before Begin.** The first two phones in become the bow and the arrow (each shows BOW or ARROW in big type). With 2 people that's all. With 3 or 4, players 3 and 4 join on their own phones, which show waiting; they shoot with the two station phones when their turn comes. |
| Operator | **Begin.** Homer reads the rules once. |
| The bow phone | Held out at arm's length, pointed at the target: tap **Take aim**. That starts the archer up (the first time, it also sets the centre of the aim). |
| Each archer | Bow phone in the outstretched hand, aimed at the target (a live dot shows where it points). Arrow phone in the other hand: **hold to nock**, pull back toward your face, let go to shoot. 3 arrows, 45 s each before it's lost. The next arrow follows by itself. |
| Between archers | The bow says **"Pass both phones to {next}"**. Pass **both**, hand to hand; the next archer holds the bow out and taps **Take aim**. |
| The end | **It ends by itself** after the last joined player's third arrow: the results come up and Homer crowns the best total. |
| Operator | Press nothing while arrows fly. **"Next" during an arrow's score skips its reveal**, so it counts as a fallback. Rematch or New event at the end. |

### At the table

The demo script's after-2:00 extras (discus, debate) switch events. That's now **New event → the game → Begin**, in the same hall, with every phone still joined, so offer an extra whenever the judge looks interested. Switch only from the results screen, never mid-battle.

## Fallbacks

Each one is decided in advance and has a line to say, so nobody improvises at the table.

| What breaks | Trigger | Do this | Owner | Say |
| --- | --- | --- | --- | --- |
| **The arena shows "Reconnecting…"** | Any time | **Wait.** It's a network blip, and the arena reconnects and finishes the battle on its own (builder's test). Keep talking. If it doesn't recover, treat it as "The room wedges" below (reload, then Resume). | Operator | "The hall's Wi-Fi is a battle of its own." |
| **The room wedges.** A turn won't advance, Rematch doesn't reset, or a phone can't rejoin. | Over 10 s stuck | **Reload the website's tab and click "Resume [code]"**: same room, same code, same scores, and the battle carries on from its phase; the phones just wait. If that fails, click "Host a battle", then the **Poetry battle** card for a new room, and the poets type its new code. If the browser itself is hung, force-quit it (⌘⌥⎋), relaunch, and Resume. | Operator | Matus: "Let's move to the other stage." |
| **One poet phone dies or freezes** | Any time | Hand that poet **iPhone C**. It joins the same room with the room code. | Operator | Matus keeps talking through the how-it-works line. |
| **The Mac dies** | Any time | **Open https://play.206.189.237.157.sslip.io/homer in Safari on another device** (the iPad, a teammate's laptop, or iPhone C, propped facing the judges), click "Host a battle", then the **Poetry battle** card for a **new room**; the poets join its new code. Another device can't take over the Mac's room, since the host identity lives in the Mac's browser. Last resort: the app's emergency arena on iPhone C, behind the Dev screen. The speaker stays on if it's wired to that device, otherwise it's device audio. | Operator | "Same game, smaller box." |
| **The Mac dies and iPhone C is already covering a poet** | Any time | **Practice Spar on one iPhone:** the poet against Homer, with that phone as both the arena and the mic. Or play the backup video on a phone. | Operator, poet | "Let me show you against Homer himself." |
| **Network is slow or down** | Turns lag past the stall line twice | Decided by leader: ethernet into the Mac first, then cellular on the phones. **No hotspot (confirmed banned).** The Cal Hacks announcement on Fri 10:16 PM said: "Personal hotspots, routers, or other broadcasting equipment are prohibited inside the venue and we have tools to find who has these." It was repeated Sat 12:48 PM: Wi-Fi 6 works better, 2.4 GHz works only on the Mezzanine, and patch cables can be rented at the Mezzanine hardware desk. **Ethernet isn't a sure thing either:** on Saturday afternoon hackers reported Wi-Fi "very slow", ethernet links not coming up and one dead switch (#0-ask-directors, Sat 1:31 and 2:11 PM), so test our switch in the 9:20 hall check. Each phone uses its own cellular data instead, which isn't broadcasting. The Mac can't use cellular, so if its ethernet dies, **iPhone C on cellular becomes the arena.** | Operator, poets | "One second, the Wi-Fi in here is a battle of its own." |
| **Two failures in a row, or no network at all** | Any time | **Backup video**, 90 s, of the best Saturday-night run. Play it from the Mac's second window, or from any phone (it's saved on all three). Play it with sound. | Operator | Matus: "Here's last night's battle, start to finish." Then quiet. |
| **No verdict after 4 s** | Automatic | The stall line plays. Keep going. | Nobody | Keep talking. Don't apologize. |
| **No verdict after 10 s** | Automatic | Nothing to do: the arena doesn't stall. Homer says "Homer is silent on this one.", the verse gets a neutral Image 4 / Answer 4 / Craft 4 = 40/100, its best line still shows, and the battle moves on (builder, Sat 4:15 PM). Say it plainly if a judge notices: "The judge timed out, so that turn got a neutral score." Never claim that turn was judged. | Operator | "Homer's thinking. Let's hear the next one." |
| **STT keeps mishearing** (noise) | After one retry | Hold the EarPods mic closer to the mouth. If it fails again, play the backup video. | Poet | "That's what Homer heard. This hall is loud." |
| **The judge has 60 s, not 120** | At the start | Follow the 60-second cut in [demo-script.md](demo-script.md). | Matus | |

**Practice Spar isn't an offline fallback.** It still needs the network for Claude and Cartesia. It covers a wedged room or a dead Mac, not a dead network. Use the backup video when the network is down.

## To buy or bring (Matus decides)

Optional, but each one fixes a real risk at a loud, shared table:

| Item | Qty | Why | Note |
| --- | --- | --- | --- |
| **Wired USB-C EarPods** (Apple, about $20) | **3**: two poets plus a spare | The inline mic sits near the chin, and a poet can hold it up like a mic. Either way it's much closer to the mouth than the phone's mic at arm's length, so STT survives the hall. Wired means no pairing chaos with three phones in one spot. | Check each iPhone's port first. Any phone with Lightning needs the Lightning EarPods. |
| **A small wired speaker** (3.5 mm) | 1 | Mac speakers lose to a hall. A wired speaker on the **MacBook Air's headphone jack** has zero latency and nothing to pair. | Preferred. |
| A Bluetooth speaker, only if there's no wired one | 1 | Louder than the Mac | **Policy risk is low:** the ban targets hotspots and routers, and a Bluetooth speaker isn't network equipment. The phrase "other broadcasting equipment" is vague, though, so unplug it if a director objects and fall back to the Mac speakers. **The real risk is technical:** Bluetooth adds roughly 150 to 300 ms of audio delay. Battles have no drum now (free verse), so the delay only matters for the beat under Homer's stitched song, where a small lag is harmless. Bluetooth also drops out in a crowded 2.4 GHz hall, so prefer a wired speaker. |
| **USB-C to Ethernet adapter** | 1 | **Required, not optional.** The MacBook Air has no ethernet port, and the venue Wi-Fi is slow. | Reserve the ethernet cable in the H@B app as well. |
| A power bank with **≥30 W USB-C PD** | 1 | Feeds the Mac under load | Only if none of the current banks can (see Power) |
| A grippy phone case or a wrist strap | One per phone that's swung | For the discus, the Stadion, boxing and archery: every phone used in a motion event | If a phone leaves someone's hand, that event stops for the night |

## Packing list

- [ ] Mac and its charger (for the wall outlet, if the table has one)
- [ ] iPhones A, B and C
- [ ] USB-C to Ethernet adapter, plus the reserved ethernet cable
- [ ] Speaker and its cable, charged
- [ ] Wired EarPods ×3 (two poets plus a spare), checked against each phone's port
- [ ] Power banks, all at 100%, plus short USB-C cables for every device
- [ ] **Every teammate's Cal Hacks badge.** "You will NEED it to get into the venue. We will not be handing out extras" (#0-announcements, Sat 9:56 AM, organizer). No badge means no teammate, and no whole team means no judging.
- [ ] **A power strip and an extension cord.** Hackers reported dead outlets at two tables Friday, and an organizer advised bringing an extension cord (#0-ask-directors, Fri). Check our table's outlet in the 9:20 hall check.
- [ ] A grippy case or wrist strap on every phone used in the discus, the Stadion, boxing or archery
- [ ] Gaffer tape, for the cables
- [ ] The backup video, saved locally on the Mac and all three phones (not streamed)
- [ ] This sheet, printed
