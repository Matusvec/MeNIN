// /join/CODE: where the arena's QR lands on a phone. Opens the room in the MeNIN app,
// or points the way to TestFlight for a phone without it. With `onPlayInBrowser` (?web=1 for now),
// also "Play in your browser": the no-install poet (src/poet/), poetry and Talk to Homer.

import { appJoinLink, hasTestFlight, TESTFLIGHT_URL } from './lib/links'
import './wired.css'

export default function JoinCard({ code, onPlayInBrowser }: { code: string; onPlayInBrowser?: () => void }) {
  return (
    <>
      <div className="dialogue-copy">
        <p className="welcome">Join the hall</p>
        <h1 className="join-page-code">{code}</h1>
        <p className="join-page-note">Open the room in MeNIN on this phone. Your phone is your mic and your hand.</p>
      </div>
      <div className="join-page-actions">
        <a className="primary-action" href={appJoinLink(code)}>
          Open in MeNIN
        </a>
        {onPlayInBrowser && (
          <button className="secondary-action" type="button" onClick={onPlayInBrowser}>
            Play in your browser
          </button>
        )}
        {hasTestFlight() ? (
          <a className="secondary-action" href={TESTFLIGHT_URL} target="_blank" rel="noreferrer">
            Get MeNIN on TestFlight
          </a>
        ) : (
          <p className="join-page-note">No MeNIN yet? Ask the host for the TestFlight invite.</p>
        )}
      </div>
    </>
  )
}
