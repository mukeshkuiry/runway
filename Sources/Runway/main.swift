import AppKit

// MARK: - Background Daemon Fork
// If not already running as a daemon (via launchd or fork), fork into background
// so the terminal is released immediately.
let isLaunchdChild = getppid() == 1
if ProcessInfo.processInfo.environment["RUNWAY_DAEMONIZED"] == nil && !isLaunchdChild {

    let execPath = ProcessInfo.processInfo.arguments[0]

    // Set up file actions: redirect stdin/stdout/stderr to /dev/null
    var fileActions: posix_spawn_file_actions_t?
    posix_spawn_file_actions_init(&fileActions)
    posix_spawn_file_actions_addopen(&fileActions, STDIN_FILENO, "/dev/null", O_RDONLY, 0)
    posix_spawn_file_actions_addopen(&fileActions, STDOUT_FILENO, "/dev/null", O_WRONLY, 0)
    posix_spawn_file_actions_addopen(&fileActions, STDERR_FILENO, "/dev/null", O_WRONLY, 0)

    // Set up spawn attributes: start a new session (setsid) so terminal close doesn't kill it
    var spawnAttr: posix_spawnattr_t?
    posix_spawnattr_init(&spawnAttr)
    posix_spawnattr_setflags(&spawnAttr, Int16(POSIX_SPAWN_SETSID))

    // Build environment with RUNWAY_DAEMONIZED=1
    var env = ProcessInfo.processInfo.environment
    env["RUNWAY_DAEMONIZED"] = "1"
    let envp: [UnsafeMutablePointer<CChar>?] = env.map { key, value in
        strdup("\(key)=\(value)")!
    } + [nil]

    let argv: [UnsafeMutablePointer<CChar>?] = [strdup(execPath)!, nil]

    var pid: pid_t = 0
    let result = posix_spawn(&pid, execPath, &fileActions, &spawnAttr, argv, envp)

    // Cleanup
    posix_spawn_file_actions_destroy(&fileActions)
    posix_spawnattr_destroy(&spawnAttr)
    argv.forEach { $0.map { free($0) } }
    envp.forEach { $0.map { free($0) } }

    if result != 0 {
        fputs("Failed to start in background: \(String(cString: strerror(result)))\n", stderr)
        exit(1)
    }
    // Parent exits immediately — terminal is free
    exit(0)
}

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
