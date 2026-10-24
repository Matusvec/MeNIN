# MeNIN: UX flow

This doc is for Matus to design against. It covers the flow, the states, the timing and what each screen shows. Visual design is Matus's, so this doc describes what is shown and what changes, never how it looks. Words like "large" or "pinned" describe hierarchy.

`SPEC.md` (as of commit 2fb21bf) is the source of truth. Anything not in it is marked **Proposal Pn** and waits on Matus.

MeNIN is ancient Greek Wii Sports, with Homer as the host: party events on one shared screen, with phones as controllers. The poetry battle is the core (sections 1 to 6). Socratic debate and discus are in build now (sections 8 and 9). The event menu ties them together (section 7), and section 10 says where the music plays.

## How to read this

**Devices**

MeNIN is one universal iOS app (iPhone and iPad), distributed through TestFlight. There is no web app. In a battle, each device runs the app either as the arena or as a player.

- **Arena**: the one big shared screen. It's the app in arena mode, full screen on an iPad or a Mac, or on an iPhone mirrored to a TV. It shows the scene, the beat lane, the transcript and the scoreboard, plays Homer's voice and the beat, and shows the QR code to join.
- **Phone**: the app on each poet's iPhone, which is their mic and their private hand.
- **Solo modes:** Bard and Practice run on a single device. The Arena line describes the layout on a large screen (iPad or Mac), and the Phone line describes it on an iPhone.

**Each state lists**

- **Arena**: what the shared screen shows
- **Phone**: what the poet's phone shows
- **Homer**: what Homer says. Sample lines set the voice; the prompts own the final copy.
- **Music**: the cue that starts or stops here, if any (section 10). Most states have none.
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
- Music never plays under an open mic or with the beat, and it ducks under Homer's voice (section 10).

## Decided and proposed

**Approved by Matus. These are in SPEC.md now, so the body below treats them as spec without tags.**

- **The beat:** a slow drum-and-lyre loop, four beats a bar, one line per bar. A stressed syllable that hits a beat sounds like a drum strike.
- **Freeze rescue:** about 1 s of silence mid-turn brings your hand forward, and Homer whispers one formula that fits. Lesson 2 teaches it.
- **Arena and phones:** one shared screen, and each phone is that poet's mic and private hand. You join by QR code or link.
- **Epithet as battle name:** you forge it in lesson 3 ("___, Breaker of Deadlines"). If you don't have one, Homer coins one when you join.
- **Carved line:** the best line of each round is carved in gold across the arena.
- **The stitched song:** at the finale Homer stitches every verse into one poem and performs it over the beat while the scene replays the battle's colors, then crowns the champion.

**Proposals P7 to P19**

Leader approved these as delegator, and Matus can veto any of them. Approved items keep their Pn tag in the body, so a veto is easy to trace.

| ID | Proposal | Status |
| --- | --- | --- |
| P7 | **Answer prompt.** During your turn, the previous poet's best line stays on screen as the thing you answer. | Approved |
| P8 | **Card reveal.** When you speak a formula from your private hand, that card turns over onto the arena for everyone to see. | Approved |
| P9 | **Voice menu.** Homer asks "Learn, train, or fight?" and you answer out loud. | **Cut:** the risk of misrecognition outweighs the gain. Menus are tap-only |
| P10 | **Help after misses.** In a lesson, after three misses Homer gives you the first half of the line. After five, he walks you through it and the lesson lands. | Approved |
| P11 | **Color replay.** When Homer re-reads your best line, the scene replays the colors it showed while you said it. | Approved |
| P12 | **First open.** On first launch, Homer speaks before any menu and asks for one line (section 1). | **Approved by Matus,** first launch only, in SPEC.md as "First open" |
| P13 | **Push-to-talk.** Hold to open the mic. | Approved, and in SPEC.md: push-to-talk in battles, open mic in solo modes |
| P14 | **Demo mode extras.** Demo mode itself is in SPEC.md. The extras: push-to-talk on, our poet goes first, operator keys, and the best-line re-read saved for the judge (section 6). | Approved |
| P15 | **One reroll.** If Homer coins your epithet on join, you can ask for another one, once. | Approved |
| P16 | **The hall stays open between events.** When an event ends, the arena goes back to the event menu with everyone still joined, so nobody rejoins to switch events (section 7). | Approved, and in SPEC.md |
| P17 | **Tap to play a move.** In debate, you tap a move card on your phone as you make the move. It lands on the arena, and the judge checks that you really made it (section 8). | Approved, and in SPEC.md |
| P18 | **Sides are dealt.** In debate, sides alternate by turn order, so you often argue a side you don't hold (section 8). | Approved, and in SPEC.md |
| P19 | **Demo mode music.** At the judging table, the hall theme stays at its ducked level the whole time, because we talk over the menu. An operator key mutes all music (sections 6 and 10). | Proposed |

