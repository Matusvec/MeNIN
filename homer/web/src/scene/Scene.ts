// The painted sea behind the battle, ported from the iOS app's Metal scene.
// WebGL2: the field and the flecks render into a half-resolution texture, then
// a finish pass grades it at screen resolution (devicePixelRatio capped at 1.25).
// 60 fps while a voice is live, 30 otherwise, and nothing at all in a hidden tab.

import { MOOD_COUNT, STYLES, ink, type EmotionWeights } from './moods'
import { FLECK_COUNT, FLECK_STRIDE, RIPPLE_COUNT, SceneMotion } from './motion'
import { FIELD_FRAG, FINISH_FRAG, FLECK_FRAG, FLECK_VERT, FULLSCREEN_VERT } from './shaders'

const MAX_DPR = 1.25
/** The field renders at this fraction of the canvas: it's soft paint, the finish adds the grain. */
const FIELD_SCALE = 0.5
/** The page's white point (cool, for HohHamNap's sky) and a whisper of vignette. */
const WHITE: [number, number, number] = [0.99, 0.995, 1.0]
const VIGNETTE = 0.05

type Program = { program: WebGLProgram; u: Record<string, WebGLUniformLocation | null> }

export class MeninScene {
  private gl: WebGL2RenderingContext
  private motion = new SceneMotion()
  private field: Program
  private fleck: Program
  private finish: Program
  private fleckVao: WebGLVertexArrayObject
  private fleckBuffer: WebGLBuffer
  private emptyVao: WebGLVertexArrayObject
  private fbo: WebGLFramebuffer | null = null
  private fieldTex: WebGLTexture | null = null
  private fieldSize = [0, 0]
  private raf = 0
  private last = 0
  private running = false
  private lost = false
  private inks = new Float32Array(MOOD_COUNT * 4 * 3)
  private onVisibility = () => this.syncRunning()
  private onLost = (e: Event) => {
    e.preventDefault()
    this.lost = true
    cancelAnimationFrame(this.raf)
  }
  private reducedQuery = window.matchMedia('(prefers-reduced-motion: reduce)')

  /** Throws when WebGL2 isn't available; the caller leaves the page's own background in place. */
  constructor(private canvas: HTMLCanvasElement) {
    const gl = canvas.getContext('webgl2', { alpha: false, antialias: false, premultipliedAlpha: true, powerPreference: 'high-performance' })
    if (!gl) throw new Error('WebGL2 unavailable')
    this.gl = gl
    this.field = this.link(FULLSCREEN_VERT, FIELD_FRAG, ['uA', 'uB', 'uC', 'uD', 'uWashInk', 'uWashFrom', 'uRip', 'uW', 'uE', 'uInks'])
    this.fleck = this.link(FLECK_VERT, FLECK_FRAG, ['uView'])
    this.finish = this.link(FULLSCREEN_VERT, FINISH_FRAG, ['uScene', 'uA', 'uB'])

    STYLES.forEach((style, m) => style.inks.forEach((hex, i) => this.inks.set(ink(hex), (m * 4 + i) * 3)))

    this.emptyVao = gl.createVertexArray()!
    this.fleckVao = gl.createVertexArray()!
    this.fleckBuffer = gl.createBuffer()!
    gl.bindVertexArray(this.fleckVao)
    gl.bindBuffer(gl.ARRAY_BUFFER, this.fleckBuffer)
    gl.bufferData(gl.ARRAY_BUFFER, this.motion.flecks.byteLength, gl.DYNAMIC_DRAW)
    const stride = FLECK_STRIDE * 4
    gl.enableVertexAttribArray(0)
    gl.vertexAttribPointer(0, 4, gl.FLOAT, false, stride, 0)
    gl.enableVertexAttribArray(1)
    gl.vertexAttribPointer(1, 4, gl.FLOAT, false, stride, 16)
    gl.enableVertexAttribArray(2)
    gl.vertexAttribPointer(2, 1, gl.FLOAT, false, stride, 32)
    gl.bindVertexArray(null)

    this.motion.reducedMotion = this.reducedQuery.matches
    document.addEventListener('visibilitychange', this.onVisibility)
    canvas.addEventListener('webglcontextlost', this.onLost)
  }

  setEmotion(weights: EmotionWeights | null) {
    this.motion.setEmotion(weights)
  }

  setProsody(energy: number, pitch: number | null) {
    this.motion.setProsody(energy, pitch)
  }

  strike(strength = 1) {
    this.motion.strike(strength)
  }

  start() {
    this.running = true
    this.syncRunning()
  }

  dispose() {
    this.running = false
    cancelAnimationFrame(this.raf)
    document.removeEventListener('visibilitychange', this.onVisibility)
    this.canvas.removeEventListener('webglcontextlost', this.onLost)
    const gl = this.gl
    if (this.fbo) gl.deleteFramebuffer(this.fbo)
    if (this.fieldTex) gl.deleteTexture(this.fieldTex)
    gl.deleteBuffer(this.fleckBuffer)
    gl.deleteVertexArray(this.fleckVao)
    gl.deleteVertexArray(this.emptyVao)
    for (const p of [this.field, this.fleck, this.finish]) gl.deleteProgram(p.program)
  }

  private syncRunning() {
    cancelAnimationFrame(this.raf)
    if (this.running && !document.hidden && !this.lost) {
      this.last = 0
      this.raf = requestAnimationFrame(this.frame)
    }
  }

