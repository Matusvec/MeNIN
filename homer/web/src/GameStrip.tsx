// The events (SPEC "The games"), on one strip: what each one is and how you play it.
// Played with phones as controllers; watched on this screen.

import './wired.css'

const GAMES = [
  { name: 'Poetry battle', what: 'Spit verse on a theme. Homer scores Image, Answer and Craft' },
  { name: 'Talk to Homer', what: 'Say a verse. He quotes you, gives one fix, scores it' },
  { name: 'Socratic debate', what: 'Argue a question in timed turns. Socrates judges' },
  { name: 'Discus', what: 'Swing your phone to throw. Angle, speed and spin count' },
  { name: 'Stadion', what: 'Pump your arms to sprint. Everyone races at once' },
  { name: 'Pygmachia', what: 'Box with your phone: punch, block, counter', beta: true },
  { name: 'Toxeia', what: 'Draw the bow with your phones and aim for the rings', beta: true },
]

export default function GameStrip() {
  return (
    <nav className="game-strip" aria-label="The games">
      <p className="game-strip-note">Seven events · phones are the controllers</p>
      {GAMES.map((game) => (
        <div key={game.name} className="game-tile">
          <strong>
            {game.name}
            {game.beta && <em className="game-beta">Beta</em>}
          </strong>
          <small>{game.what}</small>
        </div>
      ))}
    </nav>
  )
}
