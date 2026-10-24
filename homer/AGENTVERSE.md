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
- **Five scores from 1 to 10:**
  - Beat, counted by a deterministic stress scanner over the CMU Pronouncing Dictionary, not by the model.
  - Craft: did you use your formulas and bend them to the theme.
  - Image.
  - Answer: did you answer the theme.
  - Range.
- **Your best line,** and where your hits fell, in capitals.
- Sometimes a new formula you coined, for your hoard.

Say "give me a theme" again for another round.

## Behind it

Homer hosts MeNIN, a party game of ancient Greek contests (poetry battles, Socratic debate, discus) on one shared screen with phones as controllers, built at Cal Hacks 13.0. This agent speaks the Agent Chat Protocol and calls the same agent service the game uses:
- the dealer that builds a hand from a 158-formula bank;
- the stress scanner that scores the Beat;
- the judge that scores the rest. It runs on Claude, with a cached prompt and a streamed verdict.

It keeps each conversation's hand for an hour so your verse is judged against it, and nothing else.
