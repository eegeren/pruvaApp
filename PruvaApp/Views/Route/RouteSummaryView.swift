import SwiftUI
import UIKit

struct RouteSummaryView: View {
    @ObservedObject var routeVM: RouteViewModel
    @State private var routeName = "My Route"
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    VStack(alignment: .leading) {
                        Text("Route Name")
                            .foregroundColor(.white.opacity(0.7))
                            .font(.caption)
                        TextField("Route name...", text: $routeName)
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Color(hex: "0077B6"))
                            .cornerRadius(10)
                    }

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        StatCard(icon: "mappin.circle", title: "Stops", value: "\(routeVM.waypoints.count)")
                        StatCard(icon: "arrow.left.and.right", title: "Distance", value: routeVM.formattedDistance)
                        StatCard(icon: "clock", title: "Duration", value: routeVM.formattedDuration)
                        StatCard(icon: "speedometer", title: "Speed", value: "\(Int(routeVM.averageSpeed)) kn")
                    }

                    VStack(alignment: .leading, spacing: 0) {
                        Text("Timeline")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.bottom, 12)

                        ForEach(Array(routeVM.waypoints.enumerated()), id: \.element.id) { index, wp in
                            HStack(alignment: .top, spacing: 12) {
                                VStack(spacing: 0) {
                                    ZStack {
                                        Circle()
                                            .fill(Color(hex: "00B4D8"))
                                            .frame(width: 28, height: 28)
                                        Text("\(index + 1)")
                                            .font(.caption.bold())
                                            .foregroundColor(.white)
                                    }
                                    if index < routeVM.waypoints.count - 1 {
                                        Rectangle()
                                            .fill(Color(hex: "00B4D8").opacity(0.4))
                                            .frame(width: 2, height: 40)
                                    }
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(wp.displayName)
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    if let arrival = wp.estimatedArrival {
                                        Text("ETA: \(arrival.formatted(.dateTime.hour().minute()))")
                                            .font(.caption)
                                            .foregroundColor(Color(hex: "90E0EF"))
                                    }
                                    if let dist = wp.distanceFromPrevious {
                                        Text("\(String(format: "%.1f", dist)) nm from previous")
                                            .font(.caption)
                                            .foregroundColor(Color(hex: "90E0EF"))
                                    }
                                }
                                Spacer()
                            }
                            .padding(.bottom, 4)
                        }
                    }
                    .padding()
                    .background(Color(hex: "0077B6"))
                    .cornerRadius(16)

                    Button {
                        routeVM.saveRoute(name: routeName)
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: "square.and.arrow.down")
                            Text("Save Route")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(hex: "00B4D8"))
                        .foregroundColor(.white)
                        .cornerRadius(14)
                    }

                    Button {
                        shareRoute()
                    } label: {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share Route")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(hex: "023E8A"))
                        .foregroundColor(.white)
                        .cornerRadius(14)
                    }
                }
                .padding()
            }
            .background(Color(hex: "0096C7").ignoresSafeArea())
            .navigationTitle("Route Summary")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(Color(hex: "00B4D8"))
                }
            }
        }
        .onAppear {
            routeName = routeVM.currentRouteName
        }
    }

    private func shareRoute() {
        var text = "🗺 \(routeName)\n"
        text += "📍 \(routeVM.waypoints.count) stops • \(routeVM.formattedDistance) • \(routeVM.formattedDuration)\n\n"
        for (i, wp) in routeVM.waypoints.enumerated() {
            text += "\(i + 1). \(wp.displayName)"
            if let dist = wp.distanceFromPrevious {
                text += " (\(String(format: "%.1f", dist)) nm)"
            }
            text += "\n"
        }
        text += "\nPlanned with Pruva app"

        let av = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first?.rootViewController?
            .present(av, animated: true)
    }
}

private struct StatCard: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: icon)
                .font(.caption)
                .foregroundColor(.white.opacity(0.75))
            Text(value)
                .font(.headline)
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(hex: "0077B6"))
        .cornerRadius(12)
    }
}
