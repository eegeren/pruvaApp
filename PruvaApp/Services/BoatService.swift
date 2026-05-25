import Foundation

final class BoatService {
    static let shared = BoatService()
    private init() {}

    func loadBoats() async throws -> [Boat] { try await APIService.shared.fetchBoats() }
}
