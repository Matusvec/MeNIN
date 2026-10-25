// The events (SPEC "The games"), on one strip: what each one is and how you play it.
// Played with phones as controllers; watched on this screen. The list is lib/events.ts.

import { EVENTS } from './lib/events'
import './wired.css'

export default function GameStrip() {
  return (
    <nav className="game-strip" aria-label="The games">
      <p className="game-strip-note">Seven events · phones are the controllers</p>
      {EVENTS.map((game) => (
        <div key={game.name} className="game-tile">
          <strong>
            {game.name}
            {game.beta && <em className="game-beta">Beta</em>}
          </strong>
          <small>{game.line}</small>
        </div>
      ))}
    </nav>
  )
}
