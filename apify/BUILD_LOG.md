# How Epithet Miner was built

Epithet Miner was written by an AI coding agent: **Claude Opus 5.5, running in Claude Code**, on Saturday, October 24, 2026, during Cal Hacks 13.0. The team's leader session assigned the task and the agent did the work in one session: research, code, runs, tests and these docs. Matus Vecera reviews the output and deploys the Actor to Apify with his own account. The agent never logged in to Apify or pushed anything.

The brief: an Apify Actor that mines public-domain Homer translations on Project Gutenberg for noun-epithet formulas, writes them in the exact schema of MeNIN's formula bank (`content/formulas.json`), counts beats with the bank's rule, and drops anything already in the bank or not from Gutenberg. It also had to run locally without an account.

## What the agent did, in order

1. **Read the project.** SPEC.md (the four-beat line, the hand of formulas, the rule that sponsor side quests stay off the demo path), `content/README.md` (the entry schema, 16 themes, 8 emotions, the beat rule), the 158-entry bank, and the agent service's own beat counter (`homer/homer/scanner.py`).
2. **Checked Gutenberg's rules.** robots.txt disallows only `/ebooks/search`. The agent fetched the catalog records (RDF) for six candidate ebooks, once, and confirmed each says "Public domain in the USA."
3. **Chose the sources** (below) and downloaded four texts once, about 3.4 MB in all, into a cache outside the repo. Every later run read the cache.
4. **Explored the texts** before writing the extractor: it counted every hyphenated compound with the word after it in each book. That showed what the miner should look for. "aegis-bearing Zeus" occurs 60 times across two translations, "the well-greaved Achaians" 31, "many-fountained Ida" 18. It also showed that Butler uses Roman names (Jove, Minerva, Ulysses).
5. **Wrote the Actor** in Python on the Apify SDK and Crawlee (`src/`): the crawl, the lexicon, the beat counter, dedupe and ranking.
6. **Iterated on quality** by reading the ranked output and fixing what was wrong. The fixes are listed under "What went wrong along the way".
7. **Verified.** All 150 results get the same beat count from MeNIN's own scanner (`strong_hits`). There are 12 offline tests, including one that every output entry passes the bank schema with no duplicates. The fetch path was tested once on a book not downloaded before (Pope's Odyssey, #3160): RDF first, then the rights check, then the text.

## Sources, and why

| Gutenberg # | Book | Translator | Why |
| --- | --- | --- | --- |
| 3059 | Iliad (1883) | Andrew Lang, Walter Leaf, Ernest Myers | A deliberately literal prose version that keeps nearly every epithet and uses Greek names |
| 1728 | Odyssey (1879) | S. H. Butcher, Andrew Lang | Its companion, just as literal ("the grey-eyed goddess Athene", "the unharvested sea") |
| 2199 | Iliad (1898) | Samuel Butler | Plainer English for the same formulas, so a formula found in both counts twice |
| 1727 | Odyssey (1900) | Samuel Butler | The same, and the most frequent "rosy-fingered Dawn" of all four |

All four are prose. In prose an epithet stays next to its noun ("aegis-bearing Zeus"). Verse translations reorder words to fit the meter and rhyme, so Pope (6130, 3160) is supported but off by default. All six records say "Public domain in the USA.", and all the translators died between 1744 (Pope) and 1927 (Leaf).

## How the extraction works

There is no language model and no part-of-speech tagger. Every step is a rule you can read, so every result can be explained.

- **Tokens.** Each book is cut to the text between Gutenberg's START and END markers, illustrations and footnotes are removed, and the rest is split into words and punctuation.
- **Shapes.** The miner keeps six shapes: compound epithet + head, appositive ("Dawn shone forth, the rosy-fingered"), fixed adjective or title + head, agent noun ("the cloud-gatherer"), genitive title ("son of Atreus"), and preposition + epithet as a half-line ("over the wine-dark sea").
- **Heads.** Every shape needs a head the lexicon knows: 74 names in 148 spellings, and 100 kinds of thing in 451 words. That one requirement filters out most noise: "the war-cry rang" has no head, so it never becomes a candidate.
- **Folding.** Names are folded to the bank's spelling: Jove becomes Zeus, Athene becomes Athena, Achaians becomes Achaeans. Synonym compounds share one dedupe key: fleet-footed and swift-footed, rosy-fingered and rose-fingered, mail-clad and bronze-armored.
- **Beats.** CMU Pronouncing Dictionary stress (the `pronouncing` package), using the bank's rule: each content word's stressed syllable is a hit, small words are not, and a compound takes one hit, on its first part.
- **Tags.** Themes come from the head, plus a few modifier cues (cloud adds storm). Emotions come from modifier cues first ("barren" is grief, "laughter-loving" is joy), then the head. Every tag is from the bank's allowed lists, and a validator rejects any entry that isn't.
- **Ranking.** Score is log2(count) × spread across translations × fame of the head × shape (compound epithets weigh most). Caps keep the bank varied: at most 4 formulas per head, 6 patronymics, and 15 half-lines (never more than a fifth of the list).

## Results of the default run

- 4 books, 3.18 million characters, 1,375 distinct candidate phrases.
- Dropped as bank duplicates: 10 exact ("the wine-dark sea", "cloud-gathering Zeus") and 7 variants ("fleet-footed Achilles" for "swift-footed Achilles", "rosy-fingered Dawn" for "rose-fingered Dawn", "man-slaying Hector" for "man-killing Hector").
- Dropped as too rare: 733 (fewer than 2 occurrences, or 4 for a plain adjective like "great").
- Kept: 150 (136 epithets, 14 half-lines). 113 occur in two or more translations, and 115 occur five times or more.

## What went wrong along the way

The first ranked list was full of pairs like "dear son", "great wealth" and "the young men": common English, not formulas. The agent restricted plain adjectives before a common noun to the ones Homer fixes to things (hollow ships, salt sea, sweet sleep). It also dropped kinship heads.

Some compounds were truncated longer formulas. "grey-eyed daughter" is really "grey-eyed daughter of Zeus", which is three beats. A compound before a kinship word followed by "of" is now skipped.

Raw counts let "son of Atreus" (283 occurrences) bury "many-fountained Ida" (18). The ranking now uses log2(count) and weights compound epithets above other shapes.

A synonym fold of "dark" into "black" produced "into the black sea", which reads as the place, so it was removed.

A few emotion cues fired on the wrong compound. "white-tusked boars" came out tender because of "white-armed". Whole-compound cues are now checked before the parts.

## Known limits

- The lexicon sets the reach. Formulas about minor characters it doesn't list are not found.
- Tags are heuristics for a human editor, and the merge into `content/` is a human step (`scripts/merge_into_bank.py` is a dry run unless given `--write`).
- The Actor runs at build time. The game never calls Apify, which is what SPEC.md requires of a sponsor side quest.
