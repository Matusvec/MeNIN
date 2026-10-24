# Homer: UX flow

This doc is for Matus to design against. It covers the flow, the states, the timing and what each screen shows. Visual design is Matus's, so this doc describes what is shown and what changes, never how it looks. Words like "large" or "pinned" describe hierarchy.

`SPEC.md` (as of commit dc4363b) is the source of truth. Anything not in it is marked **Proposal Pn** and waits on Matus.

## How to read this

**Devices**

Homer is one iOS app, distributed through TestFlight. There is no web app. In a battle, each device runs the app either as the arena or as a player.

- **Arena**: the one big shared screen. It's the app in arena mode on a Mac (Apple Silicon Macs run iPhone apps), on an iPad, or on an iPhone mirrored to a TV. It shows the scene, the beat lane, the transcript and the scoreboard, plays Homer's voice and the beat, and shows the QR code to join.
- **Phone**: the app on each poet's iPhone, which is their mic and their private hand.
- **Solo modes:** Bard and Practice run on a single device. The Arena line describes the layout on a large screen (iPad or Mac), and the Phone line describes it on an iPhone.

**Each state lists**

- **Arena**: what the shared screen shows
- **Phone**: what the poet's phone shows
- **Homer**: what Homer says. Sample lines set the voice; the prompts own the final copy.
- **Next**: what moves it to the next state
- The duration is in each state's heading.

## Rules on every screen

- The scene is always on, including between states. When nobody is speaking it idles low. It never cuts to black.
- Whenever a mic is open, the live transcript is visible, so the poet can see what Homer heard.
- Everything Homer says is captioned on the arena. The hall is noisy, and some people will be watching rather than listening.
- Homer never names the speaker's emotion in words. The scene shows it.
- A score always comes with all five axes and the quoted line. A bare total never appears alone.
- There are no dead ends. Every finished state offers *again* and *next*.
- Only one voice at a time: Homer never talks over a poet. In battle, Homer's voice and the beat come from the arena.

## Decided and proposed

**Approved by Matus. These are in SPEC.md now, so the body below treats them as spec without tags.**

- **The beat:** a slow drum-and-lyre loop, four beats a bar, one line per bar. A stressed syllable that hits a beat sounds like a drum strike.
- **Freeze rescue:** about 1 s of silence mid-turn brings your hand forward, and Homer whispers one formula that fits. Lesson 2 teaches it.
- **Arena and phones:** one shared screen, and each phone is that poet's mic and private hand. You join by QR code or link.
- **Epithet as battle name:** you forge it in lesson 3 ("___, Breaker of Deadlines"). If you don't have one, Homer coins one when you join.
- **Carved line:** the best line of each round is carved in gold across the arena.
- **The stitched song:** at the finale Homer stitches every verse into one poem and performs it over the beat while the scene replays the battle's colors, then crowns the champion.

**Pending proposals**

| ID | Proposal |
| --- | --- |
| P7 | **Answer prompt.** During your turn, the previous poet's best line stays on screen as the thing you answer. |
| P8 | **Card reveal.** When you speak a formula from your private hand, that card turns over onto the arena for everyone to see. |
| P9 | **Voice menu.** Homer asks "Learn, train, or fight?" and you can answer out loud. Tapping still works. |
| P10 | **Help after misses.** In a lesson, after three misses Homer gives you the first half of the line. After five, he walks you through it and the lesson lands. |
| P11 | **Color replay.** When Homer re-reads your best line, the scene replays the colors it showed while you said it. |
| P12 | **The first 10 seconds.** No menu: Homer performs straight away and hands you the mic (section 1). |
| P13 | **Push-to-talk.** Hold to open the mic, for a headset or a noisy hall. The spec lists it as an open question. |
| P14 | **Demo mode.** A judging-table path that reaches the money moments within 2 minutes (section 6). |
| P15 | **One reroll.** If Homer coins your epithet on join, you can ask for another one, once. |

P1 to P6 were approved and are listed above.

---

## 1. The first 10 seconds (Proposal P12)

This is the first launch of the app. There is no menu, no sign-up and no tutorial text. Homer performs, then hands you the mic. A native app can play sound as soon as it opens, so no tap is needed first.

#### F0 · Launch · ~1 s

- **Arena:** The scene comes up and idles. Nothing else.
- **Phone:** Same.
- **Homer:** Silent, for one breath.
- **Next:** Automatic. Don't ask for the mic yet.

#### F1 · Homer spits · ~9 s

