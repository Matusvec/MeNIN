# Bard lessons

The six lesson scripts for Bard mode. The flow they run in is in `docs/ux-flow.md` (section 2, states L0 to L5). The formulas they reference by id are in `content/formulas.json`.

## How to use this file

- **Everything in double quotes is spoken by TTS, exactly as written.** No markdown, no notation.
- **Demo verses are notation, not speech.** CAPS mark the four hits, and ` / ` marks the break. Before TTS, lowercase the CAPS and drop the ` / `. Use the marks for the beat lane and for timing each hit to the drum.
- **Placeholders** like `{word}` are filled in by the app or the agent before TTS: `{word}` is a word from the poet's line, `{formula}` is a card from their hand, `{title}` is the epithet they coined, `{last_word}` is the last word of their line, `{hits}` is the number of hits the scanner counted, spelled out ("Three"), `{lines}` is the number of lines the exercise asks for, spelled out ("four"), `{n}` is the lesson number, `{half}` is the first half of a line from the lesson's demo verse, and `{line}` is a whole demo line. Both are in plain words, without the CAPS or the ` / `.
- **Feedback:** on each try, Homer says exactly one line: the first miss in the table that applies. If no miss applies, the lesson lands. **Timing never fails a lesson** (Matus, Sat 9:45 PM: content over exact timing; the beats stay). In lesson 1, "No break", "A hit on a small word" and "Ahead of the drum" are notes: they never fail a try, and when the try lands Homer adds the first one after the success line. In every lesson, three to five hits count as four.
- **Help after misses** (P10 in `docs/ux-flow.md`): after the third miss, Homer starts a line and the poet finishes it. After the fifth, he walks them through a whole line and the lesson lands. Both lines are in the table below.
- **Nothing is locked.** "Unlocks" says what the poet walks away with and where Homer points them next.
- **The voice:** a pro coach. Calm authority, precise, one fix at a time, never more than two sentences. He never names the poet's emotion.

## Lines every lesson uses

| When | Homer says |
| --- | --- |
| Lesson title (L0) | "Lesson {n}. {title}." |
| After feedback, before the next try | "Again." / "Go." / "One more." |
| No speech heard | "I heard nothing. Again, and louder." |
| The mic drops out | "I lost you. Check your mic, then go." |
| An inappropriate line | "Not in my hall. Give me another." |
| Returning to an unfinished lesson | "Back again. We were on {title}." |
| Fewer lines than the exercise asks for | "You stopped short. I asked for {lines} lines. Finish it." |
| Help after three misses | "I'll start it. You finish it. {half}" |
| Walkthrough after five misses | "Hear where the hits fall. {line}" |

---

## 1. The beat

- **id:** `beat`
- **The move:** four hits a line, a break in the middle.
- **Trains:** Beat and Craft.
- **Lands when:** both lines have three to five hits (four is the aim; scanner), and the verse says something: the judge weighs it at 40/100 or more. The break, where the hits fall and the timing never fail it.
- **Unlocks:** the beat, which every mode is built on. Homer points to lesson 2.

**Demo verse**

```
the MAST went DOWN / in the BLACK of the STORM
we LOST the STARS / and we LOST the SHORE
so I STRUCK the BENCH / and the ROWers SANG
the STORM had a VOICE / but OURS was LOUDer
```

**Name the move:** "Four hits a line. A breath in the middle."

**Exercise:** "Two lines about the road that brought you here. Four hits each. Breathe in the middle."

**Feedback**

| Miss | Homer says |
| --- | --- |
| Two hits or fewer | "{hits} hits. I need four. Add a word with weight." |
| Six hits or more | "{hits} hits. Too many. Cut a word." |
| No break | "One note: breathe in the middle of the line." |
| A hit on a small word | "One note: your hit fell on {word}. Give it to a word that matters." |
| Ahead of the drum | "One note: let the drum come to you." |
| Content is thin | "The beat's there. Now make me see the road." |

**Success:** "Four and four. That's the beat. It's yours now."

