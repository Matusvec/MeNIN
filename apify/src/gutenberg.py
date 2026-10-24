"""Fetching Homer translations from Project Gutenberg, politely, once.

For each ebook id the crawler reads the catalog record (RDF) first. Only a
book whose record says "Public domain in the USA." is fetched; anything else
is skipped and reported. The plain text is then cut to the part between
Gutenberg's START and END markers, so the license boilerplate is never mined.

Politeness: one request at a time, a per-minute cap, a descriptive
User-Agent, and a cache (a folder locally, a named key-value store on the
Apify platform) so a book is downloaded once, not on every run.
gutenberg.org/robots.txt disallows only /ebooks/search, which this never touches.
"""

from __future__ import annotations

import html
import re
from dataclasses import dataclass, field
from datetime import timedelta
from pathlib import Path
from typing import Any, Protocol

from crawlee import ConcurrencySettings, Request
from crawlee.crawlers import HttpCrawler, HttpCrawlingContext

USER_AGENT = "EpithetMiner/0.1 (Apify Actor; MeNIN, Cal Hacks 13.0; fetches each book once and caches it)"
RDF_URL = "https://www.gutenberg.org/cache/epub/{id}/pg{id}.rdf"
TEXT_URL = "https://www.gutenberg.org/cache/epub/{id}/pg{id}.txt"
PUBLIC_DOMAIN = "public domain in the usa"

START_RE = re.compile(r"^\*\*\* ?START OF (THE|THIS) PROJECT GUTENBERG EBOOK.*$", re.M | re.I)
END_RE = re.compile(r"^\*\*\* ?END OF (THE|THIS) PROJECT GUTENBERG EBOOK.*$", re.M | re.I)


@dataclass
class Book:
    id: str
    title: str
    translators: list[str]  # surnames, in catalog order
    rights: str
    text: str = ""

    @property
    def work(self) -> str:
        for w in ("Iliad", "Odyssey"):
            if w.lower() in self.title.lower():
                return w
        return self.title

    @property
    def source(self) -> str:
        """ "Iliad, tr. Lang, Leaf & Myers (Project Gutenberg #3059)" """
        names = self.translators or ["unknown translator"]
        tr = names[0] if len(names) == 1 else ", ".join(names[:-1]) + " & " + names[-1]
        return f"{self.work}, tr. {tr} (Project Gutenberg #{self.id})"


@dataclass
class FetchResult:
    books: list[Book] = field(default_factory=list)
    skipped: list[dict[str, str]] = field(default_factory=list)  # {"id", "reason"}
    fetched: list[str] = field(default_factory=list)  # URLs actually downloaded this run
    cached: list[str] = field(default_factory=list)  # cache keys reused


class Cache(Protocol):
    async def get(self, key: str) -> str | None: ...
    async def set(self, key: str, value: str) -> None: ...


class DirCache:
    """A folder of downloaded files (local runs)."""

    def __init__(self, path: Path) -> None:
        self.path = path
        path.mkdir(parents=True, exist_ok=True)

    async def get(self, key: str) -> str | None:
        p = self.path / key
        return p.read_text(encoding="utf-8") if p.exists() else None

    async def set(self, key: str, value: str) -> None:
        (self.path / key).write_text(value, encoding="utf-8")


class StoreCache:
    """A named Apify key-value store (platform runs); it outlives the run."""

    def __init__(self, store: Any) -> None:
        self.store = store

    async def get(self, key: str) -> str | None:
        v = await self.store.get_value(key)
        if v is None:
            return None
        return v.decode("utf-8") if isinstance(v, (bytes, bytearray)) else str(v)

    async def set(self, key: str, value: str) -> None:
        await self.store.set_value(key, value, content_type="text/plain; charset=utf-8")


class NoCache:
    async def get(self, key: str) -> str | None:
        return None

    async def set(self, key: str, value: str) -> None:
        return None


# ----- Parsing ---------------------------------------------------------------


def _tag(rdf: str, tag: str) -> list[str]:
    return [html.unescape(m).strip() for m in re.findall(rf"<{tag}(?:\s[^>]*)?>(.*?)</{tag}>", rdf, re.S)]


