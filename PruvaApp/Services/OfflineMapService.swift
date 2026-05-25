import Foundation
import Combine

struct OfflineRegion: Identifiable {
    let id = UUID()
    let name: String
    let radiusKm: Double
    let downloadedAt: Date
}

@MainActor
final class OfflineMapService: ObservableObject {
    static let shared = OfflineMapService()
    @Published var regions: [OfflineRegion] = []

    private init() {}

    func addRegion(name: String, radiusKm: Double) {
        regions.append(OfflineRegion(name: name, radiusKm: radiusKm, downloadedAt: Date()))
    }

    var storageUsage: Double { min(1.0, Double(regions.count) * 0.08) }
}
