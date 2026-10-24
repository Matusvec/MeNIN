"""SpacetimeDB setup for the agent service: an identity, a service key, and the claim.

Local (homer/.env):

    .venv/bin/python scripts/stdb_setup.py --set-key        # if you own the database
    .venv/bin/python scripts/stdb_setup.py                  # if its owner set the key for you

Production, with its own env file (see DEPLOY.md and scripts/prod_env.py):

    .venv/bin/python scripts/stdb_setup.py --env-file .env.prod --prepare   # identity + key, no claim yet
    # the owner sets HOMER_SERVICE_KEY on the database, then:
    .venv/bin/python scripts/stdb_setup.py --env-file .env.prod             # claim and verify

With --env-file, only that file is read, so a local token never leaks into
another server's setup (tokens don't carry across servers).
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

from homer.config import ROOT, load_env, read_env, settings  # noqa: E402
from homer.stdb import Refused, Stdb  # noqa: E402


def save(env: Path, name: str, value: str) -> None:
    lines = env.read_text().splitlines() if env.exists() else []
    lines = [line for line in lines if not line.startswith(f"{name}=")] + [f"{name}={value}"]
    env.write_text("\n".join(lines) + "\n")
    os.environ[name] = value


async def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--env-file", type=Path, help="read and write this env file instead of homer/.env")
    ap.add_argument("--prepare", action="store_true", help="create the identity and key only; don't claim yet")
    ap.add_argument("--set-key", action="store_true", help="set the service key with the owner's spacetime CLI")
    ap.add_argument("--server", default="local", help="spacetime CLI server name for --set-key (local or maincloud)")
    args = ap.parse_args()

    env = args.env_file.resolve() if args.env_file else ROOT / ".env"
    if args.env_file:
        os.environ["HOMER_DOTENV"] = "0"  # never mix in homer/.env
        os.environ.update(read_env(env))
    else:
        load_env()

    cfg = settings()
    print(f"database {cfg.stdb_url} / {cfg.stdb_db}  ({env.name})")
    if not os.environ.get("STDB_TOKEN"):
        identity, token = await Stdb(cfg).new_identity()
        save(env, "STDB_TOKEN", token)
        print(f"new identity {identity}")
    if not os.environ.get("HOMER_SERVICE_KEY"):
        save(env, "HOMER_SERVICE_KEY", secrets.token_hex(16))
        print(f"new service key saved to {env.name}")
    settings.cache_clear()
    cfg = settings()

    if args.set_key:
        cli = shutil.which("spacetime") or str(Path.home() / ".local/bin/spacetime")
        subprocess.run([cli, "call", "-s", args.server, cfg.stdb_db, "set_service_key", cfg.service_key], check=True)
        print("service key set")
    if args.prepare:
        print(f"ready: ask the owner of {cfg.stdb_db} to set HOMER_SERVICE_KEY from {env.name}, then run without --prepare")
        return 0

    db = Stdb(cfg)
    try:
        await db.claim_service()
    except Refused as exc:
        print(f"claim refused: {exc}")
    if await db.is_service():
        print(f"claimed: this identity can write to {cfg.stdb_db}")
        return 0
    print(f"NOT a service on {cfg.stdb_db} yet: has the owner set the key from {env.name}?")
    return 1


if __name__ == "__main__":
    sys.exit(asyncio.run(main()))
