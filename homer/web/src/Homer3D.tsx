import { useEffect, useRef } from 'react'
import * as THREE from 'three'

type Homer3DProps = {
  speaking: boolean
  mode: 'bard' | 'judge' | 'battle' | null
}

const material = (color: number, roughness = 0.72) =>
  new THREE.MeshStandardMaterial({ color, roughness, metalness: 0.02 })

export default function Homer3D({ speaking, mode }: Homer3DProps) {
  const mountRef = useRef<HTMLDivElement>(null)
  const speakingRef = useRef(speaking)
  const modeRef = useRef(mode)
  const reactionStarted = useRef(performance.now())

  useEffect(() => {
    speakingRef.current = speaking
  }, [speaking])

  useEffect(() => {
    modeRef.current = mode
    reactionStarted.current = performance.now()
  }, [mode])

  useEffect(() => {
    const mount = mountRef.current
    if (!mount) return

    const scene = new THREE.Scene()
    const camera = new THREE.PerspectiveCamera(27, 1, 0.1, 100)
    camera.position.set(0, 1.75, 10)

    const renderer = new THREE.WebGLRenderer({ alpha: true, antialias: true })
    renderer.setPixelRatio(Math.min(window.devicePixelRatio, 1.5))
    renderer.outputColorSpace = THREE.SRGBColorSpace
    renderer.shadowMap.enabled = true
    renderer.shadowMap.type = THREE.PCFSoftShadowMap
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
    const eyeMaterial = new THREE.MeshBasicMaterial({ color: 0x292522 })
    const gold = new THREE.MeshStandardMaterial({
      color: 0xc99c32,
      roughness: 0.38,
      metalness: 0.38,
    })

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

    const sphere = new THREE.SphereGeometry(1, 32, 24)
    const capsule = new THREE.CapsuleGeometry(0.5, 1, 8, 20)
    addMesh(sphere, white, homer, [0, 2.62, -0.3], [1.28, 1.48, 0.91])
    const head = addMesh(sphere, skinLight, homer, [0, 2.25, 0.08], [1.1, 1.34, 1])

    addMesh(capsule, skin, homer, [0, 0.9, -0.12], [0.28, 0.34, 0.28])
    addMesh(
      new THREE.CylinderGeometry(0.78, 0.58, 1.42, 32),
      white,
      homer,
      [0, 0.1, -0.05],
      [1, 1, 0.78],
    )
    addMesh(sphere, navy, homer, [0, -0.72, -0.06], [0.64, 0.34, 0.5])

    const armGeometry = new THREE.CapsuleGeometry(0.16, 0.58, 8, 18)
    addMesh(sphere, white, homer, [-0.76, 0.28, -0.01], [0.33, 0.34, 0.3])
    const leftArm = addMesh(armGeometry, skinLight, homer, [-0.84, -0.22, 0.04])
    leftArm.rotation.z = 0.06
    addMesh(sphere, skinLight, homer, [-0.87, -0.69, 0.07], [0.2, 0.2, 0.19])

    addMesh(sphere, white, homer, [0.76, 0.28, -0.01], [0.33, 0.34, 0.3])
    const rightArm = addMesh(armGeometry, skinLight, homer, [0.84, -0.22, 0.04])
    rightArm.rotation.z = -0.06
    addMesh(sphere, skinLight, homer, [0.87, -0.69, 0.07], [0.2, 0.2, 0.19])

    addMesh(capsule, navy, homer, [-0.3, -1.43, -0.06], [0.23, 0.62, 0.24])
    addMesh(capsule, navy, homer, [0.3, -1.43, -0.06], [0.23, 0.62, 0.24])
    addMesh(sphere, dark, homer, [-0.3, -2.08, 0.13], [0.3, 0.18, 0.42])
    addMesh(sphere, dark, homer, [0.3, -2.08, 0.13], [0.3, 0.18, 0.42])

    const sash = addMesh(capsule, blue, homer, [-0.28, 0.08, 0.57], [0.2, 0.82, 0.12])
    sash.rotation.z = -0.2
    addMesh(sphere, gold, homer, [-0.5, 0.68, 0.65], [0.17, 0.17, 0.085])

    const hairCurls: Array<[number, number, number, number]> = [
      [-0.92, 3.2, -0.03, 0.38],
      [-0.62, 3.5, -0.08, 0.4],
      [-0.22, 3.64, -0.1, 0.41],
      [0.22, 3.64, -0.1, 0.41],
      [0.62, 3.5, -0.08, 0.4],
      [0.92, 3.2, -0.03, 0.38],
      [-1.05, 2.84, 0, 0.36],
      [1.05, 2.84, 0, 0.36],
      [-1.06, 2.5, 0.02, 0.32],
      [1.06, 2.5, 0.02, 0.32],
    ]
    hairCurls.forEach(([x, y, z, size]) =>
      addMesh(sphere, white, homer, [x, y, z], [size, size * 1.08, size * 0.82]),
    )

    const band = addMesh(
      new THREE.TorusGeometry(1.02, 0.045, 10, 48, Math.PI),
      material(0x67452c),
      homer,
      [0, 3.38, 0.75],
      [1, 0.18, 1],
    )
    band.rotation.z = Math.PI

    const eyeGeometry = new THREE.CircleGeometry(1, 28)
    const leftEye = addMesh(eyeGeometry, eyeMaterial, homer, [-0.4, 2.48, 1.095], [0.105, 0.145, 1])
    const rightEye = addMesh(eyeGeometry, eyeMaterial, homer, [0.4, 2.48, 1.095], [0.105, 0.145, 1])

    const browGeometry = new THREE.CapsuleGeometry(0.045, 0.38, 5, 12)
    const leftBrow = addMesh(browGeometry, dark, homer, [-0.4, 2.78, 1.04], [1, 1, 0.45])
    leftBrow.rotation.z = Math.PI / 2 - 0.15
    const rightBrow = addMesh(browGeometry, dark, homer, [0.4, 2.78, 1.04], [1, 1, 0.45])
    rightBrow.rotation.z = Math.PI / 2 + 0.15

    const leftEyeLine = new THREE.CatmullRomCurve3([
      new THREE.Vector3(-0.58, 2.58, 1.055),
      new THREE.Vector3(-0.42, 2.66, 1.09),
      new THREE.Vector3(-0.25, 2.57, 1.06),
    ])
    const rightEyeLine = new THREE.CatmullRomCurve3([
      new THREE.Vector3(0.25, 2.57, 1.06),
      new THREE.Vector3(0.42, 2.66, 1.09),
      new THREE.Vector3(0.58, 2.58, 1.055),
    ])
    addMesh(new THREE.TubeGeometry(leftEyeLine, 16, 0.022, 8), dark, homer, [0, 0, 0])
    addMesh(new THREE.TubeGeometry(rightEyeLine, 16, 0.022, 8), dark, homer, [0, 0, 0])

    const noseLine = new THREE.CatmullRomCurve3([
      new THREE.Vector3(0.035, 2.48, 1.075),
      new THREE.Vector3(0.01, 2.27, 1.115),
      new THREE.Vector3(-0.08, 2.03, 1.12),
      new THREE.Vector3(0.055, 1.98, 1.115),
    ])
    addMesh(
      new THREE.TubeGeometry(noseLine, 24, 0.024, 8),
      dark,
      homer,
      [0, 0, 0],
    )

    const mouthRig = new THREE.Group()
    mouthRig.position.set(0, 1.73, 1.08)
    homer.add(mouthRig)
    const mouthOpening = addMesh(
      new THREE.CapsuleGeometry(0.065, 0.18, 8, 20),
      mouthDark,
      mouthRig,
      [0, 0, 0],
      [1, 1, 0.35],
    )
    mouthOpening.rotation.z = Math.PI / 2
    const leftMustache = new THREE.CatmullRomCurve3([
      new THREE.Vector3(0, 1.86, 1.105),
      new THREE.Vector3(-0.18, 1.91, 1.105),
      new THREE.Vector3(-0.38, 1.81, 1.06),
    ])
    const rightMustache = new THREE.CatmullRomCurve3([
      new THREE.Vector3(0, 1.86, 1.105),
      new THREE.Vector3(0.18, 1.91, 1.105),
      new THREE.Vector3(0.38, 1.81, 1.06),
    ])
    addMesh(new THREE.TubeGeometry(leftMustache, 16, 0.09, 12), white, homer, [0, 0, 0])
    addMesh(new THREE.TubeGeometry(rightMustache, 16, 0.09, 12), white, homer, [0, 0, 0])

    const jaw = new THREE.Group()
    jaw.position.set(0, 1.55, 0.88)
    homer.add(jaw)
    const beardCurls: Array<[number, number, number, number]> = [
      [-0.6, -0.08, 0.06, 0.33],
      [-0.4, -0.4, 0.08, 0.35],
      [-0.14, -0.58, 0.1, 0.38],
      [0.14, -0.58, 0.1, 0.38],
      [0.4, -0.4, 0.08, 0.35],
      [0.6, -0.08, 0.06, 0.33],
    ]
    beardCurls.forEach(([x, y, z, size]) =>
      addMesh(sphere, white, jaw, [x, y, z], [size, size * 1.16, size * 0.72]),
    )

    const resize = () => {
      const { clientWidth, clientHeight } = mount
      renderer.setSize(clientWidth, clientHeight, false)
      camera.aspect = clientWidth / Math.max(clientHeight, 1)
      camera.updateProjectionMatrix()
    }
    resize()
    const resizeObserver = new ResizeObserver(resize)
    resizeObserver.observe(mount)

    const clock = new THREE.Clock()
    let frame = 0
    let lastRender = -1
    const animate = () => {
      frame = requestAnimationFrame(animate)
      if (document.hidden) return
      const time = clock.getElapsedTime()
      const speakingNow = speakingRef.current
      const reactionAge = (performance.now() - reactionStarted.current) / 1000
      // Idle (no speech, no reaction) Homer only breathes and blinks: 20 frames a second is plenty.
      if (!speakingNow && reactionAge > 1.15 && time - lastRender < 1 / 20) return
      lastRender = time
      const voice =
        speakingNow
          ? 0.48 + Math.sin(time * 12.4) * 0.22 + Math.sin(time * 19.1) * 0.12
          : 0

      jaw.position.y = 1.55 - voice * 0.055
      jaw.rotation.x = voice * 0.035
      mouthRig.scale.y = 0.55 + voice * 0.55
      homer.position.y = homerRestY + Math.sin(time * 1.8) * 0.018

      const blinkCycle = time % 4.8
      const blink = blinkCycle > 4.58 ? Math.max(0.06, Math.abs(blinkCycle - 4.69) * 9) : 1
      leftEye.scale.y = 0.145 * blink
      rightEye.scale.y = 0.145 * blink

      head.rotation.y = Math.sin(time * 0.42) * 0.018
      if (reactionAge < 1.15 && modeRef.current) {
        const pulse = Math.sin(reactionAge * Math.PI * 2.8) * (1 - reactionAge / 1.15)
        if (modeRef.current === 'bard') homer.rotation.x = pulse * 0.035
        if (modeRef.current === 'judge') homer.rotation.z = pulse * 0.025
        if (modeRef.current === 'battle') homer.position.y += Math.abs(pulse) * 0.09
      } else {
        homer.rotation.x *= 0.9
        homer.rotation.z *= 0.9
      }

      renderer.render(scene, camera)
    }
    animate()

    return () => {
      cancelAnimationFrame(frame)
      resizeObserver.disconnect()
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
  }, [])

  return <div className="homer-3d" ref={mountRef} aria-label="Animated 3D Homer" />
}