- **Arena:** Homer performs over the beat while the scene moves with his voice. His lines appear as he speaks, with each stress marked on the beat lane as it lands.
- **Phone:** Same.
- **Homer:** The audio ships inside the app, so it starts immediately.
  > **BLIND** as the **NIGHT** / I **SANG** the **SHIPS**.
  > I **NEV**er **WROTE** / a **SIN**gle **WORD**.
  > **NOW** it's your **TURN**. / **MAKE** it **YOURS**.
- **Next:** The verse ends after three bars at about 80 BPM.

#### F2 · The mic · ~3 s

- **Arena:** The lane resets to one empty line of four beats. iOS shows its mic permission prompt.
- **Phone:** Same.
- **Homer:** "Four beats. Break in the middle. Give me one line."
- **Next:** Mic allowed → F3. Mic denied → Fx.

#### F3 · Your first line · ~6 s

- **Arena:** A one-bar count-in, then one bar to speak. Your words land on the lane live, every stress on a beat sounds a drum strike, and the scene moves with your voice. If you freeze, the rescue whispers you a formula.
- **Phone:** Same.
- **Homer:** Silent, apart from a rescue whisper.
- **Next:** The bar ends.

#### F4 · First verdict · ~4 s

- **Arena:** Your line stays on the lane with its hits marked.
- **Phone:** Same.
- **Homer:** One line, based on the scan. Four hits: "Ha. The hall heard that." Fewer: "Two hits. Rough. But you spoke, and most never do."
- **Next:** The line ends. The scanner runs on our own server with no Claude call, so this is fast.

#### F5 · Choose · until choice

- **Arena:** Three choices: **Learn** (Bard), **Train** (Practice), **Fight** (Battle). Fight also offers "Join with a code".
- **Phone:** Same, stacked.
- **Homer:** "Learn, train, or fight?" With P9 you can say the word.
- **Next:** A tap, or a spoken choice with P9.

The mic opens about 10 to 12 s after launch.

**Other ways in**

- **A hall's QR code:** Scanning it with the camera opens the app straight into the battle join screen (J1), skipping all of this. Homer greets you in the hall instead.
- **Later launches:** one greeting line ("Back for more?"), then F5.
- **Fx · Mic denied:** Homer: "No voice, no song." A button opens Homer's page in iOS Settings, where you can turn the mic on, and then you retry. See open question 10.

---

## 2. Bard mode: learn from Homer

### The path

There are six lessons. Each one trains exactly one judge axis, so by the end of Bard mode you know how you will be scored.

| # | Lesson | The move | You try | It lands when | Trains |
| --- | --- | --- | --- | --- | --- |
| 1 | The beat | Four stresses a line, a pause in the middle | 2 lines | Both lines have four stresses and a break (scanner) | Beat |
| 2 | The formula | Fill half a line with a formula from your hand. Homer sets a hard line so you freeze, and the freeze rescue saves you | 1 line on Homer's hard prompt | A formula from your hand, whispered or picked yourself, fills one half and the line scans | Craft |
| 3 | The epithet | Coin your own ("___, Breaker of Deadlines"). It joins your hoard and becomes your battle name | Your epithet, then a line using it | It scans and the judge rates it well | Craft |
| 4 | The turn | Shift the feeling mid-verse | 4 lines | The emotion engine sees the leading emotion change between lines 1–2 and lines 3–4. The scene shows the shift | Range |
| 5 | The answer | Respond to a line Homer throws at you | 2 lines | Answer is 7 or more | Answer |
| 6 | The boast | Land a closing line that hits | Homer speaks 3 lines, you give the 4th | Image is 7 or more and the line scans | Image |

The "You try" and "It lands when" columns are suggestions; the numbers get tuned in testing. Lessons 1 to 3 are the minimum we ship (spec). Everything Homer says in each lesson is scripted in `content/lessons.md`.

#### Path · until a lesson is picked

- **Arena:** The six lessons, with landed ones marked and the next one suggested. From lesson 3 on, your epithet and hoard are shown too.
- **Phone:** Same, vertical.
- **Homer:** One line pointing at the next lesson, e.g. "Next, the formula. Half the line is already written."
- **Next:** Pick a lesson. See open question 8 on whether lessons are free-pick or in order.

How the path connects to the rest of the app: after lesson 3 Homer offers battle ("You have a name now. Go fight."). After lesson 6 he offers a spar ("You're a bard. Come spar with me.").

### One lesson, start to finish

Lesson 1 is used as the example. A lesson runs 2 to 5 minutes, which fits about three to six tries.

