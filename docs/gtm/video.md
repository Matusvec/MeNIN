# Video plan

Two videos, both from real takes. Nothing is mocked, and nothing is shown as live when it isn't.

| | The Devpost video | The backup video |
| --- | --- | --- |
| Length | **3:00** (the first 2:00 stands alone) | **90 s** |
| For | Devpost, plus Cartesia ("2-minute, demo-first") and Figma (3 minutes max) | The judging table, when the network is down ([run-sheet.md](run-sheet.md)) |
| Narration | Homer, in his Cartesia voice (9 lines), and one line from Matus | None |
| Edit | Cut between camera, arena and phone footage | One battle take, trimmed only |
| Where it lives | YouTube, linked on Devpost | On the Mac and all three iPhones, **offline** |

## When

> **Superseded Sun ~2 AM:** the shoot is now the minimal one in "(c) The shot list" (one battle, a ~10-minute montage, Matus's line), builder edits overnight, and Matus signs off at 7:00 ("Morning, 7:00").

**The shoot follows Matus's "done" call** (Matus: "no filming till done": archery and boxing v2 are finished first; leader, Sat ~6:05 PM). It has no fixed time; likely about 9:00–9:30 PM, and it has to finish before the 11 PM freeze. Nothing has been filmed yet: the 1:30 PM gate run and the 5 PM shoot were both postponed. The order is fixed: **the poetry battle first**, then **discus** with the new angle display, then **Talk to Homer**, then **boxing** and **archery**, each only if it's clean. Matus reports the poetry and debate check runs as done; multiplayer is tallying the clean counts, so the shoot is no longer the gate.

**The build:** one build on both phones for the whole shoot, the newest TestFlight build that has Talk to Homer and boxing (build 19 or later; leader names it at setup). Never mix builds in one take, and write down which build each take used. The arena is the website, with its live scene. That's the game judges will play: Homer's three phrases, fresh Homeric themes and epithets, free verse with one SPEAK and a countdown ring, content-only scores out of 100, the hands-free mic, the rescue after about 2.5 s of silence (never in the first 3 s after SPEAK), and no sound effects. 11 PM is a reshoot only if something's missing.

| Time (Sat) | What | Who |
| --- | --- | --- |
| Any time before the "done" call | B-roll on the shoot build, 2 minutes at most per shot: the countdown ring closing on a phone, Homer's three phrases on a phone, SPEAK filling a phone in the poet's color, a thumb on the discus button, the discus angle display | Whoever has a free minute |
| 6–8 PM | **Only if the study runs** (Matus hasn't confirmed it): **the first-timer shot**, during the study (`docs/study.md`). Film only someone who said yes to consent question 4, and film **the screen and their voice, never their face**. | Poet runs the study; a second person films |
| 8:00 PM | The extras checkpoint: multiplayer's clean counts decide whether debate appears in the video. Discus needs 5 clean runs on build 31 (leader and pm, Sat ~8:25 PM: the build-18 pass came before discus v2 shipped in build 21). | Leader |
| **On the "done" call** (likely ~9:00 PM) | **Setup and go/no-go, about 15 minutes** ([below](#the-evening-shoot-on-matuss-done-call)). The shoot starts only if (1) ****build 44 (the judging build) is on both phones**** (Settings → About in MeNIN) (2) **Cartesia works**: Homer speaks and the mic transcribes (it was dead with HTTP 402 at 3:40 PM), (3) the website shows the live scene, and (4) **Matus gives the go**. If boxing or archery isn't clean, shoot everything else without it. | Operator, camera teammate, Matus |
| **15 minutes after the call, about 30 minutes** | **The shoot,** in this order: (1) **two full poetry battles** back to back (Rematch between them), plus the first-open line on its own; (2) **one or two discus throws** showing the new angle display, only if discus has passed its 5 runs on 31; (3) **one short Talk to Homer exchange** in a Judge hall (you speak; Homer answers in two sentences, quoting you, with one fix); (4) **one boxing exchange** and (5) **one archery shot**, each only if it's clean. If Fetch shipped, also the ASI:One screen recording for the Fetch cut. Use the quietest corner you can find. | Everyone needed |
| Before the call, or right after the shoot | Hall noise test (reality-check.md): run it while waiting for "done" if the hall is at peak noise, otherwise right after the shoot | Everyone |
| After the shoot, until 11 PM | Copy the footage to the Mac. Matus checks it against the shot list, marks anything missing for 11 PM, **exports the backup video from the best poetry take**, then edits the Devpost video and the Fetch cut if needed. | Matus, operator |
| 11:00–11:15 PM | **Reshoot only if a shot is still missing** (the freeze is code only; a pickup can still happen right after it). Then upload to YouTube, put the link in Devpost, and copy the backup video to every device. | Matus, operator |
| 11 PM | Feature freeze ([reality-check.md](reality-check.md) checkpoint). The video can still be added to Devpost after this; only the code freezes. | |

**Karaoke (8:20–9:00 PM) is dropped:** it may overlap the shoot, and the poet is needed at both.

**If the shoot fails** (the battle breaks mid-take), footage from a failing run is useless. Fix it and reshoot; the code freeze at 11 PM doesn't stop filming, but the upload has to be done before the 8:45 AM submission.

## The evening shoot (on Matus's "done" call)

> **Superseded Sun ~2 AM** by the minimal shoot in "(c) The shot list" below: one battle, a ~10-minute montage and Matus's line. The capture settings further down still apply, except the arena uses ⌘⇧5 for the picture.

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

**Rewritten Sun ~1:40 AM for a 3:00 cut** (leader, for Matus: "looks great, with clips of the team, the app and the website"). The limit is 3 minutes, and the video is required (MLH, Sat 6:29 PM). **The first 2:00 stands alone** as Cartesia's "2-minute, demo-first" cut and ends on the responsible card. Figma gets its own minute after it (their brief: "Demo video (3 minutes maximum)").

**The rules for this video:**
- **Real takes only.** Nothing is mocked, and nothing is shown as live when it isn't.
- **No "Wii"** anywhere, spoken or written.
- **No music under a verse:** the theme drops out whenever a poet speaks.
- **Captions** on every spoken line.
- **Beta labels:** any game that hasn't passed its runs on build 31 or later wears a "beta" lower third.
- **Judges watch on mute,** so the cards carry the story alone.

### (a) The narration: Homer, in his own Cartesia voice (Carl), and one line from Matus

Nine lines now (line 5 was dropped), each 14 words or fewer. builder renders Homer's eight lines through Cartesia, which doubles as the Cartesia showcase. Matus records his own line in **Voice Memos**, close to the mic, in a quiet corner.

| # | At | Who | Line (word for word) | Words |
| --- | --- | --- | --- | --- |
| 1 | 0:09 | Homer | "Rage. The first word of Western literature. Sing it back to me." | 12 |
| 2 | 0:15 | **Matus** | "AI can write anything now. It can't stand up and move a room." | 13 |
| 3 | 0:26 | Homer | "One screen is my hall. Your phone is your voice. Step up." | 12 |
| 4 | 1:02 | Homer | "The best line gets carved in gold. Then I sing the room back." | 13 |
| ~~5~~ | — | — | *Dropped (Sun ~2 AM): there's no Bard footage in the minimal shoot, so the lesson line no longer fits.* | — |
| 6 | 1:36 | Homer | "Cartesia hears every word. SpacetimeDB runs the hall. Claude judges what you said." | 13 |
| 7 | 1:49 | Homer | "Nothing here is mocked. Every verdict you saw was live." | 10 |
| 8 | 2:01 | Homer | "Then the games. Throw, run, box, draw the bow. The contest never ends." | 13 |
| 9 | 2:31 | Homer | "Two designers, one set of Figma variables. A new look is one mode." | 13 |
| 10 | 2:53 | Homer | "Most AI talks for you. I make you talk. Come battle." | 11 |

Every line sits over footage, never over a live verse or Homer's live verdict. If line 8 runs over a game that's cut from the montage, drop that game's word ("Throw, run, box" etc.).

### (b) On-screen cards and lower thirds (word for word, for artist)

Cards (**C**) are full-screen; lower thirds (**L**) sit bottom-left over footage. Use the app's own type: Bodoni Moda for titles and Inter for everything else, matte, in the Hall palette. **Names: Matus, Sunya and Paul (leader, Sun ~1:50 AM). The spelling "Paul" vs "Paulo" for the score credit and the team is pending Matus; fix both together.**

| # | At | Type | Text |
| --- | --- | --- | --- |
| C1 | 0:08–0:14 | Title card, on a hit from Matus's theme | **μῆνιν · MeNIN** / Ancient Greek party games, hosted by Homer |
| L1 | 0:14–0:20 | Lower third | Matus · Sunya · Paul / Cal Hacks 13.0 |
| L2 | 0:25 | Lower third | Join with a code. No account. |
| L3 | 0:29 | Lower third | A fresh theme from Homer, every round |
| L4 | 0:33 | Lower third | Three of Homer's phrases, dealt to your phone |
| L5 | 0:38 | Lower third | Free verse. 20 seconds. Your words, live on the big screen. |
| L6 | 0:46 | Lower third | Freeze, and Homer whispers you a phrase |
| L7 | 0:52 | Lower third | Judged on Image, Answer and Craft · out of 100 |
| L8 | 1:00 | Lower third | The best line, carved in gold |
| L9 | 1:06 | Lower third | The finale: the room's best lines, stitched into one song |
| L10 | 1:15 | Lower third, over builder's website B-roll | The arena is a website: open it on any laptop. No install. |
| ~~L11~~ | — | — | *Dropped with the Bard footage.* |
| C2 | 1:35–1:43 | Diagram card (FigJam) | iPhone mic → Cartesia speech-to-text, with Homer's phrases as keyterms → SpacetimeDB → the website arena + Claude, the judge → Cartesia, Homer's voice |
| L12 | 1:43 | Lower third, over the split-screen | Live: the SpacetimeDB timeline. The server runs the battle. |
| C3 | 1:47–1:50 | Number card | Word errors, with a drum at full volume: **20% → 3%** with keyterms / *Synthetic test clips · method in docs/voice-wer* |
| C4 | 1:50–1:55 | Card | **Nothing is mocked.** |
| C5 | 1:55–2:00 | Responsible card | Built responsibly / Captions on everything Homer says · The mic opens only on your turn · No audio passes through our server · Homer never names your emotion · No account needed |
| L13 | 2:00–2:30 | One per game, at that game's first clip in the montage | Stadion / Toxeia (archery): the webcam tracks your bow arm / Pygmachia (boxing) / Discus / Poetry battle. **Add "· beta" to every game that hasn't passed its runs on 31+.** |
| L14 | 2:31 | Lower third | Atelier → Hall: the same frame, one variable mode |
| L15 | 2:36 | Lower third | 128 hard-coded colors → 37 tokens · 119 views restyled, untouched |
| L16 | 2:41 | Lower third | The scene: 4 rounds of designer feedback in 17 minutes |
| L17 | 2:45 | Lower third | One button system, 12 variants · the icon: μ, from μῆνιν |
| C6 | 2:50–3:00 | End card | **MeNIN** / play.206.189.237.157.sslip.io/homer · github.com/sunya-afrasiabi/MeNIN / Original score by Paul / Built with SpacetimeDB · Cartesia · Claude · Figma · Apify · Moss / Matus · Sunya · Paul / Cal Hacks 13.0 |

### Timeline (what's on screen)

| Time | Shot | Sound |
| --- | --- | --- |
| 0:00–0:08 | **Cold open on a real battle, no narration.** A poet speaking (phone camera, close), the scene erupting in color (arena), Homer's spoken verdict landing. | The room and Homer |
| 0:08–0:14 | C1 title, with Homer's line 1 | A hit from the theme |
| 0:14–0:25 | **The hook:** the team at the table, the laptop arena, phones in hand (L1). Matus's line 2. | The theme, ducked |
| 0:25–1:15 | **The full poetry battle:** join by code (L2); the theme and three phrases (L3, L4); 3-2-1, SPEAK (L5); live words on the big screen; the freeze rescue whisper (L6); Homer's spoken verdict with scores (L7); the carved gold line (L8); the stitched song (L9). Homer's line 3 at the start and line 4 before the carved line. | The room and Homer; no music under any verse. The beat returns under the stitched song |
| 1:15–1:35 | **More battle, plus builder's website B-roll:** more of the same battle take (a second verse, the scores, the room reacting), cut with builder's B-roll of the website: the Poets' Hall, Homer's hall, the event board, the arena scene moving (L10). No narration. | The room and Homer |
| 1:35–1:55 | **How it works:** C2, the diagram (line 6); then a 3–4 s split-screen of the arena and the SpacetimeDB timeline, **rendered by multiplayer from the battle's own log** (L12); C3, the word-error card; C4 (line 7). | The theme, ducked |
| 1:55–2:00 | C5, the responsible card. **The 2:00 cut ends here.** | The theme |
| 2:00–2:30 | **The training montage** (Matus's idea): **every teammate on every game.** Running the Stadion, drawing the camera bow, boxing, a discus swing, spitting a verse. The raw clips are 10–20 s each, sped up 2–4×, with **speed ramps back to 1× on the hero beats**: the arrow release, the discus swing, a verdict reaction. Keep the misses, the reactions and the high-fives. Each game's name goes up as a lower third at that game's first clip (L13). Homer's line 8 opens it; no other narration. | **The theme at full volume.** The clips' own audio is off, so nothing plays under an audible verse |
| 2:30–2:50 | **The Figma workflow:** the Atelier → Hall flip, the four background rounds, the button system, the μ icon (L14–L17). Line 9. | The theme, ducked |
| 2:50–3:00 | The team, then C6, the end card. Line 10. | The champion sting |

### (c) The shot list: the minimal shoot (leader, Sun ~2 AM: the team needs sleep, and builder edits overnight)

**Only three things get filmed.** Everything else comes from the team's renders:
- **Talk to Homer, Bard and debate are cut** from the video.
- **The Figma minute** uses artist's renders and the PNGs in `docs/figma/`.
- **The SpacetimeDB timeline** is rendered by multiplayer from the battle's log.
- **Builder** supplies the website B-roll.

**Prep (Matus, 2 minutes):** on each phone, long-press the home screen for 3 s → Dev. Check "Voice diagnostics" is **off** and the server says **Maincloud (homer-calhacks)**. Every phone is on the judging build.

| # | What | How | Feeds |
| --- | --- | --- | --- |
| 1 | **One full poetry battle**, through the stitched song and the crown | The arena Mac's picture with **⌘⇧5** (Record Entire Screen, the browser full screen). **Both phones screen-recording** (Control Center, Do Not Disturb on). **One phone camera wide** on a stand, landscape, 1080p 60 fps: the poets and the screen in frame, and it carries the **room audio**. **One clap** in view of the wide camera before the 3-2-1, for syncing | 0:00–1:55: the cold open, the battle, the verdicts, the carved line, the song, and the "more battle" at 1:15 |
| 2 | **A ~10-minute montage on phone cameras:** archery in camera mode, the Stadion, boxing, discus. Every teammate on every game. Keep the misses, reactions and high-fives. Shoot 120 fps slow-mo for the arrow release and the discus swing | Phone cameras, 60 fps landscape (plus Slo-mo) | 2:00–2:30, the training montage |
| 3 | **Matus's line 2**: "AI can write anything now. It can't stand up and move a room." | **Voice Memos**, close to the mic, in a quiet corner; 3 takes | 0:15 |

**Safety for the montage:** a grippy case or a wrist strap on every swung phone, arm room all around, and nobody next to the laptops.

**Hand-off:** AirDrop every file to the Mac and tell builder where they are. Name them `battle-mac.mov`, `battle-phoneA.mp4`, `battle-phoneB.mp4`, `battle-wide.mov`, `montage-*.mov` and `line2.m4a`.

### (d) The CapCut track layout

| Track | What's on it |
| --- | --- |
| **V1** | All footage, in timeline order. Hard cuts on the beat of the theme; no transitions except one fade into C6. **The training montage (2:00–2:30):** CapCut → Speed → **Curve** on each clip, 2–4× through the run-up, and a ramp back to 1× (or the 120 fps slow-mo at 0.25×) on the hero beat: the release, the swing, the reaction. Mute each montage clip's own audio. |
| **V2** | Cards C1–C6 and lower thirds L1–L17, as PNGs from artist (transparent background for the lower thirds) |
| **Captions** | Burned in (CapCut → Text → Auto captions, then corrected word for word against the narration table and the real transcripts). Inter, white with a thin dark shadow, bottom-center, above the lower-third zone |
| **A1** | The room and Homer: camera sound, the arena's audio, Homer's live lines, and the nine rendered narration lines plus Matus's line. Normalize to about −14 LUFS |
| **A2** | Matus's theme at **−18 dB**, ducked a further ~10 dB under any voice (CapCut → Audio → Ducking on A2, keyed to A1). **Mute A2 completely under every poet's verse.** **From 2:00 to 2:30 the theme comes up to full volume** (about −6 dB), ducked only under Homer's line 8, and drops back to −18 dB at the Figma section. |

**Export:** 1080p, 30 or 60 fps, H.264, AAC 48 kHz, **2:59 at most**. Also export the first 2:00 on its own (it ends on C5) for Cartesia.

### Morning, 7:00 (Matus; done by 8:00)

1. Watch builder's **rough-cut-v1** once, start to finish, with the sound on.
2. Tell builder any fixes, in one message, by 7:20.
3. Upload the final cut to **YouTube as Unlisted**, with the title and description below.
4. Open the link in a logged-out window to check it plays, then paste it into Devpost's video field.
5. Done by **8:00**, before everyone checks in.

### (e) YouTube

**Title:** MeNIN: Ancient Greek Party Games, Hosted by Homer (Cal Hacks 13.0)

**Description:**

> A live voice poetry battle: speak a verse into your iPhone, and Homer judges it out loud within seconds. The big screen is a website; your phone is your mic and your hand of Homer's phrases.
>
> Try it: https://play.206.189.237.157.sslip.io/homer
> Code: https://github.com/sunya-afrasiabi/MeNIN
> Figma stage log: https://www.figma.com/slides/oYPLd3JeIjhnkNyt75qfOm
>
> 0:00 Cold open
> 0:25 The poetry battle
> 1:15 The website
> 1:35 How it works
> 2:00 The games
> 2:30 The Figma workflow
> 2:50 Team
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
