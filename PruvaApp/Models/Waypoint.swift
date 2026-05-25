import Foundation

struct Waypoint: Identifiable, Codable {
    let id: UUID
    var anchorage: Anchorage?
    var customName: String?
    var latitude: Double
    var longitude: Double
    var order: Int
    var estimatedArrival: Date?
    var notes: String?
    var distanceFromPrevious: Double?
    var durationFromPrevious: Double?

    var displayName: String {
        if let name = customName, !name.isEmpty { return name }
        if let anchorage = anchorage { return anchorage.name }
        return "Stop \(order + 1)"
    }
}
