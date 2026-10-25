# Inspiration

We're living in a world where fewer and fewer people practice speaking. AI can write your toast, your cover letter and even your apology, so the muscle of standing up and saying something in front of other people goes unused. Speaking well is still one of the most valuable skills there is. It's how you move people, comfort them, lead and connect, and almost nobody trains it.

The Greeks did. They treated rhetoric and recitation as a core discipline, a skill you built with practice and a community, the way you'd train for a sport. We wanted to give that training back, and to use AI to do it instead of replacing it.

The hook is historical, and it's real. Homer didn't memorize the 15,000 lines of the Iliad. He composed them live, with stock phrases like "swift-footed Achilles" and "the wine-dark sea" that fit fixed slots in the beat, so a bard could improvise for hours without losing it. The same method runs through Beowulf and freestyle rap. It's a learnable system, which means a first-timer can learn to speak with rhythm, imagery and nerve.

We built it first for spoken-word and slam poets, who get one open mic a week and practice alone in their rooms in between.

So we built MeNIN, where AI doesn't talk for you. It coaches you, judges you honestly and makes you talk. Homer teaches the craft in short lessons, then you battle friends and strangers live, in the same room. You practice diction, rhythm and delivery, and you build the nerve to perform, together with other people. AI is the teacher and the referee. The voice is still yours.

The name is μῆνιν (*mēnin*, "rage"), the first word of the Iliad.

## What it does

**MeNIN is a live voice poetry battle, judged out loud by Homer.** It's ancient Greek party games: one big screen, with every player's iPhone as the controller.

- **The arena is a website.** Open it on a laptop (https://play.206.189.237.157.sslip.io/homer) and it hosts the room, runs the game and speaks as Homer, our host and judge. Players join by QR code or room code, with no account.
- **Your iPhone is your controller.** It's your mic and your private hand of Homer's phrases.
- **Every turn runs the same way.** Homer writes a fresh theme from his own world and calls you up with an epithet he coins for you. Your phone deals you three of his phrases that fit the theme. After a 3-2-1 you speak free verse for up to 20 seconds, and your words appear live on the big screen. Then Homer judges it out loud within seconds and quotes your best line.
- **The freeze rescue.** Go silent mid-verse for about two and a half seconds, and Homer whispers one of your phrases so you can keep going.
- **The scene paints your emotion.** A painted Aegean on the big screen moves with your voice and shifts color with the feeling in it (anger, grief, joy, awe, tenderness, fear, defiance, longing), and it never names the feeling.
- **The song.** At the end, Homer stitches the best lines from the room into one song.
- **Bard lessons.** Six short lessons with Homer teach the beat, the formula, the epithet, the emotional turn, answering an opponent and the closing boast. Lesson one opens with the first line of the Iliad, whose first word in Greek is *mēnin*, our name.
- **More events on the same engine.** In Socratic debate, Socrates hosts and you argue a side you didn't choose, using a hand of rhetorical moves. The demo's question is Achilles' own choice: "Achilles could live a long life and be forgotten, or die young and be sung forever. Which would you choose?" Talk to Homer is a one-on-one: say a verse, and he quotes you, gives you one fix and scores it. [If discus passes on 31: In discus, you swing your phone and lift your thumb to throw.] The Stadion, archery and boxing (running, toxeia and pygmachia) are in beta on the website. [If archery passes on 31: Archery uses the laptop's webcam to track your bow arm and your draw.]

**How the judge scores.** Homer scores what you said, on three things: Image (×4), Answer (×4) and Craft (×2), out of 100. It's anchored: a typical verse lands at 20–45, and a 9 on any axis is a line you'd quote tomorrow. Every score and the quoted line are shown, so a loser can always see why.

## How we built it

**Four deployables:**