  private frame = (now: number) => {
    this.raf = requestAnimationFrame(this.frame)
    // 60 fps while a voice is live; 30 fps for the resting sea.
    const minGap = this.motion.voiced ? 0 : 1000 / 30 - 2
    if (this.last && now - this.last < minGap) return
    const dt = this.last ? (now - this.last) / 1000 : 1 / 60
    this.last = now
    this.render(dt)
  }

  private render(dt: number) {
    const gl = this.gl
    const dpr = Math.min(window.devicePixelRatio || 1, MAX_DPR)
    const w = Math.max(1, Math.round(this.canvas.clientWidth * dpr))
    const h = Math.max(1, Math.round(this.canvas.clientHeight * dpr))
    if (this.canvas.width !== w || this.canvas.height !== h) {
      this.canvas.width = w
      this.canvas.height = h
    }
    const fw = Math.max(1, Math.round(w * FIELD_SCALE))
    const fh = Math.max(1, Math.round(h * FIELD_SCALE))
    this.ensureField(fw, fh)

    this.motion.aspect = w / h
    this.motion.step(dt, fw, fh)
    const U = this.motion.uniforms

    // 1. The field, into the half-resolution texture.
    gl.bindFramebuffer(gl.FRAMEBUFFER, this.fbo)
    gl.viewport(0, 0, fw, fh)
    gl.disable(gl.BLEND)
    gl.useProgram(this.field.program)
    const fu = this.field.u
    gl.uniform4fv(fu.uA, U.a)
    gl.uniform4fv(fu.uB, U.b)
    gl.uniform4fv(fu.uC, U.c)
    gl.uniform4fv(fu.uD, U.d)
    gl.uniform4fv(fu.uWashInk, U.washInk)
    gl.uniform4fv(fu.uWashFrom, U.washFrom)
    gl.uniform4fv(fu.uRip, U.rip, 0, RIPPLE_COUNT * 4)
    gl.uniform1fv(fu.uW, U.w)
    gl.uniform4fv(fu.uE, U.e)
    gl.uniform3fv(fu.uInks, this.inks)
    gl.bindVertexArray(this.emptyVao)
    gl.drawArrays(gl.TRIANGLES, 0, 3)

    // 2. The flecks over it: flat paper, premultiplied, no additive glow.
    gl.enable(gl.BLEND)
    gl.blendFunc(gl.ONE, gl.ONE_MINUS_SRC_ALPHA)
    gl.useProgram(this.fleck.program)
    // Field pixels per CSS px: the flecks keep their size whatever the screen.
    gl.uniform2f(this.fleck.u.uView, w / h, (fw / Math.max(1, this.canvas.clientWidth)))
    gl.bindVertexArray(this.fleckVao)
    gl.bindBuffer(gl.ARRAY_BUFFER, this.fleckBuffer)
    gl.bufferSubData(gl.ARRAY_BUFFER, 0, this.motion.flecks)
    gl.drawArrays(gl.POINTS, 0, FLECK_COUNT)
    gl.disable(gl.BLEND)

    // 3. The finish, to the screen.
    gl.bindFramebuffer(gl.FRAMEBUFFER, null)
    gl.viewport(0, 0, w, h)
    gl.useProgram(this.finish.program)
    gl.activeTexture(gl.TEXTURE0)
    gl.bindTexture(gl.TEXTURE_2D, this.fieldTex)
    gl.uniform1i(this.finish.u.uScene, 0)
    gl.uniform4f(this.finish.u.uA, w, h, this.motion.time, VIGNETTE)
    gl.uniform4f(this.finish.u.uB, WHITE[0], WHITE[1], WHITE[2], 0)
    gl.bindVertexArray(this.emptyVao)
    gl.drawArrays(gl.TRIANGLES, 0, 3)
    gl.bindVertexArray(null)
  }

  private ensureField(w: number, h: number) {
    if (this.fieldTex && this.fieldSize[0] === w && this.fieldSize[1] === h) return
    const gl = this.gl
    if (this.fbo) gl.deleteFramebuffer(this.fbo)
    if (this.fieldTex) gl.deleteTexture(this.fieldTex)
    this.fieldTex = gl.createTexture()
    gl.bindTexture(gl.TEXTURE_2D, this.fieldTex)
    gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA8, w, h, 0, gl.RGBA, gl.UNSIGNED_BYTE, null)
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR)
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE)
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE)
    this.fbo = gl.createFramebuffer()
    gl.bindFramebuffer(gl.FRAMEBUFFER, this.fbo)
    gl.framebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, this.fieldTex, 0)
    gl.bindFramebuffer(gl.FRAMEBUFFER, null)
    this.fieldSize = [w, h]
  }

  private link(vert: string, frag: string, uniforms: string[]): Program {
    const gl = this.gl
    const compile = (type: number, src: string) => {
      const s = gl.createShader(type)!
      gl.shaderSource(s, src)
      gl.compileShader(s)
      if (!gl.getShaderParameter(s, gl.COMPILE_STATUS)) throw new Error(gl.getShaderInfoLog(s) || 'shader failed')
      return s
    }
    const program = gl.createProgram()!
    const vs = compile(gl.VERTEX_SHADER, vert)
    const fs = compile(gl.FRAGMENT_SHADER, frag)
    gl.attachShader(program, vs)
    gl.attachShader(program, fs)
    gl.linkProgram(program)
    gl.deleteShader(vs)
    gl.deleteShader(fs)
    if (!gl.getProgramParameter(program, gl.LINK_STATUS)) throw new Error(gl.getProgramInfoLog(program) || 'link failed')
    const u: Program['u'] = {}
    for (const name of uniforms) u[name] = gl.getUniformLocation(program, name)
    return { program, u }
  }
}
