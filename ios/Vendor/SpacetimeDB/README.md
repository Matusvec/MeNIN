# SpacetimeDB Swift SDK (vendored)

Source: https://github.com/avias8/spacetimedb-swift at commit `994b0d4` (release 0.23.0). It is a community SDK, not an official Clockwork Labs one. It speaks the `v2.bsatn.spacetimedb` WebSocket protocol, which our SpacetimeDB 2.13 server uses.

License: SpacetimeDB Business Source License 1.1 (`LICENSE.txt`), the same license as SpacetimeDB itself.

Only `Sources/` is vendored. Tests, benchmarks and DocC are left out, and `Package.swift` is trimmed to the library target.

## Local patches

Each patch is marked `HOMER PATCH` in the source.

1. `Network/SpacetimeClient.swift`: no implicit `SELECT * FROM <table>` for every registered table on (re)connect. Upstream subscribes to whole tables, so every phone would receive every room's rows, including prosody at 20 Hz. The app subscribes only to its own `WHERE room_id = N` queries.
2. `Cache/TableCache.swift`: `rows` lists each distinct row once. Upstream repeats a row once per overlapping subscription, because it treats the refcount as a multiplicity.
3. `Network/SpacetimeClient.swift` and `Cache/ClientCache.swift`: on every connect, the first subscription rows each table receives replace that table's cache (`ClientCache.clear(tables:)`). Upstream replays the subscriptions' rows on top of the old cache after a reconnect, so a row that changed or vanished while the socket was down stayed in the cache as a ghost beside the fresh one (a phone stuck on a room's old event until the app was killed).

## Known quirk, not patched

`ClientCache.applyTransactionUpdate` pairs a transaction's deletes and inserts by position and reports them as updates. Key rows by primary key, and don't rely on `onUpdate` pairing.

Requires iOS 18 or later, because it uses `Synchronization.Mutex`.
