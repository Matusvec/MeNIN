# Deploying the agent service

Target: a DigitalOcean droplet (Ubuntu 24.04, 2 GB, SFO3, hostname `menin-agent`), created with Matus's `~/.ssh/id_ed25519` key. It follows the `vps-hardening-and-tunnel-deploy` playbook. **The phase order is a safety rule:** never harden SSH before a second login works, and keep one SSH session open while changing `sshd` or the firewall.

Two ways to serve it; pick one in phase 4:

| Path | URL | Needs |
| --- | --- | --- |
| **A. Caddy** (default) | `https://<ip>.sslip.io` | Ports 80 and 443 open. Caddy gets a Let's Encrypt certificate by itself. |
| **B. Cloudflare Tunnel** | `https://api.<domain>` | A domain on Cloudflare and a tunnel token. No open web ports. |

`<ip>` below is the droplet's public IPv4; `<host>` is `<ip>.sslip.io`.

## Phase 0: before the droplet exists (laptop)

```bash
cd homer
.venv/bin/python scripts/prod_env.py --host <host>            # writes .env.prod (gitignored, mode 600)
.venv/bin/python scripts/stdb_setup.py --env-file .env.prod --prepare
```

`prod_env.py` copies the Anthropic and Cartesia keys and the voice, and points SpacetimeDB at Maincloud (`homer-calhacks`). `--prepare` creates a fresh Maincloud identity and a service key in `.env.prod`. **Then ask multiplayer to set that key on `homer-calhacks`** (it reads `HOMER_SERVICE_KEY` from `homer/.env.prod`). After that:

```bash
.venv/bin/python scripts/stdb_setup.py --env-file .env.prod     # claim; must print "claimed"
```

Rerunning `prod_env.py` with a new `--host` keeps the token and key.

## Phase 1: harden SSH (root, then `matus`)

```bash
ssh root@<ip>
adduser --disabled-password --gecos "" matus && usermod -aG sudo matus
echo "matus ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/90-matus && chmod 440 /etc/sudoers.d/90-matus
mkdir -p /home/matus/.ssh && cp /root/.ssh/authorized_keys /home/matus/.ssh/
chown -R matus:matus /home/matus/.ssh && chmod 700 /home/matus/.ssh && chmod 600 /home/matus/.ssh/authorized_keys
```

**Checkpoint:** in a second terminal, `ssh matus@<ip> sudo whoami` prints `root`. Don't go on until it does.

Then, still as root, with that second session open:

```bash
grep -rn "PasswordAuthentication\|PermitRootLogin\|UsePAM" /etc/ssh/sshd_config /etc/ssh/sshd_config.d/
cat > /etc/ssh/sshd_config.d/00-menin.conf <<'EOF'
PermitRootLogin no
PasswordAuthentication no
KbdInteractiveAuthentication no
UsePAM yes
EOF
sshd -t && systemctl reload ssh
```

- **Never set `UsePAM no`.** It makes logins hang after the key is accepted.
- Drop-ins are read in order and the first value wins, so `00-` beats DigitalOcean's `50-cloud-init.conf`. If the grep shows `PasswordAuthentication yes` anywhere, check `sshd -T | grep -i -E "passwordauth|permitroot|usepam"` reads `no`, `no`, `yes`.

**Checkpoint:** in a **new** terminal, `ssh matus@<ip>` works and `ssh root@<ip>` is refused.

## Phase 2: firewall, fail2ban, Docker (as `matus`)

```bash
sudo ufw allow OpenSSH && sudo ufw allow 80/tcp && sudo ufw allow 443/tcp   # path B: OpenSSH only
sudo ufw --force enable && sudo ufw status
sudo apt-get update && sudo apt-get install -y fail2ban rsync
curl -fsSL https://get.docker.com | sudo sh
sudo usermod -aG docker matus     # log out and back in
docker run --rm hello-world
```

**Checkpoint:** a new `ssh matus@<ip>` still works; `docker ps` runs without sudo.

Port 22 stays open on path A: SSH is key-only, root is refused, and fail2ban bans brute force. The playbook's SSH-over-tunnel step (closing 22) needs a Cloudflare domain, so it only applies to path B, after the tunnel is verified in two fresh terminals.

