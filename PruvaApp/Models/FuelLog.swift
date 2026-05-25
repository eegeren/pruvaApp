import Foundation

struct FuelLog: Identifiable, Codable {
    let id: String
    let boatId: String
    var liters: Double
    var pricePerLiter: Double?
    var totalCost: Double?
    var locationName: String?
    var notes: String?
    var loggedAt: String

    enum CodingKeys: String, CodingKey {
        case id, liters, notes
        case boatId = "boat_id"
        case pricePerLiter = "price_per_liter"
        case totalCost = "total_cost"
        case locationName = "location_name"
        case loggedAt = "logged_at"
    }
}
