import AppKit

// MARK: - CLI Commands
let args = CommandLine.arguments
let command = args.count > 1 ? args[1] : nil

switch command {
case "start":
    startInBackground()
case "stop":
    stopRunway()
case "status":
    showStatus()
case "--help", "-h", "help":
    printUsage()
case nil:
    // No subcommand: behave like `start` (background fork)
    // Unless launched by launchd, in which case run in foreground
    if getppid() == 1 || ProcessInfo.processInfo.environment["RUNWAY_DAEMONIZED"] != nil {
        runApp()
    } else {
        startInBackground()
    }
default:
    fputs("Unknown command: \(command!)\n", stderr)
    printUsage()
    exit(1)
}

// MARK: - Start (fork into background + install LaunchAgent)
func startInBackground() {
    // Check if already running
    if let pidStr = try? String(contentsOfFile: "/tmp/runway.pid", encoding: .utf8),
       let pid = Int32(pidStr.trimmingCharacters(in: .whitespacesAndNewlines)),
       kill(pid, 0) == 0 {
        print("")
        print("  \u{001B}[33m▸\u{001B}[0m Runway is already running (PID \(pid))")
        print("  \u{001B}[90mUse `runway-meeting stop` to stop it.\u{001B}[0m")
        print("")
        exit(0)
    }

    // Resolve the full path of the current executable
    let execPath: String
    if args[0].hasPrefix("/") {
        execPath = args[0]
    } else if let resolvedURL = Bundle.main.executableURL {
        execPath = resolvedURL.resolvingSymlinksInPath().path
    } else {
        let cwd = FileManager.default.currentDirectoryPath
        execPath = (cwd as NSString).appendingPathComponent(args[0])
    }

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

    // No subcommand — run in foreground mode (the spawned process)
    let argv: [UnsafeMutablePointer<CChar>?] = [strdup(execPath)!, nil]

    var pid: pid_t = 0
    let result = posix_spawn(&pid, execPath, &fileActions, &spawnAttr, argv, envp)

    // Cleanup
    posix_spawn_file_actions_destroy(&fileActions)
    posix_spawnattr_destroy(&spawnAttr)
    argv.forEach { $0.map { free($0) } }
    envp.forEach { $0.map { free($0) } }

    if result != 0 {
        fputs("Failed to start: \(String(cString: strerror(result)))\n", stderr)
        exit(1)
    }

    // Install LaunchAgent for auto-start on login
    LaunchAgentManager.installIfNeeded()

    print("")
    print("  \u{001B}[36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\u{001B}[0m")
    print("  \u{001B}[1m\u{001B}[36m  Runway Meeting\u{001B}[0m")
    print("  \u{001B}[36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\u{001B}[0m")
    print("")
    print("  \u{001B}[32m✓\u{001B}[0m Started in background (PID \(pid))")
    print("  \u{001B}[32m✓\u{001B}[0m Auto-launch on login enabled")
    print("")
    print("  \u{001B}[90mYour next meeting will appear in the menu bar.\u{001B}[0m")
    print("  \u{001B}[90mUse `runway-meeting stop` to stop.\u{001B}[0m")
    print("")
    exit(0)
}

// MARK: - Stop (kill process + remove LaunchAgent)
func stopRunway() {
    var stopped = false

    // Kill running process
    let pidFile = "/tmp/runway.pid"
    if let pidStr = try? String(contentsOfFile: pidFile, encoding: .utf8),
       let pid = Int32(pidStr.trimmingCharacters(in: .whitespacesAndNewlines)) {
        if kill(pid, 0) == 0 {
            kill(pid, SIGTERM)
            stopped = true
            print("Runway stopped (PID \(pid))")
        }
    }

    if !stopped {
        print("Runway is not running")
    }

    // Unload and remove LaunchAgent
    let uid = getuid()
    let plistPath = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Library/LaunchAgents/com.mukesh.runway.plist").path

    let unload = Process()
    unload.executableURL = URL(fileURLWithPath: "/bin/launchctl")
    unload.arguments = ["bootout", "gui/\(uid)", plistPath]
    unload.standardOutput = FileHandle.nullDevice
    unload.standardError = FileHandle.nullDevice
    try? unload.run()
    unload.waitUntilExit()

    if FileManager.default.fileExists(atPath: plistPath) {
        try? FileManager.default.removeItem(atPath: plistPath)
    }

    // Clean up runtime files
    try? FileManager.default.removeItem(atPath: "/tmp/runway.pid")
    try? FileManager.default.removeItem(atPath: "/tmp/runway.out.log")
    try? FileManager.default.removeItem(atPath: "/tmp/runway.err.log")

    print("LaunchAgent removed (won't auto-start on login)")
    exit(0)
}

// MARK: - Status
func showStatus() {
    let pidFile = "/tmp/runway.pid"
    if let pidStr = try? String(contentsOfFile: pidFile, encoding: .utf8),
       let pid = Int32(pidStr.trimmingCharacters(in: .whitespacesAndNewlines)),
       kill(pid, 0) == 0 {
        print("Runway is running (PID \(pid))")
    } else {
        print("Runway is not running")
    }

    let plistPath = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Library/LaunchAgents/com.mukesh.runway.plist").path
    if FileManager.default.fileExists(atPath: plistPath) {
        print("Auto-start on login: enabled")
    } else {
        print("Auto-start on login: disabled")
    }
    exit(0)
}

// MARK: - Usage
func printUsage() {
    print("""
    Usage: runway-meeting <command>

    Commands:
      start    Start Runway in the background (auto-starts on login)
      stop     Stop Runway and disable auto-start
      status   Show whether Runway is running

    Examples:
      runway-meeting start
      runway-meeting stop
      runway-meeting status
    """)
    exit(0)
}

// MARK: - Run App (foreground, used by launchd or `start` spawn)
private let kLockFile = "/tmp/runway.pid"

func runApp() {
    // Single Instance Guard
    let currentPID = ProcessInfo.processInfo.processIdentifier

    if let contents = try? String(contentsOfFile: kLockFile, encoding: .utf8),
       let existingPID = Int32(contents.trimmingCharacters(in: .whitespacesAndNewlines)),
       existingPID != currentPID && kill(existingPID, 0) == 0 {
        // Another instance is already running — exit silently
        exit(0)
    }

    // Write our PID
    try? "\(currentPID)".write(toFile: kLockFile, atomically: true, encoding: .utf8)

    // Clean up PID file on exit
    atexit {
        try? FileManager.default.removeItem(atPath: kLockFile)
    }

    // App Startup — configure as agent app (no dock icon)
    let app = NSApplication.shared
    app.setActivationPolicy(.accessory)

    let delegate = AppDelegate()
    app.delegate = delegate

    app.run()
}
