import SwiftUI

struct MapPoint: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let type: String
    let anchorageId: String?
    let latitude: Double
    let longitude: Double
    let description: String?
    let phone: String?
    let website: String?
    let vhfChannel: String?
    let depthM: Double?
    let berthCount: Int?
    let openingHours: String?
    let fuelTypes: String?
    let rating: Double

    enum CodingKeys: String, CodingKey {
        case id, name, type, latitude, longitude
        case anchorageId = "anchorage_id"
        case description, phone, website, rating
        case vhfChannel = "vhf_channel"
        case depthM = "depth_m"
        case berthCount = "berth_count"
        case openingHours = "opening_hours"
        case fuelTypes = "fuel_types"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        type = try c.decode(String.self, forKey: .type)
        anchorageId = Self.decodeString(c, keys: [.anchorageId])
        latitude = Self.decodeDouble(c, keys: [.latitude]) ?? 0
        longitude = Self.decodeDouble(c, keys: [.longitude]) ?? 0
        description = Self.decodeString(c, keys: [.description])
        phone = Self.decodeString(c, keys: [.phone])
        website = Self.decodeString(c, keys: [.website])
        vhfChannel = Self.decodeString(c, keys: [.vhfChannel])
        depthM = Self.decodeDouble(c, keys: [.depthM])
        berthCount = Self.decodeInt(c, keys: [.berthCount])
        openingHours = Self.decodeString(c, keys: [.openingHours])
        fuelTypes = Self.decodeString(c, keys: [.fuelTypes])
        rating = Self.decodeDouble(c, keys: [.rating]) ?? 0
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(name, forKey: .name)
        try c.encode(type, forKey: .type)
        try c.encodeIfPresent(anchorageId, forKey: .anchorageId)
        try c.encode(latitude, forKey: .latitude)
        try c.encode(longitude, forKey: .longitude)
        try c.encodeIfPresent(description, forKey: .description)
        try c.encodeIfPresent(phone, forKey: .phone)
        try c.encodeIfPresent(website, forKey: .website)
        try c.encodeIfPresent(vhfChannel, forKey: .vhfChannel)
        try c.encodeIfPresent(depthM, forKey: .depthM)
        try c.encodeIfPresent(berthCount, forKey: .berthCount)
        try c.encodeIfPresent(openingHours, forKey: .openingHours)
        try c.encodeIfPresent(fuelTypes, forKey: .fuelTypes)
        try c.encode(rating, forKey: .rating)
    }

    init(
        id: String,
        name: String,
        type: String,
        anchorageId: String? = nil,
        latitude: Double,
        longitude: Double,
        description: String? = nil,
        phone: String? = nil,
        website: String? = nil,
        vhfChannel: String? = nil,
        depthM: Double? = nil,
        berthCount: Int? = nil,
        openingHours: String? = nil,
        fuelTypes: String? = nil,
        rating: Double = 0
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.anchorageId = anchorageId
        self.latitude = latitude
        self.longitude = longitude
        self.description = description
        self.phone = phone
        self.website = website
        self.vhfChannel = vhfChannel
        self.depthM = depthM
        self.berthCount = berthCount
        self.openingHours = openingHours
        self.fuelTypes = fuelTypes
        self.rating = rating
    }

    private static func decodeString(_ c: KeyedDecodingContainer<CodingKeys>, keys: [CodingKeys]) -> String? {
        for key in keys {
            if let v = try? c.decodeIfPresent(String.self, forKey: key) {
                let t = v.trimmingCharacters(in: .whitespacesAndNewlines)
                if !t.isEmpty { return t }
            }
        }
        return nil
    }

    private static func decodeInt(_ c: KeyedDecodingContainer<CodingKeys>, keys: [CodingKeys]) -> Int? {
        for key in keys {
            if let v = try? c.decodeIfPresent(Int.self, forKey: key) { return v }
            if let s = try? c.decodeIfPresent(String.self, forKey: key), let v = Int(s) { return v }
        }
        return nil
    }

    private static func decodeDouble(_ c: KeyedDecodingContainer<CodingKeys>, keys: [CodingKeys]) -> Double? {
        for key in keys {
            if let v = try? c.decodeIfPresent(Double.self, forKey: key) { return v }
            if let i = try? c.decodeIfPresent(Int.self, forKey: key) { return Double(i) }
            if let s = try? c.decodeIfPresent(String.self, forKey: key), let v = Double(s) { return v }
        }
        return nil
    }

    var icon: String {
        switch type {
        case "marina": return "ferry.fill"
        case "fuel": return "fuelpump.fill"
        case "service": return "wrench.and.screwdriver.fill"
        case "diving": return "figure.open.water.swim"
        default: return "mappin.fill"
        }
    }

    var color: Color {
        switch type {
        case "marina": return Color(hex: "0077B6")
        case "fuel": return Color(hex: "F4A261")
        case "service": return Color(hex: "2EC4B6")
        case "diving": return Color(hex: "7B2FBE")
        default: return .white
        }
    }

    var typeLabel: String {
        switch type {
        case "marina": return "Marina"
        case "fuel": return "Fuel Station"
        case "service": return "Service Point"
        case "diving": return "Dive Site"
        default: return "Point"
        }
    }
}
