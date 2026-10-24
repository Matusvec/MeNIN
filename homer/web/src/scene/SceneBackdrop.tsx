// The painted sea behind the battle (the iOS app's scene, on the website).
// Mount it anywhere: it renders into <body> behind the page (a canvas fixed to
// the viewport), because the workspace's backdrop-filter would trap a fixed
// child. Feed it the room's data; it smooths everything itself.

import { useEffect, useRef, useState } from 'react'
import { createPortal } from 'react-dom'
import type { EmotionWeights } from './moods'
import { MeninScene } from './Scene'

export type SceneBackdropProps = {
  /** The room's scene row (the emotion engine's reading, ~every 1.5 s). Null or empty rests. */
  emotion: EmotionWeights | null
  /** The live speaker's loudness, 0...1 (~20 Hz). 0 when nobody speaks. */
  energy: number
  /** The live speaker's pitch in Hz, or null. */
  pitch: number | null
  /** The speaker's hit count: each increase is a drum strike. */
  hits: number
  /** Changes per turn, so a new speaker's hit count starts fresh. */
  turnKey: string
}

export default function SceneBackdrop({ emotion, energy, pitch, hits, turnKey }: SceneBackdropProps) {
  const canvas = useRef<HTMLCanvasElement>(null)
  const scene = useRef<MeninScene | null>(null)
  const [on, setOn] = useState(false)
  const seen = useRef({ turnKey, hits })

  useEffect(() => {
    if (!canvas.current) return
    try {
      const s = new MeninScene(canvas.current)
      s.start()
      scene.current = s
      setOn(true)
      return () => {
        s.dispose()
        scene.current = null
      }
    } catch (error) {
      // No WebGL2: the page keeps its own background.
      console.warn('MeNIN scene off:', error)
    }
  }, [])

  // Only a real change of feeling reaches the scene (the row object is new on every update).
  const emotionKey = emotion ? Object.entries(emotion).map(([k, v]) => `${k}:${(v ?? 0).toFixed(3)}`).join(',') : ''
  useEffect(() => {
    scene.current?.setEmotion(emotion)
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [emotionKey, on])

  useEffect(() => {
    scene.current?.setProsody(energy, pitch)
  }, [energy, pitch, on])

  useEffect(() => {
    if (seen.current.turnKey !== turnKey) {
      seen.current = { turnKey, hits }
      return
    }
    if (hits > seen.current.hits) scene.current?.strike()
    seen.current.hits = hits
  }, [hits, turnKey])

  return createPortal(<canvas ref={canvas} className={`menin-scene${on ? ' on' : ''}`} aria-hidden="true" />, document.body)
}
