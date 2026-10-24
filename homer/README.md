# Homer agent service

The Python service behind MeNIN: the four-beat scanner, the judge, the dealer, the freeze rescue, Cartesia voice tokens, and the battle agent that writes to SpacetimeDB. The HTTP API is in [API.md](API.md); the battle database contract is `spacetime/CONTRACT.md`.

## Run it

```bash
/opt/homebrew/bin/python3.13 -m venv .venv
.venv/bin/pip install -r requirements-dev.txt
cp .env.example .env        # then fill in ANTHROPIC_API_KEY and the rest
.venv/bin/uvicorn homer.server:app --host 0.0.0.0 --port 8000
```

`GET /health` reports `"judge": "warm"` once the startup call has cached the judge's prompt.

## Test it

```bash
.venv/bin/python -m pytest                    # offline: no Claude, no SpacetimeDB, never reads .env
.venv/bin/python scripts/latency.py --n 10    # live judge latency, p50/p95 (about half a cent a call)
.venv/bin/python scripts/battle_live.py       # a live demo battle against SpacetimeDB (two judge calls)
```

`scripts/stdb_setup.py` registers this service with SpacetimeDB once: it creates an identity, saves the token to `.env`, and calls `claim_service`. The database owner has to set the service key first (`--set-key` does it if you are the owner).

## Deploy it

`docker-compose.yml` runs the service and a Cloudflare Tunnel sidecar, with no published ports. From `homer/` on the server, with `.env` in place:

```bash
docker compose up -d --build
docker compose logs -f homer
```

In the Cloudflare dashboard, give the tunnel a public hostname `api.<domain>` pointing at `http://homer:8000`. Run one replica: dealt hands, emotion samples and in-flight judging live in memory.

## How it fits together

| File | Role |
| --- | --- |
| `homer/scanner.py` | The four-beat scanner (CMU dictionary, no model): hits per line, the break, on-beat timing, the beat lane. The Beat axis comes from here. |
| `homer/judge.py` | The turn verdict: one streamed Claude call with the scan inlined, strict JSON, a cached prompt, and the verdict streamed first. |
| `homer/host.py` | Homer's other lines: naming poets, the round verdict and carved line, the stitched song, spar verses. |
| `homer/claude.py` | Shared Claude plumbing: request options, streaming, strict JSON, fast-mode fallback. |
| `homer/events.py` | Per-event config: host persona, hand source, rubric axes, beat on or off. Poetry today. |
| `homer/prompts/` | Homer's character (`homer.md`), one file per task (`judge_poetry.md`, `poet.md`, `verdict.md`, `song.md`, `spar.md`), and the classifier (`emotion.md`). Plain markdown; edit freely. |
| `homer/deal.py` | Themes, hands and the freeze rescue. No model calls. |
| `homer/formulas.py` | The formula bank (`content/formulas.json`) and spotting formulas in a verse. |
| `homer/emotion.py` | The eight emotions, the live classifier (Haiku 5.5), and the Range axis. |
| `homer/lessons.py` | The Bard path from `content/lessons.md`, and Homer's one line of feedback per try. |
| `homer/arena.py` | Battle work for the arena: name, deal, scene, judge, round verdict, song, each written with the agent reducers. |
| `homer/stdb.py` | SpacetimeDB over HTTP. |
| `homer/voice.py` | Short-lived Cartesia tokens. |
| `homer/server.py` | FastAPI: the endpoints in API.md. |
| `homer/config.py` | Settings from env and `homer/.env`. |

**Judge settings** (env): `HOMER_JUDGE_MODEL` (default `claude-opus-5-5`), `HOMER_JUDGE_EFFORT` (`low`), `HOMER_JUDGE_SPEED` (`fast`; empty for standard), `HOMER_JUDGE_TIMEOUT` (10 s). Measured on Fri Oct 23: verdict p50 1.0 s, p95 1.5 s with fast mode; p50 2.0 s, p95 4.4 s without.