- **Website (the arena):** designed and generated in **Figma Make** by our web designer (React, Vite and TypeScript, with a 3D Homer modeled in Three.js and the painted Aegean scene in WebGL). It's on GitHub and served as static files at a public HTTPS URL, so judges can open it themselves.
- **iOS app (the controller):** designed in **Figma Design** and built in SwiftUI, with Metal shaders for the scene, AVAudioEngine for the mic, and Core Motion for the motion games.
- **SpacetimeDB runs the game, so every phone is just a screen.** One module (27 tables, 45 reducers) runs all seven events. Scheduled reducers end every turn on time, so a dropped phone can't stall a battle. Row-level security means only your phone can read your phrases, and only Homer's agent can post a score. The speaking poet's voice streams to the arena about 20 times a second. A phone that loses the network comes back on the right screen by itself; we tested it in airplane mode on a real iPhone.
- **Agent service:** Python and FastAPI.
  - **Claude** judges every verse and writes everything Homer says: the themes, the calls, the epithets, the verdicts and the closing song. Claude Haiku reads the emotion in your voice for the scene.
  - **Cartesia** hears you and gives Homer his voice. For streaming speech-to-text we send it every phrase Homer dealt you as keyterms.
  - **Moss** picks the phrases that fit a theme Homer wrote seconds ago, in about 13 ms on our server.
  - A deterministic meter scanner built on the CMU Pronouncing Dictionary scores the beat in the lessons, with no AI.

**Content:** a bank of 180 Homeric formulas, 125 hand-written and 55 mined from public-domain Homer translations by our **Apify** Actor, Epithet Miner (https://apify.com/matusnator/epithet-miner, Actor ID `v4i7ItNXjHMmnKzfo`). There are also six lesson scripts, 22 debate questions and 40 rhetorical-move cards.

**How we used agents:** MeNIN was built by two designers and a team of Claude Code sessions (lead, product, art, iOS, multiplayer, backend and go-to-market) working from one spec. More than 95% of our commits are co-authored by Claude. The art session read our Figma concept frames through the Figma MCP, and it kept every design token in Figma variables named after their Swift code, so the app's whole reskin to the website's palette took one new variable mode in Figma, one new case in code and five small view edits. We kept a strict rule: nothing in the demo path is a mocked response.

## Challenges we ran into

- **The backend and Homer's design.** Making Homer feel like one coherent character across lessons, battles, verdicts, whispers and Socrates' very different voice, while keeping real-time state, voice and Claude calls in sync, was our biggest problem.
- **Frontend aesthetics and integration.** Getting the generated front end to match the hand-tuned look (the flat, matte sea and the cream, sea-blue and gold palette) and wiring it to live data took the most iteration.
- **AI tools that didn't always follow instructions.** The Figma agents worked well overall, but they sometimes misread our input, so we reviewed every output and re-prompted.
- **Judging fairly.** We anchored the judge so a typical first verse lands at 4 to 6 per axis and a 9 or 10 is a line you'd quote tomorrow. The beat is scored only in the lessons, by the deterministic scanner, never by Claude.
- **Voice on a noisy hackathon floor.** Sending Cartesia the phrases Homer dealt you as keyterms cut the word error rate from 20% to 3% in our tests, with a drum at full volume as the noise (synthetic clips; the scripts and raw output are in `docs/voice-wer/`).

## Accomplishments that we're proud of

- A full game you can actually play: join by QR code, speak, and watch the scene react to your voice.
- A scene that shows emotion without ever naming it.
- A judge that explains itself and doesn't flatter.
- One engine running very different games, from poetry to debate to motion games.
- A real public deployment, with no mocked responses in the demo.
- **[B: no study]** Every lesson try gets a Beat score from the scanner, not the AI, so a poet can see their first try against their last. **[A: the study ran]** On the beat-scored version of lesson one, [N] people who'd never freestyled went from [first] to [last] out of 10 on Beat.

## What we learned

- Oral poetry is a system, not a gift. Formulas and a beat can turn improvising from terrifying into something you can learn.
- Keeping deterministic checks (the meter scanner) separate from Claude's judgment makes AI scoring more trustworthy and easier to explain.
- When an AI tool builds your front end, a precise spec and reviewing every output matter more than writing code.
- Voice products live or die on small things, like when music fades, when a mic opens and how long a silence lasts.

## What's next for MeNIN

- **More poets and more hosts**: not just Homer, but Hesiod and Virgil, each with their own tradition and teaching style.
- **A better UI and more features**, polishing the experience for phones and the big screen.
- **A learning coach**: an AI that learns your style and weaknesses and coaches you over time.
- **More motion games**: the Stadion, archery and boxing are in beta now, and each one leaves beta when it passes five clean runs in a row.
