import Foundation

enum MapPointFactsResolver {
    private static let nominatimDetailsURL = "https://nominatim.openstreetmap.org/details"

    static func basic(mapPoint: MapPoint, comments: [Comment]) -> MapPointDisplayFacts {
        var facts = MapPointDisplayFacts(
            entranceDepth: formatDepth(mapPoint.depthM) ?? communityAverageDepth(from: comments),
            berthCapacity: formatBerths(mapPoint.berthCount),
            vhfChannel: formatVHF(mapPoint.vhfChannel),
            openingHours: nonEmpty(mapPoint.openingHours),
            fuelTypes: nonEmpty(mapPoint.fuelTypes)
        )
        applyContactFallbacks(&facts, mapPoint: mapPoint)
        return facts
    }

    static func resolve(
        mapPoint: MapPoint,
        comments: [Comment],
        linkedAnchorage: Anchorage?
    ) async -> MapPointDisplayFacts {
        var facts: MapPointDisplayFacts

        if mapPoint.type == "marina" {
            facts = await resolveMarina(mapPoint: mapPoint, comments: comments, linkedAnchorage: linkedAnchorage)
        } else {
            facts = basic(mapPoint: mapPoint, comments: comments)
            if GeminiConfig.enrichableMapPointTypes.contains(mapPoint.type),
               mapPoint.type != "fuel" {
                if let osm = await fetchOSMDetails(latitude: mapPoint.latitude, longitude: mapPoint.longitude) {
                    facts.entranceDepth = facts.entranceDepth ?? osm.depth
                    facts.berthCapacity = facts.berthCapacity ?? osm.berths
                    facts.vhfChannel = facts.vhfChannel ?? osm.vhf
                    facts.openingHours = facts.openingHours ?? osm.hours
                }
                applyContactFallbacks(&facts, mapPoint: mapPoint)
            }
        }

        if GeminiConfig.enrichableMapPointTypes.contains(mapPoint.type),
           let gemini = await GeminiMapPointEnrichmentService.shared.enrich(mapPoint: mapPoint) {
            facts = merge(base: facts, gemini: gemini)
        }

        return facts
    }

    private static func resolveMarina(
        mapPoint: MapPoint,
        comments: [Comment],
        linkedAnchorage: Anchorage?
    ) async -> MapPointDisplayFacts {
        var facts = MapPointDisplayFacts(
            entranceDepth: formatDepth(mapPoint.depthM),
            berthCapacity: formatBerths(mapPoint.berthCount),
            vhfChannel: formatVHF(mapPoint.vhfChannel),
            openingHours: nonEmpty(mapPoint.openingHours),
            fuelTypes: nonEmpty(mapPoint.fuelTypes)
        )

        if let avg = communityAverageDepth(from: comments) {
            facts.entranceDepth = facts.entranceDepth ?? avg
        }

        if facts.entranceDepth == nil, let depth = linkedAnchorage?.depth {
            facts.entranceDepth = String(format: "%.1f m (nearby anchorage)", depth)
        }

        if let osm = await fetchOSMDetails(latitude: mapPoint.latitude, longitude: mapPoint.longitude) {
            facts.entranceDepth = facts.entranceDepth ?? osm.depth
            facts.berthCapacity = facts.berthCapacity ?? osm.berths
            facts.vhfChannel = facts.vhfChannel ?? osm.vhf
            facts.openingHours = facts.openingHours ?? osm.hours
        }

        applyContactFallbacks(&facts, mapPoint: mapPoint)
        facts.berthCapacity = facts.berthCapacity ?? mooringFallback(description: mapPoint.description)
        return facts
    }

    static func merge(base: MapPointDisplayFacts, gemini: MapPointDisplayFacts) -> MapPointDisplayFacts {
        var merged = base
        merged.entranceDepth = merged.entranceDepth ?? gemini.entranceDepth
        merged.berthCapacity = merged.berthCapacity ?? gemini.berthCapacity
        merged.vhfChannel = merged.vhfChannel ?? gemini.vhfChannel
        merged.openingHours = merged.openingHours ?? gemini.openingHours
        merged.fuelTypes = merged.fuelTypes ?? gemini.fuelTypes
        merged.amenities = merged.amenities ?? gemini.amenities
        merged.summary = merged.summary ?? gemini.summary
        return merged
    }

    private static func applyContactFallbacks(_ facts: inout MapPointDisplayFacts, mapPoint: MapPoint) {
        if mapPoint.type == "fuel" {
            facts.openingHours = facts.openingHours ?? fuelHoursFallback(website: mapPoint.website)
            if facts.fuelTypes == nil, mapPoint.website != nil {
                facts.fuelTypes = "See station website"
            }
        } else {
            facts.openingHours = facts.openingHours ?? marinaHoursFallback(website: mapPoint.website)
        }
        facts.vhfChannel = facts.vhfChannel ?? contactVHFFallback(phone: mapPoint.phone, website: mapPoint.website)
        facts.berthCapacity = facts.berthCapacity ?? contactBerthFallback(phone: mapPoint.phone, website: mapPoint.website)
        facts.entranceDepth = facts.entranceDepth ?? contactDepthFallback(phone: mapPoint.phone, website: mapPoint.website)
    }

    // MARK: - Formatting

    private static func formatDepth(_ value: Double?) -> String? {
        guard let value else { return nil }
        return String(format: "%.1f m", value)
    }

    private static func formatBerths(_ value: Int?) -> String? {
        guard let value, value > 0 else { return nil }
        return "\(value) \(value == 1 ? "berth" : "berths")"
    }

