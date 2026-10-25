// A poet in their own canvas: the arena's side panel and the landing page's poet cards.
// (In the hall, Homer stands inside the 3D world instead: see world/World3D.tsx.)

import { useEffect, useRef } from 'react'
import * as THREE from 'three'
import { createPoetRig, HOMER_LOOK, resolveAction, type HomerAction, type PoetLook } from './poets/rig'

export type { HomerAction } from './poets/rig'

type Homer3DProps = {
  speaking: boolean
  mode: 'bard' | 'judge' | 'battle' | null
  /** Overrides the default (a wave, or the mode's reaction). */
  action?: HomerAction
  /** 'card': full body, centred (the landing page's poet card). 'stage' (default): the arena's side panel. */
  framing?: 'stage' | 'card'
  /** Which poet: Homer unless told otherwise. */
  look?: PoetLook
  /** Draw once and stop (a locked poet's card). */
  still?: boolean
  label?: string
}

export default function Homer3D({ speaking, mode, action: actionProp, framing = 'stage', look = HOMER_LOOK, still = false, label = 'Animated 3D Homer' }: Homer3DProps) {
  const action = resolveAction(mode, actionProp)
  const mountRef = useRef<HTMLDivElement>(null)
  const speakingRef = useRef(speaking)
  const actionRef = useRef<HomerAction>(action)
  const actionStarted = useRef(performance.now())

  useEffect(() => {
    speakingRef.current = speaking
  }, [speaking])

  useEffect(() => {
    if (action !== actionRef.current) {
      actionRef.current = action
      actionStarted.current = performance.now()
    }
  }, [action])

  useEffect(() => {
    const mount = mountRef.current
    if (!mount) return

    const scene = new THREE.Scene()
    const camera = new THREE.PerspectiveCamera(27, 1, 0.1, 100)
    if (framing === 'card') {
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

    const rig = createPoetRig(look)
    rig.root.position.y = 0.85 - 2.16 * 0.46 // feet where Homer always stood in these frames
    scene.add(rig.root)

    const resize = () => {
      const { clientWidth, clientHeight } = mount
      renderer.setSize(clientWidth, clientHeight, false)
      camera.aspect = clientWidth / Math.max(clientHeight, 1)
      camera.updateProjectionMatrix()
      if (still) renderer.render(scene, camera)
    }

    // He glances toward the pointer.
    const lookAt = new THREE.Vector2()
    const lookTarget = new THREE.Vector2()
    const onMove = (event: PointerEvent) =>
      lookTarget.set((event.clientX / window.innerWidth) * 2 - 1, (event.clientY / window.innerHeight) * 2 - 1)
    if (!still) window.addEventListener('pointermove', onMove)

    const reducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches
    const start = performance.now()
    let frame = 0
    let last = -1
    const tick = (now: number, force = false) => {
      const time = (now - start) / 1000
      const speakingNow = speakingRef.current
      const current = actionRef.current
      // A still, silent, standing poet only breathes and blinks: 24 frames a second is plenty.
      if (!force && !speakingNow && !rig.settling() && current === 'idle' && time - last < 1 / 24) return
      // Never step backwards (the dev stepper and the real clock can interleave).
      const dt = last < 0 ? 0 : Math.min(Math.max(time - last, 0), 0.1)
      last = Math.max(last, time)
      lookAt.lerp(lookTarget, 1 - Math.exp(-dt * 4))
      rig.update({ time, dt, speaking: speakingNow, action: current, age: (now - actionStarted.current) / 1000, look: lookAt, motion: reducedMotion ? 0.3 : 1 })
      renderer.render(scene, camera)
    }

    resize()
    const resizeObserver = new ResizeObserver(resize)
    resizeObserver.observe(mount)
    if (still) {
      // One settled frame: the pose blended fully in, then drawn.
      rig.update({ time: 0, dt: 10, speaking: false, action: actionRef.current, age: 10, look: lookAt, motion: 1 })
      renderer.render(scene, camera)
    } else {
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
    }

    return () => {
      cancelAnimationFrame(frame)
      resizeObserver.disconnect()
      window.removeEventListener('pointermove', onMove)
      scene.traverse((object) => {
        if (object instanceof THREE.Mesh) {
          object.geometry.dispose()
          const materials = Array.isArray(object.material) ? object.material : [object.material]
          materials.forEach((entry) => {
            if ('map' in entry && entry.map instanceof THREE.Texture) entry.map.dispose()
            entry.dispose()
          })
        }
      })
      renderer.dispose()
      renderer.domElement.remove()
    }
  }, [framing, look, still])

  return <div className="homer-3d" ref={mountRef} aria-label={label} />
}
