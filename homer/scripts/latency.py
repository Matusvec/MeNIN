"""Live latency of the turn judge: request in to verdict text out.

Costs real money: each call is roughly half a cent on Opus 5.5. Keep runs small.

    .venv/bin/python scripts/latency.py                     # 20 calls, the configured judge
    .venv/bin/python scripts/latency.py --n 10 \\
        --configs claude-opus-5-5:low claude-opus-5-5:low:fast claude-haiku-5-5:low claude-sonnet-5-5:low

A config is model:effort[:fast]. Each config gets one unmeasured warm-up call
first, so the measured calls read the cached system prompt, as they would in
a live battle. Calls run one at a time, like turns.
"""

from __future__ import annotations

import argparse
import asyncio
import dataclasses
import json
import statistics
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from homer.config import settings  # noqa: E402
from homer.judge import Judge, Turn  # noqa: E402

THEMES = ["A ship that never came home", "The last train out", "A city that never sleeps", "The forge", "Deadline night"]
VERSES = [
    "the wine dark sea took my brother's ship\nhe sailed at dawn and never came back\nI stand on the shore with the salt in my teeth\nthe whale road keeps what the whale road takes",
    "the night was long and the screen was bright\nthe coffee went cold by the second hour\nthe code compiled when the sun came up\nbreaker of deadlines rose from the chair",
    "the train pulled out and I missed my stop\nmy bag on the rack and my heart on the floor\nthe city went by like a dream in the rain\nI'll ride this line till the end of the world",
    "iron on iron the hammer comes down\nthe sparks fly up like a swarm of bees\nmy father's hands on my father's tongs\nI beat the blade till the blade beats back",
    "the street moon rose over sirens and smoke\nthe crowd sea moved with a heartbeat of bass\nnobody sleeps when the city is young\nI stand on the roof and I call down the dawn",
    "rose fingered dawn came early today\nshe found me awake with a pen in my hand\ngrey eyed Athena don't leave me now\nthe words are a wall and the wall is a wave",
]
PREVIOUS = ["", "the sea took everything I ever loved", "you call that a storm, I call it a breeze", ""]


def turns(n: int) -> list[Turn]:
    return [
        Turn(
            transcript=VERSES[i % len(VERSES)],
            mode="battle" if i % 2 else "practice",
            theme=THEMES[i % len(THEMES)],
            hand=["the whale-road", "rose-fingered Dawn", "grey-eyed Athena", "the wine-dark sea", "the street-moon"],
            played=["the whale-road"],
            rescues=int(i % 3 == 0),
            previous=PREVIOUS[i % len(PREVIOUS)],
            lines_expected=4,
        )
        for i in range(n)
    ]


def pct(xs: list[float], p: float) -> float:
    xs = sorted(xs)
    return round(xs[min(len(xs) - 1, int(round(p / 100 * (len(xs) - 1))))]) if xs else float("nan")


async def run_config(spec: str, n: int) -> dict:
    model, effort, *rest = spec.split(":")
    cfg = dataclasses.replace(settings(), judge_model=model, judge_effort=effort, judge_speed="fast" if "fast" in rest else "")
    judge = Judge(cfg=cfg)
    await judge.judge(turns(1)[0])  # warm the cache; not measured
    rows = []
    for t in turns(n):
        j = await judge.judge(t)
        rows.append(j)
        print(
            f"  {spec:28} verdict {j.timing.get('verdict', float('nan')):7.0f} ms  done {j.timing['done']:7.0f} ms  "
            f"cache_read {j.usage.get('cache_read_input_tokens', 0):5}  out {j.usage.get('output_tokens', 0):4}  "
            f"{'SILENT ' + j.error if j.silent else j.verdict}",
            flush=True,
        )
    ok = [j for j in rows if not j.silent and not j.declined]
    verdict = [j.timing["verdict"] for j in ok if "verdict" in j.timing]
    done = [j.timing["done"] for j in ok]
    first = [j.timing["first_token"] for j in ok if "first_token" in j.timing]
    return {
        "config": spec,
        "n": n,
        "ok": len(ok),
        "silent": sum(j.silent for j in rows),
        "first_token_p50": pct(first, 50),
        "verdict_p50": pct(verdict, 50),
        "verdict_p95": pct(verdict, 95),
        "done_p50": pct(done, 50),
        "done_p95": pct(done, 95),
        "output_tokens_mean": round(statistics.mean(j.usage.get("output_tokens", 0) for j in ok)) if ok else 0,
        "cache_hits": sum(1 for j in ok if j.usage.get("cache_read_input_tokens")),
    }


async def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--n", type=int, default=20)
    ap.add_argument("--configs", nargs="*", default=[f"{settings().judge_model}:{settings().judge_effort}"])
    ap.add_argument("--out", type=Path)
    args = ap.parse_args()
    results = []
    for spec in args.configs:
        print(spec, flush=True)
        results.append(await run_config(spec, args.n))
    print("\nconfig                        ok  verdict p50  p95   done p50  p95   first p50  out  cached")
    for r in results:
        print(
            f"{r['config']:28} {r['ok']:3}/{r['n']:<3} {r['verdict_p50']:6}  {r['verdict_p95']:6}  {r['done_p50']:6}  "
            f"{r['done_p95']:6}  {r['first_token_p50']:6}  {r['output_tokens_mean']:4}  {r['cache_hits']}"
        )
    if args.out:
        args.out.write_text(json.dumps(results, indent=2))


if __name__ == "__main__":
    asyncio.run(main())