    private static func formatVHF(_ value: String?) -> String? {
        guard let raw = nonEmpty(value) else { return nil }
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        let lower = trimmed.lowercased()
        if lower.hasPrefix("vhf") || lower.hasPrefix("ch") { return trimmed }
        return "CH \(trimmed)"
    }

    private static func communityAverageDepth(from comments: [Comment]) -> String? {
        let depths = comments.compactMap(\.depthObserved)
        guard !depths.isEmpty else { return nil }
        let avg = depths.reduce(0, +) / Double(depths.count)
        return String(format: "%.1f m (community)", avg)
    }

    private static func mooringFallback(description: String?) -> String? {
        guard let description else { return nil }
        let lower = description.lowercased()
        if let match = lower.range(of: #"(\d+)\s*(berth|berths|slip|slips)"#, options: .regularExpression) {
            return String(description[match]).capitalized
        }
        return nil
    }

    private static func marinaHoursFallback(website: String?) -> String? {
        guard nonEmpty(website) != nil else { return nil }
        return "See marina website"
    }

    private static func fuelHoursFallback(website: String?) -> String? {
        guard nonEmpty(website) != nil else { return nil }
        return "See station website"
    }

    private static func contactVHFFallback(phone: String?, website: String?) -> String? {
        if nonEmpty(phone) != nil { return "Call marina for VHF" }
        if nonEmpty(website) != nil { return "Listed on marina website" }
        return nil
    }

    private static func contactBerthFallback(phone: String?, website: String?) -> String? {
        if nonEmpty(website) != nil { return "See marina website" }
        if nonEmpty(phone) != nil { return "Call marina for capacity" }
        return nil
    }

    private static func contactDepthFallback(phone: String?, website: String?) -> String? {
        if nonEmpty(phone) != nil { return "Call marina for depth" }
        if nonEmpty(website) != nil { return "See marina website" }
        return nil
    }

    // MARK: - OpenStreetMap

    private struct OSMFactSlice {
        var depth: String?
        var berths: String?
        var vhf: String?
        var hours: String?

        var hasAnyValue: Bool {
            depth != nil || berths != nil || vhf != nil || hours != nil
        }
    }

    private static func fetchOSMDetails(latitude: Double, longitude: Double) async -> OSMFactSlice? {
        guard let reverseURL = URL(string: "https://nominatim.openstreetmap.org/reverse?lat=\(latitude)&lon=\(longitude)&format=json&extratags=1") else {
            return nil
        }

        var request = URLRequest(url: reverseURL)
        request.setValue("PruvaApp/1.0 (marina-details)", forHTTPHeaderField: "User-Agent")

        guard let reverse = try? await decodeJSON(NominatimReverse.self, request: request) else {
            return nil
        }

        var slice = parseExtratags(reverse.extratags)

        guard let osmType = reverse.osmType,
              let osmId = reverse.osmId,
              let detailsURL = URL(string: "\(nominatimDetailsURL)?osmtype=\(osmTypeLetter(osmType))&osmid=\(osmId)&format=json&extratags=1") else {
            return slice.hasAnyValue ? slice : nil
        }

        var detailsRequest = URLRequest(url: detailsURL)
        detailsRequest.setValue("PruvaApp/1.0 (marina-details)", forHTTPHeaderField: "User-Agent")

        if let details = try? await decodeJSON(NominatimDetails.self, request: detailsRequest) {
            let merged = parseExtratags(details.extratags)
            slice.depth = slice.depth ?? merged.depth
            slice.berths = slice.berths ?? merged.berths
            slice.vhf = slice.vhf ?? merged.vhf
            slice.hours = slice.hours ?? merged.hours
        }

        return slice.hasAnyValue ? slice : nil
    }

    private static func osmTypeLetter(_ type: String) -> String {
        switch type.lowercased() {
        case "node": return "N"
        case "way": return "W"
        case "relation": return "R"
        default: return "N"
        }
    }

    private static func parseExtratags(_ tags: [String: String]?) -> OSMFactSlice {
        guard let tags else { return OSMFactSlice() }

        let depthValue = tags["depth"] ?? tags["seamark:depth"] ?? tags["maxdepth"] ?? tags["seamark:harbour:depth"]
        let berthValue = tags["capacity"] ?? tags["berth"] ?? tags["berths"] ?? tags["mooring"] ?? tags["seamark:berth:count"]
        let vhfValue = tags["seamark:radio_channel"] ?? tags["communication:radio"] ?? tags["vhf"] ?? tags["radio"]
        let hoursValue = tags["opening_hours"] ?? tags["service_times"]

        return OSMFactSlice(
            depth: depthValue.map { $0.contains("m") ? $0 : "\($0) m" },
            berths: berthValue.flatMap { formatBerths(Int($0)) ?? "\($0) berths" },
            vhf: vhfValue.map { formatVHF($0) ?? "CH \($0)" },
            hours: nonEmpty(hoursValue)
        )
    }

    private static func nonEmpty(_ value: String?) -> String? {
        guard let value else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private static func decodeJSON<T: Decodable>(_ type: T.Type, request: URLRequest) async throws -> T {
        let (data, response) = try await URLSession.shared.data(for: request)
        if let http = response as? HTTPURLResponse, http.statusCode >= 400 {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode(T.self, from: data)
    }
}

private struct NominatimReverse: Decodable {
    let osmType: String?
    let osmId: Int?
    let extratags: [String: String]?

    enum CodingKeys: String, CodingKey {
        case osmType = "osm_type"
        case osmId = "osm_id"
        case extratags
    }
}

private struct NominatimDetails: Decodable {
    let extratags: [String: String]?
}
