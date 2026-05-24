import { useRef } from 'react'
import { useInView } from '../hooks/useInView'
import TerminalBlock from './TerminalBlock'

const FEATURES = [
  { icon: '🔒', text: 'Self-installing LaunchAgent' },
  { icon: '✈️', text: 'Starts automatically on login' },
  { icon: '🚫', text: 'Never duplicates or crashes' },
  { icon: '🔒', text: 'Private — no data leaves your Mac' },
  { icon: '⚡', text: 'Zero configuration needed' },
  { icon: '🍺', text: 'One command install via Homebrew' },
]

export default function InstallSection() {
  const ref = useRef<HTMLDivElement>(null)
  const inView = useInView(ref, { threshold: 0.2 })

  return (
    <section id="install" className="relative py-32 overflow-hidden" ref={ref}>
      {/* Radial glow */}
      <div className="absolute inset-0 pointer-events-none"
        style={{ background: 'radial-gradient(ellipse at center, rgba(56,107,242,0.07) 0%, transparent 70%)' }} />

      <div className="w-full max-w-5xl mx-auto px-6 md:px-10 text-center">
        <div className="inline-flex items-center gap-2 font-mono text-xs tracking-widest uppercase text-runway-muted mb-4 px-4 py-2 rounded-full border border-runway-border">
          🍺 INSTALL IN SECONDS
        </div>
        <h2 className="font-sans font-bold text-4xl md:text-5xl text-white mb-4">
          Zero Friction.<br />
          <span className="gradient-text">That's the Whole Point.</span>
        </h2>
        <p className="text-runway-muted text-lg max-w-xl mx-auto mb-12">
          One command. One minute. You're cleared for takeoff.
        </p>

        {/* Terminal */}
        <div
          className="mb-12 transition-all duration-700 max-w-2xl mx-auto"
          style={{ opacity: inView ? 1 : 0, transform: inView ? 'translateY(0)' : 'translateY(20px)' }}
        >
          <TerminalBlock />
        </div>

        {/* Feature grid */}
        <div className="grid grid-cols-2 md:grid-cols-3 gap-4 mb-12">
          {FEATURES.map((f, i) => (
            <div
              key={i}
              className="flex items-center gap-3 p-4 rounded-xl glass text-left transition-all duration-300 hover:border-runway-blue/40"
              style={{
                transitionDelay: `${i * 80}ms`,
                opacity: inView ? 1 : 0,
                transform: inView ? 'translateY(0)' : 'translateY(15px)',
              }}
            >
              <span className="text-xl">{f.icon}</span>
              <span className="text-runway-muted text-sm">{f.text}</span>
            </div>
          ))}
        </div>

        {/* CTA buttons */}
        <div className="flex flex-col sm:flex-row items-center justify-center gap-4">
          <a
            href="https://github.com/mukeshkuiry/runway"
            target="_blank"
            rel="noopener noreferrer"
            className="px-8 py-4 rounded-xl font-mono text-sm font-bold tracking-widest uppercase text-white flex items-center gap-2"
            style={{
              background: 'linear-gradient(135deg, #386BF2 0%, #614BE1 100%)',
              boxShadow: '0 0 30px rgba(56,107,242,0.4)',
            }}
          >
            <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor">
              <path d="M12 0c-6.626 0-12 5.373-12 12 0 5.302 3.438 9.8 8.207 11.387.599.111.793-.261.793-.577v-2.234c-3.338.726-4.033-1.416-4.033-1.416-.546-1.387-1.333-1.756-1.333-1.756-1.089-.745.083-.729.083-.729 1.205.084 1.839 1.237 1.839 1.237 1.07 1.834 2.807 1.304 3.492.997.107-.775.418-1.305.762-1.604-2.665-.305-5.467-1.334-5.467-5.931 0-1.311.469-2.381 1.236-3.221-.124-.303-.535-1.524.117-3.176 0 0 1.008-.322 3.301 1.23.957-.266 1.983-.399 3.003-.404 1.02.005 2.047.138 3.006.404 2.291-1.552 3.297-1.23 3.297-1.23.653 1.653.242 2.874.118 3.176.77.84 1.235 1.911 1.235 3.221 0 4.609-2.807 5.624-5.479 5.921.43.372.823 1.102.823 2.222v3.293c0 .319.192.694.801.576 4.765-1.589 8.199-6.086 8.199-11.386 0-6.627-5.373-12-12-12z" />
            </svg>
            View on GitHub
          </a>
          <a
            href="https://github.com/mukeshkuiry/runway/releases"
            target="_blank"
            rel="noopener noreferrer"
            className="px-8 py-4 rounded-xl font-mono text-sm tracking-widest uppercase text-runway-blue border border-runway-blue hover:bg-runway-blue/10 transition-all duration-300"
          >
            📦 Download .dmg
          </a>
        </div>

        {/* Requirement */}
        <p className="mt-6 font-mono text-xs text-runway-dim">
          Requires macOS 13+ · Apple Silicon & Intel · Free & Open Source (MIT)
        </p>
      </div>
    </section>
  )
}