---

## 2. The formula

- **id:** `formula`
- **The move:** fill half a line with a formula from your hand. Homer sets a hard line so you freeze, and the freeze rescue saves you.
- **Trains:** Craft.
- **Lands when:** a formula from the hand, whispered or picked, fills one half of the line, and the line has three to five hits.
- **Unlocks:** the hand and the freeze rescue, which every turn in Practice and Battle uses. Homer points to lesson 3.
- **The hand for this lesson:** `wine-dark-sea`, `whale-road`, `as-the-fire-took-hold`, `with-nothing-in-my-hands`, `when-dawn-came-early`.

**Demo verse.** Its formulas are the wine-dark sea, the whale-road and "when Dawn came early". Mark them on the lane as Homer says them.

```
on the WINE-dark SEA / with a CREW of GHOSTS
I SANG their NAMES / so the GODS would KNOW
we RODE the WHALE-road / till the STARS gave OUT
when DAWN came EARly / I was ROWing aLONE
```

**Name the move:** "Half of every line is already written. Pull a phrase from your hand and finish it."

**Exercise.** This line is meant to freeze you: "Your ship is burning. Your crew is gone. One line. Go."

**Freeze rescue:** after about 1 s of silence, Homer whispers one card from the hand, and nothing else: "{formula}."

**Feedback**

| Miss | Homer says |
| --- | --- |
| Froze, and didn't use the whispered card | "I handed you {formula}. Say it. Half your line is done." |
| No card from the hand | "Nothing from your hand. Grab a phrase. It's free." |
| Changed the card's words | "Say it the way it's written. It already fits the beat." |
| The card alone, nothing of their own | "That's all phrase and no you. Add your own half." |
| Their own half is off | "Good grab. Your half is short a hit." |

**Success:** "That's how I sang for nine hours straight. Half the line was waiting in my hand."

---

## 3. The epithet

- **id:** `epithet`
- **The move:** coin your own title, as in "___, Breaker of Horses". It goes into your hoard. In battle Homer coins you a fresh one each time, and yours is the fallback.
- **Trains:** Craft.
- **Lands when:** the title has one to three hits (two is the aim, half a line), and it is used in a line with three to five hits. The judge rates it well.
- **Unlocks:** your fallback battle name. Homer uses it when he can't coin a fresh epithet in time. It also joins your hoard, so it can be dealt into your hand. Homer offers a battle: "You have a name now. Go fight."

**Demo verse**

```
ENter oDYSseus / MASter of LIES
then MIGHTy HECtor / the WALL of TROY
SWIFT-footed aCHILles / the BANE of KINGS
and YOU, my FRIEND / WHAT do they CALL you
```

**Name the move:** "Every legend carries a title. Name what you break, or what you rule, and wear it."

**Exercise:** "Say your name and your title. Breaker of something. Keeper of something. Then put the title in a line."

**Feedback**

| Miss | Homer says |
| --- | --- |
| Four or more hits in the title | "Too heavy to carry. Cut your title to two hits." |
| No hit in the title | "No weight in that title. Breaker of what?" |
| Generic, judged weak | "Anyone could wear that. What do only you break?" |
| Title not used in the line | "You named yourself, then left it behind. Put the title in the line." |
| The line around it is off | "Strong title. The line around it needs more weight." |

**Success:** "{title}. Good. That's how my hall will know you."

---

## 4. The turn

- **id:** `turn`
- **The move:** shift the feeling mid-verse. The scene shows it.
- **Trains:** Range.
- **Lands when:** the emotion engine sees the leading emotion change between lines 1 and 2 and lines 3 and 4.
- **Unlocks:** Range, the axis the scene measures. Homer points to lesson 5.
- **Rule:** Homer never names the feeling, before or after. The scene shows the turn, and Homer only talks about where it happened.

**Demo verse.** The turn is "then", at line 3.

```
we BROKE their GATES / we BURNED their TOWers
we DRANK their WINE / till the DAWN came UP
then I SAW my BROTHer / LYing in the SAND
and the WINE turned to ASH / in the BACK of my THROAT
```

