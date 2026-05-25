import Foundation

struct Route: Identifiable, Codable {
    let id: UUID
    var name: String
    var waypoints: [Waypoint]
    var totalDistanceNm: Double
    var totalDurationHours: Double
    var averageSpeedKn: Double
    var createdAt: Date

    var formattedDistance: String {
        String(format: "%.1f nm", totalDistanceNm)
    }

    var formattedDuration: String {
        let hours = Int(totalDurationHours)
        let minutes = Int((totalDurationHours - Double(hours)) * 60)
        return "\(hours)h \(minutes)m"
    }
}
