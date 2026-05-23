import Foundation

/// Manages the LaunchAgent plist for auto-start at login.
/// The app self-installs its LaunchAgent on first run — no manual script needed.
enum LaunchAgentManager {
    private static let label = "com.mukesh.runway"
    private static var plistPath: String {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        return "\(home)/Library/LaunchAgents/\(label).plist"
    }

    /// Installs (or updates) the LaunchAgent plist pointing to the current executable.
    /// Called automatically on every launch to keep the plist in sync with the installed binary path.
    static func installIfNeeded() {
        let executablePath = ProcessInfo.processInfo.arguments[0]
        // Resolve to absolute path
        let resolvedPath: String
        if executablePath.hasPrefix("/") {
            resolvedPath = executablePath
        } else {
            let cwd = FileManager.default.currentDirectoryPath
            resolvedPath = (cwd as NSString).appendingPathComponent(executablePath)
        }

        let plistContent = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
          <key>Label</key>
          <string>\(label)</string>
          <key>Program</key>
          <string>\(resolvedPath)</string>
          <key>RunAtLoad</key>
          <true/>
          <key>KeepAlive</key>
          <false/>
          <key>ProcessType</key>
          <string>Background</string>
          <key>LimitLoadToSessionType</key>
          <string>Aqua</string>
          <key>LaunchOnlyOnce</key>
          <true/>
          <key>StandardOutPath</key>
          <string>/tmp/runway.out.log</string>
          <key>StandardErrorPath</key>
          <string>/tmp/runway.err.log</string>
        </dict>
        </plist>
        """

        let launchAgentsDir = (plistPath as NSString).deletingLastPathComponent
        try? FileManager.default.createDirectory(atPath: launchAgentsDir, withIntermediateDirectories: true)

        // Only write if content changed or file doesn't exist
        let existingContent = try? String(contentsOfFile: plistPath, encoding: .utf8)
        if existingContent != plistContent {
            try? plistContent.write(toFile: plistPath, atomically: true, encoding: .utf8)
            // Set correct permissions
            try? FileManager.default.setAttributes([.posixPermissions: 0o644], ofItemAtPath: plistPath)
        }
    }

    /// Removes the LaunchAgent (used on uninstall/disconnect if needed).
    static func uninstall() {
        try? FileManager.default.removeItem(atPath: plistPath)
    }
}
