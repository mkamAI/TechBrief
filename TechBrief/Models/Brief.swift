import Foundation

// MARK: - Core Models

struct Brief: Codable, Identifiable, Hashable {
    var id: String { topic }
    let topic: String
    let tagline: String
    let whatIsIt: String
    let whyItMatters: String
    let concepts: [Concept]
    let useWhen: [String]
    let avoidWhen: [String]
    let codeComment: String
    let codeLines: [String]
    let youtubeLinks: [YouTubeLink]
    let learnNext: [NextTopic]

    enum CodingKeys: String, CodingKey {
        case topic, tagline
        case whatIsIt     = "what_is_it"
        case whyItMatters = "why_it_matters"
        case concepts
        case useWhen      = "use_when"
        case avoidWhen    = "avoid_when"
        case codeComment  = "code_comment"
        case codeLines    = "code_lines"
        case youtubeLinks = "youtube_links"
        case learnNext    = "learn_next"
    }
}

struct Concept: Codable, Identifiable, Hashable {
    var id: String { term }
    let term: String
    let definition: String
}

struct YouTubeLink: Codable, Identifiable, Hashable {
    var id: String { url }
    let title: String
    let channel: String
    let duration: String
    let url: String

    var resolvedURL: URL? {
        let cleaned = url.hasPrefix("http") ? url : "https://\(url)"
        return URL(string: cleaned)
    }
}

struct NextTopic: Codable, Identifiable, Hashable {
    var id: String { topic }
    let topic: String
    let description: String
}
