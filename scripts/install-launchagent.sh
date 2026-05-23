#!/usr/bin/env bash
set -euo pipefail

# Installer for the user LaunchAgent for Runway
# Usage: ./scripts/install-launchagent.sh [path-to-executable]
# If no path is provided the script will locate the built executable under .build/*/release/Runway

usage() { cat <<USAGE
Usage: $0 [path-to-executable]

If no path is provided the script attempts to find the built executable at .build/*/release/Runway.
USAGE
}

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
  usage
  exit 0
fi

if [ "${1:-}" != "" ]; then
  EXE_PATH="$1"
else
  EXE_PATH="$(find .build -type f -name Runway 2>/dev/null | head -n1 || true)"
fi

if [ -z "$EXE_PATH" ]; then
  echo "Could not find built Runway executable. Build with: swift build -c release"
  exit 1
fi

# Resolve absolute path to the executable
EXE_PATH="$(cd "$(dirname "$EXE_PATH")" && pwd)/$(basename "$EXE_PATH")"
PLIST_DEST="$HOME/Library/LaunchAgents/com.mukesh.runway.plist"

mkdir -p "$HOME/Library/LaunchAgents"

cat > "$PLIST_DEST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>com.mukesh.runway</string>
  <key>Program</key>
  <string>$EXE_PATH</string>
  <key>RunAtLoad</key>
  <true/>
  <key>KeepAlive</key>
  <false/>
  <key>StandardOutPath</key>
  <string>/tmp/runway.out.log</string>
  <key>StandardErrorPath</key>
  <string>/tmp/runway.err.log</string>
</dict>
</plist>
EOF

chmod 644 "$PLIST_DEST"

# Unload previous (ignore errors) and bootstrap for GUI session
launchctl bootout gui/$(id -u) "$PLIST_DEST" 2>/dev/null || true
launchctl bootstrap gui/$(id -u) "$PLIST_DEST"
launchctl kickstart -kp gui/$(id -u)/com.mukesh.runway

echo "Installed $PLIST_DEST -> Program: $EXE_PATH"
