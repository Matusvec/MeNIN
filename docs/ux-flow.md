# MeNIN: UX flow

This doc is for Matus to design against. It covers the flow, the states, the timing and what each screen shows. Visual design is Matus's, so this doc describes what is shown and what changes, never how it looks. Words like "large" or "pinned" describe hierarchy.

`SPEC.md` (as of commit 961bc37) is the source of truth. Anything not in it is marked **Proposal Pn** and waits on Matus.

MeNIN is ancient Greek Wii Sports, with Homer as the host: party events on one shared screen, with phones as controllers. The poetry battle is the core (sections 1 to 6). Socratic debate and discus are in build now (sections 8 and 9). The event menu ties them together (section 7), and section 10 says where the music plays.

## How to read this

**Devices**

MeNIN is one universal iOS app (iPhone and iPad), distributed through TestFlight, plus the website, which is the arena. In a battle, the website is the one big screen, and each phone runs the app as a player.

- **Arena**: the one big shared screen. It's the website, full screen in a laptop browser at its public URL (spec: the website is the only arena people see). It shows the scene, the live words, the countdown ring and the scoreboard, plays Homer's voice and the song's beat, and shows the QR code to join. The app's own arena mode stays behind the Dev screen as an emergency fallback.
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
- No sound effects beyond the beat and a soft strike on a hit (spec). The only other sounds are the hosts' voices and the music cues in section 10.
- Nothing ever looks frozen (spec). Every wait over about 300 ms shows the loading mark and one plain line saying what's happening ("Homer is weighing your verse…").

## Decided and proposed

**Approved by Matus. These are in SPEC.md now, so the body below treats them as spec without tags.**

- **The beat lives in the lessons and the song:** a slow drum-and-lyre loop, four beats a bar, one line per bar. A stressed syllable that hits a beat sounds a soft strike. Bard lessons teach with it, and Homer performs the stitched song over it.
- **Free verse in battle** (Matus, Sat 3:30 PM: "I just want to spit poetry without the metronome"): no drum, no beat haptics and no Speak/Breathe while a poet speaks. One SPEAK, one window with a countdown ring (20 s in demo mode), and "I'm done" ends it early. A line is whatever you say between breaths.
- **Freeze rescue:** about 2.5 s of silence mid-turn in battle and Practice brings Homer's phrases forward, and Homer whispers one that fits. It never fires in the first 3 s after SPEAK, and at most twice a turn, so an ordinary breath never sets it off. Lessons keep about 1 s inside a speaking bar, and lesson 2 teaches it.
- **Arena and phones:** the website is the one shared screen, and each phone is that poet's mic and private phrases. You join by QR code or room code.
- **A fresh epithet every battle:** Homer coins a new one for each poet in each battle, never one of their last five (Matus: the same one every time is boring). It comes from Homer's world ("of the bronze spear", never a modern noun). The one you forge in lesson 3 ("___, Breaker of Horses") joins your hoard and is only the fallback.
- **A fresh theme every round:** Homer writes it: six words or fewer, vivid and specific, from Homer's own world (ships, war, gods, exile, homecoming), with a feeling anyone can riff on, and never one of the last twenty ("The ship that left without you"). The written themes are the fallback.
- **Homer's world only** (Matus: "umbrellas did not exist"): nothing in a theme or an epithet was invented after the Bronze Age. No phones, trains, deadlines, clocks or coffee. The feeling can be modern; the objects can't.
- **Homer's phrases:** optional help, not homework. Your phone shows three stock phrases that fit the theme and the beat, under one line: "Stuck? Use one of Homer's phrases. It scores Craft." Using one pops "+Craft". They replace the hand of five.
- **3-2-1, then SPEAK:** a 3, 2, 1 with a haptic tick on each, then "SPEAK" fills the phone and the arena in the poet's color, once, for the whole verse. The start is unmistakable.
- **Flow:** the Beat axis is shown as Flow (its key stays `beat`). It asks whether the verse moved: a natural rhythm of roughly four stresses a line, judged from the words alone with no drum timing, and forgiving. It counts for less in the total than Image, Answer and Craft.
- **Hands-free mic:** in battles the mic opens with a haptic thump when your turn goes live and stays open for the whole verse. Your words show live on the arena, and "I'm done" ends early.
- **Carved line:** the best line of each round is carved in gold across the arena.
- **The stitched song:** at the finale Homer stitches every verse into one poem and performs it over the beat while the scene replays the battle's colors, then crowns the champion.

**Proposals P7 to P21**

Leader approved these as delegator, and Matus can veto any of them. Approved items keep their Pn tag in the body, so a veto is easy to trace.

