# Runway

A macOS menu bar app that transforms your Google Calendar into an aviation-themed command center. Get animated flyover notifications before meetings, track your daily meeting load, and never miss a call again.

![macOS](https://img.shields.io/badge/macOS-13.0+-blue) ![Swift](https://img.shields.io/badge/Swift-5.10-orange) ![License](https://img.shields.io/badge/License-MIT-green)

## Install

### Homebrew (Recommended)

```bash
brew tap mukeshkuiry-refyne/tap
brew install runway
```

Then launch it once:

```bash
runway
```

That's it. Runway will:
- Start silently in the background
- Automatically open on every future login (via LaunchAgent)
- Never open duplicate instances

### Manual Install

```bash
git clone https://github.com/mukeshkuiry-refyne/runway.git
cd runway
swift build -c release
.build/release/Runway
```

The binary self-installs its LaunchAgent on first run — no additional setup needed.

## How It Works (Zero Friction)

- **Self-installing** — On first launch, Runway installs a LaunchAgent (`~/Library/LaunchAgents/com.mukesh.runway.plist`) that starts it silently on every login. No manual scripts, no Terminal windows.
- **Single instance** — A PID lock (`/tmp/runway.pid`) ensures only one instance runs at a time. Duplicate launches exit immediately.
- **Background process** — Runs as a background agent with no Dock icon and no Terminal window.

## Google OAuth Configuration

1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Create a project (or use existing)
3. Enable **Google Calendar API**
4. Go to **Credentials** > Create **OAuth Client ID** > Type: **Desktop App**
5. Copy the Client ID and Client Secret

Configure credentials using one of:

**Option A: Environment variables**
```bash
export RUNWAY_GOOGLE_CLIENT_ID="your-client-id"
export RUNWAY_GOOGLE_CLIENT_SECRET="your-client-secret"
```

**Option B: Config file**
```bash
mkdir -p ~/.config/runway
echo '{"client_id":"your-client-id","client_secret":"your-client-secret"}' > ~/.config/runway/credentials.json
```

## Features

### Meeting Board Dashboard
- **Boarding Pass Cards** — Meetings displayed as sleek boarding passes with color-coded urgency indicators
- **Smart URL Extraction** — Automatically detects Zoom, Google Meet, and Microsoft Teams links
- **Calendar Weather Forecast** — Daily cognitive load scoring: Clear Skies, Overcast, Storm Warning
- **Conflict Detection** — Identifies overlapping meetings and surfaces ATC alerts
- **Meeting Analytics** — Real-time daily stats: time in meetings, focus time remaining
- **Pre-Flight Check** — Live hardware status (mic, audio, battery) before your next call
- **Click to Open** — Click any card to open in Google Calendar; JOIN button for video calls

### Animated Flyover Notifications
- **T-5 Minutes** — Calm plane glides across screen with meeting banner
- **T-2 Minutes** — Urgent flyover with smoke trail and orange warning
- **T-0 Minutes** — Centered notification card with pulsing JOIN button
- **Aircraft Types** — Biplane (casual), Jet (standard), Rocket (urgent), Blimp (all-day)
- **Hardware Warnings** — Mic mute, headset disconnect, low battery alerts on banner

### Smart Automations
- **Click to Board** — Hold Option key + click flying plane to join meeting
- **Autopilot Mode** — Auto-launches meeting URL at T-0
- **Focus Mode Sync** — Suppresses overlays when DND/presentation active
- **Ejection Seat** — `Cmd+Opt+Ctrl+E` emergency meeting exit

### System Integration
- **Multi-Monitor** — Overlays render on active display
- **Non-Blocking** — Transparent panels never steal focus
- **Google Calendar Sync** — OAuth2 with auto token refresh, polling every 60s
- **Auto Launch at Login** — Self-installing LaunchAgent, no setup required
- **Menu Bar Controls** — Weather status, conflicts, autopilot toggle, sync

## Usage

- **Left-click** menu bar icon — Opens meeting dashboard
- **Right-click** menu bar icon — Context menu (Sync, Autopilot, Weather, Conflicts, Disconnect, Quit)
- **Option + Click on flying plane** — Instantly join the meeting
- **Cmd+Opt+Ctrl+E** — Emergency exit protocol

On first launch, connect your Google Calendar via the onboarding flow.

## Project Structure

```
Sources/Runway/
├── main.swift                  # Entry point, single-instance guard, LaunchAgent install
├── AppDelegate.swift           # Menu bar, hotkeys, lifecycle
├── LaunchAgentManager.swift    # Self-installing LaunchAgent management
├── Models.swift                # Data models, enums, metrics types
├── CalendarManager.swift       # Google Calendar API + URL extraction + analytics
├── GoogleAuthManager.swift     # OAuth2 flow with loopback redirect
├── GoogleOAuthConfig.swift     # OAuth credentials configuration
├── KeychainManager.swift       # Local encrypted token storage
├── TimerManager.swift          # Three-stage alert scheduling engine
├── FlightPanel.swift           # Transparent NSPanel overlay
├── OverlayController.swift     # Alert dispatch, hardware checks, focus mode
├── Info.plist                  # App configuration
├── Runway.entitlements         # Sandbox permissions
└── Views/
    ├── OnboardingView.swift        # First-launch Google sign-in
    ├── MeetingsDashboardView.swift # Boarding pass dashboard + analytics
    └── ReminderAlertView.swift     # Flyover animations + aircraft sprites
```

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `Cmd+Opt+Ctrl+E` | Ejection Seat (emergency meeting exit) |
| `Option` (hold) | Enable click-through on flying notifications |

## Uninstall

```bash
brew uninstall runway
rm -f ~/Library/LaunchAgents/com.mukesh.runway.plist
rm -f /tmp/runway.pid
```

## Development

For local development, a helper script is available:

```bash
swift build -c release
./scripts/install-launchagent.sh
```

This is only needed for development — end users get auto-setup via the binary itself.

## Contributing

Contributions are welcome! Please open an issue first to discuss what you'd like to change.

## License

[MIT](LICENSE)
