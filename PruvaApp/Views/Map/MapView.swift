import SwiftUI
import MapKit
import CoreLocation

private enum ActiveMapSheet: Identifiable {
    case filter
    case weather
    case routePlanner
    case routeSearch
    case mapPoint(MapPoint)
    case anchorage(Anchorage)
    case routeSummary

    var id: String {
        switch self {
        case .filter: return "filter"
        case .weather: return "weather"
        case .routePlanner: return "routePlanner"
        case .routeSearch: return "routeSearch"
        case .mapPoint(let p): return "mapPoint-\(p.id)"
        case .anchorage(let a): return "anchorage-\(a.id)"
        case .routeSummary: return "routeSummary"
        }
    }
}

struct MapView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var mapViewModel: MapViewModel
    @EnvironmentObject var storeService: StoreService
    @ObservedObject private var locationService = LocationService.shared
    @StateObject private var routeVM = RouteViewModel()
    @StateObject private var weatherVM = WeatherViewModel()

    @State private var search = ""
    @State private var activeSheet: ActiveMapSheet?
    @State private var askWaypointAtCoordinate: CLLocationCoordinate2D?
    @State private var focusRegion: MKCoordinateRegion?
    @State private var showPaywall = false
    @State private var showProfileSheet = false
    @State private var showLogin = false
    @State private var selectedRouteDetent: PresentationDetent = .medium
    @State private var isWaitingForLocation = false
    @State private var showLocationPermissionAlert = false
    @State private var isCaptainModeEnabled = false

    var body: some View {
        ZStack {
            MapUIKitView(
                anchorages: filteredAnchorages,
                mapPoints: filteredMapPoints,
                selectedAnchorage: $mapViewModel.selectedAnchorage,
                selectedMapPoint: $mapViewModel.selectedMapPoint,
                routeWaypoints: routeVM.waypoints,
                routeMode: routeVM.isRoutingMode,
                focusRegion: focusRegion,
                onAnchorageTap: handleAnchorageTap,
                onRegionChanged: { await mapViewModel.loadAll(for: $0) },
                onLongPressCoordinate: { askWaypointAtCoordinate = $0 },
                onFocusRegionApplied: { focusRegion = nil }
            )
            .overlay {
                if routeVM.isRoutingMode {
                    Color.oceanAccent.opacity(0.05).ignoresSafeArea()
                        .allowsHitTesting(false)
                } else if mapViewModel.mapMode == .weather {
                    WaveAnimationView(waveHeight: weatherVM.currentConditions?.waveHeight ?? 0.6)
                        .opacity(0.1)
                        .ignoresSafeArea()
                        .allowsHitTesting(false)
                }
            }
            .ignoresSafeArea()
        }
        .safeAreaInset(edge: .top) {
            VStack(spacing: 8) {
                topBar
                if routeVM.isRoutingMode {
                    Text("Tap anchorages to add to route")
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color(hex: "023E8A").opacity(0.92))
                        .clipShape(Capsule())
                }
                if let message = routeVM.toastMessage {
                    Text(message)
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color(hex: "023E8A").opacity(0.95))
                        .cornerRadius(20)
                        .shadow(radius: 8)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .padding(.top, 4)
        }
        .safeAreaInset(edge: .trailing) {
            fabStack
                .padding(.trailing, 10)
        }
        .safeAreaInset(edge: .bottom) {
            if routeVM.waypoints.count >= 2 {
                RouteDetailCard(route: Route(
                    id: UUID(),
                    name: routeVM.currentRouteName,
                    waypoints: routeVM.waypoints,
                    totalDistanceNm: routeVM.totalDistanceNm,
                    totalDurationHours: routeVM.totalDurationHours,
                    averageSpeedKn: routeVM.averageSpeed,
                    createdAt: Date()
                ))
                    .padding(.horizontal)
                    .padding(.bottom, 6)
                    .animation(.spring(), value: routeVM.waypoints.count)
            }
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .filter:
                MapFilterView()
                    .environmentObject(mapViewModel)
                    .presentationDetents([.medium, .large])
                    .presentationBackground(Color(hex: "0096C7"))
                    .presentationCornerRadius(24)
                    .presentationDragIndicator(.visible)
            case .weather:
                WeatherSheetView(selectedAnchorage: nearestAnchorage, weatherVM: weatherVM, showPaywall: $showPaywall)
                    .environmentObject(storeService)
                    .presentationDetents([.medium, .large])
                    .presentationBackground(Color(hex: "0096C7"))
                    .presentationCornerRadius(24)
                    .presentationDragIndicator(.visible)
            case .routePlanner:
                RouteSheetView(routeVM: routeVM) {
                    routeVM.isRoutingMode = false
                    mapViewModel.mapMode = .browse
                    activeSheet = nil
                }
                .presentationDetents([.medium, .large], selection: $selectedRouteDetent)
                .presentationBackground(Color(hex: "0096C7"))
                .presentationCornerRadius(24)
                .presentationDragIndicator(.visible)
            case .routeSearch:
                RouteSearchView(routeVM: routeVM, mapVM: mapViewModel)
                    .presentationBackground(Color(hex: "0096C7"))
                    .presentationCornerRadius(24)
                    .presentationDragIndicator(.visible)
            case .mapPoint(let point):
                MapPointDetailView(mapPoint: point)
                    .environmentObject(storeService)
                    .environmentObject(authVM)
                    .presentationDetents([.medium, .large])
                    .presentationBackground(Color(hex: "0096C7"))
                    .presentationCornerRadius(24)
                    .presentationDragIndicator(.visible)
            case .anchorage(let anchorage):
                AnchorageDetailSheet(anchorage: anchorage) { addAnchorageToRoute(anchorage) }
                    .presentationDetents([.medium, .large])
                    .presentationBackground(Color(hex: "0096C7"))
                    .presentationCornerRadius(24)
                    .presentationDragIndicator(.visible)
            case .routeSummary:
                RouteSummaryView(routeVM: routeVM)
                    .presentationDetents([.medium, .large])
                    .presentationBackground(Color(hex: "0096C7"))
                    .presentationCornerRadius(24)
                    .presentationDragIndicator(.visible)
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
                .environmentObject(storeService)
                .presentationBackground(Color(hex: "0096C7"))
                .presentationCornerRadius(24)
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showLogin) {
            LoginView()
                .environmentObject(authVM)
                .presentationDetents([.large])
                .presentationBackground(Color(hex: "0096C7"))
                .presentationCornerRadius(24)
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showProfileSheet) {
            SettingsView()
                .presentationDetents([.medium, .large])
                .presentationBackground(Color(hex: "0096C7"))
                .presentationCornerRadius(24)
                .presentationDragIndicator(.visible)
        }
        .onReceive(locationService.$location) { loc in
            guard isWaitingForLocation, let loc else { return }
            focusRegion = .init(center: loc.coordinate, span: .init(latitudeDelta: 0.18, longitudeDelta: 0.18))
            isWaitingForLocation = false
        }
        .alert("Location Permission Needed", isPresented: $showLocationPermissionAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Please allow location access from iOS Settings to center the map on your position.")
        }
        .alert("Add waypoint here?", isPresented: .constant(askWaypointAtCoordinate != nil), actions: {
            Button("Add") {
                if let c = askWaypointAtCoordinate {
                    routeVM.addWaypoint(name: "Custom Point", lat: c.latitude, lon: c.longitude)
                    routeVM.isRoutingMode = true
                    presentSheet(.routePlanner)
                }
                askWaypointAtCoordinate = nil
            }
            Button("Cancel", role: .cancel) { askWaypointAtCoordinate = nil }
        })
        .onChange(of: mapViewModel.selectedMapPoint) { _, point in
            if let point { presentSheet(.mapPoint(point)) }
        }
        .onChange(of: routeVM.isRoutingMode) { _, isRouting in
            if !isRouting, case .routePlanner = activeSheet {
                activeSheet = nil
            }
        }
        .onChange(of: routeVM.waypoints.count) { _, count in
            selectedRouteDetent = count > 0 ? .large : .medium
        }
        .onChange(of: routeVM.showSearchSheet) { _, show in
            if show {
                routeVM.showSearchSheet = false
                presentSheet(.routeSearch)
            }
        }
        .onChange(of: routeVM.showRouteSummary) { _, show in
            if show {
                routeVM.showRouteSummary = false
                presentSheet(.routeSummary)
            }
        }
        .task {
            await mapViewModel.loadAll(for: mapViewModel.currentRegion)
            routeVM.loadSavedRoutes()
        }
    }

    private var topBar: some View {
        HStack(spacing: 8) {
            Text("PRUVA")
                .font(.system(size: 16, weight: .black))
                .foregroundStyle(.white)
                .tracking(3)

            Button {
                presentSheet(.routeSearch)
            } label: {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.white.opacity(0.7))
                        .font(.system(size: 14))
                    Text(search.isEmpty ? "Anchorage search..." : search)
                        .lineLimit(1)
                        .foregroundColor(.white.opacity(0.6))
                        .font(.system(size: 14))
                    Spacer()
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(Color.white.opacity(0.15))
                .cornerRadius(20)
            }

            Button { showProfileSheet = true } label: {
                Image(systemName: authVM.isLoggedIn ? "person.circle.fill" : "person.circle")
                    .foregroundColor(authVM.isLoggedIn ? Color(hex: "00B4D8") : .white)
                    .font(.system(size: 16))
                    .padding(8)
                    .background(Color.white.opacity(0.15))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
        .cornerRadius(30)
        .padding(.horizontal)
    }

    private var fabStack: some View {
        VStack(spacing: 10) {
            FABButton(icon: "point.topleft.down.curvedto.point.bottomright.up.fill", label: "My Route") {
                routeVM.isRoutingMode = true
                selectedRouteDetent = routeVM.waypoints.isEmpty ? .medium : .large
                presentSheet(.routePlanner)
            }
            FABButton(icon: "cloud.sun.fill", label: "Weather") {
                mapViewModel.mapMode = .weather
                presentSheet(.weather)
                loadNearestWeather()
            }
            FABButton(icon: "location.fill", label: "Location") {
                locationService.requestPermission()
                if locationService.isDeniedOrRestricted {
                    showLocationPermissionAlert = true
                    return
                }
                if let loc = locationService.location {
                    focusRegion = .init(center: loc.coordinate, span: .init(latitudeDelta: 0.18, longitudeDelta: 0.18))
                    isWaitingForLocation = false
                } else {
                    isWaitingForLocation = true
                }
            }
            FABButton(icon: "slider.horizontal.3", label: "Filter") { presentSheet(.filter) }
        }
        .padding(.trailing, 16)
    }

    private var captainModePanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Captain Mode", systemImage: "moon.stars.fill")
                    .font(.caption.bold())
                    .foregroundStyle(Color(hex: "90E0EF"))
                Spacer()
                Text(captainRiskLabel)
                    .font(.caption2.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(captainRiskColor.opacity(0.18))
                    .foregroundStyle(captainRiskColor)
                    .clipShape(Capsule())
            }

            HStack(spacing: 12) {
                metricItem("Speed", value: "\(Int(currentSpeedKn.rounded())) kn")
                metricItem("Deviation", value: String(format: "%.2f nm", routeDeviationNm))
                metricItem("ETA", value: etaText)
            }
        }
        .padding(10)
        .background(Color(hex: "03045E").opacity(0.88))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(hex: "00B4D8").opacity(0.35), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }

    private func metricItem(_ title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.7))
            Text(value)
                .font(.caption.bold())
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var currentSpeedKn: Double {
        guard let loc = locationService.location else { return 0 }
        return max(0, loc.speed) * 1.94384
    }

    private var routeDeviationNm: Double {
        guard let loc = locationService.location, routeVM.waypoints.count >= 2 else { return 0 }
        let current = loc.coordinate
        var minMeters = Double.greatestFiniteMagnitude
        for index in 0..<(routeVM.waypoints.count - 1) {
            let a = CLLocationCoordinate2D(latitude: routeVM.waypoints[index].latitude, longitude: routeVM.waypoints[index].longitude)
            let b = CLLocationCoordinate2D(latitude: routeVM.waypoints[index + 1].latitude, longitude: routeVM.waypoints[index + 1].longitude)
            minMeters = min(minMeters, distanceToSegmentMeters(point: current, a: a, b: b))
        }
        return minMeters / 1852.0
    }

    private var remainingDistanceNm: Double {
        guard let loc = locationService.location, routeVM.waypoints.count >= 2 else { return 0 }
        let current = loc.coordinate
        let nearestIndex = routeVM.waypoints.enumerated().min { lhs, rhs in
            CLLocation(latitude: lhs.element.latitude, longitude: lhs.element.longitude)
                .distance(from: CLLocation(latitude: current.latitude, longitude: current.longitude))
            <
            CLLocation(latitude: rhs.element.latitude, longitude: rhs.element.longitude)
                .distance(from: CLLocation(latitude: current.latitude, longitude: current.longitude))
        }?.offset ?? 0

        guard nearestIndex < routeVM.waypoints.count else { return 0 }
        var total = haversineNm(
            lat1: current.latitude,
            lon1: current.longitude,
            lat2: routeVM.waypoints[nearestIndex].latitude,
            lon2: routeVM.waypoints[nearestIndex].longitude
        )
        if nearestIndex + 1 < routeVM.waypoints.count {
            for i in (nearestIndex + 1)..<routeVM.waypoints.count {
                total += routeVM.waypoints[i].distanceFromPrevious ?? haversineNm(
                    lat1: routeVM.waypoints[i - 1].latitude,
                    lon1: routeVM.waypoints[i - 1].longitude,
                    lat2: routeVM.waypoints[i].latitude,
                    lon2: routeVM.waypoints[i].longitude
                )
            }
        }
        return total
    }

    private var etaText: String {
        guard routeVM.waypoints.count >= 2 else { return "--:--" }
        let speed = max(currentSpeedKn, routeVM.averageSpeed)
        guard speed > 0 else { return "--:--" }
        let hours = remainingDistanceNm / speed
        let eta = Date().addingTimeInterval(hours * 3600)
        return eta.formatted(.dateTime.hour().minute())
    }

    private var captainRiskLabel: String {
        let score = captainRiskScore
        switch score {
        case 0..<40: return "LOW RISK"
        case 40..<70: return "MEDIUM RISK"
        default: return "HIGH RISK"
        }
    }

    private var captainRiskColor: Color {
        let score = captainRiskScore
        switch score {
        case 0..<40: return .green
        case 40..<70: return .orange
        default: return .red
        }
    }

    private var captainRiskScore: Double {
        let deviation = min(routeDeviationNm * 100, 60)
        let wave = (weatherVM.currentConditions?.waveHeight ?? 0.6) * 12
        let speedPenalty = max(0, currentSpeedKn - routeVM.averageSpeed) * 2.2
        return min(100, deviation + wave + speedPenalty)
    }

    private func distanceToSegmentMeters(point: CLLocationCoordinate2D, a: CLLocationCoordinate2D, b: CLLocationCoordinate2D) -> Double {
        let px = point.longitude, py = point.latitude
        let ax = a.longitude, ay = a.latitude
        let bx = b.longitude, by = b.latitude
        let dx = bx - ax, dy = by - ay
        let lengthSq = dx * dx + dy * dy
        if lengthSq == 0 {
            return CLLocation(latitude: py, longitude: px).distance(from: CLLocation(latitude: ay, longitude: ax))
        }
        let t = max(0, min(1, ((px - ax) * dx + (py - ay) * dy) / lengthSq))
        let projX = ax + t * dx
        let projY = ay + t * dy
        return CLLocation(latitude: py, longitude: px).distance(from: CLLocation(latitude: projY, longitude: projX))
    }

    private func haversineNm(lat1: Double, lon1: Double, lat2: Double, lon2: Double) -> Double {
        let r = 3440.065
        let dLat = (lat2 - lat1) * .pi / 180
        let dLon = (lon2 - lon1) * .pi / 180
        let a = sin(dLat / 2) * sin(dLat / 2) +
            cos(lat1 * .pi / 180) * cos(lat2 * .pi / 180) * sin(dLon / 2) * sin(dLon / 2)
        return r * 2 * atan2(sqrt(a), sqrt(1 - a))
    }

    private var filteredAnchorages: [Anchorage] {
        let base = mapViewModel.visibleAnchorages
        guard !search.isEmpty else { return base }
        return base.filter { $0.name.localizedCaseInsensitiveContains(search) }
    }

    private var filteredMapPoints: [MapPoint] {
        let base = mapViewModel.visibleMapPoints
        guard !search.isEmpty else { return base }
        return base.filter { $0.name.localizedCaseInsensitiveContains(search) }
    }

    private var nearestAnchorage: Anchorage? {
        guard let loc = locationService.location else { return mapViewModel.anchorages.first }
        return mapViewModel.anchorages.min(by: {
            CLLocation(latitude: $0.latitude, longitude: $0.longitude).distance(from: loc) < CLLocation(latitude: $1.latitude, longitude: $1.longitude).distance(from: loc)
        })
    }

    private func loadNearestWeather() {
        if let anchorage = nearestAnchorage {
            Task { await weatherVM.loadWeather(lat: anchorage.latitude, lon: anchorage.longitude) }
        }
    }

    private func handleAnchorageTap(_ anchorage: Anchorage) {
        if routeVM.isRoutingMode {
            routeVM.addAnchorage(anchorage)
        } else {
            mapViewModel.mapMode = .detail
            presentSheet(.anchorage(anchorage))
        }
    }

    private func addAnchorageToRoute(_ anchorage: Anchorage) {
        withAnimation(.spring()) {
            routeVM.addAnchorage(anchorage)
            routeVM.isRoutingMode = true
            presentSheet(.routePlanner)
        }
    }

    private func presentSheet(_ sheet: ActiveMapSheet) {
        if activeSheet == nil {
            activeSheet = sheet
            return
        }
        activeSheet = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
            activeSheet = sheet
        }
    }

}

