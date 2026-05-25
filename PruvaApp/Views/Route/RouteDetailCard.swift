import SwiftUI

struct RouteDetailCard: View {
    let route: Route

    var body: some View {
        if route.waypoints.count >= 2 {
            VStack(alignment: .leading, spacing: 6) {
                Text("From: \(route.waypoints.first?.displayName ?? "-")")
                Text("To: \(route.waypoints.last?.displayName ?? "-")")
                Text("-> \(route.formattedDistance) • \(route.formattedDuration)")
                    .font(.caption)
                    .foregroundStyle(Color.seafoam)
            }
            .font(.subheadline)
            .foregroundStyle(.white)
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.seaBlueMid)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
}
