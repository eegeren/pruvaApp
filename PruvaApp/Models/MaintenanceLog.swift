import Foundation

struct MaintenanceLog: Identifiable, Codable {
    let id: String
    let boatId: String
    var title: String
    var category: String?
    var cost: Double?
    var doneAt: String
    var nextDueAt: String?

    enum CodingKeys: String, CodingKey {
        case id, title, category, cost
        case boatId = "boat_id"
        case doneAt = "done_at"
        case nextDueAt = "next_due_at"
    }
}
