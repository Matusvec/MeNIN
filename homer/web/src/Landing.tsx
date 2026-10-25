// The Poets' Hall: the landing page, where you pick whose voice guides you.
// Only Homer for now; a new poet is one entry in POETS (and a host screen behind it).

import { useState } from 'react'
import Homer3D from './Homer3D'
import World3D from './world/World3D'
import './landing.css'

export type PoetId = 'homer'

type Poet = {
  id: PoetId
  name: string
  title: string
  craft: string
  available: boolean
}

const POETS: Poet[] = [
  { id: 'homer', name: 'Homer', title: 'Blind bard of Ionia', craft: 'Epic poetry · Meter · Oral tradition', available: true },
]

export default function Landing({ onChoose }: { onChoose: (poet: PoetId) => void }) {
  const [hovered, setHovered] = useState<PoetId | null>(null)

  return (
    <main className="landing">
      <div className="landing-world" aria-hidden="true">
        <World3D view="vista" />
      </div>

      <header className="landing-header">
        <span className="landing-wordmark">MeNIN</span>
        <span className="landing-hall">The Poets’ Hall</span>
      </header>

      <section className="landing-intro">
        <p className="landing-kicker">Welcome, student</p>
        <h1>Whose voice will guide you?</h1>
        <p className="landing-lede">Select a poet to begin your study of meter, language, and craft.</p>
      </section>

      <section className="landing-poets" aria-label="Poets">
        {POETS.map((poet) => (
          <article
            key={poet.id}
            className="poet-card"
            onMouseEnter={() => setHovered(poet.id)}
            onMouseLeave={() => setHovered(null)}
          >
            {poet.available && <span className="poet-badge">Available now</span>}
            <div className="poet-figure">
              {poet.id === 'homer' && <Homer3D speaking={false} mode={null} action={hovered === 'homer' ? 'welcome' : 'idle'} framing="card" />}
            </div>
            <div className="poet-copy">
              <p className="poet-title">{poet.title}</p>
              <h2>{poet.name}</h2>
              <p className="poet-craft">{poet.craft}</p>
            </div>
            <button className="poet-choose" type="button" aria-label={`Choose ${poet.name}`} disabled={!poet.available} onClick={() => onChoose(poet.id)}>
              <span>Choose {poet.name}</span>
              <span aria-hidden="true">›</span>
            </button>
          </article>
        ))}
      </section>

      <p className="landing-footnote">More poets will join the hall soon.</p>
    </main>
  )
}
