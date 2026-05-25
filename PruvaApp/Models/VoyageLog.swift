import Foundation

struct VoyageLog: Identifiable, Codable {
    let id: String
    let boatId: String
    var fromName: String?
    var toName: String?
    var distanceNm: Double?
    var durationHours: Double?
    var departedAt: String?
    var arrivedAt: String?
    var notes: String?

    enum CodingKeys: String, CodingKey {
        case id, notes
        case boatId = "boat_id"
        case fromName = "from_name"
        case toName = "to_name"
        case distanceNm = "distance_nm"
        case durationHours = "duration_hours"
        case departedAt = "departed_at"
        case arrivedAt = "arrived_at"
    }
}