def parse_rdf(ebook_id: str, rdf: str) -> Book:
    """Title, translators and rights from a Gutenberg RDF record (read as text, never as XML)."""
    titles = _tag(rdf, "dcterms:title")
    title = re.split(r"[\r\n]", titles[0])[0].strip() if titles else f"Gutenberg #{ebook_id}"
    rights = (_tag(rdf, "dcterms:rights") or [""])[0]
    translators = []
    for block in _tag(rdf, "marcrel:trl"):
        for name in _tag(block, "pgterms:name"):
            translators.append(name.split(",")[0].strip())  # "Butcher, S. H. (Samuel Henry)" -> "Butcher"
    return Book(id=ebook_id, title=title, translators=translators, rights=rights)


def is_public_domain(book: Book) -> bool:
    return PUBLIC_DOMAIN in book.rights.lower()


def body(text: str) -> str | None:
    """The book between Gutenberg's START and END markers, or None if they're missing."""
    s, e = START_RE.search(text), END_RE.search(text)
    if not s or not e or e.start() <= s.end():
        return None
    return text[s.end() : e.start()]


# ----- Fetching --------------------------------------------------------------


async def fetch(ids: list[str], cache: Cache, *, max_per_minute: int, log: Any) -> FetchResult:
    """Every requested book that is on Gutenberg and public domain in the USA."""
    result = FetchResult()
    rdfs: dict[str, str] = {}
    texts: dict[str, str] = {}

    for i in ids:
        if (v := await cache.get(f"pg{i}.rdf")) is not None:
            rdfs[i] = v
            result.cached.append(f"pg{i}.rdf")
        if (v := await cache.get(f"pg{i}.txt")) is not None:
            texts[i] = v
            result.cached.append(f"pg{i}.txt")

    crawler = HttpCrawler(
        concurrency_settings=ConcurrencySettings(
            min_concurrency=1, max_concurrency=1, desired_concurrency=1, max_tasks_per_minute=max_per_minute
        ),
        max_request_retries=2,
        request_handler_timeout=timedelta(seconds=120),
        configure_logging=False,
    )

    def text_request(i: str) -> Request:
        return Request.from_url(TEXT_URL.format(id=i), label="text", headers={"User-Agent": USER_AGENT}, user_data={"id": i})

    @crawler.router.handler("rdf")
    async def on_rdf(ctx: HttpCrawlingContext) -> None:
        i = ctx.request.user_data["id"]
        rdf = (await ctx.http_response.read()).decode("utf-8", errors="replace")
        await cache.set(f"pg{i}.rdf", rdf)
        rdfs[i] = rdf
        result.fetched.append(ctx.request.url)
        if is_public_domain(parse_rdf(i, rdf)) and i not in texts:
            await ctx.add_requests([text_request(i)])

    @crawler.router.handler("text")
    async def on_text(ctx: HttpCrawlingContext) -> None:
        i = ctx.request.user_data["id"]
        text = (await ctx.http_response.read()).decode("utf-8", errors="replace")
        await cache.set(f"pg{i}.txt", text)
        texts[i] = text
        result.fetched.append(ctx.request.url)

    @crawler.router.default_handler
    async def on_other(ctx: HttpCrawlingContext) -> None:
        log.warning(f"Unexpected request {ctx.request.url}")

    start: list[Request] = []
    for i in ids:
        if i not in rdfs:
            start.append(Request.from_url(RDF_URL.format(id=i), label="rdf", headers={"User-Agent": USER_AGENT}, user_data={"id": i}))
        elif i not in texts and is_public_domain(parse_rdf(i, rdfs[i])):
            start.append(text_request(i))
    if start:
        log.info(f"Fetching {len(start)} file(s) from Project Gutenberg, one at a time")
        await crawler.run(start)

    for i in ids:
        if i not in rdfs:
            result.skipped.append({"id": i, "reason": "no catalog record (not on Project Gutenberg?)"})
            continue
        book = parse_rdf(i, rdfs[i])
        if not is_public_domain(book):
            result.skipped.append({"id": i, "reason": f"not public domain in the USA ({book.rights or 'no rights statement'})"})
            continue
        main = body(texts.get(i, ""))
        if main is None:
            result.skipped.append({"id": i, "reason": "no Project Gutenberg text with START/END markers"})
            continue
        book.text = main
        result.books.append(book)
    return result
