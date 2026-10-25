![tag:innovationlab](https://img.shields.io/badge/innovationlab-3D8BD3)
![tag:hackathon](https://img.shields.io/badge/hackathon-5F43F1)

# Homer, the bard who deals you a theme and judges your verse

**Agent:** `homer-bard`
**Address:** `agent1qf8cydj43pd7tue06mk9avnp45avcc4ss9gjm98r4lkjczsw0gskzw97edc`

Homer never wrote the Iliad down. He improvised it out loud, over a beat, from ready-made phrases called formulas ("the wine-dark sea", "rose-fingered Dawn"). Every oral tradition works this way, from Beowulf to freestyle rap. Learn the formulas and the beat, and you can improvise. This agent runs one round of that, inside a single chat.

## A round, in two steps

1. **Say "give me a theme".** (Or "theme: the last train out" for one of your own.) Homer deals you a theme and five formulas that fit the beat, from the same dealer the MeNIN game uses: half-lines, epithets and kennings, each marked with how many hits it fills.
2. **Answer with two to four lines,** one per line, using at least one of your formulas. Four hits a line and a breath in the middle, like Beowulf or a rap bar. Homer judges the verse against your theme and your hand.

```
the train pulled out on the whale-road of rails
when Dawn came early I was already gone
```

## What you get back

- **His verdict:** one line, spoken like a legend, never like a lecturer.
- **Three scores from 1 to 10, the game's battle scale, on content:**
  - Image: a picture we can see.
  - Answer: did you answer the theme.
  - Craft: did you use your formulas and bend them to the theme.
  - The total is out of 100: Image and Answer count four times, Craft twice.
- **Your best line,** and where your stresses fell, in capitals (shown, not scored).
- Sometimes a new formula you coined, for your hoard.

Say "give me a theme" again for another round.

## Behind it

Homer hosts MeNIN, built at Cal Hacks 13.0. MeNIN trains your voice the way the Greeks did: Homer teaches you to improvise poetry out loud, then you battle other poets live, debate like Socrates and play Greek games with friends, on one shared screen with phones as controllers. This agent speaks the Agent Chat Protocol and calls the same agent service the game uses:
- the dealer that builds a hand from the game's formula bank, part hand-written and part mined from public-domain Homer translations;
- the stress scanner that shows where your stresses fell;
- the judge that scores your verse on content. It runs on Claude, with a cached prompt and a streamed verdict.

It keeps each conversation's hand for an hour so your verse is judged against it, and nothing else.
