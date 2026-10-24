# Content

Lesson scripts and the formula bank. The agent service and the app both read these files.

| File | What it is |
| --- | --- |
| `lessons.md` | The six Bard lesson scripts: demo verse, spoken lines, feedback, and when each lesson lands. The conventions are at the top of the file. |
| `formulas.json` | The starter formula bank: 158 entries, dealt into hands and whispered by the freeze rescue. |
| `debate.md` | The Socratic debate event: Socrates' persona, 22 questions, the five-axis rubric, the freeze rescue, the move table, and shared lines. |
| `moves.json` | 40 rhetorical-move cards for the debate hand. Same schema as `formulas.json`, with `kind: "move"`, `beats: 0`, and the move's role (`open`, `attack`, `defend`, `close`) in `themes`. See `debate.md`. |

## formulas.json

A JSON array. Each entry looks like this:

```json
{ "id": "wine-dark-sea", "text": "the wine-dark sea", "kind": "epithet", "beats": 2, "themes": ["sea", "journey"], "emotions": ["awe", "longing"] }
```

- **id:** the text in lowercase with hyphens and without a leading "the". It's stable, so lessons and hoards can refer to it.
- **kind:**
  - `epithet`: a name or title ("swift-footed Achilles", "breaker of deadlines").
  - `kenning`: a compound that names a thing by a metaphor ("the whale-road" for the sea, "the sleep-thief" for an alarm).
  - `half_line`: a phrase that fills half a line by itself ("when Dawn came early").
- **beats:** how many of the line's four hits it fills, 1 or 2. A half-line is always 2. A compound word takes one hit, on its first part (WINE-dark, WHALE-road), the same way SPEC.md counts "WINE-dark SEA".
- **themes:** one or more of `sea`, `war`, `home`, `love`, `loss`, `journey`, `night`, `dawn`, `storm`, `fire`, `gods`, `feast`, `city`, `wild`, `time`, `glory`. Map a round's theme to these tags to deal a hand.
- **emotions:** one or more of the emotion engine's eight keys: `anger`, `grief`, `joy`, `awe`, `tenderness`, `fear`, `defiance`, `longing`.

The runtime card (`FormulaCard` in `ios/Homer/Contracts.swift`: `id`, `text`, `kind`, `used`) is built from an entry, and the `kind` values match its enum. `used` is game state, so it isn't stored here.

Every phrase is original, a traditional Homeric or Old English formula, or a plain rendering of one. None is quoted from a copyrighted translation.