#### L0 · Title · ~2 s

- **Arena:** The lesson number, its name and the move in one line.
- **Phone:** Same.
- **Homer:** Speaks the lesson name.
- **Next:** Automatic.

#### L1 · Homer shows it · ~12 s

- **Arena:** Homer performs a verse that demonstrates the move, over the beat, while the scene moves with his voice. The parts that show the move are marked on the lane; in lesson 1, that's the four hits and the break.
- **Phone:** Same.
- **Homer:** A four-line verse that does the move.
- **Next:** The verse ends.

#### L2 · Homer names it · ~4 s

- **Arena:** Homer's verse stays on the lane, held still, as the model.
- **Phone:** Same.
- **Homer:** One or two sentences, never a lecture. "Four hits a line. Rest in the middle. That's the whole trick."
- **Next:** He finishes the line.

#### L3 · You try · count-in plus 1 to 4 lines

- **Arena:** A one-bar count-in, then the beat, the live lane, the transcript, and the scene moving with your voice. Homer's model line sits faded beside yours for comparison. From lesson 2 on, your hand is visible.
- **Phone:** The lane, the transcript and your hand. The model line is collapsed.
- **Homer:** Silent, apart from a freeze rescue. In lesson 2 the freeze is the point: Homer's prompt is meant to stop you, and the rescue is the lesson.
- **Next:** The required lines are done. With the beat, each line gets a speaking bar and a rest bar.

#### L4 · One note · ~3–4 s

- **Arena:** The single spot Homer is talking about is marked on your lane: a missed stress, a rushed break, or the half that wasn't a formula. Only ever one spot.
- **Phone:** Same.
- **Homer:** One thing, no more. "Three hits. You owe me one more." / "You rushed the break. Let it breathe."
- **Next:** Landed → L5. Otherwise back to L3.
- **Timing:** Lesson 1 feedback can come straight from the scanner without a Claude call, well under a second. Lessons 2 to 6 use the same ~3 s budget as the turn (see the latency budget in section 5).
- **With P10:** After the third miss, Homer speaks the first half and you finish it. After the fifth, he walks you through it and the lesson lands.

#### L5 · Landed · ~5 s

- **Arena:** The lesson is marked landed on the path, and your landing line is shown as your best line. In lesson 3, the epithet is set into your hoard and labeled as your battle name.
- **Phone:** Same.
- **Homer:** Short hype. "That's the beat. It's yours now." In lesson 3: "Breaker of Deadlines. Good. That's how my hall will know you."
- **Next:** **Again**, **Next lesson** or **Spar**. It waits; nothing auto-advances.

---

## 3. Practice mode: spar with Homer

Practice has two ways to play. **Reps** is one turn at a time with the full breakdown. **Spar** is you against Homer, best of three. Both use the turn from section 5. Practice is also the demo fallback if multiplayer breaks, so it has to run on the arena alone with no phones.

#### R0 · Setup · until start

- **Arena:** Reps or Spar. A theme: three theme cards plus "Random". A Homer mode (hexameter) toggle, if it ships.
- **Phone:** Same, stacked.
- **Homer:** "Pick your ground. Or let me pick it."
- **Next:** Start.

### Reps

Theme, then hand, then your turn (section 5), then the full breakdown. From there: **Again** (same theme, new hand), **New theme** or **Spar**.

#### R1 · Full breakdown · until you move on

- **Arena:** Everything the turn's verdict shows, plus a one-sentence reason for each of the five axes, a replay of the beat lane with every hit and miss, the quoted best line, and any formula added to your hoard.
- **Phone:** Same, with the axes as a list you scroll.
- **Homer:** The verdict line from the turn, nothing more. The reasons are text only.
- **Next:** A tap.

### Spar: best of three

Each round Homer goes first and you answer him. First to two rounds wins.

#### S1 · Round start · ~6 s

- **Arena:** "Round N", the theme, and the round score (Homer 0, you 0).
- **Phone:** Same, plus your hand.
- **Homer:** "Round one. A ship that never came home. I go first."
- **Next:** Automatic.
- **Timing:** Homer's verse is generated during this state. In round 1, generation starts as soon as the theme is chosen. In rounds 2 and 3 Homer answers your last verse, so generation starts the moment your transcript is final and runs under your verdict.

#### S2 · Homer's verse · ~12 s

- **Arena:** Homer performs over the beat and the scene moves with his voice. His stresses land on the lane, and with P8 his formula cards turn over as he uses them.
- **Phone:** Same. Your hand stays visible so you can plan.
- **Homer:** His verse.
- **Next:** The verse ends.

