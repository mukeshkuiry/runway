import { useState, useRef, useEffect } from 'react'
import { useInView } from '../hooks/useInView'

const AIRCRAFT = [
  {
    emoji: '✈️',
    name: 'PASSENGER JET',
    label: 'T-5 MINUTES',
    color: '#00E676',
    glow: 'rgba(0,230,118,0.3)',
    title: 'Smooth Approach',
    desc: 'A calm banner glides across your screen. Your meeting is coming. No panic — just awareness.',
    speed: 'SLOW',
    style: 'GENTLE CRUISE',
  },
  {
    emoji: '🚀',
    name: 'ROCKET',
    label: 'T-2 MINUTES',
    color: '#FF9100',
    glow: 'rgba(255,145,0,0.3)',
    title: 'Turbulence Alert',
    desc: 'The screen shakes. A bold orange warning jolts you into action. It\'s time to wrap up.',
    speed: 'FAST',
    style: 'TURBULENT',
  },
  {
    emoji: '💥',
    name: 'EJECTION',
    label: 'T-0 · NOW',
    color: '#FF3D57',
    glow: 'rgba(255,61,87,0.5)',
    title: 'Crash Landing',
    desc: 'Full-screen takeover. Pulsing red. JOIN NOW button you cannot ignore. Meeting started.',
    speed: 'CRITICAL',
    style: 'FULL ALERT',
  },
]

function AircraftTrack({ aircraft, active, progress }: {
  aircraft: typeof AIRCRAFT[0],
  active: boolean,
  progress: number
}) {
  const translateX = active ? `${-50 + progress * 200}%` : '-60%'

  return (
    <div className="relative h-24 flex items-center overflow-hidden rounded-xl border"
      style={{
        background: active ? `rgba(20,25,36,0.9)` : 'rgba(15,18,25,0.5)',
        borderColor: active ? aircraft.color : '#1E2D45',
        boxShadow: active ? `0 0 20px ${aircraft.glow}` : 'none',
        transition: 'all 0.5s',
      }}
    >
      {/* Runway dashes */}
      <div className="absolute inset-0 flex items-center">
        {Array.from({ length: 20 }).map((_, i) => (
          <div key={i} className="flex-shrink-0 w-8 h-0.5 mx-2 rounded-full opacity-20"
            style={{ background: aircraft.color }} />
        ))}
      </div>

      {/* Aircraft */}
      <div
        className="absolute text-4xl transition-all duration-100"
        style={{ left: translateX, top: '50%', transform: `translateY(-50%) scaleX(-1)` }}
      >
        {aircraft.emoji}
      </div>

      {/* Label */}
      <div className="absolute right-4 font-mono">
        <div className="text-xs tracking-widest uppercase" style={{ color: aircraft.color }}>
          {aircraft.label}
        </div>
        <div className="text-white text-sm font-bold">{aircraft.name}</div>
      </div>
    </div>
  )
}

export default function FlyoverSection() {
  const [activeIdx, setActiveIdx] = useState(0)
  const [progress, setProgress] = useState(0)
  const ref = useRef<HTMLDivElement>(null)
  const inView = useInView(ref, { threshold: 0.3 })
  const progressRef = useRef(0)
  const rafRef = useRef<number | null>(null)

  useEffect(() => {
    if (!inView) return

    const animate = () => {
      progressRef.current += 0.003
      if (progressRef.current > 1) {
        progressRef.current = 0
        setActiveIdx(i => (i + 1) % AIRCRAFT.length)
      }
      setProgress(progressRef.current)
      rafRef.current = requestAnimationFrame(animate)
    }

    rafRef.current = requestAnimationFrame(animate)
    return () => { if (rafRef.current) cancelAnimationFrame(rafRef.current) }
  }, [inView])

  const active = AIRCRAFT[activeIdx]

  return (
    <section id="flyover" className="relative py-32 overflow-hidden" ref={ref}>
      {/* Background */}
      <div className="absolute inset-0 pointer-events-none"
        style={{ background: 'radial-gradient(ellipse at center top, rgba(56,107,242,0.05) 0%, transparent 70%)' }} />

      <div className="w-full px-6 md:px-10 lg:px-16">
        <div className="text-center mb-16">
          <div className="inline-flex items-center gap-2 font-mono text-xs tracking-widest uppercase text-runway-muted mb-4 px-4 py-2 rounded-full border border-runway-border">
            ⚡ FLYOVER ALERT SYSTEM
          </div>
          <h2 className="font-sans font-bold text-4xl md:text-5xl text-white mb-4">
            T-5. T-2. T-0.<br />
            <span className="gradient-text">We've Got Your Back.</span>
          </h2>
          <p className="text-runway-muted text-lg max-w-xl mx-auto">
            Three escalating alerts make sure you never miss a meeting —
            each more dramatic than the last.
          </p>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-2 gap-12 items-center">
          {/* Left: Aircraft tracks */}
          <div className="flex flex-col gap-4">
            {AIRCRAFT.map((a, i) => (
              <AircraftTrack
                key={i}
                aircraft={a}
                active={i === activeIdx}
                progress={i === activeIdx ? progress : 0}
              />
            ))}
          </div>

          {/* Right: Detail panel */}
          <div
            className="rounded-2xl p-8 transition-all duration-700"
            style={{
              background: 'rgba(20,25,36,0.8)',
              border: `1px solid ${active.color}`,
              boxShadow: `0 0 40px ${active.glow}`,
            }}
          >
            <div className="font-mono text-xs tracking-widest uppercase mb-2" style={{ color: active.color }}>
              ALERT STYLE · {active.style}
            </div>
            <h3 className="font-sans font-bold text-3xl text-white mb-4">{active.title}</h3>
            <p className="text-runway-muted text-base leading-relaxed mb-8">{active.desc}</p>

            <div className="flex gap-4 mb-6">
              <div className="flex-1 rounded-xl p-4 bg-runway-bg border border-runway-border text-center">
                <div className="font-mono text-xs tracking-widest uppercase text-runway-dim mb-1">Speed</div>
                <div className="font-mono font-bold" style={{ color: active.color }}>{active.speed}</div>
              </div>
              <div className="flex-1 rounded-xl p-4 bg-runway-bg border border-runway-border text-center">
                <div className="font-mono text-xs tracking-widest uppercase text-runway-dim mb-1">Alert</div>
                <div className="font-mono font-bold" style={{ color: active.color }}>{active.label}</div>
              </div>
            </div>

            {/* Progress bar */}
            <div className="h-1 rounded-full bg-runway-surface overflow-hidden">
              <div
                className="h-full rounded-full transition-all duration-100"
                style={{
                  width: `${progress * 100}%`,
                  background: `linear-gradient(90deg, ${active.color}, transparent)`,
                }}
              />
            </div>

            {/* Controls */}
            <div className="flex gap-3 mt-6">
              {AIRCRAFT.map((a, i) => (
                <button
                  key={i}
                  onClick={() => { setActiveIdx(i); progressRef.current = 0 }}
                  className="flex-1 py-2 rounded-lg font-mono text-xs tracking-widest uppercase transition-all"
                  style={{
                    background: i === activeIdx ? `${a.glow}` : 'transparent',
                    color: i === activeIdx ? a.color : '#4A5568',
                    border: `1px solid ${i === activeIdx ? a.color : '#1E2D45'}`,
                  }}
                >
                  {a.emoji}
                </button>
              ))}
            </div>
          </div>
        </div>
      </div>
    </section>
  )
}
