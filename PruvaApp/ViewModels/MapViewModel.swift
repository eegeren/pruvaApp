import Foundation
import Combine
import MapKit

enum MapMode {
    case browse
    case routing
    case detail
    case weather
}

@MainActor
final class MapViewModel: ObservableObject {
    @Published var anchorages: [Anchorage] = []
    @Published var mapPoints: [MapPoint] = []
    @Published var selectedAnchorage: Anchorage? = nil
    @Published var selectedMapPoint: MapPoint? = nil
    @Published var isLoading = false
    @Published var showAnchorages: Bool = false
    @Published var showMarinas: Bool = false
    @Published var showFuel: Bool = false
    @Published var showService: Bool = false
    @Published var showDiving: Bool = false
    @Published var mapMode: MapMode = .browse
    @Published var currentRegion: MKCoordinateRegion = .init(
        center: .init(latitude: 37.0, longitude: 27.5),
        span: .init(latitudeDelta: 4, longitudeDelta: 4)
    )

    private var lastLoadedRegion: MKCoordinateRegion? = nil
    private var isFetchingRegion = false

    func loadAnchorages(for region: MKCoordinateRegion) async {
        let minLat = region.center.latitude - region.span.latitudeDelta / 2
        let maxLat = region.center.latitude + region.span.latitudeDelta / 2
        let minLon = region.center.longitude - region.span.longitudeDelta / 2
        let maxLon = region.center.longitude + region.span.longitudeDelta / 2
        do {
            let results = try await APIService.shared.fetchAnchoragesByBounds(minLat: minLat, maxLat: maxLat, minLon: minLon, maxLon: maxLon)
            let existing = Set(anchorages.map(\.id))
            anchorages.append(contentsOf: results.filter { !existing.contains($0.id) })
            lastLoadedRegion = region
        } catch {
            print("Map load error: \(error)")
        }
    }

    func loadMapPoints(for region: MKCoordinateRegion) async {
        let minLat = region.center.latitude - region.span.latitudeDelta / 2
        let maxLat = region.center.latitude + region.span.latitudeDelta / 2
        let minLon = region.center.longitude - region.span.longitudeDelta / 2
        let maxLon = region.center.longitude + region.span.longitudeDelta / 2
        do {
            let results = try await APIService.shared.fetchMapPoints(minLat: minLat, maxLat: maxLat, minLon: minLon, maxLon: maxLon)
            let existing = Set(mapPoints.map(\.id))
            mapPoints.append(contentsOf: results.filter { !existing.contains($0.id) })
            lastLoadedRegion = region
        } catch {
            print("Map point load error: \(error)")
        }
    }

    func loadAll(for region: MKCoordinateRegion) async {
        if isFetchingRegion { return }
        if let last = lastLoadedRegion {
            let latDiff = abs(region.center.latitude - last.center.latitude)
            let lonDiff = abs(region.center.longitude - last.center.longitude)
            if latDiff < 0.22 && lonDiff < 0.22 { return }
        }

        isFetchingRegion = true
        isLoading = true
        lastLoadedRegion = region
        currentRegion = region
        async let anchoragesTask: Void = loadAnchorages(for: region)
        async let pointsTask: Void = loadMapPoints(for: region)
        _ = await (anchoragesTask, pointsTask)
        isLoading = false
        isFetchingRegion = false
    }

    var visibleMapPoints: [MapPoint] {
        let filtered = mapPoints.filter { point in
            switch point.type {
            case "marina": return showMarinas
            case "fuel": return showFuel
            case "service": return showService
            case "diving": return showDiving
            default: return true
            }
        }
        return progressiveMapPoints(filtered)
    }

    var visibleAnchorages: [Anchorage] {
        guard showAnchorages else { return [] }
        return progressiveAnchorages(anchorages)
    }

    private func progressiveAnchorages(_ items: [Anchorage]) -> [Anchorage] {
        let inRegion = items.filter { isInVisibleRegion(lat: $0.latitude, lon: $0.longitude) }
        return thinAndLimit(
            inRegion,
            lat: { $0.latitude },
            lon: { $0.longitude }
        )
    }

    private func progressiveMapPoints(_ items: [MapPoint]) -> [MapPoint] {
        let inRegion = items.filter { isInVisibleRegion(lat: $0.latitude, lon: $0.longitude) }
        return thinAndLimit(
            inRegion,
            lat: { $0.latitude },
            lon: { $0.longitude }
        )
    }

    private func thinAndLimit<T>(
        _ items: [T],
        lat: (T) -> Double,
        lon: (T) -> Double
    ) -> [T] {
        guard !items.isEmpty else { return [] }

        let span = max(currentRegion.span.latitudeDelta, currentRegion.span.longitudeDelta)
        let gridSize: Double
        let hardLimit: Int

        switch span {
        case 6...:
            gridSize = 0.35
            hardLimit = 70
        case 3...6:
            gridSize = 0.20
            hardLimit = 120
        case 1.5...3:
            gridSize = 0.10
            hardLimit = 220
        case 0.8...1.5:
            gridSize = 0.05
            hardLimit = 360
        default:
            gridSize = 0.02
            hardLimit = 700
        }

        let centerLat = currentRegion.center.latitude
        let centerLon = currentRegion.center.longitude
        let sorted = items.sorted {
            let d0 = pow(lat($0) - centerLat, 2) + pow(lon($0) - centerLon, 2)
            let d1 = pow(lat($1) - centerLat, 2) + pow(lon($1) - centerLon, 2)
            return d0 < d1
        }

        var seenCells = Set<String>()
        var result: [T] = []
        result.reserveCapacity(min(hardLimit, sorted.count))

        for item in sorted {
            let cellLat = Int((lat(item) / gridSize).rounded(.down))
            let cellLon = Int((lon(item) / gridSize).rounded(.down))
            let key = "\(cellLat)_\(cellLon)"
            guard !seenCells.contains(key) else { continue }
            seenCells.insert(key)
            result.append(item)
            if result.count >= hardLimit { break }
        }

        return result
    }

    private func isInVisibleRegion(lat: Double, lon: Double) -> Bool {
        let extraFactor = 0.65
        let latPadding = currentRegion.span.latitudeDelta * extraFactor
        let lonPadding = currentRegion.span.longitudeDelta * extraFactor
        let minLat = currentRegion.center.latitude - currentRegion.span.latitudeDelta / 2 - latPadding
        let maxLat = currentRegion.center.latitude + currentRegion.span.latitudeDelta / 2 + latPadding
        let minLon = currentRegion.center.longitude - currentRegion.span.longitudeDelta / 2 - lonPadding
        let maxLon = currentRegion.center.longitude + currentRegion.span.longitudeDelta / 2 + lonPadding
        return lat >= minLat && lat <= maxLat && lon >= minLon && lon <= maxLon
    }
}
