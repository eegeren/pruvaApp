import SwiftUI

struct WaypointRowView: View {
    let waypoint: Waypoint
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color(hex: "00B4D8"))
                    .frame(width: 32, height: 32)
                Text("\(waypoint.order + 1)")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(waypoint.displayName)
                    .font(.headline)
                    .foregroundColor(.white)

                HStack(spacing: 8) {
                    if let dist = waypoint.distanceFromPrevious {
                        Label(String(format: "%.1f nm", dist), systemImage: "arrow.right")
                            .font(.caption)
                            .foregroundColor(Color(hex: "90E0EF"))
                    }
                    if let dur = waypoint.durationFromPrevious {
                        Text("\(Int(dur * 60))m")
                            .font(.caption)
                            .foregroundColor(Color(hex: "90E0EF"))
                    }
                }

                if let arrival = waypoint.estimatedArrival {
                    Text("ETA \(arrival.formatted(.dateTime.hour().minute()))")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.6))
                }
            }

            Spacer()

            Button {
                withAnimation(.spring()) { onDelete() }
            } label: {
                Image(systemName: "minus.circle.fill")
                    .foregroundColor(.red.opacity(0.7))
                    .font(.title3)
            }
        }
        .padding(.vertical, 6)
    }
}
