// The browser poet's screen (the Safari controller): join, wait, the 3-2-1, SPEAK with the window's ring and
// "I'm done", the live words and the hand, then the verdict. Poetry battle and Talk to Homer. The logic is
// PoetClient (poet.ts); this only draws it. Styles: poet.css.

import { useEffect, useRef, useState, type CSSProperties, type ReactNode } from 'react'
import { PoetClient, type PoetView } from './poet'
import './poet.css'

const SEAT_INKS = ['#2D5C66', '#C8452C', '#A8741F', '#5B3F73', '#6E7A2E'] // = the arena's and the app's seats

export default function WebPoet({ code }: { code: string }) {
  const client = useRef<PoetClient | null>(null)
  const [view, setView] = useState<PoetView | null>(null)
  const [name, setName] = useState('')
  const [level, setLevel] = useState(0)

  useEffect(() => {
    const c = new PoetClient(code, (v) => {
      setView(v)
      // Test halls: headless runs read the poet's state from the console (window.meninPoet).
      if (import.meta.env.VITE_STDB_DB && import.meta.env.VITE_STDB_DB !== 'homer-calhacks') {
        ;(window as unknown as { meninPoet?: PoetView }).meninPoet = v
        ;(window as unknown as { meninPoetDebug?: () => unknown }).meninPoetDebug = () => c.debug
      }
    })
    client.current = c
    c.connect()
    // The countdowns and the mic meter move on their own: a light tick while the page is open.
    const tick = window.setInterval(() => {
      c.publish()
      setLevel(c.micLevel)
    }, 200)
    return () => {
      window.clearInterval(tick)
      c.dispose()
    }
  }, [code])

  if (!view) return <PoetShell code={code}><p className="poet-note">Opening the hall…</p></PoetShell>
  const ink = SEAT_INKS[view.seat % SEAT_INKS.length]

  switch (view.stage) {
    case 'connecting':
      return <PoetShell code={code}><p className="poet-note">Opening the hall…</p></PoetShell>
    case 'no-room':
      return <PoetShell code={code}><p className="poet-note">No open hall with the code {code}. Check the big screen.</p></PoetShell>
    case 'unsupported':
      return (
        <PoetShell code={code}>
          <p className="poet-note">This hall is playing a motion game. Those need the MeNIN app on your phone.</p>
        </PoetShell>
      )
    case 'name':
    case 'joining':
    case 'rejoin':
      return (
        <PoetShell code={code}>
          <form
            className="poet-join"
            onSubmit={(e) => {
              e.preventDefault()
              void client.current?.join(view.stage === 'rejoin' ? view.name : name)
            }}
          >
            {view.stage === 'rejoin' ? (
              <p className="poet-note">Welcome back, {view.name}. Tap to turn your mic back on.</p>
            ) : (
              <label>
                <span>Your name</span>
                <input value={name} onChange={(e) => setName(e.target.value)} maxLength={24} autoComplete="nickname" autoFocus />
              </label>
            )}
            <button className="primary-action" disabled={view.stage === 'joining' || (view.stage === 'name' && !name.trim())}>
              {view.stage === 'joining' ? 'Joining…' : view.stage === 'rejoin' ? 'Rejoin' : 'Join with my mic'}
            </button>
            <small>Your phone is your mic. Keep this page open, with the screen on.</small>
            {view.error && <p className="poet-error">{view.error}</p>}
          </form>
        </PoetShell>
      )
  }

  return (
    <PoetShell code={code}>
      <header className="poet-me" style={{ '--seat': ink } as CSSProperties}>
        <strong>{view.name}</strong>
        {view.theme && <span>{view.theme}</span>}
      </header>

      {view.stage === 'lobby' && (
        <section className="poet-wait">
          <p>You're in. Watch the big screen: the battle starts when the host taps Begin.</p>
          <MicMeter level={level} />
        </section>
      )}

      {view.stage === 'waiting' && (
        <section className="poet-wait">
          <p>{view.speaker ? `${view.speaker} is up.` : 'Watch the big screen.'} Your turn comes; this page will tell you.</p>
          {view.verdict && <LastVerdict verdict={view.verdict} total={view.total} />}
        </section>
      )}

      {view.stage === 'up-next' && (
        <section className="poet-up">
          <p className="poet-big">You're up next.</p>
          <p>When the 3-2-1 starts, your mic is live. Speak when you see SPEAK.</p>
        </section>
      )}

      {view.stage === 'count-in' && (
        <section className="poet-count" key={view.countIn ?? 0}>
          <span>{view.countIn}</span>
        </section>
      )}

      {view.stage === 'speak' && (
        <section className="poet-speak">
          <div
            className="poet-ring"
            style={{ '--left': view.secondsLeft !== null ? view.secondsLeft / view.windowSeconds : 1 } as CSSProperties}
          >
            <strong>SPEAK</strong>
            <small>{view.secondsLeft ?? ''}</small>
          </div>
          <p className="poet-words">{view.words || '…'}</p>
          <button className="primary-action" onClick={() => client.current?.done()}>
            I'm done
          </button>
        </section>
      )}

      {view.stage === 'judging' && (
        <section className="poet-wait">
          <p className="poet-big">Homer is listening back…</p>
          {view.words && <p className="poet-words said">{view.words}</p>}
        </section>
      )}

      {view.stage === 'verdict' && (
        <section className="poet-wait">
          <LastVerdict verdict={view.verdict} total={view.total} />
        </section>
      )}

      {view.stage === 'finished' && (
        <section className="poet-wait">
          <p className="poet-big">The battle is over.</p>
          {view.verdict && <LastVerdict verdict={view.verdict} total={view.total} />}
          <p>Stay on this page for a rematch, or close it.</p>
        </section>
      )}

      {view.cards.length > 0 && ['up-next', 'count-in', 'speak', 'waiting', 'lobby'].includes(view.stage) && (
        <section className="poet-hand" aria-label="Your phrases">
          <span>Your phrases</span>
          <ul>
            {view.cards.map((card) => (
              <li key={card.text} className={card.played ? 'played' : ''}>
                {card.text}
              </li>
            ))}
          </ul>
        </section>
      )}

      {view.error && <p className="poet-error">{view.error}</p>}
    </PoetShell>
  )
}

function PoetShell({ code, children }: { code: string; children: ReactNode }) {
  return (
    <main className="poet">
      <p className="poet-hall">MeNIN · Room {code}</p>
      {children}
    </main>
  )
}

function MicMeter({ level }: { level: number }) {
  return (
    <div className="poet-meter" aria-label="Mic check">
      <i style={{ '--level': level } as CSSProperties} />
      <small>Mic check: say something, the bar should move.</small>
    </div>
  )
}

function LastVerdict({ verdict, total }: { verdict: string; total: number | null }) {
  if (!verdict) return <p className="poet-note">Homer is weighing it. The verdict is on the big screen.</p>
  return (
    <div className="poet-verdict">
      {total !== null && (
        <strong>
          {total}
          <small>/100</small>
        </strong>
      )}
      <p>{verdict}</p>
    </div>
  )
}
