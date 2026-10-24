# Opportunities board

Every prize, side tournament and challenge at Cal Hacks 13.0, ranked by **what it pays, what it costs us and who can do it**.

**Owner: gtm** (Matus put gtm in charge, Sat 9:15 AM). gtm tracks every item to done, writes the specs, asks leader for builders and folders, and tags each one on Devpost. Status gets updated after every Slack sweep. Built Sat 9:15 AM from all 58 prizes on Hive, the Devpost prize list and every sponsor channel in Slack. gtm keeps it current with each Slack sweep.

**The rules that shape it:**
- **One project per team** (#1-ask-mlh, Fri 7:47 PM, MLH). Every sponsor track is a tag on MeNIN.
- **There's no cap on tags** (#0-ask-directors, organizers).
- Side competitions like Scrabblebot and the Fetch.ai fun challenges aren't projects, so they're fair game.
- **A tag has to be true.** Never enter a track with a bolt-on we'd have to fake. A judge who checks a fake loses us the track and the trust.
- **No side quest on the demo path** (SPEC `5a6a8fe`): side integrations run only behind switches, with today's path as the fallback, and the demo never needs them.
- **The agents are the cheap labor.** A side quest that a Claude session can run alone, without touching the demo path or a human's time, is almost free. Say yes to those.

## Tier 1: do now

| # | Opportunity | Pays | What it takes | Who | Status |
| --- | --- | --- | --- | --- | --- |
| 1 | **Spacetime Scrabblebot tournament** | $1,024 / $512 / $256 | A bot on scrabblebot.spacetimedb.com. **Finals Sat 11:59 PM in the Theater, in person.** The leaderboard rating plays no part in the tournament (the scrabble session checked the module source). Round 1 is paired at random, later rounds by Swiss points, and the cut is by Swiss points, then total score. So late rewrites are safe. Our bot is "Menice": about 45 live matches by Sat 10 AM, rating 1441 (which doesn't matter for the tournament), and it's running A/B experiments. It auto-registers for any tournament in Registration status. **No Devpost entry:** "you don't need to submit it on devpost"; teams submit at **scrabblebot.spacetimedb.com/team** (#cohost-spacetime, Sat 4:09 PM, Spacetime staff). The pool is "$1,792". Strategy can change per stage, but "you should not disconnect between rounds to replace the client" (3:35 PM), and a VM is "fine" (4:10 PM). The tournament details were given at the 4 PM Theater workshop, not in Slack. | scrabble session, plus one human in the Theater at midnight | **In progress** (the scrabble session builds it; gtm feeds it intel). **Who goes to the Theater at midnight?** |
| 2 | **Fetch.ai ASI:One fun challenges** | 5 each of **Meta AI glasses, Beats, Kindles, Instax**, plus a grand-prize trip | About 10 minutes per person on a phone: asi1.ai → the Cal Hacks event page (asi1.ai/festivals/calhacks2026/dashboard). Round 1 had a "Hacker Personality Challenge" and an "AI Investor Challenge". **Four more winner rounds remain.** Collect at the Fetch booth. | **Every teammate**, each on their own account | **Green-lit by Matus.** Every teammate enters. **Round 2 winners were posted at 1:15 PM** (Beats, Fujifilm cameras, Meta AI glasses), with "More rounds of winners to come" and no time given (#spons-fetch-ai, Fetch.ai staff). Anyone who hasn't entered still can. gtm tracks the rounds. |
| 3 | **Microsoft: Built for the Real World** (and the Customer Impact Award) | **A Surface laptop per team member**, a tech talk and mentorship | Tag MeNIN on Devpost. Their brief: "a production-minded AI agent that solves a meaningful problem in… another high-impact domain", judged on customer understanding, measurable usefulness, a path from prototype to production, responsible design and end-to-end functionality. We already document all five, so add one Devpost paragraph that maps to them. Azure isn't required. | gtm (the paragraph); Matus is at their workshop 10:00–10:45 in the Theater, so talk to their engineers after | **gtm owns it.** The Devpost section is done, and Matus's 20 s line is below. Tag it at submission. |
| 4 | **Apify: Best use** (5 places) **plus Best Actor** | $2,000 / $1,000 / $800 / $400 / $400, plus $400 for the best Actor "built with AI Chat" | An **Apify Actor that builds our formula bank**: it mines public-domain Homer translations (Project Gutenberg) for epithets and formulas into `content/formulas.json`, which the game deals from. Build it with Apify's AI Chat or MCP (mcp.apify.com works in Claude). Publish the Actor. In the pitch: "the hand you're dealt was mined by our Apify Actor". Coupon `APIFY_CAL_HACKS` ($200). Workshop at 11 AM in Breakout Room 3; the booth is on the ground floor, left. | **A new agent session** (leader assigns; `content/` belongs to whoever owns the bank) | **Done (Sat ~10:30 AM):** live on the Apify Store at https://apify.com/matusnator/epithet-miner. 55 of the bank's 213 formulas were mined (committed; the bank is 180 now, after modern phrases were cut for Homer's world, so 55 of 180), and the Devpost blurb is filled in. **Devpost split Apify into two entries again (Sat 4:17 PM): "[Apify] Best Use of Apify" and "[Apify] Best Actor sponsored by Apify" ($400): "a Best Actor award for building an actor for this event. Project must be using Apify in a meaningful way." Tag both.** Before that it had one entry, "[Apify] Best Use of Apify" (6 winners), and it covers Best Actor: "make sure to tag in your submission that is an actor". So the submission says "Epithet Miner is an Apify Actor, built with AI chat" (leader, Sat 12:30 PM). Apify staff want "the link and id" in the submission (#spons-apify, Sat 1:13 PM): Actor ID `v4i7ItNXjHMmnKzfo`, now in devpost.md. **Open:** ask Apify's staff whether an Actor built by an AI coding agent counts for Best Actor. Best Use is covered either way. |

### How-to: the Fetch.ai ASI:One fun challenges (every teammate, about 10 minutes)

1. On your phone, open **asi1.ai** and sign in, or get the ASI mobile app. Each teammate uses their own account, because each entry is a separate shot.
2. Go to the **Cal Hacks event page**: asi1.ai/launch?redirectPath=/festivals/calhacks2026/dashboard
3. **Do every "fun challenge" listed.** Round 1's were a "Hacker Personality Challenge" (the winner got Meta AI glasses) and an "AI Investor Challenge" (Beats). Each prize has 5 winners: Meta AI glasses, Beats, Kindles and Instax, plus a grand-prize trip.
4. Winners are announced in rounds in #spons-fetch-ai, and **four rounds remain** (Fri 8:49 PM). Collect your prize at the Fetch.ai booth.
5. Optional: code `CALHACKS26` gives a free month of ASI1 Pro.

Don't spend more than 15 minutes, and never during the battle checkpoints.

### Matus's line for Microsoft's engineers (after their 10:00–10:45 workshop, 20 s)

> "We built MeNIN: party games for your voice. Homer is a live agent on Claude that hears your verse through Cartesia and judges it in about a second, with a deterministic stress scanner, so the score isn't the model's opinion. It's production-minded: TestFlight now, the agent in Docker on DigitalOcean, and tonight we measure whether one lesson improves first-timers. We're entering Built for the Real World. What would make a project like this stand out to you?"

Write down their answer, and tell gtm.

## Tier 2: worth an agent if one is free

| # | Opportunity | Pays | What it takes | Honest odds |
| --- | --- | --- | --- | --- |
| 5 | **Fetch.ai: Best use** (main track) | $1,250 / $750 / $500, plus 2 × $250 (Slack); Devpost lists $1,500 / $1,000 / $500 | Wrap Homer's judge as an **Agentverse agent** with the Agent Chat Protocol, discoverable and usable in ASI:One: "send Homer a verse, get his verdict". It lives inside the agent service, so it isn't a fourth deployable. | **Live (Sat ~10:50 AM, checked by leader):** **@homer-bard** is active as a mailbox agent and listed with its README on Agentverse (registered with an API key from inside the container, `homer/scripts/agentverse_connect.py`). **Left:** Matus has one chat with it, for the video and the interaction count. Then the team submission in the ASI:One Submission agent, Sun 8:00–8:40 (run sheet). |
| 6 | **Moss** | **2 winners in total** (#spons-moss, Sat 9:27 AM): one for good use of Moss, one for best engagement. AirPods Pro or Max, plus interviews. | Their #1 example is "Voice AI: Voice agents that listen, respond, and act in real time". Use Moss retrieval to **deal formulas that fit the theme**, at retrieval speeds of a few milliseconds. Keep it behind a flag, with today's dealer as the fallback, so the demo path stays safe. Credits code `CALHACKS`. | **Shipped (Sat ~10:45 AM, builder):** `HOMER_DEALER=moss` is live on the droplet. Moss ranked all 213 formulas then (180 now), including the 55 Apify-mined, by meaning against the theme. Retrieval p50 13.7 ms and p95 32.2 ms on the 2 GB droplet; the whole deal p50 43 ms. A silent fallback to the tag dealer covers anything over 500 ms or an error, and both failures were tested live. The Devpost blurb is filled in. It stays on for judging (leader's call). |
| 7 | **MLH: Best Domain Name from GoDaddy Registry** (and the .Tech track) | Digital gift card | **A free domain now exists** (#1-ask-mlh, Sat 4:12 PM, MLH staff): mlh.link/godaddyregistry redirects to tech.study, where you redeem a domain with the provided code. Register playmenin.tech there and point it at the website. Neither MLH track is on Devpost yet, so tag it only if Devpost lists it Sunday. | High per minute; low value. **Matus's call** (registering is in his name) |

## Tier 3: only if we really use it

| # | Opportunity | Pays | The honest test |
| --- | --- | --- | --- |
| 8 | **Mana** | $5,000 cash | Needs "meaningful use of Mana while building": public links to the Mana chats or pages we used, plus a demo moment where Mana changed what we built. Only if someone really builds a piece in Mana. **Free on the side:** a Mana t-shirt brought to your table for a one-or-two-sentence idea at mana.space/a/mana-shirt, with your seat pinned (#spons-mana, Sat 12:17 PM, Mana staff). Two minutes, no tag needed. |
| 9 | **Notability** | A year of Notability Pro, plus merch | The poet runs tonight's study notes in Notability (handwriting plus the audio of each session), which really documents the process. The prize is small. |

## Requirements for the builds (gtm read the sponsors' own docs, Sat 9:40 AM)

### Apify: Epithet Miner (leader's agent builds it; requirements sent to leader)
- **The rule:** "Project must be using Apify in a meaningful way." Best Actor is "built with AI Chat".
- **The ambiguity:** Apify's own Console AI chat can't build or publish Actors, so "AI Chat" most likely means Claude through mcp.apify.com. That's unconfirmed. **Ask at the workshop or booth:** "Does Claude through mcp.apify.com count as AI Chat, and must the Actor be on the Store?"
- [x] The output really lands in the bank: 150 mined, pm kept 55, and the bank went from 158 to 213 (committed; 180 now, after modern phrases were cut for Homer's world)
- [x] How it was built is logged honestly in `apify/BUILD_LOG.md`: Claude Opus 5.5 in Claude Code on the Apify SDK and Crawlee, not through mcp.apify.com
- [x] `.actor/actor.json` has `"meta": {"templateId": "ai-generated-actor", "generatedBy": "Claude Opus 5.5 (Claude Code)"}`
- [x] **Published on the Apify Store:** https://apify.com/matusnator/epithet-miner (build 0.1.2, run on the platform, with an output schema; it loads logged out)
- [ ] Tag "[Apify] Best Use of Apify" on Devpost (one entry now covers both prizes), and write "Epithet Miner is an Apify Actor, built with AI chat" in the submission (done in devpost.md)
- [x] ~~The booth question, "Does an Actor built by an AI coding agent count for Best Actor?"~~ **Mostly settled by Devpost (Sat 4:17 PM):** the Best Actor entry now asks for "building an actor for this event", with no AI-chat condition. Epithet Miner was built here on Saturday.

### Fetch.ai: Homer on Agentverse (builder builds it; requirements sent to builder)
- **Mandatory** (hackpack): registered on Agentverse; speaks the Agent Chat Protocol; discoverable and usable in ASI:One; "meaningful tool execution or multi-agent orchestration"; "the primary user workflow entirely within an ASI:One conversation"; a public repo with run instructions; "more than a chatbot or a thin wrapper around an API".
- **Judging:** functionality 25%, use of Fetch tech 20%, innovation 20%, real-world impact 20%, UX 15%. Bonus for multi-agent work, the Payment Protocol, Interactive Cards, and an agent that keeps running after the event.
- **gtm's recommendation to builder:** a two-step flow in ASI:One. First, "give me a theme" deals five formulas. Then the user writes a verse and Homer judges it (scanner plus Claude). Optionally a separate dealer agent for the multi-agent bonus.
- [ ] The agent's README has its name and address, plus the Innovation Lab badges (`![tag:innovationlab](https://img.shields.io/badge/innovationlab-3D8BD3)` and `![tag:hackathon](https://img.shields.io/badge/hackathon-5F43F1)`)
- [ ] The agent is **running during judging**, with at least 10 interactions before Sunday ("only active, running Agents are prioritized")
- [ ] **A 3–5 minute demo video**, longer than our 2:00 Devpost video. The Fetch cut is in [video.md](video.md).
- [ ] **A second submission:** the "Cal Hacks ASI:One Submission agent" inside ASI:One. Matus chooses "Create team (I'm the lead)" and fills in project name, name, email, team size, problem, the public GitHub URL, the Devpost URL and the demo video URL. Bonus fields: the Agentverse profile URL and ASI:One shared-chat URLs. **Every teammate joins with the Team ID**, and the status must read "Submitted".
- [ ] The Devpost tag
- Code `CALHACKS26AV` gives Agentverse Premium.

### Moss: theme-fitting dealing (builder, after Fetch)
- **No rubric or Moss-specific submission step is published.** Their first example is "Voice agents that listen, respond, and act in real time." Tag it on Devpost, which is unconfirmed but the likely route.
- [x] Moss retrieval really runs in the dealer (theme in, formulas out), behind `HOMER_DEALER=moss`, with a tested silent fallback
- [x] Latency measured on the production droplet: p50 13.7 ms, p95 32.2 ms over 60 queries (1.4 ms on a MacBook). It's in the blurb.
- [x] Account and keys are set on the droplet
- [x] **Leader's call (Sat ~11 AM): Moss stays on for everything, judging included.** The fallback keeps the SPEC rule. Since SPEC 7866476 the themes are fresh every round, so the poets rehearse improvising on unseen themes, and the pitch line is "Homer's phrases were dealt by Moss".
- [ ] *(Optional; Matus's call)* A social post for their engagement prize. Its rules are unconfirmed, and a hacker's question about it is unanswered.

## Already entered (for completeness)

Spacetime (Best Use, on Devpost since Sat ~12 PM) · Cartesia · Meta (top submissions also get "Round 2: Meta AI Hackathon" and an "All-expenses-paid trip to Meta Global HQ in Menlo Park!", #0-announcements, Sat 1:51 PM) · Anthropic (Claude for Public Benefit, on Devpost since Sat ~12 PM) · Figma (one Devpost entry since Sat ~2 PM, "[Figma] Best Figma Workflow Hack"; the brief still lists 4 prizes) · MLH Gen AI · MLH .Tech domain · MLH DigitalOcean (these three are on Hive, not yet on Devpost) · MLH Commit Fellowship · every Cal Hacks main prize (automatic): First, Second and Third Overall, Most Creative, Most Technically Complex, Best People-First, Hacker's Choice.

## Skipped, with the reason

| Opportunity | Why not |
| --- | --- |
| SpaceXAI "Make it Legendary" and MLH "A-Team with SpaceXSI" | They require Cursor as the core coding agent plus Grok. We build with Claude Code, so entering would be false. |
| MLH ElevenLabs | Competes with Cartesia, our core voice |
| Convex | A second real-time backend would undercut the Spacetime story |
| Bright Data | Their judges want products that break without live web data. Ours doesn't. |
| MLH Presage, Auth0, Backboard | Each is scope creep (a camera, accounts, memory) for a small prize |
| Bitdeer | Only if a model really ran there, and none does |
| Finance and shopping tracks (Hyphenate, Visa, Coinbase, CRS, Capital One) | No fit |
| Supercell Clash Royale | The tournament ended Fri 10:35 PM, and only the top 8 play tonight's finale |
| Capital One Smash | 32 entrants picked at random, and the prize is swag. It started at 12 PM at Gate 4, and others can wait for no-show spots (#spons-capital-one, Sat 12:01 PM), but that overlaps the gate run. |

## Watch list

- **Anthropic, Annapurna Labs and AfterQuery** show "Coming soon!" on Hive. New tracks may appear; gtm checks each sweep.
- **Spacetime's startup program** offers up to $50k in credits for eligible startups (#cohost-spacetime, Oct 21). It's for after the hackathon, if MeNIN continues.
- **The Moss social-post prize and the Hacker's Choice clips** can be the same posts. Posting is Matus's call.
- **Merch:** stickers and postcards at the info desk now, and the 4 PM distribution is the last merch pickup (#0-announcements, Sat 11:57 AM; "Merch distribution #2 @ 4", #0-ask-directors, Sat 1:12 PM; organizers). Anyone passing grabs them.
- **Capital One rock contest:** bring "the coolest rock" to their booth by 3 PM for a 40 oz tumbler (#spons-capital-one, Sat 1:58 PM, sponsor staff). Free, a minute. Anyone passing.
- **Credits on offer we don't need:** Bitdeer about $50 (inference API only), Factory $20, Bright Data $300, Google Cloud $300, Convex on request. None of them touches our stack, so we skip them.
- **Free merch now:** a t-shirt, a tote, stickers and a postcard at Annapurna (Sleep) Labs, 4 to 5:30 PM, no reservation (#0-announcements, Sat 4:04 PM). The Souvenir Shop for Terminal Tasks points opened at 4:15. The Fetch-a-donut mixer is at 4:30 PM, with the ASI:One app (#spons-fetch-ai, 4:07 PM).
- **Wajo "Fo Prompt Challenge":** $10,000 for the most-reused prompt published on Fo. It launches on X on Mon Oct 26 at 10:15 AM PT, after the hackathon (luma.com/znl1y5bm; wajo.ai/join?code=FOPROMPT; #spons-wajo-ai, Sat 4:02 PM). Matus's call.
- **Cartesia's promo code needs cancelling:** `CARTESIACALHACKS` "zeros the first month" of a paid plan, but "a card is still required", so cancel before renewal (#spons-cartesia, Sat 3:59 PM). It goes on Matus's post-hackathon list.
- **Credits we haven't used:** Moss `CALHACKS` ($100, Moss Portal billing page; #spons-moss, Sat 11:03 AM) keeps the live dealer funded through judging if our plan has limits (builder). Apify's coupon is $200, not $5 (#spons-apify, Sat 10:22 AM).
