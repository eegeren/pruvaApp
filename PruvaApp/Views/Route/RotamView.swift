import SwiftUI

struct RotamView: View {
    @StateObject private var routeVM = RouteViewModel()
    @EnvironmentObject var mapVM: MapViewModel
    @State private var showRouteSheet = true
    @State private var selectedDetent: PresentationDetent = .medium

    var body: some View {
        RouteMapView(vm: routeVM)
            .ignoresSafeArea()
            .sheet(isPresented: $showRouteSheet) {
                RouteSheetView(routeVM: routeVM) {
                    routeVM.isRoutingMode = false
                    showRouteSheet = false
                }
                .presentationDetents([.medium, .large], selection: $selectedDetent)
                .presentationBackground(Color(hex: "0096C7"))
                .presentationCornerRadius(24)
                .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: Binding(
                get: { routeVM.showSearchSheet },
                set: { routeVM.showSearchSheet = $0 }
            )) {
                RouteSearchView(routeVM: routeVM, mapVM: mapVM)
                    .presentationBackground(Color(hex: "0096C7"))
            }
            .sheet(isPresented: Binding(
                get: { routeVM.showRouteSummary },
                set: { routeVM.showRouteSummary = $0 }
            )) {
                RouteSummaryView(routeVM: routeVM)
                    .presentationBackground(Color(hex: "0096C7"))
            }
            .onChange(of: routeVM.waypoints.count) { _, count in
                if count > 0 {
                    selectedDetent = .large
                }
            }
            .onAppear {
                routeVM.loadSavedRoutes()
                selectedDetent = routeVM.waypoints.isEmpty ? .medium : .large
            }
    }
}
