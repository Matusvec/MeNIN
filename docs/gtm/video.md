# Video plan

Two videos, both from real takes. Nothing is mocked, and nothing is shown as live when it isn't.

| | The Devpost video | The backup video |
| --- | --- | --- |
| Length | **2:00** | **90 s** |
| For | Devpost, plus Cartesia ("2-minute, demo-first") and Figma (3 minutes max) | The judging table, when the network is down ([run-sheet.md](run-sheet.md)) |
| Narration | Two short voiceover lines | None |
| Edit | Cut between camera, arena and phone footage | One battle take, trimmed only |
| Where it lives | YouTube, linked on Devpost | On the Mac and all three iPhones, **offline** |

## When

**The shoot follows Matus's "done" call** (Matus: "no filming till done": archery and boxing v2 are finished first; leader, Sat ~6:05 PM). It has no fixed time; likely about 9:00–9:30 PM, and it has to finish before the 11 PM freeze. Nothing has been filmed yet: the 1:30 PM gate run and the 5 PM shoot were both postponed. The order is fixed: **the poetry battle first**, then **discus** with the new angle display, then **Talk to Homer**, then **boxing** and **archery**, each only if it's clean. Matus reports the poetry and debate check runs as done; multiplayer is tallying the clean counts, so the shoot is no longer the gate.

**The build:** one build on both phones for the whole shoot, the newest TestFlight build that has Talk to Homer and boxing (build 19 or later; leader names it at setup). Never mix builds in one take, and write down which build each take used. The arena is the website, with its live scene. That's the game judges will play: Homer's three phrases, fresh Homeric themes and epithets, free verse with one SPEAK and a countdown ring, content-only scores out of 100, the hands-free mic, the rescue after about 2.5 s of silence (never in the first 3 s after SPEAK), and no sound effects. 11 PM is a reshoot only if something's missing.

