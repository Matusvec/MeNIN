// Links shared across the site. Replace [TESTFLIGHT_URL] with the public TestFlight link
// (or set VITE_TESTFLIGHT_URL at build time); until it's a real https:// link, pages say
// "ask the host" instead of showing a dead link.

export const TESTFLIGHT_URL: string = import.meta.env.VITE_TESTFLIGHT_URL || '[TESTFLIGHT_URL]'

export const hasTestFlight = (): boolean => TESTFLIGHT_URL.startsWith('https://')

/** The room code in a /join/CODE path, or null. */
export function joinCodeFromPath(path: string): string | null {
  const m = /^\/join\/([A-Za-z]{4})\/?$/.exec(path)
  return m ? m[1].toUpperCase() : null
}

export const appJoinLink = (code: string): string => `homer://join/${code}`
export const webJoinLink = (code: string): string => `${window.location.origin}/join/${code}`
