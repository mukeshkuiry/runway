# ✈ Runway — Website

Marketing website for [Runway](https://github.com/mukeshkuiry/runway) — the aviation-themed macOS meeting co-pilot.

Built with React, TypeScript, Vite, and Tailwind CSS.

---

## 🚀 Getting Started

```bash
# Install dependencies
npm install

# Start dev server
npm run dev

# Production build
npm run build
```

---

## 🗂 Project Structure

```
src/
├── components/       # All UI sections & shared components
│   ├── Navbar.tsx
│   ├── HeroSection.tsx
│   ├── DepartureBoardSection.tsx
│   ├── FlyoverSection.tsx
│   ├── WeatherSection.tsx
│   ├── ATCSection.tsx
│   ├── InstallSection.tsx
│   ├── Footer.tsx
│   ├── TerminalBlock.tsx
│   ├── SplitFlapText.tsx
│   └── ScrollProgress.tsx
├── scenes/
│   └── HeroScene.tsx   # Three.js 3D runway (lazy-loaded)
├── hooks/
│   └── useInView.ts
└── index.css           # Global styles & Tailwind
```

---

## 🛠 Tech Stack

| | |
|---|---|
| Framework | React 18 + TypeScript |
| Build | Vite |
| Styling | Tailwind CSS |
| 3D | Three.js (lazy-loaded) |
| Fonts | JetBrains Mono · Space Grotesk |

---

## 📦 Install Runway (the app)

```bash
brew install mukeshkuiry/tap/runway-meeting
runway-meeting start
```

---

## 📄 License

MIT © 2026 [Mukesh Kuiry](https://github.com/mukeshkuiry)

---