#### S3 · Homer's score · ~3 s

- **Arena:** His five axes and his total, compact. His verse was judged while he spoke, so the score is ready.
- **Phone:** Same.
- **Homer:** "Beat that."
- **Next:** Automatic.

#### S4 · Your turn · see section 5

The full turn. The line you answer (P7) is Homer's best line from S2.

#### S5 · Round result · ~4 s

- **Arena:** Your total against his, and the round score updates. Tapping opens the full breakdown (R1).
- **Phone:** Same.
- **Homer:** If you won: "Hah. Fine. Take it." If he won: "Close. Not close enough."
- **Next:** Someone has two rounds → S6. Otherwise → S1.

#### S6 · Match end · until you move on

- **Arena:** The final round score, each round's best line, and the formulas you added to your hoard.
- **Phone:** Same.
- **Homer:** If you won, hype: "You beat Homer. Tell no one. I'll deny it." If you lost, a gentle roast plus one thing to work on.
- **Next:** **Rematch**, **New theme** or **Battle real poets**.

How strong Homer should play is open question 9.

---

## 4. Battle mode: the Agon

Two to five poets in one room, with the arena and their phones.

**Pacing:** one turn takes about 45 s end to end (section 5). A battle of two poets and three rounds is about 6 minutes, plus the finale song. Five poets take about 13 minutes plus the song. For the judging table, see demo mode (section 6).

### Join

#### H0 · Open the hall (arena) · until tap

- **Arena:** On the device that will be the arena (a Mac, an iPad, or an iPhone mirrored to a TV): "Host a battle on this screen". The settings sit behind it: rounds (3), lines per turn (4), turn length (30 s), push-to-talk (P13), Homer mode, and demo mode (P14).
- **Next:** The tap creates the room and puts this device in arena mode.

#### H1 · Lobby · until the host begins

- **Arena:** The room code and a QR code, large enough to scan from across a table. The poets who have joined, each by name and epithet. A **Begin** button once two or more have joined.
- **Phone:** See J1 to J3.
- **Homer:** Silent between entrances.
- **Next:** The host taps Begin. The limit is five poets; a sixth person joins as a spectator.

#### J1 · Join (phone) · ~10 s

- **Phone:** Scanning the QR code with the camera opens the app on this screen. The fallback is to open the app, choose Fight, and type the room code. The screen has a field for your name, filled in with your epithet if this device has one in its hoard, and one button: **Enter**.
- **Arena:** No change yet.
- **Next:** Enter.

#### J2 · Mic check and entrance · ~5 s

- **Phone:** The iOS mic permission prompt (first time only), then "Say your name. Loud." with a level meter. If you have no epithet yet, Homer coins one during the check and the phone shows it: "Homer names you: Priya, Keeper of the Rubric." With P15 there is one **Ask again**; otherwise it is kept after 2 s.
- **Arena:** Your name and epithet arrive, and when your voice comes through, the scene answers it.
- **Homer (from the arena):** "Enter Priya, Keeper of the Rubric!"
- **Next:** Your voice is heard → J3. The mic fails → retry, with tips.
- **Notes:** Generating the epithet is a fast Claude call that runs during the mic check. Names and epithets are spoken aloud, so filter them for PG content first.

#### J3 · Waiting (phone) · until the battle begins

- **Phone:** "You're in." The list of poets in the hall.
- **Next:** The battle begins.

### Opening

#### B1 · Opening · ~6 s

- **Arena:** The poets in turn order, and "Three rounds."
- **Phone:** Your place in the order.
- **Homer:** "Three rounds. Every poet speaks. I judge. Highest total takes the hall."
- **Next:** Automatic.

### Each round

#### B2 · Round title · ~6 s

- **Arena:** The round number, the theme, and this round's turn order. The order rotates every round.
- **Phone:** The theme and your hand of five. The spec says you can save your best formula for the last round. My reading: a card you speak is spent, unspoken cards carry over, and the hand refills to five with new theme cards and cards from your hoard, with hoard cards marked as yours. That needs confirming (open question 5). You can study your hand from now until your turn.
- **Homer:** "Round one. A ship that never came home."
- **Next:** Automatic → the first poet's turn.

#### B3 · Turns · ~45 s each (section 5)

- **Arena:** The turn, as described in section 5.
- **Phone:** The speaker's phone runs the turn. Everyone else's phone shows who is speaking, their own hand to plan with, and their place in the order. If the spectator layer ships, it also shows reaction buttons.

