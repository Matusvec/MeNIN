// Homer's voice on the web arena: Cartesia text-to-speech over one WebSocket, one
// generation at a time (Cartesia allows two at once, account-wide). The token comes
// from the agent's /voice/token (role "arena") and is renewed before it expires.
// The arena's line queue already serializes calls; `speak` also refuses overlap.

import { voiceToken, type VoiceToken } from './agent'

const SAMPLE_RATE = 44100
type Pending = { resolve: () => void; reject: (error: Error) => void; started: boolean; onStart?: () => void }

export class HomerVoice {
  private socket: WebSocket | null = null
  private token: (VoiceToken & { expiresAt?: number }) | null = null
  private pending = new Map<string, Pending>()
  private next = 0
  private busy = false

  constructor(readonly ctx: AudioContext) {}

  private async open(): Promise<WebSocket> {
    const fresh = this.token !== null && (this.token.expiresAt ?? 0) - Date.now() > 30000
    if (this.socket?.readyState === WebSocket.OPEN && fresh) return this.socket
    this.socket?.close()
    // Cartesia closes an idle socket between lines; a token is good for minutes, so only reconnect.
    const token = fresh && this.token ? this.token : (this.token = await voiceToken())
    const url =
      `wss://api.cartesia.ai/tts/websocket?cartesia_version=${encodeURIComponent(token.cartesiaVersion)}` +
      `&access_token=${encodeURIComponent(token.token)}`
    const socket = new WebSocket(url)
    await new Promise<void>((resolve, reject) => {
      const timer = window.setTimeout(() => reject(new Error('voice socket timeout')), 8000)
      socket.onopen = () => {
        window.clearTimeout(timer)
        resolve()
      }
      socket.onerror = () => {
        window.clearTimeout(timer)
        reject(new Error('voice socket error'))
      }
    })
    socket.onmessage = (message) => this.receive(String(message.data))
    socket.onclose = () => {
      if (this.socket === socket) this.socket = null
      for (const p of this.pending.values()) p.reject(new Error('voice socket closed'))
      this.pending.clear()
    }
    this.socket = socket
    return socket
  }

  private receive(raw: string): void {
    const body = JSON.parse(raw)
    const p = this.pending.get(body.context_id)
    if (!p) return
    if (body.type === 'chunk' && body.data) {
      const bytes = Uint8Array.from(atob(body.data), (c) => c.charCodeAt(0))
      const samples = new Float32Array(bytes.buffer, 0, Math.floor(bytes.byteLength / 4))
      const buffer = this.ctx.createBuffer(1, samples.length, SAMPLE_RATE)
      buffer.copyToChannel(samples, 0)
      const source = this.ctx.createBufferSource()
      source.buffer = buffer
      source.connect(this.ctx.destination)
      this.next = Math.max(this.next, this.ctx.currentTime + 0.05)
      source.start(this.next)
      this.next += buffer.duration
      if (!p.started) {
        p.started = true
        p.onStart?.()
      }
    }
    if (body.type === 'error') {
      this.pending.delete(body.context_id)
      p.reject(new Error(body.error || 'voice error'))
    } else if (body.done || body.type === 'done') {
      this.pending.delete(body.context_id)
      p.resolve()
    }
  }

  /** Speak `text`; resolves when the audio has finished playing. Throws if the voice can't be reached. */
  async speak(text: string, onStart?: () => void, host: 'homer' | 'socrates' = 'homer'): Promise<void> {
    if (this.busy) throw new Error('one generation at a time')
    this.busy = true
    try {
      const socket = await this.open()
      const contextId = `arena-${Date.now()}-${Math.random().toString(36).slice(2, 8)}`
      const done = new Promise<void>((resolve, reject) => this.pending.set(contextId, { resolve, reject, started: false, onStart }))
      socket.send(
        JSON.stringify({
          model_id: this.token!.tts.model,
          transcript: text,
          voice: { mode: 'id', id: this.token!.tts.voices?.[host] || this.token!.tts.voiceId },
          output_format: { container: 'raw', encoding: 'pcm_f32le', sample_rate: SAMPLE_RATE },
          language: 'en',
          context_id: contextId,
          continue: false,
        }),
      )
      // No audio within 3 s: give up on this line (the arena falls back to text). A line never runs past 15 s.
      const firstAudio = window.setTimeout(() => {
        const p = this.pending.get(contextId)
        if (p && !p.started) {
          this.pending.delete(contextId)
          p.reject(new Error('voice slow'))
        }
      }, 3000)
      try {
        await Promise.race([done, new Promise((_, reject) => window.setTimeout(() => reject(new Error('voice timeout')), 15000))])
      } finally {
        window.clearTimeout(firstAudio)
      }
      const left = Math.max(0, this.next - this.ctx.currentTime)
      await new Promise((resolve) => window.setTimeout(resolve, left * 1000))
    } finally {
      this.busy = false
    }
  }

  close(): void {
    this.socket?.close()
  }
}
