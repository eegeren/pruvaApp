import SwiftUI

struct RouteSheetView: View {
    @ObservedObject var routeVM: RouteViewModel
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider().background(Color.white.opacity(0.15))

            ScrollView {
                VStack(spacing: 16) {
                    if routeVM.waypoints.isEmpty {
                        emptyStateView
                    } else {
                        RouteStatsCard(
                            stops: routeVM.waypoints.count,
                            distance: routeVM.formattedDistance,
                            duration: routeVM.formattedDuration
                        )

                        speedSliderView
                        waypointListView
                    }
                }
                .padding(.vertical, 16)
                .padding(.bottom, 50)
            }

            actionButtonsView
        }
        .background(Color(hex: "0096C7").ignoresSafeArea())
    }

    private var header: some View {
        VStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.white.opacity(0.4))
                .frame(width: 40, height: 4)
                .padding(.top, 8)

            HStack {
                Text(routeVM.waypoints.isEmpty ? "Plan Route" : "My Route")
                    .font(.title3.bold())
                    .foregroundColor(.white)
                Spacer()
                if !routeVM.waypoints.isEmpty {
                    Text("\(routeVM.waypoints.count) stops • \(routeVM.formattedDistance)")
                        .font(.caption)
                        .foregroundColor(Color(hex: "90E0EF"))
                }
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white.opacity(0.6))
                        .font(.title3)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
        }
        .background(Color(hex: "0096C7"))
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "point.topleft.down.curvedto.point.bottomright.up.fill")
                .font(.system(size: 50))
                .foregroundColor(Color(hex: "00B4D8"))

            Text("Plan Your Route")
                .font(.title2.bold())
                .foregroundColor(.white)

            Text("Tap anchorages on the map or search to add stops")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)

            Button {
                routeVM.showSearchSheet = true
            } label: {
                HStack {
                    Image(systemName: "magnifyingglass")
                    Text("Search Anchorages")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(hex: "0077B6"))
                .foregroundColor(.white)
                .cornerRadius(14)
            }

            if !routeVM.savedRoutes.isEmpty {
                Text("Saved Routes")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)

                ForEach(routeVM.savedRoutes) { route in
                    SavedRouteRow(route: route) {
                        routeVM.loadRoute(route)
                    } onDelete: {
                        routeVM.deleteSavedRoute(id: route.id)
                    }
                }
            }
        }
        .padding(.horizontal, 20)
    }

    private var speedSliderView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Speed")
                    .foregroundColor(.white.opacity(0.7))
                Spacer()
                Text(String(format: "%.0f knots", routeVM.averageSpeed))
                    .foregroundColor(Color(hex: "00B4D8"))
                    .bold()
                    .contentTransition(.numericText())
            }
            Slider(value: $routeVM.averageSpeed, in: 3...12, step: 0.5)
                .tint(Color(hex: "00B4D8"))
                .onChange(of: routeVM.averageSpeed) { _, _ in
                    routeVM.recalculate()
                }
        }
        .padding(.horizontal, 16)
    }

    private var waypointListView: some View {
        VStack(spacing: 8) {
            ForEach(Array(routeVM.waypoints.enumerated()), id: \.element.id) { index, waypoint in
                HStack(spacing: 8) {
                    WaypointRowView(waypoint: waypoint) {
                        routeVM.removeWaypoint(id: waypoint.id)
                    }

                    VStack(spacing: 6) {
                        Button {
                            guard index > 0 else { return }
                            routeVM.moveWaypoint(from: IndexSet(integer: index), to: index - 1)
                        } label: {
                            Image(systemName: "chevron.up")
                        }
                        .disabled(index == 0)

                        Button {
                            guard index < routeVM.waypoints.count - 1 else { return }
                            routeVM.moveWaypoint(from: IndexSet(integer: index), to: index + 2)
                        } label: {
                            Image(systemName: "chevron.down")
                        }
                        .disabled(index == routeVM.waypoints.count - 1)
                    }
                    .font(.caption.bold())
                    .foregroundColor(.white)
                    .padding(.trailing, 4)
                }
                .padding(.horizontal, 16)
            }
        }
    }

    private var actionButtonsView: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                Button {
                    routeVM.showSearchSheet = true
                } label: {
                    Label("Add Stop", systemImage: "plus")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(hex: "0077B6"))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }

                Button {
                    routeVM.showRouteSummary = true
                } label: {
                    Label("Summary", systemImage: "doc.text")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(hex: "023E8A"))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .disabled(routeVM.waypoints.isEmpty)
                .opacity(routeVM.waypoints.isEmpty ? 0.5 : 1)
            }
            .padding(.horizontal, 16)

            Button("Clear Route", role: .destructive) {
                withAnimation { routeVM.clearRoute() }
            }
            .foregroundColor(.red.opacity(0.8))
            .padding(.bottom, 8)
            .disabled(routeVM.waypoints.isEmpty)
            .opacity(routeVM.waypoints.isEmpty ? 0.5 : 1)
        }
        .padding(.top, 10)
        .background(Color(hex: "0096C7"))
    }
}
