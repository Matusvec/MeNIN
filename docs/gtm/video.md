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

The evening is full: the study runs 6–8 PM, the extras checkpoint is at 8, karaoke is 8–9:30 in the Theater, and the hall noise test is at 9. So **the main battle shoot happens at 5 PM**, after the 2 PM battle checkpoint, and only the extras get filmed after 8.

| Time (Sat) | What | Who |
| --- | --- | --- |
| Any time before 5 PM | B-roll, 2 minutes at most per shot: the haptic beat in a palm (close-up), a hand of formula cards, a thumb on the discus button | Whoever has a free minute |
| **5:00–5:45 PM** | **The main shoot**, in the quietest corner you can find. Not the Theater, where SpacetimeDB's workshop runs 4–5. Three demo-mode battle takes back to back, plus the first-open line on its own. | Everyone (roles below) |
| 5:45–6:00 PM | Copy the footage to the Mac. **Export the backup video now**, so it exists even if the evening goes wrong. | Matus, operator |
| 6–8 PM | **The first-timer shot**, during the study (`docs/study.md`). Film only someone who said yes to consent question 4, and film **the screen and their voice, never their face**. Matus starts the Devpost edit in between. | Poet runs the study; a second person films |
| 8:00 PM | The extras checkpoint decides whether debate and discus appear at 1:15–1:25 | Leader |
| 8:05–8:20 PM | If they passed: film 5 s of Socrates opening a debate and one discus throw | Operator, Matus |
| 8:20–9:00 PM *(optional)* | Karaoke in the Theater, with the arena and two phones: Hacker's Choice clips ([below](#hackers-choice-clips-separate-from-both-videos)) | Poet + one more |
| 9:00–9:30 PM | Hall noise test (reality-check.md) | Everyone |
| 9:30–11:00 PM | Finish the Devpost edit | Matus |
| 11:00–11:15 PM | Upload to YouTube, put the link in Devpost, and copy the backup video to every device | Matus, operator |
| 11 PM | Feature freeze ([reality-check.md](reality-check.md) checkpoint). The video can still be added to Devpost after this; only the code freezes. | |

**If the 2 PM battle checkpoint failed:** the main shoot moves to 8:20 PM, right after the extras check, and karaoke is dropped.

**Before the shoot:** run `memory_pressure | grep 'free percentage'` on the Mac. Quit Xcode and every simulator for the shoot and the edit, and confirm at least 30% free. OBS and iMovie each need memory, and the Mac is shared with the Claude sessions.

## Roles at the shoot

| Role | Who | Does |
| --- | --- | --- |
| Arena + capture | Operator | Runs the arena Mac in demo mode and starts and stops OBS. Calls "rolling" and "cut". |
| Poet 1 | The poet | Performs, and starts their own screen recording before each take |
| Poet 2 | Matus | Performs (with the staged freeze), and starts their own screen recording |
| Camera | [composer, if there; otherwise iPhone C propped on a stand by the operator] | iPhone C on the wide shot |
| Voiceover | Matus | Two lines, recorded separately in the quietest spot available |
| Editor | Matus | Both videos, in iMovie on the Mac |

## Capture settings

### The arena Mac: OBS Studio

The Mac's built-in screen recorder (⌘⇧5) records the picture, but it can't be trusted to capture the app's own sound. OBS's macOS Screen Capture source records both: Homer, the beat and the score.

| Setting | Value |
| --- | --- |
| Source | **macOS Screen Capture**, method **Application**, set to MeNIN, with **Capture audio** on. Mute the mic and any desktop-audio source, so OBS only hears the app. |
| Base and output resolution | The display's own size (System Settings → Displays). The output keeps the same shape at 1920 wide. |
| Frame rate | 60 fps, to match the scene |
| Encoder | **Apple VT H264 Hardware Encoder**, CBR, 20,000 Kbps. The hardware encoder keeps the CPU free for the app. |
| Recording format | **MKV**, which survives a crash. Afterwards, use File → Remux Recordings to get an MP4. |
| Audio | 48 kHz |
| On the Mac | Notifications off, Dock hidden, the cursor parked off the arena, MeNIN full screen, demo config on, and captions on |

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

**Syncing:** start every take with one clap in view of iPhone C. Line up the camera and OBS on the count-in's first drum hit, and the phone recordings on the moment the hand appears.

## The Devpost video: shot list (2:00)