| ID | Proposal | Status |
| --- | --- | --- |
| P7 | **Answer prompt.** During your turn, the previous poet's best line stays on screen as the thing you answer. | Approved |
| P8 | **Card reveal.** When you speak one of Homer's phrases, that card turns over onto the arena for everyone to see, with its "+Craft". | Approved |
| P9 | **Voice menu.** Homer asks "Learn, train, or fight?" and you answer out loud. | **Cut:** the risk of misrecognition outweighs the gain. Menus are tap-only |
| P10 | **Help after misses.** In a lesson, after three misses Homer gives you the first half of the line. After five, he walks you through it and the lesson lands. | Approved |
| P11 | **Color replay.** When Homer re-reads your best line, the scene replays the colors it showed while you said it. | Approved |
| P12 | **First open.** On first launch, Homer speaks before any menu and asks for one line (section 1). | **Approved by Matus,** first launch only, in SPEC.md as "First open" |
| P13 | **Push-to-talk.** Hold to open the mic. | **Replaced** by the hands-free mic (Matus, Sat 2 PM: push-to-talk confused first-timers) |
| P14 | **Demo mode extras.** Demo mode itself is in SPEC.md. The extras: our poet goes first, operator keys, and the best-line re-read saved for the judge (section 6). | Approved |
| P15 | **One reroll.** If Homer coins your epithet on join, you can ask for another one, once. | Approved |
| P16 | **The hall stays open between events.** When an event ends, the arena goes back to the event menu with everyone still joined, so nobody rejoins to switch events (section 7). | Approved, and in SPEC.md |
| P17 | **Tap to play a move.** In debate, you tap a move card on your phone as you make the move. It lands on the arena, and the judge checks that you really made it (section 8). | Approved, and in SPEC.md |
| P18 | **Sides are dealt.** In debate, sides alternate by turn order, so you often argue a side you don't hold (section 8). | Approved, and in SPEC.md |
| P19 | **Demo mode music.** At the judging table, the hall theme stays at its ducked level the whole time, because we talk over the menu. An operator key mutes all music (sections 6 and 10). | Approved, and in SPEC.md "Music" |
| P20 | **Score number in lessons.** After each try in a lesson, your scanner score (1 to 10) shows small beside Homer's note, so you can watch it climb. The first-timer study (`docs/study.md`) and the video's before-and-after shot both read it off the screen (L4). Builds 4 and 5 label it "Beat". If the lesson screen is renamed to Flow, the study names it the same way. | Approved |
| P21 | **The call to step up.** As each turn starts, the host calls the speaker by name. The round's first poet gets the theme's call ("Priya, Salt-Tongued. The sea is yours."). Every later poet gets "Answer that.", since they answer the line before (P7). In debate, the host says your side (T1 in sections 5 and 8). | Approved, built in the app and the website |
| P21b | **A call for a fresh theme.** Only the written themes have a call, so with fresh themes the first poet nearly always hears "The floor is yours." Homer writes a call of five words or fewer in the same step as the theme ("The ship that left without you" → "Call it back."). | Approved, in builder's plan: the theme and its call come from one call |
| P22 | **The freeze in free verse.** With no bars, a breath between lines is a pause too, and lines are split at pauses. At SPEC's 1 s, the rescue could fire between ordinary lines. In battle and Practice, the rescue fires after about 2.5 s of silence, never in the first 3 s after SPEAK, and at most twice a turn. Lessons keep 1 s inside a speaking bar. | **Approved,** and in SPEC.md (8d6afad, which moved it from 1.5 s to 2.5 s) |

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
| 1 | The beat | Four stresses a line, a pause in the middle | 2 lines | Both lines have four stresses and a break (scanner) | Flow |
| 2 | The formula | Fill half a line with one of Homer's phrases. Homer sets a hard line so you freeze, and the freeze rescue saves you | 1 line on Homer's hard prompt | One of Homer's phrases, whispered or picked yourself, fills one half and the line scans | Craft |
| 3 | The epithet | Coin your own ("___, Breaker of Horses"). It joins your hoard, and Homer falls back on it in battle | Your epithet, then a line using it | It scans and the judge rates it well | Craft |
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

- **Arena:** A one-bar count-in, then the beat, the live lane, the transcript, and the scene moving with your voice. Homer's model line sits faded beside yours for comparison. From lesson 2 on, Homer's phrases are visible.
- **Phone:** The lane, the transcript and Homer's phrases. The model line is collapsed.
- **Homer:** Silent, apart from a freeze rescue. In lesson 2 the freeze is the point: Homer's prompt is meant to stop you, and the rescue is the lesson.
- **Next:** The required lines are done. Each line gets a speaking bar, then a rest bar (spec).

#### L4 · One note · ~3–4 s

- **Arena:** The single spot Homer is talking about is marked on your lane: a missed stress, a rushed break, or the half that wasn't a formula. Only ever one spot. With P20, the try's scanner score (1 to 10) shows small beside it.
- **Phone:** Same.
- **Homer:** One thing, no more. "Three hits. You owe me one more." / "You rushed the break. Let it breathe."
- **Next:** Landed → L5. Otherwise back to L3.
- **Timing:** Lesson 1 feedback can come straight from the scanner without a Claude call, well under a second. Lessons 2 to 6 use the same ~3 s budget as the turn (see the latency budget in section 5).
- **With P10:** After the third miss, Homer speaks the first half and you finish it. After the fifth, he walks you through it and the lesson lands.

#### L5 · Landed · ~5 s

- **Arena:** The lesson is marked landed on the path, and your landing line is shown as your best line. In lesson 3, the epithet is set into your hoard and labeled as your battle name.
- **Phone:** Same.
- **Homer:** Short hype. "That's the beat. It's yours now." In lesson 3: "Breaker of Horses. Good. That's how my hall will know you."
- **Music:** The ambience comes back.
- **Next:** **Again**, **Next lesson** or **Spar**. It waits; nothing auto-advances.

---

## 3. Practice mode: spar with Homer

Practice has two ways to play. **Reps** is one turn at a time with the full breakdown. **Spar** is you against Homer, best of three. Both use the turn from section 5. Practice is also the demo fallback if multiplayer breaks, so it has to run on the arena alone with no phones.

#### R0 · Setup · until start

- **Arena:** Reps or Spar. A theme: three fresh theme cards from Homer, plus "Random". A Homer mode (hexameter) toggle, if it ships.
- **Phone:** Same, stacked.
- **Homer:** "Pick your ground. Or let me pick it."
- **Music:** `training-ambience`. In Reps it fades out at the count-in and comes back at the breakdown (R1).
- **Next:** Start.

### Reps

Theme, then Homer's phrases, then your turn (section 5), then the full breakdown. From there: **Again** (same theme, new phrases), **New theme** or **Spar**.

#### R1 · Full breakdown · until you move on

- **Arena:** Everything the turn's verdict shows, plus a one-sentence reason for each of the five axes, your verse line by line with the stresses the scanner counted, the quoted best line, and any formula added to your hoard.
- **Phone:** Same, with the axes as a list you scroll.
- **Homer:** The verdict line from the turn, nothing more. The reasons are text only.
- **Next:** A tap.

### Spar: best of three

Each round Homer goes first and you answer him. First to two rounds wins.

#### S1 · Round start · ~6 s

- **Arena:** "Round N", the theme, and the round score (Homer 0, you 0).
- **Phone:** Same, plus Homer's phrases.
- **Homer:** "Round one. A ship that never came home. I go first."
- **Music:** In round one, the ambience stops and `poetry-intro` plays, then Homer speaks.
- **Next:** Automatic.
- **Timing:** Homer's verse is generated during this state. In round 1, generation starts as soon as the theme is chosen. In rounds 2 and 3 Homer answers your last verse, so generation starts the moment your transcript is final and runs under your verdict.

#### S2 · Homer's verse · ~12 s

