"""One-time SpacetimeDB setup for the agent service.

1. Creates an identity if homer/.env has no STDB_TOKEN, and saves the token.
2. Creates HOMER_SERVICE_KEY if missing, and saves it.
3. With --set-key, sets that key on the database through the owner's
   `spacetime` CLI (the owner is whoever published the module).
4. Calls claim_service, which registers this identity for the agent reducers.

    .venv/bin/python scripts/stdb_setup.py --set-key
"""

from __future__ import annotations

import argparse
import asyncio
import os
import secrets
import shutil
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from homer.config import ROOT, load_env, settings  # noqa: E402
from homer.stdb import Stdb  # noqa: E402

ENV = ROOT / ".env"


def save(name: str, value: str) -> None:
    lines = ENV.read_text().splitlines() if ENV.exists() else []
    lines = [line for line in lines if not line.startswith(f"{name}=")] + [f"{name}={value}"]
    ENV.write_text("\n".join(lines) + "\n")
    os.environ[name] = value


async def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--set-key", action="store_true", help="set the service key with the owner's spacetime CLI")
    ap.add_argument("--server", default="local", help="spacetime CLI server name (local or maincloud)")
    args = ap.parse_args()
    load_env()

    db = Stdb(settings())
    if not os.environ.get("STDB_TOKEN"):
        identity, token = await db.new_identity()
        save("STDB_TOKEN", token)
        print(f"new identity {identity}")
    if not os.environ.get("HOMER_SERVICE_KEY"):
        save("HOMER_SERVICE_KEY", secrets.token_hex(16))
    settings.cache_clear()
    cfg = settings()

    if args.set_key:
        cli = shutil.which("spacetime") or str(Path.home() / ".local/bin/spacetime")
        subprocess.run([cli, "call", "-s", args.server, cfg.stdb_db, "set_service_key", cfg.service_key], check=True)
        print("service key set")

    await Stdb(cfg).claim_service()
    print(f"claimed service on {cfg.stdb_url}/{cfg.stdb_db}")


if __name__ == "__main__":
    asyncio.run(main())
