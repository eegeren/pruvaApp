import Foundation
import Combine

@MainActor
final class BoatViewModel: ObservableObject {
    @Published var boats: [Boat] = []
    @Published var selectedBoat: Boat? = nil
    @Published var fuelLogs: [FuelLog] = []
    @Published var moorings: [Mooring] = []
    @Published var maintenanceLogs: [MaintenanceLog] = []
    @Published var voyageLogs: [VoyageLog] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    var totalFuelCost: Double { fuelLogs.compactMap(\.totalCost).reduce(0, +) }
    var totalDistanceNm: Double { voyageLogs.compactMap(\.distanceNm).reduce(0, +) }

    var upcomingMaintenance: [MaintenanceLog] {
        let parser = ISO8601DateFormatter()
        let max = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
        return maintenanceLogs.filter {
            guard let next = $0.nextDueAt, let d = parser.date(from: next) else { return false }
            return d <= max
        }
    }

    func loadAll() async { await loadBoats(); await loadFuelLogs(); await loadMoorings(); await loadMaintenance(); await loadVoyages() }

    func loadBoats() async {
        isLoading = true; defer { isLoading = false }
        boats = (try? await APIService.shared.fetchBoats()) ?? []
        if selectedBoat == nil { selectedBoat = boats.first }
    }

    func loadFuelLogs() async { guard let id = selectedBoat?.id else { return }; fuelLogs = (try? await APIService.shared.fetchFuelLogs(boatId: id)) ?? [] }
    func loadMoorings() async { guard let id = selectedBoat?.id else { return }; moorings = (try? await APIService.shared.fetchMoorings(boatId: id)) ?? [] }
    func loadMaintenance() async { guard let id = selectedBoat?.id else { return }; maintenanceLogs = (try? await APIService.shared.fetchMaintenance(boatId: id)) ?? [] }
    func loadVoyages() async { guard let id = selectedBoat?.id else { return }; voyageLogs = (try? await APIService.shared.fetchVoyages(boatId: id)) ?? [] }

    func deleteSelectedBoat() async {
        guard let boat = selectedBoat else { return }
        do {
            try await APIService.shared.deleteBoat(boatId: boat.id)
            boats.removeAll { $0.id == boat.id }
            selectedBoat = boats.first
            await loadFuelLogs()
            await loadMoorings()
            await loadMaintenance()
            await loadVoyages()
            errorMessage = nil
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }
}