| Time (Sat) | What | Who |
| --- | --- | --- |
| Any time before the "done" call | B-roll on the shoot build, 2 minutes at most per shot: the countdown ring closing on a phone, Homer's three phrases on a phone, SPEAK filling a phone in the poet's color, a thumb on the discus button, the discus angle display | Whoever has a free minute |
| 6–8 PM | **Only if the study runs** (Matus hasn't confirmed it): **the first-timer shot**, during the study (`docs/study.md`). Film only someone who said yes to consent question 4, and film **the screen and their voice, never their face**. | Poet runs the study; a second person films |
| 8:00 PM | The extras checkpoint: multiplayer's clean counts decide whether debate appears in the video. Discus needs 5 clean runs on build 31 (leader and pm, Sat ~8:25 PM: the build-18 pass came before discus v2 shipped in build 21). | Leader |
| **On the "done" call** (likely ~9:00 PM) | **Setup and go/no-go, about 15 minutes** ([below](#the-evening-shoot-on-matuss-done-call)). The shoot starts only if (1) **the same shoot build, 31 or later, is on both phones** (Settings → About in MeNIN) (2) **Cartesia works**: Homer speaks and the mic transcribes (it was dead with HTTP 402 at 3:40 PM), (3) the website shows the live scene, and (4) **Matus gives the go**. If boxing or archery isn't clean, shoot everything else without it. | Operator, camera teammate, Matus |
| **15 minutes after the call, about 30 minutes** | **The shoot,** in this order: (1) **two full poetry battles** back to back (Rematch between them), plus the first-open line on its own; (2) **one or two discus throws** showing the new angle display, only if discus has passed its 5 runs on 31; (3) **one short Talk to Homer exchange** in a Judge hall (you speak; Homer answers in two sentences, quoting you, with one fix); (4) **one boxing exchange** and (5) **one archery shot**, each only if it's clean. If Fetch shipped, also the ASI:One screen recording for the Fetch cut. Use the quietest corner you can find. | Everyone needed |
| Before the call, or right after the shoot | Hall noise test (reality-check.md): run it while waiting for "done" if the hall is at peak noise, otherwise right after the shoot | Everyone |
| After the shoot, until 11 PM | Copy the footage to the Mac. Matus checks it against the shot list, marks anything missing for 11 PM, **exports the backup video from the best poetry take**, then edits the Devpost video and the Fetch cut if needed. | Matus, operator |
| 11:00–11:15 PM | **Reshoot only if a shot is still missing** (the freeze is code only; a pickup can still happen right after it). Then upload to YouTube, put the link in Devpost, and copy the backup video to every device. | Matus, operator |
| 11 PM | Feature freeze ([reality-check.md](reality-check.md) checkpoint). The video can still be added to Devpost after this; only the code freezes. | |

**Karaoke (8:20–9:00 PM) is dropped:** it may overlap the shoot, and the poet is needed at both.

**If the shoot fails** (the battle breaks mid-take), footage from a failing run is useless. Fix it and reshoot; the code freeze at 11 PM doesn't stop filming, but the upload has to be done before the 8:45 AM submission.

## The evening shoot (on Matus's "done" call)

**If any recording slows the arena or the phones, stop recording, not the run.**

**Two poetry takes, back to back.** Take 1 is the main footage; take 2 is the safety, and whichever is cleaner becomes the backup video. **Take 2 also tests the Spacetime rejoin** (unless multiplayer's runs already covered it): mid-battle, poet 1 force-quits MeNIN, reopens it and rejoins, and should get their seat back with their score. The operator notes whether it worked; it goes in the pitch and the README only if it did. Read the turn-to-voice time off the latency HUD in both takes for Devpost's `[turn-to-voice p50]`. Homer writes a fresh theme and coins fresh epithets each take, so nothing repeats and nothing needs to match between takes. Cut within one take, never across two.

**Then the extras, in order,** each on all the cameras that still apply: discus (the swing on C, the angle display and the flight on A), Talk to Homer (A for Homer's two-sentence reply, B over the speaker's shoulder), then boxing and archery, each only if it's clean (C for the players, A for the screen).

**Before setup:** **keep the arena Mac awake:** run `caffeinate -dims` in a Terminal for the whole shoot, keep the Mac plugged in if there's power (on battery, `-i` still keeps it awake), keep the arena tab in front in its own full-screen window, and keep the lid open (leader: at 4:24 PM the phones and the arena all dropped in the same second; network blips self-recover with "Reconnecting…", but a sleeping Mac or a closed tab kills the battle). Then check `memory_pressure | grep 'free percentage'` on the Mac and get it to at least 30% free (quit Xcode and the simulators). Make sure every phone has at least 5 GB free and Do Not Disturb on. Load the website full screen in the Mac's browser and click **"Open the hall" to open a fresh hall**, never "Resume" an older room: older rooms keep older settings (leader). The click also lets the browser play Homer's voice, so check that Homer speaks. Start every recording, then **clap once in view of every camera**. Then the operator starts the battle.

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

## The Devpost video: shot list (2:00)

**The limit is 3 minutes, and the video is required** (MLH staff, #0-ask-directors and #0-general, Sat 6:29 PM: "3 min"; "you also need to include a 3 min video in your Devpost"). Our 2:00 cut fits. **The video may be the first round.** MLH and organizers (#0-ask-directors, Sat 2:56–3:40 PM): "3 minutes for the video demo", "you can make your video demo more demo-focused and your live demo more pitch-focused", and "depending on track popularity, some categories may need to do a virtual first pass." The 2:00 cut fits. If Matus extends it toward 3:00, the extra time should be demo (a second full turn, or debate and discus if they pass at 8 PM), not talk.

**Built for judges who aren't in the room.** Devpost says the video is for "sponsors evaluating asynchronously", and Cartesia's staff have been hard to find. So the video has to carry each sponsor alone: name every sponsor on screen, show the keyterm numbers with how we measured them, and give responsibility its own card.

The video uses **only our original score** under the narration, and nothing under a verse (battles are free verse; the beat returns only under the stitched song and in the lesson clip). Because we own the music, YouTube won't mute or claim it. **No "Wii" anywhere in the video, not even in the voiceover.** It's published and permanent, so the spoken comparison stays at the table.

| Time | Shot | Source | Sound |
| --- | --- | --- | --- |
| 0:00–0:10 | **Cold open.** The poet, EarPods in, spits two lines. The scene moves with the voice, its color fields shift, the countdown ring runs, a phrase pops "+Craft". No narration. | Camera wide, cut to the OBS close-up | Room mix |
| 0:10–0:16 | Title card **μῆνιν · MeNIN**, with "Rage. The first word of Western literature." underneath. Homer's first-open line plays under it. | Editor, plus the OBS first-open take | Homer's first-open line and its music bed |
| 0:16–0:20 | **The voice battle leads** (leader, Sat ~8:45 PM: organizers shortlist each project for its best-fit track, so the first 20 s show the live poetry battle). Homer's verdict lands on the arena, scores counting up to a total out of 100. Matus's voiceover: "MeNIN. A live poetry battle. You speak, and Homer judges you out loud." | OBS | Hall theme, ducked |
| 0:20–0:50 | **The battle.** Homer's fresh theme lands; Homer's three phrases on a phone; 3, 2, 1, SPEAK filling the screen in the poet's color; the countdown ring; a used phrase popping "+Craft"; Homer's verdict with three scores counting up to a total out of 100. **The freeze rescue:** Homer's phrases come forward, the one that fits raised, and Homer whispers it. | OBS, phone recordings, B-roll | The poet's voice, Homer and the room mix (no beat in battle) |
| 0:50–1:00 | The round verdict: the best line carved in gold | OBS | Homer, then the round-end cue |
| 1:00–1:15 | **[A: the study ran]** **Bard lesson 1 with a first-timer** from the study: a miss, one note from Homer, then they land it. On screen: "Beat [first] → [last]". Screen and voice only, no face. **[B: no study]** **Bard lesson 1 with a teammate**, labelled as a teammate, never as a first-timer: a miss, Homer's note, the landed line, with their own Beat scores on screen. Or give the 15 s to the battle. | The lesson recording | The lesson's own sound |
| 1:15–1:25 | Open on a 1 s flash of the event menu (the poetry battle lit, every event that passed on 31 lit, the rest locked). Then 5 s of a **discus throw** (only if it passed its 5 runs on 31; if not, the poetry battle keeps these 10 s): the swing (camera), the angle display and the silent flight on the arena (OBS), the distance and the fanfare. Then 5 s of **either** Socrates opening a debate (only if debate passed at 8 PM; a different voice) **or** a boxing exchange (only if it's clean). If neither, the discus gets the full 10 s. | Camera, OBS | Their cues |
| *(optional)* | *Only if it's clean:* 5 s of **Talk to Homer**: a poet speaks, Homer answers in two sentences on the screen, quoting them. It adds about 5 s, still well under MLH's 3:00. | OBS | Homer's reply |
| 1:25–1:36 | **How it's built, in one frame:** iPhone mic → Cartesia STT with Homer's phrases as keyterms → SpacetimeDB → the website arena and its live scene, plus Homer the live agent on Claude with the stress scanner. **Name each sponsor on screen** (Spacetime, Cartesia, Claude, Figma), since a sponsor judge may only ever see this video. Caption: "3% word error in our tests, with a drum at full volume as the noise (20% without keyterms)". Under it, smaller: "Test recordings: recorded verse with our drum mixed in at 0 dB." Use the real-mic number if swift's rerun replaced it. Voiceover: "Nothing here is mocked." | A diagram. **Make it in FigJam** and log it in the Figma stage log, since that's real Figma work. | Voiceover over the hall theme, ducked |
| 1:36–1:40 | **Built responsibly**, one card: "Captions on everything Homer says · The mic opens only on your turn · No audio passes through our server · Homer never names your emotion · No account needed". It answers Cartesia's 25% on impact and responsibility, and Anthropic's "where it could go wrong". | Editor | Hall theme, ducked |
| 1:40–1:55 | The stitched song over the battle's colors, each line with its poet's name | OBS | Homer and the beat |
| 1:55–2:00 | The champion. End card: [TestFlight link] or playmenin.tech, "Original score by [composer's name]", and the team | OBS, editor | Champion cue |

**Captions:** burn them in for every spoken line, Homer's and the poets', in the app's own type style. Judges often watch on mute.

**Export:** 1080p, H.264, AAC, under 2:00 exactly.

**Upload:** YouTube, titled **"MeNIN: Ancient Greek Party Games, Hosted by Homer (Cal Hacks 13.0)"**. The description gets the Devpost tagline, the repo link and "Original score by [composer's name]". The Devpost page says submissions "should also include a clear, meaningful video demo on devpost **for sponsors evaluating asynchronously**". So the video is effectively required, and **some sponsor judges may score us from the video alone**: it has to carry every sponsor's story without us in the room. No length limit is stated. Devpost's video field generally takes YouTube or Vimeo links, so upload as **unlisted** unless the form says otherwise. Cartesia's 2-minute brief and Figma's 3-minute cap are confirmed.

## The Fetch.ai cut (3:00, only if Homer on Agentverse ships)

Fetch.ai requires "a demo video (3–5 minutes)", longer than our 2:00 Devpost video. Make one extra cut. Its URL goes in Fetch's ASI:One submission form ([opportunities.md](opportunities.md)).

| Time | Shot |
| --- | --- |
| 0:00–2:00 | The Devpost video as it is |
| 2:00–2:50 | **A screen recording of ASI:One on the Mac:** find Homer, ask for a theme, get five formulas, type a verse with two of them, and get Homer's verdict: five scores, the best line, a one-line roast. Narration: "The same judge, as an agent on Agentverse, usable from ASI:One." |
| 2:50–3:00 | End card: the agent's name and address, plus "Built with Fetch.ai Agentverse and the Agent Chat Protocol" |

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
