"""Connect homer-bard's Agentverse mailbox with an API key, no browser (the one-time step in DEPLOY.md).

    python3 homer/scripts/agentverse_connect.py matus@<ip>      # from the repo root

The Agentverse Inspector's Connect button can't reach a dockerized agent:
uagents takes POST /connect only from 127.0.0.1 inside the agent's own
container, and every request from outside (an SSH tunnel, a browser, Caddy)
arrives from the Docker bridge instead and gets 403. So this script makes the
Inspector's call from inside the `fetch` container: it hands the agent an
Agentverse API key (agentverse.ai → profile → API Keys), and the agent proves
its identity to Agentverse and registers as a mailbox agent.

The key comes from AGENTVERSE_API_KEY, else homer/.env (never committed). It
travels over SSH stdin only, never on a command line, and is never printed.
Standard library only. Exit code 0 means connected.
"""

from __future__ import annotations

import json
import os
import shlex
import subprocess
import sys

CONTAINER = "homer-fetch-1"
CONNECT = """
import sys, urllib.request, urllib.error
req = urllib.request.Request("http://127.0.0.1:8001/connect", data=sys.stdin.buffer.read(),
                             headers={"content-type": "application/json"}, method="POST")
try:
    print(urllib.request.urlopen(req, timeout=60).read().decode())
except urllib.error.HTTPError as e:
    print(e.read().decode())
"""


def api_key() -> str:
    """The Agentverse API key: AGENTVERSE_API_KEY, else homer/.env (never committed)."""
    key = os.environ.get("AGENTVERSE_API_KEY", "").strip()
    env = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".env")
    if not key and os.path.isfile(env):
        for line in open(env, encoding="utf-8"):
            if line.startswith("AGENTVERSE_API_KEY="):
                key = line.split("=", 1)[1].strip().strip("'\"")
    return key


def main() -> int:
    if len(sys.argv) != 2:
        print(__doc__.strip().splitlines()[2].strip())
        return 2
    key = api_key()
    if not key:
        print("No AGENTVERSE_API_KEY in the environment or homer/.env")
        return 2
    payload = json.dumps({"user_token": key, "agent_type": "mailbox"}).encode()
    remote = f"docker exec -i {CONTAINER} python -c {shlex.quote(CONNECT)}"
    out = subprocess.run(["ssh", "-o", "BatchMode=yes", sys.argv[1], remote], input=payload, capture_output=True, timeout=120)
    text = out.stdout.decode().strip() or out.stderr.decode().strip()
    print(text.replace(key, "<key>"))
    try:
        return 0 if json.loads(text.splitlines()[-1]).get("success") else 1
    except (ValueError, IndexError, AttributeError):
        return 1


if __name__ == "__main__":
    sys.exit(main())
