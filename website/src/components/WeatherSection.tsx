import { useState, useRef } from 'react'
import { useInView } from '../hooks/useInView'

const WEATHER_STATES = [
  {
    key: 'clear',
    label: 'CLEAR SKIES',
    emoji: '☀️',
    color: '#00E676',
    bgFrom: '#0F2419',
    bgTo: '#0F1219',
    meetings: 1,
    desc: 'One meeting. Easy day. You\'ve got this.',
    particles: '⭐',
    particleCount: 20,
  },
  {
    key: 'overcast',
    label: 'OVERCAST',
    emoji: '☁️',
    color: '#FFD740',
    bgFrom: '#1A1A0F',
    bgTo: '#0F1219',
    meetings: 4,
    desc: 'Four meetings. Stay focused. Block your deep work time.',
    particles: '●',
    particleCount: 40,
  },
  {
    key: 'storm',
    label: 'STORM WARNING',
    emoji: '⛈️',
    color: '#FF3D57',
    bgFrom: '#1A0F0F',
    bgTo: '#0F1219',
    meetings: 8,
    desc: 'Back-to-back chaos. Brace for turbulence. You\'re in the storm.',
    particles: '⚡',
    particleCount: 60,
  },
]

function SkyParticle({ state }: { state: typeof WEATHER_STATES[0] }) {
  return (
    <div className="absolute inset-0 overflow-hidden pointer-events-none">
      {Array.from({ length: state.particleCount }).map((_, i) => (
        <div
          key={i}
          className="absolute text-xs animate-float"
          style={{
            left: `${Math.random() * 100}%`,
            top: `${Math.random() * 100}%`,
            opacity: Math.random() * 0.6 + 0.1,
            animationDelay: `${Math.random() * 5}s`,
            animationDuration: `${3 + Math.random() * 4}s`,
            fontSize: `${8 + Math.random() * 8}px`,
            color: state.color,
          }}
        >
          {state.particles}
        </div>
      ))}
    </div>
  )
}

function MeetingBar({ meetings, color }: { meetings: number; color: string }) {
  return (
    <div className="flex items-end gap-1 h-16">
      {Array.from({ length: 8 }).map((_, i) => (
        <div
          key={i}
          className="flex-1 rounded-sm transition-all duration-700"
          style={{
            height: `${i < meetings ? (60 + Math.random() * 40) : 8}%`,
            background: i < meetings ? color : '#1E2D45',
            boxShadow: i < meetings ? `0 0 8px ${color}` : 'none',
            transitionDelay: `${i * 80}ms`,
          }}
        />
      ))}
    </div>
  )
}

export default function WeatherSection() {
  const [activeIdx, setActiveIdx] = useState(0)
  const ref = useRef<HTMLDivElement>(null)
  useInView(ref, { threshold: 0.3 })
  const active = WEATHER_STATES[activeIdx]

  return (
    <section id="weather" className="relative py-32 overflow-hidden" ref={ref}>
      {/* Sky background */}
      <div
        className="absolute inset-0 transition-all duration-1000 pointer-events-none"
        style={{ background: `linear-gradient(180deg, ${active.bgFrom} 0%, ${active.bgTo} 100%)` }}
      />
      <SkyParticle state={active} key={active.key} />

      <div className="relative z-10 w-full px-6 md:px-10 lg:px-16">
        <div className="text-center mb-16">
          <div className="inline-flex items-center gap-2 font-mono text-xs tracking-widest uppercase text-runway-muted mb-4 px-4 py-2 rounded-full border border-runway-border glass">
            🌤 CALENDAR WEATHER
          </div>
          <h2 className="font-sans font-bold text-4xl md:text-5xl text-white mb-4">
            Know Your Day<br />
            <span className="gradient-text">Before It Knows You.</span>
          </h2>
          <p className="text-runway-muted text-lg max-w-xl mx-auto">
            Runway scores your calendar's cognitive load and shows
            you the forecast before you start your day.
          </p>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-2 gap-12 items-center">
          {/* Weather card */}
          <div
            className="rounded-2xl p-8 transition-all duration-700 relative overflow-hidden"
            style={{
              background: 'rgba(20,25,36,0.8)',
              border: `1px solid ${active.color}`,
              boxShadow: `0 0 40px rgba(${active.color}, 0.2), 0 0 80px rgba(${active.color}, 0.1)`,
            }}
          >
            <div className="flex items-center justify-between mb-6">
              <div>
                <div className="font-mono text-xs tracking-widest uppercase mb-1" style={{ color: active.color }}>
                  TODAY'S FORECAST
                </div>
                <div className="text-5xl">{active.emoji}</div>
              </div>
              <div className="text-right">
                <div className="font-mono font-bold text-2xl" style={{ color: active.color }}>
                  {active.label}
                </div>
                <div className="font-mono text-xs text-runway-muted mt-1">
                  {active.meetings} FLIGHT{active.meetings !== 1 ? 'S' : ''} TODAY
                </div>
              </div>
            </div>

            <MeetingBar meetings={active.meetings} color={active.color} />

            <p className="text-runway-muted text-sm mt-4 leading-relaxed">{active.desc}</p>

            {/* Status bar */}
            <div className="mt-4 h-1.5 rounded-full bg-runway-surface overflow-hidden">
              <div
                className="h-full rounded-full transition-all duration-700"
                style={{
                  width: `${(active.meetings / 8) * 100}%`,
                  background: `linear-gradient(90deg, #00E676, ${active.color})`,
                }}
              />
            </div>
            <div className="flex justify-between font-mono text-xs text-runway-dim mt-1">
              <span>CLEAR</span>
              <span>STORM</span>
            </div>
          </div>

          {/* Controls + info */}
          <div className="flex flex-col gap-6">
            {WEATHER_STATES.map((w, i) => (
              <button
                key={i}
                onClick={() => setActiveIdx(i)}
                className="flex items-center gap-4 p-5 rounded-xl transition-all duration-300 text-left"
                style={{
                  background: i === activeIdx ? 'rgba(20,25,36,0.9)' : 'rgba(15,18,25,0.5)',
                  border: `1px solid ${i === activeIdx ? w.color : '#1E2D45'}`,
                  boxShadow: i === activeIdx ? `0 0 20px ${w.color}20` : 'none',
                  transform: i === activeIdx ? 'translateX(8px)' : 'translateX(0)',
                }}
              >
                <span className="text-3xl">{w.emoji}</span>
                <div>
                  <div className="font-mono font-bold text-sm" style={{ color: i === activeIdx ? w.color : '#8099B3' }}>
                    {w.label}
                  </div>
                  <div className="font-mono text-xs text-runway-dim">
                    {w.meetings} meeting{w.meetings !== 1 ? 's' : ''} · {
                      i === 0 ? 'Calm day' : i === 1 ? 'Moderate load' : 'Heavy turbulence'
                    }
                  </div>
                </div>
                {i === activeIdx && (
                  <div className="ml-auto w-2 h-2 rounded-full" style={{ background: w.color }} />
                )}
              </button>
            ))}

            <div className="p-5 rounded-xl glass">
              <div className="font-mono text-xs tracking-widest uppercase text-runway-muted mb-2">
                COGNITIVE LOAD SCORE
              </div>
              <div
                className="font-mono font-bold text-4xl transition-all duration-700"
                style={{ color: active.color }}
              >
                {Math.round((active.meetings / 8) * 100)}%
              </div>
              <div className="font-mono text-xs text-runway-dim mt-1">
                {activeIdx === 0 ? 'In the green zone' : activeIdx === 1 ? 'Monitor closely' : 'Danger zone'}
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  )
}
