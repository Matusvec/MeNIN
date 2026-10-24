// The live words of a turn, as they arrive (Matus: "I don't think the dictation is working"). A free
// verse comes in as one long line, and at the 2 m type size its newest words fell below the fold, so it
// looked frozen. Only the tail shows: the last TAIL_WORDS words, "…" in front when trimmed. The words
// that arrived with this update are wrapped in .partial (dimmed by artist's CSS), so each update visibly
// lands. Every update renders; nothing is batched. The newest word's place on screen goes to the scene,
// which ripples from it.

import { useLayoutEffect, useRef, type ReactNode } from 'react'

export const TAIL_WORDS = 28

export type WordMark = { n: number; x: number; y: number } // n words on screen; (x, y) as viewport fractions

type Props = {
  turnKey: string // a new turn starts fresh
  text: string
  className: string
  lines: boolean // poetry and debate: one span per line; coach: one paragraph
  mark?: (text: string) => ReactNode // formula marks, on the settled words only
  onWord?: (word: WordMark | null) => void
}

export default function TailVerse({ turnKey, text, className, lines, mark = (t) => t, onWord }: Props) {
  const box = useRef<HTMLElement>(null)
  // The transcript now and before its last change, per turn. Renders that don't change the words (another
  // row updated) keep the same fresh words; render itself never writes the ref, so StrictMode agrees.
  const seen = useRef({ turnKey: '', last: '', before: '' })
  const same = seen.current.turnKey === turnKey
  const before = !same ? '' : seen.current.last === text ? seen.current.before : seen.current.last

  const tokens = text.match(/\S+|\n/g) ?? []
  const words = tokens.filter((t) => t !== '\n')
  const was = before.match(/\S+/g) ?? []
  let common = 0 // speech-to-text may revise its last words, so "new" starts where the two first differ
  while (common < was.length && common < words.length && was[common] === words[common]) common++
  let start = tokens.length // the tail: the last TAIL_WORDS words, keeping the line breaks inside it
  for (let count = 0; start > 0 && count < TAIL_WORDS; ) if (tokens[--start] !== '\n') count++
  while (tokens[start] === '\n') start++

  // Group the tail into lines; each word knows whether it arrived with this update.
  const rows: Array<{ settled: string[]; fresh: string[] }> = [{ settled: [], fresh: [] }]
  let index = words.length - tokens.slice(start).filter((t) => t !== '\n').length
  for (const token of tokens.slice(start)) {
    if (token === '\n') {
      rows.push({ settled: [], fresh: [] })
      continue
    }
    const row = rows[rows.length - 1]
    if (index >= common) row.fresh.push(token)
    else row.settled.push(token)
    index++
  }
  const shown = rows.filter((r) => r.settled.length || r.fresh.length)
  const trimmed = start > 0

  useLayoutEffect(() => {
    const was = seen.current
    if (was.turnKey !== turnKey) seen.current = { turnKey, last: text, before: '' }
    else if (was.last !== text) seen.current = { turnKey, last: text, before: was.last }
    if (!onWord) return
    const last = box.current?.querySelectorAll('span.partial')
    const newest = last && last.length ? last[last.length - 1] : null
    if (!text.trim() || !newest) return onWord(null)
    const rect = newest.getBoundingClientRect()
    onWord({
      n: words.length,
      x: Math.min(1, Math.max(0, rect.right / window.innerWidth)),
      y: Math.min(1, Math.max(0, (rect.top + rect.height / 2) / window.innerHeight)),
    })
  }, [turnKey, text]) // eslint-disable-line react-hooks/exhaustive-deps

  // Every row ends in a .partial span (empty when nothing new landed there), so the last one marks the newest word.
  const row = (r: { settled: string[]; fresh: string[] }, i: number, last: boolean) => (
    <>
      {i === 0 && trimmed ? '… ' : ''}
      {mark(r.settled.join(' '))}
      {r.settled.length && r.fresh.length ? ' ' : ''}
      <span className="partial">{r.fresh.join(' ')}</span>
      {!lines && !last ? <br /> : null}
    </>
  )

  if (lines) {
    return (
      <blockquote className={className} ref={box as React.RefObject<HTMLQuoteElement>}>
        {shown.map((r, i) => (
          <span key={i}>{row(r, i, i === shown.length - 1)}</span>
        ))}
      </blockquote>
    )
  }
  return (
    <p className={className} ref={box as React.RefObject<HTMLParagraphElement>}>
      {shown.map((r, i) => (
        <span key={i} className="tail-row">
          {row(r, i, i === shown.length - 1)}
        </span>
      ))}
    </p>
  )
}
