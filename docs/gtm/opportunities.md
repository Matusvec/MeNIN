# Opportunities board

Every prize, side tournament and challenge at Cal Hacks 13.0, ranked by **what it pays, what it costs us and who can do it**. Built Sat 9:15 AM from all 58 prizes on Hive, the Devpost prize list and every sponsor channel in Slack. gtm keeps it current with each Slack sweep.

**The rules that shape it:**
- **One project per team** (#1-ask-mlh, Fri 7:47 PM, MLH). Every sponsor track is a tag on MeNIN.
- **There's no cap on tags** (#0-ask-directors, organizers).
- Side competitions like Scrabblebot and the Fetch.ai fun challenges aren't projects, so they're fair game.
- **A tag has to be true.** Never enter a track with a bolt-on we'd have to fake. A judge who checks a fake loses us the track and the trust.
- **The agents are the cheap labor.** A side quest that a Claude session can run alone, without touching the demo path or a human's time, is almost free. Say yes to those.

## Tier 1: do now

| # | Opportunity | Pays | What it takes | Who | Status |
| --- | --- | --- | --- | --- | --- |
| 1 | **Spacetime Scrabblebot tournament** | $1,024 / $512 / $256 | A bot on scrabblebot.spacetimedb.com. **Finals Sat 11:59 PM in the Theater, in person.** Don't start a new bot version late: it's provisional for 20–30 matches. | scrabble session, plus one human in the Theater at midnight | **In progress.** gtm sent it the Slack facts. |
| 2 | **Fetch.ai ASI:One fun challenges** | 5 each of **Meta AI glasses, Beats, Kindles, Instax**, plus a grand-prize trip | About 10 minutes per person on a phone: asi1.ai → the Cal Hacks event page (asi1.ai/festivals/calhacks2026/dashboard). Round 1 had a "Hacker Personality Challenge" and an "AI Investor Challenge". **Four more winner rounds remain.** Collect at the Fetch booth. | **Every teammate**, each on their own account | Not started. No build, and each teammate counts separately. |
| 3 | **Microsoft: Built for the Real World** (and the Customer Impact Award) | **A Surface laptop per team member**, a tech talk and mentorship | Tag MeNIN on Devpost. Their brief: "a production-minded AI agent that solves a meaningful problem in… another high-impact domain", judged on customer understanding, measurable usefulness, a path from prototype to production, responsible design and end-to-end functionality. We already document all five, so add one Devpost paragraph that maps to them. Azure isn't required. | gtm (the paragraph); Matus is at their workshop 10:00–10:45 in the Theater, so talk to their engineers after | Paragraph ready in [devpost.md](devpost.md). Tag it. |
| 4 | **Apify: Best use** (5 places) **plus Best Actor** | $2,000 / $1,000 / $800 / $400 / $400, plus $400 for the best Actor "built with AI Chat" | An **Apify Actor that builds our formula bank**: it mines public-domain Homer translations (Project Gutenberg) for epithets and formulas into `content/formulas.json`, which the game deals from. Build it with Apify's AI Chat or MCP (mcp.apify.com works in Claude). Publish the Actor. In the pitch: "the hand you're dealt was mined by our Apify Actor". Coupon `APIFY_CAL_HACKS` ($200). Workshop at 11 AM in Breakout Room 3; the booth is on the ground floor, left. | **A new agent session** (leader assigns; `content/` belongs to whoever owns the bank) | Not started. Five places plus the Actor prize give it the best odds per hour on this board. |

## Tier 2: worth an agent if one is free

| # | Opportunity | Pays | What it takes | Honest odds |
| --- | --- | --- | --- | --- |
| 5 | **Fetch.ai: Best use** (main track) | $1,250 / $750 / $500, plus 2 × $250 (Slack); Devpost lists $1,500 / $1,000 / $500 | Wrap Homer's judge as an **Agentverse agent** with the Agent Chat Protocol, discoverable and usable in ASI:One: "send Homer a verse, get his verdict". It lives inside the agent service, so it isn't a fourth deployable. | Medium-low. Agent projects crowd this field, but ours would be the only poet. |
| 6 | **Moss** | AirPods Pro or Max, a separate **best social-post** prize, and interviews | Their #1 example is "Voice AI: Voice agents that listen, respond, and act in real time". Use Moss retrieval to **deal formulas that fit the theme**, at retrieval speeds of a few milliseconds. Keep it behind a flag, with today's dealer as the fallback, so the demo path stays safe. Credits code `CALHACKS`. | Medium. Voice is their first example. |
| 7 | **MLH: Best Domain Name from GoDaddy Registry** | Digital gift card | Register one cheap domain from a GoDaddy Registry TLD and point it where playmenin.tech points. Ask the MLH coach at 9:45 which TLDs count, and whether there's a free code. | High per minute; low value |

## Tier 3: only if we really use it

| # | Opportunity | Pays | The honest test |
| --- | --- | --- | --- |
| 8 | **Mana** | $5,000 cash | Needs "meaningful use of Mana while building": public links to the Mana chats or pages we used, plus a demo moment where Mana changed what we built. Only if someone really builds a piece in Mana. |
| 9 | **Notability** | A year of Notability Pro, plus merch | The poet runs tonight's study notes in Notability (handwriting plus the audio of each session), which really documents the process. The prize is small. |

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
