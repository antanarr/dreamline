import Foundation

// MARK: - Public API

/// Actor to keep network state isolated and parsing safe.
actor CopyEngine {
    static let shared = CopyEngine()

    private let backend: CopyBackend = ModelCopyBackend() // switch to template fallback if no key
    private let fallback = LocalTemplateBackend()

    // MARK: Quick Read lead (two lines)
    func quickReadLines(overlap: [String], score: Float, locale: Locale = .current) async -> (h1: String, sub: String) {
        let lang = languageTag(locale)
        if let out = await backend.quickReadLead(overlap: overlap, score: score, lang: lang) {
            return (out.h1, out.sub)
        }
        // fallback (offline or no key)
        return fallback.quickReadLines(overlap: overlap, score: score)
    }

    // MARK: Alignment Explainer (lead/body/chips)
    func alignmentExplainer(overlap: [String], headline: String, summary: String, score: Float, locale: Locale = .current) async -> (lead: String, body: String, chips: [String]) {
        let lang = languageTag(locale)
        if let out = await backend.alignmentExplainer(overlap: overlap, headline: headline, summary: summary, score: score, lang: lang) {
            return (out.lead, out.body, out.chips)
        }
        return fallback.alignmentExplainer(overlap: overlap, headline: headline, summary: summary, score: score)
    }

    // MARK: Alignment Ahead teaser
    func alignmentAheadTeaser(weekday: String, locale: Locale = .current) async -> (title: String, subtitle: String, cta: String) {
        let lang = languageTag(locale)
        if let out = await backend.alignmentAheadTeaser(weekday: weekday, lang: lang) {
            return (out.title, out.subtitle, out.cta)
        }
        return ("Alignment Ahead", "When the sky is likely to echo your current thread.", "See Alignment Ahead")
    }
    
    // MARK: Alignment Deep Dive
    func alignmentDeepDive(overlap: [String], headline: String, summary: String, profile: OracleUserProfile?, locale: Locale = .current) async -> String {
        let lang = languageTag(locale)
        if let out = await backend.alignmentDeepDive(overlap: overlap, headline: headline, summary: summary, profile: profile, lang: lang) {
            return out.body
        }
        return fallback.alignmentDeepDive(overlap: overlap, headline: headline, summary: summary)
    }

    // LANGUAGE helper (BCP‑47-ish)
    private func languageTag(_ locale: Locale) -> String {
        if let code = locale.language.languageCode?.identifier {
            return code // e.g., "en"
        }
        return "en"
    }
}

// MARK: - Models

private struct QuickReadLeadOut: Decodable {
    let h1: String
    let sub: String
}
private struct AlignmentExplainerOut: Decodable {
    let lead: String
    let body: String
    let chips: [String]
}
private struct AlignmentAheadTeaserOut: Decodable {
    let title: String
    let subtitle: String
    let cta: String
}
private struct AlignmentDeepDiveOut: Decodable {
    let body: String
}
private struct AllAboutYouReportOut: Decodable {
    let title: String
    let sections: [Section]
    struct Section: Decodable {
        let heading: String
        let body: String
    }
}

public struct OracleUserProfile: Codable {
    public var name: String?
    public var sun: String
    public var moon: String?
    public var rising: String?
    public var age: Int?
    public var pronouns: String?
    
    public init(name: String? = nil, sun: String, moon: String? = nil, rising: String? = nil, age: Int? = nil, pronouns: String? = nil) {
        self.name = name
        self.sun = sun
        self.moon = moon
        self.rising = rising
        self.age = age
        self.pronouns = pronouns
    }
}

// MARK: - Backend Protocol

private protocol CopyBackend {
    func quickReadLead(overlap: [String], score: Float, lang: String) async -> QuickReadLeadOut?
    func alignmentExplainer(overlap: [String], headline: String, summary: String, score: Float, lang: String) async -> AlignmentExplainerOut?
    func alignmentAheadTeaser(weekday: String, lang: String) async -> AlignmentAheadTeaserOut?
    func alignmentDeepDive(overlap: [String], headline: String, summary: String, profile: OracleUserProfile?, lang: String) async -> AlignmentDeepDiveOut?
}

// MARK: - OpenAI Responses Backend

/// Cost‑effective default model: gpt-4o-mini (JSON response_format).
/// Reads API key from Info.plist key `OPENAI_API_KEY` or environment.
private final class ModelCopyBackend: CopyBackend {
    private let model: String
    private let apiKey: String?
    private let session: URLSession

    init(model: String = "gpt-4o-mini", apiKey: String? = ModelCopyBackend.resolveKey(), session: URLSession = .shared) {
        self.model = model
        self.apiKey = apiKey
        self.session = session
    }

    static func resolveKey() -> String? {
        if let key = Bundle.main.object(forInfoDictionaryKey: "OPENAI_API_KEY") as? String, !key.isEmpty { return key }
        return ProcessInfo.processInfo.environment["OPENAI_API_KEY"]
    }

    func quickReadLead(overlap: [String], score: Float, lang: String) async -> QuickReadLeadOut? {
        let input: [String: Any] = ["overlap": overlap, "score": score, "lang": lang]
        return await call(prompt: PromptBook.quickReadLead, input: input, as: QuickReadLeadOut.self)
    }

    func alignmentExplainer(overlap: [String], headline: String, summary: String, score: Float, lang: String) async -> AlignmentExplainerOut? {
        let input: [String: Any] = ["overlap": overlap, "headline": headline, "summary": summary, "score": score, "lang": lang]
        return await call(prompt: PromptBook.alignmentExplainer, input: input, as: AlignmentExplainerOut.self)
    }

