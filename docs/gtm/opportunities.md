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
| 1 | **Spacetime Scrabblebot tournament** | $1,024 / $512 / $256 | A bot on scrabblebot.spacetimedb.com. **Finals Sat 11:59 PM in the Theater, in person.** The leaderboard rating plays no part in the tournament (the scrabble session checked the module source). Round 1 is paired at random, later rounds by Swiss points, and the cut is by Swiss points, then total score. So late rewrites are safe. Our bot is "Menice": about 45 live matches by Sat 10 AM, rating 1441 (which doesn't matter for the tournament), and it's running A/B experiments. It auto-registers for any tournament in Registration status. The module has no Devpost dependency, so we assume no Devpost submission is needed; awaiting the staff answer. | scrabble session, plus one human in the Theater at midnight | **In progress** (the scrabble session builds it; gtm feeds it intel). **Who goes to the Theater at midnight?** |
| 2 | **Fetch.ai ASI:One fun challenges** | 5 each of **Meta AI glasses, Beats, Kindles, Instax**, plus a grand-prize trip | About 10 minutes per person on a phone: asi1.ai → the Cal Hacks event page (asi1.ai/festivals/calhacks2026/dashboard). Round 1 had a "Hacker Personality Challenge" and an "AI Investor Challenge". **Four more winner rounds remain.** Collect at the Fetch booth. | **Every teammate**, each on their own account | **Green-lit by Matus.** Leader is telling the team; every teammate enters. gtm tracks the winner rounds in #spons-fetch-ai. |
| 3 | **Microsoft: Built for the Real World** (and the Customer Impact Award) | **A Surface laptop per team member**, a tech talk and mentorship | Tag MeNIN on Devpost. Their brief: "a production-minded AI agent that solves a meaningful problem in… another high-impact domain", judged on customer understanding, measurable usefulness, a path from prototype to production, responsible design and end-to-end functionality. We already document all five, so add one Devpost paragraph that maps to them. Azure isn't required. | gtm (the paragraph); Matus is at their workshop 10:00–10:45 in the Theater, so talk to their engineers after | **gtm owns it.** The Devpost section is done, and Matus's 20 s line is below. Tag it at submission. |
| 4 | **Apify: Best use** (5 places) **plus Best Actor** | $2,000 / $1,000 / $800 / $400 / $400, plus $400 for the best Actor "built with AI Chat" | An **Apify Actor that builds our formula bank**: it mines public-domain Homer translations (Project Gutenberg) for epithets and formulas into `content/formulas.json`, which the game deals from. Build it with Apify's AI Chat or MCP (mcp.apify.com works in Claude). Publish the Actor. In the pitch: "the hand you're dealt was mined by our Apify Actor". Coupon `APIFY_CAL_HACKS` ($200). Workshop at 11 AM in Breakout Room 3; the booth is on the ground floor, left. | **A new agent session** (leader assigns; `content/` belongs to whoever owns the bank) | **Done (Sat ~10:30 AM):** live on the Apify Store at https://apify.com/matusnator/epithet-miner. 55 of the bank's 213 formulas are mined (committed), and the Devpost blurb is filled in. **Open:** ask Apify's staff whether an Actor built by an AI coding agent counts for Best Actor. Best Use (5 places) is covered either way. |

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
| 5 | **Fetch.ai: Best use** (main track) | $1,250 / $750 / $500, plus 2 × $250 (Slack); Devpost lists $1,500 / $1,000 / $500 | Wrap Homer's judge as an **Agentverse agent** with the Agent Chat Protocol, discoverable and usable in ASI:One: "send Homer a verse, get his verdict". It lives inside the agent service, so it isn't a fourth deployable. | Medium-low. Agent projects crowd this field, but ours would be the only poet. **Built and running on the droplet (builder, Sat ~9:50 AM):** agent `homer-bard`, address `agent1qf8cydj43pd7tue06mk9avnp45avcc4ss9gjm98r4lkjczsw0gskzw97edc`. It publishes the Chat Protocol manifest and is registered on the Almanac. The two-step flow (deal, then judge) runs inside one ASI:One chat, and its README with both badges is homer/AGENTVERSE.md. **Waiting on Matus:** the one-time mailbox Connect and the handle (suggested: @homer-bard). Then builder sends the ASI:One link. No separate dealer agent, because it would be orchestration for show. |
| 6 | **Moss** | **2 winners in total** (#spons-moss, Sat 9:27 AM): one for good use of Moss, one for best engagement. AirPods Pro or Max, plus interviews. | Their #1 example is "Voice AI: Voice agents that listen, respond, and act in real time". Use Moss retrieval to **deal formulas that fit the theme**, at retrieval speeds of a few milliseconds. Keep it behind a flag, with today's dealer as the fallback, so the demo path stays safe. Credits code `CALHACKS`. | Medium. Voice is their first example. **Built behind `HOMER_DEALER=moss`** (builder), with metadata flattened to strings. **Waiting on Matus:** a Moss portal account (code `CALHACKS`), with `MOSS_PROJECT_ID` and `MOSS_PROJECT_KEY` put straight into the droplet's `.env`, never pasted into chat. Then builder measures the latency. |
| 7 | **MLH: Best Domain Name from GoDaddy Registry** | Digital gift card | Register one cheap domain from a GoDaddy Registry TLD and point it where playmenin.tech points. Ask the MLH coach at 9:45 which TLDs count, and whether there's a free code. | High per minute; low value |

## Tier 3: only if we really use it

| # | Opportunity | Pays | The honest test |
| --- | --- | --- | --- |
| 8 | **Mana** | $5,000 cash | Needs "meaningful use of Mana while building": public links to the Mana chats or pages we used, plus a demo moment where Mana changed what we built. Only if someone really builds a piece in Mana. |
| 9 | **Notability** | A year of Notability Pro, plus merch | The poet runs tonight's study notes in Notability (handwriting plus the audio of each session), which really documents the process. The prize is small. |

## Requirements for the builds (gtm read the sponsors' own docs, Sat 9:40 AM)

### Apify: Epithet Miner (leader's agent builds it; requirements sent to leader)
- **The rule:** "Project must be using Apify in a meaningful way." Best Actor is "built with AI Chat".
- **The ambiguity:** Apify's own Console AI chat can't build or publish Actors, so "AI Chat" most likely means Claude through mcp.apify.com. That's unconfirmed. **Ask at the workshop or booth:** "Does Claude through mcp.apify.com count as AI Chat, and must the Actor be on the Store?"
- [x] The output really lands in the bank: 150 mined, pm kept 55, and the bank went from 158 to 213 (committed)
- [x] How it was built is logged honestly in `apify/BUILD_LOG.md`: Claude Opus 5.5 in Claude Code on the Apify SDK and Crawlee, not through mcp.apify.com
- [x] `.actor/actor.json` has `"meta": {"templateId": "ai-generated-actor", "generatedBy": "Claude Opus 5.5 (Claude Code)"}`
- [x] **Published on the Apify Store:** https://apify.com/matusnator/epithet-miner (build 0.1.2, run on the platform, with an output schema; it loads logged out)
- [ ] Tag both Apify prizes on Devpost (ready; done at submission)
- [ ] **Still open:** the booth question, "Does an Actor built by an AI coding agent count for Best Actor?"

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
- [ ] Moss retrieval really runs in the dealer (theme in, formulas out), behind its switch
- [ ] Measure the latency and put the number in the Devpost blurb (their claim: sub-10 ms)
- [ ] Matus creates the account at portal.usemoss.dev and enters code `CALHACKS` on the billing page
- [ ] *(Optional; Matus's call)* A social post for their engagement prize. Its rules are unconfirmed, and a hacker's question about it is unanswered.

## Already entered (for completeness)

Spacetime (Best Use) · Cartesia · Meta · Anthropic · Figma (4 prizes) · MLH Gen AI · MLH .Tech domain · MLH DigitalOcean · MLH Commit Fellowship · every Cal Hacks main prize (automatic): First, Second and Third Overall, Most Creative, Most Technically Complex, Best People-First, Hacker's Choice.

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
| Capital One Smash | 32 entrants picked at random, and the prize is swag |

## Watch list

- **Anthropic, Annapurna Labs and AfterQuery** show "Coming soon!" on Hive. New tracks may appear; gtm checks each sweep.
- **Spacetime's startup program** offers up to $50k in credits for eligible startups (#cohost-spacetime, Oct 21). It's for after the hackathon, if MeNIN continues.
- **The Moss social-post prize and the Hacker's Choice clips** can be the same posts. Posting is Matus's call.