## Phase 3: ship the code and the env (laptop)

The repo is private, so copy what the image needs instead of cloning:

```bash
cd ..   # repo root
rsync -az --delete --exclude .venv --exclude __pycache__ --exclude .pytest_cache --exclude '.env*' --exclude web \
  homer content matus@<ip>:~/menin/
scp homer/.env.prod matus@<ip>:~/menin/homer/.env
ssh matus@<ip> chmod 600 '~/menin/homer/.env'
```

## Phase 4: run it (on the droplet)

```bash
cd ~/menin/homer
docker compose --profile caddy up -d --build      # path A
# docker compose --profile tunnel up -d --build   # path B
docker compose ps                                  # homer healthy, caddy up
docker compose logs --tail=40 homer caddy          # "certificate obtained", no tracebacks
```

## Phase 5: verify (laptop)

```bash
python3 homer/scripts/demo_check.py https://<host>
```

It must say **GO**: health, the judge cache warm, SpacetimeDB claimed on `homer-calhacks`, a verdict under 2.5 s, themes, the rescue, and a voice token with Carl's voice. Then send the URL to swift and multiplayer, and follow `spacetime/HOSTING.md` "The switch": multiplayer stops dev-agent on `homer-calhacks`, and we run one demo battle through the real agent.

## Updating

```bash
rsync … (as in phase 3) && ssh matus@<ip> 'cd ~/menin/homer && docker compose --profile caddy up -d --build'
```

Caddy keeps its certificate in a volume, so restarts don't ask Let's Encrypt again. In-memory state (dealt hands, emotion samples) resets on restart: don't redeploy mid-battle.

## The website

SPEC "The website": static files on the droplet, at their own HTTPS name. Caddy serves `/srv/menin-web` at `WEB_HOST` (for example `play.<ip>.sslip.io`) with its own Let's Encrypt certificate, and unknown paths fall back to `index.html` for client-side routes.

```bash
homer/scripts/web_deploy.sh matus@<ip>                 # from the repo root: build web/, publish it
homer/scripts/web_deploy.sh matus@<ip> --placeholder   # the "hall opens soon" page
```

The site is `web/` at the repo root (or `homer/web/` while it sits there). With a `package.json` it is built in a scratch copy, so its folder is never written to: `pnpm install --frozen-lockfile && pnpm run build` when there's a `pnpm-lock.yaml` (pnpm, else corepack, else `npx pnpm@<the .mise.toml version>`), otherwise `npm ci && npm run build`; then `dist/`, `build/` or `out/` is published. `VITE_*` variables in your environment reach the build. Figma Make's `vite.config.ts` imports `.figma/make/site.json`, which Make keeps outside the repo; when it's missing, `homer/web_site.json` (title, description, language) stands in. A plain folder with an `index.html` is published as is. The files are swapped in place (`rsync --delay-updates`), with nothing restarted, so it never touches the agent.

The agent gives CORS headers only to the origins in `HOMER_WEB_ORIGINS` (comma-separated, in `.env`). A keyless call from one of them passes even when `HOMER_APP_KEY_REQUIRED=1`. That isn't a lock, since anyone can send that Origin; the per-IP limits and the hourly budget are the guard. The website never ships the app key. For a new domain, add it to both `WEB_HOST` (a second site block, or replace the name) and `HOMER_WEB_ORIGINS`.

First-time setup on the droplet: `sudo mkdir -p /srv/menin-web && sudo chown matus:matus /srv/menin-web`, then `docker compose --profile caddy up -d --no-deps caddy`.

**Changing the Caddyfile:** it is bind-mounted as a single file, so copy it with `rsync --inplace` and run `docker compose exec caddy caddy reload --config /etc/caddy/Caddyfile`. Without `--inplace`, rsync swaps the file for a new one, and the container keeps reading the old one until it is recreated.

## Side quests (off unless switched on)

Both are sponsor integrations behind switches (SPEC "Not building"). The demo never depends on them, and switching either off restores today's behaviour.

