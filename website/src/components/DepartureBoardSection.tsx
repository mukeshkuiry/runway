import { useState, useEffect, useRef } from 'react'
import { useInView } from '../hooks/useInView'

const URGENCY_STATES = [
  { label: 'SCHEDULED',     color: '#00E676', glow: 'rgba(0,230,118,0.4)',   badge: '🟢', time: 'T-60' },
  { label: 'BOARDING NOW',  color: '#FFD740', glow: 'rgba(255,215,64,0.4)',  badge: '🟡', time: 'T-5'  },
  { label: 'FINAL CALL',    color: '#FF9100', glow: 'rgba(255,145,0,0.4)',   badge: '🟠', time: 'T-2'  },
  { label: 'DEPARTING NOW', color: '#FF3D57', glow: 'rgba(255,61,87,0.4)',   badge: '🔴', time: 'T-0'  },
]

const CARDS = [
  { title: 'Design Review', platform: 'Zoom', time: '10:00 AM', attendees: ['JD', 'SR', 'MK'], duration: '45m' },
  { title: 'Sprint Planning', platform: 'Meet', time: '11:30 AM', attendees: ['TL', 'PO', 'QA'], duration: '90m' },
  { title: 'Investor Call', platform: 'Teams', time: '2:00 PM', attendees: ['CEO', 'CFO'], duration: '30m' },
]

function BoardingCard({ card, urgencyIdx, style }: {
  card: typeof CARDS[0],
  urgencyIdx: number,
  style?: React.CSSProperties
}) {
  const u = URGENCY_STATES[urgencyIdx]

  return (
    <div
      className="rounded-2xl p-5 w-72 font-mono transition-all duration-700 hover:scale-105 cursor-default"
      style={{
        background: 'rgba(20,25,36,0.9)',
        border: `1px solid ${u.color}`,
        boxShadow: `0 0 20px ${u.glow}, 0 20px 40px rgba(0,0,0,0.4)`,
        ...style,
      }}
    >
      {/* Header */}
      <div className="flex items-center justify-between mb-3">
        <span className="text-xs tracking-widest uppercase" style={{ color: u.color }}>{u.badge} {u.label}</span>
        <span className="text-xs text-runway-dim">{u.time}</span>
      </div>

      {/* Divider */}
      <div className="h-px mb-3" style={{ background: `linear-gradient(90deg, ${u.color}, transparent)` }} />

      {/* Flight info */}
      <div className="mb-3">
        <div className="text-white text-base font-bold mb-1">{card.title}</div>
        <div className="flex items-center gap-2 text-runway-muted text-xs">
          <span className="px-2 py-0.5 rounded bg-runway-surface border border-runway-border">{card.platform}</span>
          <span>{card.time}</span>
          <span>·</span>
          <span>{card.duration}</span>
        </div>
      </div>

      {/* Attendees */}
      <div className="flex items-center gap-1 mb-4">
        {card.attendees.map((a, i) => (
          <div
            key={i}
            className="w-7 h-7 rounded-full flex items-center justify-center text-xs font-bold"
            style={{ background: `hsl(${i * 60 + 200}, 70%, 45%)`, border: '1px solid rgba(255,255,255,0.1)' }}
          >
            {a[0]}
          </div>
        ))}
        <span className="text-runway-dim text-xs ml-2">+{card.attendees.length} attending</span>
      </div>

      {/* Join button */}
      <button
        className="w-full py-2 rounded-lg text-xs font-bold tracking-widest uppercase transition-all duration-300"
        style={{
          background: urgencyIdx >= 2 ? `linear-gradient(135deg, ${u.color}, ${URGENCY_STATES[Math.min(urgencyIdx+1, 3)].color})` : 'rgba(56,107,242,0.15)',
          color: urgencyIdx >= 2 ? '#fff' : u.color,
          border: `1px solid ${u.color}`,
          animation: urgencyIdx === 3 ? 'glowPulse 0.8s ease-in-out infinite' : 'none',
        }}
      >
        {urgencyIdx === 3 ? '⚡ JOIN NOW' : '→ Join Meeting'}
      </button>
    </div>
  )
}

export default function DepartureBoardSection() {
  const [urgencyIdx, setUrgencyIdx] = useState(0)
  const [tick, setTick] = useState(0)
  const ref = useRef<HTMLDivElement>(null)
  const inView = useInView(ref, { threshold: 0.3 })

  useEffect(() => {
    if (!inView) return
    const interval = setInterval(() => {
      setTick(t => t + 1)
    }, 2000)
    return () => clearInterval(interval)
  }, [inView])

  useEffect(() => {
    setUrgencyIdx(tick % URGENCY_STATES.length)
  }, [tick])

  const u = URGENCY_STATES[urgencyIdx]

  return (
    <section id="features" className="relative py-32 overflow-hidden" ref={ref}>
      {/* Background glow */}
      <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[600px] h-[600px] rounded-full opacity-10 pointer-events-none"
        style={{ background: `radial-gradient(circle, ${u.color} 0%, transparent 70%)`, transition: 'background 1s' }} />

      <div className="w-full px-6 md:px-10 lg:px-16">
        {/* Section label */}
        <div className="text-center mb-16">
          <div className="inline-flex items-center gap-2 font-mono text-xs tracking-widest uppercase text-runway-muted mb-4 px-4 py-2 rounded-full border border-runway-border">
            <span className="w-2 h-2 rounded-full animate-pulse" style={{ background: u.color }} />
            DEPARTURE BOARD
          </div>
          <h2 className="font-sans font-bold text-4xl md:text-5xl text-white mb-4">
            Every Meeting.<br />
            <span className="gradient-text">One Command Center.</span>
          </h2>
          <p className="text-runway-muted text-lg max-w-xl mx-auto">
            Real-time boarding cards with urgency states, attendee tracking,
            and one-click join for Zoom, Meet & Teams.
          </p>
        </div>

        {/* Cards display */}
        <div className="flex flex-col md:flex-row items-center justify-center gap-6 mb-16">
          {CARDS.map((card, i) => (
            <BoardingCard
              key={i}
              card={card}
              urgencyIdx={(urgencyIdx + i) % URGENCY_STATES.length}
              style={{
                transform: `rotate(${(i - 1) * 3}deg) translateY(${i === 1 ? '-10px' : '0'})`,
                zIndex: i === 1 ? 10 : 1,
              }}
            />
          ))}
        </div>

        {/* Urgency legend */}
        <div className="flex flex-wrap justify-center gap-6">
          {URGENCY_STATES.map((s, i) => (
            <button
              key={i}
              onClick={() => setUrgencyIdx(i)}
              className="flex items-center gap-2 px-4 py-2 rounded-lg font-mono text-xs tracking-widest uppercase transition-all duration-300"
              style={{
                color: urgencyIdx === i ? s.color : '#4A5568',
                border: `1px solid ${urgencyIdx === i ? s.color : '#1E2D45'}`,
                background: urgencyIdx === i ? `${s.glow}` : 'transparent',
              }}
            >
              <span className="w-2 h-2 rounded-full" style={{ background: s.color }} />
              {s.time} · {s.label}
            </button>
          ))}
        </div>
      </div>
    </section>
  )
}
