# Figma deck: the clicks only Matus can do

The deck is **MeNIN · Stage log (Figma track)**: https://www.figma.com/slides/oYPLd3JeIjhnkNyt75qfOm

The artist session built everything the Figma MCP can reach (Sun Oct 25, 03:20–03:50). The Plugin API can't create embeds, change sharing or add a video, so those steps are below, in order. They take about 10 minutes in the Slides app.

## The clicks, in order

1. **Share the deck.** Open the deck, then **Share** (top right) → under "Who has access", **Anyone with the link** → **can view** → **Copy link**.
   Figma's public oEmbed check already returns 200 for the deck (03:45), so this may already be set. Confirm it in the dialog anyway.

2. **Slide 16, "The prototype": embed both flows.**
   - Flow 1, first open → practice → verdict: https://www.figma.com/proto/qyaXnV3HbIUPIfYVbyqKwv?node-id=15-102&starting-point-node-id=15%3A102
   - Flow 2, join → arena → champion: https://www.figma.com/proto/qyaXnV3HbIUPIfYVbyqKwv?node-id=15-364&starting-point-node-id=15%3A364

   Copy flow 1's link, click the slide and paste (⌘V). If Slides asks, choose **Embed**. If the paste only makes a text link, use the toolbar's **Insert → Embed** and paste the link there. Drag the embed over the three phone screenshots at the top right and size it to cover them. Do the same for flow 2 over the laptop screenshot at the bottom right. Once both play in Present mode, delete the screenshots underneath (or keep them as a fallback).

3. **Slide 17, "Two directions, one switch": embed the Directions file.** https://www.figma.com/design/qyaXnV3HbIUPIfYVbyqKwv
   Paste the link the same way and place the embed over the two Home screenshots on the left. To land on the Atelier → Hall flip frame instead of the file's first page, use https://www.figma.com/design/qyaXnV3HbIUPIfYVbyqKwv/?node-id=36-128

4. **Slide 3, "The demo": the video.** Paste the YouTube link of the 3:00 cut onto the slide and choose **Embed**. If Slides won't embed YouTube, drag the final MP4 onto the slide instead, since Slides plays uploaded video. Then delete the "[video embed]" chip and the poster (the C1 title card) under it.

5. **Optional: the website's Make file.** Figma asks for "your Figma files (Make(s) and/or Figma prototypes)" to be embedded. The prototypes in step 2 cover that, but the website's Make file is its whole Figma path: https://www.figma.com/make/0o7GzG4KEQejktGJeUuNbt/MeNIN
   There's no free space for it on slide 9 ("Stage II · the website"). Add a slide after 9 (⌘D on slide 9, then delete its contents) and paste the link there as an embed.

6. **Check sharing on the other files.** Each one already passes the logged-out oEmbed check (03:45). Confirm "Anyone with the link → can view" in each Share dialog:
   - FigJam "MeNIN · How it works (video card C2)": https://www.figma.com/board/c8DkYceOjp3OJ7PPLeYUcn
   - The website's Make file (confirm in its owner's Share dialog): https://www.figma.com/make/0o7GzG4KEQejktGJeUuNbt/MeNIN
   - Matus's concept file: https://www.figma.com/design/zBILNwJB2NaVofBNJouAOW

7. **Test as a judge.** Open the deck link in a private window, logged out. Present from slide 1 and check that every embed loads and every "Open ↗" link opens.

## What's in the deck now (19 slides)

| # | Slide | Status |
|---|---|---|
| 1 | Title | Team line is now "Matus · Sunya · Paul" |
| 2 | The problem | Unchanged |
| 3 | The demo · 3:00 | **New.** Poster plus "[video embed]" stand-in (step 4) |
| 4 | The workflow | Headline is now "Two designers, a team of agents, Figma in the middle." The designers box ends "Paul and Sunya build the website in Figma Make." The website box reads "The website's Figma Make app, exported to GitHub · builder session". The Figma box now says three modes (Atelier, Cut paper, Hall) |
| 5 | How a turn works · FigJam | **New.** The FigJam 4-box diagram (Your voice → Cartesia → SpacetimeDB → Claude + Homer's voice), with the board link |
| 6, 8, 10, 12 | Stages I–IV · the app | The stage line now ends "· the app". Slide 8 now says three modes |
| 7, 9, 11, 13 | Stages I–IV · the website | **New.** The website's path, stage text from Sunya's log, in the website's own palette, facing the app slide: the Figma AI agent (45 min, 5/5), Figma Make (90 min, 4/5), Make export + GitHub (20 min, 5/5), Claude Code on the Make output (120 min, 4/5). Minutes are estimates from Sunya's log |
| 14 | One hall, two codebases | **New.** Where the two paths meet: the Hall mode. Stand-in: hall-flip-atelier-to-hall.png |
| 15 | The designer in the loop | **New.** The four rounds of scene feedback and the buttons. Stand-ins: hall-turn-promax.png, hall-join-promax.png |
| 16 | The prototype | Unchanged. Embeds go here (step 2) |
| 17 | Two directions, one switch | Unchanged. Embed goes here (step 3) |
| 18 | Before and after | Unchanged |
| 19 | The files | **New.** Every Figma file with an "Open ↗" link, plus the stack |

Slide 4's Figma box and slide 8's tool text now say "three modes (Atelier, Cut paper, Hall)". Slide 8's "What made it in" keeps "23 colors in two modes", with "(Hall, the third, came Saturday night)" added, because that was the count at that stage. Slide 17 still compares two looks, which is right for that slide.

Who ran Figma Make and the Figma AI agent for the website is for Matus to confirm. Until then, the deck credits "the website's path", with the stage text "from Sunya's log".
