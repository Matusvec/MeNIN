// Homer's voice in the browser, on a click: one Cartesia generation at a time,
// never during a battle. Cartesia allows two generations at once, account-wide,
// and the arena needs them. The agent refuses a `web` token (409) while a
// battle runs, so the page simply stays text-only then. Text is always shown
// first; the voice is extra.

import { AgentError, voiceToken } from './agent'

const SAMPLE_RATE = 44100
let busy = false

export type VoiceResult = 'spoken' | 'busy' | 'unavailable'

/** Speak `text` in Homer's voice. Resolves when the audio has finished (or failed). */
export async function speakAloud(text: string, onStart?: () => void): Promise<VoiceResult> {
  if (busy || !text.trim()) return 'busy'
  busy = true
  const audio = new AudioContext({ sampleRate: SAMPLE_RATE })
  try {
    const token = await voiceToken()
    await audio.resume()
    const url =
      `wss://api.cartesia.ai/tts/websocket?cartesia_version=${encodeURIComponent(token.cartesiaVersion)}` +
      `&access_token=${encodeURIComponent(token.token)}`
    const contextId = `web-${Date.now()}`
    let next = 0
    let started = false
    await new Promise<void>((resolve, reject) => {
      const socket = new WebSocket(url)
      const timeout = window.setTimeout(() => {
        socket.close()
        reject(new Error('timeout'))
      }, 20000)
      socket.onopen = () =>
        socket.send(
          JSON.stringify({
            model_id: token.tts.model,
            transcript: text,
            voice: { mode: 'id', id: token.tts.voiceId },
            output_format: { container: 'raw', encoding: 'pcm_f32le', sample_rate: SAMPLE_RATE },
            language: 'en',
            context_id: contextId,
            continue: false,
          }),
        )
      socket.onmessage = (message) => {
        const body = JSON.parse(String(message.data))
        if (body.type === 'chunk' && body.data) {
          const bytes = Uint8Array.from(atob(body.data), (c) => c.charCodeAt(0))
          const samples = new Float32Array(bytes.buffer, 0, Math.floor(bytes.byteLength / 4))
          const buffer = audio.createBuffer(1, samples.length, SAMPLE_RATE)
          buffer.copyToChannel(samples, 0)
          const source = audio.createBufferSource()
          source.buffer = buffer
          source.connect(audio.destination)
          next = Math.max(next, audio.currentTime + 0.05)
          source.start(next)
          next += buffer.duration
          if (!started) {
            started = true
            onStart?.()
          }
        }
        if (body.type === 'error') {
          window.clearTimeout(timeout)
          socket.close()
          reject(new Error(body.error || 'tts error'))
        }
        if (body.done || body.type === 'done') {
          window.clearTimeout(timeout)
          socket.close()
          resolve()
        }
      }
      socket.onerror = () => {
        window.clearTimeout(timeout)
        reject(new Error('socket error'))
      }
    })
    const left = Math.max(0, next - audio.currentTime)
    await new Promise((resolve) => window.setTimeout(resolve, left * 1000))
    return started ? 'spoken' : 'unavailable'
  } catch (error) {
    return error instanceof AgentError && error.status === 409 ? 'busy' : 'unavailable'
  } finally {
    busy = false
    void audio.close()
  }
}
