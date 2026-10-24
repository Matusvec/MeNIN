"""Go or no-go before each judge at the table: is the agent service up, warm and fast?

    python3 scripts/demo_check.py https://api.<domain>      # or http://127.0.0.1:8000 (the default)

Standard library only, so it runs on any laptop with Python 3.9+ (the Mac's own python3 works). It makes
one real judge call (Practice mode, so nothing is written to SpacetimeDB) and
mints one voice token. Exit code 0 means go.
"""

from __future__ import annotations

import json
import sys
import time
import urllib.error
import urllib.request

VERDICT_TARGET_S = 2.5
VERSE = "the wine dark sea took my brother's ship\nI stand on the shore with salt in my teeth"

results: list[tuple[str, str, str]] = []  # (PASS | WARN | FAIL, check, detail)


def note(level: str, check: str, detail: str) -> None:
    results.append((level, check, detail))
    print(f"{level:4}  {check:14} {detail}", flush=True)


def request(base: str, path: str, body: dict | None = None, accept: str = "application/json", timeout: float = 20):
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(
        base + path, data=data, headers={"Content-Type": "application/json", "Accept": accept}, method="POST" if body is not None else "GET"
    )
    return urllib.request.urlopen(req, timeout=timeout)


def get_json(base: str, path: str, body: dict | None = None) -> tuple[int, dict]:
    try:
        with request(base, path, body) as res:
            return res.status, json.loads(res.read() or b"{}")
    except urllib.error.HTTPError as exc:
        try:
            return exc.code, json.loads(exc.read() or b"{}")
        except ValueError:
            return exc.code, {}


def check_health(base: str) -> bool:
    t0 = time.perf_counter()
    try:
        status, h = get_json(base, "/health")
    except (urllib.error.URLError, OSError) as exc:
        note("FAIL", "health", f"can't reach {base}: {exc}")
        return False
    ms = (time.perf_counter() - t0) * 1000
    if status != 200 or not h.get("ok"):
        note("FAIL", "health", f"HTTP {status}")
        return False
    note("PASS", "health", f"{ms:.0f} ms, judge {h.get('judgeModel')} {h.get('judgeEffort')} {h.get('judgeSpeed')}")
    if h.get("judge") == "warm":
        note("PASS", "judge cache", "warm")
    else:
        note("WARN", "judge cache", f"{h.get('judge')}: the first turn may be slow; wait for warm")
    if h.get("stdb") == "claimed":
        note("PASS", "spacetimedb", f"claimed on {h.get('stdbDb')}")
    else:
        note("WARN", "spacetimedb", f"{h.get('stdb')} ({h.get('stdbDb')}): battles can't be written")
    return True


def check_judge(base: str) -> bool:
    """One verse through /judge as server-sent events: time to the verdict, then to the scores."""
    body = {"transcript": VERSE, "mode": "practice", "theme": "A ship that never came home", "linesExpected": 2,
            "hand": ["the wine-dark sea", "the whale-road"]}
    t0 = time.perf_counter()
    verdict_s = None
    card = None
    try:
        with request(base, "/judge", body, accept="text/event-stream", timeout=20) as res:
            event = None
            for raw in res:
                line = raw.decode().rstrip("\n")
                if line.startswith("event: "):
                    event = line[7:]
                elif line.startswith("data: "):
                    data = json.loads(line[6:])
                    if event == "verdict" and verdict_s is None:
                        verdict_s = time.perf_counter() - t0
                    elif event == "scorecard":
                        card = data
                        break
                    elif event == "error":
                        note("FAIL", "judge", f"error: {data.get('detail')}")
                        return False
    except (urllib.error.URLError, OSError) as exc:
        note("FAIL", "judge", f"request failed: {exc}")
        return False
    done_s = time.perf_counter() - t0
    if card is None:
        note("FAIL", "judge", "no scorecard")
        return False
    if card.get("silent"):
        note("FAIL", "judge", f"Homer was silent (Claude didn't answer) after {done_s:.1f} s")
        return False
    level = "PASS" if verdict_s is not None and verdict_s <= VERDICT_TARGET_S else "WARN"
    shown = f"{verdict_s:.2f} s" if verdict_s is not None else "never streamed"
    note(level, "judge", f"verdict in {shown}, scores in {done_s:.2f} s (target {VERDICT_TARGET_S} s)")
    note("PASS", "verdict", f"\"{card.get('verdict')}\"  {card.get('scores')}")
    return True


def check_quick(base: str) -> None:
    status, t = get_json(base, "/themes?n=3&demo=true")
    note("PASS" if status == 200 and len(t.get("themes", [])) == 3 else "FAIL", "themes", "; ".join(t.get("themes", [])) or f"HTTP {status}")
    status, r = get_json(base, "/rescue", {"transcript": "", "hand": ["when Dawn came early", "the whale-road"]})
    note("PASS" if status == 200 and r.get("formula") else "FAIL", "rescue", r.get("formula") or f"HTTP {status}")
    status, v = get_json(base, "/voice/token", {"role": "solo"})
    if status == 200 and v.get("token"):
        voice = (v.get("tts") or {}).get("voiceId") or "NO VOICE ID"
        note("PASS" if voice != "NO VOICE ID" else "WARN", "voice token", f"stt {v.get('stt', {}).get('model')}, tts voice {voice}")
    else:
        note("FAIL", "voice token", f"HTTP {status}: {v.get('detail', '')}")


def main() -> int:
    base = (sys.argv[1] if len(sys.argv) > 1 else "http://127.0.0.1:8000").rstrip("/")
    print(f"Checking {base}\n")
    if check_health(base):
        check_judge(base)
        check_quick(base)
    fails = [r for r in results if r[0] == "FAIL"]
    warns = [r for r in results if r[0] == "WARN"]
    print(f"\n{'NO-GO' if fails else 'GO'}: {len(fails)} failed, {len(warns)} warnings")
    return 1 if fails else 0


if __name__ == "__main__":
    sys.exit(main())