struct MapUIKitView: UIViewRepresentable {
    let anchorages: [Anchorage]
    let mapPoints: [MapPoint]
    @Binding var selectedAnchorage: Anchorage?
    @Binding var selectedMapPoint: MapPoint?
    let routeWaypoints: [Waypoint]
    let routeMode: Bool
    let focusRegion: MKCoordinateRegion?
    let onAnchorageTap: (Anchorage) -> Void
    let onRegionChanged: (MKCoordinateRegion) async -> Void
    let onLongPressCoordinate: (CLLocationCoordinate2D) -> Void
    let onFocusRegionApplied: () -> Void

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    func makeUIView(context: Context) -> MKMapView {
        let map = MKMapView(frame: .zero)
        map.delegate = context.coordinator
        map.showsCompass = true
        map.setRegion(.init(center: .init(latitude: 37.0, longitude: 27.5), span: .init(latitudeDelta: 4, longitudeDelta: 4)), animated: false)

        let base = MKTileOverlay(urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png")
        base.canReplaceMapContent = true
        map.addOverlay(base, level: .aboveLabels)
        map.addOverlay(MKTileOverlay(urlTemplate: "https://tiles.openseamap.org/seamark/{z}/{x}/{y}.png"), level: .aboveLabels)

        let longPress = UILongPressGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleLongPress(_:)))
        map.addGestureRecognizer(longPress)
        return map
    }

    func updateUIView(_ map: MKMapView, context: Context) {
        context.coordinator.parent = self
        if let focusRegion {
            map.setRegion(focusRegion, animated: true)
            DispatchQueue.main.async { onFocusRegionApplied() }
        }
        context.coordinator.syncAnnotations(on: map, anchorages: anchorages, mapPoints: mapPoints, routeWaypoints: routeWaypoints, routeMode: routeMode)
    }

    final class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapUIKitView
        private var regionTask: Task<Void, Never>?
        private var anchorageById: [String: AnchoragePoint] = [:]
        private var mapPointById: [String: MapPointMarker] = [:]
        private var routeById: [UUID: RouteWaypointAnnotation] = [:]

        init(parent: MapUIKitView) { self.parent = parent }

        @objc func handleLongPress(_ recognizer: UILongPressGestureRecognizer) {
            guard recognizer.state == .began, let map = recognizer.view as? MKMapView else { return }
            let point = recognizer.location(in: map)
            let coordinate = map.convert(point, toCoordinateFrom: map)
            parent.onLongPressCoordinate(coordinate)
        }

        func syncAnnotations(on mapView: MKMapView, anchorages: [Anchorage], mapPoints: [MapPoint], routeWaypoints: [Waypoint], routeMode: Bool) {
            let anchorageIds = Set(anchorages.map(\.id))
            let mapPointIds = Set(mapPoints.map(\.id))
            let routeIds = Set(routeWaypoints.map(\.id))

            for (id, annotation) in anchorageById where !anchorageIds.contains(id) || routeMode {
                mapView.removeAnnotation(annotation)
                anchorageById.removeValue(forKey: id)
            }
            for (id, annotation) in mapPointById where !mapPointIds.contains(id) {
                mapView.removeAnnotation(annotation)
                mapPointById.removeValue(forKey: id)
            }
            for (id, annotation) in routeById where !routeIds.contains(id) || !routeMode {
                mapView.removeAnnotation(annotation)
                routeById.removeValue(forKey: id)
            }

            if routeMode {
                for waypoint in routeWaypoints {
                    if let existing = routeById[waypoint.id] { existing.waypoint = waypoint }
                    else {
                        let anno = RouteWaypointAnnotation(waypoint: waypoint)
                        routeById[waypoint.id] = anno
                        mapView.addAnnotation(anno)
                    }
                }
            } else {
                for anchorage in anchorages {
                    if let existing = anchorageById[anchorage.id] { existing.anchorage = anchorage }
                    else {
                        let anno = AnchoragePoint(anchorage: anchorage)
                        anchorageById[anchorage.id] = anno
                        mapView.addAnnotation(anno)
                    }
                }
            }

            for point in mapPoints {
                if let existing = mapPointById[point.id] { existing.mapPoint = point }
                else {
                    let anno = MapPointMarker(mapPoint: point)
                    mapPointById[point.id] = anno
                    mapView.addAnnotation(anno)
                }
            }

            mapView.removeOverlays(mapView.overlays.filter { $0 is MKPolyline })
            if routeMode, routeWaypoints.count >= 2 {
                let coords = routeWaypoints.map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }
                let poly = MKPolyline(coordinates: coords, count: coords.count)
                mapView.addOverlay(poly, level: .aboveRoads)
                mapView.setRegion(MKCoordinateRegion(coordinates: coords), animated: true)
            }
        }

        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            regionTask?.cancel()
            let region = mapView.region
            regionTask = Task { [weak self] in
                try? await Task.sleep(for: .milliseconds(350))
                guard let self, !Task.isCancelled else { return }
                await self.parent.onRegionChanged(region)
            }
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let poly = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: poly)
                renderer.strokeColor = UIColor(Color(hex: "00B4D8"))
                renderer.lineWidth = 3
                renderer.lineDashPattern = [8, 6]
                return renderer
            }
            return MKTileOverlayRenderer(overlay: overlay)
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if let cluster = annotation as? MKClusterAnnotation {
                let view = mapView.dequeueReusableAnnotationView(withIdentifier: "anchorage-cluster") ?? MKAnnotationView(annotation: cluster, reuseIdentifier: "anchorage-cluster")
                view.annotation = cluster
                configureCluster(view: view, count: cluster.memberAnnotations.count)
                return view
            }

            if let route = annotation as? RouteWaypointAnnotation {
                let view = mapView.dequeueReusableAnnotationView(withIdentifier: "route") ?? MKAnnotationView(annotation: route, reuseIdentifier: "route")
                view.annotation = route
                configure(view: view, icon: "\(route.waypoint.order + 1)", color: UIColor(Color.oceanAccent), selected: false, size: 40, textMode: true)
                return view
            }

            if annotation is AnchoragePoint {
                let view = mapView.dequeueReusableAnnotationView(withIdentifier: "anchorage") ?? MKAnnotationView(annotation: annotation, reuseIdentifier: "anchorage")
                view.annotation = annotation
                view.clusteringIdentifier = "anchorage"
                configureAnchorage(view: view, selected: false)
                return view
            }
            if let point = annotation as? MapPointMarker {
                let view = mapView.dequeueReusableAnnotationView(withIdentifier: "mapPoint") ?? MKAnnotationView(annotation: annotation, reuseIdentifier: "mapPoint")
                view.annotation = point
                configure(view: view, icon: point.mapPoint.icon, color: UIColor(point.mapPoint.color), selected: false, size: 36)
                return view
            }
            return nil
        }

        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            if let route = view.annotation as? RouteWaypointAnnotation {
                configure(view: view, icon: "\(route.waypoint.order + 1)", color: UIColor(Color.oceanAccent), selected: true, size: 40, textMode: true)
                return
            }
            if let anchorage = view.annotation as? AnchoragePoint {
                parent.selectedMapPoint = nil
                parent.selectedAnchorage = anchorage.anchorage
                parent.onAnchorageTap(anchorage.anchorage)
                configureAnchorage(view: view, selected: true)
            } else if let point = view.annotation as? MapPointMarker {
                parent.selectedAnchorage = nil
                parent.selectedMapPoint = point.mapPoint
                configure(view: view, icon: point.mapPoint.icon, color: UIColor(point.mapPoint.color), selected: true, size: 36)
            }
        }

        func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
            if let route = view.annotation as? RouteWaypointAnnotation {
                configure(view: view, icon: "\(route.waypoint.order + 1)", color: UIColor(Color.oceanAccent), selected: false, size: 40, textMode: true)
            } else if view.annotation is AnchoragePoint {
                configureAnchorage(view: view, selected: false)
            } else if let point = view.annotation as? MapPointMarker {
                configure(view: view, icon: point.mapPoint.icon, color: UIColor(point.mapPoint.color), selected: false, size: 36)
            }
        }

        private func configureAnchorage(view: MKAnnotationView, selected: Bool) {
            view.canShowCallout = false
            view.frame = CGRect(x: 0, y: 0, width: 32, height: 32)
            view.backgroundColor = .clear
            view.layer.shadowOpacity = 0
            view.clusteringIdentifier = "anchorage"

            let tagCircle = 201
            let tagBoat = 202
            let tagBadge = 205

            let circle = view.viewWithTag(tagCircle) ?? {
                let v = UIView(frame: CGRect(x: 0, y: 0, width: 32, height: 32))
                v.tag = tagCircle
                v.layer.cornerRadius = 16
                v.center = CGPoint(x: 16, y: 16)
                view.addSubview(v)
                return v
            }()

            let boatIcon = (view.viewWithTag(tagBoat) as? UIImageView) ?? {
                let iv = UIImageView(frame: CGRect(x: 0, y: 0, width: 18, height: 18))
                iv.tag = tagBoat
                iv.tintColor = .white
                iv.contentMode = .scaleAspectFit
                iv.center = CGPoint(x: 16, y: 16)
                view.addSubview(iv)
                return iv
            }()

            circle.backgroundColor = UIColor(Color(hex: "0077B6"))
            circle.layer.shadowColor = UIColor(Color(hex: "0077B6")).cgColor
            circle.layer.shadowOpacity = selected ? 0.55 : 0.4
            circle.layer.shadowRadius = 6
            circle.layer.shadowOffset = .zero

            boatIcon.image = UIImage(systemName: "sailboat.fill")
            view.transform = selected ? CGAffineTransform(scaleX: 1.12, y: 1.12) : .identity

            if let anchorage = view.annotation as? AnchoragePoint,
               let count = anchorage.anchorage.currentVisitors,
               count > 0 {
                let badge = (view.viewWithTag(tagBadge) as? UILabel) ?? {
                    let l = UILabel(frame: CGRect(x: 0, y: 0, width: 16, height: 16))
                    l.tag = tagBadge
                    l.textAlignment = .center
                    l.font = .systemFont(ofSize: 9, weight: .bold)
                    l.textColor = .white
                    l.backgroundColor = .systemRed
                    l.layer.cornerRadius = 8
                    l.layer.masksToBounds = true
                    view.addSubview(l)
                    return l
                }()
                badge.text = "\(count)"
                badge.center = CGPoint(x: 27, y: 5)
                badge.isHidden = false
            } else {
                view.viewWithTag(tagBadge)?.isHidden = true
            }

            // Remove old layered subviews from circle-based style if reused.
            view.subviews
                .filter { $0.tag == 101 || $0.tag == 102 || $0.tag == 103 || $0.tag == 104 || $0.tag == 203 || $0.tag == 204 }
                .forEach { $0.removeFromSuperview() }
        }

        private func configureCluster(view: MKAnnotationView, count: Int) {
            view.canShowCallout = false
            view.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
            view.backgroundColor = .clear

            let tagCircle = 203
            let tagLabel = 204

            let circle = view.viewWithTag(tagCircle) ?? {
                let v = UIView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
                v.tag = tagCircle
                v.layer.cornerRadius = 20
                v.center = CGPoint(x: 20, y: 20)
                view.addSubview(v)
                return v
            }()

            let label = (view.viewWithTag(tagLabel) as? UILabel) ?? {
                let l = UILabel(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
                l.tag = tagLabel
                l.textAlignment = .center
                l.font = .systemFont(ofSize: 13, weight: .bold)
                l.textColor = .white
                l.center = CGPoint(x: 20, y: 20)
                view.addSubview(l)
                return l
            }()

            circle.backgroundColor = UIColor(Color(hex: "023E8A"))
            circle.layer.shadowColor = UIColor.black.cgColor
            circle.layer.shadowOpacity = 0.3
            circle.layer.shadowRadius = 4
            circle.layer.shadowOffset = CGSize(width: 0, height: 1)
            label.text = "\(count)"
        }

        private func configure(view: MKAnnotationView, icon: String, color: UIColor, selected: Bool, size: CGFloat, textMode: Bool = false) {
            view.canShowCallout = false
            view.frame = CGRect(x: 0, y: 0, width: size + 12, height: size + 12)

            let tagCircle = 101
            let tagRing = 102
            let tagIcon = 103
            let tagLabel = 104

            let ring = view.viewWithTag(tagRing) ?? {
                let v = UIView(frame: CGRect(x: 0, y: 0, width: size + 8, height: size + 8))
                v.tag = tagRing
                v.layer.cornerRadius = (size + 8) / 2
                v.layer.borderColor = UIColor.white.cgColor
                v.layer.borderWidth = 2
                v.center = CGPoint(x: (size + 12) / 2, y: (size + 12) / 2)
                view.addSubview(v)
                return v
            }()

            let circle = view.viewWithTag(tagCircle) ?? {
                let v = UIView(frame: CGRect(x: 0, y: 0, width: size, height: size))
                v.tag = tagCircle
                v.layer.cornerRadius = size / 2
                v.center = CGPoint(x: (size + 12) / 2, y: (size + 12) / 2)
                view.addSubview(v)
                return v
            }()

            let iconView = (view.viewWithTag(tagIcon) as? UIImageView) ?? {
                let iv = UIImageView(frame: CGRect(x: 0, y: 0, width: size * 0.58, height: size * 0.58))
                iv.tag = tagIcon
                iv.tintColor = .white
                iv.contentMode = .scaleAspectFit
                iv.center = CGPoint(x: (size + 12) / 2, y: (size + 12) / 2)
                view.addSubview(iv)
                return iv
            }()

            let label = (view.viewWithTag(tagLabel) as? UILabel) ?? {
                let l = UILabel(frame: CGRect(x: 0, y: 0, width: size, height: size))
                l.tag = tagLabel
                l.textAlignment = .center
                l.textColor = .white
                l.font = .systemFont(ofSize: 16, weight: .bold)
                l.center = CGPoint(x: (size + 12) / 2, y: (size + 12) / 2)
                view.addSubview(l)
                return l
            }()

            circle.backgroundColor = color
            circle.layer.shadowColor = color.cgColor
            circle.layer.shadowOpacity = 0.45
            circle.layer.shadowRadius = 6
            circle.layer.shadowOffset = .zero

            if textMode {
                iconView.isHidden = true
                label.isHidden = false
                label.text = icon
            } else {
                label.isHidden = true
                iconView.isHidden = false
                iconView.image = UIImage(systemName: icon)
            }

            ring.isHidden = !selected
            view.transform = selected ? CGAffineTransform(scaleX: 1.15, y: 1.15) : .identity
        }
    }
}

