"""Live check of Homer's and Socrates' voice against SPEC "Homer, the character".

Costs real money: about 25 Claude calls, roughly $0.25 a run on Opus 5.5 fast. Keep runs few.

    .venv/bin/python scripts/voice_eval.py --out /tmp/voice.json

Runs realistic cases through the real judge and host (turn verdicts good,
weak, frozen, mumbled and off-theme; Socrates' verdicts; entrances; round
calls; the stitched song; the last question) and flags what code can check:
length, sentences, jargon, a named emotion, a read-out number, whether a
verdict quotes the speaker's own words, whether song lines and epithets hold
the beat. The rest (does it land like a knockout?) is for a human reading the
output. The checks themselves live in homer/style.py and are unit-tested.
"""

from __future__ import annotations

import argparse
import asyncio
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from homer.config import settings  # noqa: E402
from homer.host import Host, Verse  # noqa: E402
from homer.judge import Judge, Turn  # noqa: E402
from homer.scanner import scan_verse, strong_hits  # noqa: E402
from homer.style import quoted_run, voice_problems  # noqa: E402

# ----- Cases ------------------------------------------------------------------------

SHIP, DEADLINE, WAR = "A ship that never came home", "The night before the deadline", "The war between two brothers"
HAND = {
    SHIP: ["the hollow ships", "and the sea kept them", "the swan-road", "the wine-dark sea", "far from my home"],
    DEADLINE: ["breaker of deadlines", "at three in the morning", "the light-box", "the sleepless one", "with the deadline coming"],
    WAR: ["two-edged sword", "the shield-wall", "with blood in my eye", "the war-wolf", "as the spears flew"],
}
POETRY = [  # (label, theme, verse, previous, played, rescues)
    ("strong", SHIP, "the hollow ships came back with no one aboard\nmy mother still sets a plate by the door", "",
     ["the hollow ships"], 0),
    ("strong, four lines", SHIP, "the wine dark sea took my brother's ship\nhe sailed at dawn and never came back\n"
     "I stand on the shore with the salt in my teeth\nthe whale road keeps what the whale road takes", "",
     ["the wine-dark sea"], 0),
    ("flat", SHIP, "the ship did not come home and that is bad\nwe were all sad because the ship is gone", "", [], 0),
    ("froze twice", DEADLINE, "at three in the morning\nthe light box", "", ["at three in the morning", "the light-box"], 2),
    ("mumbled", DEADLINE, "uh the the night before um\ndead line coming i i think the screen", "", [], 1),
    ("off theme", DEADLINE, "I love the beach in the summer sun\nthe waves are warm and the day is fun", "", [], 0),
    ("answers the last verse", WAR, "you took the crown but you dropped the blade\nI am the shield wall you cannot break",
     "my brother took the crown and the throne\nI took the sword and I fought alone", ["the shield-wall"], 0),
    ("roast bait", DEADLINE, "breaker of deadlines that's my name\nI hand it in late but I win the game", "",
     ["breaker of deadlines"], 0),
    ("coins a name", DEADLINE, "I am the inbox drowner keeper of three a.m.\nthe coffee goes cold and I write it again", "",
     [], 0),
    ("trash talk", WAR, "your ship sank before it left the dock\nI'm the storm you never saw coming",
     "two edged sword in my brother's hand\nhe swings it wide and he swings it grand", [], 0),
    ("strong, war", WAR, "with blood in my eye I called him by name\nwe shared a mother and now we share a grave", "",
     ["with blood in my eye"], 0),
    ("one weak line", WAR, "the war was long", "", [], 0),
]
DEBATE_ASK = "Is it better to be feared or loved?"
DEBATE_HAND = ["stake your claim", "counterexample", "ask for proof", "concede and pivot", "sum it up"]
DEBATE = [  # (label, side, argument, previous, tapped)
    ("strong", "Loved", "Loved. Fear lasts exactly as long as your power does. Look at every tyrant who died "
     "alone in a palace full of guards. Love is the only loyalty that survives your bad day.", "", ["stake your claim", "counterexample"]),
    ("dodges", "Feared", "Feared. Because people listen when they're scared. Also respect. Fear is respect, basically, "
     "and respect is what you want as a leader. So feared.", "Loved. A leader who is loved gets loyalty, and loyalty "
     "holds when the walls fall.", ["ask for proof"]),
    ("tapped, not made", "Loved", "Loved, definitely. When people love you they help you. That's just how it works, "
     "you know, everyone knows that.", "", ["counterexample", "sum it up"]),
    ("answers well", "Feared", "Feared. My opponent says love survives a bad day. But love asks for something back, "
     "and fear asks for nothing. When the gold runs out, the loved king is a beggar and the feared one is still king.",
     "Loved. Love is the only loyalty that survives your bad day.", ["concede and pivot", "counterexample"]),
]
NAMES = [("Matus", ""), ("Priya", "Salt-Tongued"), ("xXgamerXx", ""), ("Jo", "")]


