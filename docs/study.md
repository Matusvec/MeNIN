# First-timer study

Five people who have never freestyled take MeNIN's first lesson, and we write down how their Beat score changes from their first try to their last. That one real number is our proof that MeNIN teaches, so it replaces the benchmark (`docs/gtm/reality-check.md`, section 3). It goes in the pitch, on Devpost and in the video.

- **Who runs it:** the poet (`docs/gtm/README.md`, step 8). One person can run it alone.
- **When:** Saturday, 6 to 8 PM. It takes about 45 minutes for five people, including finding them.
- **Where:** anywhere at the venue with a little less noise. It doesn't need to be quiet.
- **The study build:** **build 18, which TestFlight shows as 0.1.0 (202610241606).** At 5:30 it should be the newest build TestFlight offers.
  - **If TestFlight offers a build newer than 18,** don't install it, because nobody has checked its lesson 1 yet. Install build 18 from Previous Builds (below) and tell the leader.
  - **If build 18 isn't there,** use the newest of these that is: build 14, 0.1.0 (202610241531); build 11, 0.1.0 (202610241510); build 4, 0.1.0 (202610240956).
  - **To install an older build:** in TestFlight, tap MeNIN, then **Previous Builds**, and tap Install next to its number.
  - All four score lesson 1 exactly the same. On build 4, Homer's voice needs a strong connection and can sound choppy, and the app can crash if something interrupts its audio. Count those as tech fails (see "Rules while it runs").
- **Finish by 8 PM.** The poet is Poet 1 in the Sat 8 PM poetry runs (`docs/ux-flow.md`, "Sat 8 PM runs"), which start around 8:20, after debate.

**Before 6 PM**

- **5:30:** update MeNIN in TestFlight to the study build, and charge the phone.
- **5:45:** the dry run below.
- **6:00:** start recruiting.

## What you need

- [ ] An iPhone with the study build of MeNIN from TestFlight, charged above 50%.
- [ ] Do Not Disturb on, and no other app playing sound. A call or another app taking the audio can stop Homer mid-lesson.
- [ ] Automatic updates off: in TestFlight, tap MeNIN and turn off **Automatic Updates**, so the build can't change in the middle of the study.
- [ ] Wired EarPods, the same ones we use in the demo
- [ ] A second phone with a stopwatch
- [ ] This page, open or printed, and the score sheet below
- [ ] **A dry run, 10 minutes before the first person.** Check four things:
  - **The build.** Open TestFlight, tap MeNIN, and check that its number matches the study build at the top of this page. If it doesn't, update it before anything else.
  - Take lesson 1 yourself once. Homer speaks and the drum plays.
  - After each try, the screen shows a **Beat** number from 1 to 10.
  - Your try gets feedback from Homer.

  If any of these fails, message the leader before you start. Don't run the study on another build or in a different mode on your own.

**Why the build matters:** since build 4, the beat is judged more strictly than in build 3. A hit has to land closer to the drum, and each drum beat counts one hit at most. Every person in the study has to be on the same build, or their numbers can't be compared. Judges get build 25 or later, and lesson 1 hasn't changed from build 18 through 25, in the app or on Homer's server (pm checked the code, Sat 7 PM), so the study's number holds for what judges play. Builds 4, 11, 14 and 18 score lesson 1 exactly the same (swift confirmed), so if the phone moves between them partway through, keep going and write it in Notes. Any other build change: stop and message the leader.

## Who counts

Ask two questions before anything else:

1. "Have you ever freestyled, rapped, or performed spoken word in front of people?" They need to say **no**. Writing poems privately is fine.
2. "Are you 18 or older?" They need to say **yes**.

Also:

- **Strangers only.** No one from our team, and no one who has already tried MeNIN.
- **Anyone who says yes to question 1 can still play for fun.** Just don't write their numbers down.
- **Everyone who starts counts,** even if they do badly or stop early. Never swap a person out for a better one. That's what makes the number honest.

## The recruiting line

About a minute, out loud:

> "Hey, got five minutes? We're building MeNIN at Cal Hacks. Homer, the ancient Greek poet, teaches you to freestyle on your phone. We're testing one thing: can someone who's never done it get better in a single lesson? So we're looking for people who've never freestyled or done slam. You put in earbuds, Homer shows you a move, and you try it out loud a few times. It takes five minutes, there's no wrong answer, and the only one judging you is Homer. Afterwards you can battle us, or throw the discus. Want to try?"

## Consent

Read this out loud, word for word, and tick their answers on the sheet:

> "Before we start: what you say goes to our speech-recognition and AI services so Homer can score it. I'll write down your scores, and nothing that identifies you.
>
> 1. Can we use your scores in our pitch, on our Devpost page and in our demo video, together with four other people's? If you say no, you can still play, but your scores won't count.
> 2. Can we quote one thing you say, without your name?
> 3. Can we use your first name with the quote?
> 4. Can we film your screen and voice for our demo video?
>
> You can say no to any of these. If you change your mind, tell us before Sunday 9 AM and we'll delete it."