- **Arena:** Homer performs his verse free, the way a battle turn runs, and the scene moves with his voice. With P8 his phrase cards turn over as he uses them.
- **Phone:** Same. Homer's phrases stay visible so you can plan.
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

- **Arena:** The website, open on the laptop that will be the arena: "Host a battle on this screen". The settings sit behind it: rounds (3), turn window (10 s a line), Homer mode, and demo mode. The mic is always hands-free in battles.
- **Next:** The tap creates the room and puts this device in arena mode.

#### H1 · Lobby · until the host begins

- **Arena:** The room code and a QR code, large enough to scan from across a table. The poets who have joined, each by name and epithet. A **Begin** button once two or more have joined.
- **Phone:** See J1 to J3.
- **Homer:** Silent between entrances.
- **Music:** `hall-theme` continues from the menu. It ducks under each entrance, and goes silent while any phone's mic is open (J2).
- **Next:** The host taps Begin. The limit is five poets; a sixth person joins as a spectator.

#### J1 · Join (phone) · ~10 s

- **Phone:** Scanning the QR code with the camera opens the app on this screen. The fallback is to open the app, choose Fight, and type the room code. The screen has a field for your name and one button: **Enter**. The epithet comes from Homer in J2.
- **Arena:** No change yet.
- **Next:** Enter.

#### J2 · Mic check and entrance · ~5 s

- **Phone:** The iOS mic permission prompt (first time only), then "Say your name. Loud." with a level meter. Homer coins a fresh epithet for this battle during the check, never one of your last five, and the phone shows it: "Homer names you: Priya, of the bronze spear." With P15 there is one **Ask again**; otherwise it is kept after 2 s. If the new one isn't back in time, Homer uses the epithet in your hoard (lesson 3), and if you have none, your name alone.
- **Arena:** Your name and epithet arrive, and when your voice comes through, the scene answers it.
- **Homer (from the arena):** "Enter Priya, of the bronze spear!"
- **Music:** The arena's hall theme goes silent while this phone's mic is open, so it stays out of the name clip that discus reuses. It ducks under the entrance.
- **Next:** Your voice is heard → J3. The mic fails → retry, with tips.
- **Notes:** Generating the epithet is a fast Claude call that runs during the mic check. Names and epithets are spoken aloud, so filter them for PG content first. On **Rematch** every poet gets a fresh epithet again, coined during the reset (B7). There's no second entrance, so the room hears the new one in the first poet's call (T1) and the crown.

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
- **Phone:** The theme and Homer's phrases: three stock phrases that fit this round's theme and the beat, under "Stuck? Use one of Homer's phrases. It scores Craft." They're dealt fresh each round, because each round's theme is fresh, so nothing carries over (this settles open question 5). You can look them over from now until your turn.
- **Homer:** "Round one. The ship that left without you." In demo mode there's only one round, so he drops "Round one" and says the theme with the first poet's call (T1).
- **The theme is fresh:** Homer writes it ahead, while the previous round's verdict plays (for round one, at Begin), so the round never waits on it. If it isn't ready, a written theme is used, without saying so.
- **Next:** Automatic → the first poet's turn.

#### B3 · Turns · ~45 s each (section 5)

- **Arena:** The turn, as described in section 5.
- **Phone:** The speaker's phone runs the turn. Everyone else's phone shows who is speaking, their own phrases to plan with, and their place in the order. If the spectator layer ships, it also shows reaction buttons.

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
- **Next:** **Rematch** (same poets, fresh themes and epithets), **New hall** or **Leave**. Ties are open question 6.

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
- **Phone (the next poet):** "You're next." Homer's phrases come forward.
- **Next:** The previous turn ends.

#### T1 · Step up · ~3 s

- **Arena:** The poet's name and epithet. With P7, the previous poet's best line is pinned and labeled as the line to answer; for the first poet of a round, the theme is pinned instead. The countdown ring is full.
- **Phone:** A **Ready** button, Homer's phrases, and the theme.
- **Homer (P21):** calls the poet up in MC voice, using the name and this battle's epithet.
  - **The round's first poet:** "{name}, {title}." and then the theme's call, like "Matus, Breaker of Horses. Call it back." A fresh theme gets the call Homer wrote with it (P21b). A written fallback theme gets its call from the table below, and anything else gets "The floor is yours."
  - **Every later poet:** "{name}. Answer that." Their job is to answer the line pinned on the arena (P7), and the call says so.
  - The count-in (T2) waits until Homer finishes, even in auto-ready, so his voice never runs into an open mic.

| Written theme (fallback) | The call |
| --- | --- |
| A ship that never came home | "The sea is yours." |
| The night before the battle | "The watch is yours." |
| The war between two brothers | "Pick a brother." |
| The city that fell in one night | "The walls are yours." |
| The ship that left without you | "Call it back." |
| A feast for a returning hero | "Raise the cup." |
| The forge at midnight | "Strike while it's hot." |
| A storm on the open sea | "The storm is yours." |
| The road that brought you here | "The road is yours." |
| The words you never said | "Say them now." |
| Dawn after the long battle | "The dawn is yours." |
| The wolf at the edge of the wood | "Mind the wolf." |
| A throne nobody wanted | "The throne is yours." |
| The fire that took the hall | "The fire is yours." |
| The gods are watching | "Give them a show." |
| The house you grew up in | "Take us home." |
- **Next:** A tap on Ready, or automatically after 5 s.

#### T2 · 3, 2, 1, SPEAK · ~3 s

- **Arena:** A large 3, 2, 1 with no drum, then "SPEAK" fills the arena in the poet's color.
- **Phone:** The same 3, 2, 1 with a haptic tick on each, then "SPEAK" fills the whole phone in the poet's color. The mic opens hands-free, with a haptic thump, when the turn goes live, so the first word isn't clipped, and it stays open for the whole verse. In solo modes it opens at the start of the count.
- **Lessons are different:** there the count-in is a bar of the drum, and each line gets a speaking bar and a rest bar (section 2).
- **Next:** SPEAK → T3.

#### T3 · Speak · one window: 20 s in demo mode, 10 s a line otherwise

Free verse: no drum, no beat lane, no beat haptics, and no Speak/Breathe per line (spec).

