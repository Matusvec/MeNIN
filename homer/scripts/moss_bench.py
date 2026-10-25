"""Moss dealer bench on the current formula bank: the index load, then p50/p95 for a ranked lookup and
for a whole deal (lookup + building the hand), and a hand per demo theme from the tag dealer next to Moss.

Needs MOSS_PROJECT_ID and MOSS_PROJECT_KEY (homer/.env). Moss calls only, no Claude.

    .venv/bin/python scripts/moss_bench.py --n 40 | tee bench/moss-2026-10-24.txt
"""

from __future__ import annotations

import argparse
import asyncio
import os
import random
import sys
import time
from pathlib import Path

os.environ.setdefault("HOMER_DEALER", "moss")
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from homer import formulas, moss_dealer  # noqa: E402
from homer.config import load_env  # noqa: E402
from homer.deal import DEFAULT_THEMES, deal, themes  # noqa: E402


def pct(xs: list[float], p: float) -> float:
    xs = sorted(xs)
    return round(xs[min(len(xs) - 1, int(round(p / 100 * (len(xs) - 1))))], 2) if xs else float("nan")


async def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--n", type=int, default=40)
    args = ap.parse_args()
    load_env()
    d = moss_dealer.dealer()
    if d is None:
        sys.exit("Moss is off: set HOMER_DEALER=moss, MOSS_PROJECT_ID and MOSS_PROJECT_KEY")
    t0 = time.perf_counter()
    await d.start()
    load_ms = (time.perf_counter() - t0) * 1000
    if not d.ready:
        sys.exit("Moss didn't load the index")
    print(f"bank: {len(formulas.bank())} formulas, index {moss_dealer.index_name()}, loaded in {load_ms:.0f} ms")

    pool = list(themes())
    lookups, deals = [], []
    for i in range(args.n):
        theme = pool[i % len(pool)]
        t = time.perf_counter()
        await d.ranked(theme)
        lookups.append((time.perf_counter() - t) * 1000)
        t = time.perf_counter()
        deal(theme, n=5, rng=random.Random(i), ranked=await d.ranked(theme))
        deals.append((time.perf_counter() - t) * 1000)
    print(f"\n{args.n} runs over {len(pool)} themes")
    print(f"ranked lookup  p50 {pct(lookups, 50)} ms  p95 {pct(lookups, 95)} ms  max {round(max(lookups), 2)} ms")
    print(f"whole deal     p50 {pct(deals, 50)} ms  p95 {pct(deals, 95)} ms  max {round(max(deals), 2)} ms")

    print("\nThe demo themes, one hand each (same seed): the tag dealer, then Moss")
    for theme in DEFAULT_THEMES[:3]:
        tags = [c.text for c in deal(theme, n=5, rng=random.Random(7))]
        moss = [c.text for c in deal(theme, n=5, rng=random.Random(7), ranked=await d.ranked(theme))]
        print(f"\n{theme}\n  tags: {' | '.join(tags)}\n  moss: {' | '.join(moss)}")


if __name__ == "__main__":
    asyncio.run(main())
