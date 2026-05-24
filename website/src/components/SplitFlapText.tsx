import { useEffect, useRef, useState } from 'react'

const WORDS = [
  'STANDUP IN 5 MIN · GET READY',
  'ZOOM WITH SARAH · STARTING SOON',
  'YOU\'RE FREE UNTIL 2 PM · BREATHE',
  'DESIGN REVIEW · JOIN LINK READY',
  'NEXT: 1:1 WITH ALEX · 2:30 PM',
]

export default function SplitFlapText({ className = '' }: { className?: string }) {
  const [displayed, setDisplayed] = useState('')
  const [wordIdx, setWordIdx] = useState(0)
  const [charIdx, setCharIdx] = useState(0)
  const [phase, setPhase] = useState<'typing' | 'holding' | 'clearing'>('typing')
  const frameRef = useRef<ReturnType<typeof setTimeout> | null>(null)

  useEffect(() => {
    const word = WORDS[wordIdx]

    if (phase === 'typing') {
      if (charIdx <= word.length) {
        frameRef.current = setTimeout(() => {
          setDisplayed(word.slice(0, charIdx))
          setCharIdx(c => c + 1)
        }, 60)
      } else {
        frameRef.current = setTimeout(() => setPhase('holding'), 2000)
      }
    } else if (phase === 'clearing') {
      if (displayed.length > 0) {
        frameRef.current = setTimeout(() => {
          setDisplayed(d => d.slice(0, -1))
        }, 30)
      } else {
        setWordIdx(i => (i + 1) % WORDS.length)
        setCharIdx(0)
        setPhase('typing')
      }
    } else if (phase === 'holding') {
      setPhase('clearing')
    }

    return () => { if (frameRef.current) clearTimeout(frameRef.current) }
  }, [phase, charIdx, wordIdx, displayed])

  return (
    <span className={className}>
      {displayed.split('').map((char, i) => (
        <span key={i} className="flip-char" style={{ animationDelay: `${i * 0.02}s` }}>
          {char === ' ' ? '\u00A0' : char}
        </span>
      ))}
      <span className="inline-block w-[2px] h-[1em] bg-runway-blue ml-1 animate-pulse align-middle" />
    </span>
  )
}
