// The archer on camera (artist): a small mirrored live view in the range's corner,
// with the tracked arms drawn over it, so everyone sees the camera has the archer.
// The bow arm is gold, the drawing arm slip, both on a black keyline, as on the
// pots; the drawing hand rings as the draw fills. A caption says what the camera is
// doing: starting, "Step into view", "Hold still" (zeroing at each arrow), tracking.
// Builder's pose code (src/pose/) feeds it; toxeia.css places it.

import { useEffect, useRef, useState, type CSSProperties } from 'react'

/** 0…1 in the unmirrored video frame (x right, y down), as the pose model returns it. */
export type PosePoint = { x: number; y: number }

export type ArcherPose = {
  bowShoulder: PosePoint
  bowElbow: PosePoint
  bowWrist: PosePoint
  drawShoulder: PosePoint
  drawElbow: PosePoint
  drawWrist: PosePoint
  nose?: PosePoint
  hips?: [PosePoint, PosePoint]
}

export type CameraState = 'starting' | 'searching' | 'steadying' | 'tracking'

export type CameraViewProps = {
  /** The webcam; null hides the view (the camera is off or denied: the phones take over). */
  stream: MediaStream | null
  /** The latest tracked pose, or null when nobody is found. */
  pose: ArcherPose | null
  state: CameraState
  /** 0…1, the draw from the camera: rings the drawing hand. */
  draw?: number
  /** For the operator when the camera falls back ("Camera denied: phones"): shown
   *  as a small pill in the corner, even with no stream. */
  note?: string
}

const INK = '#1f1612'
const SLIP = '#f1dfc4'
const GOLD = '#e2bd6c'

const CAPTION: Record<CameraState, string> = {
  starting: 'Starting the camera…',
  searching: 'Step into view',
  steadying: 'Hold still',
  tracking: 'Tracking',
}

export default function CameraView({ stream, pose, state, draw = 0, note }: CameraViewProps) {
  const video = useRef<HTMLVideoElement>(null)
  const [aspect, setAspect] = useState(16 / 9)

  useEffect(() => {
    const v = video.current
    if (!v || !stream) return
    v.srcObject = stream
    const sized = () => v.videoWidth && v.videoHeight && setAspect(v.videoWidth / v.videoHeight)
    v.addEventListener('loadedmetadata', sized)
    v.play().catch(() => {})
    return () => {
      v.removeEventListener('loadedmetadata', sized)
      v.srcObject = null
    }
  }, [stream])

  if (!stream) {
    return note ? (
      <figure className="tox-cam off">
        <figcaption>
          <i />
          {note}
        </figcaption>
      </figure>
    ) : null
  }
  const W = 100 * aspect
  const H = 100
  const at = (p: PosePoint) => `${(p.x * W).toFixed(1)},${(p.y * H).toFixed(1)}`
  const limb = (pts: PosePoint[]) => pts.map(at).join(' ')
  const shown = pose && state !== 'searching'

  return (
    <figure className={`tox-cam ${state}`} aria-label={`Camera: ${CAPTION[state]}`}>
      <div className="tox-cam-frame" style={{ aspectRatio: `${aspect}` } as CSSProperties}>
        <video ref={video} autoPlay muted playsInline />
        <svg viewBox={`0 0 ${W.toFixed(1)} ${H}`} preserveAspectRatio="none" aria-hidden="true">
          {shown && (
            <g strokeLinecap="round" strokeLinejoin="round" fill="none">
              {/* The body: shoulders, and down to the hips when they're in frame. */}
              <polyline points={limb([pose.bowShoulder, pose.drawShoulder])} stroke={INK} strokeWidth="4.4" />
              <polyline points={limb([pose.bowShoulder, pose.drawShoulder])} stroke={SLIP} strokeWidth="2" />
              {pose.hips && (
                <>
                  <polyline points={limb([pose.bowShoulder, pose.hips[0], pose.hips[1], pose.drawShoulder])} stroke={INK} strokeWidth="3.4" />
                  <polyline points={limb([pose.bowShoulder, pose.hips[0], pose.hips[1], pose.drawShoulder])} stroke={SLIP} strokeWidth="1.4" opacity="0.8" />
                </>
              )}
              {/* The drawing arm, slip; the bow arm, gold, on top. */}
              <polyline points={limb([pose.drawShoulder, pose.drawElbow, pose.drawWrist])} stroke={INK} strokeWidth="6" />
              <polyline points={limb([pose.drawShoulder, pose.drawElbow, pose.drawWrist])} stroke={SLIP} strokeWidth="3.4" />
              <polyline points={limb([pose.bowShoulder, pose.bowElbow, pose.bowWrist])} stroke={INK} strokeWidth="6.4" />
              <polyline points={limb([pose.bowShoulder, pose.bowElbow, pose.bowWrist])} stroke={GOLD} strokeWidth="3.8" />
              {pose.nose && <circle cx={pose.nose.x * W} cy={pose.nose.y * H} r="4.5" fill={SLIP} stroke={INK} strokeWidth="1.6" />}
              {/* The hands: the bow hand gold; the drawing hand rings as the draw fills. */}
              <circle cx={pose.bowWrist.x * W} cy={pose.bowWrist.y * H} r="3.4" fill={GOLD} stroke={INK} strokeWidth="1.6" />
              <circle cx={pose.drawWrist.x * W} cy={pose.drawWrist.y * H} r="3.2" fill={SLIP} stroke={INK} strokeWidth="1.6" />
              {draw > 0.02 && (
                <circle
                  className={`draw-ring${draw >= 0.85 ? ' full' : draw >= 0.5 ? ' good' : ''}`}
                  cx={pose.drawWrist.x * W}
                  cy={pose.drawWrist.y * H}
                  r={(4 + 7 * Math.min(1, draw)).toFixed(1)}
                  strokeWidth="1.8"
                />
              )}
            </g>
          )}
          {state === 'searching' && (
            /* Where to stand: a dashed figure, waist up. */
            <g className="tox-cam-ghost" fill="none" stroke={SLIP} strokeWidth="1.6" strokeDasharray="4 3">
              <circle cx={W / 2} cy="30" r="10" />
              <path d={`M${W / 2 - 24} 100 V62 Q${W / 2 - 24} 46 ${W / 2 - 10} 46 H${W / 2 + 10} Q${W / 2 + 24} 46 ${W / 2 + 24} 62 V100`} />
            </g>
          )}
        </svg>
      </div>
      <figcaption>
        <i />
        {note ?? CAPTION[state]}
      </figcaption>
    </figure>
  )
}
