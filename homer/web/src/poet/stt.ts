// Cartesia's streaming STT from the browser, for a poet with no app (the Safari controller). The same session
// the app's CartesiaSTT.swift runs (docs/voice.md "1. STT"): the manual endpoint, 16 kHz pcm_s16le frames of
// ~100 ms, "finalize" when the turn ends (then "flush_done"), "close" to end. Finals carry the text since the
// previous final and are joined exactly as received; the latest partial is the live tail.

export type SttToken = {
  token: string
  cartesiaVersion: string
  stt?: { model: string; encoding: string; sampleRate: number }
}

const ENDPOINT = 'wss://api.cartesia.ai/stt/websocket'
const KEYTERM_BUDGET = 1200 // ink-2: up to 100 terms and 1200 characters
const FLUSH_WAIT_MS = 1500 // after "finalize", wait this long for the last finals at most

export class BrowserStt {
  private ws: WebSocket | null = null
  private finals = ''
  private partial = ''
  private flushed: (() => void) | null = null
  readonly sampleRate: number
  sent = 0 // frames sent, and what came back (test halls read these)
  received = 0
  last = ''
  closed = ''

  constructor(
    private readonly token: SttToken,
    private readonly keyterms: string[],
    private readonly onText: (text: string) => void,
  ) {
    this.sampleRate = token.stt?.sampleRate ?? 16000
  }

  /** Open the session; resolves once the socket is up (call it before the count-in, so no word is clipped). */
  open(): Promise<void> {
    const stt = this.token.stt ?? { model: 'ink-2', encoding: 'pcm_s16le', sampleRate: 16000 }
    const q = new URLSearchParams({
      model: stt.model,
      encoding: stt.encoding,
      sample_rate: String(stt.sampleRate),
      cartesia_version: this.token.cartesiaVersion,
      access_token: this.token.token,
    })
    if (stt.model.startsWith('ink-2')) {
      let budget = KEYTERM_BUDGET
      for (const term of this.keyterms.slice(0, 100)) {
        if (term.length > budget) break
        q.append('keyterm', term)
        budget -= term.length
      }
    }
    const ws = new WebSocket(`${ENDPOINT}?${q}`)
    ws.binaryType = 'arraybuffer'
    this.ws = ws
    ws.onmessage = (e) => this.message(e.data)
    ws.onclose = (e) => (this.closed = `${e.code} ${e.reason}`.trim())
    return new Promise((resolve, reject) => {
      ws.onopen = () => resolve()
      ws.onerror = () => reject(new Error('speech-to-text unreachable'))
    })
  }

  /** One ~100 ms frame of 16-bit mono PCM. Frames are never dropped mid-turn (word timing depends on it). */
  send(frame: ArrayBuffer): void {
    if (this.ws?.readyState === WebSocket.OPEN) {
      this.ws.send(frame)
      this.sent += 1
    }
  }

  /** The whole transcript so far: the finals, then the live partial. */
  text(): string {
    return (this.finals + this.partial).trim()
  }

  /** End of the turn: flush the last finals (or give up after FLUSH_WAIT_MS) and return the transcript. */
  async finalize(): Promise<string> {
    const ws = this.ws
    if (ws?.readyState === WebSocket.OPEN) {
      const done = new Promise<void>((resolve) => (this.flushed = resolve))
      ws.send('finalize')
      await Promise.race([done, new Promise((r) => window.setTimeout(r, FLUSH_WAIT_MS))])
    }
    return this.text()
  }

  close(): void {
    const ws = this.ws
    this.ws = null
    if (!ws) return
    try {
      if (ws.readyState === WebSocket.OPEN) ws.send('close')
      ws.close()
    } catch {
      // already gone
    }
  }

  private message(data: unknown): void {
    this.received += 1
    if (typeof data !== 'string') return
    this.last = data.slice(0, 160)
    let m: { type?: string; is_final?: boolean; text?: string }
    try {
      m = JSON.parse(data)
    } catch {
      return
    }
    if (m.type === 'transcript') {
      if (m.is_final) {
        this.finals += m.text ?? ''
        this.partial = ''
      } else {
        this.partial = m.text ?? ''
      }
      this.onText(this.text())
    } else if (m.type === 'flush_done') {
      this.flushed?.()
      this.flushed = null
    }
  }
}