- **Arena:**
  - Your words, live and large, as you speak. That's the main element now. A new line starts where you pause for breath.
  - The countdown ring, emptying.
  - The scene moving with you: the instant layer follows loudness and pitch, and the color layer shifts with the feeling about every 1.5 s.
  - When you speak one of Homer's phrases, it's marked as played with "+Craft" (with P8, it turns over onto the arena).
  - With P7, the pinned line.
- **Phone:** "SPEAK" stays up in your color for the whole verse, with the countdown ring. Under it: your mic level, your last line, and Homer's phrases. One you use lights up and pops "+Craft". Then **I'm done**.
- **Homer:** Silent, except for the freeze rescue.
- **Next:** The ring empties or the poet taps I'm done.
- **Lines:** a line is whatever you say between breaths. The pause length that splits lines is builder's to tune. It has to be shorter than the freeze (P22), or every line break would raise a rescue.
- **Freeze rescue (P22):** after about 2.5 s of silence, Homer's phrases come forward on your phone, the one that fits is raised and shown first, and Homer whispers it. Never in the first 3 s after SPEAK, and at most twice a turn.

#### T4 · Settle · from the end of the turn to ~0.6 s

- **Arena:** The mic closes and the transcript locks. Then the loading mark and "Homer is weighing your verse…" until the verdict starts.
- **Phone:** The same loading mark and line.
- **Next:** The verdict is ready.

#### T5 · Verdict · starts by ~3 s, lasts ~3 s

- **Arena:** The verdict, captioned as Homer speaks it.
- **Phone:** The same caption.
- **Homer:** One line. "Strong bones, thin blood. Your third line carried you."
- **Next:** Automatic.

#### T6 · Scores · ~3 s

- **Arena:** The five axes count up in the order the phone shows them, picture first: Image, Answer, Craft, Flow, Range. Then the turn total, in which Flow counts for less than Image, Answer and Craft (spec). In battle, the scoreboard updates. "Beat" never appears as a label in poetry; it's Flow.
- **Phone:** Your five axes and your total.
- **Next:** Automatic.

#### T7 · Best line · ~4 s

- **Arena:** The quoted line, alone and large. With P11, the scene replays that line's colors.
- **Phone:** The same line.
- **Homer:** Re-reads your line in his own voice.
- **Next:** Automatic.

#### T8 · Hoard · ~2 s, only when earned

- **Arena:** "Into the hoard: storm-throated", with the poet's name.
- **Phone:** The new card joins your hoard.
- **Homer:** "That one's yours now."
- **Next:** The next poet's T1, or the round verdict.
- **Rule (spec):** You coined it, it scans, and the judge rated it well.

End to end, a three-line turn takes about 3 + 3 + 30 + 10 seconds, so roughly 45 s. In demo mode, with the 20 s window, it takes about 35 s.

### Latency budget

The goal: Homer starts speaking the verdict about 3 s after the turn ends. For the first 0.6 s, nothing on screen waits on the network.

| After the turn ends | What happens | Source | Budget |
| --- | --- | --- | --- |
| 0 | Turn end detected | on device | – |
| 0–0.3 s | Mic closes, transcript locks, loading line | on device | no network |
| by 0.6 s | Final transcript | Cartesia STT | 600 ms |
| by 0.7 s | Flow score | meter scanner | 100 ms |
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

- **At 4 s with no verdict:** Homer says a pre-recorded stall line ("The Muse is still counting."), and Flow and Range appear, since they're already done.
- **At 10 s:** Show Flow and Range only, with "Homer is silent on this one." Never fall back to a canned verdict; that would be a mocked response, which AGENTS.md forbids in the demo path.

---

## 6. Demo mode: the judging table

**The setting** (from gtm): a 2-minute pitch with a live demo, at a table shared by two or three teams, with three judges and a noisy hall.

**The second-by-second script is `docs/gtm/demo-script.md`** (SPEC.md points there). **The logistics are in `docs/gtm/run-sheet.md`:** devices, charging, setup, the rematch drill and fallbacks. This section only covers what the app does differently in demo mode.

**Who plays:** two team poets battle (the poet and Matus), each on their own iPhone with a wired headset. The judges pick the theme from three cards and watch. After 2:00, a judge can take a team iPhone for a discus throw or a rematch. Judges never install anything, since MeNIN is TestFlight-only.

**The money moments, in the order they happen:**

1. Homer's first-open line, replayed by the operator: "The first word of Western literature is mēnin. Rage."
2. A judge picks the battleground.
3. 3, 2, 1, SPEAK, then a free verse: the words land live on the arena, the ring runs down, and the scene paints the voice.
4. The freeze rescue, staged but running live: Homer whispers one of his phrases, the poet uses it, and "+Craft" pops.
5. A spoken verdict starting about 3 s after the turn, with the five axes counting up under it.
6. The carved line, and the 4-line song stitched from the verses the table just heard.

### What demo mode changes

Demo mode is in SPEC.md. Rows marked P14 are extras, approved by leader.

| Setting | Normal | Demo mode | Source |
| --- | --- | --- | --- |
| Rounds | 3 | 1 | spec |
| Poets | 2 to 5 | 2 team poets. Judges pick the theme and watch | spec, demo script |
| Turn window | 10 s a line, with the countdown ring | 20 s, with the countdown ring | spec |
| Ready and mic check | Ready tap, mic check on join | Auto-ready, no mic check | spec |
| Verdict and scores | Verdict, then scores | Scores count up while Homer speaks the verdict | spec |
| Best-line re-read and hoard step | Every turn | Off. The best line is carved once, at round end | spec |
| Tally | Yes | Skipped | spec |
| The song | Every verse | 4 lines | spec |
| The crown | Proclamation and compliments | One line | spec |
| Theme | Fresh from Homer every round | Judges pick from 3 fresh theme cards on the arena. Optional, and the first thing to cut; without it, Homer gives one fresh theme. Either way no two pitches share a theme, so there's nothing fixed to rehearse | spec |
| Epithets | Fresh every battle | Fresh every battle, including each rematch | spec |
| Rematch | n/a | Resets in under 10 s: same poets, fresh themes and epithets | spec |
| Mic | Hands-free in battles | Hands-free, with wired headsets | spec |
| Replay opening | n/a | An operator key replays Homer's first-open line on the arena | demo script |
| Operator keys | None | Replay opening, advance, retry the turn, skip, rematch | P14 |
| Music | Every cue (section 10) | The same cues. The replayed opening brings its bed. The hall theme stays at its ducked level because we talk over the menu, and an operator key mutes all music. The poetry intro plays under the theme cards and never delays them | spec (P19), demo script |