#### B4 · Round verdict · ~10 s

- **Arena:** Every poet's round score, then the best line of the round, quoted and attributed and carved in gold across the arena. It stays there for the rest of the battle. The scoreboard re-sorts.
- **Phone:** Your round score and your position, plus "You're up first next round" if you are.
- **Homer:** Reads the round verdict and quotes the best line. "The round goes to the line that sank the ship:" and then he says it.
- **Next:** Rounds left → B2. Otherwise → the finale.

### Finale

#### B5 · Tally · ~5 s

- **Arena:** Totals roll up. The ranking is not revealed yet.
- **Phone:** Your total.
- **Homer:** "Before I crown anyone, listen."
- **Next:** Automatic. The song is built during round 3, with rounds 1 and 2 stitched ahead of time, and finished during this tally.

#### B6 · The song · ~70 s for two poets (see open question 7)

- **Arena:** Homer performs the stitched poem over the beat. Each line appears with its poet's name, the carved lines come back, and the scene replays the battle's colors in order.
- **Phone:** The lines of the song, with yours marked.
- **Homer:** The song: every verse of the battle, stitched, rounds in order.
- **Next:** The song ends.

#### B7 · Champion · ~8 s

- **Arena:** The winner, with epithet and total, then the full standings. If ranks ship, also the winner's title and rank change.
- **Phone:** The winner sees "You took the hall." Everyone else sees their place, their best line and the formulas added to their hoard.
- **Homer:** A short proclamation for the winner, then one quick, sincere compliment for each poet.
- **Next:** **Rematch** (same poets, new themes), **New hall** or **Leave**. Ties are open question 6.

### Edge cases

- **A phone drops:** Their turn waits 10 s, then is skipped with 0 points. They rejoin with the same code and keep their scores.
- **Silence** (no words heard): In battle you get one retry; Homer says "I heard the wind. Again." A second silence scores 0.
- **Inappropriate verse:** Homer says "Not in my hall." The turn scores 0, nothing is quoted, and the battle moves on.
- **Spectators** (a layer, second in the cut order): They join with the same QR code when the hall is full, or by choosing "Watch". Their phone shows reaction buttons only, and their reactions appear in the arena's scene during turns. Spectators need the app too.

---

## 5. The turn

Practice and Battle share this. The spec's order is theme, hand, speak, freeze rescue, scene, judge, hoard. Here it is broken into states with a time budget.

#### T0 · On deck · overlaps the previous turn's verdict

- **Arena:** "Next: Matus" in a corner.
- **Phone (the next poet):** "You're next." Your hand comes forward.
- **Next:** The previous turn ends.

#### T1 · Step up · ~3 s

- **Arena:** The poet's name and epithet. With P7, the previous poet's best line is pinned and labeled as the line to answer; for the first poet of a round, the theme is pinned instead. The beat lane resets to 4 lines of 4 beats.
- **Phone:** A **Ready** button, your hand, and the theme.
- **Homer:** "Matus. The sea is yours."
- **Next:** A tap on Ready, or automatically after 5 s.

#### T2 · Count-in · one bar, ~3 s

- **Arena:** The drum enters and counts one bar. The mic opens at the start of the count-in so the first word isn't clipped. With push-to-talk, it opens when the poet holds.
- **Phone:** The mic is live, with a large level meter and the count. With P13, the lower half of the screen is a single **Hold to speak** target.
- **Next:** The bar ends.

#### T3 · Speak · ~24 s, 30 s at most

- **Arena:**
  - The beat lane. Your words land on it live. A stressed syllable that hits a beat is marked on the lane and sounds a drum strike.
  - The live transcript.
  - The scene moving with you: the instant layer follows loudness and pitch, and the color layer shifts about every 1.5 s.
  - When you speak a formula card, it is marked as played (with P8, it turns over onto the arena).
  - Time left, counted in bars.
  - With P7, the pinned line.
- **Phone:** Your mic level, your hand (a card is marked when you use it), bars left, a short transcript, and a **Done** button.
- **Homer:** Silent, except for the freeze rescue.
- **Next:** Four lines are complete, 30 s pass, or the poet taps Done.
- **Bars:** Each line is one speaking bar followed by one rest bar. At about 80 BPM, four lines take 8 bars, about 24 s. The bars also tell us where each line ends.
- **Freeze rescue:** If about 1 s passes with no speech during a speaking bar, your hand comes forward on your phone, one card is raised, and Homer whispers it. Rest bars and the mid-line break don't count as silence. With push-to-talk, letting go for a whole speaking bar counts as a freeze.

