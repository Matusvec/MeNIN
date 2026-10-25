// The Poets' Hall: the landing page, where you pick whose voice guides you.
// Homer is playable; Hesiod and Virgil are locked for now. A new poet is one entry in POETS
// (a look for the rig, and a host screen behind it once they're available).

import { useState } from 'react'
import Homer3D from './Homer3D'
import { HESIOD_LOOK, HOMER_LOOK, VIRGIL_LOOK, type PoetLook } from './poets/rig'
import World3D from './world/World3D'
import './landing.css'

export type PoetId = 'homer' | 'hesiod' | 'virgil'

type Poet = {
  id: PoetId
  name: string
  title: string
  craft: string
  look: PoetLook
  available: boolean
}

const POETS: Poet[] = [
  { id: 'homer', name: 'Homer', title: 'Blind bard of Ionia', craft: 'Epic poetry · Meter · Oral tradition', look: HOMER_LOOK, available: true },
  { id: 'hesiod', name: 'Hesiod', title: 'Shepherd of Ascra', craft: 'Works and Days · Theogony · Didactic verse', look: HESIOD_LOOK, available: false },
  { id: 'virgil', name: 'Virgil', title: 'Poet of Mantua', craft: 'The Aeneid · Latin epic · Hexameter', look: VIRGIL_LOOK, available: false },
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
            className={`poet-card${poet.available ? '' : ' locked'}`}
            onMouseEnter={() => setHovered(poet.id)}
            onMouseLeave={() => setHovered(null)}
          >
            <span className={`poet-badge${poet.available ? '' : ' locked'}`}>
              {poet.available ? 'Available now' : (
                <>
                  <svg viewBox="0 0 16 16" aria-hidden="true"><path d="M4.5 7V5a3.5 3.5 0 0 1 7 0v2h.5a1 1 0 0 1 1 1v6a1 1 0 0 1-1 1H4a1 1 0 0 1-1-1V8a1 1 0 0 1 1-1zm1.6 0h3.8V5a1.9 1.9 0 0 0-3.8 0z" /></svg>
                  Locked
                </>
              )}
            </span>
            <div className="poet-figure">
              <Homer3D
                speaking={false}
                mode={null}
                action={poet.available && hovered === poet.id ? 'welcome' : 'idle'}
                framing="card"
                look={poet.look}
                still={!poet.available}
                label={`3D ${poet.name}`}
              />
            </div>
            <div className="poet-copy">
              <p className="poet-title">{poet.title}</p>
              <h2>{poet.name}</h2>
              <p className="poet-craft">{poet.craft}</p>
            </div>
            <button
              className="poet-choose"
              type="button"
              aria-label={poet.available ? `Choose ${poet.name}` : `${poet.name} is locked`}
              disabled={!poet.available}
              onClick={() => onChoose(poet.id)}
            >
              <span>{poet.available ? `Choose ${poet.name}` : 'Coming soon'}</span>
              <span aria-hidden="true">{poet.available ? '›' : ''}</span>
            </button>
          </article>
        ))}
      </section>

      <p className="landing-footnote">More poets will join the hall soon.</p>
    </main>
  )
}
