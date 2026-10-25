import { useEffect, useRef } from 'react'
import * as THREE from 'three'

/** What Homer is doing. The hall and the arena pick one from the context. */
export type HomerAction =
  | 'idle' // standing, breathing, glancing at the pointer
  | 'welcome' // waves the poets in
  | 'listen' // hands clasped, leaning in while a poet gets ready
  | 'judge' // sits on his throne, chin on hand
  | 'verdict' // seated, points at the poet as the verdict lands
  | 'sing' // arms wide, singing the stitched song
  | 'laurel' // holds up the laurel wreath for the champion
  | 'cheer' // both arms up

type Homer3DProps = {
  speaking: boolean
  mode: 'bard' | 'judge' | 'battle' | null
  /** Overrides the hall's default (idle, or a wave when a mode is picked). */
  action?: HomerAction
  /** 'hall': full body, standing on the plaza above the dialogue. 'card': full body, centred (the
   *  landing page's poet card). 'stage' (default): the arena's side panel. */
  framing?: 'hall' | 'stage' | 'card'
}

const material = (color: number, roughness = 0.72) =>
  new THREE.MeshStandardMaterial({ color, roughness, metalness: 0.02 })

/** Every joint Homer animates, in radians, plus how far he is sitting (0 standing, 1 seated). */
type Pose = {
  sit: number
  torsoX: number
  torsoZ: number
  headX: number
  headZ: number
  lShoulderX: number
  lShoulderY: number
  lShoulderZ: number
  lElbowX: number
  rShoulderX: number
  rShoulderY: number
  rShoulderZ: number
  rElbowX: number
  hipX: number
  kneeX: number
  wreath: number
  /** Turns his whole body; seated, he faces the poets three-quarters on so the pose reads. */
  yaw: number
}

const REST: Pose = {
  sit: 0, torsoX: 0, torsoZ: 0, headX: 0, headZ: 0,
  lShoulderX: 0, lShoulderY: 0, lShoulderZ: -0.08, lElbowX: -0.15,
  rShoulderX: 0, rShoulderY: 0, rShoulderZ: 0.08, rElbowX: -0.15,
  hipX: 0, kneeX: 0, wreath: 0, yaw: 0,
}

// Signs: a shoulder's negative X swings the arm forward (toward the viewer); Z swings it out to
// the side (left arm negative, right arm positive); a negative elbow X bends the forearm forward.
const SEATED = { sit: 1, hipX: -1.5, kneeX: 1.5, yaw: 0.55 }
const POSES: Record<HomerAction, Partial<Pose>> = {
  idle: {},
  welcome: { rShoulderZ: 2.35, rShoulderX: -0.2, rElbowX: -0.35, lShoulderZ: -0.3, lElbowX: -0.6, headZ: -0.05 },
  listen: { lShoulderX: -0.55, lShoulderY: 0.5, lShoulderZ: 0.1, lElbowX: -1.35, rShoulderX: -0.55, rShoulderY: -0.5, rShoulderZ: -0.1, rElbowX: -1.35, torsoX: 0.06, headX: 0.06 },
  judge: { ...SEATED, torsoX: 0.12, headX: 0.12, headZ: 0.08, rShoulderX: -0.95, rShoulderY: -0.35, rShoulderZ: -0.15, rElbowX: -2.15, lShoulderX: -0.75, lShoulderZ: -0.05, lElbowX: -0.55 },
  verdict: { ...SEATED, torsoX: -0.04, headX: -0.05, rShoulderX: -1.45, rShoulderZ: 0.35, rElbowX: -0.1, lShoulderX: -0.75, lShoulderZ: -0.05, lElbowX: -0.55 },
  sing: { torsoX: -0.06, headX: -0.18, lShoulderX: -0.35, lShoulderZ: -1.85, lElbowX: -0.35, rShoulderX: -0.35, rShoulderZ: 1.85, rElbowX: -0.35 },
  laurel: { headX: 0.08, torsoX: 0.04, lShoulderX: -1.3, lShoulderY: 0.4, lShoulderZ: 0.1, lElbowX: -0.35, rShoulderX: -1.3, rShoulderY: -0.4, rShoulderZ: -0.1, rElbowX: -0.35, wreath: 1 },
  cheer: { headX: -0.15, lShoulderZ: -2.65, lElbowX: -0.2, rShoulderZ: 2.65, rElbowX: -0.2 },
}

