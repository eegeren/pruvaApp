import Foundation

struct MapPointDisplayFacts: Codable {
    var entranceDepth: String?
    var berthCapacity: String?
    var vhfChannel: String?
    var openingHours: String?
    var fuelTypes: String?
    var amenities: String?
    var summary: String?

    var hasAnyDetail: Bool {
        entranceDepth != nil || berthCapacity != nil || vhfChannel != nil
            || openingHours != nil || fuelTypes != nil || amenities != nil || summary != nil
    }
}
