import Foundation

/// Google OAuth2 configuration
/// Set these environment variables before running:
///   RUNWAY_GOOGLE_CLIENT_ID
///   RUNWAY_GOOGLE_CLIENT_SECRET
///
/// Or create a file at ~/.config/runway/credentials.json with:
/// { "client_id": "...", "client_secret": "..." }
struct GoogleOAuthConfig {
    static let clientID: String = {
        if let envValue = ProcessInfo.processInfo.environment["RUNWAY_GOOGLE_CLIENT_ID"], !envValue.isEmpty {
            return envValue
        }
        if let creds = loadCredentialsFile(), let id = creds["client_id"] {
            return id
        }
        fatalError("Missing Google Client ID. Set RUNWAY_GOOGLE_CLIENT_ID env var or create ~/.config/runway/credentials.json")
    }()

    static let clientSecret: String = {
        if let envValue = ProcessInfo.processInfo.environment["RUNWAY_GOOGLE_CLIENT_SECRET"], !envValue.isEmpty {
            return envValue
        }
        if let creds = loadCredentialsFile(), let secret = creds["client_secret"] {
            return secret
        }
        fatalError("Missing Google Client Secret. Set RUNWAY_GOOGLE_CLIENT_SECRET env var or create ~/.config/runway/credentials.json")
    }()

    static let redirectURI = "http://127.0.0.1:8089/callback"
    static let scope = "https://www.googleapis.com/auth/calendar.readonly"
    static let authURL = "https://accounts.google.com/o/oauth2/v2/auth"
    static let tokenURL = "https://oauth2.googleapis.com/token"
    static let calendarAPIBase = "https://www.googleapis.com/calendar/v3"

    private static func loadCredentialsFile() -> [String: String]? {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let path = home.appendingPathComponent(".config/runway/credentials.json")
        guard let data = try? Data(contentsOf: path),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: String]
        else { return nil }
        return json
    }
}
