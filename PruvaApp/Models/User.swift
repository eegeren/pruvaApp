import Foundation

struct User: Codable {
    let id: String
    let email: String
    let username: String
    let isPremium: Bool

    enum CodingKeys: String, CodingKey {
        case id, email, username
        case isPremium = "is_premium"
    }
}

struct AuthResponse: Codable {
    let user: User
    let token: String
}