P1 to P6 were approved by Matus and are listed above.

---

## 1. First open

Approved by Matus (SPEC.md, "First open"). This runs on the first launch only: Homer speaks before any menu, you give him one line, and the scene answers. There is no sign-up and no tutorial text. A native app can play sound as soon as it opens, so no tap comes first. Every later launch opens straight on the event menu.

#### F0 · Launch · ~1 s

- **Arena:** The scene comes up and idles. Nothing else.
- **Phone:** Same.
- **Homer:** Silent, for one breath.
- **Music:** `first-open-bed` starts at launch. Homer's line enters 1 s into it.
- **Next:** Automatic.

#### F1 · Homer speaks · ~5 s

- **Arena:** The scene moves with Homer's voice. His words are captioned as he speaks.
- **Phone:** Same.
- **Homer:** "The first word of Western literature is mēnin. Rage. Give me one line." The audio ships inside the app, so it starts at once. Check how TTS pronounces mēnin: it should sound like MAY-nin.
- **Music:** The bed continues under him, with a hit on "Rage" (about 3.9 s into his line). It's the one cue written to sit under Homer, so it isn't ducked. It ends before the mic opens.
- **Next:** He finishes. iOS shows its mic permission prompt right after "Give me one line", so the request comes with its reason.

#### F2 · Your line · up to 8 s

- **Arena:** The mic is open, with the live transcript. The scene answers your voice: the instant layer follows your loudness and pitch, and the color layer shifts with what you say. There's no beat, no lane and no score yet. Anything counts.
- **Phone:** Same.
- **Homer:** Silent.
- **Next:** About 1 s of silence after you've spoken, or 8 s pass. Mic denied → Fx.

#### F3 · "Now let me show you" · ~3 s

- **Arena:** Your line stays on screen as the scene settles.
- **Phone:** Same.
- **Homer:** "Good. Now let me show you how I did it."
- **Next:** Automatic.

#### F4 · The event menu · until choice

- **Arena:** The event menu (section 7), with the poetry tile open on **Learn** (Bard), **Train** (Practice) and **Fight** (Battle). **Learn** (Bard lesson 1) is the suggested pick, so "let me show you how I did it" pays off. Decided by leader; Matus can veto.
- **Phone:** Same, stacked.
- **Homer:** Silent. He just spoke.
- **Music:** `hall-theme` starts.
- **Next:** A tap. Closing the poetry tile shows the whole event menu.

The mic opens about 6 s after launch.

**Other ways in**

- **A hall's QR code:** Scanning it with the camera opens the app straight into the battle join screen (J1), skipping first open. Homer greets you in the hall instead. First open runs the next time you launch the app yourself.
- **Later launches:** straight to the event menu (section 7), with no greeting.
- **Fx · Mic denied:** Homer: "No voice, no song." A button opens MeNIN's page in iOS Settings, where you can turn the mic on, and then F2 retries. Skipping it goes to the event menu. See open question 10.

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
- **Music:** `training-ambience`. It continues through L0.
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
- **Music:** The ambience fades out as the beat comes in, and stays out from L1 to L4.
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
- **Next:** The required lines are done. Each line gets a speaking bar, then a rest bar (spec).

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
- **Music:** The ambience comes back.
- **Next:** **Again**, **Next lesson** or **Spar**. It waits; nothing auto-advances.

---

## 3. Practice mode: spar with Homer

