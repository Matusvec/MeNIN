# Instructions for AI agents in this repo

1. Read `SPEC.md` before writing code. It defines what Homer is and does. If what you are about to build is not in it or contradicts it, leave a `TODO(spec):` note and keep going on spec'd work instead of inventing features.
2. `Homer Cal Hacks 13.0 Project Plan.md` is background (pitch, sponsor tracks, schedule). `SPEC.md` wins where they disagree.
3. Build order: the turn (spec section "The turn") working end to end with two browsers first. Everything else layers on top.

## Stack

- Web: React + Vite + TypeScript, Three.js with custom GLSL for the scene.
- Real-time state: SpacetimeDB (rooms, players, turns, verses, scores, scene state).
- Agent service: Python + FastAPI (Claude calls, meter scanner, formula bank).
- Voice: Cartesia (streaming STT, TTS).

Three deployables. Do not add a fourth.

## UI

Matus owns the visual design and UX. Keep state and logic (hooks, stores, SpacetimeDB subscriptions, audio) separate from presentation components, and keep styling minimal and placeholder, so the real design can drop in without rewriting logic.

## Git

- Pull `main` before starting and before every push, and read `SPEC.md` again after every pull.
- Each part of the app lives in its own folder. Only change files inside the folder you were asked to work on; never edit `SPEC.md`, `AGENTS.md`, or another part's folder:
  - `homer/`: agent brain in Python (Claude calls, meter scanner, judging).
  - `spacetime/`: SpacetimeDB module (TypeScript) and `spacetime/CONTRACT.md`, the contract for tables and reducers.
  - `web/`: the React app. Scaffold, `package.json`, `src/scene/`, `src/ui/`, `src/screens/` belong to the art lead; `src/module_bindings/` (generated) and `src/state/` belong to the SpacetimeDB owner. Shared types live in `web/src/contracts.ts`; change them only with the leader's sign-off.
  - `docs/`: UX flow, voice research, and other design docs. Go-to-market material goes in `docs/gtm/`.
- Never force-push, never rewrite history, never delete files you did not create. If a push is rejected, pull and merge, then push again.

## Rules

- No mocked responses in the demo path. Mocks only behind an explicit dev flag.
- Never commit API keys. Use `.env` (gitignored) and commit `.env.example`.
- Small commits that each leave the app running.
