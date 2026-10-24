// The agent service (homer/API.md, "Agent HTTP endpoints the arena calls").
// No app key: the website's origin is allowed by CORS, and the agent's per-IP
// limits and hourly budget are the guard.

export const AGENT_URL = (import.meta.env.VITE_AGENT_URL || 'https://206.189.237.157.sslip.io').replace(/\/$/, '')

export type VoiceToken = {
  token: string
  cartesiaVersion: string
  tts: { model: string; voiceId: string }
}

export class AgentError extends Error {
  status: number

  constructor(status: number, message: string) {
    super(message)
    this.status = status
  }
}

/** A text-to-speech token for Homer's voice on the arena (W2). */
export async function voiceToken(): Promise<VoiceToken> {
  const res = await fetch(`${AGENT_URL}/voice/token`, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({ role: 'arena' }),
  })
  if (!res.ok) throw new AgentError(res.status, `voice token: HTTP ${res.status}`)
  return res.json()
}
