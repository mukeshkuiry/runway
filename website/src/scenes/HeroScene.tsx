import { useRef, useMemo } from 'react'
import { Canvas, useFrame, useThree } from '@react-three/fiber'
import { Stars, Float, Sparkles } from '@react-three/drei'
import * as THREE from 'three'

/* ── Animated runway plane with UV scroll ── */
function RunwaySurface() {
  const matRef = useRef<THREE.MeshStandardMaterial>(null)

  useFrame(({ clock }) => {
    if (matRef.current) {
      // Scroll texture forward
      const map = matRef.current.map
      if (map) {
        map.offset.y = clock.getElapsedTime() * 0.08
        map.needsUpdate = true
      }
    }
  })

  const texture = useMemo(() => {
    const canvas = document.createElement('canvas')
    canvas.width = 256
    canvas.height = 1024
    const ctx = canvas.getContext('2d')!
    ctx.fillStyle = '#0A0D14'
    ctx.fillRect(0, 0, 256, 1024)
    // Center line dashes
    for (let y = 0; y < 1024; y += 80) {
      ctx.fillStyle = '#FFD740'
      ctx.fillRect(122, y, 12, 50)
    }
    // Edge stripes
    ctx.fillStyle = '#1A2233'
    ctx.fillRect(0, 0, 40, 1024)
    ctx.fillRect(216, 0, 40, 1024)
    // Edge dashes
    for (let y = 0; y < 1024; y += 40) {
      ctx.fillStyle = '#386BF2'
      ctx.fillRect(8, y, 8, 20)
      ctx.fillRect(240, y, 8, 20)
    }
    const tex = new THREE.CanvasTexture(canvas)
    tex.wrapS = THREE.RepeatWrapping
    tex.wrapT = THREE.RepeatWrapping
    tex.repeat.set(1, 3)
    return tex
  }, [])

  return (
    <mesh rotation={[-Math.PI / 2, 0, 0]} position={[0, -1.5, 0]} receiveShadow>
      <planeGeometry args={[12, 80, 8, 8]} />
      <meshStandardMaterial
        ref={matRef}
        map={texture}
        roughness={0.8}
        metalness={0.1}
      />
    </mesh>
  )
}

/* ── Pulsing runway edge lights ── */
function RunwayLights() {
  const groupRef = useRef<THREE.Group>(null)

  useFrame(({ clock }) => {
    if (!groupRef.current) return
    const t = clock.getElapsedTime()
    groupRef.current.children.forEach((child, i) => {
      const light = child as THREE.Mesh
      const mat = light.material as THREE.MeshStandardMaterial
      const offset = (i % 8) / 8
      const wave = Math.sin(t * 3 - offset * Math.PI * 2)
      mat.emissiveIntensity = 0.3 + wave * 0.7
    })
  })

  const lights = useMemo(() => {
    const arr = []
    const colors = ['#00E676', '#00E676', '#FFD740', '#FF3D57']
    for (let z = -35; z < 10; z += 2.5) {
      const colorIndex = z > -5 ? 3 : z > -15 ? 2 : 1
      arr.push({ pos: [-5.5, -1.45, z] as [number, number, number], color: colors[colorIndex] })
      arr.push({ pos: [5.5, -1.45, z] as [number, number, number], color: colors[colorIndex] })
    }
    return arr
  }, [])

  return (
    <group ref={groupRef}>
      {lights.map((l, i) => (
        <mesh key={i} position={l.pos}>
          <sphereGeometry args={[0.08, 6, 6]} />
          <meshStandardMaterial
            color={l.color}
            emissive={l.color}
            emissiveIntensity={0.6}
            toneMapped={false}
          />
        </mesh>
      ))}
    </group>
  )
}

/* ── Simple procedural jet shape ── */
function Jet({ position }: { position: [number, number, number] }) {
  const groupRef = useRef<THREE.Group>(null)

  useFrame(({ clock }) => {
    if (!groupRef.current) return
    const t = clock.getElapsedTime()
    groupRef.current.rotation.z = Math.sin(t * 0.4) * 0.03
    groupRef.current.rotation.x = Math.sin(t * 0.3) * 0.02
  })

  return (
    <group ref={groupRef} position={position} rotation={[0, Math.PI, 0]}>
      {/* Fuselage */}
      <mesh>
        <capsuleGeometry args={[0.12, 1.2, 4, 8]} />
        <meshStandardMaterial color="#C0C8D8" metalness={0.8} roughness={0.2} />
      </mesh>
      {/* Wings */}
      <mesh rotation={[0, 0, 0]} position={[0, 0, 0.1]}>
        <boxGeometry args={[1.8, 0.04, 0.5]} />
        <meshStandardMaterial color="#A0A8B8" metalness={0.7} roughness={0.3} />
      </mesh>
      {/* Tail */}
      <mesh position={[0, 0.18, -0.65]} rotation={[0.2, 0, 0]}>
        <boxGeometry args={[0.6, 0.3, 0.05]} />
        <meshStandardMaterial color="#A0A8B8" metalness={0.7} roughness={0.3} />
      </mesh>
      {/* Vertical tail */}
      <mesh position={[0, 0.22, -0.6]}>
        <boxGeometry args={[0.04, 0.35, 0.3]} />
        <meshStandardMaterial color="#A0A8B8" metalness={0.7} roughness={0.3} />
      </mesh>
      {/* Engine glow */}
      <pointLight color="#386BF2" intensity={2} distance={3} position={[0, 0, 0.7]} />
      <mesh position={[0, 0, 0.72]}>
        <circleGeometry args={[0.08, 8]} />
        <meshStandardMaterial color="#00D4FF" emissive="#00D4FF" emissiveIntensity={3} toneMapped={false} />
      </mesh>
    </group>
  )
}