- If they say no to question 1, they can play for fun, but don't count them.
- Questions 2 to 4 are optional, and a no changes nothing else.
- Write their **first name only** on the sheet, and only if they agreed to question 3. Everyone else is P1, P2 and so on.

## Steps for each person

About 5 minutes each.

1. **Recruit and check.** Use the recruiting line and the two questions in "Who counts".
2. **Consent.** Read it and tick the answers.
3. **Set up.** Hand them the iPhone with the EarPods in. Open MeNIN and start Bard lesson 1, "The beat". Then say:
   > "Homer will show you a move, then ask you to try it. Talk the way you'd talk across a table. I can't help you, because that's what we're testing."
4. **Start the stopwatch** when the drum counts in for their first try.
5. **Write down the Beat number after every try.** Say nothing about how to do it. If they ask you, say: "Do what Homer says."
6. **Stop** at whichever of these comes first:
   - Homer says "Four and four. That's the beat. It's yours now." That means the lesson landed, so stop the stopwatch and write down the time.
   - They finish their 5th try.
   - 4 minutes pass on the stopwatch.
   - They want to stop. That's always fine.
7. **Ask one question** and write their exact words: "What changed between your first try and your last?"
8. **Thank them.** Offer a battle or a discus throw.

**Rules while it runs**

- Don't coach. That means no counting along, no clapping the beat, no "louder", and no "good". Homer does all the teaching.
- If Homer gives them the first half of a line (after a third miss), the try still counts. Write "helped on try N" in Notes.
- **A tech fail** is when the app breaks: Homer is silent, there's no transcript, or it crashes. Cross that try out and write "tech fail" in Notes. Never cross out a try because it scored badly. If the app stays broken for 2 minutes, thank them and move on. They count as "stopped early".

## What to write down

| What | How |
| --- | --- |
| **Beat, first try** | The Beat number after their first try |
| **Beat, last try** | The Beat number after their last try. That's the try that landed, or the last one before you stopped |
| **Every try** | All their Beat numbers in order, like `3, 5, 6, 9`. It shows the curve |
| **Landed** | Yes, with the try number, or No |
| **Time to land** | The stopwatch time when Homer said "Four and four", or "–" if they didn't land |
| **Quote** | Their exact words from step 7, if they agreed to question 2 |

## Score sheet

**Consent**

| Person | Never freestyled | 18+ | 1. Scores | 2. Quote | 3. First name | 4. Video |
| --- | --- | --- | --- | --- | --- | --- |
| P1 | | | | | | |
| P2 | | | | | | |
| P3 | | | | | | |
| P4 | | | | | | |
| P5 | | | | | | |

**Results**

| Person | Beat, first try | Beat, last try | Every try | Landed (try #) | Time to land | Quote | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- |
| P1 | | | | | | | |
| P2 | | | | | | | |
| P3 | | | | | | | |
| P4 | | | | | | | |
| P5 | | | | | | | |

**Summary**

| | |
| --- | --- |
| Build (from TestFlight) | ___ |
| People counted | ___ |
| Average Beat, first try (add the first tries and divide by the number of people) | ___ |
| Average Beat, last try | ___ |
| Landed | ___ of ___ |
| Middle time to land (sort the landed times and take the middle one) | ___ |

When the last person finishes, send a photo of the sheet, or the filled-in tables, to gtm and the leader. Keep the sheet: if a judge asks, we can show it, since it has no names on it.

## From the result to one pitch line (for gtm)

**The line goes in:**
- the poet's line in `docs/gtm/demo-script.md` at 1:26
- the impact line in `docs/gtm/devpost.md`
- the Q&A answer in `docs/gtm/pitch.md`, "Isn't this just a game?"
- the video at 1:00–1:15, where a filmed first-timer shows the before and after Beat number (only someone who said yes to question 4)

**Pick the line:**

1. **The main line,** if the averages moved and most people landed:
   > "Last night, five people who'd never freestyled took lesson one. Their Beat score went from [first] to [last] out of 10, in about [time] minutes."
2. **The landing line,** if the averages barely moved but some people landed:
   > "Last night, [N] of five first-timers landed Homer's beat in their first lesson."
3. **No line,** if neither is true. The checkpoint already says: drop the number from the pitch (`docs/gtm/reality-check.md`).

**Keep it honest:**

- Count everyone who started, including anyone who stopped early, and say the real count ("four people" if it was four).
- Round the first and last averages the same way, to the nearest whole number.
- Say "Beat score" and "out of 10", which is what we measured. Don't say "learned to freestyle", don't give a percentage, and don't say "everyone" or "proves".
- Use the real time to land. If fewer than three people landed, leave the time out.
- The judging is on Sunday morning, so the demo script's "Tonight we sat five people" becomes **"Last night"**.
- Quote only people who said yes, word for word, with a first name only if they agreed to question 3.
- If a judge asks how Beat is measured: "Our stress scanner counts the four hits and the break in each line. It's the same Beat score you see in a battle, and it doesn't use Claude."
