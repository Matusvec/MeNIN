// The browser poet's mic (the Safari controller): one getUserMedia stream, opened on the Join tap (iOS Safari
// asks for the mic from a gesture), kept for the whole hall. Frames go to the STT only from the count-in to
// the end of the turn (the mic "opens" at the count-in, as on the phone). 16 kHz 16-bit mono, ~100 ms frames;
// loudness and onsets for the arena's sea (set_prosody), like the app's MicEngine.

const FRAME_MS = 100
const ONSET_RISE = 0.08 // a loudness jump this big over the running base is a syllable onset (a "hit")

export type MicFrame = { pcm: ArrayBuffer; loudness: number; onset: boolean }

export class BrowserMic {
  private stream: MediaStream | null = null
  private ctx: AudioContext | null = null
  private node: ScriptProcessorNode | null = null
  private pending: number[] = []
  private base = 0
  private listener: ((frame: MicFrame) => void) | null = null
  level = 0 // 0..1, for the mic check
  frames = 0 // frames handed to a listener (test halls read it)

  get audioState(): string {
    return this.ctx?.state ?? 'none'
  }

  get isOpen(): boolean {
    return this.stream !== null
  }

  constructor(private readonly rate = 16000) {}

  /** Ask for the mic and start the audio graph. Call from a tap: iOS Safari needs the gesture for both. */
  async open(): Promise<void> {
    if (this.stream) return
    this.stream = await navigator.mediaDevices.getUserMedia({
      audio: { echoCancellation: true, noiseSuppression: true, autoGainControl: true, channelCount: 1 },
    })
    const Ctx = window.AudioContext ?? (window as unknown as { webkitAudioContext: typeof AudioContext }).webkitAudioContext
    let ctx: AudioContext
    try {
      ctx = new Ctx({ sampleRate: this.rate }) // the browser resamples the mic for us
    } catch {
      ctx = new Ctx() // some browsers won't run at 16 kHz: resample below
    }
    await ctx.resume()
    this.ctx = ctx
    const source = ctx.createMediaStreamSource(this.stream)
    const node = ctx.createScriptProcessor(1024, 1, 1)
    node.onaudioprocess = (e) => this.process(e.inputBuffer.getChannelData(0), ctx.sampleRate)
    source.connect(node)
    node.connect(ctx.destination) // a ScriptProcessor only runs while connected; it writes silence
    this.node = node
  }

  /** Frames go to `fn` until stop(); nothing is sent while no one listens. */
  listen(fn: ((frame: MicFrame) => void) | null): void {
    this.listener = fn
    this.pending = []
  }

  close(): void {
    this.listener = null
    this.node?.disconnect()
    this.stream?.getTracks().forEach((t) => t.stop())
    void this.ctx?.close()
    this.stream = this.ctx = this.node = null
  }

  private process(input: Float32Array, rate: number): void {
    let sum = 0
    for (const s of input) sum += s * s
    this.level = Math.min(1, Math.sqrt(sum / input.length) * 4)
    if (!this.listener) return // between turns: only the level meter
    // Downsample to `this.rate` (a no-op when the context already runs at it).
    const step = rate / this.rate
    for (let i = 0; i < input.length / step; i++) this.pending.push(input[Math.floor(i * step)])
    const perFrame = (this.rate * FRAME_MS) / 1000
    while (this.pending.length >= perFrame) {
      const chunk = this.pending.splice(0, perFrame)
      const pcm = new Int16Array(perFrame)
      let energy = 0
      for (let i = 0; i < perFrame; i++) {
        const s = Math.max(-1, Math.min(1, chunk[i]))
        pcm[i] = s < 0 ? s * 0x8000 : s * 0x7fff
        energy += s * s
      }
      const loudness = Math.min(1, Math.sqrt(energy / perFrame) * 4)
      const onset = loudness - this.base > ONSET_RISE
      this.base += (loudness - this.base) * 0.2
      this.frames += 1
      this.listener?.({ pcm: pcm.buffer, loudness, onset })
    }
  }
}
