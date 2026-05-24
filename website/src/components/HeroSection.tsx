import { Suspense, lazy, useEffect, useRef } from 'react'
const HeroScene = lazy(() => import('../scenes/HeroScene'))
import SplitFlapText from './SplitFlapText'

export default function HeroSection() {
  const contentRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    // Fade in content after mount
    const el = contentRef.current
    if (!el) return
    el.style.opacity = '0'
    el.style.transform = 'translateY(30px)'
    const raf = requestAnimationFrame(() => {
      el.style.transition = 'opacity 1s ease 0.5s, transform 1s ease 0.5s'
      el.style.opacity = '1'
      el.style.transform = 'translateY(0)'
    })
    return () => cancelAnimationFrame(raf)
  }, [])

  return (
    <section className="relative w-full h-screen overflow-hidden">
      {/* ── Three.js canvas fills entire background ── */}
      <div className="absolute inset-0">
        <Suspense fallback={<div className="absolute inset-0 bg-runway-bg" />}>
          <HeroScene />
        </Suspense>
      </div>

      {/* ── Subtle overlays — keep runway visible ── */}
      {/* thin top bar so navbar blends */}
      <div className="absolute inset-x-0 top-0 h-32 bg-gradient-to-b from-runway-bg/60 to-transparent pointer-events-none" />
      {/* left edge fade */}
      <div className="absolute inset-y-0 left-0 w-24 bg-gradient-to-r from-runway-bg/60 to-transparent pointer-events-none" />
      {/* right edge fade */}
      <div className="absolute inset-y-0 right-0 w-24 bg-gradient-to-l from-runway-bg/60 to-transparent pointer-events-none" />
      {/* bottom fade for section transition */}
      <div className="absolute inset-x-0 bottom-0 h-28 bg-gradient-to-t from-runway-bg to-transparent pointer-events-none" />

      {/* ── Content — centred column in upper 60%, runway shows below ── */}
      <div
        ref={contentRef}
        className="relative z-10 h-full w-full flex flex-col items-center justify-start text-center px-6 pt-32 pb-8 overflow-y-auto"
      >
        {/* Status badge */}
        <div className="mb-5 flex items-center gap-2 px-4 py-2 rounded-full glass font-mono text-xs tracking-widest uppercase text-runway-green border-glow-green">
          <span className="w-2 h-2 rounded-full bg-runway-green animate-pulse" />
          ⌘ macOS App · Free
        </div>

        {/* Main headline */}
        <h1 className="font-sans font-bold text-5xl sm:text-6xl md:text-7xl lg:text-8xl text-white leading-[1.08] mb-4 max-w-5xl">
          Your meetings deserve<br />
          <span className="gradient-text text-glow-blue">a heads-up.</span>
        </h1>

        {/* Animated sub-headline — shows real scenarios */}
        <div className="font-mono text-sm md:text-base tracking-widest uppercase text-runway-muted mb-3 h-7 flex items-center justify-center">
          <SplitFlapText />
        </div>

        {/* Description */}
        <p className="text-runway-muted text-sm md:text-base max-w-lg mb-7 leading-relaxed">
          Runway lives in your menu bar and tells you about your next meeting
          before it sneaks up on you — alerts, a glanceable dashboard,
          and your join link, always one click away.
        </p>

        {/* CTA buttons */}
        <div className="flex flex-row items-center justify-center gap-3 mb-8 flex-wrap">
          <a
            href="#install"
            className="px-7 py-3 rounded-xl font-mono text-sm font-bold tracking-widest uppercase text-white"
            style={{ background: 'linear-gradient(135deg, #386BF2 0%, #614BE1 100%)', boxShadow: '0 0 30px rgba(56,107,242,0.4)' }}
          >
            ✈ Install Now
          </a>
          <a
            href="#features"
            className="px-7 py-3 rounded-xl font-mono text-sm tracking-widest uppercase text-runway-blue border border-runway-blue hover:bg-runway-blue/10 transition-all duration-300"
          >
            See It In Action ↓
          </a>
        </div>

        {/* ── Scroll indicator ── */}
        <div className="mt-auto pt-6 flex flex-col items-center gap-1.5 text-runway-muted">
          <span className="font-mono text-xs tracking-widest uppercase opacity-50">Scroll</span>
          <div className="w-px h-8 bg-gradient-to-b from-runway-blue to-transparent animate-pulse" />
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" className="animate-bounce">
            <path d="M12 5v14M5 12l7 7 7-7" />
          </svg>
        </div>
      </div>
    </section>
  )
}
