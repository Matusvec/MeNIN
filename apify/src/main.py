"""Epithet Miner: the Actor's entry point.

Runs the same way on the Apify platform and on a laptop:

    on Apify   input from the Console or API; formulas go to the default
               dataset and to the record `formulas.mined.json`; the
               Gutenberg cache is a named key-value store.
    locally    `python -m src` with no account; the same, plus the file
               output/formulas.mined.json, deduped against ../content/formulas.json.
"""

from __future__ import annotations

import argparse
import asyncio
import json
import os
import re
import urllib.request
from pathlib import Path
from typing import Any

from apify import Actor

from . import gutenberg
from .bank import Bank
from .miner import Miner, Settings

ROOT = Path(__file__).resolve().parents[1]  # apify/
LOCAL_BANK = ROOT.parent / "content" / "formulas.json"
LOCAL_OUT = ROOT / "output" / "formulas.mined.json"
LOCAL_CACHE = ROOT / "storage" / "pg-cache"
CACHE_STORE = "epithet-miner-pg-cache"
OUTPUT_KEY = "formulas.mined.json"

# Lang, Leaf & Myers's Iliad, Butcher & Lang's Odyssey, Butler's Iliad and Odyssey.
DEFAULT_IDS = ["3059", "1728", "2199", "1727"]


def parse_cli(argv: list[str]) -> argparse.Namespace:
    p = argparse.ArgumentParser(prog="python -m src", description="Mine Homeric formulas from Project Gutenberg.")
    p.add_argument("--ids", nargs="+", help="Gutenberg ebook ids (default: 3059 1728 2199 1727)")
    p.add_argument("--min-count", type=int, help="occurrences a formula needs (default 2)")
    p.add_argument("--max-formulas", type=int, help="cap on the output (default 150)")
    p.add_argument("--bank", type=Path, help=f"existing bank to dedupe against (default {LOCAL_BANK})")
    p.add_argument("--out", type=Path, help=f"output file (default {LOCAL_OUT})")
    p.add_argument("--cache-dir", type=Path, help="where downloaded books are kept (default storage/pg-cache)")
    p.add_argument("--no-half-lines", action="store_true", help="mine epithets only")
    args, _ = p.parse_known_args(argv)
    return args


def _ids(values: list[Any]) -> list[str]:
    """ "3059", 3059 or "https://www.gutenberg.org/ebooks/3059" -> "3059"."""
    out = []
    for v in values:
        m = re.search(r"(\d+)\D*$", str(v).strip())
        if m and m.group(1) not in out:
            out.append(m.group(1))
    return out


def _fetch_json(url: str) -> Any:
    req = urllib.request.Request(url, headers={"User-Agent": gutenberg.USER_AGENT, "Accept": "application/json"})
    with urllib.request.urlopen(req, timeout=30) as r:  # noqa: S310 (the user supplies the URL)
        return json.loads(r.read().decode("utf-8"))


async def _bank(inp: dict[str, Any], cli: argparse.Namespace) -> Bank:
    if cli.bank:
        return Bank.from_path(cli.bank)
    if isinstance(inp.get("existingBank"), list) and inp["existingBank"]:
        return Bank.from_json(inp["existingBank"], "input: existingBank")
    if url := (inp.get("existingBankUrl") or "").strip():
        return Bank.from_json(await asyncio.to_thread(_fetch_json, url), url)
    if LOCAL_BANK.exists():
        return Bank.from_path(LOCAL_BANK)
    return Bank.empty()


def _write_local(path: Path, entries: list[dict[str, Any]]) -> None:
    """One entry per line, like content/formulas.json."""
    path.parent.mkdir(parents=True, exist_ok=True)
    lines = ",\n".join("  " + json.dumps(e, ensure_ascii=False) for e in entries)
    path.write_text("[\n" + lines + "\n]\n", encoding="utf-8")


async def main(argv: list[str] | None = None) -> None:
    cli = parse_cli(argv or [])
    async with Actor:
        inp: dict[str, Any] = await Actor.get_input() or {}
        at_home = Actor.is_at_home()

        ids = _ids(cli.ids or inp.get("gutenbergIds") or DEFAULT_IDS)
        settings = Settings(
            min_count=cli.min_count or int(inp.get("minCount", 2)),
            max_formulas=cli.max_formulas or int(inp.get("maxFormulas", 150)),
            max_per_head=int(inp.get("maxPerHead", 4)),
            include_half_lines=not cli.no_half_lines and bool(inp.get("includeHalfLines", True)),
            modernize_names=bool(inp.get("modernizeNames", True)),
        )

        if not inp.get("useCache", True):
            cache: gutenberg.Cache = gutenberg.NoCache()
        elif at_home:
            cache = gutenberg.StoreCache(await Actor.open_key_value_store(name=CACHE_STORE))
        else:
            cache_dir = cli.cache_dir or Path(os.environ.get("EPITHET_MINER_CACHE_DIR") or LOCAL_CACHE)
            cache = gutenberg.DirCache(cache_dir)

        await Actor.set_status_message(f"Reading {len(ids)} book(s) from Project Gutenberg")
        fetched = await gutenberg.fetch(
            ids, cache, max_per_minute=int(inp.get("maxRequestsPerMinute", 10)), log=Actor.log
        )
        for s in fetched.skipped:
            Actor.log.warning(f"Skipped Gutenberg #{s['id']}: {s['reason']}")
        if not fetched.books:
            await Actor.fail(status_message="No public-domain Project Gutenberg book to mine")
            return

        bank = await _bank(inp, cli)
        if not bank.entries:
            Actor.log.warning("No existing bank given: candidates are not deduped against content/formulas.json")

        await Actor.set_status_message(f"Mining {len(fetched.books)} book(s)")
        miner = Miner(settings)
        for book in fetched.books:
            miner.scan(book)
            Actor.log.info(f"Mined {book.source}")
        entries, report = miner.entries(bank)

        report = {
            "sources": [
                {"id": b.id, "title": b.title, "translators": b.translators, "rights": b.rights,
                 "source": b.source, "chars": len(b.text)}
                for b in fetched.books
            ],
            "skipped": fetched.skipped,
            "fetched": fetched.fetched,
            "cache_hits": fetched.cached,
            "bank": {"origin": bank.origin, "entries": len(bank.entries)},
            "settings": settings.__dict__,
            "by_kind": {k: sum(1 for e in entries if e["kind"] == k) for k in ("epithet", "kenning", "half_line")},
            **report,
        }

        await Actor.push_data(miner.dataset_items())
        await Actor.set_value(OUTPUT_KEY, entries)
        await Actor.set_value("REPORT", report)
        if not at_home:
            out = cli.out or LOCAL_OUT
            _write_local(out, entries)
            Actor.log.info(f"Wrote {len(entries)} formulas to {out}")

        msg = f"{len(entries)} formulas from {len(fetched.books)} book(s); {report['candidates_seen']} candidates seen"
        Actor.log.info(msg)
        await Actor.set_status_message(msg)
