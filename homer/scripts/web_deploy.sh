#!/usr/bin/env bash
# Publish the website (SPEC "The website") to the droplet: build web/ here, rsync the result.
#
#   homer/scripts/web_deploy.sh matus@<ip>                 # from the repo root
#   homer/scripts/web_deploy.sh matus@<ip> --placeholder   # the "hall opens soon" page
#
# web/ with a package.json is built with `npm ci && npm run build` and its dist/,
# build/ or out/ is published; a plain web/ with an index.html is published as is.
# Caddy serves /srv/menin-web at WEB_HOST (homer/Caddyfile). Nothing restarts:
# the files are swapped in place, so it's safe between battles and during them.
set -euo pipefail

host=${1:?usage: web_deploy.sh user@host [--placeholder]}
root=$(cd "$(dirname "$0")/../.." && pwd)
src=""
if [[ "${2:-}" == "--placeholder" ]]; then
  src="$root/homer/web_placeholder"
elif [[ -f "$root/web/package.json" ]]; then
  (cd "$root/web" && npm ci && npm run build)
  for d in dist build out; do
    if [[ -f "$root/web/$d/index.html" ]]; then src="$root/web/$d"; break; fi
  done
elif [[ -f "$root/web/index.html" ]]; then
  src="$root/web"
fi
if [[ -z "$src" || ! -f "$src/index.html" ]]; then
  echo "nothing to publish: no index.html in web/ (or its build), and no --placeholder" >&2
  exit 1
fi

rsync -az --delete --delay-updates --exclude node_modules --exclude '.env*' --exclude '.git' "$src/" "$host:/srv/menin-web/"
web_host=$(ssh -o BatchMode=yes "$host" "grep '^WEB_HOST=' ~/menin/homer/.env | cut -d= -f2-")
echo "published $src"
echo "https://$web_host"