#### T4 · Settle · from the end of the turn to ~0.6 s

- **Arena:** The drum lands a closing hit and stops. The transcript locks and the lane holds still with the hits marked. At about 0.3 s, a short pre-recorded Homer sound plays ("Hah." or "Hm.").
- **Phone:** "Homer is weighing it."
- **Next:** The verdict is ready.

#### T5 · Verdict · starts by ~3 s, lasts ~3 s

- **Arena:** The verdict, captioned as Homer speaks it.
- **Phone:** The same caption.
- **Homer:** One line. "Strong bones, thin blood. Your third line carried you."
- **Next:** Automatic.

#### T6 · Scores · ~3 s

- **Arena:** The five axes count up in order (Beat, Craft, Image, Answer, Range), then the turn total. In battle, the scoreboard updates.
- **Phone:** Your five axes and your total.
- **Next:** Automatic.

#### T7 · Best line · ~4 s

- **Arena:** The quoted line, alone and large. With P11, the scene replays that line's colors.
- **Phone:** The same line.
- **Homer:** Re-reads your line in his own voice, over the beat.
- **Next:** Automatic.

#### T8 · Hoard · ~2 s, only when earned

- **Arena:** "Into the hoard: storm-throated", with the poet's name.
- **Phone:** The new card joins your hoard.
- **Homer:** "That one's yours now."
- **Next:** The next poet's T1, or the round verdict.
- **Rule (spec):** You coined it, it scans, and the judge rated it well.

End to end, a turn takes about 3 + 3 + 24 + 10 seconds, so roughly 40 to 45 s.

### Latency budget

The goal: Homer starts speaking the verdict about 3 s after the turn ends. For the first 0.6 s, nothing on screen waits on the network.

| After the turn ends | What happens | Source | Budget |
| --- | --- | --- | --- |
| 0 | Turn end detected | on device | – |
| 0–0.3 s | Closing drum hit, mic closes, lane holds | on device | no network |
| ~0.3 s | Pre-recorded "Hah." | on device, cached audio | no network |
| by 0.6 s | Final transcript | Cartesia STT | 600 ms |
| by 0.7 s | Beat score | meter scanner | 100 ms |
| by 0.7 s | Range score | emotion engine, which already ran during the turn | ~0 |
| by 2.2 s | Craft, Image, Answer, best line, verdict line | Claude | 1.5 s |
| by 2.6 s | First audio of the spoken verdict | Cartesia TTS | 400 ms |
| ~3 s | Homer is speaking | | |

To get Claude's part down to 1.5 s:

- Use a fast model with no extended thinking for the turn verdict. The current `homer/` judge runs Opus at high effort with a tool loop, which won't fit.
- Keep the output small (scores, best line and verdict, under about 80 tokens) and stream it, so TTS can start as soon as the verdict field is complete.
- Put the rubric, the hand and the previous verse in a cached prompt prefix before the turn ends.
- Pass the scanner's output into the prompt instead of having Claude call the scanner as a tool.

When it runs late:

- **At 4 s with no verdict:** Homer says a pre-recorded stall line ("The Muse is still counting."), and Beat and Range appear, since they're already done.
- **At 10 s:** Show Beat and Range only, with "Homer is silent on this one." Never fall back to a canned verdict; that would be a mocked response, which AGENTS.md forbids in the demo path.

---

## 6. Demo mode: the judging table (Proposal P14)

**The setting** (from gtm): a 2-minute pitch with a live demo, at a table shared by two or three teams, with three judges and a noisy hall. The pitch talk runs over the app, not around it, so every second of app time also has to carry the story.

**The money moments, in the order they happen**

1. A judge scans the QR code and Homer announces them with an epithet he coined for them.
2. A verse over the beat: stresses land as drum strikes and the scene paints the voice.
3. The freeze rescue: Homer whispers a formula and the poet uses it. That is the formula method in one moment.
4. A spoken verdict in about 3 s, the five axes, then Homer re-reading the judge's own best line.
5. The carved line, and the song stitched from the verses the table just heard.

The benchmark chart (raw Claude against scaffolded Claude) is a pitch slide, outside the app.

**Judges won't have the app.** Homer ships through TestFlight to the team only. A judge can't install it at the table in time, and some judges carry Android phones. So in demo mode, a judge plays on a phone we hand them or on the guest seat. Money moment 1 becomes "a judge picks up a phone and gets named" instead of "a judge scans with their own phone". The QR code stays on screen to show how joining works.