/* ── Smoke/contrail particles ── */
function Contrail({ position }: { position: [number, number, number] }) {
  const pointsRef = useRef<THREE.Points>(null)

  const { positions } = useMemo(() => {
    const count = 120
    const pos = new Float32Array(count * 3)
    for (let i = 0; i < count; i++) {
      pos[i * 3] = (Math.random() - 0.5) * 0.3
      pos[i * 3 + 1] = (Math.random() - 0.5) * 0.1
      pos[i * 3 + 2] = (i / count) * 4
    }
    return { positions: pos }
  }, [])

  useFrame(({ clock }) => {
    if (!pointsRef.current) return
    const t = clock.getElapsedTime()
    const geo = pointsRef.current.geometry
    const pos = geo.attributes.position.array as Float32Array
    for (let i = 0; i < 120; i++) {
      pos[i * 3 + 1] += Math.sin(t * 2 + i) * 0.0008
    }
    geo.attributes.position.needsUpdate = true
  })

  const geo = useMemo(() => {
    const g = new THREE.BufferGeometry()
    g.setAttribute('position', new THREE.BufferAttribute(positions, 3))
    return g
  }, [positions])

  return (
    <points ref={pointsRef} geometry={geo} position={position}>
      <pointsMaterial
        color="#8099B3"
        size={0.06}
        transparent
        opacity={0.4}
        depthWrite={false}
        sizeAttenuation
      />
    </points>
  )
}

/* ── Fog/haze sphere ── */
function HorizonFog() {
  return (
    <>
      <fog attach="fog" args={['#0A0D14', 20, 60]} />
      <mesh position={[0, -1, -40]}>
        <sphereGeometry args={[30, 16, 8]} />
        <meshBasicMaterial color="#050708" side={THREE.BackSide} />
      </mesh>
    </>
  )
}

/* ── Camera subtle drift ── */
function CameraDrift() {
  const { camera } = useThree()
  useFrame(({ clock }) => {
    const t = clock.getElapsedTime()
    camera.position.y = 1.5 + Math.sin(t * 0.2) * 0.1
    camera.position.x = Math.sin(t * 0.15) * 0.3
    camera.lookAt(0, 0, -20)
  })
  return null
}

export default function HeroScene() {
  return (
    <Canvas
      camera={{ position: [0, 1.5, 8], fov: 60 }}
      shadows
      dpr={[1, 1.5]}
      style={{ position: 'absolute', inset: 0 }}
      gl={{ antialias: true, alpha: false, toneMapping: THREE.ACESFilmicToneMapping }}
    >
      <color attach="background" args={['#0A0D14']} />
      <HorizonFog />
      <CameraDrift />

      {/* Lighting */}
      <ambientLight intensity={0.2} />
      <directionalLight position={[10, 10, 5]} intensity={0.5} color="#386BF2" />
      <pointLight position={[0, 5, 0]} intensity={1} color="#614BE1" distance={30} />

      {/* Scene */}
      <RunwaySurface />
      <RunwayLights />

      <Float speed={1.5} rotationIntensity={0.2} floatIntensity={0.5}>
        <Jet position={[-8, 1.2, -5]} />
        <Contrail position={[-8, 1.2, -4.5]} />
      </Float>

      {/* Stars / atmosphere */}
      <Stars radius={80} depth={50} count={3000} factor={4} saturation={0} fade />
      <Sparkles count={60} scale={[20, 8, 20]} size={1} speed={0.3} color="#386BF2" />

      {/* Ground glow */}
      <pointLight position={[0, -1, 0]} intensity={3} color="#386BF2" distance={10} />
      <pointLight position={[0, -1, -20]} intensity={2} color="#614BE1" distance={15} />
    </Canvas>
  )
}
