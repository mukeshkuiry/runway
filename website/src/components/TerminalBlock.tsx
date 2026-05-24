import { useEffect, useRef, useState } from 'react'

const LINES = [
  '$ brew install mukeshkuiry/tap/runway-meeting',
  '==> Downloading runway-meeting...',
  '==> Installing runway-meeting...',
  '==> Linking runway-meeting...',
  '✈  runway-meeting installed. Cleared for takeoff.',
  '$ runway-meeting start',
  '🛫  ATC online · All systems go.',
]

export default function TerminalBlock() {
  const [lines, setLines] = useState<string[]>([])
  const [lineIdx, setLineIdx] = useState(0)
  const [charIdx, setCharIdx] = useState(0)
  const [done, setDone] = useState(false)
  const timeoutRef = useRef<ReturnType<typeof setTimeout> | null>(null)

  useEffect(() => {
    if (done) return
    const line = LINES[lineIdx]
    if (!line) { setDone(true); return }

    if (charIdx < line.length) {
      timeoutRef.current = setTimeout(() => {
        setLines(prev => {
          const next = [...prev]
          next[lineIdx] = (next[lineIdx] || '') + line[charIdx]
          return next
        })
        setCharIdx(c => c + 1)
      }, lineIdx === 0 ? 80 : 20)
    } else {
      timeoutRef.current = setTimeout(() => {
        setLineIdx(i => i + 1)
        setCharIdx(0)
      }, lineIdx === 0 ? 600 : 200)
    }

    return () => { if (timeoutRef.current) clearTimeout(timeoutRef.current) }
  }, [lineIdx, charIdx, done])

  const restart = () => {
    setLines([])
    setLineIdx(0)
    setCharIdx(0)
    setDone(false)
  }

  return (
    <div className="rounded-xl overflow-hidden border border-runway-border font-mono text-sm">
      {/* title bar */}
      <div className="flex items-center gap-2 px-4 py-2.5 bg-runway-surface border-b border-runway-border">
        <span className="w-3 h-3 rounded-full bg-runway-red opacity-80" />
        <span className="w-3 h-3 rounded-full bg-runway-yellow opacity-80" />
        <span className="w-3 h-3 rounded-full bg-runway-green opacity-80" />
        <span className="ml-3 text-runway-muted text-xs tracking-widest uppercase">Terminal</span>
      </div>
      {/* body */}
      <div className="bg-runway-bg p-5 min-h-[160px]">
        {lines.map((line, i) => (
          <div key={i} className={`leading-7 ${
            i === 0 ? 'text-runway-teal' :
            i === lines.length - 1 && done ? 'text-runway-green' :
            'text-runway-muted'
          }`}>
            {i === 0 && <span className="text-runway-purple mr-2">›</span>}
            {line}
            {i === lineIdx && !done && (
              <span className="inline-block w-[2px] h-[1em] bg-runway-blue ml-0.5 animate-pulse align-middle" />
            )}
          </div>
        ))}
        {done && (
          <button
            onClick={restart}
            className="mt-4 text-xs text-runway-dim hover:text-runway-blue transition-colors"
          >
            ↺ run again
          </button>
        )}
      </div>
    </div>
  )
}
