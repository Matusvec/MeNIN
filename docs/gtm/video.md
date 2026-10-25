# Video plan

Two videos, both from real takes. Nothing is mocked, and nothing is shown as live when it isn't.

| | The Devpost video | The backup video |
| --- | --- | --- |
| Length | **3:00** (the first 2:00 stands alone) | **90 s** |
| For | Devpost, plus Cartesia ("2-minute, demo-first") and Figma (3 minutes max) | The judging table, when the network is down ([run-sheet.md](run-sheet.md)) |
| Narration | Homer in his Cartesia voice, plus Matus's four answers to camera | None |
| Edit | Cut between camera, arena and phone footage | One battle take, trimmed only |
| Where it lives | YouTube, linked on Devpost | On the Mac and all three iPhones, **offline** |

## When

> **Superseded Sun ~2 AM:** the shoot is now the minimal one in "(c) The shot list" (one battle and a ~10-minute montage), builder edits overnight, and Matus signs off at 7:00 ("Morning, 7:00").

**The shoot follows Matus's "done" call** (Matus: "no filming till done": archery and boxing v2 are finished first; leader, Sat ~6:05 PM). It has no fixed time; likely about 9:00–9:30 PM, and it has to finish before the 11 PM freeze. Nothing has been filmed yet: the 1:30 PM gate run and the 5 PM shoot were both postponed. The order is fixed: **the poetry battle first**, then **discus** with the new angle display, then **Talk to Homer**, then **boxing** and **archery**, each only if it's clean. Matus reports the poetry and debate check runs as done; multiplayer is tallying the clean counts, so the shoot is no longer the gate.

**The build:** one build on both phones for the whole shoot, the newest TestFlight build that has Talk to Homer and boxing (build 19 or later; leader names it at setup). Never mix builds in one take, and write down which build each take used. The arena is the website, with its live scene. That's the game judges will play: Homer's three phrases, fresh Homeric themes and epithets, free verse with one SPEAK and a countdown ring, content-only scores out of 100, the hands-free mic, the rescue after about 2.5 s of silence (never in the first 3 s after SPEAK), and no sound effects. 11 PM is a reshoot only if something's missing.