### Before the judges sit (off the clock)

- **The arena:** a Mac in arena mode, a small speaker aimed at the judges, and a headset mic for our poet, plugged into the Mac.
- **Demo mode on:** the hall is already open with the QR code on screen, and our poet has already joined with their epithet.
- **Judge phones:** one or two team iPhones with the app installed, already open on the join screen (J1) for this hall, so a judge only types a name.
- **The guest seat:** a judge can also play from the arena, with their hand shown on the arena and the arena's mic (or a second headset) as their mic.
- **Sound check:** the beat at table volume, and one push-to-talk test.

### What demo mode changes

| Setting | Normal | Demo mode |
| --- | --- | --- |
| Rounds | 3 | 1 |
| Lines per turn | 4 | 2 |
| Poets | 2 to 5 | Our poet plus the first judge to join. Later joiners are announced, then watch as spectators |
| Mic check on join | Yes | Skipped, since push-to-talk is checked at the turn |
| Push-to-talk (P13) | Option | On. Judges hold on their phone; our poet holds a key or a clicker |
| Turn order | Rotates | Our poet first, so the judges see a turn once before they take one |
| Theme | Random or chosen | Preset, one we've rehearsed |
| Our poet's verdict | Full | Verdict and scores only; the best-line re-read is saved for the judge |
| The song | Every verse | The four lines of the round |
| Operator keys | None | Advance, retry the turn, skip, restart |

### Timeline

| Clock | State | Arena | Judges | Homer |
| --- | --- | --- | --- | --- |
| 0:00–0:20 | Join and entrances | The QR code, then names and epithets arriving | Take a team phone, type a name, Enter | "Enter Priya, Keeper of the Rubric!" once for each judge |
| 0:20–0:24 | Round title | The theme | Hands dealt to phones | "One round. A ship that never came home." |
| 0:24–0:47 | Our poet's turn | The beat, the lane and the scene. A planned pause triggers the rescue | Watch | Whispers a formula, then gives the verdict |
| 0:47–1:15 | The judge's turn | The judge holds to speak, with our poet's best line pinned (P7) | One judge speaks two lines | A rescue if they freeze, then the verdict, then re-reads their best line |
| 1:15–1:22 | Round verdict | The best line carved | | Quotes it |
| 1:22–1:42 | Song and crown | The song, then the champion | | Performs the four lines, then crowns the winner |
| 1:42–2:00 | Close | The scene idles behind the carved line and the QR code | | Silent |

That leaves about 18 s of talk with the app idle, plus talk over the entrances and the round title. gtm owns the talk track.

### When something breaks at the table

- **A judge's phone can't join within about 15 s:** the operator opens the guest seat on the arena.
- **The venue Wi-Fi fails:** the arena and the team phones need SpacetimeDB and the agent service. Bring a hotspot.
- **The transcript comes back wrong:** it's on screen, so the table can see what Homer heard. Say so out loud; it's one of the failure modes we state. One key retries the turn.
- **The verdict is slow:** the stall line plays at 4 s. The operator can skip ahead.
- **Multiplayer is down:** switch to Practice spar on the arena: a judge against Homer, with the same beat and the same verdict.

---

## Risk: the beat bleeds into the speaker's mic

If the arena plays the beat and the poet speaks into their phone, the phone's mic picks up the beat. A device's echo cancellation only removes sound that the device itself played, so the phone can't remove what the arena's speaker plays. The same goes for Homer's whisper if it plays from the arena, and for a loud hall.

What it can break:

- STT accuracy, with drum and lyre under the voice.
- The live drum strikes and the instant layer of the scene, which would react to the drum even when the poet is silent.
- The transcript: the rescue whisper could be transcribed as the poet's own words.

For the demo, the headset mic on the arena (option A) plus push-to-talk covers most of this. Phone-mic play still needs a choice. Options, not decided:

| Option | How it works | What it gives up |
| --- | --- | --- |
| A. Mic at the arena | A headset or wired mic on the arena. The arena plays and records, so its own echo cancellation removes the beat and Homer. Phones become hand and controls only. | "Your phone is your mic." Poets have to step up, which also gives it the open-mic feel. |
| B. Duck the beat while you speak | The beat plays full during the count-in and the rest bars, and drops to a soft tick during speaking bars. | Some of the feel of riding the drum. Some bleed remains. |
| C. The beat plays on the speaker's phone | The arena goes visual-only during a turn, and the speaking phone plays the beat itself. iOS voice processing removes the app's own playback from the mic. | The room doesn't hear the drum during a turn. |
| D. Haptic beat | The speaking phone taps out each beat with haptics, and the arena is silent during speaking bars. | The room doesn't hear the drum during a turn. |
| E. Filter it | Keep the beat low (a kick drum below ~150 Hz), filter that range out of the mic signal, and only let the strikes and the instant layer respond when a voice is detected. | Unknown cost to STT accuracy. Needs a test at demo volume. |
| F. Push-to-talk (P13) | The mic is open only while the poet holds. | It doesn't help while they're speaking, and it takes a hand. |

B, E and F combine with any of the others. Whichever we choose, test it once at the venue at demo volume.

## Constraints for the build

These shape the UX. They are flagged here for whoever builds each part.

- **The drum strike on a hit has to be decided on the device holding the mic, within about 50 ms.** It can't wait for the transcript. The practical signal is a loudness onset close to a beat, since stressed syllables are louder. The Beat score comes later, from the scanner on the transcript, so the two can disagree (open question 3). When the mic is on a phone and the drum is on the arena, the strike also crosses the network and can land 100 to 200 ms late. With a mic on the arena, everything stays on one device.
- **The instant layer across devices:** the mic is on the phone but the scene is on the arena, so loudness and pitch have to travel from phone to arena, about 20 updates a second, smoothed on the arena. Expect 100 to 200 ms of lag, which still reads as live.
- **The app keeps the screen awake** during a battle and a lesson, or the mic and the hand vanish when the phone locks.
- **iOS notes:**
  - The QR code carries a link that opens the app on J1. Someone without the app can't join, so it's worth deciding where that link lands for them: a page that points to TestFlight, or nothing.
  - On a Mac, an iPhone-only app runs in a phone-sized window. To fill a big screen in arena mode, the app probably needs iPad support, which the Mac can run full screen. Verify this before the demo.
  - On an iPhone mirrored to a TV, plain mirroring shows the phone's portrait screen with bars on either side. A full landscape arena needs the app to draw a separate layout for the external display.
  - Homer's voice and the beat use the same audio session as the mic, with voice processing on, so a device removes its own playback from its own mic (options A and C).

## Screen inventory

This is the list of layouts to design. The states above describe what changes inside each one.

**Arena (or the single device in solo modes)**

1. Launch and idle (F0)
2. Homer performing (F1, L1, S2, B6)
3. Mode choice (F5)
4. Lesson path
5. Lesson (L0–L5)
6. Practice setup (R0)
7. Host a battle, with settings (H0), and the lobby with its QR code (H1)
8. Round title (B2, S1)
9. Turn: step up, speak, verdict, scores, best line, hoard (T1–T8)
10. Turn with a guest seat, where the hand is shown on the arena (demo mode)
11. Full breakdown (R1)
12. Round verdict and scoreboard (B4, S5)
13. Champion and match end (B7, S6)

**Phone**

1. Join (J1)
2. Mic check and the epithet Homer gives you (J2)
3. Waiting, or watching someone else's turn (J3, B3)
4. Your hand (from B2 on)
5. On deck and ready (T0–T1)
6. Speaking, with or without the hold-to-speak target (T2–T3)
7. Your result (T5–T8)
8. Final (B7)

## Open questions for Matus

1. Which pending proposals are in? Answer by number, P7 to P15.
2. For phone-mic play, outside the demo: which bleed option should we test first, A to F?
3. The live drum strikes come from loudness and the Beat score comes from the scanner, so they can disagree. Is that acceptable? And should the Beat score also check timing against the drum?
4. In demo mode, judges can't use their own phones, since the app is TestFlight-only. Does a judge play on a team iPhone with push-to-talk, or speak into a mic at the arena (the guest seat)? Is one round, two lines and one judge battling the right cut?
5. Your hand across rounds: is a spoken card spent, with unspoken cards carrying over and the hand refilling to five? That's how I read "save your best formula for the last round."
6. A battle tie: one-line sudden death between the tied poets, or a shared crown?
7. The song stitches every verse: about 70 s for two poets and three minutes for five. Do we cap it at a few lines per poet?
8. Lessons: can you open any one, or only in order? Should a lesson pass you after five misses (P10)?
9. Spar: how strong should Homer play? Should a beginner be able to beat him?
10. If the mic is denied: offer typed input, or stay voice-only?
11. Freeze rescue: should using the whispered formula cost Craft points?