/** The hall's mode reactions, as actions. */
const MODE_ACTION: Record<NonNullable<Homer3DProps['mode']>, HomerAction> = {
  bard: 'listen',
  judge: 'judge',
  battle: 'welcome',
}

// Dev only: ?homer=judge (or any action) pins the pose, for styling without running a battle.
const DEV_ACTION = import.meta.env.DEV ? (new URLSearchParams(window.location.search).get('homer') as HomerAction | null) : null

export default function Homer3D({ speaking, mode, action: actionProp, framing = 'stage' }: Homer3DProps) {
  const action = DEV_ACTION && DEV_ACTION in POSES ? DEV_ACTION : actionProp
  const mountRef = useRef<HTMLDivElement>(null)
  const speakingRef = useRef(speaking)
  const actionRef = useRef<HomerAction>(action ?? (mode ? MODE_ACTION[mode] : 'welcome'))
  const actionStarted = useRef(performance.now())

  useEffect(() => {
    speakingRef.current = speaking
  }, [speaking])

  useEffect(() => {
    const next = action ?? (mode ? MODE_ACTION[mode] : 'welcome')
    if (next !== actionRef.current) {
      actionRef.current = next
      actionStarted.current = performance.now()
    }
  }, [action, mode])

  useEffect(() => {
    const mount = mountRef.current
    if (!mount) return

    const scene = new THREE.Scene()
    const camera = new THREE.PerspectiveCamera(27, 1, 0.1, 100)
    if (framing === 'hall') {
      // Whole Homer, a little above centre, so his feet land just above the dialogue panel.
      camera.position.set(0, 1.0, 10.8)
      camera.lookAt(0, 0.85, 0)
    } else if (framing === 'card') {
      camera.position.set(0, 1.35, 8.4)
      camera.lookAt(0, 1.4, 0) // a little headroom under the card's badge
    } else {
      camera.position.set(0, 1.75, 10)
    }

    const renderer = new THREE.WebGLRenderer({ alpha: true, antialias: true })
    renderer.setPixelRatio(Math.min(window.devicePixelRatio, 1.5))
    renderer.outputColorSpace = THREE.SRGBColorSpace
    renderer.shadowMap.enabled = true
    renderer.shadowMap.type = THREE.PCFShadowMap
    mount.appendChild(renderer.domElement)

    scene.add(new THREE.HemisphereLight(0xc9ebff, 0x8c674c, 2.35))
    const keyLight = new THREE.DirectionalLight(0xfff1cf, 3.5)
    keyLight.position.set(-4, 7, 7)
    keyLight.castShadow = true
    scene.add(keyLight)
    const rimLight = new THREE.DirectionalLight(0x73bfff, 2.2)
    rimLight.position.set(5, 3, -2)
    scene.add(rimLight)

    const homer = new THREE.Group()
    const homerRestY = 0.85
    homer.position.y = homerRestY
    homer.scale.setScalar(0.46)
    scene.add(homer)

    const skin = material(0xe8a26f, 0.82)
    const skinLight = material(0xf1b681, 0.8)
    const white = material(0xf1eee4, 0.9)
    const blue = material(0x174f9f, 0.7)
    const navy = material(0x24364f, 0.76)
    const dark = material(0x252321, 0.84)
    const mouthDark = material(0x4b241c, 0.9)
    const marble = material(0xf4eee0, 0.55)
    const marbleShade = material(0xdccfb4, 0.6)
    const leaf = material(0x4f8a35, 0.7)
    const leafLight = material(0x79b04e, 0.7)
    const eyeMaterial = new THREE.MeshBasicMaterial({ color: 0x292522 })
    const gold = new THREE.MeshStandardMaterial({ color: 0xc99c32, roughness: 0.38, metalness: 0.38 })

    const addMesh = (
      geometry: THREE.BufferGeometry,
      meshMaterial: THREE.Material,
      parent: THREE.Object3D,
      position: [number, number, number],
      scale: [number, number, number] = [1, 1, 1],
    ) => {
      const mesh = new THREE.Mesh(geometry, meshMaterial)
      mesh.position.set(...position)
      mesh.scale.set(...scale)
      mesh.castShadow = true
      mesh.receiveShadow = true
      parent.add(mesh)
      return mesh
    }
    const group = (parent: THREE.Object3D, position: [number, number, number]) => {
      const g = new THREE.Group()
      g.position.set(...position)
      parent.add(g)
      return g
    }

    const sphere = new THREE.SphereGeometry(1, 32, 24)
    const capsule = new THREE.CapsuleGeometry(0.5, 1, 8, 20)

    // Skeleton. Coordinates are Homer's own (before the 0.46 scale); y = 0 is mid-chest.
    // hips (y -0.7) carries the torso and the legs; sitting lowers the hips by a thigh's length.
    const HIPS_Y = -0.7
    const THIGH = 0.68
    const hips = group(homer, [0, HIPS_Y, 0])
    const torso = group(hips, [0, 0, 0])
    addMesh(sphere, navy, hips, [0, -0.02, -0.06], [0.64, 0.34, 0.5])

    // Torso: chiton, neck, sash and pin (positions relative to the hips).
    addMesh(new THREE.CylinderGeometry(0.78, 0.58, 1.42, 32), white, torso, [0, 0.8, -0.05], [1, 1, 0.78])
    addMesh(capsule, skin, torso, [0, 1.6, -0.12], [0.28, 0.34, 0.28])
    const sash = addMesh(capsule, blue, torso, [-0.28, 0.78, 0.57], [0.2, 0.82, 0.12])
    sash.rotation.z = -0.2
    addMesh(sphere, gold, torso, [-0.5, 1.38, 0.65], [0.17, 0.17, 0.085])

    // Arms: shoulder > upper arm > elbow > forearm > hand. side -1 is the viewer's left.
    const arm = (side: -1 | 1) => {
      addMesh(sphere, white, torso, [side * 0.76, 0.98, -0.01], [0.33, 0.34, 0.3])
      const shoulder = group(torso, [side * 0.8, 0.95, 0.02])
      addMesh(new THREE.CapsuleGeometry(0.16, 0.3, 8, 18), skinLight, shoulder, [0, -0.28, 0])
      const elbow = group(shoulder, [0, -0.55, 0])
      addMesh(new THREE.CapsuleGeometry(0.15, 0.26, 8, 18), skinLight, elbow, [0, -0.22, 0])
      const hand = group(elbow, [0, -0.47, 0.02])
      addMesh(sphere, skinLight, hand, [0, 0, 0], [0.2, 0.2, 0.19])
      return { shoulder, elbow, hand }
    }
    const left = arm(-1)
    const right = arm(1)

    // Legs: hip > thigh > knee > shin > sandal.
    const leg = (side: -1 | 1) => {
      const hip = group(hips, [side * 0.3, -0.1, -0.06])
      addMesh(capsule, navy, hip, [0, -0.34, 0], [0.23, 0.36, 0.24])
      const knee = group(hip, [0, -THIGH, 0])
      addMesh(capsule, navy, knee, [0, -0.3, 0], [0.22, 0.34, 0.23])
      addMesh(sphere, dark, knee, [0, -0.62, 0.17], [0.3, 0.18, 0.42])
      return { hip, knee }
    }
    const legs = [leg(-1), leg(1)]

    // Head: everything above the neck pivots here. headInner shifts back to the original
    // coordinates so the face keeps its hand-placed positions.
    const NECK_Y = 1.15
    const headPivot = group(torso, [0, NECK_Y - HIPS_Y, 0])
    const headInner = group(headPivot, [0, -NECK_Y, 0])
    addMesh(sphere, white, headInner, [0, 2.62, -0.3], [1.28, 1.48, 0.91])
    addMesh(sphere, skinLight, headInner, [0, 2.25, 0.08], [1.1, 1.34, 1])

    const hairCurls: Array<[number, number, number, number]> = [
      [-0.92, 3.2, -0.03, 0.38], [-0.62, 3.5, -0.08, 0.4], [-0.22, 3.64, -0.1, 0.41],
      [0.22, 3.64, -0.1, 0.41], [0.62, 3.5, -0.08, 0.4], [0.92, 3.2, -0.03, 0.38],
      [-1.05, 2.84, 0, 0.36], [1.05, 2.84, 0, 0.36], [-1.06, 2.5, 0.02, 0.32], [1.06, 2.5, 0.02, 0.32],
    ]
    hairCurls.forEach(([x, y, z, size]) => addMesh(sphere, white, headInner, [x, y, z], [size, size * 1.08, size * 0.82]))

    const band = addMesh(new THREE.TorusGeometry(1.02, 0.045, 10, 48, Math.PI), material(0x67452c), headInner, [0, 3.38, 0.75], [1, 0.18, 1])
    band.rotation.z = Math.PI

    const eyeGeometry = new THREE.CircleGeometry(1, 28)
    const leftEye = addMesh(eyeGeometry, eyeMaterial, headInner, [-0.4, 2.48, 1.095], [0.105, 0.145, 1])
    const rightEye = addMesh(eyeGeometry, eyeMaterial, headInner, [0.4, 2.48, 1.095], [0.105, 0.145, 1])

    const browGeometry = new THREE.CapsuleGeometry(0.045, 0.38, 5, 12)
    const leftBrow = addMesh(browGeometry, dark, headInner, [-0.4, 2.78, 1.04], [1, 1, 0.45])
    leftBrow.rotation.z = Math.PI / 2 - 0.15
    const rightBrow = addMesh(browGeometry, dark, headInner, [0.4, 2.78, 1.04], [1, 1, 0.45])
    rightBrow.rotation.z = Math.PI / 2 + 0.15

    const tube = (points: Array<[number, number, number]>, radius: number, meshMaterial: THREE.Material) =>
      addMesh(new THREE.TubeGeometry(new THREE.CatmullRomCurve3(points.map((p) => new THREE.Vector3(...p))), 16, radius, 8), meshMaterial, headInner, [0, 0, 0])
    tube([[-0.58, 2.58, 1.055], [-0.42, 2.66, 1.09], [-0.25, 2.57, 1.06]], 0.022, dark)
    tube([[0.25, 2.57, 1.06], [0.42, 2.66, 1.09], [0.58, 2.58, 1.055]], 0.022, dark)
    tube([[0.035, 2.48, 1.075], [0.01, 2.27, 1.115], [-0.08, 2.03, 1.12], [0.055, 1.98, 1.115]], 0.024, dark)

    const mouthRig = group(headInner, [0, 1.73, 1.08])
    const mouthOpening = addMesh(new THREE.CapsuleGeometry(0.065, 0.18, 8, 20), mouthDark, mouthRig, [0, 0, 0], [1, 1, 0.35])
    mouthOpening.rotation.z = Math.PI / 2
    tube([[0, 1.86, 1.105], [-0.18, 1.91, 1.105], [-0.38, 1.81, 1.06]], 0.09, white)
    tube([[0, 1.86, 1.105], [0.18, 1.91, 1.105], [0.38, 1.81, 1.06]], 0.09, white)

    const jaw = group(headInner, [0, 1.55, 0.88])
    const beardCurls: Array<[number, number, number, number]> = [
      [-0.6, -0.08, 0.06, 0.33], [-0.4, -0.4, 0.08, 0.35], [-0.14, -0.58, 0.1, 0.38],
      [0.14, -0.58, 0.1, 0.38], [0.4, -0.4, 0.08, 0.35], [0.6, -0.08, 0.06, 0.33],
    ]
    beardCurls.forEach(([x, y, z, size]) => addMesh(sphere, white, jaw, [x, y, z], [size, size * 1.16, size * 0.72]))

    // The judge's throne: marble, gold trim. It rises into place when he sits.
    const throne = group(homer, [0, -2.16, 0])
    const seatTop = HIPS_Y - THIGH - 0.13 + 2.16
    addMesh(new THREE.BoxGeometry(1.8, seatTop, 1.2), marble, throne, [0, seatTop / 2, 0.22])
    addMesh(new THREE.BoxGeometry(1.95, 0.1, 1.3), gold, throne, [0, seatTop + 0.02, 0.22])
    addMesh(new THREE.BoxGeometry(1.8, 2.3, 0.28), marble, throne, [0, seatTop + 1.15, -0.5])
    addMesh(new THREE.CylinderGeometry(0.16, 0.16, 2.6, 16), marbleShade, throne, [-0.95, seatTop + 1.0, -0.5])
    addMesh(new THREE.CylinderGeometry(0.16, 0.16, 2.6, 16), marbleShade, throne, [0.95, seatTop + 1.0, -0.5])
    addMesh(sphere, gold, throne, [-0.95, seatTop + 2.35, -0.5], [0.22, 0.22, 0.22])
    addMesh(sphere, gold, throne, [0.95, seatTop + 2.35, -0.5], [0.22, 0.22, 0.22])
    throne.scale.setScalar(0.001)
    throne.visible = false

    // The laurel wreath he holds up for the champion: a ring of leaves.
    const wreath = group(torso, [0, 1.05, 1.3])
    for (let i = 0; i < 22; i++) {
      const a = (i / 22) * Math.PI * 2
      const m = addMesh(sphere, i % 2 ? leaf : leafLight, wreath, [Math.cos(a) * 0.55, Math.sin(a) * 0.55, 0], [0.15, 0.07, 0.06])
      m.rotation.z = a + Math.PI / 2 + (i % 2 ? 0.5 : -0.5)
    }
    addMesh(sphere, gold, wreath, [0, -0.58, 0.04], [0.09, 0.09, 0.06])
    wreath.scale.setScalar(0.001)
    wreath.visible = false

    const resize = () => {
      const { clientWidth, clientHeight } = mount
      renderer.setSize(clientWidth, clientHeight, false)
      camera.aspect = clientWidth / Math.max(clientHeight, 1)
      camera.updateProjectionMatrix()
    }
    resize()
    const resizeObserver = new ResizeObserver(resize)
    resizeObserver.observe(mount)

    // He glances toward the pointer.
    const look = new THREE.Vector2()
    const lookTarget = new THREE.Vector2()
    const onMove = (event: PointerEvent) =>
      lookTarget.set((event.clientX / window.innerWidth) * 2 - 1, (event.clientY / window.innerHeight) * 2 - 1)
    window.addEventListener('pointermove', onMove)

    const reducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches
    const pose: Pose = { ...REST }
    const target: Pose = { ...REST }
    const keys = Object.keys(REST) as Array<keyof Pose>
    const start = performance.now()
    let frame = 0
    let last = -1
    const tick = (now: number, force = false) => {
      const time = (now - start) / 1000
      const speakingNow = speakingRef.current
      const current = actionRef.current
      const age = (now - actionStarted.current) / 1000
      const settling = keys.some((k) => Math.abs(pose[k] - target[k]) > 0.002)
      // A still, silent, standing Homer only breathes and blinks: 24 frames a second is plenty.
      if (!force && !speakingNow && !settling && current === 'idle' && time - last < 1 / 24) return
      // Never step backwards (the dev stepper and the real clock can interleave).
      const dt = last < 0 ? 0 : Math.min(Math.max(time - last, 0), 0.1)
      last = Math.max(last, time)
      const motion = reducedMotion ? 0.3 : 1

      // Target = rest, then the action's pose, then live overlays.
      Object.assign(target, REST, POSES[current])
      if (current === 'welcome') {
        // A wave every few seconds; between waves the arm comes back down.
        const cycle = age % 5
        const waving = age < 3 || cycle < 1.8
        if (!waving) Object.assign(target, { rShoulderZ: REST.rShoulderZ, rShoulderX: 0, rElbowX: REST.rElbowX, lShoulderZ: REST.lShoulderZ, lElbowX: REST.lElbowX })
        else target.rElbowX = -0.35 + Math.sin(time * 9) * 0.45 * motion
      }
      if (current === 'cheer' || current === 'laurel') target.sit = 0
      if (speakingNow) {
        // Talking with his hands: whichever arm is free gestures with the speech.
        const g = (0.5 + 0.5 * Math.sin(time * 2.6)) * motion
        const h = (0.5 + 0.5 * Math.sin(time * 2.1 + 1.7)) * motion
        if (current === 'idle' || current === 'listen' || (current === 'welcome' && target.rShoulderZ < 1)) {
          target.rShoulderX += -0.45 * g
          target.rShoulderZ += 0.2 * g
          target.rElbowX += -0.75 * g
          target.lShoulderX += -0.35 * h
          target.lShoulderZ -= 0.15 * h
          target.lElbowX += -0.6 * h
        } else if (current === 'judge' || current === 'verdict') {
          target.lShoulderX += -0.45 * h
          target.lShoulderZ -= 0.3 * h
          target.lElbowX += -0.5 * h
        } else if (current === 'sing') {
          target.lShoulderZ -= 0.25 * g
          target.rShoulderZ += 0.25 * h
        }
        target.torsoZ += Math.sin(time * 1.3) * 0.03 * motion
        target.headX += Math.sin(time * 3.1) * 0.03 * motion
      }
      if (current === 'cheer') target.lShoulderZ -= Math.sin(time * 8) * 0.15 * motion
      if (current === 'laurel') {
        const lift = Math.max(0, Math.sin(time * 1.8)) * 0.18 * motion
        target.lShoulderX -= lift
        target.rShoulderX -= lift
      }
      if (current === 'sing') target.torsoZ += Math.sin(time * 1.6) * 0.06 * motion

      const k = 1 - Math.exp(-dt * (current === 'welcome' ? 9 : 6))
      for (const key of keys) pose[key] += (target[key] - pose[key]) * k

      look.lerp(lookTarget, 1 - Math.exp(-dt * 4))

      // Apply the pose.
      hips.position.y = HIPS_Y - pose.sit * THIGH
      homer.rotation.y = pose.yaw
      // Seated and turned, the throne's back sticks out to his right: shift him so it stays in frame.
      homer.position.x = pose.sit * 0.22
      torso.rotation.set(pose.torsoX, 0, pose.torsoZ)
      headPivot.rotation.set(pose.headX + look.y * 0.08, look.x * 0.22, pose.headZ)
      left.shoulder.rotation.set(pose.lShoulderX, pose.lShoulderY, pose.lShoulderZ)
      left.elbow.rotation.set(pose.lElbowX, 0, 0)
      right.shoulder.rotation.set(pose.rShoulderX, pose.rShoulderY, pose.rShoulderZ)
      right.elbow.rotation.set(pose.rElbowX, 0, 0)
      legs.forEach(({ hip, knee }) => {
        hip.rotation.x = pose.hipX
        knee.rotation.x = pose.kneeX
      })
      const throneScale = THREE.MathUtils.smoothstep(pose.sit, 0.05, 0.6)
      throne.visible = throneScale > 0.01
      throne.scale.setScalar(Math.max(0.001, throneScale))
      wreath.visible = pose.wreath > 0.02
      wreath.scale.setScalar(Math.max(0.001, pose.wreath))
      wreath.rotation.z = Math.sin(time * 1.5) * 0.05
      // Offered up to the champion: a slow lift and settle.
      wreath.position.y = 1.05 + Math.max(0, Math.sin(time * 1.8)) * 0.12 * motion

      // Breathing, the mouth, blinking.
      const voice = speakingNow ? 0.48 + Math.sin(time * 12.4) * 0.22 + Math.sin(time * 19.1) * 0.12 : 0
      jaw.position.y = 1.55 - voice * 0.055
      jaw.rotation.x = voice * 0.035
      mouthRig.scale.y = 0.55 + voice * 0.55
      const breath = Math.sin(time * 1.8) * motion
      homer.position.y = homerRestY + breath * 0.018 + (current === 'cheer' ? Math.abs(Math.sin(time * 5)) * 0.08 * motion : 0)
      torso.scale.set(1 + breath * 0.008, 1 + breath * 0.012, 1 + breath * 0.008)

      const blinkCycle = time % 4.8
      const blink = blinkCycle > 4.58 ? Math.max(0.06, Math.abs(blinkCycle - 4.69) * 9) : 1
      leftEye.scale.y = 0.145 * blink
      rightEye.scale.y = 0.145 * blink

      renderer.render(scene, camera)
    }
    const animate = () => {
      frame = requestAnimationFrame(animate)
      if (document.hidden || !mount.offsetWidth) return
      tick(performance.now())
    }
    animate()
    // Dev only: step the animation by hand (the loop pauses while the page isn't on screen).
    if (import.meta.env.DEV) {
      let fake = performance.now()
      ;(window as unknown as Record<string, unknown>).__homer = {
        advance: (seconds = 1) => {
          for (let t = 0; t < seconds; t += 1 / 30) tick((fake = Math.max(fake, performance.now()) + 1000 / 30), true)
        },
        set: (next: HomerAction) => {
          actionRef.current = next
          actionStarted.current = Math.max(fake, performance.now())
        },
      }
    }

    return () => {
      cancelAnimationFrame(frame)
      resizeObserver.disconnect()
      window.removeEventListener('pointermove', onMove)
      scene.traverse((object) => {
        if (object instanceof THREE.Mesh) {
          object.geometry.dispose()
          const materials = Array.isArray(object.material) ? object.material : [object.material]
          materials.forEach((entry) => entry.dispose())
        }
      })
      renderer.dispose()
      renderer.domElement.remove()
    }
  }, [framing])

  return <div className="homer-3d" ref={mountRef} aria-label="Animated 3D Homer" />
}
