// Talk to Homer (SPEC "The website", the coach event): a poet speaks into the phone, the words show
// here as they come, and Homer answers out loud in two sentences. No scorecard: his reply is the
// score row's verdict. The conversation runs on the battle engine (lib/arena.ts); this only shows it.
// Styles are artist's (coach.css): data-mic is the one state the whole screen keys off.

import { useEffect, useRef } from 'react'
import { SILENT_VERDICT, type ArenaView } from './lib/arena'
import TailVerse, { type WordMark } from './TailVerse'
import './coach.css'

type Mic = 'listening' | 'thinking' | 'speaking' | 'off'

export default function CoachPanel({ view, onWord }: { view: ArenaView; onWord: (word: WordMark | null) => void }) {
  const room = view.room
  const log = useRef<HTMLOListElement>(null)
  const turn = view.turn
  const speaker = turn ? view.poets.find((p) => p.id === turn.playerId) : undefined
  const solo = view.poets.length < 2
  const replies = new Map(view.scores.map((s) => [s.turnId, s.verdict || SILENT_VERDICT]))
  // Every exchange so far, newest last: the poet's words, then Homer's answer once it's in.
  const exchanges = view.turns.filter((t) => t.transcript.trim() && replies.has(t.id))
  const latest = exchanges.length ? replies.get(exchanges[exchanges.length - 1].id) : ''

  useEffect(() => {
    if (log.current) log.current.scrollTop = log.current.scrollHeight
  }, [exchanges.length])

  if (!room) return null
  const phase = room.phase
  const name = speaker?.name ?? 'the poet'
  const mic: Mic =
    phase === 'speaking' ? 'listening'
    : phase === 'judging' ? 'thinking'
    : view.speaking ? 'speaking'
    : 'off'
  const [title, line] =
    mic === 'listening' ? [`${name} is speaking`, 'Homer is listening']
    : mic === 'thinking' ? ['Homer is answering…', `${name} said their piece`]
    : mic === 'speaking' ? ['Homer speaks', solo ? 'Then answer him, or try again' : `Then ${name} answers`]
    : phase === 'lobby' ? [`Join with the code ${room.code}`, 'Scan with the MeNIN app']
    : phase === 'finished' ? ['The conversation is over', 'Start a new one when you like']
    : [`Waiting for ${name}`, 'SPEAK comes up on the phone']
  const live = ['speaking', 'judging'].includes(phase) ? (turn?.transcript ?? '') : ''

  return (
    <div className="coach" data-mic={mic}>
      {latest && (
        <blockquote className="reply">
          <b>Homer</b>
          <p>{latest}</p>
        </blockquote>
      )}
      <TailVerse turnKey={turn ? `${turn.id}-${turn.attempt}` : ''} text={live} className="live-words" lines={false} onWord={onWord} />
      <div className="mic-state">
        <i className="mic-mark" />
        <strong>{title}</strong>
        <small>{line}</small>
      </div>
      {exchanges.length > 0 && (
        <ol className="coach-log" ref={log}>
          {exchanges.map((t) => {
            const poet = view.poets.find((p) => p.id === t.playerId)
            return [
              <li key={`${t.id}-you`} className="turn you">
                <b>{solo ? 'You' : poet?.name ?? 'Poet'}</b>
                <p>{t.transcript}</p>
              </li>,
              <li key={`${t.id}-homer`} className="turn homer">
                <b>Homer</b>
                <p>{replies.get(t.id)}</p>
              </li>,
            ]
          })}
        </ol>
      )}
    </div>
  )
}
