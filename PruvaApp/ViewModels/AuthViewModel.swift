import Foundation
import Combine

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var isLoggedIn = false
    @Published var user: User? = nil
    @Published var isLoading = false
    @Published var error: String? = nil

    init() {
        if let savedUser = AuthService.shared.loadSavedUser(), AuthService.shared.loadSavedToken() != nil {
            user = savedUser
            isLoggedIn = true
        }
    }

    func login(email: String, password: String) async {
        guard !isLoading else { return }
        isLoading = true; error = nil
        defer { isLoading = false }
        do {
            let response = try await APIService.shared.login(email: email, password: password)
            AuthService.shared.saveAuth(response: response)
            user = response.user
            isLoggedIn = true
        } catch {
            self.error = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    func register(email: String, username: String, password: String) async {
        guard !isLoading else { return }
        isLoading = true; error = nil
        defer { isLoading = false }
        do {
            let response = try await APIService.shared.register(email: email, username: username, password: password)
            AuthService.shared.saveAuth(response: response)
            user = response.user
            isLoggedIn = true
        } catch {
            self.error = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    func logout() { AuthService.shared.logout(); user = nil; isLoggedIn = false }
}
