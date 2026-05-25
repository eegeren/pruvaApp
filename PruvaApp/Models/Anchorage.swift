import Foundation

struct Anchorage: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let latitude: Double
    let longitude: Double
    let depth: Double?
    let bottomType: String?
    let rating: Double
    let ratingCount: Int
    let description: String?
    let currentVisitors: Int?

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: FlexibleKey.self)

        id = try Self.decodeRequiredString(container, keys: ["id"])
        name = try Self.decodeRequiredString(container, keys: ["name"])
        latitude = Self.decodeDouble(container, keys: ["latitude", "lat"]) ?? 0
        longitude = Self.decodeDouble(container, keys: ["longitude", "lon", "lng"]) ?? 0
        depth = Self.decodeDouble(container, keys: ["depth", "depth_m", "average_depth", "avg_depth"])
        bottomType = Self.decodeString(container, keys: ["bottom_type", "bottomType"])
        rating = Self.decodeDouble(container, keys: ["rating"]) ?? 0
        ratingCount = Self.decodeInt(container, keys: ["rating_count"]) ?? 0
        description = Self.decodeString(container, keys: ["description"])
        currentVisitors = Self.decodeInt(container, keys: ["current_visitors"])
    }

    private static func decodeRequiredString(_ container: KeyedDecodingContainer<FlexibleKey>, keys: [String]) throws -> String {
        if let value = decodeString(container, keys: keys) { return value }
        throw DecodingError.keyNotFound(FlexibleKey(stringValue: keys.first ?? "unknown"), .init(codingPath: container.codingPath, debugDescription: "Missing required field"))
    }

    private static func decodeString(_ container: KeyedDecodingContainer<FlexibleKey>, keys: [String]) -> String? {
        for key in keys {
            let k = FlexibleKey(stringValue: key)
            if let value = try? container.decodeIfPresent(String.self, forKey: k) { return value }
        }
        return nil
    }

    private static func decodeInt(_ container: KeyedDecodingContainer<FlexibleKey>, keys: [String]) -> Int? {
        for key in keys {
            let k = FlexibleKey(stringValue: key)
            if let value = try? container.decodeIfPresent(Int.self, forKey: k) { return value }
            if let str = try? container.decodeIfPresent(String.self, forKey: k), let value = Int(str) { return value }
        }
        return nil
    }

    private static func decodeDouble(_ container: KeyedDecodingContainer<FlexibleKey>, keys: [String]) -> Double? {
        for key in keys {
            let k = FlexibleKey(stringValue: key)
            if let value = try? container.decodeIfPresent(Double.self, forKey: k) { return value }
            if let intValue = try? container.decodeIfPresent(Int.self, forKey: k) { return Double(intValue) }
            if let str = try? container.decodeIfPresent(String.self, forKey: k), let value = Double(str) { return value }
        }
        return nil
    }
}

private struct FlexibleKey: CodingKey {
    let stringValue: String
    let intValue: Int?

    init(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }

    init?(intValue: Int) {
        self.stringValue = "\(intValue)"
        self.intValue = intValue
    }
}
