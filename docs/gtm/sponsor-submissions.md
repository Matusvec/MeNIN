# Sponsor submissions: paste-ready

For Matus, Sun ~3:20 AM. Every line is a paste or a click. **The public repo is the mirror https://github.com/Matusvec/MeNIN** (leader, Sun 8:25 AM: the original owner couldn't be reached to flip it public). All GitHub links below point at it.

## 1. Cartesia: "FINAL MATERIALS - CARTESIA" (their shared doc)

**Working Demo:**
> https://play.206.189.237.157.sslip.io/homer: open it on a laptop, click "Host a battle", then the Poetry battle card. Players join from the MeNIN iPhone app: https://testflight.apple.com/join/r9KCHkhc (live once Apple approves the beta; submitted Sun 3:27 AM); build 45. Until then, a judge can try the experimental browser play: /join/CODE?web=1 → "Play in your browser" (poetry and Talk to Homer only).

**Demo-First Presentation:**
> [2:00 cut link]: a 1:49 cut of our Devpost video, exported on its own (`menin-demo-2min-final.mp4`), ending on our "Built responsibly" card. One complete battle turn first (a poet speaks, Cartesia transcribes it live, Homer judges it out loud in his Cartesia voice), then the problem and how we built it.

**Short README:**
> https://github.com/Matusvec/MeNIN#cartesia-ears-and-voice: the Cartesia section of our README.
> - **Speech-to-text:** ink-2, streaming over WebSocket. Every phrase Homer dealt the poet, plus the theme, goes in as keyterms. In our noise test (a drum at full volume, synthetic clips), the word error rate was 3% with keyterms and 20% without, and the final transcript landed 62–81 ms after the end of speech.
> - **Text-to-speech:** sonic-3.6, voice Carl, for Homer: entrances, verdicts, the freeze whisper, the lessons and the stitched song.
> - **Privacy:** our server mints short-lived tokens, and the phone streams straight to Cartesia, so no audio passes through our server and the API key never leaves it.
> - **Setup:** the "Run it" section (`homer/.env.example` lists the Cartesia settings).
> - **Known limitations:** loud rooms (our tests used synthetic mixes, not a real phone mic in a hall), and accents, names, slang and loanwords. The transcript is always on screen, so you see what Homer heard.

**Source Access for Judges:**
> https://github.com/Matusvec/MeNIN (public, MIT license). There are no API keys or secrets in the repo: `.env` is gitignored, `.env.example` is committed, and a full-history secret scan (gitleaks, every commit) came back clean.

*gtm note: the brief said STT "ink-whisper", but the product uses **ink-2** (`homer/homer/voice.py`, `CartesiaSTT.swift`, `homer/web/src/poet/stt.ts`). ink-whisper appears only in a voiceover script. The text above says ink-2.*

## 2. Apify: what goes where

- **Devpost, "Sponsors & Special Prizes":** tick **both** "[Apify] Best Use of Apify" and "[Apify] Best Actor sponsored by Apify".
- **Devpost, Apify blurb** (paste from `docs/gtm/devpost.md`, "Sponsor-track blurbs"). It must contain the Store link **https://apify.com/matusnator/epithet-miner** and the Actor ID **`v4i7ItNXjHMmnKzfo`** (Apify staff: "in your submission just share the link and id for us"; "share the actor id so we can view").
- **The built-with-AI line, in the blurb:** "Epithet Miner is an Apify Actor, built with AI chat: Claude in Claude Code wrote it from our prompts." *(Honest note: we never asked Apify staff whether an Actor written by an AI coding agent counts as "built with AI Chat". Best Use is covered either way.)*
- **Devpost, "Built with":** include `apify` ("Be sure to list Apify as one of your sponsor tooling used").
- **Anything outside Devpost?** Nothing Apify posted asks for anything beyond the Devpost submission (#spons-apify, Sat 1:13 PM and 9:12 PM, staff). The Actor needn't be public, but ours is on the Store anyway.

## 3. Figma: five steps

1. Share the Slides deck as **Anyone with the link → can view ("View all")**: https://www.figma.com/slides/oYPLd3JeIjhnkNyt75qfOm
2. In Devpost → Project details → **"Try it out" links**, paste that Slides link (Figma staff: "You are required to submit a Figma slides link").
3. Tick **"[Figma] Best Figma Workflow Hack"**. It "will also opt you into the Figma Best Design, Most Creative, and Best Stage Log!"
4. In the deck: embed both prototype flows on slide 8 and the Directions file on slide 9, put the team's names on slide 1, and add the two Hall slides from `docs/gtm/figma-stage-log.md` ("Deck text for Matus").
5. Check every Figma file opens logged out: the deck, "MeNIN · Directions", the concept-art file, the FigJam board and the Make files.
6. **The demo video** Figma asks for (3 minutes max) is our Devpost video, https://youtu.be/gvGEeuahLdE (2:41). It "does not have to be the same video", but it can be (Figma staff, Sun 12:23 AM). It also goes on slide 3 of the deck.

## 4. SpacetimeDB: the Swift SDK fixes

The fork is public (Sun ~4:25 AM), so the SpacetimeDB story now has two links a judge can click.

- **Fork:** https://github.com/Matusvec/spacetimedb-swift, a fork of avias8/spacetimedb-swift v0.23.0 with our three fixes, their tests and a FORK.md on how they were tested. BSL 1.1 kept.
- **Draft PR upstream:** https://github.com/avias8/spacetimedb-swift/pull/3, five commits (three fixes, tests, FORK.md); `swift test`: 86 passed, 0 failures.
- **Devpost:** tick "[Spacetime] Best Use of Spacetime" and paste the SpacetimeDB blurb from `docs/gtm/devpost.md` ("Sponsor-track blurbs"). Its "We fixed the Swift SDK to ship" bullet carries both links.
- **The video** (2:41), which shows the SpacetimeDB flip: https://youtu.be/gvGEeuahLdE. Judges at the table won't have seen it (MLH staff, Sun 6:07 AM), so the live flip on the second desktop still has to happen there.
- **The README's SpacetimeDB section** carries both links too: https://github.com/Matusvec/MeNIN#spacetimedb-the-hall.
- **Say it exactly like this:** "a public fork with fixes sent upstream". Clockwork Labs has no official Swift SDK; avias8's is a community SDK; ours is a fork with fixes, not a new SDK. The license is BSL 1.1, unchanged, so never "open-sourced" and never "MIT".
