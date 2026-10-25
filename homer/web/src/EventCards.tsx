// The arena's event board: one card per event, each with its emblem, host and a line on how it
// plays. The first card is featured. Used to open the hall and, compact, for "New event".

import type { CSSProperties } from 'react'
import type { GameEvent } from './lib/arena'
import { EVENTS, type EventInfo } from './lib/events'
import './events.css'

/** Simple emblems in the black-figure spirit: one silhouette per event. */
function Emblem({ id }: { id: GameEvent }) {
  switch (id) {
    case 'poetry': // a lyre
      return (
        <svg viewBox="0 0 48 48" aria-hidden="true">
          <path d="M13 8c-4 6-4 16 2 22l1 6h16l1-6c6-6 6-16 2-22l-3 2c3 5 3 12-2 17h-3V12h-2v15h-4V12h-2v15h-3c-5-5-5-12-2-17z" />
          <rect x="13" y="37" width="22" height="4" rx="2" />
        </svg>
      )
    case 'coach': // Homer listening: a speech mark
      return (
        <svg viewBox="0 0 48 48" aria-hidden="true">
          <path d="M8 12a6 6 0 0 1 6-6h20a6 6 0 0 1 6 6v14a6 6 0 0 1-6 6H22l-9 8v-8h1a6 6 0 0 1-6-6z" />
          <path d="M17 16h14M17 22h9" stroke="#fff" strokeWidth="3" strokeLinecap="round" />
        </svg>
      )
    case 'debate': // two voices facing off
      return (
        <svg viewBox="0 0 48 48" aria-hidden="true">
          <path d="M4 10a5 5 0 0 1 5-5h16a5 5 0 0 1 5 5v9a5 5 0 0 1-5 5h-9l-7 6v-6a5 5 0 0 1-5-5z" />
          <path d="M44 22a5 5 0 0 0-5-5h-6v4a8 8 0 0 1-8 8h-4v1a5 5 0 0 0 5 5h8l7 6v-6a5 5 0 0 0 3-5z" opacity="0.7" />
        </svg>
      )
    case 'discus': // the disc, spinning
      return (
        <svg viewBox="0 0 48 48" aria-hidden="true">
          <ellipse cx="24" cy="24" rx="17" ry="11" transform="rotate(-20 24 24)" />
          <ellipse cx="24" cy="24" rx="7" ry="4.5" transform="rotate(-20 24 24)" fill="#fff" opacity="0.85" />
          <path d="M5 34c4 4 9 6 15 6M43 14c-4-4-9-6-15-6" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" />
        </svg>
      )
    case 'stadion': // a runner mid-stride
      return (
        <svg viewBox="0 0 48 48" aria-hidden="true">
          <circle cx="29" cy="8" r="4.5" />
          <path d="M27 14l-7 8 5 5-4 12M27 14l5 9 7 1M20 22l-8 2M25 27l7 6 2 8" fill="none" stroke="currentColor" strokeWidth="4.5" strokeLinecap="round" strokeLinejoin="round" />
        </svg>
      )
    case 'pygmachia': // a wrapped fist
      return (
        <svg viewBox="0 0 48 48" aria-hidden="true">
          <path d="M12 18a5 5 0 0 1 5-5h14a7 7 0 0 1 7 7v8a10 10 0 0 1-10 10h-6a10 10 0 0 1-10-10z" />
          <path d="M18 13v10M24 13v10M30 14v9" stroke="#fff" strokeWidth="2.5" strokeLinecap="round" />
          <rect x="15" y="38" width="16" height="5" rx="2" />
        </svg>
      )
    case 'toxeia': // the target and an arrow
      return (
        <svg viewBox="0 0 48 48" aria-hidden="true">
          <circle cx="22" cy="26" r="16" />
          <circle cx="22" cy="26" r="10" fill="#fff" opacity="0.85" />
          <circle cx="22" cy="26" r="4.5" />
          <path d="M22 26L42 6M36 6h6v6" fill="none" stroke="currentColor" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round" />
        </svg>
      )
  }
}

export default function EventCards({
  events = EVENTS,
  disabled = false,
  compact = false,
  onPick,
}: {
  events?: EventInfo[]
  disabled?: boolean
  /** The "New event" picker: no featured card, smaller tiles. */
  compact?: boolean
  onPick: (event: GameEvent) => void
}) {
  return (
    <div className={`event-board${compact ? ' compact' : ''}`}>
      {events.map((event, i) => {
        const featured = !compact && i === 0
        return (
          <button
            key={event.id}
            type="button"
            className={`event-card${featured ? ' featured' : ''}`}
            style={{ '--accent': event.accent } as CSSProperties}
            disabled={disabled}
            onClick={() => onPick(event.id)}
          >
            <span className="event-emblem">
              <Emblem id={event.id} />
            </span>
            <span className="event-text">
              <span className="event-meta">
                {featured && <em className="event-tag start">Start here</em>}
                {event.beta && <em className="event-tag beta">Beta</em>}
                <span className="event-host">{event.host}</span>
              </span>
              <strong className="event-name">{event.name}</strong>
              {!compact && <span className="event-line">{event.line}</span>}
            </span>
            <span className="event-go" aria-hidden="true">›</span>
          </button>
        )
      })}
    </div>
  )
}
