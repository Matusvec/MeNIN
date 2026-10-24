# Demo-day run sheet

Logistics for judging day, Sunday Oct 25: what goes where, what gets charged, how the table is set, how we reset between judges, and what to do when something breaks. The 2-minute script is in [demo-script.md](demo-script.md), and what the app does in demo mode is in `docs/ux-flow.md`, section 6. This sheet doesn't repeat them.

**Print it, and tape a copy behind the arena screen.**

gtm checked the **(confirm)** items against the Hacker Guide and the Cal Hacks announcements on Fri Oct 23. Results are marked **(confirmed)** or **(not in the guide)**. Items marked **(needs iPad + iPhone C)** depend on the team having those devices. Matus is confirming.

## Sunday timeline

| Time | What | Who |
| --- | --- | --- |
| Sat 11 PM | Feature freeze. The demo build goes to TestFlight and is installed on every team device. Write the build number here: ______ | iOS lead |
| Sat night | Everything charges overnight (see Charging). Five rematch drills in a row, timed. | All |
| Sun 7:00 | Pack, using the list at the bottom. | All |
| 8:00 | At the venue. | All |
| 8:45 | Devpost submitted, every track tagged. The hard deadline is 9:00. | Matus |
| 9:00–9:20 | **Get our judging table number and move there.** The Hacker Guide: "Shortly after the 9:00 AM submission deadline, all projects will be assigned a table number. You will need to move to your assigned table by 10:30 AM." Watch #0-announcements and the app. The table may not be where we hacked. | Matus |
| 9:20–10:00 | Hall check **at the assigned table**: find the nearest hardline switch (there's one every 3 tables, per the announcements), plug in ethernet, set sound at demo volume, run the noise test, and do two full warm-up runs. If no switch reaches, tell a director immediately. | All |
| 10:15 | Table set. Demo config loaded, the main hall open, the backup hall open, the backup video cued. | Operator |
| 10:30–12:30 | Judging. The whole team stays at the table. The guide: "If your entire team is not present while a judge comes, you will not be judged!" Take bathroom breaks one at a time, never two at once. Reset with the rematch drill between judges. | All |

## Device roles

Every device runs the same TestFlight build. Check under TestFlight, MeNIN, build number, and write it in the timeline above.

| Device | Held by | Role | Connection | Power |
| --- | --- | --- | --- | --- |
| **Arena Mac** | Operator | The arena, full screen, demo config on. Operator keys. The backup video sits paused in a second window. Latency HUD on. | Ethernet, through the USB-C adapter | On its charger the whole time |
| **Big screen** | none | Shows the Mac's arena to the judges, over HDMI. Mirrored, so the operator sees the same thing. | HDMI from the Mac | **(not in the guide)** The guide says nothing about monitors at judging tables, only that each table is shared by 2-3 teams. **Bring our own screen**: a teammate's portable monitor, if anyone has one. Otherwise the Mac's own display is the arena, turned to face the judges, with the operator beside it. Power isn't guaranteed either: a hacker reported a dead outlet at their table on Friday, so bring the power strip and charge everything to 100%. |
| **Wired speaker** | none | Homer's voice and the beat. Aimed at the judges, low and close. | 3.5 mm or USB from the Mac | Wall or charged |
| **iPhone A** | The poet | Poet 1: mic and hand. | Venue Wi-Fi. Cellular as plan B | Charged; on a cable until the judge arrives |
| **iPhone B** | Matus | Poet 2: mic and hand, and the staged freeze. | Same | Same |
| **iPhone C** **(needs iPad + iPhone C)** | Operator, handed to a judge | The judge's phone after 2:00, for discus or a rematch. Grippy case, plus a wrist strap if we have one. | Same | Same |
| **iPad** **(needs iPad + iPhone C)** | Operator | The backup arena, holding the backup hall open. A second copy of the backup video is saved on it. | Venue Wi-Fi. Cellular if it has it | Charged |

**On every device:**

- Do Not Disturb on, so no notification ever pops up on the arena.
- Ringer silent. Brightness up. Low Power Mode off. System haptics on, since the beat lives in the poets' palms.
- On the Mac: notifications off, sleep and the screen saver off, the Dock hidden, and nothing open except MeNIN and the backup video.

**Headsets:** iPhones have no headphone jack, so bring wired USB-C (or Lightning) headsets, or the right adapters. Test each headset on its own phone. A wired headset uses the charging port, so phones charge between judges, not during a run.

## Charging

- **Saturday night:** charge every phone, the iPad, the Mac, the speaker and both battery packs to 100%.
- **At the table:** the Mac stays on its charger. Phones sit on short cables until a judge walks up (per the demo script), then come off for the run.
- **The 40% rule:** any phone under 40% swaps roles with a fuller one between judges and goes on charge. Write the swap on the sheet, so nobody grabs the wrong phone.
- **Budget:** mic streaming, the screen at full brightness and constant network drain a phone fast. Expect roughly 15 to 20% an hour during judging. Top-ups between judges cover a 2-hour window.

## Room setup

Rough table layout, with the judges in front:

```
            [ big screen ]   [speaker]
   Poet (A)                         Matus (B)
              [ arena Mac ]
               Operator

   ---------- judges sit here ----------

   (discus space: one arm's length clear, away from the table)
```

- **The screen** faces the judges, with captions readable from their seats.
- **The speaker** sits low and close to the judges. Set the volume during the hall check: loud enough over the noise, not so loud it reaches the next team.
- **The poets** stand on either side of the screen, facing the judges, headsets on, phones in hand. They're performing, not reading the screen.
- **The operator** sits behind the Mac, in reach of its keys, and says nothing during a run.
- **Discus space:** before any throw, check one arm's length of clear space away from the shared table, the screen and the neighbors' laptops. The release is a thumb lift, never an open hand.
- **Cables** are taped down where people step.
- **Optional:** a small card on the table with MeNIN, its pronunciation (MAY-nin), and the Devpost QR code.

## Before each judge (about 2 minutes)

Before every run:

- [ ] The main hall is open, both poets have joined with their epithets, demo config is on, and the three theme cards are up.
- [ ] Push-to-talk works on both phones, and the haptic beat can be felt.
- [ ] Speaker volume is set and captions are on.
- [ ] The operator key "replay opening" is ready.
- [ ] The backup hall is open on the iPad and the backup video is paused at 0:00.
- [ ] The latency HUD shows the last run's verdict under 3.5 s.
- [ ] Phones come off their chargers only when the judge sits down.

## The rematch drill

Between judges, or after a judge stays for a rematch. The spec's target is under 10 seconds.

| Seconds | Operator | Poets |
| --- | --- | --- |
| 0–2 | Press **Rematch**: same poets, new theme cards. | Lower the phones and reset your stance. |
| 2–6 | Check the arena: the theme cards are up and the old carved line is gone. | Check your phone: a new hand, and Hold to speak works. |
| 6–10 | Nod "ready". | Nod "ready". |

- **If it isn't reset in 10 s:** switch to the backup hall (see Fallbacks). Don't press Rematch a second time.
- **Drill it Saturday night:** five times in a row, timed. Write the slowest time here: ______
- **More than 30 s until the next judge:** phones go back on their cables.

## Fallbacks

Each one is decided in advance and has a line to say, so nobody improvises at the table.

| What breaks | Trigger | Do this | Owner | Say |
| --- | --- | --- | --- | --- |
| **The hall wedges.** A turn won't advance, Rematch doesn't reset, or a phone can't rejoin. | Over 10 s stuck | **Backup hall (needs iPad + iPhone C).** The iPad holds a second hall, already open. Put it on the big screen (iPad to HDMI). The poets join it with the room code taped to the back of each phone, about 15 s. | Operator | Matus: "Let's move to the other stage." |
| **One phone dies or freezes** | Any time | **(needs iPad + iPhone C)** Hand the poet iPhone C. It joins the same hall with the room code. | Operator | Matus keeps talking through the how-it-works line. |
| **The Mac dies** | Any time | **(needs iPad + iPhone C)** The iPad becomes the arena, on the backup hall, plugged into the screen. | Operator | "Same game, smaller box." |
| **Network is slow or down** | Turns lag past the stall line twice | Decided by leader: ethernet into the Mac first, then cellular on the phones, and a hotspot only if the venue allows it. **The venue has already answered: no hotspot (confirmed banned).** The Cal Hacks announcement on Fri 10:16 PM said: "Personal hotspots, routers, or other broadcasting equipment are prohibited inside the venue and we have tools to find who has these." Each phone uses its own cellular data instead, which isn't broadcasting. The Mac can't tether, so it stays on ethernet. If ethernet dies, the iPad becomes the arena, on cellular if it has it. | Operator, poets | "One second, the Wi-Fi in here is a battle of its own." |
| **Two failures in a row, or no network at all** | Any time | **Backup video**, 90 s, of the best Saturday-night run, from the Mac's second window or the iPad. Play it with sound. | Operator | Matus: "Here's last night's battle, start to finish." Then quiet. |
| **No verdict after 4 s** | Automatic | The stall line plays, and Beat and Range show. Keep going. | Nobody | Keep talking. Don't apologize. |
| **No verdict after 10 s** | Automatic | Beat and Range only. Move on. Never show a canned verdict. | Operator | "Homer's thinking. Let's hear the next one." |
| **STT keeps mishearing** (noise) | After one retry | Bring the headset closer to the mouth and use push-to-talk. If it fails again, play the backup video. | Poet | "That's what Homer heard. This hall is loud." |
| **The judge has 60 s, not 120** | At the start | Follow the 60-second cut in [demo-script.md](demo-script.md). | Matus | |

**Practice Spar isn't an offline fallback.** It still needs the network for Claude and Cartesia. It covers a wedged multiplayer hall, not a dead network. Use the backup video when the network is down.

## Packing list

- [ ] Arena Mac and its charger
- [ ] iPhones A, B and C, and the iPad
- [ ] USB-C ethernet adapter (the MacBook Air has no ethernet port), and the reserved ethernet cable
- [ ] HDMI cable, plus USB-C to HDMI adapters for both the Mac and the iPad
- [ ] Wired speaker and its cable, charged
- [ ] Two wired headsets with mics, plus a spare, plus any adapters
- [ ] A power strip, short charging cables for every device, and two battery packs
- [ ] A grippy phone case, plus a wrist strap if we have one, for discus
- [ ] Gaffer tape, for the cables and the room codes on the backs of the phones
- [ ] The backup video, saved locally on the Mac and the iPad (not streamed)
- [ ] This sheet, printed
