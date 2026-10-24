# Instructions for AI agents in this repo

1. Read `SPEC.md` before writing code. It defines what MeNIN is and does (Homer is its host character). If what you are about to build is not in it or contradicts it, leave a `TODO(spec):` note and keep going on spec'd work instead of inventing features.
2. `Homer Cal Hacks 13.0 Project Plan.md` is background (pitch, sponsor tracks, schedule). `SPEC.md` wins where they disagree.
3. Build order: the turn (spec section "The turn") working end to end on two devices first. Everything else layers on top.

## Stack

- App: iOS only (SwiftUI, iOS 18+, universal iPhone and iPad), Metal shaders for the scene, AVAudioEngine for the mic, project generated with XcodeGen. No web app.
- Real-time state: SpacetimeDB (rooms, players, turns, verses, scores, scene state).
- Agent service: Python + FastAPI (Claude calls, meter scanner, formula bank).
- Voice: Cartesia (streaming STT, TTS).

Three deployables. Do not add a fourth.

## UI

Matus owns the visual design and UX. Keep state and logic (view models, SpacetimeDB subscriptions, audio) separate from SwiftUI views, so the design can change without rewriting logic.

## Git

- Pull `main` before starting and before every push, and read `SPEC.md` again after every pull.
- Each part of the app lives in its own folder. Only change files inside the folder you were asked to work on; never edit `SPEC.md`, `AGENTS.md`, or another part's folder:
  - `homer/`: agent brain in Python (Claude calls, meter scanner, judging).
  - `spacetime/`: SpacetimeDB module (TypeScript) and `spacetime/CONTRACT.md`, the contract for tables and reducers.
  - `ios/`: the iOS app. The project, app shell, audio, networking and state belong to the iOS lead; `ios/Homer/Scene/` and `ios/Homer/UI/` belong to the art lead. Shared types live in `ios/Homer/Contracts.swift`; change them only with the leader's sign-off.
  - `content/`: lesson scripts and the formula bank, read by the agent service and the app.
  - `docs/`: UX flow, voice research, and other design docs. Go-to-market material goes in `docs/gtm/`.
- Never force-push, never rewrite history, never delete files you did not create. If a push is rejected, pull and merge, then push again.

## Rules

- No mocked responses in the demo path. Mocks only behind an explicit dev flag.
- Never commit API keys. Use `.env` (gitignored) and commit `.env.example`.
- Small commits that each leave the app running.
