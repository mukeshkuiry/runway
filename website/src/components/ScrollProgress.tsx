import { useEffect, useState } from 'react'

export default function ScrollProgress() {
  const [progress, setProgress] = useState(0)

  useEffect(() => {
    const onScroll = () => {
      const scrolled = window.scrollY
      const total = document.documentElement.scrollHeight - window.innerHeight
      setProgress(total > 0 ? (scrolled / total) * 100 : 0)
    }
    window.addEventListener('scroll', onScroll, { passive: true })
    return () => window.removeEventListener('scroll', onScroll)
  }, [])

  return (
    <div className="fixed top-0 left-0 right-0 z-[100] h-0.5">
      <div
        className="h-full transition-[width] duration-100"
        style={{
          width: `${progress}%`,
          background: 'linear-gradient(90deg, #386BF2, #614BE1, #00D4FF)',
          boxShadow: '0 0 8px rgba(56,107,242,0.6)',
        }}
      />
    </div>
  )
}