---

## 7. The event menu

This is the home screen, Wii Sports style: one tile per event, and each tile opens onto its own few choices. On first launch, F4 lands here with the poetry tile already open.

#### E0 · Event menu · until a pick

- **Arena:** A grid of tiles. Each live tile shows the event, its host, what you do in one line, and your best on this device: rank, wins, or longest throw. The locked tiles follow, with a name only, marked locked.

  | Tile | Host | One line | Opens to |
  | --- | --- | --- | --- |
  | Poetry battle | Homer | Spit verse on a theme. Homer judges. | Learn, Train, Fight |
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
| Hand | Homer's phrases: three, optional | Five moves: at least one each of open, attack, defend and close |
| Beat | None in battle: free verse. Lessons and the song have it | None |
| Turn length | One window with a countdown ring: 10 s a line, 20 s in demo mode | 45 s (suggested), with a "Ten seconds" call |
| Freeze rescue | About 2.5 s of silence, never in the first 3 s (P22); Homer whispers a phrase | About 2 s of silence; Socrates whispers a question to ask |
| Using a card | A spoken phrase is matched in the transcript and pops "+Craft" | You tap the card as you make the move (P17). The judge checks you made it |
| Rubric | Flow, Craft, Image, Answer, Range | Claim, Reason, Answer, Craft, Poise |
| The axis Claude doesn't score | Flow, from the scanner | Poise, from fillers, pace and silence |
| Hoard | Coined formulas join it | None |
| Round end | The best line is carved | Same |
| Finale | The stitched song | Socrates' last question, about 10 s. He quotes the strongest point of the night, then asks the one question nobody answered |
| Practice | Reps, and spar with Homer | Spar with Socrates, best of three. He takes the other side and argues mostly by asking you questions |
| Music | `poetry-intro` opens a battle or spar. Nothing plays in turns | `debate-intro` opens a battle or spar. Nothing plays in turns. The round-end and champion stings are shared |

### The debate turn

Only the states that differ from section 5 are listed.

#### T1 · Step up · ~3 s

- **Arena:** The debater's name and epithet, and their side, large. The question is pinned. With P7, the last speaker's strongest line is pinned as the point to answer.
- **Phone:** Your side, your five moves with their roles marked, and **Ready**.
- **Socrates:** "{name}, {title}. You say {side}. The floor is yours. Try not to fall through it."
- **Next:** Ready, or automatically after 5 s.

#### T2 · Count-in · ~3 s

- **Arena:** The same 3, 2, 1 and "SPEAK" in the debater's color as poetry (spec, "The turn"), with no drum. Socrates says "Go." on the 1, so he's done before SPEAK.
- **Phone:** The same 3, 2, 1 and SPEAK. The mic opens hands-free with the haptic thump.
- **Next:** SPEAK.

#### T3 · Speak · 45 s

- **Arena:** The live transcript is the main element, since there's no lane. Time left, and move cards landing as they're played (P17). The scene still moves with the voice.
- **Phone:** Your five moves (tap one as you make it), time left, a short transcript, and **Done**.
- **Socrates:** Silent, except "Ten seconds." and the rescue whisper.
- **Next:** 45 s pass, or Done.
- **Freeze rescue:** after about 2 s of silence, your hand comes forward, one move is raised, and Socrates whispers a question in your own voice ("What do you mean by fair?"). Asking it plays that move. The whispers are prepared at T1, so the rescue is instant.
- **P17, tap to play:** a tap is a claim, not a score. A tapped move you didn't make earns no Craft, and the verdict reason says so. A move you made without tapping still counts if the judge hears it.

#### T4 to T7 · Verdict · same timing as poetry

Same states and latency budget. The verdict is in Socrates' voice, the five debate axes count up, and Socrates re-reads your best line. Poise is ready first, the way Flow is in poetry.

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
- **Homer:** Silent.
- **Music:** None, and no crowd sound (spec: no sound effects beyond the beat and the soft strike). The haptics carry the build.
- **Next:** The thumb lifts → D3.
  - A lift before a real swing (under 0.5 s, or under about half a turn) is a drop, not a throw. "That's a drop, not a throw." One retry.
  - Holding for more than 6 s resets to D1: "The crowd is getting old. Throw."

#### D3 · Release · instant

- **Arena:** The discus leaves the hand.
- **Phone:** A heavy haptic, and "Look up."
- **Music:** None. The whoosh was a sound effect, so it's cut (spec).
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

- **Never under an open mic** (spec). Music fades out over about 0.3 s before any mic in the room opens, and stays out until it closes. That includes the mic check (J2) and the line in first open (F2). Music bleeding into a phone's mic hurts STT the same way the beat does (see "Risk" below).
- **Never with the beat.** In lessons and under the stitched song, only the procedural drum-and-lyre beat plays. In battle turns nothing plays at all, only the poet's voice (free verse). Music fades out before the beat starts.
- **Ducks under a host** (spec). When Homer or Socrates speaks, music drops about 12 dB and comes back about 0.5 s after he stops. The exception is the first-open bed, which is written to sit under Homer and plays at full level.
- **The arena plays it** (spec). In a hall, only the arena plays music. Phones never do, since they're the mics. In solo modes the one device plays it.
- **Demo mode** (spec, P19): the hall theme stays at its ducked level, and an operator key mutes all music.
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
| `discus-fanfare` | The distance appears | Before Homer's distance line | D5 |
| `round-end` | The round's scores appear | Before Homer's verdict | B4, S5 |
| `champion` | The winner appears | Under the crown line | B7, S6 (if you won), D6 (after the last throw), the debate crown |
| `rematch` | Rematch is tapped | During the reset | B7, then B2 |

Everything else has no music: the turn (T0 to T8), round titles (B2), the tally (B5) and the song (B6). The beat carries the song. Battle turns stay quiet apart from the voice.

