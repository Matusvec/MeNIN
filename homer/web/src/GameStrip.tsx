// The three games (SPEC "The games"), on one strip. Played with the app; watched here.

import './wired.css'

const GAMES = [
  { name: 'Poetry battle', host: 'Homer', what: 'Improvise verse over the beat' },
  { name: 'Socratic debate', host: 'Socrates', what: 'Argue a question, on the clock' },
  { name: 'Discus', host: 'Homer announces', what: 'Swing your phone, throw' },
]

export default function GameStrip() {
  return (
    <nav className="game-strip" aria-label="The games">
      {GAMES.map((game) => (
        <div key={game.name} className="game-tile">
          <strong>{game.name}</strong>
          <small>{game.what}</small>
        </div>
      ))}
    </nav>
  )
}
