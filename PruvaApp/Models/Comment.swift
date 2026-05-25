import Foundation

struct Comment: Identifiable, Codable {
    let id: String
    let anchorageId: String?
    let mapPointId: String?
    let userId: String
    let username: String?
    let text: String
    let depthObserved: Double?
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id, username, text
        case anchorageId = "anchorage_id"
        case mapPointId = "map_point_id"
        case userId = "user_id"
        case depthObserved = "depth_observed"
        case createdAt = "created_at"
    }
}
