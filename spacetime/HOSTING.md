# Hosting the battle database for the demo

Phones at the venue must reach SpacetimeDB. A laptop on venue WiFi is the fragile option: client isolation, a changing IP, plain `ws://`. Two real options follow. Development stays on the local server either way.

## Status: live on Maincloud (2026-10-24)

- Database `homer-calhacks`, owned by Matus's Maincloud login. Dashboard: https://spacetimedb.com/homer-calhacks
- Maincloud runs SpacetimeDB **2.13.0** (`GET /v1/health`), the same version as our CLI and module.
- `npm run smoke` against it: all 52 checks pass, including the scheduled turn timer and row-level security on hands.
- HTTP round trip from the venue laptop: p50 about 73 ms.
- Clients: server URL `https://maincloud.spacetimedb.com` (the WebSocket is `wss://`), database `homer-calhacks`.
- Development stays on the local `homer` for now.

## Recommendation: Maincloud

Maincloud is Clockwork Labs' hosted SpacetimeDB. It takes minutes to set up, needs no operations work, comes with TLS (`wss://`), and it's the Spacetime track's own platform. Start on Free and move to Pro if the pausing below worries us.

| | Maincloud | Small VPS (self-hosted) |
| --- | --- | --- |
| Setup | `spacetime login` (GitHub or Google, **Matus's call**), then one `publish`. About 10 min. | Ubuntu VPS, a systemd service, TLS through nginx/Caddy or a Cloudflare Tunnel, and a deploy path for module updates. 1–2 h, using Matus's existing Vultr → Cloudflare Tunnel playbook. |
| Cost | Free: $0, 2,500 TeV/month (about 3M reducer calls, 12.5 GB egress, 1 GB storage). Pro: $25/month. | About $6–12/month |
| TLS / iOS ATS | Built in: `https://maincloud.spacetimedb.com` | We set it up. Standalone has no TLS ("SSL is not supported in standalone mode"). |
| Risk | Free pauses after inactivity. The pricing page says after 1 week with no connections or calls; the docs give no number. It resumes on the next connection, "typically less than one second". Pro with pay-as-you-go never pauses. The region isn't documented, so latency is unknown until we test. | We own uptime, disk and restarts. Remote publish is blocked by the recommended nginx config, so updates go over SSH. We can pick a region near the venue (e.g. Silicon Valley). |
| Updates | `spacetime publish -s maincloud <name>` from any laptop that's logged in | Build locally, copy the module, publish over SSH |

## Our load fits the Free tier easily

Each turn makes about 800 reducer calls: prosody at 20 Hz × 30 s is about 600, transcript partials about 150, scene about 20, plus the turn's own calls.

| Usage | Reducer calls |
| --- | --- |
| A 2-poet, 1-round demo battle | about 1,600 |
| A full battle (5 poets × 3 rounds) | about 12,000 |
| The whole weekend of testing | a few hundred thousand |

All of that is under 10% of the 3M free calls. Egress is also small: one prosody update fans out to about six clients at roughly 100 bytes each. Scope phone subscriptions to the room, so phones don't receive other rooms' prosody.

## Moving to Maincloud (once Matus has logged in)

1. `spacetime login` (Matus, in a browser).
2. `cd spacetime && spacetime publish -s maincloud -y homer-calhacks`. Done; it runs 2.13.0.
3. `spacetime call -s maincloud homer-calhacks set_service_key <key>`. The new owner is Matus's Maincloud identity.
4. The agent service gets `STDB_URL=https://maincloud.spacetimedb.com`, `STDB_DB=homer-calhacks` and a fresh token from `POST https://maincloud.spacetimedb.com/v1/identity`. Then it calls `claim_service`.
5. The app's server URL becomes `https://maincloud.spacetimedb.com` (the WebSocket is `wss://`) with database `homer-calhacks`. Each device gets a new identity, because tokens don't carry across servers.
6. Run `STDB_URL=https://maincloud.spacetimedb.com STDB_DB=homer-calhacks STDB_SERVER=maincloud npm run smoke`.

## Demo-day insurance (either option)

- Keep the arena connected from setup onward, and make one warm-up call before each pitch.
- Pre-create a second room (SPEC: "a second room pre-created in case the live one wedges"). `rematch` resets the first room in one call.
- Last resort: the laptop's local server on a phone hotspot. This is today's setup; the phones point at the laptop's IP.

Sources: spacetimedb.com/pricing, /docs/how-to/deploy/maincloud and /docs/how-to/deploy/self-hosting, read 2026-10-24.
