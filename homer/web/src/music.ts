// Matus's theme (Sat 8:15 PM: "make this the background music"), on the website only: the
// phones are the mics. A low bed under the menu, the lobby, the results and the motion
// games; it ducks while Homer speaks, and in the spoken games (poetry, debate, Talk to
// Homer) it fades out from the count-in through the verdict, so the Mac's speakers never
// leak into a phone's mic or talk over Homer. Every change is a fade; nothing cuts.
// Browsers block autoplay, so it starts at the first click or key after a screen that
// plays it mounts (MusicToggle arms it). The header toggle is remembered per browser;
// the operator's key, M, flips the same toggle (SPEC "Music": a key mutes all music).
// Music, not a sound effect: outside the SPEC's no-effects rule (Matus's call).

import { useEffect, useId, useSyncExternalStore } from 'react'

const SRC = '/audio/menin-theme.m4a?v=3' // v3: v2's master without its 59.8 s of leading silence; the query skips a cached copy
// Levels for the loudness-normalised master (−16.7 LUFS): a bed you hear on MacBook
// speakers, ducked well under Homer.
const BED = 0.5
const DUCKED = 0.15
const FADE_S = 1.5
const KEY = 'menin.music'

type Want = { hush: boolean; duck: boolean }

function readEnabled(): boolean {
  try {
    return localStorage.getItem(KEY) !== 'off'
  } catch {
    return true
  }
}

class Music {
  enabled = readEnabled()
  private audio: HTMLAudioElement | null = null
  private gain: GainNode | null = null
  private ctx: AudioContext | null = null
  private wants = new Map<string, Want>()
  private listeners = new Set<() => void>()
  private armed = false
  private stopTimer = 0

  /** Start at the first gesture (once), and listen for M; a screen that plays the music calls this on mount. */
  arm() {
    if (this.armed) return
    this.armed = true
    const go = () => {
      window.removeEventListener('pointerdown', go, true)
      window.removeEventListener('keydown', go, true)
      this.start()
    }
    window.addEventListener('pointerdown', go, true)
    window.addEventListener('keydown', go, true)
    window.addEventListener('keydown', (e) => {
      if (e.key !== 'm' && e.key !== 'M') return
      if (e.repeat || e.metaKey || e.ctrlKey || e.altKey) return
      const t = e.target as HTMLElement | null
      if (t && (t.isContentEditable || /^(INPUT|TEXTAREA|SELECT)$/.test(t.tagName))) return // typing, not the key
      this.setEnabled(!this.enabled)
    })
  }

  /** One screen's wish: hush (a spoken turn is on) and duck (Homer is speaking). Any hush wins. */
  claim(id: string, want: Want) {
    this.wants.set(id, want)
    this.apply()
  }

  release(id: string) {
    this.wants.delete(id)
    this.apply()
  }

  setEnabled(on: boolean) {
    this.enabled = on
    try {
      localStorage.setItem(KEY, on ? 'on' : 'off')
    } catch {
      // private window: the toggle still works for this visit
    }
    if (on) this.start() // the toggle's click is a gesture, so it may start here
    this.apply()
    this.listeners.forEach((l) => l())
  }

  subscribe = (listener: () => void) => {
    this.listeners.add(listener)
    return () => this.listeners.delete(listener)
  }

  private start() {
    if (!this.enabled) return
    if (!this.audio) {
      const audio = new Audio(SRC)
      audio.loop = true
      audio.preload = 'auto'
      try {
        const ctx = new AudioContext()
        const gain = ctx.createGain()
        gain.gain.value = 0
        ctx.createMediaElementSource(audio).connect(gain).connect(ctx.destination)
        this.ctx = ctx
        this.gain = gain
      } catch {
        audio.volume = 0 // no Web Audio: plain volume steps instead of a ramp
      }
      this.audio = audio
    }
    this.ctx?.resume().catch(() => {})
    this.audio.play().catch(() => {})
    this.apply()
  }

  private level(): number {
    if (!this.enabled) return 0
    const wants = [...this.wants.values()]
    if (wants.some((w) => w.hush)) return 0
    return wants.some((w) => w.duck) ? DUCKED : BED
  }

  /** Fade to the level the screens want; once faded out for good (off), pause. */
  private apply() {
    const audio = this.audio
    if (!audio) return
    const target = this.level()
    if (this.gain && this.ctx) {
      const now = this.ctx.currentTime
      const g = this.gain.gain
      g.cancelScheduledValues(now)
      g.setValueAtTime(g.value, now)
      g.setTargetAtTime(target, now, FADE_S / 4) // ~98% of the way in FADE_S
    } else {
      audio.volume = target
    }
    window.clearTimeout(this.stopTimer)
    if (!this.enabled) {
      this.stopTimer = window.setTimeout(() => audio.pause(), FADE_S * 1000 + 300)
    } else if (audio.paused) {
      audio.play().catch(() => {})
    }
  }
}

export const music = new Music()

/** A screen's wish for the music while it's mounted. Arms the first-click start. */
export function useMusic(want: Partial<Want> = {}) {
  const id = useId()
  const hush = Boolean(want.hush)
  const duck = Boolean(want.duck)
  useEffect(() => {
    music.arm()
    return () => music.release(id)
  }, [id])
  useEffect(() => {
    music.claim(id, { hush, duck })
  }, [id, hush, duck])
}

/** The toggle's state, remembered in localStorage. */
export function useMusicEnabled(): [boolean, (on: boolean) => void] {
  const on = useSyncExternalStore(music.subscribe, () => music.enabled)
  return [on, (next: boolean) => music.setEnabled(next)]
}
