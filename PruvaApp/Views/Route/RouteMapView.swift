import SwiftUI
import MapKit

struct RouteMapView: UIViewRepresentable {
    @ObservedObject var vm: RouteViewModel

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    func makeUIView(context: Context) -> MKMapView {
        let map = MKMapView(frame: .zero)
        map.delegate = context.coordinator
        map.showsCompass = true
        map.setRegion(.init(center: .init(latitude: 37.0, longitude: 27.5), span: .init(latitudeDelta: 4, longitudeDelta: 4)), animated: false)
        return map
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        context.coordinator.parent = self
        context.coordinator.refresh(mapView: mapView, waypoints: vm.waypoints)
    }

    final class Coordinator: NSObject, MKMapViewDelegate {
        var parent: RouteMapView

        init(parent: RouteMapView) {
            self.parent = parent
        }

        func refresh(mapView: MKMapView, waypoints: [Waypoint]) {
            mapView.removeAnnotations(mapView.annotations)
            let annotations = waypoints.map { RoutePreviewWaypointAnnotation(waypoint: $0) }
            mapView.addAnnotations(annotations)
            updateRoutePolyline(mapView: mapView, waypoints: waypoints)

            if !annotations.isEmpty {
                mapView.showAnnotations(annotations, animated: true)
            }
        }

        private func updateRoutePolyline(mapView: MKMapView, waypoints: [Waypoint]) {
            let existing = mapView.overlays.filter { $0 is MKPolyline }
            mapView.removeOverlays(existing)

            guard waypoints.count >= 2 else { return }

            let coords = waypoints.map {
                CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude)
            }
            let polyline = MKPolyline(coordinates: coords, count: coords.count)
            mapView.addOverlay(polyline, level: .aboveRoads)
            mapView.setRegion(MKCoordinateRegion(coordinates: coords), animated: true)
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            guard let poly = overlay as? MKPolyline else { return MKOverlayRenderer(overlay: overlay) }
            let renderer = MKPolylineRenderer(polyline: poly)
            renderer.strokeColor = UIColor(Color(hex: "00B4D8"))
            renderer.lineWidth = 3
            renderer.lineDashPattern = [8, 6]
            return renderer
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard let wp = annotation as? RoutePreviewWaypointAnnotation else { return nil }
            let id = "route-waypoint"
            let view = mapView.dequeueReusableAnnotationView(withIdentifier: id) ?? MKAnnotationView(annotation: annotation, reuseIdentifier: id)
            view.annotation = wp
            view.canShowCallout = false
            view.subviews.forEach { $0.removeFromSuperview() }

            let host = UIHostingController(rootView: WaypointPinView(number: wp.waypoint.order + 1))
            host.view.backgroundColor = .clear
            host.view.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
            view.addSubview(host.view)
            view.frame = host.view.frame
            return view
        }
    }
}

final class RoutePreviewWaypointAnnotation: NSObject, MKAnnotation {
    let waypoint: Waypoint
    var coordinate: CLLocationCoordinate2D { .init(latitude: waypoint.latitude, longitude: waypoint.longitude) }

    init(waypoint: Waypoint) {
        self.waypoint = waypoint
    }
}

struct WaypointPinView: View {
    let number: Int

    var body: some View {
        ZStack {
            Circle().fill(Color(hex: "00B4D8")).frame(width: 40, height: 40)
            Text("\(number)")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.white)
        }
    }
}

extension MKCoordinateRegion {
    init(coordinates: [CLLocationCoordinate2D]) {
        let minLat = coordinates.map { $0.latitude }.min() ?? 0
        let maxLat = coordinates.map { $0.latitude }.max() ?? 0
        let minLon = coordinates.map { $0.longitude }.min() ?? 0
        let maxLon = coordinates.map { $0.longitude }.max() ?? 0

        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        let span = MKCoordinateSpan(
            latitudeDelta: (maxLat - minLat) * 1.4 + 0.5,
            longitudeDelta: (maxLon - minLon) * 1.4 + 0.5
        )
        self.init(center: center, span: span)
    }
}
