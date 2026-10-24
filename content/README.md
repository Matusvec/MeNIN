# Content

Lesson scripts and the formula bank. The agent service and the app both read these files.

| File | What it is |
| --- | --- |
| `lessons.md` | The six Bard lesson scripts: demo verse, spoken lines, feedback, and when each lesson lands. The conventions are at the top of the file. |
| `formulas.json` | The formula bank: 216 entries, dealt into hands and whispered by the freeze rescue. 161 were written by hand, and 55 were mined from public-domain Homer translations (see "Mined entries" below). |
| `debate.md` | The Socratic debate event: Socrates' persona, 22 questions, the five-axis rubric, the freeze rescue, the move table, and shared lines. |
| `moves.json` | 40 rhetorical-move cards for the debate hand. Same schema as `formulas.json`, with `kind: "move"`, `beats: 0`, and empty `themes`, plus a `role` field. See `moves.json` below. |

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
- **source** and **count** (mined entries only): which translations the phrase was found in, and how many times it appears across them. The service and the dealer ignore both.

The runtime card (`FormulaCard` in `ios/Homer/Contracts.swift`: `id`, `text`, `kind`, `used`) is built from an entry, and the `kind` values match its enum. `used` is game state, so it isn't stored here.

Every phrase is original, a traditional Homeric or Old English formula, or a plain rendering of one. None is quoted from a copyrighted translation.

### Mined entries

The last 55 entries come from the Epithet Miner, our Apify Actor (`apify/`). It read four public-domain translations on Project Gutenberg: the Iliad by Lang, Leaf and Myers (#3059) and by Butler (#2199), and the Odyssey by Butcher and Lang (#1728) and by Butler (#1727). It found 150 candidates, gave each a beat count from the game's scanner, and dropped any already in the bank.

We kept 55 of the 150 and fixed their themes and emotions by hand, because the miner tags them from word lists. We dropped:

- near-duplicates of entries already here, like "king of men" next to "lord of men", and extra epithets for the same hero
- names and words a player wouldn't know, like "son of Atreus", "the well-greaved Achaeans" and "unharvested"
- phrases that read badly today, like "the ox-eyed queen" and "goodly Odysseus"
- gore and plague, like "the black blood" and "black death"

To add more, review `apify/output/formulas.mined.json`, then run `python scripts/merge_into_bank.py --keep-provenance` from `apify/` (dry run first, then `--write`), and then `.venv/bin/python -m pytest tests/test_content.py -q` from `homer/`. That test checks every entry's fields, tags and beat count.

## moves.json

A JSON array in the same shape as `formulas.json`, plus a `role` field:

```json
{ "id": "stake-your-claim", "text": "stake your claim", "kind": "move", "role": "open", "beats": 0, "themes": [], "emotions": ["defiance"] }
```

- **kind:** always `move`. It's in the `FormulaCard.Kind` enum.
- **role:** one of `open`, `attack`, `defend`, `close`. A dealt hand has at least one of each.
- **beats:** always `0`, since debate has no beat.
- **themes:** topics, using the same idea as the formula bank. Empty for now, because every move fits every question.
- **emotions:** the same eight keys as the formula bank.

Every move's id appears in the move table in `debate.md`, along with the question Socrates whispers when it's the rescue.
