import { useEffect, useRef, useState } from 'react'
import { useInView } from '../hooks/useInView'

/* ── Radar canvas ── */
function RadarCanvas() {
  const canvasRef = useRef<HTMLCanvasElement>(null)
  const angleRef = useRef(0)

  useEffect(() => {
    const canvas = canvasRef.current
    if (!canvas) return
    const ctx = canvas.getContext('2d')!
    const size = canvas.width
    const cx = size / 2
    const cy = size / 2
    const radius = size / 2 - 10

    // Blip positions (meeting conflicts)
    const blips = [
      { angle: 0.8, dist: 0.5 }, { angle: 2.1, dist: 0.7 },
      { angle: 3.5, dist: 0.3 }, { angle: 4.8, dist: 0.6 },
      { angle: 1.2, dist: 0.85 },
    ]

    let animId: number

    const draw = () => {
      ctx.clearRect(0, 0, size, size)

      // Background
      ctx.fillStyle = '#0A0D14'
      ctx.beginPath()
      ctx.arc(cx, cy, radius, 0, Math.PI * 2)
      ctx.fill()

      // Grid rings
      for (let r = 1; r <= 4; r++) {
        ctx.strokeStyle = `rgba(0, 230, 118, ${0.08 + r * 0.02})`
        ctx.lineWidth = 1
        ctx.beginPath()
        ctx.arc(cx, cy, radius * r / 4, 0, Math.PI * 2)
        ctx.stroke()
      }

      // Grid crosshairs
      ctx.strokeStyle = 'rgba(0,230,118,0.1)'
      ctx.beginPath()
      ctx.moveTo(cx - radius, cy); ctx.lineTo(cx + radius, cy)
      ctx.moveTo(cx, cy - radius); ctx.lineTo(cx, cy + radius)
      ctx.stroke()

      // Sweep gradient fill
      ctx.save()
      ctx.translate(cx, cy)
      ctx.rotate(angleRef.current)
      ctx.fillStyle = 'rgba(0,230,118,0.15)'
      ctx.beginPath()
      ctx.moveTo(0, 0)
      ctx.arc(0, 0, radius, -0.4, 0.1)
      ctx.closePath()
      ctx.fill()
      ctx.restore()

      // Blips
      blips.forEach(b => {
        const angleDiff = ((b.angle - angleRef.current) % (Math.PI * 2) + Math.PI * 2) % (Math.PI * 2)
        const fade = angleDiff < 0.3 ? 1 : Math.max(0, 1 - angleDiff / (Math.PI * 2) * 3)
        if (fade <= 0) return

        const x = cx + Math.cos(b.angle) * radius * b.dist
        const y = cy + Math.sin(b.angle) * radius * b.dist

        ctx.fillStyle = `rgba(255, 61, 87, ${fade})`
        ctx.shadowBlur = 10 * fade
        ctx.shadowColor = '#FF3D57'
        ctx.beginPath()
        ctx.arc(x, y, 4, 0, Math.PI * 2)
        ctx.fill()
        ctx.shadowBlur = 0
      })

      // Sweep line
      ctx.save()
      ctx.translate(cx, cy)
      ctx.rotate(angleRef.current)
      ctx.strokeStyle = 'rgba(0,230,118,0.8)'
      ctx.lineWidth = 2
      ctx.shadowBlur = 8
      ctx.shadowColor = '#00E676'
      ctx.beginPath()
      ctx.moveTo(0, 0)
      ctx.lineTo(radius, 0)
      ctx.stroke()
      ctx.restore()

      // Center dot
      ctx.fillStyle = '#00E676'
      ctx.shadowBlur = 12
      ctx.shadowColor = '#00E676'
      ctx.beginPath()
      ctx.arc(cx, cy, 3, 0, Math.PI * 2)
      ctx.fill()
      ctx.shadowBlur = 0

      angleRef.current += 0.02
      animId = requestAnimationFrame(draw)
    }

    draw()
    return () => cancelAnimationFrame(animId)
  }, [])

  return (
    <canvas
      ref={canvasRef}
      width={280}
      height={280}
      className="rounded-full"
      style={{ border: '1px solid rgba(0,230,118,0.2)', boxShadow: '0 0 30px rgba(0,230,118,0.1)' }}
    />
  )
}