final class AnchoragePoint: NSObject, MKAnnotation {
    var anchorage: Anchorage
    var coordinate: CLLocationCoordinate2D { .init(latitude: anchorage.latitude, longitude: anchorage.longitude) }
    init(anchorage: Anchorage) { self.anchorage = anchorage }
}

final class MapPointMarker: NSObject, MKAnnotation {
    var mapPoint: MapPoint
    var coordinate: CLLocationCoordinate2D { .init(latitude: mapPoint.latitude, longitude: mapPoint.longitude) }
    init(mapPoint: MapPoint) { self.mapPoint = mapPoint }
}

final class RouteWaypointAnnotation: NSObject, MKAnnotation {
    var waypoint: Waypoint
    var coordinate: CLLocationCoordinate2D { .init(latitude: waypoint.latitude, longitude: waypoint.longitude) }
    init(waypoint: Waypoint) { self.waypoint = waypoint }
}

struct ToastItem: Identifiable {
    let id = UUID()
    let message: String
    let color: Color
}

struct ToastView: View {
    let item: ToastItem
    var body: some View {
        HStack {
            Text(item.message).font(.subheadline.bold()).foregroundStyle(.white)
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(item.color.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }
}

struct FABButton: View {
    let icon: String
    let label: String
    let action: () -> Void
    @State private var isPressed = false

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isPressed = false
            }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        }) {
            ZStack {
                Circle()
                    .fill(Color(hex: "023E8A"))
                    .frame(width: 52, height: 52)
                    .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
            }
        }
        .accessibilityLabel(Text(label))
        .scaleEffect(isPressed ? 0.88 : 1.0)
    }
}

