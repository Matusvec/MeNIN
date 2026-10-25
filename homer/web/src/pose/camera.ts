// The arena Mac's webcam and MediaPipe's pose model, in the browser (SPEC "Toxeia", camera: nothing leaves
// the Mac). The lite model on the GPU (CPU if the GPU won't start), VIDEO mode, one person, ~30 fps. The
// model and the wasm are served from this site (public/pose/, and Vite bundles the wasm from the package):
// no CDN at runtime, because the venue wifi is bad. In a test hall a video file can stand in for the webcam
// (`file`, from ?camera-file=…): the same model, mapper and corner view, for headless runs.

import { PoseLandmarker, type Landmark, type NormalizedLandmark } from '@mediapipe/tasks-vision'
import wasmLoaderPath from '@mediapipe/tasks-vision/vision_wasm_internal.js?url'
import wasmBinaryPath from '@mediapipe/tasks-vision/vision_wasm_internal.wasm?url'

const MODEL = `${import.meta.env.BASE_URL}pose/pose_landmarker_lite.task`
const FRAME_MS = 30 // ~30 fps: the lite model's budget on a Mac that also hosts everything else

export type CameraStatus = 'off' | 'starting' | 'live' | 'denied' | 'failed'

/** One video frame's pose: image landmarks (0..1, unmirrored) and world landmarks (metres, about the hips). */
export type PoseFrame = { at: number; image: NormalizedLandmark[] | null; world: Landmark[] | null }

export class PoseCamera {
  status: CameraStatus = 'off'
  stream: MediaStream | null = null
  error = ''
  private video: HTMLVideoElement | null = null
  private landmarker: PoseLandmarker | null = null
  private raf = 0
  private lastFrame = -1
  private lastDetect = 0
  private run = 0 // bumped by stop(): a start still loading the model gives up

  constructor(
    private readonly onFrame: (frame: PoseFrame) => void,
    private readonly onStatus: () => void,
  ) {}

  async start(file = ''): Promise<void> {
    if (this.status === 'starting' || this.status === 'live') return
    const run = ++this.run
    this.set('starting')
    try {
      const video = document.createElement('video')
      video.muted = true
      video.playsInline = true
      let stream: MediaStream
      if (file) {
        video.src = file
        video.loop = true
        video.crossOrigin = 'anonymous'
        await video.play()
        stream = (video as HTMLVideoElement & { captureStream: () => MediaStream }).captureStream()
      } else {
        stream = await navigator.mediaDevices.getUserMedia({
          video: { width: { ideal: 640 }, height: { ideal: 480 }, frameRate: { ideal: 30 } },
          audio: false,
        })
        if (run !== this.run) return stream.getTracks().forEach((t) => t.stop())
        video.srcObject = stream
        await video.play()
      }
      this.stream = stream
      this.video = video
      const landmarker = await this.load()
      if (run !== this.run) return landmarker.close()
      this.landmarker = landmarker
      // A camera unplugged or taken by another app ends the track: the phones take over.
      stream.getVideoTracks()[0]?.addEventListener('ended', () => this.fail('The camera stopped'))
      this.set('live')
      this.raf = requestAnimationFrame(this.loop)
    } catch (error) {
      if (run !== this.run) return
      const name = error instanceof DOMException ? error.name : ''
      this.fail(error instanceof Error ? error.message : String(error), name === 'NotAllowedError' || name === 'SecurityError' ? 'denied' : 'failed')
    }
  }

  stop(): void {
    this.run += 1
    this.release()
    this.set('off')
  }

  private async load(): Promise<PoseLandmarker> {
    const options = (delegate: 'GPU' | 'CPU') => ({
      baseOptions: { modelAssetPath: MODEL, delegate },
      runningMode: 'VIDEO' as const,
      numPoses: 1,
      minPoseDetectionConfidence: 0.5,
      minPosePresenceConfidence: 0.5,
      minTrackingConfidence: 0.5,
    })
    try {
      return await PoseLandmarker.createFromOptions({ wasmLoaderPath, wasmBinaryPath }, options('GPU'))
    } catch (error) {
      console.warn('MeNIN camera: the GPU delegate failed, using the CPU:', error)
      return PoseLandmarker.createFromOptions({ wasmLoaderPath, wasmBinaryPath }, options('CPU'))
    }
  }

  private loop = (): void => {
    this.raf = requestAnimationFrame(this.loop)
    const video = this.video
    const landmarker = this.landmarker
    if (!video || !landmarker || video.readyState < 2) return
    const now = performance.now()
    if (video.currentTime === this.lastFrame || now - this.lastDetect < FRAME_MS) return
    this.lastFrame = video.currentTime
    this.lastDetect = now
    try {
      const result = landmarker.detectForVideo(video, now)
      this.onFrame({ at: now, image: result.landmarks[0] ?? null, world: result.worldLandmarks[0] ?? null })
    } catch (error) {
      this.fail(error instanceof Error ? error.message : String(error))
    }
  }

  private fail(message: string, status: CameraStatus = 'failed'): void {
    console.warn('MeNIN camera:', message)
    this.run += 1
    this.release()
    this.error = message
    this.set(status)
  }

  private release(): void {
    cancelAnimationFrame(this.raf)
    this.landmarker?.close()
    this.landmarker = null
    this.stream?.getTracks().forEach((t) => t.stop())
    this.stream = null
    if (this.video) {
      this.video.pause()
      this.video.srcObject = null
      this.video.removeAttribute('src')
    }
    this.video = null
    this.lastFrame = -1
  }

  private set(status: CameraStatus): void {
    this.status = status
    if (status !== 'failed' && status !== 'denied') this.error = ''
    this.onStatus()
  }
}
