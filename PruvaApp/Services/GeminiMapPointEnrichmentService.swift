import Foundation

/// Fills marina and fuel-station detail fields using Gemini when the Pruva API has gaps.
actor GeminiMapPointEnrichmentService {
    static let shared = GeminiMapPointEnrichmentService()

    private let cacheTTL: TimeInterval = 7 * 24 * 60 * 60
    private var memoryCache: [String: CachedEntry] = [:]

    private struct CachedEntry {
        let facts: MapPointDisplayFacts
        let savedAt: Date
    }

    private struct GeminiResponse: Decodable {
        struct Candidate: Decodable {
            struct Content: Decodable {
                struct Part: Decodable {
                    let text: String?
                }
                let parts: [Part]?
            }
            let content: Content?
        }
        let candidates: [Candidate]?
    }

    private struct GeminiFactsPayload: Decodable {
        let entranceDepth: String?
        let berthCapacity: String?
        let vhfChannel: String?
        let openingHours: String?
        let fuelTypes: String?
        let amenities: String?
        let summary: String?

        enum CodingKeys: String, CodingKey {
            case entranceDepth = "entrance_depth"
            case berthCapacity = "berth_capacity"
            case vhfChannel = "vhf_channel"
            case openingHours = "opening_hours"
            case fuelTypes = "fuel_types"
            case amenities
            case summary
        }

        func asDisplayFacts() -> MapPointDisplayFacts {
            MapPointDisplayFacts(
                entranceDepth: Self.clean(entranceDepth),
                berthCapacity: Self.clean(berthCapacity),
                vhfChannel: Self.clean(vhfChannel),
                openingHours: Self.clean(openingHours),
                fuelTypes: Self.clean(fuelTypes),
                amenities: Self.clean(amenities),
                summary: Self.clean(summary)
            )
        }

        private static func clean(_ value: String?) -> String? {
            guard let value else { return nil }
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty || trimmed.lowercased() == "null" || trimmed.lowercased() == "unknown" {
                return nil
            }
            return trimmed
        }
    }

    func enrich(mapPoint: MapPoint) async -> MapPointDisplayFacts? {
        guard GeminiConfig.isConfigured else { return nil }
        guard GeminiConfig.enrichableMapPointTypes.contains(mapPoint.type) else { return nil }

        if let cached = cachedFacts(for: mapPoint.id) {
            return cached
        }

        guard let facts = await fetchFromGemini(mapPoint: mapPoint) else { return nil }
        storeCache(facts, mapPointId: mapPoint.id)
        return facts
    }

    // MARK: - Cache

    private func cachedFacts(for mapPointId: String) -> MapPointDisplayFacts? {
        if let entry = memoryCache[mapPointId], Date().timeIntervalSince(entry.savedAt) < cacheTTL {
            return entry.facts
        }
        guard let url = cacheFileURL(mapPointId: mapPointId),
              let data = try? Data(contentsOf: url),
              let wrapper = try? JSONDecoder().decode(DiskCache.self, from: data),
              Date().timeIntervalSince(wrapper.savedAt) < cacheTTL else {
            return nil
        }
        memoryCache[mapPointId] = CachedEntry(facts: wrapper.facts, savedAt: wrapper.savedAt)
        return wrapper.facts
    }

    private func storeCache(_ facts: MapPointDisplayFacts, mapPointId: String) {
        let entry = CachedEntry(facts: facts, savedAt: Date())
        memoryCache[mapPointId] = entry
        guard let url = cacheFileURL(mapPointId: mapPointId),
              let data = try? JSONEncoder().encode(DiskCache(facts: facts, savedAt: entry.savedAt)) else { return }
        try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? data.write(to: url, options: .atomic)
    }

    private func cacheFileURL(mapPointId: String) -> URL? {
        guard let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return nil
        }
        let safeId = mapPointId.replacingOccurrences(of: "/", with: "_")
        return base.appendingPathComponent("gemini-map-cache", isDirectory: true)
            .appendingPathComponent("\(safeId).json")
    }

    private struct DiskCache: Codable {
        let facts: MapPointDisplayFacts
        let savedAt: Date
    }

    // MARK: - API

    private func fetchFromGemini(mapPoint: MapPoint) async -> MapPointDisplayFacts? {
        let body: [String: Any] = [
            "contents": [
                [
                    "role": "user",
                    "parts": [["text": buildPrompt(mapPoint: mapPoint)]],
                ],
            ],
            "generationConfig": [
                "temperature": 0.2,
                "responseMimeType": "application/json",
            ],
        ]
        guard let httpBody = try? JSONSerialization.data(withJSONObject: body) else { return nil }

        for model in GeminiConfig.models {
            guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent?key=\(GeminiConfig.apiKey)") else {
                continue
            }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.timeoutInterval = 45
            request.httpBody = httpBody

            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                if let http = response as? HTTPURLResponse, http.statusCode >= 400 {
                    #if DEBUG
                    let raw = String(data: data, encoding: .utf8) ?? ""
                    print("Gemini \(model) error \(http.statusCode):", raw.prefix(200))
                    #endif
                    continue
                }
                if let facts = parseResponse(data) {
                    return facts
                }
            } catch {
                #if DEBUG
                print("Gemini \(model) failed:", error.localizedDescription)
                #endif
            }
        }
        return nil
    }

    private func buildPrompt(mapPoint: MapPoint) -> String {
        let kind = Self.placeKind(for: mapPoint.type)
        var lines = [
            "You are a nautical data assistant for the Pruva sailing app.",
            "Return ONLY valid JSON (no markdown) for this \(kind).",
            "Use concise English. Use null for unknown fields — do not guess wildly.",
            "Prefer facts from the business name, coordinates, phone, and website when plausible.",
            "",
            "Place:",
            "- name: \(mapPoint.name)",
            "- type: \(mapPoint.type)",
            "- latitude: \(mapPoint.latitude)",
            "- longitude: \(mapPoint.longitude)",
        ]
        if let phone = mapPoint.phone { lines.append("- phone: \(phone)") }
        if let website = mapPoint.website { lines.append("- website: \(website)") }
        if let desc = mapPoint.description { lines.append("- description: \(desc)") }
        if let depth = mapPoint.depthM { lines.append("- known_depth_m: \(depth)") }
        if let berths = mapPoint.berthCount { lines.append("- known_berth_count: \(berths)") }
        if let vhf = mapPoint.vhfChannel { lines.append("- known_vhf: \(vhf)") }
        if let hours = mapPoint.openingHours { lines.append("- known_opening_hours: \(hours)") }

        lines.append("")
        lines.append(Self.jsonSchemaInstructions(for: mapPoint.type))
        return lines.joined(separator: "\n")
    }

    private static func placeKind(for type: String) -> String {
        switch type {
        case "marina": return "marina"
        case "fuel": return "marine fuel station"
        case "service": return "marine service yard, shipyard, or chandlery"
        case "diving": return "dive site or dive center"
        case "water": return "potable water station for boats"
        case "customs": return "port customs or immigration office"
        case "emergency": return "maritime emergency or rescue facility"
        case "restaurant": return "waterfront restaurant for boaters"
        case "beach": return "beach or landing spot relevant to sailors"
        default: return "nautical map point (\(type))"
        }
    }

    private static func jsonSchemaInstructions(for type: String) -> String {
        let keys = """
        JSON keys (all strings or null):
        entrance_depth, berth_capacity, vhf_channel,
        opening_hours, fuel_types, amenities, summary
        """
        switch type {
        case "fuel":
            return keys + """

            Focus on fuel_types, opening_hours, amenities (pump-out, water, electricity).
            Leave berth_capacity null unless clearly a marina fuel dock.
            summary: one sentence for boaters about this fuel station.
            """
        case "service":
            return keys + """

            Focus on amenities (haul-out, repairs, chandlery, crane, travel lift),
            opening_hours, vhf_channel if they monitor radio.
            entrance_depth / berth_capacity usually null unless a full marina yard.
            summary: what services sailors can expect here.
            """
        case "diving":
            return keys + """

            Focus on entrance_depth (typical dive depth), amenities (equipment rental, courses, boat pickup),
            opening_hours. berth_capacity and fuel_types usually null.
            summary: one sentence for divers and visiting sailors.
            """
        case "marina":
            return keys + """

            Focus on entrance_depth, berth_capacity, vhf_channel, opening_hours,
            fuel_types at marina, amenities (wifi, laundry, restaurant).
            summary: one sentence for sailors.
            """
        default:
            return keys + """

            Fill only fields that apply to this place type; leave others null.
            summary: one practical sentence for sailors visiting this location.
            """
        }
    }

    private func parseResponse(_ data: Data) -> MapPointDisplayFacts? {
        guard let gemini = try? JSONDecoder().decode(GeminiResponse.self, from: data),
              let text = gemini.candidates?.first?.content?.parts?.first?.text,
              let jsonData = text.data(using: .utf8),
              let payload = try? JSONDecoder().decode(GeminiFactsPayload.self, from: jsonData) else {
            return nil
        }
        let facts = payload.asDisplayFacts()
        return facts.hasAnyDetail ? facts : nil
    }
}
