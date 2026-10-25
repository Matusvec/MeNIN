// The music toggle (artist): a small speaker in the header, remembered per browser.
// Rendering it arms the theme to start at the first click (src/music.ts), so a page
// without it (the phone's join page) never plays music. `hush` keeps it silent while
// this screen is up (Bard mode: the poet is at the mic the whole lesson).

import { useMusic, useMusicEnabled } from './music'
import './music.css'

export default function MusicToggle({ hush = false, className = '' }: { hush?: boolean; className?: string }) {
  useMusic({ hush })
  const [on, setOn] = useMusicEnabled()
  return (
    <button
      type="button"
      className={`music-toggle${on ? '' : ' off'}${className ? ` ${className}` : ''}`}
      aria-pressed={on}
      aria-label={on ? 'Music on. Turn it off' : 'Music off. Turn it on'}
      title={on ? 'Music on' : 'Music off'}
      onClick={() => setOn(!on)}
    >
      <svg viewBox="0 0 24 24" aria-hidden="true">
        <path d="M4 9.5h3.5L12 5.5v13l-4.5-4H4z" fill="currentColor" stroke="currentColor" strokeWidth="1.5" strokeLinejoin="round" />
        {on ? (
          <path d="M15.5 9a4 4 0 0 1 0 6M18 6.5a7.5 7.5 0 0 1 0 11" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" />
        ) : (
          <path d="M16 9.5l5 5M21 9.5l-5 5" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" />
        )}
      </svg>
    </button>
  )
}
