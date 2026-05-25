import Foundation

final class AuthService {
    static let shared = AuthService()
    private init() {}

    func saveAuth(response: AuthResponse) {
        UserDefaults.standard.set(response.token, forKey: "jwt_token")
        if let data = try? JSONEncoder().encode(response.user) {
            UserDefaults.standard.set(data, forKey: "current_user")
        }
    }

    func loadSavedUser() -> User? {
        guard let data = UserDefaults.standard.data(forKey: "current_user") else { return nil }
        return try? JSONDecoder().decode(User.self, from: data)
    }

    func loadSavedToken() -> String? { UserDefaults.standard.string(forKey: "jwt_token") }
    func logout() { UserDefaults.standard.removeObject(forKey: "jwt_token"); UserDefaults.standard.removeObject(forKey: "current_user") }
    func isLoggedIn() -> Bool { loadSavedToken() != nil }
}