Practice has two ways to play. **Reps** is one turn at a time with the full breakdown. **Spar** is you against Homer, best of three. Both use the turn from section 5. Practice is also the demo fallback if multiplayer breaks, so it has to run on the arena alone with no phones.

#### R0 · Setup · until start

- **Arena:** Reps or Spar. A theme: three theme cards plus "Random". A Homer mode (hexameter) toggle, if it ships.
- **Phone:** Same, stacked.
- **Homer:** "Pick your ground. Or let me pick it."
- **Music:** `training-ambience`. In Reps it fades out at the count-in and comes back at the breakdown (R1).
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
- **Music:** In round one, the ambience stops and `poetry-intro` plays, then Homer speaks.
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
- **Music:** `round-end` as the result appears, before Homer speaks.
- **Next:** Someone has two rounds → S6. Otherwise → S1.

#### S6 · Match end · until you move on

- **Arena:** The final round score, each round's best line, and the formulas you added to your hoard.
- **Phone:** Same.
- **Homer:** If you won, hype: "You beat Homer. Tell no one. I'll deny it." If you lost, a gentle roast plus one thing to work on.
- **Music:** `champion` if you won. Nothing if Homer won.
- **Next:** **Rematch**, **New theme** or **Battle real poets**.

How strong Homer should play is open question 9.

---

## 4. Battle mode: the Agon

Two to five poets in one room, with the arena and their phones.

**Pacing:** one turn takes about 45 s end to end (section 5). A battle of two poets and three rounds is about 6 minutes, plus the finale song. Five poets take about 13 minutes plus the song. For the judging table, see demo mode (section 6).

### Join

#### H0 · Open the hall (arena) · until tap

- **Arena:** On the device that will be the arena (a Mac, an iPad, or an iPhone mirrored to a TV): "Host a battle on this screen". The settings sit behind it: rounds (3), lines per turn (4), turn length (30 s), Homer mode, and demo mode. Push-to-talk is always on in battles (P13).
- **Next:** The tap creates the room and puts this device in arena mode.

#### H1 · Lobby · until the host begins

- **Arena:** The room code and a QR code, large enough to scan from across a table. The poets who have joined, each by name and epithet. A **Begin** button once two or more have joined.
- **Phone:** See J1 to J3.
- **Homer:** Silent between entrances.
- **Music:** `hall-theme` continues from the menu. It ducks under each entrance, and goes silent while any phone's mic is open (J2).
- **Next:** The host taps Begin. The limit is five poets; a sixth person joins as a spectator.

#### J1 · Join (phone) · ~10 s

- **Phone:** Scanning the QR code with the camera opens the app on this screen. The fallback is to open the app, choose Fight, and type the room code. The screen has a field for your name, filled in with your epithet if this device has one in its hoard, and one button: **Enter**.
- **Arena:** No change yet.
- **Next:** Enter.

#### J2 · Mic check and entrance · ~5 s

- **Phone:** The iOS mic permission prompt (first time only), then "Say your name. Loud." with a level meter. If you have no epithet yet, Homer coins one during the check and the phone shows it: "Homer names you: Priya, Keeper of the Rubric." With P15 there is one **Ask again**; otherwise it is kept after 2 s.
- **Arena:** Your name and epithet arrive, and when your voice comes through, the scene answers it.
- **Homer (from the arena):** "Enter Priya, Keeper of the Rubric!"
- **Music:** The arena's hall theme goes silent while this phone's mic is open, so it stays out of the name clip that discus reuses. It ducks under the entrance.
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
- **Music:** The hall theme stops at Begin and `poetry-intro` plays. Homer speaks as it ends. From here to B7 there's no music, only stings, and in turns only the beat.
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
- **Music:** `round-end` as the scores appear. Homer starts the verdict as it ends.
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
- **Music:** `champion` as the winner appears. Its big moment is in the first 2 s, and Homer's proclamation starts over its tail, ducked. **Rematch** plays `rematch` during the reset. **New event** brings back the hall theme.
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

