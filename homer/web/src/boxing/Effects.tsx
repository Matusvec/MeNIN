// The fight's effects (artist), cut paper like the figures: the spark at the point
// of impact, with flecks thrown off on a big hit, gold on a counter; and the dust
// a knocked-out fighter raises when he hits the floor. boxing.css animates them.
// Builder places them: <Spark key={punch.id} … /> over the .ring, <Dust key={…} side … />
// in it.

import type { CSSProperties } from 'react'

/** Angle (deg), distance (× the throw), size of each fleck: spread all round, a few long. */
const FLECKS: Array<[number, number, number]> = [
  [-8, 1, 1], [34, 0.7, 0.7], [71, 0.95, 0.9], [118, 0.65, 0.6], [152, 1.05, 1],
  [196, 0.75, 0.75], [229, 0.9, 0.85], [271, 0.6, 0.65], [311, 1, 0.95], [343, 0.8, 0.7],
]

/** x, y: the point of impact, 0…1 of the ring. power: the punch's damage over 16. */
export function Spark({ x, y, power = 0.5, counter = false }: { x: number; y: number; power?: number; counter?: boolean }) {
  const big = counter || power >= 0.7
  return (
    <span className={`spark${big ? ' big' : ''}${counter ? ' counter' : ''}`} style={{ '--x': x, '--y': y } as CSSProperties}>
      {big &&
        FLECKS.map(([a, d, s], i) => (
          <i key={i} className={i % 3 === 0 ? 'ink' : undefined} style={{ '--a': `${a}deg`, '--d': d, '--s': s } as CSSProperties} />
        ))}
    </span>
  )
}

/** Horizontal offset (rem from the impact), size, delay (s) of each puff. */
const PUFFS: Array<[number, number, number]> = [
  [-4.5, 0.8, 0.04], [-2.6, 1.15, 0], [-0.8, 1.35, 0.02], [1.2, 1.1, 0.05], [3.2, 0.85, 0.08], [5, 0.6, 0.1],
]

/** The dust under a fighter going down: side a falls to the left, b to the right. */
export function Dust({ side }: { side: 'a' | 'b' }) {
  return (
    <span className={`dust ${side}`} aria-hidden="true">
      {PUFFS.map(([x, s, d], i) => (
        <i key={i} style={{ '--x': `${side === 'a' ? -x : x}rem`, '--s': s, '--d': `${d}s` } as CSSProperties} />
      ))}
    </span>
  )
}
