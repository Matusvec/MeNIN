// The wind for this arrow (artist), as GamePigeon's archery shows it: a big arrow
// pointing the way it blows, turning when the wind changes, and the speed in m/s.
// The pennants in Range.tsx blow with the same wind.

import type { CSSProperties } from 'react'
import type { ToxWind } from './Range'

export default function WindVane({ wind }: { wind: ToxWind | null }) {
  if (!wind) return null
  const still = wind.speed < 0.3
  return (
    <div className={`tox-wind${still ? ' still' : ''}`} role="img" aria-label={still ? 'No wind' : `Wind ${wind.speed.toFixed(1)} metres a second`}>
      <span className="tox-wind-label">Wind</span>
      <svg className="vane" viewBox="-60 -60 120 120" aria-hidden="true" style={{ '--toward': `${-wind.toward}deg` } as CSSProperties}>
        <circle r="56" className="vane-dial" />
        <g className="vane-arrow">
          <rect x="-40" y="-7" width="62" height="14" rx="3" />
          <polygon points="18,-22 50,0 18,22" />
          <path d="M-40 -7 l-12 -12 h14 l10 12 Z M-40 7 l-12 12 h14 l10 -12 Z" />
        </g>
      </svg>
      <b>{still ? '0' : wind.speed.toFixed(1)}</b>
      <small>m/s</small>
    </div>
  )
}
