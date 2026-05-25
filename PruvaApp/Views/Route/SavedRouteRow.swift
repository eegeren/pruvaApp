import SwiftUI

struct SavedRouteRow: View {
    let route: Route
    let onLoad: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(route.name)
                    .font(.headline)
                    .foregroundColor(.white)
                HStack {
                    Text("\(route.waypoints.count) stops")
                    Text("•")
                    Text(route.formattedDistance)
                    Text("•")
                    Text(route.formattedDuration)
                }
                .font(.caption)
                .foregroundColor(Color(hex: "90E0EF"))
            }

            Spacer()

            HStack(spacing: 8) {
                Button(action: onLoad) {
                    Text("Load")
                        .font(.caption.bold())
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(hex: "00B4D8"))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }

                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.red.opacity(0.7))
                }
            }
        }
        .padding()
        .background(Color(hex: "0077B6"))
        .cornerRadius(12)
    }
}