- **Arena:** The drum enters and counts one bar. In solo modes the mic opens at the start of the count-in so the first word isn't clipped. In battles it opens while the poet holds (P13).
- **Phone:** The mic is live, with a large level meter and the count. In battles (P13), the lower half of the screen is a single **Hold to speak** target.
- **Next:** The bar ends.

#### T3 · Speak · ~24 s, 30 s at most

- **Arena:**
  - The beat lane. Your words land on it live. A stressed syllable that hits a beat is marked on the lane and sounds a drum strike.
  - The live transcript.
  - The scene moving with you: the instant layer follows loudness and pitch, and the color layer shifts about every 1.5 s.
  - When you speak a formula card, it is marked as played (with P8, it turns over onto the arena).
  - Time left, counted in bars.
  - With P7, the pinned line.
- **Phone:** Your mic level, your hand (a card is marked when you use it), bars left, a short transcript, and a **Done** button. In a battle the phone carries the beat as haptics, one tap per beat, because the arena ducks the drum while you speak (spec).
- **Homer:** Silent, except for the freeze rescue.
- **Next:** Four lines are complete, 30 s pass, or the poet taps Done.
- **Bars:** Each line is one speaking bar followed by one rest bar. At about 80 BPM, four lines take 8 bars, about 24 s. The bars also tell us where each line ends.
- **Freeze rescue:** If about 1 s passes with no speech during a speaking bar, your hand comes forward on your phone, one card is raised, and Homer whispers it. Rest bars and the mid-line break don't count as silence. In battles, letting go of Hold to speak for a whole speaking bar counts as a freeze.

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

## 6. Demo mode: the judging table

**The setting** (from gtm): a 2-minute pitch with a live demo, at a table shared by two or three teams, with three judges and a noisy hall.

**The second-by-second script is `docs/gtm/demo-script.md`** (SPEC.md points there). **The logistics are in `docs/gtm/run-sheet.md`:** devices, charging, setup, the rematch drill and fallbacks. This section only covers what the app does differently in demo mode.

**Who plays:** two team poets battle (the poet and Matus), each on their own iPhone with a wired headset. The judges pick the theme from three cards and watch. After 2:00, a judge can take a team iPhone for a discus throw or a rematch. Judges never install anything, since MeNIN is TestFlight-only.

**The money moments, in the order they happen:**

1. Homer's first-open line, replayed by the operator: "The first word of Western literature is mēnin. Rage."
2. A judge picks the battleground.
3. A verse over the beat: stresses land as drum strikes, and the scene paints the voice.
4. The freeze rescue, staged but running live: Homer whispers a formula and the poet uses it.
5. A spoken verdict starting about 3 s after the turn, with the five axes counting up under it.
6. The carved line, and the 4-line song stitched from the verses the table just heard.

### What demo mode changes

Demo mode is in SPEC.md. Rows marked P14 are extras, approved by leader.

| Setting | Normal | Demo mode | Source |
| --- | --- | --- | --- |
| Rounds | 3 | 1 | spec |
| Poets | 2 to 5 | 2 team poets. Judges pick the theme and watch | spec, demo script |
| Lines per turn | 4 | 2 | spec |
| Rest bars | One after every line | Kept, but droppable if we run long | spec |
| Ready and mic check | Ready tap, mic check on join | Auto-ready, no mic check | spec |
| Verdict and scores | Verdict, then scores | Scores count up while Homer speaks the verdict | spec |
| Best-line re-read and hoard step | Every turn | Off. The best line is carved once, at round end | spec |
| Tally | Yes | Skipped | spec |
| The song | Every verse | 4 lines | spec |
| The crown | Proclamation and compliments | One line | spec |
| Theme | Random or chosen | Judges pick from 3 theme cards on the arena. Optional, and the first thing to cut; without it, the theme is preset | spec |
| Rematch | n/a | Resets in under 10 s: same poets, new theme cards | spec |
| Push-to-talk (P13) | On in battles | On, with wired headsets | spec |
| Replay opening | n/a | An operator key replays Homer's first-open line on the arena | demo script |
| Operator keys | None | Replay opening, advance, retry the turn, skip, rematch | P14 |
| Music | Every cue (section 10) | The same cues. The replayed opening brings its bed. The hall theme stays at its ducked level because we talk over the menu, and an operator key mutes all music | P19 |

