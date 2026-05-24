import { useState, useEffect } from 'react'

// ── Easter egg: Konami code ──
const KONAMI = [
  'ArrowUp','ArrowUp','ArrowDown','ArrowDown',
  'ArrowLeft','ArrowRight','ArrowLeft','ArrowRight',
  'b','a'
]

// ── Easter egg: Ejection shortcut (Cmd+Opt+Ctrl+E) ──
function useEasterEggs(onEject: () => void, onKonami: () => void) {
  useEffect(() => {
    let konamiIdx = 0
    const onKey = (e: KeyboardEvent) => {
      // Ejection seat
      if (e.key === 'e' && e.metaKey && e.altKey && e.ctrlKey) {
        onEject()
        return
      }
      // Konami
      if (e.key === KONAMI[konamiIdx]) {
        konamiIdx++
        if (konamiIdx === KONAMI.length) {
          onKonami()
          konamiIdx = 0
        }
      } else {
        konamiIdx = 0
      }
    }
    window.addEventListener('keydown', onKey)
    return () => window.removeEventListener('keydown', onKey)
  }, [onEject, onKonami])
}

export default function Footer() {
  const [ejectionActive, setEjectionActive] = useState(false)
  const [konamiActive, setKonamiActive] = useState(false)

  const handleEject = () => {
    setEjectionActive(true)
    setTimeout(() => setEjectionActive(false), 1500)
  }

  const handleKonami = () => {
    setKonamiActive(true)
    setTimeout(() => setKonamiActive(false), 3000)
  }

  useEasterEggs(handleEject, handleKonami)

  return (
    <>
      {/* ── Ejection flash ── */}
      {ejectionActive && (
        <div className="ejection-flash">
          <div className="text-center font-mono">
            <div className="text-8xl mb-4">🚀</div>
            <div className="text-4xl font-black tracking-widest text-white text-glow-red">
              EJECTION INITIATED
            </div>
            <div className="text-sm tracking-widest uppercase text-white/60 mt-2">
              MAYDAY · MAYDAY · MAYDAY
            </div>
          </div>
        </div>
      )}

      {/* ── Konami overlay ── */}
      {konamiActive && (
        <div className="fixed inset-0 z-[9999] pointer-events-none flex items-center justify-center">
          <div className="font-mono text-center animate-slide-up">
            <div className="text-6xl mb-3">📡</div>
            <div className="text-2xl font-black tracking-widest text-runway-green text-glow-green">
              MAYDAY · MAYDAY · MAYDAY
            </div>
            <div className="text-sm text-runway-muted mt-2">
              easter egg unlocked — you found the ATC frequency
            </div>
          </div>
        </div>
      )}

      {/* ── Footer ── */}
      <footer id="footer" className="relative py-20 border-t border-runway-border overflow-hidden">
        <div className="absolute inset-0 pointer-events-none"
          style={{ background: 'radial-gradient(ellipse at center bottom, rgba(56,107,242,0.05) 0%, transparent 60%)' }} />

        <div className="w-full max-w-6xl mx-auto px-6 md:px-10 lg:px-16 relative z-10">
          {/* Ejection seat section */}
          <div className="mb-16 py-10 px-8 rounded-2xl relative overflow-hidden"
            style={{ background: 'rgba(20,25,36,0.5)', border: '1px solid rgba(255,61,87,0.2)' }}>

            <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-8">
              {/* Left: text */}
              <div className="flex-1">
                <div className="font-mono text-xs tracking-widest uppercase text-runway-red mb-3 opacity-60">
                  EMERGENCY SYSTEM
                </div>
                <h3 className="font-sans font-bold text-3xl text-white mb-2">
                  Ejection Seat
                </h3>
                <p className="text-runway-muted text-sm max-w-sm">
                  Need to escape a meeting fast? Runway has you covered.
                </p>
              </div>

              {/* Right: shortcut + button */}
              <div className="flex flex-col items-start md:items-end gap-4">
                <div className="flex items-center gap-2 font-mono text-sm">
                  {['⌘', '⌥', '⌃', 'E'].map((k, i) => (
                    <span key={i} className="flex items-center gap-2">
                      <span
                        className="px-3 py-1.5 rounded-lg font-bold text-runway-red transition-all duration-300 hover:scale-110"
                        style={{
                          background: 'rgba(255,61,87,0.1)',
                          border: '1px solid rgba(255,61,87,0.4)',
                          boxShadow: ejectionActive ? '0 0 12px rgba(255,61,87,0.6)' : 'none',
                        }}
                      >
                        {k}
                      </span>
                      {i < 3 && <span className="text-runway-dim text-xs">+</span>}
                    </span>
                  ))}
                </div>
                <button
                  onClick={handleEject}
                  className="px-6 py-3 rounded-xl font-mono text-xs font-bold tracking-widest uppercase text-runway-red border border-runway-red/40 hover:bg-runway-red/10 hover:border-runway-red transition-all duration-300"
                >
                  Try Ejection Seat →
                </button>
              </div>
            </div>
          </div>

          {/* Main footer content */}
          <div className="flex flex-col md:flex-row justify-between gap-12 mb-16 text-left">
            {/* Brand */}
            <div>
              <div className="flex items-center gap-2 mb-4">
                <span className="text-2xl">✈</span>
                <span className="font-mono font-bold text-xl tracking-widest uppercase text-white">RUNWAY</span>
              </div>
              <p className="text-runway-muted text-sm leading-relaxed mb-4">
                Your macOS meeting co-pilot.<br />
                Aviation-themed alerts &amp; departure board.<br />
                Zero-friction meeting management.
              </p>
              <div className="font-mono text-xs text-runway-dim">
                MIT License · Open Source
              </div>
            </div>

            {/* Links */}
            <div className="pr-16">
              <div className="font-mono text-xs tracking-widest uppercase text-runway-dim mb-4">Links</div>
              <div className="flex flex-col gap-3">
                <a href="https://github.com/mukeshkuiry/runway" target="_blank" rel="noopener noreferrer"
                  className="text-runway-muted hover:text-white transition-colors text-sm flex items-center gap-2">
                  <svg width="14" height="14" viewBox="0 0 24 24" fill="currentColor"><path d="M12 0c-6.626 0-12 5.373-12 12 0 5.302 3.438 9.8 8.207 11.387.599.111.793-.261.793-.577v-2.234c-3.338.726-4.033-1.416-4.033-1.416-.546-1.387-1.333-1.756-1.333-1.756-1.089-.745.083-.729.083-.729 1.205.084 1.839 1.237 1.839 1.237 1.07 1.834 2.807 1.304 3.492.997.107-.775.418-1.305.762-1.604-2.665-.305-5.467-1.334-5.467-5.931 0-1.311.469-2.381 1.236-3.221-.124-.303-.535-1.524.117-3.176 0 0 1.008-.322 3.301 1.23.957-.266 1.983-.399 3.003-.404 1.02.005 2.047.138 3.006.404 2.291-1.552 3.297-1.23 3.297-1.23.653 1.653.242 2.874.118 3.176.77.84 1.235 1.911 1.235 3.221 0 4.609-2.807 5.624-5.479 5.921.43.372.823 1.102.823 2.222v3.293c0 .319.192.694.801.576 4.765-1.589 8.199-6.086 8.199-11.386 0-6.627-5.373-12-12-12z"/></svg>
                  GitHub Repository
                </a>
                <a href="https://github.com/mukeshkuiry/runway/releases" target="_blank" rel="noopener noreferrer"
                  className="text-runway-muted hover:text-white transition-colors text-sm">
                  📦 Releases
                </a>
                <a href="https://github.com/mukeshkuiry/runway/issues" target="_blank" rel="noopener noreferrer"
                  className="text-runway-muted hover:text-white transition-colors text-sm">
                  🐛 Report Issue
                </a>
              </div>
            </div>
          </div>

          {/* Bottom bar */}
          <div className="flex items-center justify-between pt-8 border-t border-runway-border">
            <div className="font-mono text-xs text-runway-dim">
              © 2026 Runway · Built for macOS · All systems go.
            </div>
            <div className="font-mono text-xs text-runway-dim">
              MIT License · Open Source
            </div>
          </div>
        </div>
      </footer>
    </>
  )
}
