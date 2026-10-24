#!/usr/bin/env bash
# Publish the website (SPEC "The website") to the droplet: build it here, rsync the result.
#
#   homer/scripts/web_deploy.sh matus@<ip>                 # from the repo root
#   homer/scripts/web_deploy.sh matus@<ip> --placeholder   # the "hall opens soon" page
#
# The site is web/ at the repo root (or homer/web/ while it sits there). It is
# built in a scratch copy, so the site's folder is never written to:
# - With a package.json: install (pnpm when there's a pnpm-lock.yaml, else npm),
#   then `run build`, and publish dist/, build/ or out/. VITE_* variables in the
#   environment reach the build.
# - Figma Make's vite.config.ts imports .figma/make/site.json, which Make keeps
#   outside the repo. When it's missing, homer/web_site.json stands in.
# - A plain folder with an index.html is published as is.
# Caddy serves /srv/menin-web at WEB_HOST (homer/Caddyfile). Nothing restarts:
# the files are swapped in place, so it's safe at any time.
set -euo pipefail

host=${1:?usage: web_deploy.sh user@host [--placeholder]}
root=$(cd "$(dirname "$0")/../.." && pwd)
src=""

pnpm_cmd() {
  local version
  version=$(grep -o '"npm:pnpm" *= *"[^"]*"' "$1/.mise.toml" 2>/dev/null | cut -d'"' -f4 || true)
  if command -v pnpm >/dev/null; then echo pnpm
  elif command -v corepack >/dev/null; then echo "corepack pnpm@${version:-latest}"
  else echo "npx --yes pnpm@${version:-latest}"
  fi
}

if [[ "${2:-}" == "--placeholder" ]]; then
  src="$root/homer/web_placeholder"
else
  site=""
  for d in "$root/web" "$root/homer/web"; do
    if [[ -f "$d/package.json" || -f "$d/index.html" ]]; then site=$d; break; fi
  done
  if [[ -z "$site" ]]; then
    echo "no website to publish: neither web/ nor homer/web/ has a package.json or index.html" >&2
    exit 1
  fi
  if [[ -f "$site/package.json" ]]; then
    build=$(mktemp -d "${TMPDIR:-/tmp}/menin-web.XXXXXX")
    trap 'rm -rf "$build"' EXIT
    rsync -a --exclude node_modules --exclude dist --exclude build --exclude out --exclude .git "$site/" "$build/"
    if grep -q "figma/make/site.json" "$build"/vite.config.* 2>/dev/null && [[ ! -f "$build/.figma/make/site.json" ]]; then
      mkdir -p "$build/.figma/make" && cp "$root/homer/web_site.json" "$build/.figma/make/site.json"
      echo "using homer/web_site.json for .figma/make/site.json"
    fi
    if [[ -f "$build/pnpm-lock.yaml" ]]; then
      pm=$(pnpm_cmd "$build")
      (cd "$build" && $pm install --frozen-lockfile && $pm run build)
    else
      (cd "$build" && npm ci && npm run build)
    fi
    for d in dist build out; do
      if [[ -f "$build/$d/index.html" ]]; then src="$build/$d"; break; fi
    done
  else
    src="$site"
  fi
fi
if [[ -z "$src" || ! -f "$src/index.html" ]]; then
  echo "nothing to publish: the build made no index.html" >&2
  exit 1
fi

rsync -az --delete --delay-updates --exclude node_modules --exclude '.env*' --exclude '.git' "$src/" "$host:/srv/menin-web/"
web_host=$(ssh -o BatchMode=yes "$host" "grep '^WEB_HOST=' ~/menin/homer/.env | cut -d= -f2-")
echo "published $src"
echo "https://$web_host"
