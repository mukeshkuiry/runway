# Runway - Publish Guide

A complete plan to ship Runway to the public.

---

## 1. Distribution Channel Decision

| Option | Pros | Cons |
|--------|------|------|
| **Mac App Store** | Discovery, trust, auto-updates | 30% cut, strict review, sandboxing limits |
| **Direct Download (website)** | Full control, no cut, faster releases | Need own update mechanism, notarization required |
| **Both** | Maximum reach | More maintenance |

**Recommendation:** Start with **Direct Download** + Homebrew Cask. Faster to ship, no Apple review delays, and your target audience (professionals/CXOs) are comfortable installing apps directly.

---

## 2. Pre-Launch Checklist

### 2.1 Developer Account & Signing

- [ ] Enroll in **Apple Developer Program** ($99/year) — https://developer.apple.com/programs/
- [ ] Create a **Developer ID Application** certificate (for distribution outside App Store)
- [ ] Create a **provisioning profile** for the app

### 2.2 Google OAuth Production Setup

- [ ] Go to Google Cloud Console → your project
- [ ] Fill out the **OAuth Consent Screen** completely (app name, logo, privacy policy URL, support email)
- [ ] Submit for **Google verification** (required for public apps accessing calendar) — takes 2-4 weeks
- [ ] Once approved, remove the "Testing" restriction so any Google user can sign in
- [ ] Set your published Client ID in `GoogleOAuthConfig.swift`

### 2.3 Code Signing & Notarization

```bash
# Archive the build
swift build -c release

# Sign with Developer ID
codesign --deep --force --options runtime \
  --sign "Developer ID Application: Your Name (TEAM_ID)" \
  .build/release/Runway

# Create a .dmg or .zip for notarization
ditto -c -k --keepParent .build/release/Runway Runway.zip

# Submit for notarization
xcrun notarytool submit Runway.zip \
  --apple-id "you@email.com" \
  --team-id "TEAM_ID" \
  --password "app-specific-password" \
  --wait

# Staple the ticket
xcrun stapler staple Runway.app
```

### 2.4 Packaging

- [ ] Wrap the binary in a proper `.app` bundle (Info.plist, icon, entitlements)
- [ ] Create a `.dmg` installer with a drag-to-Applications design
- [ ] OR use Homebrew Cask for technical users

---

## 3. Branding & Marketing Assets

- [ ] **App Icon** — design a proper 1024x1024 icon (airplane departure + calendar motif)
- [ ] **Landing Page** — single-page site (runway.app or getrunway.dev)
  - Hero: screen recording GIF of the plane flyover
  - Features: Dashboard, Flyover alerts, Google Calendar sync, Launch at login
  - Download button
- [ ] **Privacy Policy** — required by Google OAuth verification
  - State: "We only read calendar event metadata. No data is stored on external servers. Tokens are stored locally on your device."
- [ ] **Terms of Service** — simple, standard

---

## 4. Infrastructure

| Need | Solution |
|------|----------|
| Landing page | GitHub Pages, Vercel, or Framer |
| Auto-updates | [Sparkle Framework](https://sparkle-project.org/) — industry standard for macOS |
| Analytics (optional) | TelemetryDeck (privacy-first, macOS native) |
| Crash reporting | Sentry or none (keep it simple) |
| Domain | `runway.so`, `getrunway.app`, `runwayapp.dev` |

---

## 5. Launch Strategy

### Week 1-2: Prep

- Finish Google OAuth verification
- Get Developer ID certificate
- Build landing page
- Record a 30-second demo GIF/video

### Week 3: Soft Launch

Share on:

- [ ] Twitter/X — tag indie Mac dev community
- [ ] r/macapps on Reddit
- [ ] Hacker News (Show HN)
- [ ] Product Hunt (schedule a launch day)
- [ ] MacStories / 9to5Mac tip line

### Week 4+: Iterate

- Collect feedback
- Add features (multiple calendar support, custom alert timing, sounds)
- Consider App Store submission if demand warrants it

---

## 6. Monetization Options

| Model | Approach |
|-------|----------|
| **Free forever** | Open source, build reputation |
| **Freemium** | Free with 1 calendar, paid for multi-calendar + custom timings |
| **One-time purchase** | $9-15 via Gumroad or Paddle |
| **Subscription** | $3/month — probably overkill for this scope |

**Recommendation:** Launch free, open source on GitHub. Build community. Monetize later with a Pro tier if there's demand.

---

## 7. Open Source Checklist (if going that route)

- [ ] Add `LICENSE` (MIT)
- [ ] Add `README.md` with screenshots, install instructions, build steps
- [ ] Add `CONTRIBUTING.md`
- [ ] Remove hardcoded OAuth credentials — use environment variables or a config file
- [ ] Add GitHub Actions CI for automated builds
- [ ] Create GitHub Releases with signed `.dmg` downloads

---

## 8. Immediate Next Steps

1. **Register Apple Developer account** (if you don't have one)
2. **Submit Google OAuth for verification** (this is the bottleneck — start now)
3. **Design an app icon**
4. **Set up a landing page**
5. **Integrate Sparkle** for auto-updates
