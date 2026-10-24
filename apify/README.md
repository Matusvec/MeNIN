# Epithet Miner

**Mine Homer's formulas out of public-domain translations.** Epithet Miner crawls the Iliad and the Odyssey on Project Gutenberg and pulls out the noun-epithet formulas the oral poets improvised with: *aegis-bearing Zeus*, *laughter-loving Aphrodite*, *the wine-dark deep*, *the horse-taming Trojans*, *over the wine-dark sea*. Each formula comes out tagged with how many beats it fills in a four-beat line (from the CMU Pronouncing Dictionary), themes, emotions, the translations it appears in, and how often it occurs.

It was built to fill the formula bank of [MeNIN](#how-it-feeds-menin), a game that teaches you to improvise poetry out loud the way Homer did, but the output is plain JSON for any project that wants a curated, scansion-tagged phrasebook of Homeric English.

## Why formulas

Homer never memorized the Iliad. He improvised it from ready-made phrases that fit the beat, and he used them again and again: "rosy-fingered Dawn" alone appears more than twenty times. The English translators kept them. So a formula can be found the way a philologist finds one: it is a fixed shape that recurs. Epithet Miner counts every occurrence across several translations and keeps the shapes that recur.

## What it does

1. **Crawls Project Gutenberg** with Crawlee, one request at a time. For each ebook it reads the catalog record first and continues only if the record says **"Public domain in the USA."** Books that aren't are skipped and reported.
2. **Cuts each book to its text**, between Gutenberg's START and END markers, so license boilerplate is never mined.
3. **Finds six formula shapes**, each anchored on a name or noun from a hand-written lexicon of Homer's world (74 names in 148 spellings, 100 kinds of thing in 451 words):

   | Shape | Example |
   | --- | --- |
   | compound epithet + head | aegis-bearing Zeus, the well-greaved Achaeans |
   | appositive ("Dawn shone forth, the rosy-fingered") | counted toward rosy-fingered Dawn |
   | fixed adjective or title + head | goodly Odysseus, the salt sea, father Zeus, Pallas Athena |
   | agent noun | the cloud-gatherer |
   | genitive title | son of Atreus, king of men, the house of Hades |
   | half-line (preposition + epithet) | over the wine-dark sea |

4. **Folds names to the familiar Greek forms**, so Butler's *Jove* and *Minerva* and Lang's *Athene*, *Achaians* and *Aias* all count as *Zeus*, *Athena*, *Achaeans* and *Ajax*.
5. **Counts beats** with the CMU Pronouncing Dictionary: every content word's stressed syllable is a hit, and a compound takes one hit, on its first part (WINE-dark, AEGIS-bearing). Only formulas that fill 1 or 2 of a line's 4 hits are kept.
6. **Drops duplicates** of an existing bank you pass in, including variants: *fleet-footed Achilles* is a duplicate of *swift-footed Achilles*, and *rosy-fingered Dawn* of *rose-fingered Dawn*.
7. **Ranks** by how often a formula recurs, how many translations share it, how well known its head is, and its shape (compound epithets first). It caps formulas per head, so the bank isn't twenty epithets of Zeus.

Everything is deterministic: no language model, no API keys.

## Input

Every field is optional. An empty input mines four prose translations.

| Field | Default | What it does |
| --- | --- | --- |
| `gutenbergIds` | `3059, 1728, 2199, 1727` | Ebook IDs or URLs. 3059 Iliad (Lang, Leaf & Myers), 1728 Odyssey (Butcher & Lang), 2199 Iliad and 1727 Odyssey (Samuel Butler). 6130 and 3160 are Pope's verse Iliad and Odyssey. |
| `maxFormulas` | 150 | The most formulas to output, best first. At most 15 of them, and never more than a fifth, are half-lines. |
| `minCount` | 2 | Occurrences a formula needs across all books. Plain adjectives ("great", "old") need twice this. |
| `maxPerHead` | 4 | At most this many formulas for one name or noun. |
| `includeHalfLines` | true | Also mine half-lines such as "over the wine-dark sea". |
| `modernizeNames` | true | Familiar Greek names (Zeus, Athena) instead of each translator's spelling. |
| `existingBankUrl` | | A JSON formula bank to dedupe against. |
| `existingBank` | | The same, pasted as a JSON array. |
| `maxRequestsPerMinute` | 10 | Politeness cap for gutenberg.org. |
| `useCache` | true | Keep downloaded books in the named key-value store `epithet-miner-pg-cache`. |

Example:

```json
{ "gutenbergIds": ["3059", "1728"], "maxFormulas": 80, "minCount": 3 }
```

## Output

- **Dataset**: one item per formula, best first. The *Formulas* view shows each one in context.
- **Key-value store, `formulas.mined.json`**: the whole list as a JSON array in the formula-bank schema, ready to merge.
- **Key-value store, `REPORT`**: sources used, books skipped and why, files fetched, and how many candidates were dropped at each step (rare, too long, bank duplicate, caps).

A dataset item:

```json
{
  "id": "aegis-bearing-zeus",
  "text": "aegis-bearing Zeus",
  "kind": "epithet",
  "beats": 2,
  "themes": ["gods", "storm"],
  "emotions": ["awe", "fear"],
  "source": "Iliad, tr. Lang, Leaf & Myers (Project Gutenberg #3059); Iliad, tr. Butler (Project Gutenberg #2199)",
  "count": 60,
  "pattern": "compound",
  "example": "… come hither, thou daughter of aegis-bearing Zeus? Is it to behold the …"
}
```

| Field | Meaning |
| --- | --- |
| `id` | The text in lowercase with hyphens, without a leading "the" |
| `text` | The formula as a player says it |
| `kind` | `epithet` (a name or title) or `half_line` (fills half a line by itself) |
| `beats` | Hits of a four-beat line it fills, 1 or 2 |
| `themes` | 1 to 3 of: sea, war, home, love, loss, journey, night, dawn, storm, fire, gods, feast, city, wild, time, glory |
| `emotions` | 1 or 2 of: anger, grief, joy, awe, tenderness, fear, defiance, longing |
| `source` | Each translation it occurs in, most occurrences first |
| `count` | Occurrences across all books |
| `pattern`, `example` | Review aids, in the dataset only |

Themes come from the head (Zeus is *gods* and *storm*; ships are *sea* and *journey*) plus a few modifier cues. Emotions come from the modifiers first ("barren" is grief, "laughter-loving" is joy), then the head. They are a starting point for a human editor, not a judgment.

## Run it locally (no Apify account)

The Actor runs on a laptop with the Apify SDK's local storage. Python 3.11 or newer.

```bash
cd apify
python3 -m venv .venv && . .venv/bin/activate
pip install -r requirements-dev.txt
python -m src                     # writes output/formulas.mined.json
python -m pytest                  # offline tests
```

The first run downloads the four books (about 3.4 MB) into `storage/pg-cache/`; later runs reuse them and touch the network not at all. Locally the Actor also dedupes against `../content/formulas.json` and writes `output/formulas.mined.json`, one entry per line like the bank.

Options for local runs: `python -m src --ids 3059 1728 --min-count 3 --max-formulas 80 --bank path/to/bank.json --out path/to/out.json --cache-dir path/to/cache --no-half-lines`. `apify run` from the Apify CLI works too and needs no login.

## How it feeds MeNIN

MeNIN deals each player a hand of formulas from `content/formulas.json`; the freeze rescue whispers one when a player goes silent. Epithet Miner is how that bank grows past what the team wrote by hand:

1. Run the Actor (locally or on Apify). It writes `output/formulas.mined.json`, already deduped against the current bank and in its schema, plus `source` and `count`.
2. Whoever owns `content/` reviews the candidates and merges the ones they want:

   ```bash
   python scripts/merge_into_bank.py --min-count 5            # dry run: prints what it would add
   python scripts/merge_into_bank.py --skip son-of-atreus --write
   ```

   Merged entries keep only the bank fields unless `--keep-provenance` is given. The agent service's loader reads only those fields anyway.
3. The game deals from the bigger bank. Nothing in the game calls Apify: the Actor runs at build time, and the demo works without it.

## Sources and licensing

The Actor mines only books whose Project Gutenberg record says "Public domain in the USA." The four defaults are 19th-century prose translations: Lang, Leaf & Myers (1883), Butcher & Lang (1879), and Samuel Butler (1898, 1900). Formulas are short phrases, and each entry names the translation it came from. Gutenberg's robots.txt disallows only `/ebooks/search`, which the Actor never requests. It sends a descriptive User-Agent, makes one request at a time, and caches every book, so a run downloads each file at most once. Outside the USA, check your local copyright terms before reusing the texts.

## Limits

- The lexicon decides what counts as a head. A formula about a name or noun that isn't in it (most minor characters) is not found.
- Tags are heuristic. Review them before they reach players.
- Names are modernized on purpose (Jove becomes Zeus). Turn `modernizeNames` off to keep each translator's spelling.
- Beat counts use the plain stress rule. All 150 default results match MeNIN's own scanner.

## Deploy to Apify (Matus's steps)

Nothing below has been run yet. It needs your Apify account and token.

1. Sign in at [console.apify.com](https://console.apify.com) and redeem the coupon `APIFY_CAL_HACKS` on the account.
2. Install the CLI: `npm install -g apify-cli` (or `brew install apify-cli`).
3. Log in from this folder: `cd apify && apify login` (paste the API token from Console → Settings → API & Integrations).
4. Push and build: `apify push`. It builds the image from `.actor/Dockerfile` and creates the Actor `epithet-miner` under your account.
5. Run it once on the platform: Console → My Actors → epithet-miner → Start with the default input. The repo is private, so to dedupe against MeNIN's bank, paste `content/formulas.json` into *Existing bank (JSON)*. Check the *Formulas* view of the dataset and the `formulas.mined.json` record.
6. Publish: Console → My Actors → epithet-miner → **Publishing** tab → fill in the display information (this README is the Store page) → **Publish on Store**.

`.actor/actor.json` already sets `"meta": {"templateId": "ai-generated-actor", "generatedBy": "Claude Opus 5.5 (Claude Code)"}`, Apify's marker for an Actor built with AI. How it was built is in [BUILD_LOG.md](BUILD_LOG.md).