---

## 7. The event menu

This is the home screen, Wii Sports style: one tile per event, and each tile opens onto its own few choices. On first launch, F4 lands here with the poetry tile already open.

#### E0 · Event menu · until a pick

- **Arena:** A grid of tiles. Each live tile shows the event, its host, what you do in one line, and your best on this device: rank, wins, or longest throw. The locked tiles follow, with a name only, marked locked.

  | Tile | Host | One line | Opens to |
  | --- | --- | --- | --- |
  | Poetry battle | Homer | Improvise verse over the beat. | Learn, Train, Fight |
  | Socratic debate | Socrates | Argue a question out loud, on the clock. | Train, Fight |
  | Discus | Homer announces | Swing your phone. Let go of the button, not the phone. | Throw, Fight |
  | Chariot race, Javelin, Wrestling | none | Locked | nothing |

  Debate and discus are in build now. Either one that can't run 5 times in a row without failing by Saturday 8 PM stays a locked tile for the demo (spec). Turning a tile on or off is a config switch.
- **Phone:** The same tiles in two columns. In a hall (P16), the phone shows the tiles read-only with "The arena is picking", and the arena's pick opens on every phone.
- **Homer:** On a later launch: "Pick your event." On a locked tile: "Not yet. Those games are still being built."
- **Music:** `hall-theme`. In a hall it plays from the arena only.
- **Next:** Tap a live tile → E1. In a hall, the arena picks.

#### E1 · Event choices · until a pick

- **Arena:** The chosen tile opens in place onto its choices. Fight also offers "Join with a code".
- **Phone:** Same.
- **The host:** One line. Homer, for poetry: "Learn, train, or fight?" Socrates, for debate: "Ah. A question. Train with me, or fight them?" Homer, for discus: "Grip it. Swing. Let go."
- **Next:** A choice opens that event's flow. Back returns to E0.

**Between events (P16):** when a battle ends, **New event** on the arena returns everyone to E0, still joined. Epithets carry over and scores don't, since each event crowns its own winner. Without P16, every event opens its own hall, and everyone rejoins.

---

## 8. Socratic debate

In build now (spec). The persona, questions, rubric, rescue, moves and lines are in `content/debate.md`.

Debate runs on the poetry engine. Anything not listed here works as in sections 3 to 5.

### What changes from poetry

| | Poetry battle | Socratic debate |
| --- | --- | --- |
| Host | Homer | Socrates: dry and ironic, a coach in training and an MC in battle |
| Each round | A theme | A question with two sides |
| Sides | None | Dealt by turn order, alternating (P18). Turn order rotates, so in a two-player battle everyone argues both sides |
| Hand | Five formulas | Five moves: at least one each of open, attack, defend and close |
| Beat | Drum and lyre, the beat lane, haptics | None. No drum, no lane, no haptic beat |
| Turn length | 4 lines, about 24 s | 45 s (suggested), with a "Ten seconds" call |
| Freeze rescue | About 1 s of silence; Homer whispers a formula | About 2 s of silence; Socrates whispers a question to ask |
| Using a card | A spoken formula is matched in the transcript | You tap the card as you make the move (P17). The judge checks you made it |
| Rubric | Beat, Craft, Image, Answer, Range | Claim, Reason, Answer, Craft, Poise |
| The axis Claude doesn't score | Beat, from the scanner | Poise, from fillers, pace and silence |
| Hoard | Coined formulas join it | None |
| Round end | The best line is carved | Same |
| Finale | The stitched song | Socrates' last question, about 10 s. He quotes the strongest point of the night, then asks the one question nobody answered |
| Practice | Reps, and spar with Homer | Spar with Socrates, best of three. He takes the other side and argues mostly by asking you questions |
| Music | `poetry-intro` opens a battle or spar. Only the beat plays in turns | `debate-intro` opens a battle or spar. Nothing plays in turns. The round-end and champion stings are shared |

### The debate turn

Only the states that differ from section 5 are listed.

#### T1 · Step up · ~3 s

