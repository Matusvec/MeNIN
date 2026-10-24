"""Merge reviewed candidates from output/formulas.mined.json into the formula bank.

A dry run by default: it prints what it would add. Pass --write to update the
bank file (whoever owns content/ runs this, after reviewing the candidates).

    python scripts/merge_into_bank.py                       # dry run, all candidates
    python scripts/merge_into_bank.py --min-count 5         # only well-attested ones
    python scripts/merge_into_bank.py --skip son-of-atreus,king-of-men --write

Merged entries keep only the bank fields (id, text, kind, beats, themes,
emotions) unless --keep-provenance is given. Run from apify/.
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from src.bank import BANK_FIELDS, Bank, validate  # noqa: E402

ROOT = Path(__file__).resolve().parents[1]


def main() -> None:
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--mined", type=Path, default=ROOT / "output" / "formulas.mined.json")
    p.add_argument("--bank", type=Path, default=ROOT.parent / "content" / "formulas.json")
    p.add_argument("--min-count", type=int, default=1)
    p.add_argument("--kinds", default="epithet,kenning,half_line", help="comma-separated kinds to take")
    p.add_argument("--only", default="", help="comma-separated ids to take (default: all)")
    p.add_argument("--skip", default="", help="comma-separated ids to leave out")
    p.add_argument("--keep-provenance", action="store_true", help="also keep source and count")
    p.add_argument("--write", action="store_true", help="update the bank file")
    a = p.parse_args()

    raw_bank = json.loads(a.bank.read_text(encoding="utf-8"))
    bank = Bank.from_json(raw_bank, str(a.bank))
    mined = json.loads(a.mined.read_text(encoding="utf-8"))
    kinds = set(a.kinds.split(","))
    only = {x for x in a.only.split(",") if x}
    skip = {x for x in a.skip.split(",") if x}

    added = []
    for e in mined:
        if problems := validate(e):
            print(f"invalid, skipped: {e.get('text')}: {problems}")
            continue
        if e["kind"] not in kinds or e["count"] < a.min_count or e["id"] in skip or (only and e["id"] not in only):
            continue
        if dup := bank.duplicate_of(e["id"], e["text"]):
            print(f"already in the bank ({dup[0]}: {dup[1]}): {e['text']}")
            continue
        added.append(e if a.keep_provenance else {k: e[k] for k in BANK_FIELDS})
        bank = Bank.from_json(raw_bank + added, str(a.bank))

    for e in added:
        print(f"+ {e['text']}  ({e['kind']}, {e['beats']} beats)")
    print(f"{len(added)} new formulas; the bank would go from {len(raw_bank)} to {len(raw_bank) + len(added)}")
    if not a.write:
        print("Dry run. Pass --write to update", a.bank)
        return
    merged = raw_bank + added
    a.bank.write_text("[\n" + ",\n".join("  " + json.dumps(e, ensure_ascii=False) for e in merged) + "\n]\n", encoding="utf-8")
    print(f"Wrote {a.bank}. Update the entry count in content/README.md too.")


if __name__ == "__main__":
    main()
