"""Write homer/.env.prod for the server, from homer/.env.

It copies the API keys and the voice, and points SpacetimeDB at Maincloud. The
SpacetimeDB token and service key are left out on purpose: a local token is
useless on another server, so scripts/stdb_setup.py makes fresh ones.

    .venv/bin/python scripts/prod_env.py --host 203.0.113.7.sslip.io          # Caddy path
    .venv/bin/python scripts/prod_env.py --tunnel-token <token>              # Cloudflare Tunnel path

Never prints a secret. .env.prod is gitignored.
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from homer.config import ROOT, read_env  # noqa: E402

CARRY = (
    "ANTHROPIC_API_KEY",
    "CARTESIA_API_KEY",
    "HOMER_VOICE_ID",
    "HOMER_JUDGE_MODEL",
    "HOMER_JUDGE_EFFORT",
    "HOMER_JUDGE_SPEED",
    "HOMER_JUDGE_TIMEOUT",
    "HOMER_MODEL",
    "HOMER_EFFORT",
    "HOMER_SPEED",
    "HOMER_EMOTION_MODEL",
)
REQUIRED = ("ANTHROPIC_API_KEY", "CARTESIA_API_KEY", "HOMER_VOICE_ID")


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--host", default="", help="public name for Caddy, e.g. 203.0.113.7.sslip.io")
    ap.add_argument("--tunnel-token", default="", help="Cloudflare Tunnel token (the tunnel path)")
    ap.add_argument("--stdb-url", default="https://maincloud.spacetimedb.com")
    ap.add_argument("--stdb-db", default="homer-calhacks")
    ap.add_argument("--out", type=Path, default=ROOT / ".env.prod")
    args = ap.parse_args()
    if not args.host and not args.tunnel_token:
        ap.error("give --host (Caddy) or --tunnel-token (Cloudflare Tunnel)")

    local = read_env(ROOT / ".env")
    missing = [k for k in REQUIRED if not local.get(k)]
    if missing:
        print(f"homer/.env is missing {', '.join(missing)}")
        return 1
    keep = read_env(args.out) if args.out.exists() else {}  # keep a prod token and key made earlier
    lines = [f"{k}={local[k]}" for k in CARRY if local.get(k)]
    lines += [f"STDB_URL={args.stdb_url}", f"STDB_DB={args.stdb_db}"]
    lines += [f"{k}={keep[k]}" for k in ("STDB_TOKEN", "HOMER_SERVICE_KEY") if keep.get(k)]
    if args.host:
        lines.append(f"HOMER_HOST={args.host}")
    if args.tunnel_token:
        lines.append(f"CLOUDFLARE_TUNNEL_TOKEN={args.tunnel_token}")
    args.out.write_text("\n".join(lines) + "\n")
    args.out.chmod(0o600)
    print(f"wrote {args.out} with: {', '.join(line.split('=', 1)[0] for line in lines)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