**The beat's sounds.** The composer also records the beat's single hits: six lyre notes (`lyre-d3`, `lyre-f3`, `lyre-g3`, `lyre-a3`, `lyre-c4`, `lyre-d4`), `drum-kick` and `drum-rim`. They're dry, mono, 48 kHz, and start on the first sample. They replace the synthesized kick, rim and pluck in the beat. The app still schedules every hit, so the beat stays procedural, and the strike on a hit is the kick and rim together, played soft (spec).

**No sound effects** (spec, Matus: weird effects are worse than silence). Beyond the music cues above, only the beat and the soft strike make sound. No whoosh, crowd, card flips, knocks, chisel taps or thumps. The haptics on the phone stay. Until the files arrive, the synthesized sounds stay. The full spec for these files is in `docs/audio.md`.

---

## Sat 8 PM runs

The checkpoint (`docs/gtm/reality-check.md`): an extra event that can't run **5 times in a row without a failure** stays a locked tile for the demo. Poetry is never locked, but it gets the same 5 runs, because it's the demo.

**Rules for every run**

- **Set up as at the table:** the arena is the website, full screen in a browser on the arena Mac, on Ethernet. Phones in poetry and debate have wired EarPods. The production agent service runs with Moss dealing, demo mode is on, and every phone is on **build 25 or later**, the build judges get (leader), all on the same build. Check the number in TestFlight on every phone before an event's first run. If build 25 isn't in TestFlight by 8 PM, no series starts: tell the leader. Run it in the hacking hall, not in a quiet room.
- **The count:** 5 clean runs in a row per event. A failure resets that event's count to 0, and you can start again right away. A new build, a redeploy or a code change also resets it.
- **When:** debate and poetry have to finish by 9 PM, when the hall noise test starts. The motion events (discus, the Stadion, boxing and archery) use no mic, so hall noise doesn't touch them. If there are enough people, run them at the same time on a second laptop in the hall. If not, run them after 9 PM and finish by the leader's cutoff (proposed: 10:30 PM, so the tiles are settled before the 11 PM freeze).
- **Order:** debate, then poetry, about 40 minutes for both. The motion events go in this order: the Stadion, boxing, discus, then archery, about 45 minutes for all four. Boxing comes after the Stadion because SPEC opens boxing only once the Stadion passes. Archery goes last because it's the newest, and until it passes, its tile stays locked.
- **Motion events:** play only where there's arm room, away from laptops and other people, with a firm grip on the phone. If a phone leaves anyone's hand, that's a failure, and it stops that event for the night until the leader says otherwise.
- **Between runs:** the hall stays open. Use Rematch, the way we will at the table. Never relaunch the app or restart a server.
- **Between events:** after an event's last run, the operator presses **New event**, picks the next game, and presses **Begin**. Every phone stays joined, so nobody types a new code. New event is next to Rematch on the results screen and next to Begin in the lobby (builder, 6:44 PM).
- **Who records:** whoever isn't playing fills in the table at the end of this section and sends it to the leader. The leader decides which tiles are unlocked.

**These are failures in every event:**

- The app crashes, freezes, or has to be relaunched on any device.
- Someone has to do something that isn't in `docs/gtm/run-sheet.md`, like a hidden key, a server poke or a rejoin.
- The host is silent where he should speak, or he speaks with no caption.
- The arena or a phone shows a state that doesn't match the run, like the wrong player, a stale screen or a missing score.
- A wait of more than a moment shows no loading mark and no line, so the screen looks frozen.
- Music plays under an open mic.
- Any sound effect plays. The only sounds allowed are the beat, the soft strike, the hosts' voices and the music cues: no whoosh, crowd, card flip, knock, chisel, thump, punch, bell, starting gun or bowstring. Haptic ticks and buzzes on the phones are fine.

Player slips aren't failures when the app handles them as designed: a freeze gets a rescue, silence gets "Again", a short swing counts as a drop, a runner who slows down gets placed at the 40 s cap, punches faster than four a second are dropped, a weak draw drops the arrow low, and an arrow not loosed within 45 s is lost. Handling those is part of what we're testing.

### Poetry

- **One run:** a full demo-mode battle. The poetry tile opens and Homer gives the theme. Both poets take one free-verse turn in the 20 s window (two or three lines is plenty), then come the verdicts, the round verdict with the carved line, the 4-line song and the crown, and then **Rematch** until the next battle is ready.
- **Themes and epithets are fresh every run,** so there's no fixed theme, hand or epithet to rehearse. Play whatever Homer deals. That's what the runs test: the poets improvise on a theme they've never seen, the way they will at the table. If theme cards are on, the recorder picks one. Write the theme and both epithets in the table.
- **Who plays:** the demo cast. The poet is Poet 1 and uses at least one of Homer's phrases on purpose, so every run checks "+Craft". Matus is Poet 2 and does the staged freeze: at least one full line first, since the rescue never fires in the first 3 s after SPEAK, then silence until the whisper comes. The operator runs the arena.
- **Also a failure:**
  - A verdict starts more than 4 s after a turn ends.
  - Matus's staged freeze gets no whisper within about 4 s of going silent.
  - The 3, 2, 1 or SPEAK is missing on the phone or the arena, SPEAK isn't in the poet's color or doesn't stay up for the whole verse, or the first word gets clipped.
  - Anything from the old beat shows up during a turn: a drum, beat haptics, a beat lane, strikes, or Speak/Breathe per line.
  - The countdown ring is missing, or the turn doesn't end when the ring empties or when I'm done is tapped.
  - A rescue fires between ordinary lines, while the poet is only breathing.
  - The stitched song plays without its beat.
  - A clearly spoken line comes back empty or garbled in the transcript.
  - A phone doesn't show three of Homer's phrases under "Stuck? Use one of Homer's phrases. It scores Craft."
  - One of the three is clearly spoken and gets no "+Craft".
  - A score reads "Beat" anywhere, on the phone or the arena, instead of Flow.
  - Homer's theme is missing, isn't PG, or makes no sense out loud.
  - A theme or an epithet has something from after the Bronze Age in it: a phone, a train, a deadline, a clock hour, an umbrella.
  - Rematch takes more than 10 s.
- **Write down, but not a failure:** a theme over six words, or one repeated from an earlier run. An epithet repeated from an earlier run. A written fallback theme. If any of these happen twice in the series, tell the leader.

### Debate

