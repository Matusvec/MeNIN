// The arena's drum in WebAudio: the beat under Homer's stitched song in the finale, and
// nothing else. Battles are free verse with no metronome (SPEC "The turn", Matus: "I just
// want to spit poetry without the metronome"), so the arena is silent while a poet speaks,
// and there are no stingers or effects (Matus: "silence beats a weird sound").

const BEATS_PER_BAR = 4

export type Grid = {
  beatAtLocalMs: number // beat 1 of line 1, on this browser's clock
  bpm: number
  barsPerLine: number
  lines: number
}

export class Stage {
  private beat: { stop: () => void } | null = null

  constructor(readonly ctx: AudioContext) {}

  /** Seconds on the audio clock for a wall-clock time. */
  private at(localMs: number): number {
    return this.ctx.currentTime + (localMs - Date.now()) / 1000
  }

  private hit(when: number, pitch: number, level: number, length = 0.16): AudioScheduledSourceNode[] {
    const { ctx } = this
    const body = ctx.createOscillator()
    const gain = ctx.createGain()
    body.frequency.setValueAtTime(pitch, when)
    body.frequency.exponentialRampToValueAtTime(Math.max(30, pitch * 0.35), when + length)
    gain.gain.setValueAtTime(0.0001, when)
    gain.gain.exponentialRampToValueAtTime(level, when + 0.005)
    gain.gain.exponentialRampToValueAtTime(0.0001, when + length)
    body.connect(gain).connect(ctx.destination)
    body.start(when)
    body.stop(when + length + 0.02)
    // a breath of noise on top, for the skin of the drum
    const noise = ctx.createBufferSource()
    const buffer = ctx.createBuffer(1, Math.floor(ctx.sampleRate * 0.04), ctx.sampleRate)
    const data = buffer.getChannelData(0)
    for (let i = 0; i < data.length; i++) data[i] = (Math.random() * 2 - 1) * (1 - i / data.length)
    noise.buffer = buffer
    const noiseGain = ctx.createGain()
    noiseGain.gain.value = level * 0.25
    noise.connect(noiseGain).connect(ctx.destination)
    noise.start(when)
    return [body, noise]
  }

  /** The beat for one turn: a count-in bar, then every line's bars. Replaces any beat playing. */
  playBeat(grid: Grid): void {
    this.stopBeat()
    const beatMs = 60000 / Math.max(grid.bpm, 1)
    const barMs = beatMs * BEATS_PER_BAR
    const lineMs = barMs * Math.max(grid.barsPerLine, 1)
    const start = grid.beatAtLocalMs - barMs // the count-in
    const end = grid.beatAtLocalMs + lineMs * Math.max(grid.lines, 1)
    const nodes: AudioScheduledSourceNode[] = []
    for (let t = start, n = 0; t < end; t += beatMs, n++) {
      if (t < Date.now() - 20) continue
      const downbeat = n % BEATS_PER_BAR === 0
      const inLine = t >= grid.beatAtLocalMs
      const speakingBar = inLine && Math.floor((t - grid.beatAtLocalMs) / barMs) % Math.max(grid.barsPerLine, 1) === 0
      const level = (downbeat ? 0.5 : 0.28) * (speakingBar ? 0.55 : 1)
      nodes.push(...this.hit(this.at(t), downbeat ? 120 : 90, level))
    }
    this.beat = {
      stop: () => {
        for (const node of nodes) {
          try {
            node.stop()
          } catch {
            /* already ended */
          }
        }
      },
    }
  }

  stopBeat(): void {
    this.beat?.stop()
    this.beat = null
  }
}
