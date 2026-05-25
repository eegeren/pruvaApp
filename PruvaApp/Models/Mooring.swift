import Foundation

struct Mooring: Identifiable, Codable {
    let id: String
    let boatId: String
    var marinaName: String
    var pontoon: String?
    var berthNo: String?
    var monthlyFee: Double?
    var isCurrent: Bool
    var startDate: String?
    var notes: String?

    enum CodingKeys: String, CodingKey {
        case id, pontoon, notes
        case boatId = "boat_id"
        case marinaName = "marina_name"
        case berthNo = "berth_no"
        case monthlyFee = "monthly_fee"
        case isCurrent = "is_current"
        case startDate = "start_date"
    }
}
