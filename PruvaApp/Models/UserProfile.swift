import Foundation

struct UserProfile: Codable {
    let id: String
    var email: String
    var username: String
    var fullName: String?
    var phone: String?
    var country: String?
    var age: Int?
    var bio: String?
    var avatarColor: String?
    let isPremium: Bool
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id, email, username, phone, country, age, bio
        case fullName = "full_name"
        case avatarColor = "avatar_color"
        case isPremium = "is_premium"
        case createdAt = "created_at"
    }

    var initials: String {
        if let fullName, !fullName.isEmpty {
            let parts = fullName.split(separator: " ")
            if parts.count >= 2 {
                return "\(parts[0].prefix(1))\(parts[1].prefix(1))".uppercased()
            }
            return String(fullName.prefix(1)).uppercased()
        }
        return String(username.prefix(1)).uppercased()
    }

    var displayName: String {
        if let fullName, !fullName.isEmpty { return fullName }
        return username
    }

    var memberSince: String {
        guard let createdAt else { return "" }
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let iso2 = ISO8601DateFormatter()
        guard let date = iso.date(from: createdAt) ?? iso2.date(from: createdAt) else { return "" }
        let fmt = DateFormatter()
        fmt.dateFormat = "MMMM yyyy"
        return "Member since \(fmt.string(from: date))"
    }
}
