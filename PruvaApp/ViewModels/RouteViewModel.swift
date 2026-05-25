import Foundation
import SwiftUI
import Combine

@MainActor
final class RouteViewModel: ObservableObject {
    @Published var isRoutingMode: Bool = false
    @Published var waypoints: [Waypoint] = []
    @Published var savedRoutes: [Route] = []
    @Published var averageSpeed: Double = 6.0
    @Published var isCalculating: Bool = false
    @Published var showRouteSummary: Bool = false
    @Published var showSearchSheet: Bool = false
    @Published var toastMessage: String? = nil

    // Compatibility with existing views still using currentRoute.
    var currentRoute: Route {
        get {
            Route(
                id: UUID(),
                name: currentRouteName,
                waypoints: waypoints,
                totalDistanceNm: totalDistanceNm,
                totalDurationHours: totalDurationHours,
                averageSpeedKn: averageSpeed,
                createdAt: Date()
            )
        }
        set {
            currentRouteName = newValue.name
            waypoints = newValue.waypoints
            averageSpeed = newValue.averageSpeedKn
            recalculate()
        }
    }

    @Published var currentRouteName: String = "My Route"

    var totalDistanceNm: Double {
        waypoints.compactMap { $0.distanceFromPrevious }.reduce(0, +)
    }

    var totalDurationHours: Double {
        guard averageSpeed > 0 else { return 0 }
        return totalDistanceNm / averageSpeed
    }

    var formattedDistance: String { String(format: "%.1f nm", totalDistanceNm) }

    var formattedDuration: String {
        let h = Int(totalDurationHours)
        let m = Int((totalDurationHours - Double(h)) * 60)
        return "\(h)h \(m)m"
    }

    init() {
        loadSavedRoutes()
    }

    func addWaypoint(name: String, lat: Double, lon: Double) {
        let wp = Waypoint(
            id: UUID(),
            anchorage: nil,
            customName: name,
            latitude: lat,
            longitude: lon,
            order: waypoints.count,
            estimatedArrival: nil,
            notes: nil,
            distanceFromPrevious: nil,
            durationFromPrevious: nil
        )
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            waypoints.append(wp)
        }
        recalculate()
        showToast("✓ \(name) added to route")
    }

    func addWaypoint(_ waypoint: Waypoint) {
        addWaypoint(name: waypoint.displayName, lat: waypoint.latitude, lon: waypoint.longitude)
    }

    func addAnchorage(_ anchorage: Anchorage) {
        let wp = Waypoint(
            id: UUID(),
            anchorage: anchorage,
            customName: anchorage.name,
            latitude: anchorage.latitude,
            longitude: anchorage.longitude,
            order: waypoints.count,
            estimatedArrival: nil,
            notes: nil,
            distanceFromPrevious: nil,
            durationFromPrevious: nil
        )
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            waypoints.append(wp)
        }
        recalculate()
        showToast("✓ \(anchorage.name) added")
    }

    func removeWaypoint(id: UUID) {
        withAnimation(.spring()) {
            waypoints.removeAll { $0.id == id }
        }
        for i in 0..<waypoints.count { waypoints[i].order = i }
        recalculate()
    }

    func moveWaypoint(from: IndexSet, to: Int) {
        waypoints.move(fromOffsets: from, toOffset: to)
        for i in 0..<waypoints.count { waypoints[i].order = i }
        recalculate()
    }

    func recalculate() {
        isCalculating = true
        var time = Date()

        for i in 0..<waypoints.count {
            waypoints[i].estimatedArrival = time
            if i == 0 {
                waypoints[i].distanceFromPrevious = nil
                waypoints[i].durationFromPrevious = nil
                continue
            }

            let dist = haversineNm(
                lat1: waypoints[i - 1].latitude,
                lon1: waypoints[i - 1].longitude,
                lat2: waypoints[i].latitude,
                lon2: waypoints[i].longitude
            )
            waypoints[i].distanceFromPrevious = dist
            let duration = averageSpeed > 0 ? dist / averageSpeed : 0
            waypoints[i].durationFromPrevious = duration
            time = time.addingTimeInterval(duration * 3600)
        }

        isCalculating = false
    }

    func recalculateRoute() { recalculate() }

    func clearRoute() {
        withAnimation(.spring()) { waypoints.removeAll() }
        isRoutingMode = false
    }

    func newRoute() {
        currentRouteName = "My Route"
        clearRoute()
    }

    func saveRoute(name: String? = nil) {
        let route = Route(
            id: UUID(),
            name: name?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false ? name! : currentRouteName,
            waypoints: waypoints,
            totalDistanceNm: totalDistanceNm,
            totalDurationHours: totalDurationHours,
            averageSpeedKn: averageSpeed,
            createdAt: Date()
        )
        savedRoutes.append(route)
        if let encoded = try? JSONEncoder().encode(savedRoutes) {
            UserDefaults.standard.set(encoded, forKey: "saved_routes")
        }
        showToast("Route saved!")
    }

    func loadSavedRoutes() {
        if let data = UserDefaults.standard.data(forKey: "saved_routes"),
           let decoded = try? JSONDecoder().decode([Route].self, from: data) {
            savedRoutes = decoded
        }
    }

    func loadRoute(_ route: Route) {
        currentRouteName = route.name
        waypoints = route.waypoints
        averageSpeed = route.averageSpeedKn
        isRoutingMode = true
        recalculate()
        showToast("✓ \(route.name) loaded")
    }

    func deleteSavedRoute(id: UUID) {
        savedRoutes.removeAll { $0.id == id }
        if let encoded = try? JSONEncoder().encode(savedRoutes) {
            UserDefaults.standard.set(encoded, forKey: "saved_routes")
        }
    }

    func showToast(_ message: String) {
        toastMessage = message
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            self.toastMessage = nil
        }
    }

    private func haversineNm(lat1: Double, lon1: Double, lat2: Double, lon2: Double) -> Double {
        let r = 3440.065
        let dLat = (lat2 - lat1) * .pi / 180
        let dLon = (lon2 - lon1) * .pi / 180
        let a = sin(dLat / 2) * sin(dLat / 2) +
            cos(lat1 * .pi / 180) * cos(lat2 * .pi / 180) * sin(dLon / 2) * sin(dLon / 2)
        return r * 2 * atan2(sqrt(a), sqrt(1 - a))
    }
}
