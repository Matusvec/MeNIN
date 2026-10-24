import { useEffect, useState } from 'react'
import Homer3D from './Homer3D'

type HomerMode = 'bard' | 'judge' | 'battle'

const modes: Array<{
  id: HomerMode
  label: string
  description: string
  response: string
}> = [
  {
    id: 'bard',
    label: 'Bard Mode',
    description: 'Learn iambic pentameter with Homer',
    response:
      'Ah, Bard Mode—the Muse approves! We shall train your ear, one measured foot at a time.',
  },
  {
    id: 'judge',
    label: 'Judge Mode',
    description: 'Scan and strengthen your verse',
    response:
      'Judge Mode! Bring me your verse, and I shall weigh each beat with a fair and careful hand.',
  },
  {
    id: 'battle',
    label: 'Battle Mode',
    description: 'Compete with fellow poets',
    response:
      'Battle Mode! Gather your poets. I shall judge the contest without fear or favor.',
  },
]

function AegeanScene() {
  return (
    <svg className="scene-landscape" viewBox="0 0 1000 1000" aria-hidden="true">
      <defs>
        <linearGradient id="sky" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0" stopColor="#2f96ea" />
          <stop offset=".55" stopColor="#72c2f1" />
          <stop offset="1" stopColor="#b9e5f7" />
        </linearGradient>
        <radialGradient id="sunWash" cx="78%" cy="10%" r="65%">
          <stop offset="0" stopColor="#fff8cc" stopOpacity=".72" />
          <stop offset=".28" stopColor="#fff8d8" stopOpacity=".18" />
          <stop offset="1" stopColor="#fff" stopOpacity="0" />
        </radialGradient>
        <linearGradient id="sea" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0" stopColor="#2ca1e7" />
          <stop offset=".5" stopColor="#178bd6" />
          <stop offset="1" stopColor="#086dbb" />
        </linearGradient>
        <linearGradient id="mountain" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0" stopColor="#82b5df" />
          <stop offset="1" stopColor="#4a8fc9" />
        </linearGradient>
        <linearGradient id="cliff" x1="0" y1="0" x2="1" y2="1">
          <stop offset="0" stopColor="#f4dfb5" />
          <stop offset=".52" stopColor="#d2b77f" />
          <stop offset="1" stopColor="#ad9568" />
        </linearGradient>
        <linearGradient id="green" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0" stopColor="#91bd76" />
          <stop offset="1" stopColor="#4f8a5d" />
        </linearGradient>
        <linearGradient id="stone" x1="0" y1="0" x2="1" y2="1">
          <stop offset="0" stopColor="#fff1d0" />
          <stop offset=".5" stopColor="#e3cda3" />
          <stop offset="1" stopColor="#bfa67b" />
        </linearGradient>
        <linearGradient id="column" x1="0" y1="0" x2="1" y2="0">
          <stop offset="0" stopColor="#c6ad80" />
          <stop offset=".35" stopColor="#fff0cb" />
          <stop offset=".72" stopColor="#e3cba0" />
          <stop offset="1" stopColor="#af9469" />
        </linearGradient>
        <filter id="sceneSoft"><feGaussianBlur stdDeviation="7" /></filter>
        <filter id="sceneShadow" x="-30%" y="-30%" width="160%" height="180%">
          <feDropShadow dx="0" dy="12" stdDeviation="10" floodColor="#35617b" floodOpacity=".22" />
        </filter>
      </defs>

      <rect width="1000" height="560" fill="url(#sky)" />
      <rect width="1000" height="560" fill="url(#sunWash)" />
      <circle cx="795" cy="96" r="55" fill="#fff7cf" opacity=".35" filter="url(#sceneSoft)" />

      <g opacity=".62" filter="url(#sceneSoft)">
        <path d="M575 556 700 434l53 55 75-93 172 160Z" fill="url(#mountain)" />
        <path d="m700 556 112-90 49 44 75-70 64 69v47Z" fill="#6ea9d5" />
      </g>

      <rect y="530" width="1000" height="270" fill="url(#sea)" />
      <path d="M0 535c160 8 326-8 488 0s328-8 512 0" fill="none" stroke="#d9f5ff" strokeWidth="5" opacity=".55" />
      {[570, 610, 655, 710].map((y, index) => (
        <path key={y} d={`M${430 + index * 24} ${y}c120-12 280 12 430 0`} fill="none" stroke="#bcecff" strokeWidth={3 - index * .35} opacity={.34 - index * .04} />
      ))}

      <g filter="url(#sceneShadow)">
        <path d="M-30 555V350L92 268l166 31 116 103 47 153Z" fill="url(#cliff)" />
        <path d="M-20 555V432l127-53 164 35 103 141Z" fill="#8aa770" />
        <path d="M-20 512 89 462l133 17 101 76H-20Z" fill="url(#green)" />
        <path d="M0 422c69-32 132-36 190-13 66 26 128 19 187-8v63c-81 31-151 31-214 8-57-21-111-14-163 18Z" fill="#79a568" />
      </g>

      <g transform="translate(36 211)" filter="url(#sceneShadow)">
        <path d="m0 55 107-48 111 48Z" fill="#f8e8c3" />
        <path d="M12 55h195v18H12Z" fill="url(#stone)" />
        <rect x="24" y="73" width="172" height="96" fill="#d8c092" />
        {[37, 68, 99, 130, 161].map((x) => (
          <g key={x}>
            <rect x={x} y="77" width="18" height="92" rx="7" fill="url(#column)" />
            <rect x={x - 5} y="72" width="28" height="10" rx="3" fill="#f2dfb7" />
            <rect x={x - 4} y="164" width="26" height="9" rx="2" fill="#c7aa78" />
          </g>
        ))}
        <path d="M2 169h216v18H2Z" fill="url(#stone)" />
        <path d="M-12 187h240v20H-12Z" fill="#c8ae7e" />
      </g>

      {[278, 320, 361, 401].map((x, index) => (
        <path key={x} d={`M${x} 502h${12 + index * 2}l-3-139h-7Z`} fill="#34765d" opacity=".94" />
      ))}
      {[45, 101, 173, 240, 323].map((x, index) => (
        <g key={x}>
          <ellipse cx={x} cy={470 + (index % 2) * 30} rx={24 + (index % 3) * 5} ry={29 + (index % 2) * 5} fill="#4f8b62" />
          <ellipse cx={x - 7} cy={462 + (index % 2) * 30} rx="10" ry="12" fill="#77ac74" opacity=".75" />
        </g>
      ))}

      <g transform="translate(825 545)" filter="url(#sceneShadow)">
        <path d="M0 38h95L78 53H18Z" fill="#795438" />
        <path d="M48-68v109" stroke="#8b6848" strokeWidth="5" />
        <path d="m53-58 37 67H53Z" fill="#fff4d7" />
        <path d="m43-43-27 51h27Z" fill="#f7dca8" />
      </g>

      <rect y="738" width="1000" height="262" fill="url(#stone)" />
      <path d="M0 802h1000M0 878h1000M160 738 66 1000M398 738l-35 262M647 738l54 262M830 738l119 262" stroke="#ae946b" strokeWidth="3" opacity=".38" />
      <rect y="696" width="1000" height="48" fill="url(#stone)" filter="url(#sceneShadow)" />
      <rect y="688" width="1000" height="13" fill="#fff1d2" />
      <rect x="934" width="66" height="1000" fill="url(#column)" filter="url(#sceneShadow)" />
      <rect x="922" width="16" height="1000" fill="#ead4aa" />
    </svg>
  )
}