const FEATURES = [
  {
    icon: '🎯',
    title: 'Conflict Detection',
    desc: 'ATC scans your calendar for overlapping meetings and flags them instantly.',
    color: '#FF3D57',
  },
  {
    icon: '🤖',
    title: 'Autopilot Mode',
    desc: 'Flip the switch and Runway auto-launches your meeting URL at T-0. Zero clicks.',
    color: '#386BF2',
  },
  {
    icon: '🔧',
    title: 'Pre-Flight Check',
    desc: 'Mic, battery, headset — all verified before every meeting. Never scramble again.',
    color: '#00E676',
  },
]

export default function ATCSection() {
  const [autopilot, setAutopilot] = useState(false)
  const ref = useRef<HTMLDivElement>(null)
  const inView = useInView(ref, { threshold: 0.2 })

  return (
    <section id="atc" className="relative py-32 overflow-hidden" ref={ref}>
      <div className="absolute inset-0 pointer-events-none"
        style={{ background: 'radial-gradient(ellipse at center, rgba(0,230,118,0.03) 0%, transparent 70%)' }} />

      <div className="w-full px-6 md:px-10 lg:px-16">
        <div className="text-center mb-16">
          <div className="inline-flex items-center gap-2 font-mono text-xs tracking-widest uppercase text-runway-muted mb-4 px-4 py-2 rounded-full border border-runway-border">
            📡 ATC INTELLIGENCE
          </div>
          <h2 className="font-sans font-bold text-4xl md:text-5xl text-white mb-4">
            Your Co-Pilot.<br />
            <span className="gradient-text">Runs Silent.</span>
          </h2>
          <p className="text-runway-muted text-lg max-w-xl mx-auto">
            Conflict radar, autopilot auto-join, and pre-flight hardware checks —
            all running quietly in your menu bar.
          </p>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-2 gap-12 items-center">
          {/* Radar */}
          <div className="flex flex-col items-center gap-6">
            <div
              className={`transition-all duration-1000 ${inView ? 'opacity-100 scale-100' : 'opacity-0 scale-90'}`}
            >
              <RadarCanvas />
            </div>
            <div className="font-mono text-xs tracking-widest uppercase text-runway-green text-center">
              <span className="animate-pulse">● </span>
              CONFLICT SCAN ACTIVE · {Math.floor(Math.random() * 3) + 1} BLIP{Math.floor(Math.random() * 3) + 1 !== 1 ? 'S' : ''} DETECTED
            </div>
          </div>

          {/* Feature cards + autopilot */}
          <div className="flex flex-col gap-5">
            {FEATURES.map((f, i) => (
              <div
                key={i}
                className="flex items-start gap-4 p-5 rounded-xl transition-all duration-300 hover:scale-[1.02] cursor-default"
                style={{
                  background: 'rgba(20,25,36,0.8)',
                  border: `1px solid ${f.color}20`,
                  transitionDelay: `${i * 100}ms`,
                  opacity: inView ? 1 : 0,
                  transform: inView ? 'translateX(0)' : 'translateX(20px)',
                }}
              >
                <span className="text-3xl">{f.icon}</span>
                <div className="flex-1">
                  <div className="font-mono font-bold text-sm mb-1" style={{ color: f.color }}>
                    {f.title}
                  </div>
                  <div className="text-runway-muted text-sm leading-relaxed">{f.desc}</div>
                </div>
                {i === 1 && (
                  <button
                    onClick={() => setAutopilot(a => !a)}
                    className="flex-shrink-0 w-12 h-6 rounded-full transition-all duration-300 relative"
                    style={{
                      background: autopilot ? '#386BF2' : '#1E2D45',
                      boxShadow: autopilot ? '0 0 12px rgba(56,107,242,0.6)' : 'none',
                    }}
                    title="Toggle autopilot"
                  >
                    <span
                      className="absolute top-0.5 w-5 h-5 rounded-full bg-white transition-all duration-300"
                      style={{ left: autopilot ? '26px' : '2px' }}
                    />
                  </button>
                )}
              </div>
            ))}

            {/* Autopilot status */}
            <div
              className="p-4 rounded-xl font-mono text-xs tracking-widest uppercase text-center transition-all duration-500"
              style={{
                background: autopilot ? 'rgba(56,107,242,0.1)' : 'rgba(15,18,25,0.5)',
                border: `1px solid ${autopilot ? '#386BF2' : '#1E2D45'}`,
                color: autopilot ? '#386BF2' : '#4A5568',
              }}
            >
              {autopilot ? '✈ AUTOPILOT ENGAGED · AUTO-JOIN ARMED' : '— AUTOPILOT STANDBY —'}
            </div>
          </div>
        </div>
      </div>
    </section>
  )
}
