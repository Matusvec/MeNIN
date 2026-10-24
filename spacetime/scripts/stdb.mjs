// Minimal SpacetimeDB HTTP client, the same calls the agent service makes.
// Used by smoke.mjs and dev-agent.mjs.

import { execFileSync } from 'node:child_process';
import { randomBytes } from 'node:crypto';

export const URL_ = process.env.STDB_URL ?? 'http://127.0.0.1:3000';
export const DB = process.env.STDB_DB ?? 'homer';
export const SERVER = process.env.STDB_SERVER ?? 'local';

export async function identity() {
  const res = await fetch(`${URL_}/v1/identity`, { method: 'POST' });
  const { identity, token } = await res.json();
  return { hex: identity, token };
}

// Throws with the reducer's error text when it refuses (HTTP 530).
export async function call(who, reducer, ...args) {
  const res = await fetch(`${URL_}/v1/database/${DB}/call/${reducer}`, {
    method: 'POST',
    headers: { Authorization: `Bearer ${who.token}`, 'Content-Type': 'application/json' },
    body: JSON.stringify(args),
  });
  const body = await res.text();
  if (!res.ok) throw new Error(`${reducer}: ${res.status} ${body}`);
}

// One SQL statement; returns rows as objects keyed by column name.
export async function sql(who, query) {
  const res = await fetch(`${URL_}/v1/database/${DB}/sql`, {
    method: 'POST',
    headers: who ? { Authorization: `Bearer ${who.token}` } : {},
    body: query,
  });
  if (!res.ok) throw new Error(`sql: ${res.status} ${await res.text()}`);
  const [{ schema, rows }] = await res.json();
  const names = schema.elements.map(e => e.name.some);
  return rows.map(r => Object.fromEntries(names.map((n, i) => [n, r[i]])));
}

// A fresh identity registered as a service. Needs the `spacetime` CLI
// logged in as the database owner, to set the key.
export async function serviceIdentity() {
  const key = randomBytes(16).toString('hex');
  execFileSync('spacetime', ['call', '-s', SERVER, DB, 'set_service_key', key], { stdio: 'ignore' });
  const who = await identity();
  await call(who, 'claim_service', key);
  return who;
}
