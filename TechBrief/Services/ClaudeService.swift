import Foundation

// MARK: - Usage Model

struct UsageInfo: Codable {
    let used: Int
    let limit: Int
    let remaining: Int
}

// MARK: - API Response

private struct GenerateResponse: Codable {
    let brief: Brief
    let usage: UsageInfo
}

private struct LimitErrorPayload: Codable {
    let used: Int
    let limit: Int
}

// MARK: - Errors

enum TechBriefError: LocalizedError {
    case freeLimitReached(used: Int, limit: Int)
    case badResponse(String)
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .freeLimitReached:
            return "You've used all your free briefs for today."
        case .badResponse(let msg):
            return msg
        case .networkError(let err):
            return err.localizedDescription
        }
    }
}

// MARK: - Service

@Observable
class ClaudeService {

    // ── Config ─────────────────────────────────────────────────────────────────
    // Swap this for your Railway URL once deployed.
    // Local testing: "http://localhost:3001"
    static let backendBaseURL = "https://techbrief-backend.vercel.app"

    // A stable anonymous device ID stored in UserDefaults
    static var deviceId: String {
        let key = "techbrief_device_id"
        if let existing = UserDefaults.standard.string(forKey: key) { return existing }
        let new = UUID().uuidString
        UserDefaults.standard.set(new, forKey: key)
        return new
    }

    // ── State ──────────────────────────────────────────────────────────────────
    var usage: UsageInfo?

    // ── Public API ─────────────────────────────────────────────────────────────

    /// Generate a brief. Throws `TechBriefError.freeLimitReached` when quota exhausted.
    func generateBrief(for topic: String) async throws -> Brief {
        let url = URL(string: "\(Self.backendBaseURL)/api/generate")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(Self.deviceId, forHTTPHeaderField: "x-device-id")
        request.httpBody = try JSONEncoder().encode(["topic": topic])

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            let http = response as! HTTPURLResponse

            if http.statusCode == 429 {
                if let payload = try? JSONDecoder().decode(LimitErrorPayload.self, from: data) {
                    throw TechBriefError.freeLimitReached(used: payload.used, limit: payload.limit)
                }
                throw TechBriefError.freeLimitReached(used: 3, limit: 3)
            }

            guard http.statusCode == 200 else {
                let msg = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw TechBriefError.badResponse("Server error \(http.statusCode): \(msg)")
            }

            let decoded = try JSONDecoder().decode(GenerateResponse.self, from: data)
            self.usage = decoded.usage
            return decoded.brief

        } catch let err as TechBriefError {
            throw err
        } catch {
            throw TechBriefError.networkError(error)
        }
    }

    /// Refresh usage counter — call on app launch and SearchView appear.
    func fetchUsage() async {
        guard let url = URL(string: "\(Self.backendBaseURL)/api/usage") else { return }
        var request = URLRequest(url: url)
        request.setValue(Self.deviceId, forHTTPHeaderField: "x-device-id")
        if let (data, _) = try? await URLSession.shared.data(for: request),
           let decoded = try? JSONDecoder().decode(UsageInfo.self, from: data) {
            self.usage = decoded
        }
    }
}