    func alignmentAheadTeaser(weekday: String, lang: String) async -> AlignmentAheadTeaserOut? {
        let input: [String: Any] = ["weekday": weekday, "lang": lang]
        return await call(prompt: PromptBook.alignmentAheadTeaser, input: input, as: AlignmentAheadTeaserOut.self)
    }
    
    func alignmentDeepDive(overlap: [String], headline: String, summary: String, profile: OracleUserProfile?, lang: String) async -> AlignmentDeepDiveOut? {
        let profileData = try? JSONEncoder().encode(profile ?? OracleUserProfile(sun: "unknown"))
        let profileJSON = profileData.flatMap { try? JSONSerialization.jsonObject(with: $0) } ?? [:]
        let input: [String: Any] = ["overlap": overlap, "headline": headline, "summary": summary, "profile": profileJSON, "lang": lang]
        return await call(prompt: PromptBook.alignmentDeepDive, input: input, as: AlignmentDeepDiveOut.self)
    }

    // Core call to OpenAI Responses API
    private func call<T: Decodable>(prompt: String, input: [String: Any], as: T.Type) async -> T? {
        guard let apiKey else { return nil }
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Serialize the user content with the JSON input
        let inputJSON = (try? JSONSerialization.data(withJSONObject: input, options: [.sortedKeys])) ?? Data("{}".utf8)
        let inputString = String(data: inputJSON, encoding: .utf8) ?? "{}"
        let userContent = """
        SYSTEM:
        \(PromptBook.system)

        TASK PROMPT:
        \(prompt)

        INPUT:
        \(inputString)
        """

        let body: [String: Any] = [
            "model": model,
            "response_format": ["type": "json_object"],
            "messages": [
                ["role": "user", "content": userContent]
            ]
        ]

        req.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])

        do {
            let (data, resp) = try await session.data(for: req)
            guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else { return nil }

            // Chat Completions API returns choices[0].message.content
            if let parsed = try? JSONDecoder().decode(ChatCompletionResponse.self, from: data),
               let text = parsed.choices.first?.message.content?.trimmingCharacters(in: .whitespacesAndNewlines),
               let decoded = Self.decodeJSON(text, as: T.self) {
                return decoded
            }
            return nil
        } catch {
            return nil
        }
    }

    private struct ChatCompletionResponse: Decodable {
        let choices: [Choice]
        struct Choice: Decodable {
            let message: Message
        }
        struct Message: Decodable {
            let content: String?
        }
    }

    private static func decodeJSON<T: Decodable>(_ text: String, as: T.Type) -> T? {
        // Be tolerant: strip code fences if any slipped through
        let cleaned = text
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return try? JSONDecoder().decode(T.self, from: Data(cleaned.utf8))
    }
}

// MARK: - Local fallback (offline-safe)

private final class LocalTemplateBackend: CopyBackend {
    func quickReadLead(overlap: [String], score: Float, lang: String) async -> QuickReadLeadOut? {
        let result = quickReadLines(overlap: overlap, score: score)
        return QuickReadLeadOut(h1: result.h1, sub: result.sub)
    }
    
    func alignmentExplainer(overlap: [String], headline: String, summary: String, score: Float, lang: String) async -> AlignmentExplainerOut? {
        let result = alignmentExplainer(overlap: overlap, headline: headline, summary: summary, score: score)
        return AlignmentExplainerOut(lead: result.lead, body: result.body, chips: result.chips)
    }
    
    func alignmentAheadTeaser(weekday: String, lang: String) async -> AlignmentAheadTeaserOut? {
        return AlignmentAheadTeaserOut(
            title: "Alignment Ahead",
            subtitle: "When the sky is likely to echo your current thread.",
            cta: "See Alignment Ahead"
        )
    }
    
    func alignmentDeepDive(overlap: [String], headline: String, summary: String, profile: OracleUserProfile?, lang: String) async -> AlignmentDeepDiveOut? {
        let result = alignmentDeepDive(overlap: overlap, headline: headline, summary: summary)
        return AlignmentDeepDiveOut(body: result)
    }
    
    func quickReadLines(overlap: [String], score: Float) -> (h1: String, sub: String) {
        let motif = overlap.first?.replacingOccurrences(of: "_", with: " ")
        let h1: String
        if let m = motif {
            h1 = "You're circling \(m)"
        } else if score >= 0.84 {
            h1 = "A clear echo"
        } else if score >= 0.79 {
            h1 = "A soft echo"
        } else {
            h1 = "A faint echo"
        }
        let sub = "Let the pattern name itself."
        return (h1, sub)
    }

    func alignmentExplainer(overlap: [String], headline: String, summary: String, score: Float) -> (lead: String, body: String, chips: [String]) {
        let motif = overlap.first?.replacingOccurrences(of: "_", with: " ")
        let lead = motif != nil ? "Today's sky rhymes with \(motif!)." :
                                  "Today's sky rhymes with what you're already dreaming."
        let body = "Recognition rarely arrives with trumpets. Notice the repeat and move gently toward it."
        let chips = Array(overlap.prefix(2)).map { $0.replacingOccurrences(of: "_", with: " ") }
        return (lead, body, chips)
    }
    
    func alignmentDeepDive(overlap: [String], headline: String, summary: String) -> String {
        let motif = overlap.first?.replacingOccurrences(of: "_", with: " ") ?? "what you're already circling"
        return "Themes repeat until they root. Your recent dreams keep brushing \(motif). Today's sky mirrors the same contour. Treat the echo as permission, not pressure. Follow the small nudge that keeps returning. What opens if you take one careful step toward it?"
    }
}