- **One run:** a demo-length debate on the arena. The debate tile opens, Socrates asks the question, and both debaters take one 45-second turn, each tapping at least one move as they make it. Then come the verdicts, the round verdict, Socrates' last question and the crown, and then **Rematch** for the next run.
- **Who plays:** Matus is debater 1. Debater 2 is someone who hasn't played debate, in at least 2 of the 5 runs, since a judge will be in that seat. Debater 2 goes silent for about 3 s once in every run, to test the rescue.
- **Also a failure:**
  - The side on the arena or the phone is missing or wrong.
  - The silence gets no Socrates whisper within about 3 s.
  - A tapped move doesn't land on the arena.
  - A verdict starts more than 5 s after a turn ends.
  - Homer's voice speaks instead of Socrates'.
  - Any drum plays.

### Discus

- **One run:** one discus event with two throwers and three throws each. The discus tile opens, each thrower goes through the safety card on their first throw, then the throws, the flight, the distances with Homer's call, the leaderboard and "The discus goes to {name}.", and then **Rematch** for the next run.
- **Who plays:** the operator and one other person. The other thrower uses Matus's iPhone, as a judge will, and is someone who has never thrown, in at least 2 of the 5 runs.
- **Also a failure:**
  - A full swing with the thumb lifted at the end gets read as a drop, or as no throw.
  - The arena shows the throw more than about 1 s after the release.
  - A distance is plainly wrong: 0 m on a full swing, over 100 m, or different on the phone and the arena.
  - Homer gives the wrong call, like "New mark" when it isn't the hall's best, or names the wrong champion.

### The Stadion

- **One run:** one heat, the demo format. The Stadion tile opens. Homer says "One stadion. Phone in hand, pump your arms like a sprinter." and "Runners, to your marks.", then the 3-2-1 and GO show on the arena while the phones tick. Everyone races 192 m at once. Then come "{name} breaks the tape!", the winner's time, the places and "The stadion goes to {name}.", and then **Rematch** for the next run.
- **Who plays:** two or three runners on team iPhones, with three in at least 2 of the 5 runs, and someone who has never run it in at least 2. In one run, one runner only shakes the phone in place, without swinging their arms, to test the shake check.
- **Also a failure:**
  - The 3-2-1 on the arena and the ticks on a phone are more than a beat apart, or a runner moves before GO.
  - A runner who pumps hard the whole way doesn't cross before the 40 s cap. A full pump takes about 14 s.
  - A runner on the track stalls, jumps, or lags behind the arms by more than about half a second, or doesn't slow down within about a second of stopping.
  - The runner who only shakes the phone crosses the line.
  - The order on the arena doesn't match who crossed first, or a phone's place or time differs from the arena's.
  - The heat doesn't end at 40 s while someone is still short of the line, or that runner gets no place.
  - Homer names the wrong winner, or says "Nobody reached the line" when someone did.
  - A phone's screen dims or locks during the race.
- **Write down, but not a failure:** the winner's time, so we can tell whether the speed feels fair.

### Boxing

- **One run:** one bout, the demo format, on the v2 rules. The boxing tile opens. Homer says "{A} and {B}. Fists up.", the phones tick 3-2-1 to the bell, and the fight runs 60 s or to a knockout while Homer calls the big hits. Then comes "{loser} is down! The fight goes to {winner}!" or "The bell! {winner} takes it on the cards.", then "{winner}. The ring is yours.", and then **Rematch** for the next run.
- **Who plays:** two fighters on team iPhones, standing more than an arm's length apart and punching the air, never at each other. Someone who has never boxed in MeNIN fights in at least 2 of the 5 runs. At least one run has three fighters, to check that the winner stays on and that the third phone shows "Up next".
- **Stage the v2 moves in every run,** so each run checks them:
  - Fighter 1 throws two or three quick punches in a row while Fighter 2's guard is down (the combo).
  - Fighter 2 holds the guard up against a head shot, then punches straight back within half a second (the counter).
  - Each fighter throws at least one low punch to the body.
  - One fighter punches nonstop for about 5 s, then rests for about 5 s (stamina).
- **Also a failure:**
  - A clear, hard punch shows no throw on the arena. Punches faster than four a second are dropped on purpose.
  - A low punch lands on the head, or a high one on the body.
  - A fist on the arena sticks to one side for more than a few seconds.
  - Holding the phone upright and still doesn't raise the guard within about a second, or a head shot into a raised guard does full damage instead of showing BLOCKED.
  - The staged counter gets no COUNTER banner and no slow-motion flash.
  - The staged combo gets no COMBO stamp. Homer only calls a combo from the third punch, so a two-punch combo with no call is fine.
  - The stamina bar doesn't drop as the punches come or doesn't refill within about 5 s of rest, the tired fighter doesn't sag, or the nonstop punches don't hit softer by the end.
  - The fight stalls: the clock, a health bar or a fighter freezes, the bell doesn't end the fight at 0:00, or health reaching zero doesn't end it.
  - The knockout doesn't fall in slow motion, or the result names the wrong fighter. At the bell, the winner is the one with more health.
  - A phone's health or stamina doesn't match the arena's, or a hit gives no flash or buzz on the phones.
- **Write down, but not a failure:** how each bout ended (knockout or bell) and how long it lasted. The fight is tuned to last about 30 to 50 s. If most bouts go the full 60 s or end in under 20 s, tell the leader.

### Archery

Archery has been on the website since 6:35 PM as "Toxeia (beta)" (SPEC acbecb0). Like every event, it runs on build 25 or later. In build 24 the bow phone can't start the first archer.