function ModePage({
  mode,
  onBack,
}: {
  mode: HomerMode
  onBack: () => void
}) {
  const info = modes.find((item) => item.id === mode)!
  const [isSpeaking, setIsSpeaking] = useState(false)
  const [lessonStep, setLessonStep] = useState(1)
  const [answer, setAnswer] = useState<string | null>(null)
  const [poem, setPoem] = useState('')
  const [judged, setJudged] = useState(false)
  const [players, setPlayers] = useState(2)
  const [rounds, setRounds] = useState(2)
  const [battleStarted, setBattleStarted] = useState(false)
  const [coachLine, setCoachLine] = useState(
    mode === 'bard'
      ? 'Listen first. An iamb rises from a light beat to a strong one: da-DUM.'
      : mode === 'judge'
        ? 'Set your verse before me. I shall weigh its stresses, not merely count its syllables.'
        : 'Name the poets and the rounds. I shall keep the contest fair.',
  )

  const speak = (line: string) => {
    setCoachLine(line)
    setIsSpeaking(true)
    window.setTimeout(() => setIsSpeaking(false), 2200)
  }

  const bardContent = (
    <>
      <div className="workspace-heading">
        <span>Lesson {lessonStep} of 8</span>
        <h2>The heartbeat of a line</h2>
        <p>Tap the pattern that sounds like an iamb.</p>
      </div>
      <div className="meter-demo" aria-label="Meter exercise">
        <span>the</span>
        <strong>WIND</strong>
        <span>will</span>
        <strong>RISE</strong>
        <span>be</span>
        <strong>YOND</strong>
        <span>the</span>
        <strong>HILL</strong>
      </div>
      <div className="choice-grid">
        {['DUM-da', 'da-DUM', 'DUM-DUM'].map((choice) => (
          <button
            key={choice}
            className={answer === choice ? 'active' : ''}
            onClick={() => setAnswer(choice)}
          >
            {choice}
          </button>
        ))}
      </div>
      <button
        className="primary-action"
        disabled={!answer}
        onClick={() => {
          if (answer === 'da-DUM') {
            speak('Well heard, swift-fingered student. That rising pair is an iamb.')
            setLessonStep((step) => Math.min(8, step + 1))
          } else {
            speak('Nearly. Let the first beat fall lightly, then give the second its strength.')
          }
        }}
      >
        Check answer
      </button>
    </>
  )

  const judgeContent = (
    <>
      <div className="workspace-heading">
        <span>Scansion desk</span>
        <h2>Bring me your verse</h2>
        <p>Enter a line or stanza for a measured critique.</p>
      </div>
      <textarea
        className="poem-input"
        value={poem}
        onChange={(event) => {
          setPoem(event.target.value)
          setJudged(false)
        }}
        placeholder="Shall I compare thee to a summer’s day?"
        rows={5}
      />
      {judged && (
        <div className="score-panel">
          <div><strong>8.6</strong><span>Meter</span></div>
          <div><strong>9.1</strong><span>Naturalness</span></div>
          <div><strong>8.4</strong><span>Imagery</span></div>
          <div><strong>8.7</strong><span>Craft</span></div>
          <p><b>ˇ / | ˇ / | ˇ / | ˇ / | ˇ /</b><br />A confident line with a natural rising cadence.</p>
        </div>
      )}
      <button
        className="primary-action"
        disabled={!poem.trim()}
        onClick={() => {
          setJudged(true)
          speak('The line carries its rhythm well. Let us examine where speech and meter meet.')
        }}
      >
        Scan my verse
      </button>
    </>
  )

  const battleContent = (
    <>
      <div className="workspace-heading">
        <span>{battleStarted ? 'Round 1' : 'Battle setup'}</span>
        <h2>{battleStarted ? 'The sea at dawn' : 'Prepare the poets'}</h2>
        <p>
          {battleStarted
            ? 'Write four lines of pentameter. Include one trochaic opening.'
            : 'Choose the company and length of your contest.'}
        </p>
      </div>
      {!battleStarted ? (
        <div className="battle-settings">
          <label>
            <span>Players</span>
            <div className="stepper">
              <button onClick={() => setPlayers((count) => Math.max(2, count - 1))}>−</button>
              <strong>{players}</strong>
              <button onClick={() => setPlayers((count) => Math.min(6, count + 1))}>+</button>
            </div>
          </label>
          <label>
            <span>Rounds</span>
            <div className="stepper">
              <button onClick={() => setRounds((count) => Math.max(1, count - 1))}>−</button>
              <strong>{rounds}</strong>
              <button onClick={() => setRounds((count) => Math.min(5, count + 1))}>+</button>
            </div>
          </label>
          <button
            className="primary-action"
            onClick={() => {
              setBattleStarted(true)
              speak(`Let the contest begin: ${players} poets, ${rounds} rounds, and one impartial judge.`)
            }}
          >
            Begin battle
          </button>
        </div>
      ) : (
        <>
          <div className="scoreboard">
            {Array.from({ length: players }, (_, index) => (
              <div key={index}>
                <span>Poet {index + 1}</span>
                <strong>—</strong>
                <small>Awaiting verse</small>
              </div>
            ))}
          </div>
          <button
            className="primary-action"
            onClick={() => speak('Submissions are open. Each poet shall be heard in turn.')}
          >
            Collect submissions
          </button>
        </>
      )}
    </>
  )

  return (
    <main className={`mode-screen ${mode}`}>
      <div className="mode-scene" aria-hidden="true"><AegeanScene /></div>
      <header className="mode-topbar">
        <button className="mode-back" onClick={onBack}>‹ Main menu</button>
        <div><span>Homer</span><strong>{info.label}</strong></div>
        <span className="session-status">Session active</span>
      </header>
      <div className="mode-layout">
        <aside className="coach-stage">
          <Homer3D speaking={isSpeaking} mode={mode} />
          <div className="coach-dialogue">
            <span>Homer</span>
            <p>{coachLine}</p>
          </div>
        </aside>
        <section className="workspace">
          {mode === 'bard' ? bardContent : mode === 'judge' ? judgeContent : battleContent}
        </section>
      </div>
    </main>
  )
}