| Time (Sat) | What | Who |
| --- | --- | --- |
| Any time before the "done" call | B-roll on the shoot build, 2 minutes at most per shot: the countdown ring closing on a phone, Homer's three phrases on a phone, SPEAK filling a phone in the poet's color, a thumb on the discus button, the discus angle display | Whoever has a free minute |
| 6–8 PM | **Only if the study runs** (Matus hasn't confirmed it): **the first-timer shot**, during the study (`docs/study.md`). Film only someone who said yes to consent question 4, and film **the screen and their voice, never their face**. | Poet runs the study; a second person films |
| 8:00 PM | The extras checkpoint: multiplayer's clean counts decide whether debate appears in the video. Discus needs 5 clean runs on build 31 (leader and pm, Sat ~8:25 PM: the build-18 pass came before discus v2 shipped in build 21). | Leader |
| **On the "done" call** (likely ~9:00 PM) | **Setup and go/no-go, about 15 minutes** ([below](#the-evening-shoot-on-matuss-done-call)). The shoot starts only if (1) **build 45 (the judging build) is on both phones** (Settings → About in MeNIN) (2) **Cartesia works**: Homer speaks and the mic transcribes (it was dead with HTTP 402 at 3:40 PM), (3) the website shows the live scene, and (4) **Matus gives the go**. If boxing or archery isn't clean, shoot everything else without it. | Operator, camera teammate, Matus |
| **15 minutes after the call, about 30 minutes** | **The shoot,** in this order: (1) **two full poetry battles** back to back (Rematch between them), plus the first-open line on its own; (2) **one or two discus throws** showing the new angle display, only if discus has passed its 5 runs on 31; (3) **one short Talk to Homer exchange** in a Judge hall (you speak; Homer answers in two sentences, quoting you, with one fix); (4) **one boxing exchange** and (5) **one archery shot**, each only if it's clean. If Fetch shipped, also the ASI:One screen recording for the Fetch cut. Use the quietest corner you can find. | Everyone needed |
| Before the call, or right after the shoot | Hall noise test (reality-check.md): run it while waiting for "done" if the hall is at peak noise, otherwise right after the shoot | Everyone |
| After the shoot, until 11 PM | Copy the footage to the Mac. Matus checks it against the shot list, marks anything missing for 11 PM, **exports the backup video from the best poetry take**, then edits the Devpost video and the Fetch cut if needed. | Matus, operator |
| 11:00–11:15 PM | **Reshoot only if a shot is still missing** (the freeze is code only; a pickup can still happen right after it). Then upload to YouTube, put the link in Devpost, and copy the backup video to every device. | Matus, operator |
| 11 PM | Feature freeze ([reality-check.md](reality-check.md) checkpoint). The video can still be added to Devpost after this; only the code freezes. | |

**Karaoke (8:20–9:00 PM) is dropped:** it may overlap the shoot, and the poet is needed at both.

**If the shoot fails** (the battle breaks mid-take), footage from a failing run is useless. Fix it and reshoot; the code freeze at 11 PM doesn't stop filming, but the upload has to be done before the 8:45 AM submission.

## The evening shoot (on Matus's "done" call)

> **Superseded Sun ~2 AM** by the minimal shoot in "(c) The shot list" below: one battle and a ~10-minute montage. The capture settings further down still apply, except the arena uses ⌘⇧5 for the picture.

**If any recording slows the arena or the phones, stop recording, not the run.**

**Two poetry takes, back to back.** Take 1 is the main footage; take 2 is the safety, and whichever is cleaner becomes the backup video. **Take 2 also tests the Spacetime rejoin** (unless multiplayer's runs already covered it): mid-battle, poet 1 force-quits MeNIN, reopens it and rejoins, and should get their seat back with their score. The operator notes whether it worked; it goes in the pitch and the README only if it did. Read the turn-to-voice time off the latency HUD in both takes for Devpost's `[turn-to-voice p50]`. Homer writes a fresh theme and coins fresh epithets each take, so nothing repeats and nothing needs to match between takes. Cut within one take, never across two.

**Then the extras, in order,** each on all the cameras that still apply: discus (the swing on C, the angle display and the flight on A), Talk to Homer (A for Homer's two-sentence reply, B over the speaker's shoulder), then boxing and archery, each only if it's clean (C for the players, A for the screen).

**Before setup:** **open the arena at https://play.206.189.237.157.sslip.io/homer** ("/" is now the Poets' Hall landing page), click "Host a battle", then the **Poetry battle** card. **Keep the arena Mac awake:** run `caffeinate -dims` in a Terminal for the whole shoot, keep the Mac plugged in if there's power (on battery, `-i` still keeps it awake), keep the arena tab in front in its own full-screen window, and keep the lid open (leader: at 4:24 PM the phones and the arena all dropped in the same second; network blips self-recover with "Reconnecting…", but a sleeping Mac or a closed tab kills the battle). Then check `memory_pressure | grep 'free percentage'` on the Mac and get it to at least 30% free (quit Xcode and the simulators). Make sure every phone has at least 5 GB free and Do Not Disturb on. Load /homer full screen in the Mac's browser, click "Host a battle", then **the Poetry battle card to open a fresh hall**, never "Resume" an older room: older rooms keep older settings (leader). The click also lets the browser play Homer's voice, so check that Homer speaks. Start every recording, then **clap once in view of every camera**. Then the operator starts the battle.

| # | Shot | Device and settings | Framing | Must catch |
| --- | --- | --- | --- | --- |
| **A** | **The arena screen recording** | The Mac, in **OBS**: macOS Screen Capture → Application → **the browser running the website**, app audio on, mic muted; Apple VT H264 hardware encoder, 60 fps, MKV. Settings are below. | Full arena, nothing else on screen | The whole take: the entrance with the fresh theme and Homer's call, SPEAK filling the arena in each poet's color, both turns over the live scene, both verdicts with scores counting up, the carved line, the stitched song, the crown. Captions on. |
| **B** | **Over the shoulder** | **iPhone C**, handheld by the free teammate: 1080p at 60 fps, landscape, AE/AF lock on the arena, then drag exposure down a little | From behind and just above a poet's shoulder: the phone's three phrases in the foreground, the arena beyond it, in focus on the phone | **3, 2, 1, SPEAK filling the phone**, then **Matus's freeze rescue** (he says one full line, then holds about 3 s of silence): Homer's phrases come forward, the one that fits is raised, Homer whispers it, Matus uses it and "+Craft" pops. Stay on Matus for turn 2; take poet 1 for turn 1. |
| **C** | **A wide shot of the table** | **Any spare phone**, such as a teammate's own, propped or on a stand: 1080p at 60 fps, landscape, AE/AF lock on a face | Both poets, the arena screen and the operator in one frame, from about 2 m away at chest height | The human moment: two people battling, a reaction to a verdict, the room listening to the song. In take 2, **the rejoin**: the phone force-quit, reopened, and the seat and score coming back on the arena. **Room audio comes from here.** |
| *(D)* | *Optional:* the poets' own phone screens | Control Center → Screen Recording, **mic off** (the app has the mic) | The phone screen | Close-ups of Homer's three phrases, SPEAK, and "+Craft". Skip it if either phone is low on battery. |

**If there's no spare phone for C,** iPhone C does B for turn 2 only, then moves to the wide spot for the verdict, the song and the crown. Take 2 can fill whatever C missed.

**After the takes:** name the files `shoot1-A-arena.mkv`, `shoot1-B-ots.mov`, `shoot1-C-wide.mov`, `shoot1-D-phone1.mov` (and `shoot2-…` for take 2), and copy them to the Mac over a USB-C cable or by AirDrop. Remux the MKVs to MP4 in OBS. Matus checks each shot in the Devpost shot list below and writes "missing: …" for 11 PM.


**Before the shoot:** run `memory_pressure | grep 'free percentage'` on the Mac. Quit Xcode and every simulator for the shoot and the edit, and confirm at least 30% free. OBS and iMovie each need memory, and the Mac is shared with the Claude sessions.

## Roles at the shoot

| Role | Who | Does |
| --- | --- | --- |
| Arena + capture | Operator | Runs the website arena on the Mac in demo mode and starts and stops OBS. Calls "rolling" and "cut". |
| Poet 1 | The poet | Performs, and starts their own screen recording before each take |
| Poet 2 | Matus | Performs (with the staged freeze), and starts their own screen recording |
| Camera | [composer, if there; otherwise iPhone C propped on a stand by the operator] | iPhone C on the wide shot |
| Voiceover | Matus | Two lines, recorded separately in the quietest spot available |
| Editor | Matus | Both videos, in iMovie on the Mac |

## Capture settings

### The arena Mac: OBS Studio

The Mac's built-in screen recorder (⌘⇧5) records the picture, but it can't be trusted to capture the browser's sound. OBS's macOS Screen Capture source records both: Homer, the beat and the score.

| Setting | Value |
| --- | --- |
| Source | **macOS Screen Capture**, method **Application**, set to the browser running the website, with **Capture audio** on. Close every other tab and window in that browser, since the app capture records all of it. Mute the mic and any desktop-audio source, so OBS only hears the app. |
| Base and output resolution | The display's own size (System Settings → Displays). The output keeps the same shape at 1920 wide. |
| Frame rate | 60 fps, to match the scene |
| Encoder | **Apple VT H264 Hardware Encoder**, CBR, 20,000 Kbps. The hardware encoder keeps the CPU free for the app. |
| Recording format | **MKV**, which survives a crash. Afterwards, use File → Remux Recordings to get an MP4. |
| Audio | 48 kHz |
| On the Mac | Notifications off, Dock hidden, the cursor parked off the arena, the website full screen in the browser (no tabs or address bar showing), demo config on, and captions on |

If OBS misbehaves, fall back to ⌘⇧5 for the picture and use iPhone C's audio.

### The poets' iPhones: screen recording

| Setting | Value |
| --- | --- |
| How | Control Center → **Screen Recording**. Long-press the button to set the microphone. |
| Microphone | **Off** for close-ups; the camera and the arena carry the sound. Once, before the first take, try 20 s with it **on** while MeNIN has the mic open. If the poet's voice comes through clean, keep it on: that's the cleanest verse audio we can get. |
| Focus | **Do Not Disturb on.** Banners show up in screen recordings. |
| Battery | Low Power Mode off, phones charged, and at least 5 GB free |
| Afterwards | Move the files to the Mac over a USB-C cable (Image Capture) or by AirDrop |

### iPhone C: the wide shot

| Setting | Value |
| --- | --- |
| Format | Settings → Camera → Record Video: **1080p at 60 fps** |
| Framing | Landscape, on a stand. The poet and the arena screen are both in frame, but the arena close-ups come from OBS. |
| Exposure | Long-press a face for **AE/AF Lock**, then drag exposure down a little so the arena screen doesn't blow out |
| Sound | The camera mic is the room mix: the poet, the beat and Homer. In a quiet room that's the authentic sound of the battle. |

**Syncing:** start every take with one clap in view of iPhone C. Line up the camera and OBS on the first "3" of the 3, 2, 1, and the phone recordings on the moment SPEAK fills the phone.

## The Devpost video (3:00)

**Rewritten Sun ~2:15 AM** from three independent reviews (a hackathon judge, a trailer editor and a sponsor judge), merged by leader. The limit is 3 minutes, and the video is required (MLH, Sat 6:29 PM). **The first 2:00 stands alone** as Cartesia's "2-minute, demo-first" cut, ending on the song and the responsible card. The last minute is the training montage and the Figma workflow.

**The rules for this video:**
- **Real takes only.** Nothing is mocked, and nothing is shown as live when it isn't.
- **No "Wii"** anywhere.
- **Burned captions** on every spoken line.
- **Beta labels:** any game that hasn't passed its runs on 31+ wears "· beta".
- **Teach the turn on mute, and label the sponsors' tech by 0:15.** Judges often watch without sound, so Matus's answers are captioned too.
- **Matus's four answers** (a SpacetimeDB sponsor told Matus the video must clearly cover what the product is, the value proposition, what we built in the time, and what's next; leader, Sun ~2:45 AM). They're four short clips to camera, each placed where it belongs, not one long opener. Homer narrates everything else.

### (a) The narration: Homer, in his own Cartesia voice (Carl), plus Matus's four answers to camera

builder renders these through Cartesia, which doubles as the Cartesia showcase. Every line sits over footage, never over a live verse or Homer's live verdict.

| # | At | Line (word for word) | Words |
| --- | --- | --- | --- |
| G | 0:00–0:02.5 | "μῆνιν ἄειδε θεὰ" (*Iliad* 1.1, the first 2.5 s of Paul's Greek clip only; `homer/web/src/poets/iliad.ts`) | 3 |
| ~~A~~ | — | *Cut: Matus's M2 now names the community.* | — |
| 4 | ~1:02 | "The best line gets carved in gold. Then I sing the room back." | 13 |
| 6 | ~1:27 | "Cartesia hears every word. SpacetimeDB runs the hall. Claude judges what you said." | 13 |
| 7 | ~1:31 | "Nothing here is mocked. Every verdict you saw was live." | 10 |
| 8 | 2:01 | "Then the games. Throw, run, box, draw the bow. The contest never ends." | 13 |
| 9 | 2:15 | "Two designers, one set of Figma variables. A new look is one mode." | 13 |
| 10 | 2:52 | "Most AI talks for you. I make you talk. Come battle." (Homer answers Matus's M1 line as the bookend.) | 11 |

**Matus's four answers to camera (word for word; each is its own clip):**

| # | At | Answer | Covers |
| --- | --- | --- | --- |
| M1 | 0:20–0:37 (~17 s) | "MeNIN trains your voice the way the Greeks did, like a sport. Homer teaches you to improvise poetry out loud. You spar with him, you battle other poets live, you debate the way Socrates did, and then you play Greek games with your friends. Most AI talks for you. MeNIN makes you talk." | What it is: the learn → practice → battle → debate → games arc (SPEC "The idea"; Matus, Sun ~3:50 AM) |
| M2 | 0:37–0:45 | "Open mics come once a week. MeNIN gives you a room, a judge and a crowd any night. Nobody practices alone again." | The value |
| M3 | 1:12–1:21 | "In one weekend: the battle, Talk to Homer, six lessons, four motion games, a website arena, and a server that judges even when the arena dies. Nothing is mocked." | What we built |
| M4 | 2:29–2:50 (~18 s) | "We're not stopping Monday. TestFlight this week, the App Store after. Every open mic, every classroom reading Homer, every party is a hall. One SpacetimeDB module runs every room, so adding a hall is adding a row. And our Swift SDK fixes go upstream, maintained, so any iPhone game can run on SpacetimeDB." | What's next, and that we keep going |

*gtm's truth fixes to leader's draft script (Sun ~2:50 AM):* M3 said "In 36 hours" (hacking ran Fri 6 PM to Sun 9 AM, 39 hours, so it's now "In one weekend"), "five motion games" (there are four: discus, the Stadion, boxing and archery) and "a server that never drops a verdict" (now what the backstop actually does). M4 said "open-sourced", but the vendored SDK is under SpacetimeDB's Business Source License 1.1, which says it "is not an Open Source license" (`ios/Vendor/SpacetimeDB/LICENSE.txt`), so it's now "sent upstream and maintained". Matus films the fixed lines.

*Second pass (leader, Sun ~3:00 AM: the SpacetimeDB sponsor also wants visible enthusiasm about continuing, and about scale).* M2 and M4 are rewritten. Two truth fixes to that draft: (1) "a thousand halls cost us what one does" overclaims. Rooms are rows in one module (`spacetime/CONTRACT.md`: every public table carries `room_id`), but every verse still costs a Claude call and Cartesia audio, so it's now "adding a hall is adding a row". (2) "open-source the Swift SDK" again: the SDK is under SpacetimeDB's Business Source License, so it's now "our Swift SDK fixes go upstream, maintained" (leader's final wording, sent to Matus). There are no user numbers anywhere.

**Cut:** line 1 ("Rage. The first word…"), line 2 (replaced by Matus's M1–M4), line 5 and **line A** (M2 covers the community now). **Line 3** ("One screen is my hall…") is cut too, because 0:25 onward doesn't re-explain the battle and line A already ends on "Battle me".

### (b) Cards and lower thirds (word for word, for artist)

**Sponsor logos** (Matus, Sun ~3:40 AM) go on the lower thirds and cards where each sponsor's part appears: Cartesia on L3, L4 and C3; Claude (Anthropic) on L4 and C2; SpacetimeDB on L10, C2 and L15; Figma on L14; and all of them (SpacetimeDB, Cartesia, Claude, Figma, Apify, Moss) on the C6 end card's "Built with" line. Use each sponsor's official logo file, small and in one cream tone to match the grade, always as "built with", never implying the sponsor made the video.

**Type:** cards in Bodoni Moda, big and centered; lower thirds in Inter only; the Greek at **90 px or more**. Names: Matus, Sunya and Paul ("Paul" confirmed, Matus, Sun ~3:40 AM).

| # | At | Type | Text |
| --- | --- | --- | --- |
| C0 | 0:00–0:02.5 | Caption over the scene, centered | **μῆνιν ἄειδε θεὰ** (≥90 px) / *Sing, goddess, the rage…* (small, under it) |
| L2 | 0:02.5–0:04 | Lower third | Homer deals you three phrases |
| L3 | 0:04–0:11 | Lower third | Your words, live on the big screen · Cartesia speech-to-text |
| L4 | 0:11.5–0:16 | Lower third | Judged by Claude · Homer's voice by Cartesia |
| C1 | 0:16–0:17.5 | Title card, on the theme's hit | **μῆνιν · MeNIN** / Homer teaches you to speak. Then you battle. |
| L1 | 0:17.5–0:20 | Lower third | Matus · Sunya · Paul / Cal Hacks 13.0 |
| LM | 0:20–0:23 | Lower third, Matus's first answer only | A live voice poetry battle · Matus, MeNIN |
| L5 | 0:45–1:12 | Lower third (the battle gets 4 at most) | Answer your opponent: it's 40 of the 100 points |
| L6 | 0:45–1:12 | Lower third | Freeze, and Homer whispers you a phrase |
| L7 | 0:45–1:12 | Lower third | Image ×4 · Answer ×4 · Craft ×2 = /100 |
| L8 | 0:45–1:12 | Lower third | The best line, carved in gold |
| L9 | 1:12–1:21 | Lower third, over the website B-roll cut into Matus's M3 | The arena is a website: open it on any laptop. No install. |
| L10 | 1:21–1:27 | Lower third, over the SpacetimeDB moment | SpacetimeDB ends the turn. Every screen flips in the same frame. |
| C2 | 1:27–1:31 | Diagram card (FigJam), 4 s | iPhone mic → Cartesia speech-to-text (Homer's phrases as keyterms) → SpacetimeDB → the website arena + Claude, the judge → Cartesia, Homer's voice |
| C3 | 1:31–1:34 | Number card | Word errors, with a drum at full volume: **20% → 3%** with keyterms / *Synthetic test clips · method in docs/voice-wer* |
| C5 | 1:55–2:00 | Responsible card | Built responsibly / Captions on everything Homer says · The mic opens only on your turn · No audio passes through our server · Homer never names your emotion · No account needed |
| L13 | 2:00–2:14 | One per game, at that game's first clip | Stadion / Toxeia (archery): the webcam tracks your bow arm / Pygmachia (boxing) / Discus, each with "· beta" if it hasn't passed its runs on 31+ |
| L14 | 2:14–2:29 | One stat, over the Figma footage | 128 hard-coded colors → 37 tokens |
| L15 | 2:29–2:50 | Lower third, under M4 from "And our Swift SDK fixes…" to the end of M4 | Our Swift SDK fixes: a public fork, sent upstream · github.com/Matusvec/spacetimedb-swift |
| C6 | 2:50–3:00 | End card; **hold "Play it now" and the URL for 5 s** | **Play it now** / play.206.189.237.157.sslip.io/homer / github.com/sunya-afrasiabi/MeNIN / Original score by Paul / Built with SpacetimeDB · Cartesia · Claude · Figma · Apify · Moss / Matus · Sunya · Paul · Cal Hacks 13.0 |

*L15 (leader, Sun ~4:25 AM): the fork is public (https://github.com/Matusvec/spacetimedb-swift, BSL 1.1 kept) and the draft PR is open upstream (https://github.com/avias8/spacetimedb-swift/pull/3). Say "a public fork with fixes sent upstream", never "open-sourced" or "our SDK": it's a fork of the community SDK, and Clockwork Labs has no official one. M4's spoken line stays as recorded; it's still true.*

*L14 uses the stat nobody can dispute (leader, Sun ~2:25 AM): builder's count of the website's CSS, `docs/hall-tokens.md`.*

### The timeline

| Time | Shot | Sound |
| --- | --- | --- |
| 0:00–0:02.5 | **The painted scene at rest** (not the 3D hall). Homer speaks "μῆνιν ἄειδε θεὰ" (G), with the Greek big and centered and the small English under it (C0). | Homer only |
| 0:02.5–0:04 | **Hard cut mid-word** to the poet's phone: three phrases dealt (L2). | The room |
| 0:04–0:11 | **The poet speaks.** Cut between the wide, the arena's live words with the scene erupting, and a phone inset (L3). | **Room sound only, no music** |
| 0:11–0:11.5 | **0.5 s of silence.** | Silence |
| 0:11.5–0:16 | **Homer's real verdict**, quoting the line, and the score lands (L4). | Homer |
| 0:16–0:17.5 | **The theme hits** with C1. *(The theme file opens with 59.8 s of silence; the hit is at 59.83 s, so start A2 there.)* | The theme |
| 0:17.5–0:20 | **The room reacting**, then the names (L1). | The theme, ducked |
| 0:20–0:45 | **Matus to camera: M1, then M2** (LM on M1). Under M1's list, cut 1 s glimpses in order: a lesson, Practice, the battle, Socrates, archery and boxing. | Matus, the theme ducked |
| 0:45–1:12 | **The rest of the battle, with no re-explaining** (27 s now; if it's too tight, take 4 s from the song, which can peak at 1:43). Poet B's answer (L5); both scores side by side; **the freeze rescue uncut at 1×** (Matus goes silent about 3 s on purpose, the phrase rises, Homer whispers; L6); the scores (L7); the gold line (L8) with line 4 before it. **Hold 1.5 s on faces after every score.** | The room and Homer; the music is hard-muted from every 3-2-1 and slams back on the score |
| 1:12–1:21 | **Matus to camera: M3, "what we built"**, the top of "How it works". Cut in 2–3 s of website B-roll under his voice: the arena scene, or the hall **cropped and desaturated**, never the 3D hall full-frame (L9). | Matus, the theme ducked |
| 1:21–1:27 | **The SpacetimeDB moment, 6 s:** the turn timer hits 0 and every screen (the arena and both phones) flips in the same frame, next to the real timeline rows rendered by multiplayer from the battle's log (L10). | The room |
| 1:27–1:31 | C2, the diagram, 4 s, with line 6. | Homer, the theme ducked |
| 1:31–1:34 | C3, the 20% → 3% card, with line 7. | Homer, the theme ducked |
| 1:34–1:55 | **The stitched song**, each line with its poet's name, **peaking around 1:45**. | Homer singing and the beat |
| 1:55–2:00 | C5, the responsible card, over the song's last line. **The 2:00 cut ends here.** | The song's tail |
| 2:00–2:14 | **The training montage, trimmed to ~14 s** (it gave its time to M4): every teammate on the Stadion, camera archery, boxing and discus, sped up 2–4× with ramps to 1× on the hero beats (the arrow release, the discus swing, a reaction). Line 8 opens it. **It ends on a miss and a laugh.** L13 goes up at each game's first clip. | The theme at full volume; the clips' audio muted |
| 2:14–2:29 | **The Figma workflow, ~15 s.** Best: 15 s of Matus's real screen recording of the variable mode switching Atelier → Hall, with the variables panel and the Swift names visible. Otherwise: artist's single before/after wipe. Either way, one stat (L14), not four cards. Line 9. | The theme, ducked |
| 2:29–2:50 | **Matus to camera: M4, "we're not stopping Monday"** (~18 s). | Matus, the theme ducked |
| 2:50–3:00 | C6, the end card, with "Play it now" and the URL held 5 s. Line 10. | The champion sting |

### (c) The shot list: the minimal shoot (the team needs sleep; builder edits overnight)

**Three things get filmed (the battle, the montage, Matus's four answers), plus one optional screen recording in the morning.** The rest comes from the team:
- **artist:** the Figma before/after wipe (and the PNGs in `docs/figma/`).
- **multiplayer:** the SpacetimeDB timeline rows, rendered from the battle's log.
- **builder:** the website footage.

> **Make it look great at the shoot (Matus):**
> - **Light on faces,** not the laptop's backlight: face a lamp or a window, never sit with your back to one.
> - **Landscape, propped steady:** every phone on a stand or wedged against something. No handheld wides.
> - **Get the reactions when verdicts land:** keep the wide rolling on the poets' faces through Homer's verdict, and hold for 1.5 s after.
> - **Perform the verses with feeling:** stand up, look at the other poet, and mean it.
> - **A quiet corner for the battle,** so Homer and the verses are clean.
> - **Slow-mo** (Camera → Slo-mo) **for the arrow release and the discus swing.**

**Prep (Matus, 2 minutes):** on each phone, long-press the home screen for 3 s → Dev. Check "Voice diagnostics" is **off** and the server says **Maincloud (homer-calhacks)**. Every phone is on the judging build.

| # | What | How | Feeds |
| --- | --- | --- | --- |
| 1 | **One full poetry battle**, through the stitched song and the crown. **Three must-haves:** (a) poet B answers poet A; (b) Matus **goes silent for about 3 s on purpose** in one turn, so the freeze rescue fires; (c) **one turn runs out to 0** (nobody taps "I'm done"), with the arena and both phones in the wide frame, for the SpacetimeDB moment | The arena Mac's picture with **⌘⇧5** (Record Entire Screen, the browser full screen). **Both phones screen-recording** (Control Center, Do Not Disturb on). **One phone camera wide** on a stand, landscape, 1080p 60 fps, with the poets and the screen in frame; it carries the **room audio**. **One clap** in view of the wide camera before the first 3-2-1 | 0:00–1:55 |
| 2 | **A ~10-minute montage on phone cameras:** archery in camera mode, the Stadion, boxing, discus. Every teammate on every game. **Get at least one clean miss and a laugh** for the ending. Slo-mo for the arrow release and the discus swing | Phone cameras, 60 fps landscape (plus Slo-mo) | 2:00–2:30 |
| 3 | **Matus's four answers to camera (M1–M4)**, each its own clip, word for word from the table above; 3 takes each (M4 runs ~18 s, so say it with energy: it's the "we keep going" moment) | Phone camera on a stand at eye level, landscape, 1080p; a lamp or window lighting his face; the quietest corner; EarPods or the phone close for clean sound | 0:20, 0:37, 1:12, 2:29 |
| 3b | **Two 3 s glimpses for M1's list:** Bard lesson one (Homer's demo, then a try) and Practice (sparring with Homer) | Phone screen recording on Matus's phone, mic on | 0:20–0:37 (under M1). Skip them if there's no time; builder then uses the battle and the games only |
| 4 | *(Optional, Matus, in the morning)* **15–30 s of the Figma variable mode switching Atelier → Hall**, with the variables panel open so the Swift names show | ⌘⇧5 on Figma (Record Selected Portion) | 2:30–2:50 |

**Safety for the montage:** a grippy case or a wrist strap on every swung phone, arm room all around, and nobody next to the laptops.

**Hand-off:** AirDrop every file to the Mac and tell builder where they are. Name them `battle-mac.mov`, `battle-phoneA.mp4`, `battle-phoneB.mp4`, `battle-wide.mov`, `montage-*.mov`, `answer-M1.mov` to `answer-M4.mov` and (if made) `figma-modes.mov`.

### (d) The CapCut track layout and the look

| Track | What's on it |
| --- | --- |
| **V1** | All footage, in timeline order. **Hard cuts only.** **Beat-snapped cuts only in the montage and the website footage**; the battle is cut on the action. The training montage uses CapCut → Speed → **Curve**: 2–4× through the run-up, with a ramp back to 1× (or the 120 fps slow-mo at 0.25×) on the hero beat. Mute each montage clip's own audio. |
| **V2** | Cards and lower thirds as PNGs from artist (transparent background for the lower thirds) |
| **Captions** | Burned in, corrected word for word against the narration table and the real transcripts. Inter, bottom-center, above the lower-third zone |
| **A1** | The room and Homer: the wide camera's sound, the arena's audio, Homer's live lines and the rendered narration. Normalize to about −14 LUFS |
| **A2** | Matus's theme. **Start the clip at 59.83 s** (the file opens with 59.8 s of silence), so the hit lands at 0:16. It sits at −18 dB, ducked a further ~10 dB under voice. **Hard-mute it at every 3-2-1 and slam it back on the score.** Bring it up to about −6 dB for the montage (2:00–2:30), ducked only under line 8. |

**The look:**
- **Grade:** cream highlights, lifted blacks, low saturation and a light grain.
- **Laptop footage:** cropped to the live words and the scene, never letterboxed.
- **Phones:** bare portrait insets, with no device frames.
- **One effect:** the scene's own color wash. Everything else is a hard cut.

**Export:** 1080p, 30 or 60 fps, H.264, AAC 48 kHz, **2:59 at most**. Also export the first 2:00 on its own (it ends on the song and C5) for Cartesia.

### Morning, 7:00 (Matus; done by 8:00)

1. Watch builder's **rough-cut-v1** once, start to finish, with the sound on. *(Optional first: the 30 s Figma screen recording, shot 3.)*
2. Tell builder any fixes, in one message, by 7:20.
3. Upload the final cut to **YouTube as Unlisted**, with the title and description below.
4. Open the link in a logged-out window to check it plays, then paste it into Devpost's video field.
5. **Share the FigJam board** (the how-it-works diagram, C2): https://www.figma.com/board/c8DkYceOjp3OJ7PPLeYUcn → Share → **Anyone with the link → can view**.
6. Done by **8:00**, before everyone checks in.

### (e) YouTube

**Title:** MeNIN: Homer teaches you to speak. Then you battle. (Cal Hacks 13.0)

**Description:**

> A live voice poetry battle: speak a verse into your iPhone, and Homer judges it out loud within seconds. Before you battle, Homer teaches you to improvise like the Greeks, and Socrates lets you practice the art of the argument. The big screen is a website; your phone is your mic and your hand of Homer's phrases.
>
> Play it now: https://play.206.189.237.157.sslip.io/homer
> Code: https://github.com/sunya-afrasiabi/MeNIN
> Figma stage log: https://www.figma.com/slides/oYPLd3JeIjhnkNyt75qfOm
>
> 0:00 A turn, start to finish
> 0:20 What MeNIN is
> 0:45 The battle
> 1:12 What we built, and how it works
> 1:34 The song
> 2:00 The games
> 2:14 The Figma workflow
> 2:29 What's next: we're not stopping
> 2:50 Play it now
>
> Built with SpacetimeDB, Cartesia, Claude, Figma, Apify and Moss at Cal Hacks 13.0.
> Built by Matus, Sunya and Paul. Original score by Paul. Nothing in this video is mocked.

Upload it as **Unlisted** or Public (Matus's call), and check it plays in a logged-out window before pasting the link into Devpost.

## The Fetch.ai cut (3:00, only if Homer on Agentverse ships)

Fetch.ai requires "a demo video (3–5 minutes)", longer than our 2:00 Devpost video. Make one extra cut. Its URL goes in Fetch's ASI:One submission form ([opportunities.md](opportunities.md)).

| Time | Shot |
| --- | --- |
| 0:00–3:00 | The Devpost video as it is |
| 3:00–3:50 | **A screen recording of ASI:One on the Mac:** find Homer, ask for a theme, get five formulas, type a verse with two of them, and get Homer's verdict: five scores, the best line, a one-line roast. Narration: "The same judge, as an agent on Agentverse, usable from ASI:One." |
| 3:50–4:00 | End card: the agent's name and address, plus "Built with Fetch.ai Agentverse and the Agent Chat Protocol" |

Export it the same way as the Devpost video. Upload it unlisted as its own YouTube video.

## The backup video (90 s)

**What it's for:** if the network dies at the table, the operator plays this and we narrate it live. We say plainly, "This is last night's battle."

**What it is:** the cleaner of the two evening poetry takes, from OBS with the room mix underneath, trimmed only to cut dead air. There's no voiceover and no added music, just the app's own sound. A 2-second card opens it: "Recorded live, Sat Oct 24".

| Time | What |
| --- | --- |
| 0:00–0:02 | Card: "Recorded live, Sat Oct 24" |
| 0:02–0:06 | Homer's first-open line |
| 0:06–0:10 | Homer's fresh theme, his call and the poet's entrance |
| 0:10–0:25 | Turn 1 |
| 0:25–0:31 | Verdict |
| 0:31–0:49 | Turn 2, with the freeze rescue and "+Craft" |
| 0:49–0:55 | Verdict |
| 0:55–1:02 | The round verdict and the carved line |
| 1:02–1:25 | The stitched song (4 lines) |
| 1:25–1:30 | The crown |

**Export:** 1080p, H.264, AAC, as `menin-backup-90s.mp4`. The app's on-screen captions are already in the frame, so no burn-in is needed.

**Where to keep it** (offline on every device, since it's only for when the network is gone):
- [ ] The Mac: on the Desktop, opened in QuickTime and paused at 0:00 (the run sheet's pre-judge check)
- [ ] iPhones A, B and C: in **Files → On My iPhone**, not just Photos. iCloud Photos with "Optimize iPhone Storage" can leave only a preview on the phone.
- [ ] Play it once on each device in Airplane Mode to prove it works offline

## Hacker's Choice clips (separate from both videos)

At karaoke and around the hall, film 15-second vertical clips on any phone: a discus throw, the scene shifting color during a verse, a crowd reacting to a verdict. Post them tagging the sponsors. Only film people who said yes. One person, one hour at most, and never at the expense of the build.

## What the research said (leader, Sun ~4:50 AM)

Sources read before the v4/v5 polish pass: Devpost's own "6 tips for making a hackathon demo video" (https://info.devpost.com/blog/6-tips-for-making-a-hackathon-demo-video), hackathon.com's demo-video guide (https://tips.hackathon.com/article/creating-the-best-demo-video-for-a-hackathon-what-to-know), a 3-minute pitch guide (https://blogs.reskilll.com/hackathon-demo-presentation-tips-pitch-3-minutes-win-2026/), and general editing guidance on hooks and cut rhythm (https://reap.video/blog/video-editing-tips, https://www.capcut.com/create/music-video-pacing-emotional-montage-rhythm).

What changed in the cut because of it:
- **The elevator pitch lands in the first seconds**, not at the title: a one-line caption at 0:03 ("Homer judges your verse out loud. Live.") so the sound-off test passes before C1 at ~0:17. Devpost: "open with the elevator pitch and what the app does in the first few seconds."
- **Real demo early, no slides, no code.** The battle stays the spine; the C2 diagram is the only explainer card and stays at 6.6 s.
- **Clean audio is a judging factor.** The mix is verified by script (duration, true peak, -14 LUFS) before any render is named; v2 and v3 shipped with a 2.5 s silent track and nobody heard it until the leader's QA.
- **Cut on the music.** The theme is 107.7 BPM (bar = 2.23 s); montage and card cuts snap to bar starts, with varied lengths (half a bar, one bar, two bars). The battle cuts on speech.
- **Captions carry the message with sound off**, placed off the speaker's mouth.
- **Don't speed up speech to fit**; trim at sentence ends instead (Matus's answers were trimmed, never sped).
