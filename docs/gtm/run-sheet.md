# Demo-day run sheet

Logistics for judging day, Sunday Oct 25: what goes where, what gets charged, how the table is set, how we reset between judges, and what to do when something breaks. The 2-minute script is in [demo-script.md](demo-script.md), and what the app does in demo mode is in `docs/ux-flow.md`, section 6. This sheet doesn't repeat them.

**Print it, and tape a copy to the back of the Mac's lid.**

**Our gear (Matus's list):** one Mac (a MacBook Air), three iPhones and power banks. There's no iPad and no portable monitor. gtm checked the venue items against the Hacker Guide and the Cal Hacks announcements on Fri Oct 23, and marks them **(confirmed)** or **(not in the guide)**.

## Sunday timeline

| Time | What | Who |
| --- | --- | --- |
| Sat 11 PM | Feature freeze. The demo build goes to TestFlight and is installed on all three iPhones and the Mac. Write the build number here: ______ | iOS lead |
| Sat night | Everything charges overnight to 100% (see Power). Five rematch drills in a row, timed. Save the backup video (`menin-backup-90s.mp4`; spec in [video.md](video.md)) to the Mac **and** to all three phones, in **Files → On My iPhone**, and play it once in Airplane Mode. On the Mac, confirm `python3 --version` works (it needs Xcode or the Command Line Tools) and that the repo is pulled, then run the demo check once against the production URL. | All |
| Sun 7:00 | Pack, using the list at the bottom. | All |
| 8:00 | At the venue. | All |
| 8:45 | Devpost submitted, every track tagged. The hard deadline is 9:00. | Matus |
| 9:00–9:20 | **Get our judging table number and move there.** The Hacker Guide: "Shortly after the 9:00 AM submission deadline, all projects will be assigned a table number. You will need to move to your assigned table by 10:30 AM." Watch #0-announcements and the app. The table may not be where we hacked. | Matus |
| 9:20–10:00 | Hall check **at the assigned table**: find the nearest hardline switch (there's one every 3 tables, per the announcements), plug in ethernet, and **run the demo check until it says GO with no no-go warnings** (see Before each judge). Then set sound at demo volume, run the noise test, and do two full warm-up runs. If no switch reaches, tell a director immediately. Two teams had dead table ethernet on Friday night: one got no DHCP address, and one had a tripped cable. If the Mac shows no IP address on ethernet, tell a director right away and use venue Wi-Fi meanwhile. | All |
| 10:15 | Table set: demo config loaded, the main room open, **the backup room created on the Mac** (code written down), and the backup video cued. | Operator |
| 10:30–12:30 | Judging. The whole team stays at the table. The guide: "If your entire team is not present while a judge comes, you will not be judged!" Take bathroom breaks one at a time, never two at once. Reset with the rematch drill between judges. | All |

## Device roles

Every device runs the same TestFlight build. Check under TestFlight, MeNIN, build number, and write it in the timeline above.

| Device | Held by | Role | Connection | Power |
| --- | --- | --- | --- | --- |
| **Mac (arena)** | Operator | **The arena, full screen, with the display turned to face the judges.** Demo config on, operator keys, latency HUD on. A Terminal sits on a second desktop for the demo check. The main room is live, and the **backup room is a second room code the Mac can switch to**. The backup video is paused in a second window. | Ethernet, through the USB-C adapter | **100% at the start.** Wall outlet if the table has one, or a power bank if one can feed it (see Power). |
| **iPhone A** | The poet | Poet 1: mic and hand. | Venue Wi-Fi, with cellular data as plan B | Power bank between runs |
| **iPhone B** | Matus | Poet 2: mic and hand, and the staged freeze. | Same | Same |
| **iPhone C** | Operator | **The spare, with duties in priority order:** 1) replaces a dead poet phone; 2) **backup arena** in arena mode, landscape, if the Mac dies (small, but it works); 3) plays the backup video if the Mac is gone; 4) the judge's phone after 2:00, for discus or a rematch. Grippy case. | Same | Same |

If iPhone C is already covering for a dead poet phone, the judge's phone after 2:00 is Matus's iPhone B, once his turn is done.

**On every device:**

- Do Not Disturb on, so no notification ever pops up on the arena.
- Ringer silent. Brightness up. System haptics on, since the beat lives in the poets' palms.
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
  - If none can, it doesn't matter much. An Air at 100% runs the 2-hour judging window plus setup on battery, with room to spare. Plug into the table's outlet if it has one; a hacker reported a dead outlet at their table on Friday, so don't count on it.
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

## Before each judge (about 2 minutes)

Before every run:

- [ ] The main room is open on the Mac, both poets have joined with their epithets, demo config is on, and the three theme cards are up.
- [ ] Push-to-talk works on both phones, and the haptic beat can be felt.
- [ ] Speaker volume is set and captions are on.
- [ ] The operator key "replay opening" is ready.
- [ ] The backup room code is written down, and the backup video is paused at 0:00 on the Mac.
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
| 0–2 | Press **Rematch**: same poets, new theme cards. | Lower the phones and reset your stance. |
| 2–6 | Check the arena: the theme cards are up and the old carved line is gone. | Check your phone: a new hand, and Hold to speak works. |
| 6–10 | Nod "ready". | Nod "ready". |

- **If it isn't reset in 10 s:** switch to the backup room (see Fallbacks). Don't press Rematch a second time.
- **Drill it Saturday night:** five times in a row, timed. Write the slowest time here: ______
- **More than 30 s until the next judge:** phones go back on their banks.