export default function App() {
  const [isOpen, setIsOpen] = useState(false)
  const [selectedMode, setSelectedMode] = useState<HomerMode | null>(null)
  const [activeMode, setActiveMode] = useState<HomerMode | null>(null)
  const selected = modes.find((mode) => mode.id === selectedMode)
  const fullMessage =
    selected?.response ??
    'Welcome! I’m Homer. How would you like to explore poetry today?'
  const [spokenMessage, setSpokenMessage] = useState('')

  useEffect(() => {
    setSpokenMessage('')
    let character = 0
    const timer = window.setInterval(() => {
      character += 1
      setSpokenMessage(fullMessage.slice(0, character))
      if (character >= fullMessage.length) window.clearInterval(timer)
    }, 28)

    return () => window.clearInterval(timer)
  }, [fullMessage])

  const isSpeaking = spokenMessage.length < fullMessage.length

  if (activeMode) {
    return <ModePage mode={activeMode} onBack={() => setActiveMode(null)} />
  }

  return (
    <main className="scene">
      <div className="animated-background" aria-hidden="true">
        <div className="scene-artboard">
          <AegeanScene />
          <span className="sun-haze" />
          <span className="cloud cloud-one" />
          <span className="cloud cloud-two" />
          <span className="cloud cloud-three" />
          <span className="sea-light sea-light-one" />
          <span className="sea-light sea-light-two" />
          <span className="sea-light sea-light-three" />
          <span className="gull gull-one" />
          <span className="gull gull-two" />
          <Homer3D speaking={isSpeaking} mode={selectedMode} />
        </div>
      </div>

      <header className="nameplate" aria-label="Homer">
        <span>Homer</span>
        <i aria-hidden="true" />
        <i aria-hidden="true" />
        <i aria-hidden="true" />
      </header>

      <section className="dialogue" aria-labelledby="dialogue-title">
        <div className="dialogue-copy">
          <p className="welcome">{selected ? selected.label : 'Homer speaks'}</p>
          <h1 id="dialogue-title">{spokenMessage}<span className="typing-cursor" /></h1>
        </div>

        <div className="mode-select">
          <button
            className="select-trigger"
            type="button"
            aria-haspopup="listbox"
            aria-expanded={isOpen}
            onClick={() => setIsOpen((open) => !open)}
          >
            <span>
              <small>Choose your path</small>
              <strong>{selected?.label ?? 'Select a mode'}</strong>
            </span>
            <span className={`select-arrow ${isOpen ? 'open' : ''}`} aria-hidden="true" />
          </button>

          {isOpen && (
            <div className="dropdown" role="listbox" aria-label="Homer mode">
              {modes.map((mode) => (
                <button
                  key={mode.id}
                  className={selectedMode === mode.id ? 'selected' : ''}
                  type="button"
                  role="option"
                  aria-selected={selectedMode === mode.id}
                  onClick={() => {
                    setSelectedMode(mode.id)
                    setIsOpen(false)
                  }}
                >
                  <span className="option-mark" aria-hidden="true" />
                  <span>
                    <strong>{mode.label}</strong>
                    <small>{mode.description}</small>
                  </span>
                </button>
              ))}
            </div>
          )}
        </div>

        <button
          className="continue-button"
          type="button"
          aria-label={selected ? `Continue to ${selected.label}` : 'Select a mode'}
          onClick={() => selected ? setActiveMode(selected.id) : setIsOpen(true)}
        >
          A
        </button>
      </section>
    </main>
  )
}
