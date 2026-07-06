import Foundation

// MARK: - Usage Model

struct UsageInfo: Codable {
    let used: Int
    let limit: Int
    let remaining: Int
}

// MARK: - SSE Event

private struct SSEEvent: Codable {
    let status: String          // "generating" | "complete" | "error"
    let brief: Brief?
    let usage: UsageInfo?
    let cached: Bool?
    let message: String?
}

// MARK: - API Response (non-streaming fallback)

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
    /// True from the moment the server acknowledges the request until the brief arrives.
    /// Bind to a loading indicator in the UI.
    var isGenerating: Bool = false

    // ── Public API ─────────────────────────────────────────────────────────────

    /// Generate a brief using SSE streaming.
    /// `isGenerating` flips true immediately when the server responds with "generating",
    /// so the UI can show a spinner before the full JSON arrives.
    func generateBrief(for topic: String) async throws -> Brief {
        let url = URL(string: "\(Self.backendBaseURL)/api/generate")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        request.setValue(Self.deviceId, forHTTPHeaderField: "x-device-id")
        request.httpBody = try JSONEncoder().encode(["topic": topic])

        isGenerating = true
        defer { isGenerating = false }

        do {
            let (asyncBytes, response) = try await URLSession.shared.bytes(for: request)
            let http = response as! HTTPURLResponse

            // Rate limit — collect body then decode
            if http.statusCode == 429 {
                var data = Data()
                for try await byte in asyncBytes { data.append(byte) }
                if let payload = try? JSONDecoder().decode(LimitErrorPayload.self, from: data) {
                    throw TechBriefError.freeLimitReached(used: payload.used, limit: payload.limit)
                }
                throw TechBriefError.freeLimitReached(used: 3, limit: 3)
            }

            guard http.statusCode == 200 else {
                var data = Data()
                for try await byte in asyncBytes { data.append(byte) }
                let msg = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw TechBriefError.badResponse("Server error \(http.statusCode): \(msg)")
            }

            // Parse SSE lines
            for try await line in asyncBytes.lines {
                guard line.hasPrefix("data: ") else { continue }
                let jsonStr = String(line.dropFirst(6))
                guard let jsonData = jsonStr.data(using: .utf8),
                      let event = try? JSONDecoder().decode(SSEEvent.self, from: jsonData)
                else { continue }

                switch event.status {
                case "generating":
                    // Server is alive — isGenerating already true, nothing else to do
                    break
                case "complete":
                    guard let brief = event.brief else {
                        throw TechBriefError.badResponse("Missing brief in complete event")
                    }
                    if let u = event.usage { self.usage = u }
                    return brief
                case "error":
                    throw TechBriefError.badResponse(event.message ?? "Generation failed")
                default:
                    break
                }
            }

            throw TechBriefError.badResponse("Stream ended without a complete event")

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
