import Foundation

/// Google AI Studio → API key. Set `GEMINI_API_KEY` in target Info.plist or build settings.
enum GeminiConfig {
    static let apiKey: String = {
        if let key = Bundle.main.object(forInfoDictionaryKey: "GEMINI_API_KEY") as? String,
           !key.isEmpty,
           !key.contains("REPLACE_WITH") {
            return key
        }
        if let env = ProcessInfo.processInfo.environment["GEMINI_API_KEY"],
           !env.isEmpty {
            return env
        }
        return ""
    }()

    /// Tried in order when the primary model hits quota or availability errors.
    static let models = [
        "gemini-2.0-flash-lite",
        "gemini-1.5-flash",
        "gemini-2.0-flash",
    ]

    static var isConfigured: Bool {
        apiKey.hasPrefix("AIza")
    }

    /// Map point types enriched with Gemini when API data is sparse.
    static let enrichableMapPointTypes: Set<String> = [
        "marina", "fuel", "service", "diving",
        "water", "customs", "emergency", "restaurant", "beach",
    ]
}