struct AnchorageDetailSheet: View {
    let anchorage: Anchorage
    let onAddToRoute: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                AnchorageDetailView(anchorage: anchorage, onAddToRoute: {
                    onAddToRoute()
                    dismiss()
                }).frame(maxHeight: 420)
            }
            .padding()
        }
        .background(Color.seaBlue.ignoresSafeArea())
    }
}

struct WeatherSheetView: View {
    let selectedAnchorage: Anchorage?
    @ObservedObject var weatherVM: WeatherViewModel
    @Binding var showPaywall: Bool
    @EnvironmentObject var storeService: StoreService

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                Text(selectedAnchorage?.name ?? "Nearest point")
                    .font(.title3.bold())
                    .foregroundStyle(.white)

                ZStack {
                    WaveAnimationView(waveHeight: weatherVM.currentConditions?.waveHeight ?? 0.5).frame(height: 180)
                    if let c = weatherVM.currentConditions {
                        VStack(spacing: 8) {
                            Text("\(c.safetyScore)").font(.system(size: 36, weight: .bold)).foregroundStyle(.white)
                            Text(c.safetyLabel).foregroundStyle(.white)
                            if storeService.isPremium { WindCompassView(direction: c.waveDirection, waveHeight: c.waveHeight) }
                        }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 16))