- **Arena:** The debater's name and epithet, and their side, large. The question is pinned. With P7, the last speaker's strongest line is pinned as the point to answer.
- **Phone:** Your side, your five moves with their roles marked, and **Ready**.
- **Socrates:** "{name}, {title}. You say {side}. The floor is yours. Try not to fall through it."
- **Next:** Ready, or automatically after 5 s.

#### T2 · Count-in · ~3 s

- **Arena:** A three-count with no drum, then Socrates says "Go." The mic opens at the start of the count.
- **Phone:** The mic is live, with the count.
- **Next:** "Go."

#### T3 · Speak · 45 s

- **Arena:** The live transcript is the main element, since there's no lane. Time left, and move cards landing as they're played (P17). The scene still moves with the voice.
- **Phone:** Your five moves (tap one as you make it), time left, a short transcript, and **Done**.
- **Socrates:** Silent, except "Ten seconds." and the rescue whisper.
- **Next:** 45 s pass, or Done.
- **Freeze rescue:** after about 2 s of silence, your hand comes forward, one move is raised, and Socrates whispers a question in your own voice ("What do you mean by fair?"). Asking it plays that move. The whispers are prepared at T1, so the rescue is instant.
- **P17, tap to play:** a tap is a claim, not a score. A tapped move you didn't make earns no Craft, and the verdict reason says so. A move you made without tapping still counts if the judge hears it.

#### T4 to T7 · Verdict · same timing as poetry

Same states and latency budget. The verdict is in Socrates' voice, the five debate axes count up, and Socrates re-reads your best line. Poise is ready first, the way Beat is in poetry.

#### T8 · Hoard

Skipped.

---

## 9. Discus

In build now, under the same Saturday 8 PM rule (spec). It's a self-contained motion minigame: no voice and no Claude (spec). The phone's motion sensors measure the swing and the release, and the arena shows the throw. A throw takes about 20 s.

**Safety comes first.** The release is your thumb lifting off the screen, never your hand opening. You hold the phone the whole time. The first throw on any device starts with the safety card.

**Format (suggested):** three throws each, and your best one counts, as in the real event. Turn order rotates. Two players take about 2 minutes, five players about 5.

#### D0 · Safety card · first throw on a device, until tap

- **Arena:** "{name} is reading the rules."
- **Phone:** "Hold your phone tight. Your thumb is the release: lift it to throw. Never let go of the phone. Clear some space." One button: **Got it**.
- **Homer:** "Grip it. Swing. Let go of the button, not the phone."
- **Next:** Got it.

#### D1 · Pick up · ~3 s

- **Arena:** The field from the throwing circle, the thrower's name, their best so far, and the distance markers. One marker is the Phayllos line at 29 m, the ancient legend's throw (suggested).
- **Phone:** One large target: "Press and hold to pick up the discus." A firm haptic on press.
- **Homer:** "{name} steps into the circle." These lines are pre-recorded; the name reuses the clip recorded when the player joined.
- **Music:** On the event's first throw, `discus-intro` plays before Homer's line.
- **Next:** The player presses and holds.

#### D2 · Wind-up · 1 to 4 s

- **Arena:** The thrower winds up in time with the phone's motion, and the speed builds. The scene's instant layer follows the swing speed, so it moves with the throw as it does with a voice.
- **Phone:** Only the held target. Haptics build with the speed.
- **Homer:** Silent. The crowd builds.
- **Music:** None. The crowd is the optional `discus-crowd` cue. If it isn't delivered, this state is silent.
- **Next:** The thumb lifts → D3.
  - A lift before a real swing (under 0.5 s, or under about half a turn) is a drop, not a throw. "That's a drop, not a throw." One retry.
  - Holding for more than 6 s resets to D1: "The crowd is getting old. Throw."

#### D3 · Release · instant

- **Arena:** The discus leaves the hand.
- **Phone:** A heavy haptic, and "Look up."
- **Music:** `discus-whoosh` starts on the release and fades through the flight (D4).
- **Measured at release:**
  - the speed, from peak rotation in the last 0.3 s or so
  - the angle, from the phone's tilt; about 35 to 40 degrees flies farthest
  - the timing, meaning how close the release came to peak speed
  The iOS lead tunes how these become a distance. The phone sends one message to the arena with the three numbers, so no network lag reaches the measurement.
