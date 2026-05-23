# Runway

A macOS menu bar app that syncs with your Google Calendar and sends animated plane flyover notifications before meetings start.

![macOS](https://img.shields.io/badge/macOS-13.0+-blue) ![Swift](https://img.shields.io/badge/Swift-5.10-orange) ![License](https://img.shields.io/badge/License-MIT-green)

## Features

- **Meetings Dashboard** — See all upcoming meetings in a beautiful card-based UI, grouped by day
- **Plane Flyover Alerts** — Animated jet flies across your screen towing a banner with meeting info
  - 5 minutes before: calm flyover with meeting details
  - At start time: urgent red-tinted flyover with Join button
- **Google Calendar Sync** — OAuth2 integration, refreshes automatically
- **Launch at Login** — Starts with your Mac, always ready
- **Multi-Monitor** — Works across all screens and Spaces
- **Click-Through** — Notifications never block your mouse or keyboard

## Setup

### Prerequisites

- macOS 13.0+
- Swift 5.10+
- A Google Cloud project with Calendar API enabled

### Google OAuth Configuration

1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Create a project (or use existing)
3. Enable **Google Calendar API**
4. Go to **Credentials** → Create **OAuth Client ID** → Type: **Desktop App**
5. Copy the Client ID and Client Secret
6. Edit `Sources/Runway/GoogleOAuthConfig.swift` and replace the placeholder values

### Build & Run

```bash
git clone https://github.com/mukeshkuiry-refyne/runway.git
cd runway
swift build
swift run Runway
```

## Usage

- **Left-click** menu bar icon → Opens meeting dashboard
- **Right-click** menu bar icon → Context menu (Sync, Disconnect, Launch at Login, Quit)

On first launch, you'll be prompted to connect your Google Calendar. Sign in via browser and you're set.

## Project Structure

```
Sources/Runway/
├── main.swift                  # Entry point
├── AppDelegate.swift           # Menu bar + lifecycle
├── Models.swift                # Data models
├── CalendarManager.swift       # Google Calendar API client
├── GoogleAuthManager.swift     # OAuth2 flow with loopback server
├── GoogleOAuthConfig.swift     # OAuth credentials config
├── KeychainManager.swift       # Local token storage
├── TimerManager.swift          # Alert scheduling engine
├── FlightPanel.swift           # Transparent overlay window
├── OverlayController.swift     # Alert dispatch
├── Info.plist                  # App configuration
├── Runway.entitlements         # Sandbox permissions
└── Views/
    ├── OnboardingView.swift        # First-launch setup
    ├── MeetingsDashboardView.swift # Main dashboard
    └── ReminderAlertView.swift     # Plane flyover notifications
```

## Contributing

Contributions are welcome! Please open an issue first to discuss what you'd like to change.

## License

[MIT](LICENSE)
