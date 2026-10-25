// The events, for the screens that present them (the hall's strip, the arena's event board).
// SPEC "The games". The arena's own logic keys on GameEvent; this is only how they look and read.

import type { GameEvent } from './arena'

export type EventInfo = {
  id: GameEvent
  name: string
  host: string
  /** One line: what you do and how it's judged. */
  line: string
  beta?: boolean
}

export const EVENTS: EventInfo[] = [
  { id: 'poetry', name: 'Poetry battle', host: 'Homer', line: 'Spit verse on a theme. Homer scores Image, Answer and Craft' },
  { id: 'coach', name: 'Talk to Homer', host: 'Homer', line: 'Say a verse. He quotes you, gives one fix, scores it' },
  { id: 'debate', name: 'Socratic debate', host: 'Socrates', line: 'Argue a question in timed turns. Socrates judges' },
  { id: 'discus', name: 'Discus', host: 'Homer announces', line: 'Swing your phone to throw. Angle, speed and spin count' },
  { id: 'stadion', name: 'Stadion', host: 'Homer announces', line: 'Pump your arms to sprint. Everyone races at once' },
  // Beta: live for Matus's first real fights (build 20); scripted runs follow.
  { id: 'pygmachia', name: 'Pygmachia', host: 'Homer announces', line: 'Box with your phone: punch, block, counter', beta: true },
  // Beta: module on prod 18:20; a scripted run passed 18:34 (2 archers, 6 arrows); Matus's real runs next.
  { id: 'toxeia', name: 'Toxeia', host: 'Homer announces', line: 'The camera tracks your bow arm. Draw back, and loose with your phone', beta: true },
]
