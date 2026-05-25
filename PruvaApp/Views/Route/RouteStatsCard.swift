import SwiftUI

struct RouteStatsCard: View {
    let stops: Int
    let distance: String
    let duration: String

    var body: some View {
        HStack {
            StatPill(icon: "mappin.circle.fill", value: "\(stops)", label: "stops")
            Divider().background(Color.white.opacity(0.3)).frame(height: 30)
            StatPill(icon: "arrow.left.and.right", value: distance, label: "distance")
            Divider().background(Color.white.opacity(0.3)).frame(height: 30)
            StatPill(icon: "clock.fill", value: duration, label: "duration")
        }
        .padding()
        .background(Color(hex: "023E8A"))
        .cornerRadius(16)
        .padding(.horizontal)
    }
}

struct StatPill: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: icon)
                .foregroundColor(Color(hex: "00B4D8"))
                .font(.caption)
            Text(value)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.white)
            Text(label)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
    }
}