### Fetch.ai: Homer on Agentverse and ASI:One

A sidecar container from the same image (`fetch` profile). It speaks the Agent Chat Protocol and forwards each chatted verse to this service's `/judge`, so the same rate limits and hourly budget apply. `FETCH_AGENT_SEED` in `.env` fixes its identity, and so its `agent1…` address.

```bash
docker compose --profile caddy --profile fetch up -d --build   # switch on
docker compose logs --tail=40 fetch                            # look for "Manifest published successfully: AgentChatProtocol"
docker compose stop fetch                                      # switch off
# update the sidecar alone, leaving the game's agent running: `fetch` has no build of its own,
# so build the shared image through `homer`, then recreate only `fetch`
docker compose build homer && docker compose --profile fetch up -d --no-deps fetch
```

**One-time mailbox connection** (needs an Agentverse account at agentverse.ai). The Agentverse Inspector's **Connect** button can't do it here: uagents takes `POST /connect` only from 127.0.0.1 inside the agent's container, and anything from outside (an SSH tunnel, a browser, Caddy) arrives from the Docker bridge and gets 403. So connect with an API key instead:

1. In Agentverse: profile → **API Keys** → **New API Key** (shortest expiry, default permissions). Put it in `homer/.env` on the laptop as `AGENTVERSE_API_KEY=…`. Never paste it into a chat.
2. From the repo root: `python3 homer/scripts/agentverse_connect.py matus@<ip>`. It sends the key into the `fetch` container over SSH stdin and makes the Inspector's call from there. It prints `{"success": true, …}`, and `docker compose logs fetch` shows "Successfully registered as mailbox agent in Agentverse". The key can be revoked afterwards; the mailbox stays registered.
3. In the agent's Agentverse profile, set the handle (for example `@homer-bard`) and keywords (poetry, verse, judge, rap, improv), then **Chat with Agent** to try it from ASI:One. The README shown there is `AGENTVERSE.md`.

After that, messages reach the agent through its Agentverse mailbox; port 8001 stays bound to the droplet's localhost.

### Moss: deal formulas by meaning

`HOMER_DEALER=moss` with `MOSS_PROJECT_ID` and `MOSS_PROJECT_KEY` (from the Moss portal) in `.env`, then restart. On startup the agent builds the bank's index once per bank version and loads it in the background. `/health` shows `"dealer": "moss"` once it's ready. Until then, and on any error or a query slower than `HOMER_MOSS_TIMEOUT_MS` (500), hands are dealt by tags as before. Remove `HOMER_DEALER` to switch it off.

- **The project holds at most three indexes.** At the cap, a build fails with "The project's usage limit has been reached", which reads like billing but isn't. So on a new bank version the agent first deletes its own older `menin-formulas-*` indexes (never anyone else's), then builds. Run Moss from one place (the droplet), or two different banks will keep evicting each other's index.
- If Moss can't start (a limit, a network blip), the agent deals by tags and retries in the background (30 s, 1, 2, 5, then every 10 minutes), so it comes back without a redeploy.
- To spare the droplet the build (8–22 s on tags), build from the laptop before deploying a bank change: start a `MossDealer` once with the new `content/`, as `scripts/` runs do.

## If it breaks

| Symptom | Fix |
| --- | --- |
| SSH hangs after "Server accepts key" | `UsePAM` must be `yes` (phase 1). On the laptop, a wedged ssh-agent does the same: try `ssh -o IdentitiesOnly=yes -i ~/.ssh/id_ed25519 matus@<ip>`. |
| Caddy has no certificate | Ports 80 and 443 open in UFW (and in any DigitalOcean cloud firewall); `HOMER_HOST` in `.env` matches the IP; `docker compose logs caddy`. |
| `/health` says `stdb: failed` | The key isn't set on `homer-calhacks` for this identity: ask multiplayer, then rerun `stdb_setup.py --env-file .env.prod`. |
| `/health` says `judge: failed` | The Anthropic key in `.env`; `docker compose logs homer`. |
| The verdict streams in one lump | Caddy must keep `flush_interval -1` (see `Caddyfile`). |
