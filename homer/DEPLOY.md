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
rsync -az --delete --exclude .venv --exclude __pycache__ --exclude .pytest_cache --exclude '.env*' \
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

## If it breaks

| Symptom | Fix |
| --- | --- |
| SSH hangs after "Server accepts key" | `UsePAM` must be `yes` (phase 1). On the laptop, a wedged ssh-agent does the same: try `ssh -o IdentitiesOnly=yes -i ~/.ssh/id_ed25519 matus@<ip>`. |
| Caddy has no certificate | Ports 80 and 443 open in UFW (and in any DigitalOcean cloud firewall); `HOMER_HOST` in `.env` matches the IP; `docker compose logs caddy`. |
| `/health` says `stdb: failed` | The key isn't set on `homer-calhacks` for this identity: ask multiplayer, then rerun `stdb_setup.py --env-file .env.prod`. |
| `/health` says `judge: failed` | The Anthropic key in `.env`; `docker compose logs homer`. |
| The verdict streams in one lump | Caddy must keep `flush_interval -1` (see `Caddyfile`). |