                if storeService.isPremium {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack { ForEach(weatherVM.hourlyData.prefix(168)) { WeatherHourCard(hour: $0) } }
                    }
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack { ForEach(weatherVM.hourlyData.prefix(24)) { WeatherHourCard(hour: $0) } }
                    }
                    BlurredPremiumGate(icon: "cloud.sun.fill", title: "7-Day Forecast + Risk Analysis", subtitle: "Go Pro to view route-level risks", showPaywall: $showPaywall)
                }
            }
            .padding()
        }
        .background(Color.seaBlue.ignoresSafeArea())
        .task {
            if let anchorage = selectedAnchorage {
                await weatherVM.loadWeather(lat: anchorage.latitude, lon: anchorage.longitude)
            }
        }
    }
}

struct RoutePlannerSheet: View {
    @ObservedObject var vm: RouteViewModel
    let onAddStop: () -> Void
    let onShowSummary: () -> Void
    let onClose: () -> Void
    @EnvironmentObject var mapVM: MapViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Plan Route")
                    .foregroundStyle(.white)
                Spacer()
                Button {
                    dismiss()
                    onClose()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white.opacity(0.7))
                        .font(.title2)
                }
            }

            HStack {
                Text(vm.waypoints.isEmpty ? "0 stops - 0.0 nm - 0h 0m" : "\(vm.waypoints.count) stops • \(vm.formattedDistance) • \(vm.formattedDuration)")
                    .foregroundStyle(Color.seafoam)
                Spacer()
                Button("+ Add Stop") { onAddStop() }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.oceanAccent)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
            }

            if vm.waypoints.isEmpty {
                Text("Search start point...").foregroundStyle(Color.seafoam)
                Button("Search Stop") { onAddStop() }
                    .buttonStyle(.borderedProminent)
                    .tint(.oceanAccent)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    TextField("Route name", text: $vm.currentRouteName).textFieldStyle(.roundedBorder)
                    HStack {
                        Text("Speed: \(String(format: "%.1f", vm.averageSpeed)) kn").foregroundStyle(.white)
                        Slider(value: $vm.averageSpeed, in: 3...12, step: 0.5)
                            .tint(.oceanAccent)
                            .onChange(of: vm.averageSpeed) { _, _ in vm.recalculate() }
                    }

                    List {
                        ForEach(vm.waypoints) { waypoint in
                            WaypointRowView(waypoint: waypoint) {
                                vm.removeWaypoint(id: waypoint.id)
                            }
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                        }
                        .onMove(perform: vm.moveWaypoint)
                    }
                    .frame(height: 220)
                    .scrollContentBackground(.hidden)
                    .listStyle(.plain)

                    HStack(spacing: 10) {
                        Button("Save Route") { vm.saveRoute(name: vm.currentRouteName) }
                            .buttonStyle(.borderedProminent)
                            .tint(.oceanAccent)
                        Button("Summary") { onShowSummary() }
                            .buttonStyle(.bordered)
                            .tint(.white)
                        Button("Clear") {
                            vm.clearRoute()
                            mapVM.mapMode = .browse
                            vm.isRoutingMode = false
                        }
                        .buttonStyle(.bordered)
                        .tint(.white)
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .padding()
        .background(Color.seaBlueMid)
    }
}
