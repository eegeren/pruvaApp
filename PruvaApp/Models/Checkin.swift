import Foundation

struct Checkin: Identifiable, Codable {
    let id: String
    let userId: String
    let anchorageId: String
    let username: String?
    let boatName: String?
    let note: String?
    let depthObserved: Double?
    let waveHeight: Double?
    let windSpeed: Double?
    let bottomQuality: Int?
    let isCurrent: Bool
    let arrivedAt: String
    let departedAt: String?

    enum CodingKeys: String, CodingKey {
        case id, username, note
        case userId = "user_id"
        case anchorageId = "anchorage_id"
        case boatName = "boat_name"
        case depthObserved = "depth_observed"
        case waveHeight = "wave_height"
        case windSpeed = "wind_speed"
        case bottomQuality = "bottom_quality"
        case isCurrent = "is_current"
        case arrivedAt = "arrived_at"
        case departedAt = "departed_at"
    }

    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        let date = ISO8601DateFormatter().date(from: arrivedAt) ?? Date()
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    var durationText: String? {
        guard let departed = departedAt,
              let arrivedDate = ISO8601DateFormatter().date(from: arrivedAt),
              let departedDate = ISO8601DateFormatter().date(from: departed) else { return nil }
        let hours = Int(departedDate.timeIntervalSince(arrivedDate) / 3600)
        let minutes = Int(departedDate.timeIntervalSince(arrivedDate) / 60) % 60
        return "\(hours)h \(minutes)m"
    }
}