- **One run:** two archers, three arrows each. Archers are the joined players, in the order they joined, so nobody types a name. The first phone in is the **bow** and its player shoots first. The second phone is the **arrow**, and its player shoots second. Each phone says which it is in big type. Begin reads "Waiting for the bow and the arrow" until both are in. Then Homer gives the rules ("Toxeia. One phone is the bow: point it at the target. The other is the arrow: hold, pull back, let go.") and says "{name}, take both phones." The archer holds the bow out at the target and taps **Ready**, and Homer says "{name} steps to the line." The arena shows only the target, with a live dot where the bow points, a draw meter, and the wind for each arrow: a direction arrow and a speed in m/s. When the wind is 3 m/s or more, Homer warns "A strong wind, to the left" (or right). The archer holds the arrow phone's button to nock, pulls it back toward their face to draw, and lets go to loose. The arrow flies, drifts with the wind, scores on the rings and gets Homer's call, and the next arrow follows by itself. After the third arrow, Homer says "{name} finishes on {total}." and "Pass both phones to {next}.", and the next archer taps Ready. After the last joined player shoots come the results and "The bow goes to {name}, with {total}.", and then **Rematch** for the next run.
- **Who plays:** two archers per run, with someone who has never shot in at least 2 of the 5. In at least one run a third archer joins on a third phone, to check that a phone that's neither bow nor arrow still gets a turn. The pass happens in every run, hand to hand, as it will at the table.
- **Also a failure:**
  - A phone doesn't say in big type which one it is, both phones say the same one, or they swap partway through.
  - Something starts without Ready: an archer's first arrow opens before the bow taps Ready.
  - Archers go out of join order, a joined player is skipped, or the arena names the wrong archer up.
  - After an archer's third arrow, there's no "Pass both phones to {next}", or Ready doesn't start the next archer.
  - The aim dot doesn't follow the bow: it lags by more than about half a second, drifts while the bow is still, or sticks at an edge.
  - Pulling the arrow phone back doesn't fill the draw meter, or moving it sideways does.
  - Letting go doesn't loose the arrow, or an arrow looses while the button is still held.
  - The wind isn't shown before an arrow is loosed, or the arrow drifts the opposite way from it. A calm 0 m/s is fine, as long as it shows.
  - A weak draw doesn't drop the arrow low.
  - The ring scored doesn't match where the arrow sits on the target, or Homer's "finishes on {total}" doesn't match the board.
  - An archer gets more or fewer than three arrows.
  - The wrong archer is named the winner.
- **Write down, but not a failure:** a phone fumbled in the pass. If it happens twice in the series, tell the leader, since judges will pass the phones at the table.

### Results

| Event | Run | Time | Pass or fail | What failed | Notes |
| --- | --- | --- | --- | --- | --- |
| Debate | 1 | | | | |
| Debate | 2 | | | | |
| Debate | 3 | | | | |
| Debate | 4 | | | | |
| Debate | 5 | | | | |
| Discus | 1 | | | | |
| Discus | 2 | | | | |
| Discus | 3 | | | | |
| Discus | 4 | | | | |
| Discus | 5 | | | | |
| Stadion | 1 | | | | |
| Stadion | 2 | | | | |
| Stadion | 3 | | | | |
| Stadion | 4 | | | | |
| Stadion | 5 | | | | |
| Boxing | 1 | | | | |
| Boxing | 2 | | | | |
| Boxing | 3 | | | | |
| Boxing | 4 | | | | |
| Boxing | 5 | | | | |
| Archery | 1 | | | | |
| Archery | 2 | | | | |
| Archery | 3 | | | | |
| Archery | 4 | | | | |
| Archery | 5 | | | | |

In Notes, write the winner's time for the Stadion, how each boxing bout ended and how long it lasted, and any fumbled pass in archery.

| Poetry run | Time | Theme | Epithets (Poet 1, Poet 2) | Pass or fail | What failed |
| --- | --- | --- | --- | --- | --- |
| 1 | | | | | |
| 2 | | | | | |
| 3 | | | | | |
| 4 | | | | | |
| 5 | | | | | |

Add rows for any restarted series. If an event never gets 5 clean in a row by its cutoff (9 PM for debate, the leader's cutoff for the motion events), its tile stays locked, and the demo script's lines for that event don't run.

---

## Risk: the beat bleeds into the speaker's mic

**Mostly settled by free verse (SPEC 5fb8baf):** no beat plays while a poet speaks in battle, and the song's beat plays with every mic closed. Lessons run on one device, where voice processing removes the device's own beat. What's left in battles is the rescue whisper from the arena (open question 2) and the hall itself. The analysis below is kept for reference.

If the arena plays the beat and the poet speaks into their phone, the phone's mic picks up the beat. A device's echo cancellation only removes sound that the device itself played, so the phone can't remove what the arena's speaker plays. The same goes for Homer's whisper if it plays from the arena, and for a loud hall.

What it can break:

- STT accuracy, with drum and lyre under the voice.
- The live drum strikes and the instant layer of the scene, which would react to the drum even when the poet is silent.
- The transcript: the rescue whisper could be transcribed as the poet's own words.

**Decided in SPEC.md before free verse: B plus D.** In a battle, the arena ducked the drum while a poet spoke, and the speaker's phone carried the beat as haptics. The rescue whisper still needs a test, since it can play from the arena during a speaking bar. The full set of options is below for reference.

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

- **In lessons, the strike on a hit has to be decided on the device holding the mic, within about 50 ms.** Battles have no strikes now. It can't wait for the transcript. The practical signal is a loudness onset close to a beat, since stressed syllables are louder. The Flow score comes later, from the scanner on the transcript, so the two can disagree (open question 3). When the mic is on a phone and the drum is on the arena, the strike also crosses the network and can land 100 to 200 ms late. With a mic on the arena, everything stays on one device.
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
4. Homer's phrases (from B2 on)
5. On deck and ready (T0–T1)
6. Speaking: 3-2-1, one SPEAK with the countdown ring, Homer's phrases and "+Craft" (T2–T3)
7. Your result (T5–T8)
8. Final (B7)
9. Event menu, or "The arena is picking" in a hall (E0)
10. Move hand, with tap to play (debate T3)
11. Discus: safety card, hold target, look up, your distance (D0–D5)

## Open questions for Matus

1. **Decided by leader (Matus can veto):** after first open, the poetry tile suggests Learn (Bard lesson 1), so "Now let me show you how I did it" pays off.
2. Where does the rescue whisper play? From the arena, it can bleed into the speaker's mic while they speak. From the speaker's phone, voice processing removes it, but the room doesn't hear it.
3. In lessons, the live strikes come from loudness and the Beat score comes from the scanner, so they can disagree. Is that acceptable?
4. Demo mode: when a judge stays after 2:00 for a rematch, do they take a poet's seat (the poet's iPhone and headset), or does a third team iPhone join as a third poet?
5. **Settled by the fresh themes (SPEC 7866476):** Homer's phrases are dealt fresh each round, so nothing carries over (B2).
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