- **Foul:** a release far off to the side flies into the crowd.
- **Next:** Automatic.

#### D4 · Flight · ~4 s

- **Arena:** The view follows the discus across the field, past the markers.
- **Phone:** "Look up." A haptic when it lands.
- **Homer:** Only on long throws: "Look at it go."
- **Next:** It lands.

#### D5 · Distance · ~3 s

- **Arena:** The landing mark and the distance in meters to one decimal, labeled as a personal best or the hall's best. The Phayllos line is called out if the throw passed it.
- **Phone:** Your distance, and your best so far.
- **Homer** (pre-recorded, by bracket):
  - Short: "A gentle toss. The crowd forgives you."
  - Good: "Strong arm."
  - The hall's best: "New mark. Remember that name."
  - Past the Phayllos line: "Past Phayllos. They'll carve that one."
  - A foul: "Into the crowd. They'll live."
- **Music:** `discus-fanfare` as the distance appears, then Homer's line. No fanfare on a foul.
- **Next:** Automatic.

#### D6 · Leaderboard · ~3 s

- **Arena:** Everyone's best throw, sorted, with the throws each has left.
- **Phone:** Your place, your throws left, and "You're up" if you're next.
- **Homer:** Silent between throws. After the last throw: "The discus goes to {name}."
- **Music:** After the last throw, `champion`, with Homer's line over its tail.
- **Next:** The next thrower's D1. After the last throw, the champion (one line, as in demo mode), then **New event** (P16).

**Solo (Throw):** on one iPhone, the phone is both arena and discus. After the release, the phone shows the flight and the distance, and keeps your best on this device.

---

## 10. Music

MeNIN has an original soundtrack by a teammate (spec, "Music"). The composer's brief, with each cue's length, format and loudness, is `docs/audio.md`. This section covers where each cue plays and the rules the app follows.

**Rules**

- **Never under an open mic.** Music fades out over about 0.3 s before any mic in the room opens, and stays out until it closes. That includes the mic check (J2) and the line in first open (F2). Music bleeding into a phone's mic hurts STT the same way the beat does (see "Risk" below).
- **Never with the beat.** In poetry turns and lessons, only the procedural drum-and-lyre beat plays (spec). Music fades out before the beat starts.
- **Ducks under a host** (spec). When Homer or Socrates speaks, music drops about 12 dB and comes back about 0.5 s after he stops. The exception is the first-open bed, which is written to sit under Homer and plays at full level.
- **The arena plays it.** In a hall, only the arena plays music. Phones never do, since they're the mics. In solo modes the one device plays it.
- **Stings start on their cue, with no delay,** and play once. A host line can start over a sting's tail, ducked.
- **Loops fade out.** `hall-theme` and `training-ambience` loop until their screen ends, then fade out over about 1 s.

**Where each cue plays**

| Cue | Starts | Ends | States |
| --- | --- | --- | --- |
| `first-open-bed` | At launch, 1 s before Homer's first line | Before the mic opens | F0, F1, and the demo's replay opening |
| `hall-theme` | The event menu after first open, or at launch | When an event starts | F4, E0, E1, H1, J1 to J3 (on the arena) |
| `training-ambience` | The Bard path, Practice setup | At the count-in or Homer's demo verse, and back after the try | Path, L0, L5, R0, R1 |
| `poetry-intro` | A poetry battle or spar begins | Before Homer's opening line | B1, S1 (round one) |
| `debate-intro` | A debate battle or spar begins | Before Socrates' opening line | Debate B1 and S1 |
| `discus-intro` | The event's first throw | Before Homer's line | D1 |
| `discus-whoosh` | The release | As the discus flies off | D3, D4 |
| `discus-fanfare` | The distance appears | Before Homer's distance line | D5 |
| `round-end` | The round's scores appear | Before Homer's verdict | B4, S5 |
| `champion` | The winner appears | Under the crown line | B7, S6 (if you won), D6 (after the last throw), the debate crown |
| `rematch` | Rematch is tapped | During the reset | B7, then B2 |