**Name the move:** "Two lines one way, two lines the other. The hinge is one word, like then, or but."

**Exercise:** "Four lines. Open on a victory. At line three, turn it."

**Feedback**

| Miss | Homer says |
| --- | --- |
| No turn | "It never turned. Same road, start to finish. Find your then." |
| Turned at line 1 or 2 | "You turned too soon. Hold your ground for two full lines." |
| Turned at line 4 | "You turned on the last line. No room to land it. Turn at three." |
| Said the feeling instead of showing it | "Don't tell me what changed. Show me what you saw." |
| The turn cost a hit | "The turn cost you the beat in line three. Keep it, even on the bend." |

**Success:** "You moved the room. That's the turn."

---

## 5. The answer

- **id:** `answer`
- **The move:** respond to a line Homer throws at you.
- **Trains:** Answer.
- **Lands when:** Answer is 7 or more, and both lines have three to five hits.
- **Unlocks:** Answer, the axis that makes a battle a conversation. Homer points to lesson 6, or to a spar.

**Demo verse.** Line 1 is the insult, and lines 2 to 4 take its image and turn it around.

```
you SAID I was a LAMP / that the RAIN would DROWN
but a LAMP in the RAIN / is a FIRE that FIGHTS
the RAIN gets TIRED / the FIRE does NOT
so BRING your STORM / I'll BRING the LIGHT
```

**Name the move:** "Take their words and turn them on them. Their image, your ending."

**Exercise:** "I'll throw you a line. Answer in two. Use my words against me." Then Homer throws one of these, a different one on each try:

```
you SPEAK like a SPARrow / LOST in a STORM
your SONG is a SHIP / with a HOLE in the HULL
you CAME to the HALL / with an EMPty HAND
```

**Feedback**

| Miss | Homer says |
| --- | --- |
| Ignored the line | "You talked past me. Grab one word I said and throw it back." |
| Agreed with it | "You just agreed with me. Flip it. Make my image work for you." |
| Denied it | "Don't deny it. Own it, then turn it." |
| Only one line | "Strong start. I asked for two. Finish it." |
| Good answer, but a hit short | "That landed. Line two lost its beat. Tighten it." |
| Answer below 7 | "Clean lines, but it barely stung. Take my sharpest word and turn it on me." |

**Success:** "That stung. Good. That's an answer."

---

## 6. The boast

- **id:** `boast`
- **The move:** land a closing line that hits.
- **Trains:** Image.
- **Lands when:** the closing line has three to five hits, ends on its heaviest word, and Image is 7 or more.
- **Unlocks:** the whole path. Homer offers a spar: "You're a bard now. Come spar with me."

**Demo verse.** Line 4 is the boast.

```
I SANG of KINGS / when your WORLD was YOUNG
I SANG of GODS / with a BLIND man's TONGUE
they BURNED the CITies / they BROKE the SWORDS
the KINGS are DUST / and I'm STILL HERE
```

**Name the move:** "The last word is the punch. Put your heaviest word there, and stop."

**Exercise:** "I'll give you three lines. You close it." Homer speaks these, then waits one rest bar:

```
you CROSSED the SEA / with a BROKen OAR
you FOUGHT the TIDE / that the GODS had SENT
and NOW you STAND / at the GATE of the HALL
```

**Feedback**

| Miss | Homer says |
| --- | --- |
| Ended on a weak word | "You ended on {last_word}. End on the word that hits hardest." |
| Kept going after the hit | "You landed it, then kept talking. Stop on the hit." |
| Hedged | "No maybe in a boast. Say it like it already happened." |
| Didn't close the setup | "Close my verse, not a new one. Pay off the gate." |
| A hit short | "The idea's there. Give it weight, and save the heaviest for last." |
| Image below 7 | "Clean, but I can't see it. Put one thing in that line I could paint." |

**Success:** "That's how you leave a stage. Nobody speaks after that."
