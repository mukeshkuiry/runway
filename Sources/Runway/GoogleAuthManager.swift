import Foundation
import AppKit
import Network

/// Handles Google OAuth2 authorization flow using loopback redirect
final class GoogleAuthManager {
    static let shared = GoogleAuthManager()

    private var listener: NWListener?
    private var authCompletion: ((Bool) -> Void)?

    var isSignedIn: Bool {
        return KeychainManager.load(key: "google_access_token") != nil
    }

    var accessToken: String? {
        return KeychainManager.load(key: "google_access_token")
    }

    private init() {}

    // MARK: - Start OAuth Flow

    func startSignIn(completion: @escaping (Bool) -> Void) {
        self.authCompletion = completion
        startLocalServer()
        openAuthURL()
    }

    func signOut() {
        KeychainManager.delete(key: "google_access_token")
        KeychainManager.delete(key: "google_refresh_token")
        KeychainManager.delete(key: "google_token_expiry")
    }

    // MARK: - Open browser for Google sign-in

    private func openAuthURL() {
        var components = URLComponents(string: GoogleOAuthConfig.authURL)!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: GoogleOAuthConfig.clientID),
            URLQueryItem(name: "redirect_uri", value: GoogleOAuthConfig.redirectURI),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: GoogleOAuthConfig.scope),
            URLQueryItem(name: "access_type", value: "offline"),
            URLQueryItem(name: "prompt", value: "consent")
        ]

        if let url = components.url {
            NSWorkspace.shared.open(url)
        }
    }

    // MARK: - Local HTTP server to receive callback

    private func startLocalServer() {
        do {
            let params = NWParameters.tcp
            listener = try NWListener(using: params, on: 8089)
        } catch {
            print("Failed to create listener: \(error)")
            authCompletion?(false)
            return
        }

        listener?.newConnectionHandler = { [weak self] connection in
            self?.handleConnection(connection)
        }

        listener?.start(queue: .main)
    }

    private func handleConnection(_ connection: NWConnection) {
        connection.start(queue: .main)

        connection.receive(minimumIncompleteLength: 1, maximumLength: 4096) { [weak self] data, _, _, _ in
            guard let self = self, let data = data, let request = String(data: data, encoding: .utf8) else {
                connection.cancel()
                return
            }

            // Parse the authorization code from the GET request
            if let code = self.extractCode(from: request) {
                // Send success response to browser
                let response = """
                HTTP/1.1 200 OK\r\n\
                Content-Type: text/html\r\n\
                Connection: close\r\n\
                \r\n\
                <html><body style="font-family:-apple-system,sans-serif;display:flex;align-items:center;justify-content:center;height:100vh;margin:0;background:#1a1a2e;color:#fff;">\
                <div style="text-align:center;"><h1>FlightRisk Connected!</h1><p>You can close this tab and return to FlightRisk.</p></div>\
                </body></html>
                """
                let responseData = Data(response.utf8)
                connection.send(content: responseData, completion: .contentProcessed { _ in
                    connection.cancel()
                })

                // Exchange code for tokens
                self.exchangeCodeForTokens(code: code)
            } else {
                let response = "HTTP/1.1 400 Bad Request\r\nConnection: close\r\n\r\nMissing code"
                connection.send(content: Data(response.utf8), completion: .contentProcessed { _ in
                    connection.cancel()
                })
                self.authCompletion?(false)
            }

            self.listener?.cancel()
            self.listener = nil
        }
    }

    private func extractCode(from request: String) -> String? {
        // Parse "GET /callback?code=XXXX&scope=... HTTP/1.1"
        guard let firstLine = request.components(separatedBy: "\r\n").first,
              let urlPart = firstLine.components(separatedBy: " ").dropFirst().first,
              let components = URLComponents(string: urlPart),
              let code = components.queryItems?.first(where: { $0.name == "code" })?.value
        else {
            return nil
        }
        return code
    }

    // MARK: - Token Exchange

    private func exchangeCodeForTokens(code: String) {
        let url = URL(string: GoogleOAuthConfig.tokenURL)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let body = [
            "code=\(code)",
            "client_id=\(GoogleOAuthConfig.clientID)",
            "client_secret=\(GoogleOAuthConfig.clientSecret)",
            "redirect_uri=\(GoogleOAuthConfig.redirectURI)",
            "grant_type=authorization_code"
        ].joined(separator: "&")

        request.httpBody = body.data(using: .utf8)

        URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
            guard let data = data, error == nil else {
                DispatchQueue.main.async { self?.authCompletion?(false) }
                return
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let accessToken = json["access_token"] as? String {
                    KeychainManager.save(key: "google_access_token", value: accessToken)

                    if let refreshToken = json["refresh_token"] as? String {
                        KeychainManager.save(key: "google_refresh_token", value: refreshToken)
                    }

                    if let expiresIn = json["expires_in"] as? Int {
                        let expiry = Date().addingTimeInterval(TimeInterval(expiresIn))
                        KeychainManager.save(key: "google_token_expiry", value: "\(expiry.timeIntervalSince1970)")
                    }

                    DispatchQueue.main.async { self?.authCompletion?(true) }
                } else {
                    DispatchQueue.main.async { self?.authCompletion?(false) }
                }
            } catch {
                DispatchQueue.main.async { self?.authCompletion?(false) }
            }
        }.resume()
    }

    // MARK: - Token Refresh

    func refreshTokenIfNeeded(completion: @escaping (Bool) -> Void) {
        // Check if token is expired
        if let expiryStr = KeychainManager.load(key: "google_token_expiry"),
           let expiryTs = Double(expiryStr) {
            let expiry = Date(timeIntervalSince1970: expiryTs)
            if expiry > Date().addingTimeInterval(60) {
                // Token still valid
                completion(true)
                return
            }
        }

        // Refresh the token
        guard let refreshToken = KeychainManager.load(key: "google_refresh_token") else {
            completion(false)
            return
        }

        let url = URL(string: GoogleOAuthConfig.tokenURL)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let body = [
            "refresh_token=\(refreshToken)",
            "client_id=\(GoogleOAuthConfig.clientID)",
            "client_secret=\(GoogleOAuthConfig.clientSecret)",
            "grant_type=refresh_token"
        ].joined(separator: "&")

        request.httpBody = body.data(using: .utf8)

        URLSession.shared.dataTask(with: request) { data, _, error in
            guard let data = data, error == nil else {
                completion(false)
                return
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let accessToken = json["access_token"] as? String {
                    KeychainManager.save(key: "google_access_token", value: accessToken)

                    if let expiresIn = json["expires_in"] as? Int {
                        let expiry = Date().addingTimeInterval(TimeInterval(expiresIn))
                        KeychainManager.save(key: "google_token_expiry", value: "\(expiry.timeIntervalSince1970)")
                    }
                    completion(true)
                } else {
                    completion(false)
                }
            } catch {
                completion(false)
            }
        }.resume()
    }
}
