"""Offline tests: no network, no Apify account. Run from apify/: python -m pytest"""

import json
from pathlib import Path

import pytest

from src import beats, gutenberg
from src.bank import ENTRY_FIELDS, Bank, loose_key, slug, validate
from src.miner import Miner, Settings

ROOT = Path(__file__).resolve().parents[1]
BANK = ROOT.parent / "content" / "formulas.json"
OUTPUT = ROOT / "output" / "formulas.mined.json"
needs_bank = pytest.mark.skipif(not BANK.exists(), reason="content/formulas.json not next to apify/")


def book(text: str, translators=("Lang",)) -> gutenberg.Book:
    return gutenberg.Book(id="0", title="The Iliad", translators=list(translators), rights="Public domain in the USA.", text=text)


def mine(text: str, bank: Bank | None = None, **settings) -> dict[str, dict]:
    m = Miner(Settings(min_count=1, **settings))
    m.scan(book(text))
    entries, _ = m.entries(bank or Bank.empty())
    return {e["text"]: e for e in entries}


# ----- beats ---------------------------------------------------------------


@needs_bank
def test_beats_match_the_bank_for_noun_phrases():
    # The miner emits noun phrases, so its plain count must agree with every
    # bank epithet and kenning. ("child of no one" is a clause the game's
    # scanner reads with a swallowed stress; the miner never makes that shape.)
    for e in json.loads(BANK.read_text()):
        if e["kind"] != "half_line" and e["text"] != "child of no one":
            assert beats.count(e["text"]) == e["beats"], e["text"]


def test_compound_takes_one_hit():
    assert beats.count("the wine-dark sea") == 2
    assert beats.count("the earth-shaker") == 1
    assert beats.count("aegis-bearing Zeus") == 2
    assert beats.count("over the wine-dark sea") == 2
    assert beats.count("the bright-eyed goddess Athene") == 3


# ----- extraction ----------------------------------------------------------


def test_compound_epithets_and_name_folding():
    got = mine("Then aegis-bearing Jove spake. And aegis-bearing Zeus thundered. The well-greaved Achaians fled.")
    assert got["aegis-bearing Zeus"]["count"] == 2  # Butler's Jove folded into Zeus
    assert "the well-greaved Achaeans" in got  # a people keeps its article


def test_appositive_epithet_counts_for_the_name():
    got = mine("So soon as early Dawn shone forth, the rosy-fingered, they rose. Then golden-throned Dawn came.")
    assert "rosy-fingered Dawn" in got
    assert got["golden-throned Dawn"]["beats"] == 2


def test_truncated_and_plain_phrases_are_skipped():
    got = mine("The swift-footed son of Peleus ran. My dear son wept. The great hall shook.")
    assert "the swift-footed son" not in got  # really "swift-footed son of Peleus": 3 beats
    assert "dear son" not in got and "the great hall" not in got
    assert "son of Peleus" in got  # the patronymic itself is a formula


def test_genitive_titles_and_half_lines():
    got = mine("Agamemnon son of Atreus, king of men, sailed over the wine-dark sea.")
    assert {"son of Atreus", "king of men"} <= set(got)
    assert got["over the wine-dark sea"]["kind"] == "half_line"
    assert got["over the wine-dark sea"]["beats"] == 2


def test_fixed_head_override():
    got = mine("Hermes, the slayer of Argos, went.")
    assert got["slayer of Argus"]["themes"][0] == "gods"


# ----- dedupe --------------------------------------------------------------


def test_variants_of_bank_formulas_are_dropped():
    bank = Bank.from_json(
        [{"id": "swift-footed-achilles", "text": "swift-footed Achilles"}, {"id": "grey-eyed-athena", "text": "grey-eyed Athena"}],
        "test",
    )
    got = mine("Fleet-footed Achilles ran. Then bright-eyed Athene smiled. Then fleet-footed Iris flew.", bank)
    assert "fleet-footed Achilles" not in got
    assert "bright-eyed Athena" not in got
    assert "fleet-footed Iris" in got


def test_keys():
    assert slug("the gannet's bath") == "gannet-s-bath"
    assert loose_key("fleet-footed Achilleus") == loose_key("the swift-footed Achilles")


# ----- Gutenberg -----------------------------------------------------------

RDF = """<rdf:RDF><pgterms:ebook rdf:about="ebooks/1728">
<dcterms:rights>{rights}</dcterms:rights>
<marcrel:trl><pgterms:agent><pgterms:name>Butcher, S. H. (Samuel Henry)</pgterms:name></pgterms:agent></marcrel:trl>
<marcrel:trl><pgterms:agent><pgterms:name>Lang, Andrew</pgterms:name></pgterms:agent></marcrel:trl>
<dcterms:title>The Odyssey of Homer</dcterms:title></pgterms:ebook></rdf:RDF>"""


def test_rdf_and_rights_gate():
    b = gutenberg.parse_rdf("1728", RDF.format(rights="Public domain in the USA."))
    assert b.source == "Odyssey, tr. Butcher & Lang (Project Gutenberg #1728)"
    assert gutenberg.is_public_domain(b)
    assert not gutenberg.is_public_domain(gutenberg.parse_rdf("9", RDF.format(rights="Copyrighted. Read the copyright notice.")))


async def test_fetch_skips_books_that_are_not_public_domain(tmp_path):
    cache = gutenberg.DirCache(tmp_path)
    text = "header\n*** START OF THE PROJECT GUTENBERG EBOOK X ***\nbody\n*** END OF THE PROJECT GUTENBERG EBOOK X ***\n"
    await cache.set("pg1.rdf", RDF.format(rights="Public domain in the USA."))
    await cache.set("pg1.txt", text)
    await cache.set("pg2.rdf", RDF.format(rights="Copyrighted."))
    await cache.set("pg2.txt", text)
    r = await gutenberg.fetch(["1", "2"], cache, max_per_minute=1, log=None)  # all cached: no network
    assert [b.id for b in r.books] == ["1"]
    assert r.books[0].text.strip() == "body"
    assert r.skipped[0]["id"] == "2" and r.fetched == []


# ----- the output file -----------------------------------------------------


@pytest.mark.skipif(not OUTPUT.exists(), reason="run the Actor first")
def test_output_file_matches_the_bank_schema():
    entries = json.loads(OUTPUT.read_text())
    assert 40 <= len(entries) <= 150
    assert len({e["id"] for e in entries}) == len(entries)
    for e in entries:
        assert tuple(e) == ENTRY_FIELDS
        assert validate(e) == [], e
        assert "Project Gutenberg #" in e["source"]
    if BANK.exists():
        bank = Bank.from_path(BANK)
        assert not [e["text"] for e in entries if bank.duplicate_of(e["id"], e["text"])]
