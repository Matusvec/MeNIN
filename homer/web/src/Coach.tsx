// Talk to Homer (SPEC "The website", the coach event): a poet speaks into the phone, the words show
// here as they come, and Homer answers out loud in two sentences: the score row's verdict. Each verse
// attempt is also scored like a battle verse (Image x4, Answer x4, Craft x2 = /100) so a poet can see
// they're improving (Matus); talking back has no score (axes []). The conversation runs on the battle
// engine (lib/arena.ts); this only shows it.
// Styles are artist's (coach.css): data-mic is the one state the whole screen keys off.

import { useEffect, useRef, type CSSProperties } from 'react'
import { SILENT_VERDICT, type ArenaView } from './lib/arena'
import TailVerse, { type WordMark } from './TailVerse'
import './coach.css'

type Mic = 'listening' | 'thinking' | 'speaking' | 'off'

// A coach attempt's axes come in the poetry order: Flow, Craft, Image, Answer, Range. The screen shows the content three.
const CONTENT: Array<[string, number]> = [['Image', 2], ['Answer', 3], ['Craft', 1]]

export default function CoachPanel({ view, onWord }: { view: ArenaView; onWord: (word: WordMark | null) => void }) {
  const room = view.room
  const log = useRef<HTMLOListElement>(null)
  const turn = view.turn
  const speaker = turn ? view.poets.find((p) => p.id === turn.playerId) : undefined
  const solo = view.poets.length < 2
  const replies = new Map(view.scores.map((s) => [s.turnId, s.verdict || SILENT_VERDICT]))
  const scored = new Map(view.scores.filter((s) => s.axes.length === 5).map((s) => [s.turnId, s])) // verse attempts only
  // Every exchange so far, newest last: the poet's words, then Homer's answer once it's in.
  const exchanges = view.turns.filter((t) => t.transcript.trim() && replies.has(t.id))
  const latest = exchanges.length ? replies.get(exchanges[exchanges.length - 1].id) : ''
  const latestAttempt = [...exchanges].reverse().find((t) => scored.has(t.id))?.id
  // A neutral score (the judge timed out: 4/4/4) is shown greyed but never counts as progress or as the best.
  const judged = (id: bigint) => scored.has(id) && replies.get(id) !== SILENT_VERDICT
  // Each attempt's trend is against the same poet's previous judged attempt; the best is per poet, ties to the newest.
  const prevTotal = new Map<bigint, number>()
  const bestOf = new Map<bigint, { id: bigint; total: number }>()
  for (const t of exchanges) {
    if (!judged(t.id)) continue
    const total = scored.get(t.id)!.total
    const before = [...exchanges].filter((x) => x.playerId === t.playerId && x.id < t.id && judged(x.id)).pop()
    if (before) prevTotal.set(t.id, scored.get(before.id)!.total)
    const best = bestOf.get(t.playerId)
    if (!best || total >= best.total) bestOf.set(t.playerId, { id: t.id, total })
  }

  // The newest exchange's score, up in Homer's reply card (artist: in view at 1440x900, not only in the log).
  // Only when that reply answers a verse attempt: after a talk-back the card shows no score, so it's never stale.
  const last = exchanges[exchanges.length - 1]
  const lastScore = last ? scored.get(last.id) : undefined

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
          {last && lastScore && (
            <ReplyScore
              score={lastScore}
              prev={prevTotal.get(last.id)}
              best={judged(last.id) && bestOf.get(last.playerId)?.id === last.id}
              neutral={!judged(last.id)}
            />
          )}
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
              <AttemptEntry
                key={`${t.id}-you`}
                who={solo ? 'You' : poet?.name ?? 'Poet'}
                text={t.transcript}
                score={scored.get(t.id)}
                prev={prevTotal.get(t.id)}
                latest={t.id === latestAttempt}
                best={judged(t.id) && bestOf.get(t.playerId)?.id === t.id}
                neutral={scored.has(t.id) && !judged(t.id)}
              />,
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

type AttemptScore = { total: number; axes: ArrayLike<number> }

/** "52 → 58 ↑" against the poet's previous judged attempt; none on a first attempt or a neutral score. */
function Trend({ score, prev, neutral }: { score: AttemptScore; prev?: number; neutral: boolean }) {
  if (prev === undefined || neutral) return null
  const trend = score.total > prev ? 'up' : score.total < prev ? 'down' : 'same'
  return (
    <em className={`trend ${trend}`}>
      {prev} → {score.total} {trend === 'up' ? '↑' : trend === 'down' ? '↓' : '='}
    </em>
  )
}

/** The newest attempt's score inside Homer's reply card (coach.css .reply-score). */
function ReplyScore({ score, prev, best, neutral }: { score: AttemptScore; prev?: number; best: boolean; neutral: boolean }) {
  return (
    <div className={['reply-score', best && 'best', neutral && 'neutral'].filter(Boolean).join(' ')}>
      <strong>{score.total}</strong>
      <small>/100</small>
      <Trend score={score} prev={prev} neutral={neutral} />
      <span>
        {CONTENT.map(([label, i]) => {
          const v = score.axes[i] ?? 0
          return (
            <i key={label} className={v >= 8 ? 'high' : undefined}>
              {label} <b>{v}</b>
            </i>
          )
        })}
      </span>
    </div>
  )
}

/** A poet's line in the log; a verse attempt also shows its score, the trend and (newest only) the bars. */
function AttemptEntry({ who, text, score, prev, latest, best, neutral }: {
  who: string
  text: string
  score?: AttemptScore
  prev?: number
  latest: boolean
  best: boolean
  neutral: boolean
}) {
  const classes = ['turn', 'you', score && 'scored', best && 'best', score && latest && 'latest', neutral && 'neutral'].filter(Boolean).join(' ')
  return (
    <li className={classes}>
      <b>{who}</b>
      <p>{text}</p>
      {score && (
        <div className="attempt-score">
          <strong>{score.total}</strong>
          <small>/100</small>
          <Trend score={score} prev={prev} neutral={neutral} />
        </div>
      )}
      {score && latest && (
        <div className="attempt-bars">
          {CONTENT.map(([label, i]) => {
            const v = score.axes[i] ?? 0
            return (
              <div key={label} className={v >= 8 ? 'high' : ''} style={{ '--v': v } as CSSProperties}>
                <strong>{v}</strong>
                <i className="bar" />
                <span>{label}</span>
              </div>
            )
          })}
        </div>
      )}
    </li>
  )
}