The video uses **only our original score** under the narration, and only the beat under a verse. Because we own the music, YouTube won't mute or claim it. **No "Wii" anywhere in the video, not even in the voiceover.** It's published and permanent, so the spoken comparison stays at the table.

| Time | Shot | Source | Sound |
| --- | --- | --- | --- |
| 0:00–0:10 | **Cold open.** The poet, EarPods in, spits two lines. The scene moves with the voice, its color fields shift, the beat lane fills, a card flips. No narration. | Camera wide, cut to the OBS close-up | Room mix |
| 0:10–0:16 | Title card **μῆνιν · MeNIN**, with "Rage. The first word of Western literature." underneath. Homer's first-open line plays under it. | Editor, plus the OBS first-open take | Homer's first-open line and its music bed |
| 0:16–0:20 | The event menu: the poetry battle lit, other passed events lit, the rest locked. Matus's voiceover: "MeNIN. Ancient Greek party games, with your iPhone as the controller." | OBS | Hall theme, ducked |
| 0:20–0:50 | **The battle.** The theme lands; the private hand on a phone; the haptic beat in a palm (B-roll); Homer's verdict with five scores counting up. **The freeze rescue:** the hand comes forward with one card raised, and Homer whispers. | OBS, phone recordings, B-roll | The arena's sound (beat, Homer) and the room mix |
| 0:50–1:00 | The round verdict: the best line carved in gold | OBS | Homer, then the round-end cue |
| 1:00–1:15 | **Bard lesson 1 with a first-timer** from the study: a miss, one note from Homer, then they land it. On screen: "Beat [first] → [last]". Screen and voice only, no face. | The first-timer's phone recording | The lesson's own sound |
| 1:15–1:25 | *Only if it passed at 8 PM:* 5 s of Socrates opening a debate (a different voice), then 5 s of a discus throw: the swing (camera), the flight on the arena (OBS), the fanfare. If neither passed, give the stitched song 10 s more. | Camera, OBS | Their cues |
| 1:25–1:40 | **How it's built, in one frame:** iPhone mic → on-device onsets (beat lane) and Cartesia STT with your hand as keyterms → SpacetimeDB → arena Metal scene, plus the Claude judge with the stress scanner. Caption: "3% word error with the drum at full volume, in our tests (20% without keyterms)". Use the real-mic number instead if swift's rerun replaced it. Voiceover: "Nothing here is mocked." | A diagram. **Make it in FigJam** and log it in the Figma stage log, since that's real Figma work. | Voiceover over the hall theme, ducked |
| 1:40–1:55 | The stitched song over the battle's colors, each line with its poet's name | OBS | Homer and the beat |
| 1:55–2:00 | The champion. End card: [TestFlight link] or playmenin.tech, "Original score by [composer's name]", and the team | OBS, editor | Champion cue |

**Captions:** burn them in for every spoken line, Homer's and the poets', in the app's own type style. Judges often watch on mute.

**Export:** 1080p, H.264, AAC, under 2:00 exactly.

**Upload:** YouTube, titled **"MeNIN: Ancient Greek Party Games, Hosted by Homer (Cal Hacks 13.0)"**. The description gets the Devpost tagline, the repo link and "Original score by [composer's name]". The Devpost page says submissions "should also include a clear, meaningful video demo on devpost **for sponsors evaluating asynchronously**". So the video is effectively required, and **some sponsor judges may score us from the video alone**: it has to carry every sponsor's story without us in the room. No length limit is stated. Devpost's video field generally takes YouTube or Vimeo links, so upload as **unlisted** unless the form says otherwise. Cartesia's 2-minute brief and Figma's 3-minute cap are confirmed.

## The backup video (90 s)

**What it's for:** if the network dies at the table, the operator plays this and we narrate it live. We say plainly, "This is last night's battle."

**What it is:** the best of the three demo-mode takes from the main shoot, from OBS with the room mix underneath, trimmed only to cut dead air. There's no voiceover and no added music, just the app's own sound. A 2-second card opens it: "Recorded live, Sat Oct 24".

| Time | What |
| --- | --- |
| 0:00–0:02 | Card: "Recorded live, Sat Oct 24" |
| 0:02–0:06 | Homer's first-open line |
| 0:06–0:10 | Theme card and the poet's entrance |
| 0:10–0:25 | Turn 1 |
| 0:25–0:31 | Verdict |
| 0:31–0:49 | Turn 2, with the freeze rescue |
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