async def run(out: Path | None) -> None:
    cfg = settings()
    judge, host, socrates = Judge(cfg=cfg), Host(cfg=cfg), Host(cfg=cfg, event="debate")
    rows: list[dict] = []

    def note(kind: str, label: str, text: str, problems: list[str], **extra) -> None:
        rows.append({"kind": kind, "label": label, "text": text, "problems": problems, **extra})
        flag = "  ok " if not problems else "  !! "
        print(f"{flag}{kind:9} {label:24} {text}" + (f"   [{'; '.join(problems)}]" if problems else ""), flush=True)

    await judge.judge(Turn("warm the cache", mode="battle", theme=SHIP))  # unmeasured: the cache is warm in a real battle
    timings, verses = [], {}
    for label, theme, verse, prev, played, rescues in POETRY:
        j = await judge.judge(Turn(verse, mode="battle", theme=theme, hand=HAND[theme], played=played, rescues=rescues,
                                   previous=prev, demo=True, lines_expected=max(2, len(verse.splitlines()))))
        timings.append(j.timing.get("verdict"))
        verses.setdefault(theme, []).append((label, verse, j))
        note("verdict", label, j.verdict, voice_problems(j.verdict, verse), best_line=j.best_line, scores=j.scores,
             coined=j.coined, verdict_ms=j.timing.get("verdict"))
    for label, side, arg, prev, tapped in DEBATE:
        j = await judge.judge(Turn(arg, event="debate", mode="battle", theme=DEBATE_ASK, side=side, hand=DEBATE_HAND,
                                   played=tapped, previous=prev, turn_seconds=45))
        timings.append(j.timing.get("verdict"))
        note("socrates", label, j.verdict, voice_problems(j.verdict, arg), best_line=j.best_line, scores=j.scores,
             verdict_ms=j.timing.get("verdict"))
    for name, epithet in NAMES:
        n, e, coined = await host.name_poet(name, epithet)
        hits = strong_hits(e) if e else 0
        note("entrance", f"{name} / {epithet or '-'}", f"Enter {n}, {e}!", [] if hits == 2 else [f"epithet has {hits} hits"],
             coined=coined)
    for theme in (SHIP, WAR):
        vs = [Verse(i + 1, poet, v, sum(j.scores.values()), j.best_line)
              for i, ((label, v, j), poet) in enumerate(zip(verses[theme][:2], ("Ada", "Bo")))]
        call, turn, line = await host.round_verdict(theme, vs)
        lead = call.split(":")[0] if ":" in call else call
        note("round", theme, call, voice_problems(lead, "", max_words=12, must_quote=0), best_turn=turn)
    battles = {"demo": (verses[SHIP][:2], True), "full": (verses[SHIP][:2] + verses[DEADLINE][:2] + verses[WAR][:2], False)}
    for label, (picked, demo) in battles.items():
        vs = [Verse(i + 1, ("Ada", "Bo")[i % 2], v) for i, (_, v, _) in enumerate(picked)]
        lines = await host.song(vs, demo=demo)
        source = "\n".join(v.transcript for v in vs)
        problems = [f"line {k + 1} has {scan_verse(t).lines[0].hits} hits" for k, (_, t) in enumerate(lines)
                    if scan_verse(t).lines and scan_verse(t).lines[0].hits != 4]
        problems += [f"line {k + 1} isn't theirs" for k, (_, t) in enumerate(lines) if quoted_run(t, source) < 3]
        note("song", label, " / ".join(t for _, t in lines), problems)
    turns = [Verse(i + 1, ("Ada", "Bo")[i % 2], arg) for i, (_, _, arg, _, _) in enumerate(DEBATE)]
    last = await socrates.last_question(turns, [DEBATE_ASK])
    note("last q", "night", " ".join(t for _, t in last), voice_problems(last[-1][1] if last else "", "", max_words=15, must_quote=0))

    ms = sorted(t for t in timings if t)
    p = lambda q: round(ms[min(len(ms) - 1, int(round(q * (len(ms) - 1))))])  # noqa: E731
    flagged = sum(1 for r in rows if r["problems"])
    print(f"\n{len(rows)} outputs, {flagged} flagged. Turn verdicts (incl. Socrates): p50 {p(.5)} ms, p95 {p(.95)} ms")
    if out:
        out.write_text(json.dumps({"rows": rows, "verdict_p50": p(.5), "verdict_p95": p(.95)}, indent=1, default=str))


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", type=Path)
    asyncio.run(run(ap.parse_args().out))