Everything else has no music: the turn (T0 to T8), round titles (B2), the tally (B5) and the song (B6). In poetry, the beat carries them.

---

## Risk: the beat bleeds into the speaker's mic

If the arena plays the beat and the poet speaks into their phone, the phone's mic picks up the beat. A device's echo cancellation only removes sound that the device itself played, so the phone can't remove what the arena's speaker plays. The same goes for Homer's whisper if it plays from the arena, and for a loud hall.

What it can break:

- STT accuracy, with drum and lyre under the voice.
- The live drum strikes and the instant layer of the scene, which would react to the drum even when the poet is silent.
- The transcript: the rescue whisper could be transcribed as the poet's own words.

**Decided in SPEC.md: B plus D.** In a battle, the arena ducks the drum while a poet speaks, and the speaker's phone carries the beat as haptics. The rescue whisper still needs a test, since it can play from the arena during a speaking bar. The full set of options is below for reference.

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
  - On an iPhone mirrored to a TV, plain mirroring shows the phone's portrait screen with bars on either side. A full landscape arena needs the app to draw a separate layout for the external display.
  - Homer's voice and the beat use the same audio session as the mic, with voice processing on, so a device removes its own playback from its own mic (options A and C).

## Screen inventory

This is the list of layouts to design. The states above describe what changes inside each one.

**Arena (or the single device in solo modes)**

1. Launch and idle (F0)
2. Homer performing (F1, L1, S2, B6)
3. Event menu and event choices (E0, E1, F4)
4. Lesson path
5. Lesson (L0–L5)
6. Practice setup (R0)
7. Host a battle, with settings (H0), and the lobby with its QR code (H1)
8. Round title (B2, S1)
9. Turn: step up, speak, verdict, scores, best line, hoard (T1–T8)
10. Full breakdown (R1)
11. Round verdict and scoreboard (B4, S5)
12. Champion and match end (B7, S6)
13. Debate turn: side, question, transcript, played moves (section 8)
14. Discus field: pick up, wind-up, flight, distance, leaderboard (D1–D6)

**Phone**

1. Join (J1)
2. Mic check and the epithet Homer gives you (J2)
3. Waiting, or watching someone else's turn (J3, B3)
4. Your hand (from B2 on)
5. On deck and ready (T0–T1)
6. Speaking, with or without the hold-to-speak target (T2–T3)
7. Your result (T5–T8)
8. Final (B7)
9. Event menu, or "The arena is picking" in a hall (E0)
10. Move hand, with tap to play (debate T3)
11. Discus: safety card, hold target, look up, your distance (D0–D5)

## Open questions for Matus

1. **Decided by leader (Matus can veto):** after first open, the poetry tile suggests Learn (Bard lesson 1), so "Now let me show you how I did it" pays off.
2. Where does the rescue whisper play? From the arena, it can bleed into the speaker's mic during a speaking bar. From the speaker's phone, voice processing removes it, but the room doesn't hear it.
3. The live drum strikes come from loudness and the Beat score comes from the scanner, so they can disagree. Is that acceptable? And should the Beat score also check timing against the drum?
4. Demo mode: when a judge stays after 2:00 for a rematch, do they take a poet's seat (the poet's iPhone and headset), or does a third team iPhone join as a third poet?
5. Your hand across rounds: is a spoken card spent, with unspoken cards carrying over and the hand refilling to five? That's how I read "save your best formula for the last round."
6. A battle tie: one-line sudden death between the tied poets, or a shared crown?
7. The song stitches every verse: about 70 s for two poets and three minutes for five. Do we cap it at a few lines per poet?
8. Lessons: can you open any one, or only in order?
9. Spar: how strong should Homer play? Should a beginner be able to beat him?
10. If the mic is denied: offer typed input, or stay voice-only?
11. Freeze rescue: should using the whispered formula cost Craft points?
12. Debate: is 45 s the right turn length?
13. Discus: three throws with the best one counting? And should the Phayllos line (29 m, the ancient legend's throw) be on the field?
14. Event menu: which locked tiles? I used chariot race, javelin and wrestling.
15. In a hall, does only the arena pick the next event, or do the phones vote?
