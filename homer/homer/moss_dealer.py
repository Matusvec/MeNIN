"""Moss retrieval for the dealer: formulas that fit a theme by meaning, not only by keyword tags.

Behind a switch (SPEC "Not building"): HOMER_DEALER=moss turns it on. Today's
tag dealer (homer/deal.py) is the fallback whenever Moss is off, not ready yet,
errors or runs past its timeout, so a hand is always dealt and the demo never
depends on it.

The formula bank is indexed once per bank version (the index name carries a
hash of formulas.json), loaded into this process at startup, and queried
locally, which Moss puts at a few milliseconds.

Env: HOMER_DEALER=moss, MOSS_PROJECT_ID, MOSS_PROJECT_KEY, HOMER_MOSS_TIMEOUT_MS (default 500).
"""

from __future__ import annotations

import asyncio
import hashlib
import json
import logging
import os
from typing import Any

from . import formulas
from .formulas import Formula

log = logging.getLogger("homer")

MODEL = "moss-minilm"
TOP_K = 48


def index_name() -> str:
    """One index per bank version, so a bank edit builds a fresh index instead of querying a stale one."""
    raw = json.dumps([f.__dict__ for f in formulas.bank()], sort_keys=True, default=list)
    return f"menin-formulas-{hashlib.sha256(raw.encode()).hexdigest()[:10]}"


def documents() -> list[dict[str, Any]]:
    """The bank as Moss documents: the phrase, with its themes and moods spelled out so meaning has more to hold."""
    return [
        {
            "id": f.id,
            "text": f"{f.text}. themes: {', '.join(f.themes)}. mood: {', '.join(f.emotions)}.",
            "metadata": {"kind": f.kind, "beats": str(f.beats)},
        }
        for f in formulas.bank()
    ]


class MossDealer:
    def __init__(self, project_id: str, project_key: str, client: Any | None = None, timeout_s: float = 0.5) -> None:
        self.project_id, self.project_key = project_id, project_key
        self.client = client
        self.timeout_s = timeout_s
        self.name = index_name()
        self.ready = False

    async def start(self) -> None:
        """Create the index if this bank version has none, then load it. Never raises: off is a fine state."""
        try:
            if self.client is None:
                from moss import MossClient

                self.client = MossClient(self.project_id, self.project_key)
            names = {getattr(i, "name", None) for i in await self.client.list_indexes()}
            if self.name not in names:
                await self.client.create_index(self.name, documents(), MODEL)
                log.info("moss: built %s (%d formulas)", self.name, len(formulas.bank()))
            await self.client.load_index(self.name)
            self.ready = True
            log.info("moss: %s loaded", self.name)
        except Exception as exc:  # any failure leaves the tag dealer in charge
            self.ready = False
            log.warning("moss unavailable, dealing by tags: %s: %s", type(exc).__name__, exc)

    async def ranked(self, theme: str) -> list[Formula] | None:
        """The bank's formulas ranked by fit to the theme, or None to fall back to the tag dealer."""
        if not self.ready or not theme.strip():
            return None
        try:
            from moss import QueryOptions

            result = await asyncio.wait_for(self.client.query(self.name, theme, QueryOptions(top_k=TOP_K)), self.timeout_s)
        except Exception as exc:
            log.warning("moss query failed, dealing by tags: %s", type(exc).__name__)
            return None
        by_id = {f.id: f for f in formulas.bank()}
        out = [by_id[d.id] for d in getattr(result, "docs", []) if getattr(d, "id", None) in by_id]
        return out or None


_dealer: MossDealer | None = None


def dealer() -> MossDealer | None:
    """The Moss dealer when HOMER_DEALER=moss and credentials are set, else None (the tag dealer)."""
    global _dealer
    if os.environ.get("HOMER_DEALER", "").strip().lower() != "moss":
        return None
    if _dealer is None:
        pid, key = os.environ.get("MOSS_PROJECT_ID", "").strip(), os.environ.get("MOSS_PROJECT_KEY", "").strip()
        if not pid or not key:
            log.warning("HOMER_DEALER=moss but MOSS_PROJECT_ID or MOSS_PROJECT_KEY is missing; dealing by tags")
            return None
        _dealer = MossDealer(pid, key, timeout_s=float(os.environ.get("HOMER_MOSS_TIMEOUT_MS", "500")) / 1000)
    return _dealer


async def ranked_formulas(theme: str) -> list[Formula] | None:
    d = dealer()
    return await d.ranked(theme) if d else None
