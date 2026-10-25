# Sponsor submissions: paste-ready

For Matus, Sun ~3:20 AM. Every line is a paste or a click. The repo goes public at 8:00 AM, so the GitHub links only work after that.

## 1. Cartesia: "FINAL MATERIALS - CARTESIA" (their shared doc)

**Working Demo:**
> https://play.206.189.237.157.sslip.io/homer: open it on a laptop, click "Host a battle", then the Poetry battle card. Players join from the MeNIN iPhone app: [TestFlight link] (the public link is pending Apple's Beta App Review; build 45).

**Demo-First Presentation:**
> [2:00 cut link]: the first 2:00 of our Devpost video, exported on its own. One complete battle turn first (a poet speaks, Cartesia transcribes it live, Homer judges it out loud in his Cartesia voice), then the problem and how we built it.

**Short README:**
> https://github.com/sunya-afrasiabi/MeNIN#cartesia-ears-and-voice: the Cartesia section of our README.
> - **Speech-to-text:** ink-2, streaming over WebSocket. Every phrase Homer dealt the poet, plus the theme, goes in as keyterms. In our noise test (a drum at full volume, synthetic clips), the word error rate was 3% with keyterms and 20% without, and the final transcript landed 62–81 ms after the end of speech.
> - **Text-to-speech:** sonic-3.6, voice Carl, for Homer: entrances, verdicts, the freeze whisper, the lessons and the stitched song.
> - **Privacy:** our server mints short-lived tokens, and the phone streams straight to Cartesia, so no audio passes through our server and the API key never leaves it.
> - **Setup:** the "Run it" section (`homer/.env.example` lists the Cartesia settings).
> - **Known limitations:** loud rooms (our tests used synthetic mixes, not a real phone mic in a hall), and accents, names, slang and loanwords. The transcript is always on screen, so you see what Homer heard.

**Source Access for Judges:**
> https://github.com/sunya-afrasiabi/MeNIN (public from Sun 8:00 AM, MIT license). There are no API keys or secrets in the repo: `.env` is gitignored, `.env.example` is committed, and a full-history secret scan (gitleaks, every commit) came back clean.

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
