import AppKit

// MARK: - Single Instance Guard
// Prevent multiple instances from running simultaneously
let lockFile = "/tmp/runway.pid"
let currentPID = ProcessInfo.processInfo.processIdentifier

func isAnotherInstanceRunning() -> Bool {
    guard let contents = try? String(contentsOfFile: lockFile, encoding: .utf8),
          let existingPID = Int32(contents.trimmingCharacters(in: .whitespacesAndNewlines)) else {
        return false
    }
    // Check if that PID is still alive
    if existingPID != currentPID && kill(existingPID, 0) == 0 {
        return true
    }
    return false
}

if isAnotherInstanceRunning() {
    // Another instance is already running — exit silently
    exit(0)
}

// Write our PID
try? "\(currentPID)".write(toFile: lockFile, atomically: true, encoding: .utf8)

// Clean up PID file on exit
atexit {
    try? FileManager.default.removeItem(atPath: lockFile)
}

// MARK: - Self-install LaunchAgent (zero friction for end users)
LaunchAgentManager.installIfNeeded()

// MARK: - App Startup
// Configure as agent app (no dock icon)
let app = NSApplication.shared
app.setActivationPolicy(.accessory)

let delegate = AppDelegate()
app.delegate = delegate

app.run()