## Fallbacks

Each one is decided in advance and has a line to say, so nobody improvises at the table.

| What breaks | Trigger | Do this | Owner | Say |
| --- | --- | --- | --- | --- |
| **The room wedges.** A turn won't advance, Rematch doesn't reset, or a phone can't rejoin. | Over 10 s stuck | **Switch the Mac to the backup room.** The poets join it with the room code taped to the back of each phone, about 15 s. If the app itself is hung, force-quit it (⌘⌥⎋), relaunch, and open the backup room. | Operator | Matus: "Let's move to the other stage." |
| **One poet phone dies or freezes** | Any time | Hand that poet **iPhone C**. It joins the same room with the room code. | Operator | Matus keeps talking through the how-it-works line. |
| **The Mac dies** | Any time | **iPhone C becomes the arena**: arena mode, landscape, propped facing the judges, on the backup room. The speaker stays on if it's wired to the phone, otherwise it's phone audio. Small, but it's live. | Operator | "Same game, smaller box." |
| **The Mac dies and iPhone C is already covering a poet** | Any time | **Practice Spar on one iPhone:** the poet against Homer, with that phone as both the arena and the mic. Or play the backup video on a phone. | Operator, poet | "Let me show you against Homer himself." |
| **Network is slow or down** | Turns lag past the stall line twice | Decided by leader: ethernet into the Mac first, then cellular on the phones. **No hotspot (confirmed banned).** The Cal Hacks announcement on Fri 10:16 PM said: "Personal hotspots, routers, or other broadcasting equipment are prohibited inside the venue and we have tools to find who has these." Each phone uses its own cellular data instead, which isn't broadcasting. The Mac can't use cellular, so if its ethernet dies, **iPhone C on cellular becomes the arena.** | Operator, poets | "One second, the Wi-Fi in here is a battle of its own." |
| **Two failures in a row, or no network at all** | Any time | **Backup video**, 90 s, of the best Saturday-night run. Play it from the Mac's second window, or from any phone (it's saved on all three). Play it with sound. | Operator | Matus: "Here's last night's battle, start to finish." Then quiet. |
| **No verdict after 4 s** | Automatic | The stall line plays, and Beat and Range show. Keep going. | Nobody | Keep talking. Don't apologize. |
| **No verdict after 10 s** | Automatic | Beat and Range only. Move on. Never show a canned verdict. | Operator | "Homer's thinking. Let's hear the next one." |
| **STT keeps mishearing** (noise) | After one retry | Hold the EarPods mic closer to the mouth and use push-to-talk. If it fails again, play the backup video. | Poet | "That's what Homer heard. This hall is loud." |
| **The judge has 60 s, not 120** | At the start | Follow the 60-second cut in [demo-script.md](demo-script.md). | Matus | |

**Practice Spar isn't an offline fallback.** It still needs the network for Claude and Cartesia. It covers a wedged room or a dead Mac, not a dead network. Use the backup video when the network is down.

## To buy or bring (Matus decides)

Optional, but each one fixes a real risk at a loud, shared table:

| Item | Qty | Why | Note |
| --- | --- | --- | --- |
| **Wired USB-C EarPods** (Apple, about $20) | **3**: two poets plus a spare | The inline mic sits near the chin, and a poet can hold it up like a mic. Either way it's much closer to the mouth than the phone's mic at arm's length, so STT survives the hall. Wired means no pairing chaos with three phones in one spot. | Check each iPhone's port first. Any phone with Lightning needs the Lightning EarPods. |
| **A small wired speaker** (3.5 mm) | 1 | Mac speakers lose to a hall. A wired speaker on the **MacBook Air's headphone jack** has zero latency and nothing to pair. | Preferred. |
| A Bluetooth speaker, only if there's no wired one | 1 | Louder than the Mac | **Policy risk is low:** the ban targets hotspots and routers, and a Bluetooth speaker isn't network equipment. The phrase "other broadcasting equipment" is vague, though, so unplug it if a director objects and fall back to the Mac speakers. **The real risk is technical:** Bluetooth adds roughly 150 to 300 ms of audio delay. At 80 BPM a beat is 750 ms, so the drum would land a quarter-beat behind the beat lane and the haptic beat in the poets' palms. Bluetooth also drops out in a crowded 2.4 GHz hall. If we use one, use it for Homer's voice and keep the count-in drum short, or have the app apply an audio offset. |
| **USB-C to Ethernet adapter** | 1 | **Required, not optional.** The MacBook Air has no ethernet port, and the venue Wi-Fi is slow. | Reserve the ethernet cable in the H@B app as well. |
| A power bank with **≥30 W USB-C PD** | 1 | Feeds the Mac under load | Only if none of the current banks can (see Power) |
| A grippy phone case or a wrist strap | 1 | For discus, on iPhone C | |

## Packing list

- [ ] Mac and its charger (for the wall outlet, if the table has one)
- [ ] iPhones A, B and C
- [ ] USB-C to Ethernet adapter, plus the reserved ethernet cable
- [ ] Speaker and its cable, charged
- [ ] Wired EarPods ×3 (two poets plus a spare), checked against each phone's port
- [ ] Power banks, all at 100%, plus short USB-C cables for every device
- [ ] A grippy case or wrist strap, for discus
- [ ] Gaffer tape, for the cables and the room codes on the backs of the phones
- [ ] The backup video, saved locally on the Mac and all three phones (not streamed)
- [ ] This sheet, printed
