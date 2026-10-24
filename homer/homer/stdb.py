"""SpacetimeDB over HTTP, the way spacetime/CONTRACT.md describes it.

There is no Python SDK. Reducer arguments are positional JSON arrays; a
refused call (wrong phase, a duplicate, not authorized) is HTTP 530 with the
reason as the body. A refusal means "already done or not now": it is raised
as `Refused` and never retried.
"""

from __future__ import annotations

from typing import Any

import httpx2

from .config import Settings, settings as load_settings


class StdbError(RuntimeError):
    pass


class Refused(StdbError):
    """The reducer said no (HTTP 530)."""


class Stdb:
    def __init__(self, cfg: Settings | None = None, http: httpx2.AsyncClient | None = None) -> None:
        self.cfg = cfg or load_settings()
        self.http = http or httpx2.AsyncClient(timeout=10.0)

    @property
    def base(self) -> str:
        return f"{self.cfg.stdb_url}/v1/database/{self.cfg.stdb_db}"

    def _auth(self) -> dict[str, str]:
        return {"Authorization": f"Bearer {self.cfg.stdb_token}"} if self.cfg.stdb_token else {}

    async def _post(self, url: str, **kw: Any) -> httpx2.Response:
        """POST, with network failures raised as StdbError: a database that's down never crashes the service."""
        try:
            return await self.http.post(url, **kw)
        except httpx2.HTTPError as exc:
            raise StdbError(f"can't reach {self.cfg.stdb_url}: {type(exc).__name__}") from exc

    async def call(self, reducer: str, *args: Any) -> None:
        res = await self._post(f"{self.base}/call/{reducer}", json=list(args), headers=self._auth())
        if res.status_code == 530:
            raise Refused(f"{reducer}: {res.text}")
        if res.status_code >= 300:
            raise StdbError(f"{reducer}: HTTP {res.status_code} {res.text}")

    async def sql(self, query: str) -> list[dict[str, Any]]:
        """One statement; rows as dicts keyed by column name."""
        res = await self._post(f"{self.base}/sql", content=query, headers=self._auth())
        if res.status_code >= 300:
            raise StdbError(f"sql: HTTP {res.status_code} {res.text}")
        out = []
        for table in res.json():
            names = [e["name"]["some"] for e in table["schema"]["elements"]]
            out.extend(dict(zip(names, row)) for row in table["rows"])
        return out

    async def new_identity(self) -> tuple[str, str]:
        """A fresh identity and its token (first run only; keep the token in .env)."""
        res = await self._post(f"{self.cfg.stdb_url}/v1/identity")
        if res.status_code >= 300:
            raise StdbError(f"identity: HTTP {res.status_code} {res.text}")
        body = res.json()
        return body["identity"], body["token"]

    async def claim_service(self) -> None:
        """Register this identity for the agent-only reducers. Idempotent."""
        await self.call("claim_service", self.cfg.service_key)

    async def is_service(self) -> bool:
        """Whether this identity may call the agent reducers, without changing anything.

        set_scene on turn 0 is dropped silently for a service and refused for
        anyone else. The key can rotate after a claim (each smoke run sets a
        new one) while the identity stays registered, so a refused claim alone
        doesn't mean we can't write.
        """
        try:
            await self.call("set_scene", 0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0)
        except Refused:
            return False
        return True
