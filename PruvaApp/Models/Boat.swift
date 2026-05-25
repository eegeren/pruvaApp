import Foundation

struct Boat: Identifiable, Codable {
    let id: String
    var name: String
    var type: String?
    var lengthM: Double?
    var draftM: Double?
    var fuelCapacityL: Double?
    var engineType: String?
    var registrationNo: String?
    var insuranceExpiresAt: String?
    var registrationExpiresAt: String?

    enum CodingKeys: String, CodingKey {
        case id, name, type
        case lengthM = "length_m"
        case draftM = "draft_m"
        case fuelCapacityL = "fuel_capacity_l"
        case engineType = "engine_type"
        case registrationNo = "registration_no"
        case insuranceExpiresAt = "insurance_expires_at"
        case registrationExpiresAt = "registration_expires_at"
    }
}
