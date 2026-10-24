# Figma Make and Figma agent: 10 minutes for Matus

Why: the Figma prizes ("Best Workflow", "Best Use Case of Figma Agent", "Most Creative Use Case of Figma Agent") want Figma's own AI used for something real. The artist session's MCP can create and seed a Make file and read results back, but it can't prompt Make's AI or the Figma agent. That step is yours, and it's the story anyway: you drive the AI, it doesn't drive you.

The setup is done. "MeNIN · Discus (Make)" already holds a playable sketch of the discus screens built on our tokens (the CSS variables = Figma variables = `Palette` in Swift).

## Steps

**1 · Open and play it (1 min).** Open https://www.figma.com/make/MexcUVEohKsNVAw5pHh596 and wait for the preview. Press and hold the discus on the left, let go, and watch the arena on the right fly the throw.

**2 · Prompt one, the arena (3 min).** In Make's chat, paste:

> This is the Discus event from MeNIN, an ancient-Greek party-game app (one shared screen, phones as controllers). Keep the CSS variables in styles.css as the design tokens: matte, flat fills, hairlines, no glow, no gradients, Bodoni Moda + Inter. Redesign only the arena side as a title-fight broadcast: a much bigger distance number, a stadium band for the field, the thrower's name plate slamming in, and a stamp when a throw passes Phayllos's 29 m flag. Keep it playable.

**3 · Prompt two, the phone (3 min).** Paste:

> Now the phone side: make the discus feel physical, like matte cut paper with a thumb-print target, and make the power ring readable from across a table. Add a "foul" state when the swing is too hard ("Into the crowd").

**4 · Pick (1 min).** Use the version history (the clock icon) to compare. If the first take was better, restore it. If neither is better than the seed, say so; that's a valid result.

**5 · Optional, Figma agent in Design (1 min).** Open https://www.figma.com/design/qyaXnV3HbIUPIfYVbyqKwv, page "Prototype · Atelier", and select the frame "7 · Arena · turn". In the AI or agent panel, ask:

> Suggest three layout variations of this frame using only the components and variables already in this file.

Keep one if it's good.

**6 · Capture (1 min).** Screenshot each prompt and its result. They go in the Figma Slides stage log.

**7 · Hand back.** Tell the artist session "Make is done" (and which version won, if it wasn't the latest). It reads the Make file through the MCP and ports the winning ideas into the SwiftUI discus views (`ios/Homer/UI/Discus/`). Then it logs what Make changed and what we kept or rejected.

## Notes

- Make uses Figma AI credits. If the student plan runs out, note that in the stage log; it's honest friction.
- Share both files with "Anyone" (Share → Anyone with the link → can view). The Figma deck must embed them.
